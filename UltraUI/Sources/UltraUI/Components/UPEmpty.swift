import SwiftUI

/// A string-or-number value accepted by uview-plus `u-empty` unit props.
public protocol UPEmptyUnitValue {
    var upEmptyUnitValue: String { get }
}

extension String: UPEmptyUnitValue {
    public var upEmptyUnitValue: String { self }
}

extension Int: UPEmptyUnitValue {
    public var upEmptyUnitValue: String { String(self) }
}

extension Double: UPEmptyUnitValue {
    public var upEmptyUnitValue: String {
        guard isFinite else { return "0" }
        return rounded() == self ? String(Int(self)) : String(self)
    }
}

extension Float: UPEmptyUnitValue {
    public var upEmptyUnitValue: String { Double(self).upEmptyUnitValue }
}

extension CGFloat: UPEmptyUnitValue {
    public var upEmptyUnitValue: String { Double(self).upEmptyUnitValue }
}

/// Native SwiftUI counterpart of uview-plus `u-empty`.
///
/// Property names and defaults mirror the checked-in uview-plus source. An
/// `icon` containing `/` uses the image branch; otherwise the component uses
/// uview-plus's built-in `empty-{mode}` glyph convention (with `message`
/// mapped to `chat`). The default trailing `ViewBuilder` corresponds to the
/// component's default Vue slot.
///
/// Although the uview-plus documentation lists `click` and `close`, its actual
/// `u-empty.vue` implementation does not emit either event or render a close
/// control. This replica therefore intentionally exposes no synthetic event
/// callbacks for them.
public struct UPEmpty<Content: View>: View {
    var icon: String
    var text: String
    var textColor: String
    var textSize: String
    var iconColor: String
    var iconSize: String
    var mode: String
    var width: String
    var height: String
    var show: Bool
    var marginTop: String
    var customStyle: UPStyle

    private let content: Content

    @Environment(\.upTheme) private var theme

    /// Creates an empty-state view with a SwiftUI equivalent of the default
    /// uview-plus slot.
    public init(
        icon: String = UPConfig.empty.icon,
        text: String = UPConfig.empty.text,
        textColor: String = UPConfig.empty.textColor,
        textSize: some UPEmptyUnitValue = UPConfig.empty.textSize,
        iconColor: String = UPConfig.empty.iconColor,
        iconSize: some UPEmptyUnitValue = UPConfig.empty.iconSize,
        mode: String = UPConfig.empty.mode,
        width: some UPEmptyUnitValue = UPConfig.empty.width,
        height: some UPEmptyUnitValue = UPConfig.empty.height,
        show: Bool = UPConfig.empty.show,
        marginTop: some UPEmptyUnitValue = UPConfig.empty.marginTop,
        customStyle: UPStyle = UPStyle(),
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.text = text
        self.textColor = textColor
        self.textSize = textSize.upEmptyUnitValue
        self.iconColor = iconColor
        self.iconSize = iconSize.upEmptyUnitValue
        self.mode = mode
        self.width = width.upEmptyUnitValue
        self.height = height.upEmptyUnitValue
        self.show = show
        self.marginTop = marginTop.upEmptyUnitValue
        self.customStyle = customStyle
        self.content = content()
    }

    /// Matches uview-plus's `isSrc` computed property.
    var usesImageIcon: Bool {
        icon.contains("/")
    }

    /// The built-in uview-plus icon name selected for the current mode.
    var iconName: String {
        mode == "message" ? "chat" : "empty-\(mode)"
    }

    /// Uses explicit `text` before the mode-specific uview-plus default text.
    var displayText: String {
        text.isEmpty ? Self.defaultText(for: mode) : text
    }

    var resolvedTextSize: CGFloat { UPUnit.parse(textSize) }
    var resolvedIconSize: CGFloat { UPUnit.parse(iconSize) }
    var resolvedWidth: CGFloat { UPUnit.parse(width) }
    var resolvedHeight: CGFloat { UPUnit.parse(height) }
    var resolvedMarginTop: CGFloat { UPUnit.parse(marginTop) }

    @ViewBuilder
    public var body: some View {
        if show {
            VStack(spacing: 0) {
                iconContent

                Text(displayText)
                    .font(.system(size: max(resolvedTextSize, 0)))
                    .foregroundStyle(UPColor.parse(textColor, theme: theme))
                    .multilineTextAlignment(.center)
                    .padding(.top, UPUnit.rpx(20))

                content
            }
            .frame(maxWidth: .infinity)
            .padding(.top, resolvedMarginTop)
            .upStyle(customStyle)
        }
    }

    @ViewBuilder
    private var iconContent: some View {
        if usesImageIcon {
            // uview-plus renders this branch with image mode `widthFix`.
            UPImage(src: icon, mode: "widthFix", width: width, height: height)
        } else {
            UPIcon(
                name: iconName,
                color: iconColor,
                size: iconSize,
                top: "14"
            )
        }
    }

    private static func defaultText(for mode: String) -> String {
        switch mode {
        case "car": return "购物车为空"
        case "page": return "页面不存在"
        case "search": return "没有搜索结果"
        case "address": return "没有收货地址"
        case "wifi": return "没有WiFi"
        case "order": return "订单为空"
        case "coupon": return "没有优惠券"
        case "favor": return "暂无收藏"
        case "permission": return "无权限"
        case "history": return "无历史记录"
        case "news": return "无新闻列表"
        case "message": return "消息列表为空"
        case "list": return "列表为空"
        case "data": return "数据为空"
        case "comment": return "暂无评论"
        default: return ""
        }
    }

}

public extension UPEmpty where Content == EmptyView {
    /// Creates `u-empty` without default-slot content.
    init(
        icon: String = UPConfig.empty.icon,
        text: String = UPConfig.empty.text,
        textColor: String = UPConfig.empty.textColor,
        textSize: some UPEmptyUnitValue = UPConfig.empty.textSize,
        iconColor: String = UPConfig.empty.iconColor,
        iconSize: some UPEmptyUnitValue = UPConfig.empty.iconSize,
        mode: String = UPConfig.empty.mode,
        width: some UPEmptyUnitValue = UPConfig.empty.width,
        height: some UPEmptyUnitValue = UPConfig.empty.height,
        show: Bool = UPConfig.empty.show,
        marginTop: some UPEmptyUnitValue = UPConfig.empty.marginTop,
        customStyle: UPStyle = UPStyle()
    ) {
        self.init(
            icon: icon,
            text: text,
            textColor: textColor,
            textSize: textSize,
            iconColor: iconColor,
            iconSize: iconSize,
            mode: mode,
            width: width,
            height: height,
            show: show,
            marginTop: marginTop,
            customStyle: customStyle,
            content: { EmptyView() }
        )
    }

}
