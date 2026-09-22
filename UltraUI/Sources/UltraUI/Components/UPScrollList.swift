import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-scroll-list` unit props.
public typealias UPScrollListUnitValue = UPImageUnitValue

/// 对应上游 `data`：`scrollInfo`（滚动位置与内容宽度）与量出来的组件宽度。
@MainActor
@Observable
private final class UPScrollListState {
    /// 上游 `scrollInfo.scrollLeft`。
    var scrollLeft: CGFloat = 0
    /// 上游 `scrollInfo.scrollWidth`：内容总宽。
    var scrollWidth: CGFloat = 0
    /// 上游 `scrollWidth`（`getComponentWidth()` 量到的容器宽）。
    var componentWidth: CGFloat = 0
}

/// Native SwiftUI counterpart of uview-plus `u-scroll-list`.
///
/// 上游是「横向 scroll-view + 底部线型指示器」：滑块位移按
/// `scrollLeft / (scrollWidth - componentWidth) * (indicatorWidth - indicatorBarWidth)` 算，
/// 触达左右边界时分别抛 `left` / `right`。原生保留同一套比例算法与事件语义。
@MainActor
public struct UPScrollList<Content: View>: View {
    public var indicatorWidth: CGFloat
    public var indicatorBarWidth: CGFloat
    public var indicator: Bool
    public var indicatorColor: String
    public var indicatorActiveColor: String
    /// 上游 `indicatorStyle`：`String | Object`，可用 bottom / left / right 定位。
    public var indicatorStyle: UPStyle
    /// 仓库既有属性：内容总宽（上游从 scroll 事件的 `scrollWidth` 拿）。
    public var contentWidth: CGFloat
    /// 仓库既有属性：容器宽（上游 `getComponentWidth()` 量）。
    public var viewportWidth: CGFloat

    private let content: Content
    @State private var state: UPScrollListState
    private var onLeftHandler: (() -> Void)?
    private var onRightHandler: (() -> Void)?

    @Environment(\.upTheme) private var theme

    private static var scrollSpace: String { "UPScrollList" }

    /// 与上游 `props` 对齐的初始化器。
    public init(indicatorWidth: any UPScrollListUnitValue = UPConfig.scrollList.indicatorWidth,
                indicatorBarWidth: any UPScrollListUnitValue = UPConfig.scrollList.indicatorBarWidth,
                indicator: Bool = UPConfig.scrollList.indicator,
                indicatorColor: String = UPConfig.scrollList.indicatorColor,
                indicatorActiveColor: String = UPConfig.scrollList.indicatorActiveColor,
                indicatorStyle: UPStyle = UPStyle(),
                contentWidth: CGFloat = 0,
                viewportWidth: CGFloat = 0,
                @ViewBuilder content: () -> Content) {
        self.indicatorWidth = UPUnit.parse(indicatorWidth.upImageUnitValue)
        self.indicatorBarWidth = UPUnit.parse(indicatorBarWidth.upImageUnitValue)
        self.indicator = indicator
        self.indicatorColor = indicatorColor
        self.indicatorActiveColor = indicatorActiveColor
        self.indicatorStyle = indicatorStyle
        self.contentWidth = contentWidth
        self.viewportWidth = viewportWidth
        self.content = content()
        let state = UPScrollListState()
        state.scrollWidth = contentWidth
        state.componentWidth = viewportWidth
        self._state = State(initialValue: state)
    }

    // MARK: - 解析后的呈现值

    /// 上游 `scrollInfo.scrollLeft`。
    public var scrollLeft: CGFloat { state.scrollLeft }

    /// 上游 `barAllMoveWidth = indicatorWidth - indicatorBarWidth`。
    public var barTravel: CGFloat { max(indicatorWidth - indicatorBarWidth, 0) }

    /// 上游 `barStyle`：滑块的位移量。
    public func indicatorOffset(scrollOffset: CGFloat) -> CGFloat {
        let scrollable = max(resolvedContentWidth - resolvedViewportWidth, 0)
        guard scrollable > 0 else { return 0 }
        return min(max(scrollOffset / scrollable, 0), 1) * barTravel
    }

    private var resolvedContentWidth: CGFloat {
        state.scrollWidth > 0 ? state.scrollWidth : contentWidth
    }

    private var resolvedViewportWidth: CGFloat {
        state.componentWidth > 0 ? state.componentWidth : viewportWidth
    }

    // MARK: - 上游 methods

    /// 上游 `scrollHandler(e)`：记录滚动信息。
    public func scrollHandler(scrollLeft: CGFloat, scrollWidth: CGFloat? = nil) {
        state.scrollLeft = scrollLeft
        if let scrollWidth { state.scrollWidth = scrollWidth }
    }

    /// 上游 `scrolltoupperHandler()`：抛 `left` 并把 `scrollLeft` 归零。
    public func scrollToUpper() {
        onLeftHandler?()
        state.scrollLeft = 0
    }

    /// 上游 `scrolltolowerHandler()`：抛 `right`，再把 `scrollLeft` 设成
    /// `indicatorWidth - indicatorBarWidth`，靠 computed 把滑块推到最右。
    ///
    /// 照抄上游这处反直觉：这里塞的是「指示器坐标系」的值而不是真实滚动距离，
    /// 只是为了让上面那条比例公式算出满格位移。
    public func scrollToLower() {
        onRightHandler?()
        state.scrollLeft = barTravel
    }

    /// 仓库既有方法：按当前偏移决定是否触边。
    public func reportScroll(offset: CGFloat) {
        let maxOffset = max(resolvedContentWidth - resolvedViewportWidth, 0)
        state.scrollLeft = offset
        if offset <= 0 { onLeftHandler?() }
        if maxOffset > 0, offset >= maxOffset { onRightHandler?() }
    }

    /// 上游 `getComponentWidth()`。
    public func recordComponentWidth(_ width: CGFloat) {
        state.componentWidth = width
    }

    // MARK: - 事件

    /// 对应上游 `left` 事件。
    public func onLeft(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onLeftHandler = action
        return copy
    }

    /// 对应上游 `right` 事件。
    public func onRight(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onRightHandler = action
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) { content }
                    .background(scrollProbe)
            }
            .coordinateSpace(.named(Self.scrollSpace))

            if indicator { indicatorBar }
        }
        // 上游 `.u-scroll-list { padding-bottom: 10px }`。
        .padding(.bottom, UPConfig.scrollList.paddingBottom)
        .background(widthProbe)
    }

    /// 上游 `.__indicator__line` 里套一个 `.__bar`，两者都是 4pt 高的胶囊。
    private var indicatorBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(UPColor.parse(indicatorColor, theme: theme))
                .frame(width: indicatorWidth, height: UPConfig.scrollList.indicatorHeight)

            Capsule()
                .fill(UPColor.parse(indicatorActiveColor, theme: theme))
                .frame(width: indicatorBarWidth, height: UPConfig.scrollList.indicatorHeight)
                .offset(x: indicatorOffset(scrollOffset: state.scrollLeft))
        }
        .frame(width: indicatorWidth, height: UPConfig.scrollList.indicatorHeight)
        .padding(.top, UPConfig.scrollList.indicatorMarginTop)
        .upStyle(indicatorStyle)
    }

    private var scrollProbe: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { state.scrollWidth = proxy.size.width }
                .onChange(of: proxy.size.width) { _, value in state.scrollWidth = value }
                .onChange(of: Self.probeOffset(proxy)) { _, offset in
                    scrollHandler(scrollLeft: max(offset, 0))
                }
        }
    }

    private static func probeOffset(_ proxy: GeometryProxy) -> CGFloat {
        let space: NamedCoordinateSpace = .named(scrollSpace)
        return -proxy.frame(in: space).minX
    }

    private var widthProbe: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { recordComponentWidth(proxy.size.width) }
                .onChange(of: proxy.size.width) { _, value in recordComponentWidth(value) }
        }
    }
}

public extension UPScrollList where Content == EmptyView {
    init(indicatorWidth: any UPScrollListUnitValue = UPConfig.scrollList.indicatorWidth,
         indicatorBarWidth: any UPScrollListUnitValue = UPConfig.scrollList.indicatorBarWidth,
         indicator: Bool = UPConfig.scrollList.indicator,
         indicatorColor: String = UPConfig.scrollList.indicatorColor,
         indicatorActiveColor: String = UPConfig.scrollList.indicatorActiveColor,
         indicatorStyle: UPStyle = UPStyle(),
         contentWidth: CGFloat = 0,
         viewportWidth: CGFloat = 0) {
        self.init(indicatorWidth: indicatorWidth,
                  indicatorBarWidth: indicatorBarWidth,
                  indicator: indicator,
                  indicatorColor: indicatorColor,
                  indicatorActiveColor: indicatorActiveColor,
                  indicatorStyle: indicatorStyle,
                  contentWidth: contentWidth,
                  viewportWidth: viewportWidth,
                  content: EmptyView.init)
    }
}
