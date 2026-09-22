import Observation
import SwiftUI

/// 对应上游 `data`：`refreshing` 与 `scrollTop`。
@MainActor
@Observable
private final class UPRefreshVirtualListState {
    var refreshing: Bool
    var scrollTop: CGFloat = 0

    init(refreshing: Bool) {
        self.refreshing = refreshing
    }
}

/// Native SwiftUI counterpart of uview-plus `u-refresh-virtual-list`.
///
/// 上游就是 `u-pull-refresh` 包 `u-virtual-list`：把 5 个列表 prop 原样透传，
/// `refresh` / `scroll` 两个事件向上抛，另有 `finishRefresh()` / `scrollTo(_:)` /
/// `scrollToTop()` 三个方法（`threshold` 在模板里写死 50）。
/// 原生同样是 `UPVirtualList` 加 `.refreshable`。
@MainActor
public struct UPRefreshVirtualList<Item, Content: View>: View {
    /// 上游模板里写死的 `:threshold="50"`。
    public static var threshold: CGFloat { 50 }

    public var listData: [Item]
    public var itemHeight: CGFloat
    public var height: String
    public var buffer: Int
    public var keyField: String
    public var refresherEnabled: Bool
    public var refresherThreshold: CGFloat

    public var refreshing: Bool { refreshingBinding?.wrappedValue ?? state.refreshing }
    /// 上游 `data.scrollTop`。
    public var scrollTop: CGFloat { state.scrollTop }

    private var refreshingBinding: Binding<Bool>?
    @State private var state: UPRefreshVirtualListState
    private let content: (Item, Int) -> Content
    private var keyProvider: ((Item) -> String)?
    private var onRefreshHandler: (() -> Void)?
    private var onScrollHandler: ((CGFloat) -> Void)?

    /// 与上游 `props` 对齐的初始化器。
    public init(listData: [Item],
                itemHeight: some UPImageUnitValue = UPConfig.virtualList.itemHeight,
                height: String = UPConfig.virtualList.height,
                buffer: Int = UPConfig.virtualList.buffer,
                keyField: String = UPConfig.virtualList.keyField,
                refreshing: Binding<Bool>? = nil,
                refresherEnabled: Bool = true,
                refresherThreshold: CGFloat = UPRefreshVirtualList.threshold,
                key: ((Item) -> String)? = nil,
                initialRefreshing: Bool = false,
                @ViewBuilder content: @escaping (Item, Int) -> Content) {
        self.listData = listData
        self.itemHeight = max(UPUnit.parse(itemHeight.upImageUnitValue), 0)
        self.height = height
        self.buffer = max(buffer, 0)
        self.keyField = keyField
        self.refreshingBinding = refreshing
        self.refresherEnabled = refresherEnabled
        self.refresherThreshold = max(refresherThreshold, 0)
        self.keyProvider = key
        self.content = content
        self._state = State(initialValue: UPRefreshVirtualListState(
            refreshing: refreshing?.wrappedValue ?? initialRefreshing
        ))
    }

    // MARK: - 上游方法

    /// 对应上游 `handleRefresh()`：置位并抛 `refresh`。
    public func beginRefresh() {
        guard refresherEnabled, !refreshing else { return }
        state.refreshing = true
        refreshingBinding?.wrappedValue = true
        onRefreshHandler?()
    }

    /// 对应上游 `finishRefresh()`。
    public func finishRefresh() {
        state.refreshing = false
        refreshingBinding?.wrappedValue = false
    }

    /// 仓库既有名。
    public func endRefresh() { finishRefresh() }

    /// 对应上游 `handleScroll(scrollTop)`。
    public func handleScroll(_ value: CGFloat) {
        state.scrollTop = value
        onScrollHandler?(value)
    }

    /// 对应上游 `scrollTo(top)` / `scrollToTop()`。
    public func scrollTo(_ top: CGFloat) { state.scrollTop = max(top, 0) }

    public func scrollToTop() { scrollTo(0) }

    // MARK: - 事件

    public func onRefresh(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onRefreshHandler = action
        return copy
    }

    /// 对应上游 `scroll` 事件。
    public func onScroll(_ action: @escaping (CGFloat) -> Void) -> Self {
        var copy = self
        copy.onScrollHandler = action
        return copy
    }

    public var body: some View {
        UPVirtualList(listData: listData,
                      itemHeight: itemHeight,
                      height: height,
                      buffer: buffer,
                      keyField: keyField,
                      scrollTop: Binding(get: { state.scrollTop }, set: { handleScroll($0) }),
                      key: keyProvider) { item in
            content(item, listData.firstIndex(where: { keyOf($0) == keyOf(item) }) ?? 0)
        }
        .refreshable {
            guard refresherEnabled else { return }
            beginRefresh()
        }
    }

    private func keyOf(_ item: Item) -> String {
        keyProvider?(item) ?? String(describing: item)
    }
}

public extension UPRefreshVirtualList where Item == Int, Content == EmptyView {
    /// 仓库既有签名：只关心刷新状态时用。
    init(refreshing: Bool = false,
         refresherEnabled: Bool = true,
         refresherThreshold: CGFloat = UPRefreshVirtualList.threshold) {
        self.init(listData: [],
                  refresherEnabled: refresherEnabled,
                  refresherThreshold: refresherThreshold,
                  initialRefreshing: refreshing,
                  content: { _, _ in EmptyView() })
    }

    init(refreshing: Binding<Bool>,
         refresherEnabled: Bool = true,
         refresherThreshold: CGFloat = UPRefreshVirtualList.threshold) {
        self.init(listData: [],
                  refreshing: refreshing,
                  refresherEnabled: refresherEnabled,
                  refresherThreshold: refresherThreshold,
                  content: { _, _ in EmptyView() })
    }
}
