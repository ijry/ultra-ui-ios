import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-navbar`.
///
/// 上游模板结构：可选占位块（`fixed && placeholder`）→ `u-navbar__inner`（`fixed`
/// 时固定顶部、`zIndex 11`，背景取 `navbarBgColor`）→ 内含 `u-status-bar`
/// （`safeAreaInsetTop`）与 `u-navbar__content`（左区绝对左、居中标题、右区绝对右）。
/// 颜色回落照抄上游：`navbarBgColor` 空时 `--up-navbar-bg-color`（暗 `#1c1c1e` /
/// 亮 `#ffffff`）；`navbarTitleColor`/`navbarLeftIconColor` 空时 `--up-main-color`
/// （mainColor `#303133`）；`navbarRightColor` 恒为 mainColor。右区仅在
/// `$slots.right || rightIcon || rightText` 时渲染。左区点击先抛 `leftClick`，
/// 无拦截器时按 `autoBack` 触发 `navigateBack`（原生交由 `onNavigateBack` 宿主实现）。
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
    private var onNavigateBackHandler: (() -> Void)?
    private var leftSlot: AnyView?
    private var centerSlot: AnyView?
    private var rightSlot: AnyView?

    @Environment(\.colorScheme) private var colorScheme

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

    /// 上游 mainColor（`$u.color.mainColor`）。
    private static let mainColor = "#303133"

    /// 上游 `navbarBgColor`：`bgColor` 优先，否则 `--up-navbar-bg-color`
    /// （暗 `#1c1c1e` / 亮 `#ffffff`）。此处只解析亮色回落，暗色在 `body` 中随
    /// `colorScheme` 切换。
    public var resolvedBgColorValue: String { bgColor.isEmpty ? "#ffffff" : bgColor }
    /// 上游 `navbarTitleColor`：`titleColor` 优先，否则 mainColor。
    public var resolvedTitleColorValue: String { titleColor.isEmpty ? Self.mainColor : titleColor }
    /// 上游 `navbarLeftIconColor`：`leftIconColor` 优先，否则 mainColor。
    public var resolvedLeftIconColorValue: String { leftIconColor.isEmpty ? Self.mainColor : leftIconColor }
    /// 上游 `navbarRightColor`：恒为 mainColor。
    public var resolvedRightColorValue: String { Self.mainColor }
    /// 上游状态栏色 `statusBarBgColor` 为空回落 `bgColor`（再回落 navbarBgColor）。
    public var resolvedStatusBarColorValue: String {
        statusBarBgColor.isEmpty ? resolvedBgColorValue : statusBarBgColor
    }

    /// 上游右区 `v-if="$slots.right || rightIcon || rightText"`。
    public var showsRightArea: Bool { rightSlot != nil || !rightIcon.isEmpty || !rightText.isEmpty }
    /// 上游占位块 `v-if="fixed && placeholder"`。
    public var showsPlaceholder: Bool { fixed && placeholder }

    public var hasLeftSlot: Bool { leftSlot != nil }
    public var hasCenterSlot: Bool { centerSlot != nil }
    public var hasRightSlot: Bool { rightSlot != nil }

    private func bgColorForScheme() -> String {
        if !bgColor.isEmpty { return bgColor }
        return colorScheme == .dark ? "#1c1c1e" : "#ffffff"
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
        }
    }

    @ViewBuilder private var content: some View {
        // 上游占位块：高 = getPx(height) + statusBarHeight，此处交由 status bar
        // 自适应，仅补 navbar 内容高度那部分。
        if showsPlaceholder {
            Color.clear.frame(height: resolvedHeight)
        }
        VStack(spacing: 0) {
            if safeAreaInsetTop {
                UPStatusBar(bgColor: resolvedStatusBarColorValue)
            }
            ZStack {
                // 居中标题
                if let centerSlot {
                    centerSlot
                } else {
                    Text(title)
                        .font(.system(size: 16))
                        .lineLimit(1)
                        .frame(width: resolvedTitleWidth)
                        .foregroundStyle(UPColor.parse(resolvedTitleColorValue))
                        .upStyle(titleStyle)
                }
                HStack(spacing: 0) {
                    // 左区（绝对左）
                    Button(action: triggerLeftClick) {
                        if let leftSlot {
                            leftSlot
                        } else {
                            HStack(spacing: 3) {
                                if !leftIcon.isEmpty {
                                    UPIcon(name: leftIcon, color: resolvedLeftIconColorValue, size: leftIconSize)
                                }
                                if !leftText.isEmpty {
                                    Text(leftText)
                                        .font(.system(size: 15))
                                        .foregroundStyle(UPColor.parse(resolvedLeftIconColorValue))
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    // 右区（绝对右），仅在有内容/插槽时渲染
                    if showsRightArea {
                        Button(action: triggerRightClick) {
                            if let rightSlot {
                                rightSlot
                            } else {
                                HStack(spacing: 3) {
                                    if !rightIcon.isEmpty {
                                        UPIcon(name: rightIcon, color: resolvedRightColorValue, size: "20px")
                                    }
                                    if !rightText.isEmpty {
                                        Text(rightText)
                                            .font(.system(size: 15))
                                            .foregroundStyle(UPColor.parse(resolvedRightColorValue))
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 13)
            }
            .frame(height: resolvedHeight)
            .overlay(alignment: .bottom) { if border { Divider() } }
        }
        .background(UPColor.parse(bgColorForScheme()))
    }

    public func onLeftClick(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onLeftClickHandler = action; return copy }
    public func onRightClick(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onRightClickHandler = action; return copy }
    /// 对应上游 `leftClick` 无拦截器时的 `uni.navigateBack()`，页面栈交宿主实现。
    public func onNavigateBack(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onNavigateBackHandler = action; return copy }

    /// 对应上游具名插槽 `left`。
    public func left<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self; copy.leftSlot = AnyView(builder()); return copy
    }
    /// 对应上游具名插槽 `center`。
    public func center<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self; copy.centerSlot = AnyView(builder()); return copy
    }
    /// 对应上游具名插槽 `right`。
    public func right<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self; copy.rightSlot = AnyView(builder()); return copy
    }

    /// 上游 `leftClick`：先 `$emit('leftClick')`，无拦截器时按 `autoBack` 触发返回。
    public func triggerLeftClick() {
        onLeftClickHandler?()
        if autoBack { onNavigateBackHandler?() }
    }
    public func triggerRightClick() { onRightClickHandler?() }
}

@MainActor
/// Native SwiftUI counterpart of uview-plus `u-navbar-mini`.
///
/// 上游是「返回箭头 + 竖分割线 + 首页图标」的胶囊：左半区点击抛 `leftClick`（`autoBack`
/// 为真时再 `navigateBack`），右半区点击抛 `homeClick`（`homeUrl` 非空时 `reLaunch`）。
/// 页面栈跳转是宿主的事，原生只抛事件并把 `autoBack` / `homeUrl` 原样保留。
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
    private var onHomeClickHandler: (() -> Void)?
    private var leftSlot: AnyView?
    private var centerSlot: AnyView?

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

    public var body: some View {
        HStack(spacing: 0) {
            Button(action: triggerLeftClick) {
                if let leftSlot {
                    leftSlot
                } else {
                    UPIcon(name: leftIcon, color: iconColor, size: iconSize)
                }
            }
            .buttonStyle(.plain)

            // 上游 `<view style="padding: 10px 10px"><up-line direction="col" .../></view>`。
            UPLine(color: "#fff", length: "16px", direction: "col")
                .padding(10)

            Button(action: triggerHomeClick) {
                if let centerSlot {
                    centerSlot
                } else {
                    UPIcon(name: "home", color: iconColor, size: iconSize)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(height: resolvedHeight)
        .background(UPColor.parse(bgColor))
        .clipShape(Capsule())
    }

    /// 对应上游 `leftClick` 事件。上游随后按 `autoBack` 调 `navigateBack`，
    /// 页面栈由宿主掌握，原生只抛事件。
    public func onLeftClick(_ action: @escaping () -> Void) -> Self {
        var copy = self; copy.onLeftClickHandler = action; return copy
    }

    /// 对应上游 `homeClick` 事件。
    ///
    /// 照抄上游一处反直觉行为：`homeClick()` 只在 `homeUrl` 非空时 `reLaunch`，
    /// 但 `homeClick` 这个事件名虽在 `emits` 里声明，上游方法体里其实从未 `$emit`。
    /// 原生按 `emits` 声明补上事件，让宿主能接住点击。
    public func onHomeClick(_ action: @escaping () -> Void) -> Self {
        var copy = self; copy.onHomeClickHandler = action; return copy
    }

    /// 对应上游具名插槽 `left`。
    public func left<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self; copy.leftSlot = AnyView(builder()); return copy
    }

    /// 对应上游具名插槽 `center`。
    public func center<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> Self {
        var copy = self; copy.centerSlot = AnyView(builder()); return copy
    }

    public var hasLeftSlot: Bool { leftSlot != nil }
    public var hasCenterSlot: Bool { centerSlot != nil }

    public func triggerLeftClick() { onLeftClickHandler?() }
    public func triggerHomeClick() { onHomeClickHandler?() }
}
