import Observation
import SwiftUI

/// 对应上游 `data`：`startIndex` 与量出来的 `containerHeight`。
@MainActor
@Observable
private final class UPVirtualListState {
    var startIndex = 0
    var containerHeight: CGFloat = 0
    var scrollTop: CGFloat = 0
}

/// Native SwiftUI counterpart of uview-plus `u-virtual-list`.
///
/// 上游是「上占位 + 可见项 + 下占位」的经典虚拟列表：`remain` 由容器高度除以
/// `itemHeight` 得出，`visibleCount = remain + buffer`，起点再往前退 `buffer / 2`。
/// 原生保留同一套区间算法（`visibleRange` / `topSpacer` / `bottomSpacer` 可单测），
/// 渲染改用 `LazyVStack`，本身就只实例化可见行。
@MainActor
public struct UPVirtualList<Item, Content: View>: View {
    public var items: [Item]
    public var itemHeight: CGFloat
    /// 上游 `height` 是 CSS 值（默认 `'100%'`）。
    public var height: String
    /// 上游 `buffer`：可视区之外额外渲染的项数。
    public var buffer: Int
    /// 上游 `keyField`：`getItemKey` 取该字段当 key，取不到时退回下标。
    public var keyField: String
    public var showScrollbar: Bool

    private let content: (Item) -> Content
    private var keyProvider: ((Item) -> String)?
    private var scrollTopBinding: Binding<CGFloat>?
    private var onScrollHandler: ((CGFloat) -> Void)?

    @State private var state: UPVirtualListState

    private static var scrollSpace: String { "UPVirtualList" }

    /// 与上游 `props` 对齐的初始化器。
    public init(listData: [Item],
                itemHeight: some UPImageUnitValue = UPConfig.virtualList.itemHeight,
                height: String = UPConfig.virtualList.height,
                buffer: Int = UPConfig.virtualList.buffer,
                keyField: String = UPConfig.virtualList.keyField,
                scrollTop: Binding<CGFloat>? = nil,
                showScrollbar: Bool = true,
                key: ((Item) -> String)? = nil,
                @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = listData
        self.itemHeight = max(UPUnit.parse(itemHeight.upImageUnitValue), 0)
        self.height = height
        self.buffer = max(buffer, 0)
        self.keyField = keyField
        self.showScrollbar = showScrollbar
        self.scrollTopBinding = scrollTop
        self.keyProvider = key
        self.content = content
        self._state = State(initialValue: UPVirtualListState())
    }

    /// 仓库既有签名：`viewportHeight` 是具体高度、`overscan` 是 `buffer` 的旧名。
    public init(items: [Item],
                itemHeight: CGFloat,
                viewportHeight: CGFloat,
                overscan: Int = 2,
                showScrollbar: Bool = true,
                @ViewBuilder content: @escaping (Item) -> Content) {
        self.init(listData: items,
                  itemHeight: itemHeight,
                  height: String(describing: Double(max(viewportHeight, 0))),
                  buffer: overscan,
                  showScrollbar: showScrollbar,
                  content: content)
    }

    // MARK: - 解析后的呈现值

    /// 仓库既有名。
    public var overscan: Int { buffer }

    /// 上游 `calculateDefaultHeight`：`100%` 这类交给父级，量不到时兜底 500。
    public var viewportHeight: CGFloat {
        if let explicit = Self.explicitHeight(height) { return explicit }
        return state.containerHeight > 0 ? state.containerHeight : CGFloat(UPConfig.virtualList.fallbackHeight)
    }

    /// 上游 `remain`：容器高度能放几项，至少 1 项。
    public var remain: Int {
        guard itemHeight > 0 else { return 10 }
        return max(Int(ceil(viewportHeight / itemHeight)), 1)
    }

    /// 上游 `visibleCount = remain + buffer`。
    public var visibleCount: Int { remain + buffer }

    /// 上游 `getVisibleRange()`：起点往前退 `buffer / 2`。
    public func visibleRange(offset: CGFloat) -> ClosedRange<Int> {
        guard !items.isEmpty, itemHeight > 0 else { return 0...0 }
        let startIndex = max(Int(floor(max(offset, 0) / itemHeight)), 0)
        let start = max(startIndex - buffer / 2, 0)
        let end = min(items.count, start + visibleCount)
        return start...max(start, end - 1)
    }

    /// 上游 `topPlaceholderHeight`。
    public func topSpacer(offset: CGFloat) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        return CGFloat(visibleRange(offset: offset).lowerBound) * itemHeight
    }

    /// 上游 `bottomPlaceholderHeight`。
    public func bottomSpacer(offset: CGFloat) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        let renderedCount = visibleRange(offset: offset).upperBound + 1
        return max(totalHeight - CGFloat(renderedCount) * itemHeight, 0)
    }

    /// 上游 `getItemKey(item)`：取 `keyField`，取不到用下标。
    public func itemKey(_ item: Item, index: Int) -> String {
        keyProvider?(item) ?? String(index)
    }

    /// 对应上游 `handleScroll`：写回 `update:scrollTop` 并抛 `scroll`。
    public func handleScroll(scrollTop: CGFloat) {
        state.scrollTop = scrollTop
        state.startIndex = itemHeight > 0 ? max(Int(floor(scrollTop / itemHeight)), 0) : 0
        scrollTopBinding?.wrappedValue = scrollTop
        onScrollHandler?(scrollTop)
    }

    /// 上游 `data.startIndex`。
    public var startIndex: Int { state.startIndex }

    private var totalHeight: CGFloat { CGFloat(items.count) * itemHeight }

    nonisolated static func explicitHeight(_ value: String) -> CGFloat? {
        guard !value.contains("%"), !value.contains("vh") else { return nil }
        let parsed = UPUnit.parse(value)
        return parsed > 0 ? parsed : nil
    }

    // MARK: - 事件

    /// 对应上游 `scroll` 事件，负载是 `scrollTop`。
    public func onScroll(_ action: @escaping (CGFloat) -> Void) -> UPVirtualList {
        var copy = self
        copy.onScrollHandler = action
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        ScrollView(.vertical, showsIndicators: showScrollbar) {
            LazyVStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    content(items[index]).frame(height: itemHeight)
                }
            }
            .background(scrollProbe)
        }
        .coordinateSpace(.named(Self.scrollSpace))
        .frame(height: Self.explicitHeight(height))
        .background(heightProbe)
    }

    private var scrollProbe: some View {
        GeometryReader { inner in
            Color.clear
                .onChange(of: Self.probeOffset(inner)) { _, offset in
                    handleScroll(scrollTop: offset)
                }
        }
    }

    private static func probeOffset(_ proxy: GeometryProxy) -> CGFloat {
        let space: NamedCoordinateSpace = .named(scrollSpace)
        return -proxy.frame(in: space).minY
    }

    /// 上游 `measureContainerHeight` 用 selectorQuery 量容器，原生用 GeometryReader。
    private var heightProbe: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { state.containerHeight = proxy.size.height }
                .onChange(of: proxy.size.height) { _, value in state.containerHeight = value }
        }
    }
}

public extension UPVirtualList where Content == EmptyView {
    init(listData: [Item],
         itemHeight: some UPImageUnitValue = UPConfig.virtualList.itemHeight,
         height: String = UPConfig.virtualList.height,
         buffer: Int = UPConfig.virtualList.buffer,
         keyField: String = UPConfig.virtualList.keyField,
         scrollTop: Binding<CGFloat>? = nil,
         showScrollbar: Bool = true,
         key: ((Item) -> String)? = nil) {
        self.init(listData: listData,
                  itemHeight: itemHeight,
                  height: height,
                  buffer: buffer,
                  keyField: keyField,
                  scrollTop: scrollTop,
                  showScrollbar: showScrollbar,
                  key: key,
                  content: { _ in EmptyView() })
    }

    init(items: [Item],
         itemHeight: CGFloat,
         viewportHeight: CGFloat,
         overscan: Int = 2,
         showScrollbar: Bool = true) {
        self.init(items: items,
                  itemHeight: itemHeight,
                  viewportHeight: viewportHeight,
                  overscan: overscan,
                  showScrollbar: showScrollbar,
                  content: { _ in EmptyView() })
    }
}
