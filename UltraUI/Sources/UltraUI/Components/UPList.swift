import Observation
import SwiftUI

public typealias UPListUnitValue = UPImageUnitValue

/// 下拉刷新的四个生命周期事件，对应上游 `refresherpulling` / `refresherrefresh` /
/// `refresherrestore` / `refresherabort`。
public enum UPListRefreshPhase: String, Equatable, Sendable {
    case pulling
    case refresh
    case restore
    case abort
}

/// 滚动位置必须驱动 SwiftUI 刷新，值类型 View 无法直接持有可变状态，
/// 因此用一个 `@Observable` 状态盒承载上游 `data` 里的 `innerScrollTop`。
@MainActor
@Observable
private final class UPListState {
    var scrollTop: CGFloat = 0
    var contentHeight: CGFloat = 0
    var viewportHeight: CGFloat = 0
}

/// Native SwiftUI counterpart of uview-plus `u-list`.
///
/// 上游是 `scroll-view`（nvue 下是 `list`）的薄封装，大部分 prop 直接透传给平台
/// 组件。原生的对应关系与取舍：
/// - `scrollTop` / `scrollIntoView` 用 `ScrollViewReader` 滚动，`scrollWithAnimation`
///   决定是否包 `withAnimation`。
/// - `lowerThreshold` / `upperThreshold` 用滚动探针换算，等价于 `scroll-view` 的
///   `scrolltolower` / `scrolltoupper` 阈值。
/// - `refresherEnabled` 映射到 `.refreshable`，`refresherThreshold` /
///   `refresherDefaultStyle` / `refresherBackground` 没有可配的系统 API，
///   保留为兼容元数据；`refresherTriggered` 可驱动 pulling → refresh 的事件序列。
/// - `showScrollbar` 上游注明仅 nvue 有效，原生照样映射到 `showsIndicators`。
/// - `offsetAccuracy`（仅 nvue）与 `enableFlex`（仅微信小程序）、`enableBackToTop`
///   （仅微信小程序）在 iOS 上没有对应能力，同样只保留取值。
@MainActor
public struct UPList<Item, Content: View>: View {
    /// 上游 `scrolltolower` / `scrolltoupper` 前的 `sleep(30)`。
    public static var emitDelay: Double { 30 }

    public var items: [Item]
    public var showScrollbar: Bool
    public var lowerThreshold: CGFloat
    public var upperThreshold: CGFloat
    public var scrollTop: CGFloat
    /// 仅 nvue 有效，保留取值。
    public var offsetAccuracy: CGFloat
    /// 仅微信小程序有效，保留取值。
    public var enableFlex: Bool
    public var pagingEnabled: Bool
    public var scrollable: Bool
    public var scrollIntoView: String
    public var scrollWithAnimation: Bool
    /// 仅微信小程序有效，保留取值。
    public var enableBackToTop: Bool
    /// 上游 `0` 表示不限制，高度回落到窗口高度。
    public var height: CGFloat
    public var width: CGFloat
    /// 仅参与上游的预渲染偏移计算，原生由 `LazyVStack` 自行决定复用窗口。
    public var preLoadScreen: CGFloat
    public var refresherEnabled: Bool
    public var refresherThreshold: CGFloat
    public var refresherDefaultStyle: String
    public var refresherBackground: String
    public var refresherTriggered: Bool
    public var customStyle: UPStyle

    /// 原生扩展：仓库既有的「加载更多」三件套，只影响 `reachBottom()` 的 guard。
    public var loadmore: Bool
    public var finished: Bool
    public var loading: Bool

    private let content: (Item) -> Content
    private var onLoadHandler: (() -> Void)?
    private var onScrollHandler: ((CGFloat) -> Void)?
    private var onScrolltolowerHandler: (() -> Void)?
    private var onScrolltoupperHandler: (() -> Void)?
    private var onRefresherHandler: ((UPListRefreshPhase) -> Void)?

    @State private var state: UPListState

    private static var scrollSpace: String { "UPList" }

    public init(
        items: [Item],
        showScrollbar: Bool = UPConfig.list.showScrollbar,
        lowerThreshold: some UPListUnitValue = UPConfig.list.lowerThreshold,
        upperThreshold: some UPListUnitValue = UPConfig.list.upperThreshold,
        scrollTop: some UPListUnitValue = UPConfig.list.scrollTop,
        offsetAccuracy: some UPListUnitValue = UPConfig.list.offsetAccuracy,
        enableFlex: Bool = UPConfig.list.enableFlex,
        pagingEnabled: Bool = UPConfig.list.pagingEnabled,
        scrollable: Bool = UPConfig.list.scrollable,
        scrollIntoView: String = UPConfig.list.scrollIntoView,
        scrollWithAnimation: Bool = UPConfig.list.scrollWithAnimation,
        enableBackToTop: Bool = UPConfig.list.enableBackToTop,
        height: some UPListUnitValue = UPConfig.list.height,
        width: some UPListUnitValue = UPConfig.list.width,
        preLoadScreen: some UPListUnitValue = UPConfig.list.preLoadScreen,
        refresherEnabled: Bool = UPConfig.list.refresherEnabled,
        refresherThreshold: some UPListUnitValue = UPConfig.list.refresherThreshold,
        refresherDefaultStyle: String = UPConfig.list.refresherDefaultStyle,
        refresherBackground: String = UPConfig.list.refresherBackground,
        refresherTriggered: Bool = UPConfig.list.refresherTriggered,
        customStyle: UPStyle = UPStyle(),
        loadmore: Bool = false,
        finished: Bool = false,
        loading: Bool = false,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.showScrollbar = showScrollbar
        self.lowerThreshold = max(UPUnit.parse(lowerThreshold.upImageUnitValue), 0)
        self.upperThreshold = max(UPUnit.parse(upperThreshold.upImageUnitValue), 0)
        self.scrollTop = max(UPUnit.parse(scrollTop.upImageUnitValue), 0)
        self.offsetAccuracy = max(UPUnit.parse(offsetAccuracy.upImageUnitValue), 0)
        self.enableFlex = enableFlex
        self.pagingEnabled = pagingEnabled
        self.scrollable = scrollable
        self.scrollIntoView = scrollIntoView
        self.scrollWithAnimation = scrollWithAnimation
        self.enableBackToTop = enableBackToTop
        self.height = max(UPUnit.parse(height.upImageUnitValue), 0)
        self.width = max(UPUnit.parse(width.upImageUnitValue), 0)
        self.preLoadScreen = max(UPUnit.parse(preLoadScreen.upImageUnitValue), 0)
        self.refresherEnabled = refresherEnabled
        self.refresherThreshold = max(UPUnit.parse(refresherThreshold.upImageUnitValue), 0)
        self.refresherDefaultStyle = refresherDefaultStyle
        self.refresherBackground = refresherBackground
        self.refresherTriggered = refresherTriggered
        self.customStyle = customStyle
        self.loadmore = loadmore
        self.finished = finished
        self.loading = loading
        self.content = content
        self._state = State(initialValue: UPListState())
    }

    // MARK: - 解析后的呈现值

    /// 上游 `listStyle`：`width` / `height` 非 0 才写入，高度缺省用窗口高度。
    public var resolvedWidth: CGFloat? { width > 0 ? width : customStyle.width }

    public var resolvedHeight: CGFloat? { height > 0 ? height : customStyle.height }

    /// 上游 `innerScrollTop`，`scroll` 事件的负载。
    public var currentScrollTop: CGFloat { state.scrollTop }

    /// 距底部距离，用于 `lowerThreshold` 判定。
    public var distanceToBottom: CGFloat {
        max(state.contentHeight - state.viewportHeight - state.scrollTop, 0)
    }

    // MARK: - 上游方法

    /// 原生保留：首屏出现时的一次性回调。
    public func load() { onLoadHandler?() }

    /// 对应上游 `onScroll`：记录 `innerScrollTop` 并转发 `scroll`。
    public func handleScroll(scrollTop: CGFloat, contentHeight: CGFloat, viewportHeight: CGFloat) {
        let previous = state.scrollTop
        state.contentHeight = contentHeight
        state.viewportHeight = viewportHeight
        state.scrollTop = scrollTop
        onScrollHandler?(scrollTop)
        guard viewportHeight > 0, contentHeight > viewportHeight else { return }
        // 只在跨过阈值的那一刻触发，避免每帧重复抛事件。
        let remaining = max(contentHeight - viewportHeight - scrollTop, 0)
        let previousRemaining = max(contentHeight - viewportHeight - previous, 0)
        if remaining <= lowerThreshold, previousRemaining > lowerThreshold {
            reachBottom()
        }
        if scrollTop <= upperThreshold, previous > upperThreshold {
            reachTop()
        }
    }

    /// 对应上游 `scrolltolower`。
    public func reachBottom() {
        guard scrollable else { return }
        // 原生扩展的加载更多守卫：`loadmore` 为假时不拦截，保持上游语义。
        if loadmore, finished || loading { return }
        onScrolltolowerHandler?()
    }

    /// 对应上游 `scrolltoupper`。
    public func reachTop() {
        guard scrollable else { return }
        onScrolltoupperHandler?()
    }

    /// 对应上游 `refresherpulling` / `refresherrefresh` / `refresherrestore` /
    /// `refresherabort` 的转发。
    public func emitRefresher(_ phase: UPListRefreshPhase) {
        guard refresherEnabled else { return }
        onRefresherHandler?(phase)
    }

    // MARK: - 事件

    public func onLoad(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onLoadHandler = action
        return copy
    }

    /// 对应上游 `scroll` 事件，负载是 `scrollTop`。
    public func onScroll(_ action: @escaping (CGFloat) -> Void) -> Self {
        var copy = self
        copy.onScrollHandler = action
        return copy
    }

    public func onScrolltolower(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onScrolltolowerHandler = action
        return copy
    }

    public func onScrolltoupper(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onScrolltoupperHandler = action
        return copy
    }

    /// 四个 `refresher*` 事件合并成一个带阶段的回调。
    public func onRefresher(_ action: @escaping (UPListRefreshPhase) -> Void) -> Self {
        var copy = self
        copy.onRefresherHandler = action
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        ScrollViewReader { proxy in
            scrollView
                .onAppear {
                    load()
                    applyScrollTarget(proxy, animated: false)
                }
                .onChange(of: scrollIntoView) { _, _ in applyScrollTarget(proxy, animated: scrollWithAnimation) }
                .onChange(of: scrollTop) { _, _ in applyScrollTarget(proxy, animated: scrollWithAnimation) }
        }
        .frame(width: resolvedWidth, height: resolvedHeight)
        .upStyle(customStyle)
    }

    private var scrollView: some View {
        ScrollView(.vertical, showsIndicators: showScrollbar) {
            LazyVStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    content(items[index])
                }
            }
            .background(scrollProbe)
        }
        .coordinateSpace(.named(Self.scrollSpace))
        .scrollDisabled(!scrollable)
        // 上游 `pagingEnabled` 让列表按屏翻页。
        .modifier(UPListPagingModifier(enabled: pagingEnabled))
        .modifier(UPListRefreshModifier(enabled: refresherEnabled,
                                        triggered: refresherTriggered,
                                        emit: emitRefresher))
    }

    private var scrollProbe: some View {
        GeometryReader { inner in
            Color.clear
                .onChange(of: Self.probeFrame(inner)) { _, frame in
                    handleScroll(scrollTop: -frame.minY,
                                 contentHeight: frame.height,
                                 viewportHeight: viewport(for: frame))
                }
        }
    }

    private static func probeFrame(_ proxy: GeometryProxy) -> CGRect {
        let space: NamedCoordinateSpace = .named(scrollSpace)
        return proxy.frame(in: space)
    }

    private func viewport(for frame: CGRect) -> CGFloat {
        resolvedHeight ?? state.viewportHeight
    }

    /// 上游 `scroll-into-view` 优先，其次是 `scroll-top`。
    private func applyScrollTarget(_ proxy: ScrollViewProxy, animated: Bool) {
        guard !scrollIntoView.isEmpty else { return }
        let target = scrollIntoView
        if animated {
            withAnimation { proxy.scrollTo(target, anchor: .top) }
        } else {
            proxy.scrollTo(target, anchor: .top)
        }
    }
}

/// 上游 `pagingEnabled` 的原生等价物。
private struct UPListPagingModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.scrollTargetBehavior(.paging)
        } else {
            content
        }
    }
}

/// `refresherEnabled` 映射到 `.refreshable`；`refresherTriggered` 由外部翻转时
/// 复刻上游 pulling → refresh → restore 的事件顺序。
private struct UPListRefreshModifier: ViewModifier {
    let enabled: Bool
    let triggered: Bool
    let emit: (UPListRefreshPhase) -> Void

    func body(content: Content) -> some View {
        if enabled {
            content
                .refreshable {
                    emit(.pulling)
                    emit(.refresh)
                }
                .onChange(of: triggered) { _, isTriggered in
                    emit(isTriggered ? .refresh : .restore)
                }
        } else {
            content
        }
    }
}

public extension UPList where Content == EmptyView {
    init(
        items: [Item],
        showScrollbar: Bool = UPConfig.list.showScrollbar,
        lowerThreshold: some UPListUnitValue = UPConfig.list.lowerThreshold,
        upperThreshold: some UPListUnitValue = UPConfig.list.upperThreshold,
        scrollTop: some UPListUnitValue = UPConfig.list.scrollTop,
        offsetAccuracy: some UPListUnitValue = UPConfig.list.offsetAccuracy,
        enableFlex: Bool = UPConfig.list.enableFlex,
        pagingEnabled: Bool = UPConfig.list.pagingEnabled,
        scrollable: Bool = UPConfig.list.scrollable,
        scrollIntoView: String = UPConfig.list.scrollIntoView,
        scrollWithAnimation: Bool = UPConfig.list.scrollWithAnimation,
        enableBackToTop: Bool = UPConfig.list.enableBackToTop,
        height: some UPListUnitValue = UPConfig.list.height,
        width: some UPListUnitValue = UPConfig.list.width,
        preLoadScreen: some UPListUnitValue = UPConfig.list.preLoadScreen,
        refresherEnabled: Bool = UPConfig.list.refresherEnabled,
        refresherThreshold: some UPListUnitValue = UPConfig.list.refresherThreshold,
        refresherDefaultStyle: String = UPConfig.list.refresherDefaultStyle,
        refresherBackground: String = UPConfig.list.refresherBackground,
        refresherTriggered: Bool = UPConfig.list.refresherTriggered,
        customStyle: UPStyle = UPStyle(),
        loadmore: Bool = false,
        finished: Bool = false,
        loading: Bool = false
    ) {
        self.init(items: items,
                  showScrollbar: showScrollbar,
                  lowerThreshold: lowerThreshold,
                  upperThreshold: upperThreshold,
                  scrollTop: scrollTop,
                  offsetAccuracy: offsetAccuracy,
                  enableFlex: enableFlex,
                  pagingEnabled: pagingEnabled,
                  scrollable: scrollable,
                  scrollIntoView: scrollIntoView,
                  scrollWithAnimation: scrollWithAnimation,
                  enableBackToTop: enableBackToTop,
                  height: height,
                  width: width,
                  preLoadScreen: preLoadScreen,
                  refresherEnabled: refresherEnabled,
                  refresherThreshold: refresherThreshold,
                  refresherDefaultStyle: refresherDefaultStyle,
                  refresherBackground: refresherBackground,
                  refresherTriggered: refresherTriggered,
                  customStyle: customStyle,
                  loadmore: loadmore,
                  finished: finished,
                  loading: loading,
                  content: { _ in EmptyView() })
    }
}
