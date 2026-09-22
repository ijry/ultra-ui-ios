import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 对应上游 `data.list` / `orderIds` / `dragItemId`。
@MainActor
@Observable
private final class UPDragsortState<Item> {
    var items: [Item]
    var draggingIndex: Int?

    init(items: [Item]) {
        self.items = items
    }
}

/// Native SwiftUI counterpart of uview-plus `u-dragsort`.
///
/// 上游用 `movable-area` + `movable-view` 实现拖拽：长按抓起某项（`vibrate` 时震一下），
/// 拖动过程中按位置换序，松手后 50ms 抛 `drag-end`（负载是排好序的整个列表）。
/// `direction` 决定竖排 / 横排 / 网格（`all` 时按 `columns` 分列），
/// `draggable` 全局开关，单项还可以用 `item.draggable === false` 单独禁用。
///
/// 原生用 `DragGesture` + `move(from:to:)` 完成同样的换序，
/// 拖拽中的位移不做逐帧跟手动画（上游靠 `movable-view` 的 `x`/`y` 属性驱动）。
@MainActor
public struct UPDragsort<Item: Equatable, Content: View>: View {
    public var direction: String
    public var draggable: Bool
    public var vibrate: Bool
    public var columns: Int

    public var items: [Item] { state.items }
    /// 仓库既有名：`draggable` 的反义。
    public var disabled: Bool { !draggable }
    /// 正在拖动的下标，对应上游 `dragItemId`。
    public var draggingIndex: Int? { state.draggingIndex }

    @State private var state: UPDragsortState<Item>
    private let content: ((Item, Int) -> Content)?
    private var handlerSlot: ((Item, Int) -> AnyView)?
    private var itemDraggable: ((Item) -> Bool)?
    private var onChangeHandler: (([Item]) -> Void)?
    private var onStartHandler: ((Int) -> Void)?
    private var onEndHandler: ((Int, Int) -> Void)?
    private var onDragEndHandler: (([Item]) -> Void)?

    /// 与上游 `props` 对齐的初始化器。
    public init(initialList: [Item],
                draggable: Bool = UPConfig.dragsort.draggable,
                vibrate: Bool = UPConfig.dragsort.vibrate,
                direction: String = UPConfig.dragsort.direction,
                columns: Int = UPConfig.dragsort.columns,
                itemDraggable: ((Item) -> Bool)? = nil,
                @ViewBuilder content: @escaping (Item, Int) -> Content) {
        self.draggable = draggable
        self.vibrate = vibrate
        self.direction = ["vertical", "horizontal", "all"].contains(direction) ? direction : "vertical"
        self.columns = max(columns, 1)
        self.itemDraggable = itemDraggable
        self.content = content
        self._state = State(initialValue: UPDragsortState(items: initialList))
    }

    /// 仓库既有签名。
    public init(items: [Item],
                disabled: Bool = false,
                @ViewBuilder content: @escaping (Item) -> Content) {
        self.init(initialList: items,
                  draggable: !disabled,
                  content: { item, _ in content(item) })
    }

    /// 仓库既有签名（无内容闭包）。
    public init(items: [Item], disabled: Bool = false) where Content == EmptyView {
        self.draggable = !disabled
        self.vibrate = UPConfig.dragsort.vibrate
        self.direction = UPConfig.dragsort.direction
        self.columns = UPConfig.dragsort.columns
        self.content = nil
        self._state = State(initialValue: UPDragsortState(items: items))
    }

    // MARK: - 上游方法

    /// 单项是否可拖，对应上游 `!draggable || item.draggable === false`。
    public func isDraggable(_ item: Item) -> Bool {
        draggable && (itemDraggable?(item) ?? true)
    }

    /// 对应上游 `onTouchStart`：抓起某项，`vibrate` 时震一下。
    public func begin(at index: Int) {
        guard items.indices.contains(index), isDraggable(items[index]) else { return }
        state.draggingIndex = index
        if vibrate { Self.playVibration() }
        onStartHandler?(index)
    }

    /// 换序。上游是拖动中即时换位，松手后才抛 `drag-end`；
    /// 原生把「换位」与「抛事件」都放在这里，保持仓库既有语义。
    @discardableResult
    public func move(from source: Int, to destination: Int) -> [Item] {
        guard draggable, items.indices.contains(source), !items.isEmpty else { return items }
        var result = items
        let item = result.remove(at: source)
        let target = min(max(destination, 0), result.count)
        result.insert(item, at: target)
        state.items = result
        onChangeHandler?(result)
        onEndHandler?(source, target)
        onDragEndHandler?(result)
        return result
    }

    /// 对应上游 `onTouchEnd`：清掉拖动态。
    public func end() {
        state.draggingIndex = nil
    }

    private static func playVibration() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    // MARK: - 事件与插槽

    public func onChange(_ action: @escaping ([Item]) -> Void) -> Self {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    public func onStart(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onStartHandler = action
        return copy
    }

    public func onEnd(_ action: @escaping (Int, Int) -> Void) -> Self {
        var copy = self
        copy.onEndHandler = action
        return copy
    }

    /// 对应上游 `drag-end` 事件，负载是排好序的整个列表。
    public func onDragEnd(_ action: @escaping ([Item]) -> Void) -> Self {
        var copy = self
        copy.onDragEndHandler = action
        return copy
    }

    /// 对应上游 `#handler` 作用域插槽：只有拖拽把手能发起拖动。
    public func handler<Slot: View>(@ViewBuilder _ builder: @escaping (Item, Int) -> Slot) -> Self {
        var copy = self
        copy.handlerSlot = { AnyView(builder($0, $1)) }
        return copy
    }

    public var hasHandlerSlot: Bool { handlerSlot != nil }

    // MARK: - 视图

    public var body: some View {
        switch direction {
        case "horizontal":
            return AnyView(
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) { rows }
                }
            )
        case "all":
            return AnyView(
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: columns),
                          spacing: 0) { rows }
            )
        default:
            return AnyView(LazyVStack(spacing: 0) { rows })
        }
    }

    @ViewBuilder
    private var rows: some View {
        ForEach(items.indices, id: \.self) { index in
            row(at: index)
        }
    }

    @ViewBuilder
    private func row(at index: Int) -> some View {
        let item = items[index]
        HStack(spacing: 8) {
            if let handlerSlot {
                handlerSlot(item, index)
                    .gesture(dragGesture(at: index))
            }

            if let content {
                content(item, index)
            }
        }
        .opacity(draggingIndex == index ? 0.6 : 1)
        .contentShape(Rectangle())
        // 没有把手时整行都能拖，对应上游 `movable-view` 自身的 touchstart。
        .modifier(UPDragsortRowGesture(gesture: dragGesture(at: index), enabled: !hasHandlerSlot))
    }

    /// 长按抓起、拖动换序、松手结束，对应上游 touchstart/touchmove/touchend 三段。
    private func dragGesture(at index: Int) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if draggingIndex == nil { begin(at: index) }
                guard let from = draggingIndex else { return }
                let step = direction == "horizontal"
                    ? Int((value.translation.width / Self.stepLength).rounded())
                    : Int((value.translation.height / Self.stepLength).rounded())
                let target = from + step
                guard step != 0, items.indices.contains(target) else { return }
                move(from: from, to: target)
                state.draggingIndex = target
            }
            .onEnded { _ in end() }
    }

    /// 换序步长：上游用实测的 item 宽高，原生没有逐项测量，取一个稳定的近似值。
    static var stepLength: CGFloat { 44 }
}

/// 没有 `#handler` 插槽时整行可拖。
private struct UPDragsortRowGesture<G: Gesture>: ViewModifier {
    let gesture: G
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.gesture(gesture)
        } else {
            content
        }
    }
}
