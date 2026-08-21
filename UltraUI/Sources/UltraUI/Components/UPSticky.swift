import SwiftUI

public struct UPStickyChange: Equatable, Sendable {
    public var index: String
    public var isFixed: Bool
    public init(index: String, isFixed: Bool) { self.index = index; self.isFixed = isFixed }
}

@MainActor
public struct UPSticky<Content: View>: View {
    public var offsetTop: CGFloat
    public var customNavHeight: CGFloat
    public var disabled: Bool
    public var bgColor: String
    public var zIndex: CGFloat
    public var index: String
    private let content: Content
    private var onFixedHandler: ((UPStickyChange) -> Void)?

    public init(offsetTop: some UPImageUnitValue = 0, customNavHeight: some UPImageUnitValue = 0,
                disabled: Bool = false, bgColor: String = "transparent", zIndex: some UPImageUnitValue = 0,
                index: String = "", @ViewBuilder content: () -> Content) {
        self.offsetTop = UPUnit.parse(offsetTop.upImageUnitValue)
        self.customNavHeight = UPUnit.parse(customNavHeight.upImageUnitValue)
        self.disabled = disabled; self.bgColor = bgColor; self.zIndex = UPUnit.parse(zIndex.upImageUnitValue)
        self.index = index; self.content = content()
    }
    public var pinOffset: CGFloat { offsetTop + customNavHeight }
    public func isFixed(minY: CGFloat) -> Bool { !disabled && minY <= pinOffset }
    public var body: some View { content.background(UPColor.parse(bgColor)).zIndex(zIndex) }
    public func report(minY: CGFloat) { onFixedHandler?(UPStickyChange(index: index, isFixed: isFixed(minY: minY))) }
    public func onFixed(_ action: @escaping (UPStickyChange) -> Void) -> Self { var copy = self; copy.onFixedHandler = action; return copy }
}
public extension UPSticky where Content == EmptyView {
    init(offsetTop: some UPImageUnitValue = 0, customNavHeight: some UPImageUnitValue = 0,
         disabled: Bool = false, bgColor: String = "transparent", zIndex: some UPImageUnitValue = 0,
         index: String = "") {
        self.init(offsetTop: offsetTop, customNavHeight: customNavHeight, disabled: disabled,
                  bgColor: bgColor, zIndex: zIndex, index: index, content: EmptyView.init)
    }
}
