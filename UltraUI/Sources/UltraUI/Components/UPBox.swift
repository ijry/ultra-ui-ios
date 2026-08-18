import SwiftUI

/// String-or-number props accepted by uview-plus `u-box` dimensions and text.
public protocol UPBoxUnitValue {
    var upBoxUnitValue: String { get }
}

extension String: UPBoxUnitValue {
    public var upBoxUnitValue: String { self }
}

extension Int: UPBoxUnitValue {
    public var upBoxUnitValue: String { String(self) }
}

extension Double: UPBoxUnitValue {
    public var upBoxUnitValue: String {
        guard isFinite else { return "0" }
        return rounded() == self ? String(Int(self)) : String(self)
    }
}

extension Float: UPBoxUnitValue {
    public var upBoxUnitValue: String { Double(self).upBoxUnitValue }
}

extension CGFloat: UPBoxUnitValue {
    public var upBoxUnitValue: String { Double(self).upBoxUnitValue }
}

extension Bool: UPBoxUnitValue {
    public var upBoxUnitValue: String { description }
}

/// SwiftUI counterpart of uview-plus `u-box`.
///
/// The component contains one full-height panel on the left and two equal
/// panels stacked on the right. The named `left`, `rightTop`, and
/// `rightBottom` slots are represented by the corresponding SwiftUI builder
/// parameters; when omitted, the upstream icon-and-title defaults are used.
public struct UPBox: View {
    public var bgColors: [String]
    public var height: String
    public var borderRadius: String
    public var gap: String
    public var leftIcon: String
    public var leftTitle: String
    public var rightTopIcon: String
    public var rightTopTitle: String
    public var rightBottomIcon: String
    public var rightBottomTitle: String
    public var customClass: String
    public var customStyle: UPStyle

    private var leftSlot: AnyView?
    private var rightTopSlot: AnyView?
    private var rightBottomSlot: AnyView?

    @Environment(\.upTheme) private var theme

    public var hasLeftSlot: Bool { leftSlot != nil }
    public var hasRightTopSlot: Bool { rightTopSlot != nil }
    public var hasRightBottomSlot: Bool { rightBottomSlot != nil }

    public var resolvedHeight: Double {
        Double(UPUnit.parse(height))
    }

    public var resolvedBorderRadius: Double {
        Double(UPUnit.parse(borderRadius))
    }

    public var resolvedGap: Double {
        Double(UPUnit.parse(gap))
    }

    /// Keeps exactly three panel colors, filling omitted values from defaults.
    public static func normalizedColors(_ colors: [String]) -> [String] {
        let defaults = UPBoxConfig.bgColors
        return (0..<3).map { index in
            guard index < colors.count, !colors[index].isEmpty else {
                return defaults[index]
            }
            return colors[index]
        }
    }

    public init(
        bgColors: [String] = UPConfig.box.bgColors,
        height: some UPBoxUnitValue = UPConfig.box.height,
        borderRadius: some UPBoxUnitValue = UPConfig.box.borderRadius,
        gap: some UPBoxUnitValue = UPConfig.box.gap,
        leftIcon: String = UPConfig.box.leftIcon,
        leftTitle: some UPBoxUnitValue = UPConfig.box.leftTitle,
        rightTopIcon: String = UPConfig.box.rightTopIcon,
        rightTopTitle: some UPBoxUnitValue = UPConfig.box.rightTopTitle,
        rightBottomIcon: String = UPConfig.box.rightBottomIcon,
        rightBottomTitle: some UPBoxUnitValue = UPConfig.box.rightBottomTitle,
        customClass: String = UPConfig.box.customClass,
        customStyle: UPStyle = UPConfig.box.customStyle
    ) {
        self.bgColors = Self.normalizedColors(bgColors)
        self.height = height.upBoxUnitValue
        self.borderRadius = borderRadius.upBoxUnitValue
        self.gap = gap.upBoxUnitValue
        self.leftIcon = leftIcon
        self.leftTitle = leftTitle.upBoxUnitValue
        self.rightTopIcon = rightTopIcon
        self.rightTopTitle = rightTopTitle.upBoxUnitValue
        self.rightBottomIcon = rightBottomIcon
        self.rightBottomTitle = rightBottomTitle.upBoxUnitValue
        self.customClass = customClass
        self.customStyle = customStyle
        self.leftSlot = nil
        self.rightTopSlot = nil
        self.rightBottomSlot = nil
    }

    public init<Left: View, RightTop: View, RightBottom: View>(
        bgColors: [String] = UPConfig.box.bgColors,
        height: some UPBoxUnitValue = UPConfig.box.height,
        borderRadius: some UPBoxUnitValue = UPConfig.box.borderRadius,
        gap: some UPBoxUnitValue = UPConfig.box.gap,
        leftIcon: String = UPConfig.box.leftIcon,
        leftTitle: some UPBoxUnitValue = UPConfig.box.leftTitle,
        rightTopIcon: String = UPConfig.box.rightTopIcon,
        rightTopTitle: some UPBoxUnitValue = UPConfig.box.rightTopTitle,
        rightBottomIcon: String = UPConfig.box.rightBottomIcon,
        rightBottomTitle: some UPBoxUnitValue = UPConfig.box.rightBottomTitle,
        customClass: String = UPConfig.box.customClass,
        customStyle: UPStyle = UPConfig.box.customStyle,
        @ViewBuilder left: () -> Left,
        @ViewBuilder rightTop: () -> RightTop,
        @ViewBuilder rightBottom: () -> RightBottom
    ) {
        self.init(
            bgColors: bgColors,
            height: height,
            borderRadius: borderRadius,
            gap: gap,
            leftIcon: leftIcon,
            leftTitle: leftTitle,
            rightTopIcon: rightTopIcon,
            rightTopTitle: rightTopTitle,
            rightBottomIcon: rightBottomIcon,
            rightBottomTitle: rightBottomTitle,
            customClass: customClass,
            customStyle: customStyle
        )
        self.leftSlot = AnyView(left())
        self.rightTopSlot = AnyView(rightTop())
        self.rightBottomSlot = AnyView(rightBottom())
    }

    public init<Left: View, RightTop: View>(
        bgColors: [String] = UPConfig.box.bgColors,
        height: some UPBoxUnitValue = UPConfig.box.height,
        borderRadius: some UPBoxUnitValue = UPConfig.box.borderRadius,
        gap: some UPBoxUnitValue = UPConfig.box.gap,
        leftIcon: String = UPConfig.box.leftIcon,
        leftTitle: some UPBoxUnitValue = UPConfig.box.leftTitle,
        rightTopIcon: String = UPConfig.box.rightTopIcon,
        rightTopTitle: some UPBoxUnitValue = UPConfig.box.rightTopTitle,
        rightBottomIcon: String = UPConfig.box.rightBottomIcon,
        rightBottomTitle: some UPBoxUnitValue = UPConfig.box.rightBottomTitle,
        customClass: String = UPConfig.box.customClass,
        customStyle: UPStyle = UPConfig.box.customStyle,
        @ViewBuilder left: () -> Left,
        @ViewBuilder rightTop: () -> RightTop
    ) {
        self.init(
            bgColors: bgColors,
            height: height,
            borderRadius: borderRadius,
            gap: gap,
            leftIcon: leftIcon,
            leftTitle: leftTitle,
            rightTopIcon: rightTopIcon,
            rightTopTitle: rightTopTitle,
            rightBottomIcon: rightBottomIcon,
            rightBottomTitle: rightBottomTitle,
            customClass: customClass,
            customStyle: customStyle
        )
        self.leftSlot = AnyView(left())
        self.rightTopSlot = AnyView(rightTop())
    }

    public init<Left: View, RightBottom: View>(
        bgColors: [String] = UPConfig.box.bgColors,
        height: some UPBoxUnitValue = UPConfig.box.height,
        borderRadius: some UPBoxUnitValue = UPConfig.box.borderRadius,
        gap: some UPBoxUnitValue = UPConfig.box.gap,
        leftIcon: String = UPConfig.box.leftIcon,
        leftTitle: some UPBoxUnitValue = UPConfig.box.leftTitle,
        rightTopIcon: String = UPConfig.box.rightTopIcon,
        rightTopTitle: some UPBoxUnitValue = UPConfig.box.rightTopTitle,
        rightBottomIcon: String = UPConfig.box.rightBottomIcon,
        rightBottomTitle: some UPBoxUnitValue = UPConfig.box.rightBottomTitle,
        customClass: String = UPConfig.box.customClass,
        customStyle: UPStyle = UPConfig.box.customStyle,
        @ViewBuilder left: () -> Left,
        @ViewBuilder rightBottom: () -> RightBottom
    ) {
        self.init(
            bgColors: bgColors,
            height: height,
            borderRadius: borderRadius,
            gap: gap,
            leftIcon: leftIcon,
            leftTitle: leftTitle,
            rightTopIcon: rightTopIcon,
            rightTopTitle: rightTopTitle,
            rightBottomIcon: rightBottomIcon,
            rightBottomTitle: rightBottomTitle,
            customClass: customClass,
            customStyle: customStyle
        )
        self.leftSlot = AnyView(left())
        self.rightBottomSlot = AnyView(rightBottom())
    }

    public init<RightTop: View, RightBottom: View>(
        bgColors: [String] = UPConfig.box.bgColors,
        height: some UPBoxUnitValue = UPConfig.box.height,
        borderRadius: some UPBoxUnitValue = UPConfig.box.borderRadius,
        gap: some UPBoxUnitValue = UPConfig.box.gap,
        leftIcon: String = UPConfig.box.leftIcon,
        leftTitle: some UPBoxUnitValue = UPConfig.box.leftTitle,
        rightTopIcon: String = UPConfig.box.rightTopIcon,
        rightTopTitle: some UPBoxUnitValue = UPConfig.box.rightTopTitle,
        rightBottomIcon: String = UPConfig.box.rightBottomIcon,
        rightBottomTitle: some UPBoxUnitValue = UPConfig.box.rightBottomTitle,
        customClass: String = UPConfig.box.customClass,
        customStyle: UPStyle = UPConfig.box.customStyle,
        @ViewBuilder rightTop: () -> RightTop,
        @ViewBuilder rightBottom: () -> RightBottom
    ) {
        self.init(
            bgColors: bgColors,
            height: height,
            borderRadius: borderRadius,
            gap: gap,
            leftIcon: leftIcon,
            leftTitle: leftTitle,
            rightTopIcon: rightTopIcon,
            rightTopTitle: rightTopTitle,
            rightBottomIcon: rightBottomIcon,
            rightBottomTitle: rightBottomTitle,
            customClass: customClass,
            customStyle: customStyle
        )
        self.rightTopSlot = AnyView(rightTop())
        self.rightBottomSlot = AnyView(rightBottom())
    }

    public init<Left: View>(
        bgColors: [String] = UPConfig.box.bgColors,
        height: some UPBoxUnitValue = UPConfig.box.height,
        borderRadius: some UPBoxUnitValue = UPConfig.box.borderRadius,
        gap: some UPBoxUnitValue = UPConfig.box.gap,
        leftIcon: String = UPConfig.box.leftIcon,
        leftTitle: some UPBoxUnitValue = UPConfig.box.leftTitle,
        rightTopIcon: String = UPConfig.box.rightTopIcon,
        rightTopTitle: some UPBoxUnitValue = UPConfig.box.rightTopTitle,
        rightBottomIcon: String = UPConfig.box.rightBottomIcon,
        rightBottomTitle: some UPBoxUnitValue = UPConfig.box.rightBottomTitle,
        customClass: String = UPConfig.box.customClass,
        customStyle: UPStyle = UPConfig.box.customStyle,
        @ViewBuilder left: () -> Left
    ) {
        self.init(
            bgColors: bgColors,
            height: height,
            borderRadius: borderRadius,
            gap: gap,
            leftIcon: leftIcon,
            leftTitle: leftTitle,
            rightTopIcon: rightTopIcon,
            rightTopTitle: rightTopTitle,
            rightBottomIcon: rightBottomIcon,
            rightBottomTitle: rightBottomTitle,
            customClass: customClass,
            customStyle: customStyle
        )
        self.leftSlot = AnyView(left())
    }

    public init<RightTop: View>(
        bgColors: [String] = UPConfig.box.bgColors,
        height: some UPBoxUnitValue = UPConfig.box.height,
        borderRadius: some UPBoxUnitValue = UPConfig.box.borderRadius,
        gap: some UPBoxUnitValue = UPConfig.box.gap,
        leftIcon: String = UPConfig.box.leftIcon,
        leftTitle: some UPBoxUnitValue = UPConfig.box.leftTitle,
        rightTopIcon: String = UPConfig.box.rightTopIcon,
        rightTopTitle: some UPBoxUnitValue = UPConfig.box.rightTopTitle,
        rightBottomIcon: String = UPConfig.box.rightBottomIcon,
        rightBottomTitle: some UPBoxUnitValue = UPConfig.box.rightBottomTitle,
        customClass: String = UPConfig.box.customClass,
        customStyle: UPStyle = UPConfig.box.customStyle,
        @ViewBuilder rightTop: () -> RightTop
    ) {
        self.init(
            bgColors: bgColors,
            height: height,
            borderRadius: borderRadius,
            gap: gap,
            leftIcon: leftIcon,
            leftTitle: leftTitle,
            rightTopIcon: rightTopIcon,
            rightTopTitle: rightTopTitle,
            rightBottomIcon: rightBottomIcon,
            rightBottomTitle: rightBottomTitle,
            customClass: customClass,
            customStyle: customStyle
        )
        self.rightTopSlot = AnyView(rightTop())
    }

    public init<RightBottom: View>(
        bgColors: [String] = UPConfig.box.bgColors,
        height: some UPBoxUnitValue = UPConfig.box.height,
        borderRadius: some UPBoxUnitValue = UPConfig.box.borderRadius,
        gap: some UPBoxUnitValue = UPConfig.box.gap,
        leftIcon: String = UPConfig.box.leftIcon,
        leftTitle: some UPBoxUnitValue = UPConfig.box.leftTitle,
        rightTopIcon: String = UPConfig.box.rightTopIcon,
        rightTopTitle: some UPBoxUnitValue = UPConfig.box.rightTopTitle,
        rightBottomIcon: String = UPConfig.box.rightBottomIcon,
        rightBottomTitle: some UPBoxUnitValue = UPConfig.box.rightBottomTitle,
        customClass: String = UPConfig.box.customClass,
        customStyle: UPStyle = UPConfig.box.customStyle,
        @ViewBuilder rightBottom: () -> RightBottom
    ) {
        self.init(
            bgColors: bgColors,
            height: height,
            borderRadius: borderRadius,
            gap: gap,
            leftIcon: leftIcon,
            leftTitle: leftTitle,
            rightTopIcon: rightTopIcon,
            rightTopTitle: rightTopTitle,
            rightBottomIcon: rightBottomIcon,
            rightBottomTitle: rightBottomTitle,
            customClass: customClass,
            customStyle: customStyle
        )
        self.rightBottomSlot = AnyView(rightBottom())
    }

    public var body: some View {
        let colors = Self.normalizedColors(bgColors)
        let spacing = CGFloat(resolvedGap)
        let radius = CGFloat(resolvedBorderRadius)

        return HStack(spacing: spacing) {
            panel(
                content: leftSlot ?? defaultPanel(icon: leftIcon, title: leftTitle, size: 16),
                color: colors[0],
                radius: radius
            )

            VStack(spacing: spacing) {
                panel(
                    content: rightTopSlot ?? defaultPanel(icon: rightTopIcon, title: rightTopTitle, size: 15),
                    color: colors[1],
                    radius: radius
                )
                panel(
                    content: rightBottomSlot ?? defaultPanel(icon: rightBottomIcon, title: rightBottomTitle, size: 15),
                    color: colors[2],
                    radius: radius
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: CGFloat(resolvedHeight))
        .upStyle(customStyle)
    }

    private func panel(content: AnyView, color: String, radius: CGFloat) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(UPColor.parse(color, theme: theme))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    private func defaultPanel(icon: String, title: String, size: CGFloat) -> AnyView {
        AnyView(
            HStack(spacing: 8) {
                if !icon.isEmpty {
                    UPIcon(name: icon, size: "36px")
                }
                Text(title)
                    .font(.system(size: size))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        )
    }
}
