import SwiftUI

@MainActor
public struct UPNavbar: View {
    public var safeAreaInsetTop: Bool
    public var placeholder: Bool
    public var fixed: Bool
    public var border: Bool
    public var leftIcon: String
    public var leftText: String
    public var rightText: String
    public var rightIcon: String
    public var title: String
    public var titleColor: String
    public var bgColor: String
    public var statusBarBgColor: String
    public var titleWidth: String
    public var height: String
    public var leftIconSize: String
    public var leftIconColor: String
    public var autoBack: Bool
    public var titleStyle: UPStyle
    private var onLeftClickHandler: (() -> Void)?
    private var onRightClickHandler: (() -> Void)?

    public init(
        safeAreaInsetTop: Bool = true, placeholder: Bool = false, fixed: Bool = true,
        border: Bool = false, leftIcon: String = "arrow-left", leftText: String = "",
        rightText: String = "", rightIcon: String = "", title: String = "",
        titleColor: String = "", bgColor: String = "", statusBarBgColor: String = "",
        titleWidth: some UPImageUnitValue = "400rpx", height: some UPImageUnitValue = "44px",
        leftIconSize: some UPImageUnitValue = 20, leftIconColor: String = "",
        autoBack: Bool = false, titleStyle: UPStyle = UPStyle()
    ) {
        self.safeAreaInsetTop = safeAreaInsetTop; self.placeholder = placeholder; self.fixed = fixed
        self.border = border; self.leftIcon = leftIcon; self.leftText = leftText; self.rightText = rightText
        self.rightIcon = rightIcon; self.title = title; self.titleColor = titleColor; self.bgColor = bgColor
        self.statusBarBgColor = statusBarBgColor; self.titleWidth = titleWidth.upImageUnitValue
        self.height = height.upImageUnitValue; self.leftIconSize = leftIconSize.upImageUnitValue
        self.leftIconColor = leftIconColor; self.autoBack = autoBack; self.titleStyle = titleStyle
    }

    public var resolvedHeight: CGFloat { UPUnit.parse(height) }
    public var resolvedTitleWidth: CGFloat { UPUnit.parse(titleWidth) }
    public var body: some View {
        HStack {
            Button(action: triggerLeftClick) { HStack { if !leftIcon.isEmpty { Image(systemName: "chevron.left") }; Text(leftText) } }
            Spacer()
            Text(title).lineLimit(1).frame(maxWidth: resolvedTitleWidth).upStyle(titleStyle)
                .foregroundStyle(UPColor.parse(titleColor.isEmpty ? "#303133" : titleColor))
            Spacer()
            Button(action: triggerRightClick) { HStack { Text(rightText); if !rightIcon.isEmpty { Image(systemName: rightIcon) } } }
        }
        .frame(height: resolvedHeight)
        .padding(.horizontal, 12)
        .background(UPColor.parse(bgColor.isEmpty ? "#ffffff" : bgColor))
        .overlay(alignment: .bottom) { if border { Divider() } }
    }
    public func onLeftClick(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onLeftClickHandler = action; return copy }
    public func onRightClick(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onRightClickHandler = action; return copy }
    public func triggerLeftClick() { onLeftClickHandler?() }
    public func triggerRightClick() { onRightClickHandler?() }
}

@MainActor
public struct UPNavbarMini: View {
    public var safeAreaInsetTop: Bool
    public var fixed: Bool
    public var leftIcon: String
    public var bgColor: String
    public var height: String
    public var iconSize: String
    public var iconColor: String
    public var autoBack: Bool
    public var homeUrl: String
    private var onLeftClickHandler: (() -> Void)?

    public init(safeAreaInsetTop: Bool = true, fixed: Bool = true, leftIcon: String = "arrow-leftward",
                bgColor: String = "rgba(0,0,0,.15)", height: some UPImageUnitValue = "32px",
                iconSize: some UPImageUnitValue = "20px", iconColor: String = "#fff",
                autoBack: Bool = true, homeUrl: String = "") {
        self.safeAreaInsetTop = safeAreaInsetTop; self.fixed = fixed; self.leftIcon = leftIcon
        self.bgColor = bgColor; self.height = height.upImageUnitValue; self.iconSize = iconSize.upImageUnitValue
        self.iconColor = iconColor; self.autoBack = autoBack; self.homeUrl = homeUrl
    }
    public var resolvedHeight: CGFloat { UPUnit.parse(height) }
    public var resolvedIconSize: CGFloat { UPUnit.parse(iconSize) }
    public var body: some View { Button(action: triggerLeftClick) { Image(systemName: "chevron.left").font(.system(size: resolvedIconSize)).foregroundStyle(UPColor.parse(iconColor)) }.frame(width: 48, height: resolvedHeight).background(UPColor.parse(bgColor)).clipShape(Capsule()) }
    public func onLeftClick(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onLeftClickHandler = action; return copy }
    public func triggerLeftClick() { onLeftClickHandler?() }
}
