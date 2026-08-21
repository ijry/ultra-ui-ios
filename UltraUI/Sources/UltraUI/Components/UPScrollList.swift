import SwiftUI

@MainActor
public struct UPScrollList<Content: View>: View {
    public var indicatorWidth: CGFloat
    public var indicatorBarWidth: CGFloat
    public var indicator: Bool
    public var indicatorColor: String
    public var indicatorActiveColor: String
    public var indicatorStyle: UPStyle
    public var contentWidth: CGFloat
    public var viewportWidth: CGFloat
    private let content: Content
    private var onLeftHandler: (() -> Void)?
    private var onRightHandler: (() -> Void)?

    public init(indicatorWidth: some UPImageUnitValue = 50, indicatorBarWidth: some UPImageUnitValue = 20,
                indicator: Bool = true, indicatorColor: String = "#f2f2f2",
                indicatorActiveColor: String = "#3c9cff", indicatorStyle: UPStyle = UPStyle(),
                contentWidth: CGFloat = 0, viewportWidth: CGFloat = 0,
                @ViewBuilder content: () -> Content) {
        self.indicatorWidth = UPUnit.parse(indicatorWidth.upImageUnitValue)
        self.indicatorBarWidth = UPUnit.parse(indicatorBarWidth.upImageUnitValue)
        self.indicator = indicator; self.indicatorColor = indicatorColor
        self.indicatorActiveColor = indicatorActiveColor; self.indicatorStyle = indicatorStyle
        self.contentWidth = contentWidth; self.viewportWidth = viewportWidth; self.content = content()
    }
    public var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) { content }
            if indicator { ZStack(alignment: .leading) { Capsule().fill(UPColor.parse(indicatorColor)); Capsule().fill(UPColor.parse(indicatorActiveColor)).frame(width: indicatorBarWidth) }.frame(width: indicatorWidth, height: 4).upStyle(indicatorStyle) }
        }
    }
    public func indicatorOffset(scrollOffset: CGFloat) -> CGFloat {
        let scrollable = max(contentWidth - viewportWidth, 0)
        guard scrollable > 0 else { return 0 }
        let travel = max(indicatorWidth - indicatorBarWidth, 0)
        return min(max(scrollOffset / scrollable, 0), 1) * travel
    }
    public func reportScroll(offset: CGFloat) {
        let maxOffset = max(contentWidth - viewportWidth, 0)
        if offset <= 0 { onLeftHandler?() }
        if maxOffset > 0, offset >= maxOffset { onRightHandler?() }
    }
    public func onLeft(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onLeftHandler = action; return copy }
    public func onRight(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onRightHandler = action; return copy }
}
public extension UPScrollList where Content == EmptyView {
    init(indicatorWidth: some UPImageUnitValue = 50, indicatorBarWidth: some UPImageUnitValue = 20,
         indicator: Bool = true, indicatorColor: String = "#f2f2f2", indicatorActiveColor: String = "#3c9cff",
         indicatorStyle: UPStyle = UPStyle(), contentWidth: CGFloat = 0, viewportWidth: CGFloat = 0) {
        self.init(indicatorWidth: indicatorWidth, indicatorBarWidth: indicatorBarWidth, indicator: indicator,
                  indicatorColor: indicatorColor, indicatorActiveColor: indicatorActiveColor,
                  indicatorStyle: indicatorStyle, contentWidth: contentWidth, viewportWidth: viewportWidth,
                  content: EmptyView.init)
    }
}
