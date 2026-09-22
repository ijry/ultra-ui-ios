import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-pull-refresh` scroll props.
public typealias UPPullRefreshUnitValue = UPImageUnitValue

/// 上游 `data.refreshStatus` 的三个取值。
public enum UPPullRefreshStatus: String, Equatable, Sendable {
    case pull
    case release
    case refreshing
}

/// 上游 `loadmoreProps`：透传给内嵌 `u-loadmore` 的配置。
///
/// 上游默认值只带 `status: 'loadmore'`，其余键交给 `u-loadmore` 自己的默认值。
public struct UPPullRefreshLoadmoreProps: Equatable, Sendable {
    public var status: String
    public var loadmoreText: String
    public var loadingText: String
    public var nomoreText: String

    public init(status: String = UPConfig.pullRefresh.loadmoreStatus,
                loadmoreText: String = UPConfig.loadmore.loadmoreText,
                loadingText: String = UPConfig.loadmore.loadingText,
                nomoreText: String = UPConfig.loadmore.nomoreText) {
        self.status = status
        self.loadmoreText = loadmoreText
        self.loadingText = loadingText
        self.nomoreText = nomoreText
    }
}

/// 对应上游 `data`：刷新标记、状态、下拉距离与内容位移。
@MainActor
@Observable
private final class UPPullRefreshState {
    var isRefreshing: Bool
    var refreshStatus: UPPullRefreshStatus = .pull
    var refreshDistance: CGFloat = 0
    var contentTranslateY: CGFloat = 0
    var touching = false
    var startY: CGFloat = 0
    var currentY: CGFloat = 0

    init(_ refreshing: Bool) {
        self.isRefreshing = refreshing
        if refreshing { refreshStatus = .refreshing }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-pull-refresh`.
///
/// 上游自己接 `touchstart` / `touchmove` / `touchend`：下拉位移乘 `damping` 后夹到
/// `maxDistance`，越过 `threshold` 就把状态从 `pull` 切到 `release`，松手时越过阈值触发
/// `refresh`，否则回弹。原生保留同一套状态机与三个状态插槽，手势换成 `DragGesture`，
/// 并保留仓库既有的 `refreshable` 形态作为系统下拉入口。
@MainActor
public struct UPPullRefresh<Content: View>: View {
    /// 上游 `threshold`：触发刷新的下拉距离。
    public var threshold: CGFloat
    /// 上游 `damping`：下拉位移的阻尼系数。
    public var damping: CGFloat
    /// 上游 `maxDistance`：最大下拉距离。
    public var maxDistance: CGFloat
    /// 上游 `showLoadmore`：是否在内容末尾放 `u-loadmore`。
    public var showLoadmore: Bool
    /// 上游 `loadmoreProps`。
    public var loadmoreProps: UPPullRefreshLoadmoreProps
    /// 上游 `useScrollView`：是否用 `scroll-view` 包内容。
    public var useScrollView: Bool
    /// 上游 `enableBackToTop`。
    public var enableBackToTop: Bool
    /// 上游 `lowerThreshold`：距底多远算触底。
    public var lowerThreshold: CGFloat
    /// 上游 `scrollTop`。
    public var scrollTop: CGFloat
    /// 仓库既有属性：关掉后不响应下拉。
    public var enabled: Bool

    private var binding: Binding<Bool>?
    private let state: UPPullRefreshState
    private let content: Content
    private var onRefreshHandler: (() -> Void)?
    private var onLoadmoreHandler: (() -> Void)?
    private var onScrollHandler: ((CGFloat) -> Void)?
    private var pullSlot: ((CGFloat, CGFloat) -> AnyView)?
    private var releaseSlot: ((CGFloat, CGFloat) -> AnyView)?
    private var refreshingSlot: AnyView?

    @Environment(\.upTheme) private var theme

    private static var scrollSpace: String { "UPPullRefresh" }

    fileprivate init(binding: Binding<Bool>?,
                     refreshing: Bool,
                     threshold: CGFloat,
                     damping: CGFloat,
                     maxDistance: CGFloat,
                     showLoadmore: Bool,
                     loadmoreProps: UPPullRefreshLoadmoreProps,
                     useScrollView: Bool,
                     enableBackToTop: Bool,
                     lowerThreshold: CGFloat,
                     scrollTop: CGFloat,
                     enabled: Bool,
                     content: Content) {
        self.binding = binding
        self.state = UPPullRefreshState(refreshing)
        self.threshold = max(threshold, 0)
        self.damping = damping
        self.maxDistance = max(maxDistance, 0)
        self.showLoadmore = showLoadmore
        self.loadmoreProps = loadmoreProps
        self.useScrollView = useScrollView
        self.enableBackToTop = enableBackToTop
        self.lowerThreshold = max(lowerThreshold, 0)
        self.scrollTop = scrollTop
        self.enabled = enabled
        self.content = content
    }

    /// 与上游 `props` 对齐的初始化器。
    public init(refreshing: Binding<Bool>,
                threshold: CGFloat = UPConfig.pullRefresh.threshold,
                damping: CGFloat = UPConfig.pullRefresh.damping,
                maxDistance: CGFloat = UPConfig.pullRefresh.maxDistance,
                showLoadmore: Bool = UPConfig.pullRefresh.showLoadmore,
                loadmoreProps: UPPullRefreshLoadmoreProps = UPPullRefreshLoadmoreProps(),
                useScrollView: Bool = UPConfig.pullRefresh.useScrollView,
                enableBackToTop: Bool = UPConfig.pullRefresh.enableBackToTop,
                lowerThreshold: any UPPullRefreshUnitValue = UPConfig.pullRefresh.lowerThreshold,
                scrollTop: any UPPullRefreshUnitValue = UPConfig.pullRefresh.scrollTop,
                enabled: Bool = true,
                @ViewBuilder content: () -> Content) {
        self.init(binding: refreshing,
                  refreshing: refreshing.wrappedValue,
                  threshold: threshold,
                  damping: damping,
                  maxDistance: maxDistance,
                  showLoadmore: showLoadmore,
                  loadmoreProps: loadmoreProps,
                  useScrollView: useScrollView,
                  enableBackToTop: enableBackToTop,
                  lowerThreshold: UPUnit.parse(lowerThreshold.upImageUnitValue),
                  scrollTop: UPUnit.parse(scrollTop.upImageUnitValue),
                  enabled: enabled,
                  content: content())
    }

    /// 仓库既有签名：`refreshing` 是普通 Bool，状态存在组件内部。
    public init(refreshing: Bool = UPConfig.pullRefresh.refreshing,
                threshold: CGFloat = 45,
                enabled: Bool = true,
                @ViewBuilder content: () -> Content) {
        self.init(binding: nil,
                  refreshing: refreshing,
                  threshold: threshold,
                  damping: UPConfig.pullRefresh.damping,
                  maxDistance: UPConfig.pullRefresh.maxDistance,
                  showLoadmore: UPConfig.pullRefresh.showLoadmore,
                  loadmoreProps: UPPullRefreshLoadmoreProps(),
                  useScrollView: UPConfig.pullRefresh.useScrollView,
                  enableBackToTop: UPConfig.pullRefresh.enableBackToTop,
                  lowerThreshold: UPConfig.pullRefresh.lowerThreshold,
                  scrollTop: UPConfig.pullRefresh.scrollTop,
                  enabled: enabled,
                  content: content())
    }

    // MARK: - 解析后的呈现值

    /// 上游 `isRefreshing`，有绑定时以绑定为准。
    public var refreshing: Bool { binding?.wrappedValue ?? state.isRefreshing }
    /// 上游 `refreshStatus`。
    public var refreshStatus: UPPullRefreshStatus { state.refreshStatus }
    /// 上游 `refreshDistance`。
    public var refreshDistance: CGFloat { state.refreshDistance }
    /// 上游 `contentTranslateY`。
    public var contentTranslateY: CGFloat { state.contentTranslateY }

    // MARK: - 上游 methods

    /// 上游 `onTouchStart`。
    public func onTouchStart(pageY: CGFloat) {
        guard !refreshing else { return }
        state.touching = true
        state.startY = pageY
        state.currentY = pageY
        state.refreshStatus = .pull
    }

    /// 上游 `onTouchMove`：位移乘阻尼、夹到 `maxDistance`，越过阈值切 `release`。
    ///
    /// 照抄上游：`isScrollViewAtTop()` 直接 `return true`（注释里也承认这是简化），
    /// 所以内容已经滚下去时下拉依然会被当成刷新手势。
    public func onTouchMove(pageY: CGFloat) {
        guard state.touching, !refreshing else { return }
        state.currentY = pageY
        let diff = state.currentY - state.startY
        guard diff > 0, isScrollViewAtTop() else { return }
        state.refreshDistance = min(diff * damping, maxDistance)
        state.contentTranslateY = state.refreshDistance
        state.refreshStatus = state.refreshDistance >= threshold ? .release : .pull
    }

    /// 上游 `onTouchEnd`：越过阈值触发刷新，否则回弹。
    public func onTouchEnd() {
        guard state.touching else { return }
        state.touching = false
        if state.refreshDistance >= threshold, !refreshing {
            startRefresh()
            onRefreshHandler?()
        } else {
            resetRefresh()
        }
    }

    /// 上游 `startRefresh()`。
    public func startRefresh() {
        state.isRefreshing = true
        binding?.wrappedValue = true
        state.refreshStatus = .refreshing
        state.refreshDistance = threshold
        state.contentTranslateY = threshold
    }

    /// 上游 `finishRefresh()`。
    public func finishRefresh() {
        state.isRefreshing = false
        binding?.wrappedValue = false
        state.refreshStatus = .pull
        resetRefresh()
    }

    /// 上游 `resetRefresh()`。
    public func resetRefresh() {
        state.refreshDistance = 0
        state.contentTranslateY = 0
    }

    /// 照抄上游 `isScrollViewAtTop()`：注释说「简单起见直接返回 true」。
    public func isScrollViewAtTop() -> Bool { true }

    /// 上游 `handleScroll(e)`：原样抛 `scroll`，负载这里收敛成 scrollTop。
    public func handleScroll(scrollTop: CGFloat) {
        onScrollHandler?(scrollTop)
    }

    /// 上游 `handleScrollToLower(e)`：只有 `showLoadmore` 且状态是 `loadmore` 时才抛。
    public func handleScrollToLower() {
        guard showLoadmore, loadmoreProps.status == "loadmore" else { return }
        onLoadmoreHandler?()
    }

    // MARK: - 仓库既有 API

    @discardableResult
    public func pull(distance: CGFloat) -> Bool {
        guard enabled, distance >= threshold else { return false }
        beginRefresh()
        return refreshing
    }

    public func beginRefresh() {
        guard enabled, !refreshing else { return }
        startRefresh()
        onRefreshHandler?()
    }

    public func endRefresh() { finishRefresh() }

    // MARK: - 事件

    /// 对应上游 `refresh` 事件。
    public func onRefresh(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onRefreshHandler = action
        return copy
    }

    /// 对应上游 `loadmore` 事件。
    public func onLoadmore(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onLoadmoreHandler = action
        return copy
    }

    /// 对应上游 `scroll` 事件，负载收敛成 scrollTop。
    public func onScroll(_ action: @escaping (CGFloat) -> Void) -> Self {
        var copy = self
        copy.onScrollHandler = action
        return copy
    }

    // MARK: - 插槽

    /// 对应上游作用域插槽 `pull`，参数是 `distance` 与 `threshold`。
    public func pullContent<Slot: View>(@ViewBuilder _ builder: @escaping (CGFloat, CGFloat) -> Slot) -> Self {
        var copy = self
        copy.pullSlot = { AnyView(builder($0, $1)) }
        return copy
    }

    /// 对应上游作用域插槽 `release`，参数同 `pull`。
    public func releaseContent<Slot: View>(@ViewBuilder _ builder: @escaping (CGFloat, CGFloat) -> Slot) -> Self {
        var copy = self
        copy.releaseSlot = { AnyView(builder($0, $1)) }
        return copy
    }

    /// 对应上游具名插槽 `refreshing`。
    public func refreshingContent<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self
        copy.refreshingSlot = AnyView(builder())
        return copy
    }

    public var hasPullSlot: Bool { pullSlot != nil }
    public var hasReleaseSlot: Bool { releaseSlot != nil }
    public var hasRefreshingSlot: Bool { refreshingSlot != nil }
}

// MARK: - 视图

public extension UPPullRefresh {
    var body: some View {
        ZStack(alignment: .top) {
            // 上游 `.refresh-area { position: absolute; top: 0 }`，高度就是下拉距离。
            refreshArea
                .frame(height: state.refreshDistance)
                .clipped()

            contentWrapper
                .offset(y: state.contentTranslateY)
        }
        // 上游 `.u-pull-refresh { position: relative; overflow: hidden }`。
        .clipped()
        .simultaneousGesture(dragGesture)
        .animation(.easeOut(duration: 0.2), value: state.contentTranslateY)
        .onChange(of: refreshing) { _, value in
            // 上游 `watch.refreshing`：翻真走 startRefresh，翻假走 finishRefresh。
            if value { startRefresh() } else { finishRefresh() }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard enabled else { return }
                if !state.touching { onTouchStart(pageY: value.startLocation.y) }
                onTouchMove(pageY: value.location.y)
            }
            .onEnded { _ in
                guard enabled else { return }
                onTouchEnd()
            }
    }

    @ViewBuilder
    private var refreshArea: some View {
        switch state.refreshStatus {
        case .pull:
            if let pullSlot {
                pullSlot(state.refreshDistance, threshold)
            } else {
                defaultRefreshRow(icon: UPConfig.pullRefresh.pullIcon,
                                  text: UPConfig.pullRefresh.pullText)
            }
        case .release:
            if let releaseSlot {
                releaseSlot(state.refreshDistance, threshold)
            } else {
                defaultRefreshRow(icon: UPConfig.pullRefresh.releaseIcon,
                                  text: UPConfig.pullRefresh.releaseText)
            }
        case .refreshing:
            if let refreshingSlot {
                refreshingSlot
            } else {
                // 上游默认插槽用一个自绘的 .spinner，原生换成 UPLoadingIcon。
                HStack(spacing: 8) {
                    UPLoadingIcon(show: true, size: 26)
                    Text(UPConfig.pullRefresh.refreshingText + "...")
                        .font(.system(size: 14))
                        .foregroundStyle(UPColor.parse(UPConfig.pullRefresh.textColor, theme: theme))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func defaultRefreshRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            UPIcon(name: icon,
                   color: UPConfig.pullRefresh.textColor,
                   size: UPConfig.pullRefresh.iconSize)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(UPColor.parse(UPConfig.pullRefresh.textColor, theme: theme))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var contentWrapper: some View {
        if useScrollView {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    content
                    loadmoreView
                }
                .background(scrollProbe)
            }
            .coordinateSpace(.named(Self.scrollSpace))
            // 上游 `refreshable` 不在模板里，这是仓库既有的系统下拉入口。
            .refreshable { beginRefresh() }
            .scrollDismissesKeyboard(.interactively)
        } else {
            VStack(spacing: 0) {
                content
                loadmoreView
            }
        }
    }

    @ViewBuilder
    private var loadmoreView: some View {
        if showLoadmore {
            UPLoadmore(status: loadmoreProps.status,
                       loadmoreText: loadmoreProps.loadmoreText,
                       loadingText: loadmoreProps.loadingText,
                       nomoreText: loadmoreProps.nomoreText) {
                handleScrollToLower()
            }
        }
    }

    /// 上游 `@scroll` / `@scrolltolower`：原生用滚动探针换算，触底判定用 `lowerThreshold`。
    private var scrollProbe: some View {
        GeometryReader { proxy in
            Color.clear
                .onChange(of: Self.probeOffset(proxy)) { _, offset in
                    handleScroll(scrollTop: offset)
                }
        }
    }

    private static func probeOffset(_ proxy: GeometryProxy) -> CGFloat {
        let space: NamedCoordinateSpace = .named(scrollSpace)
        return -proxy.frame(in: space).minY
    }
}

public extension UPPullRefresh where Content == EmptyView {
    init(refreshing: Binding<Bool>,
         threshold: CGFloat = UPConfig.pullRefresh.threshold,
         damping: CGFloat = UPConfig.pullRefresh.damping,
         maxDistance: CGFloat = UPConfig.pullRefresh.maxDistance,
         showLoadmore: Bool = UPConfig.pullRefresh.showLoadmore,
         loadmoreProps: UPPullRefreshLoadmoreProps = UPPullRefreshLoadmoreProps(),
         useScrollView: Bool = UPConfig.pullRefresh.useScrollView,
         enableBackToTop: Bool = UPConfig.pullRefresh.enableBackToTop,
         lowerThreshold: any UPPullRefreshUnitValue = UPConfig.pullRefresh.lowerThreshold,
         scrollTop: any UPPullRefreshUnitValue = UPConfig.pullRefresh.scrollTop,
         enabled: Bool = true) {
        self.init(refreshing: refreshing,
                  threshold: threshold,
                  damping: damping,
                  maxDistance: maxDistance,
                  showLoadmore: showLoadmore,
                  loadmoreProps: loadmoreProps,
                  useScrollView: useScrollView,
                  enableBackToTop: enableBackToTop,
                  lowerThreshold: lowerThreshold,
                  scrollTop: scrollTop,
                  enabled: enabled,
                  content: EmptyView.init)
    }

    init(refreshing: Bool = UPConfig.pullRefresh.refreshing,
         threshold: CGFloat = 45,
         enabled: Bool = true) {
        self.init(refreshing: refreshing,
                  threshold: threshold,
                  enabled: enabled,
                  content: EmptyView.init)
    }
}
