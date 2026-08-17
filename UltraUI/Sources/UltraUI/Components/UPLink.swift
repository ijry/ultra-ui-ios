import SwiftUI

/// Semantic alias for the `String | Number` `fontSize` prop accepted by `u-link`.
public typealias UPLinkUnitValue = UPCheckboxUnitValue

/// Native SwiftUI counterpart of uview-plus `u-link`.
///
/// The component accepts the upstream prop names. `mpTips` is retained as
/// metadata because copying a URL is a mini-program-specific behavior; on
/// Apple platforms `href` is opened through SwiftUI's native `openURL` action.
public struct UPLink: View {
    var color: String
    var fontSize: Double
    var underLine: Bool
    var href: String
    var mpTips: String
    var lineColor: String
    var text: String
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no CSS-class analogue.
    var customClass: String
    var customStyle: UPStyle
    var onTap: (() -> Void)?
    var onClick: (() -> Void)?

    @Environment(\.upTheme) private var theme
    @Environment(\.openURL) private var openURL

    /// Creates a native link while accepting the upstream `String | Number`
    /// `fontSize` input and shared mixin style/class props.
    public init(color: String = UPConfig.link.color,
                fontSize: some UPLinkUnitValue = UPConfig.link.fontSize,
                underLine: Bool = UPConfig.link.underLine,
                href: String = UPConfig.link.href,
                mpTips: String = UPConfig.link.mpTips,
                lineColor: String = UPConfig.link.lineColor,
                text: String = UPConfig.link.text,
                customClass: String = UPConfig.link.customClass,
                customStyle: UPStyle = UPConfig.link.customStyle,
                onTap: (() -> Void)? = nil,
                onClick: (() -> Void)? = nil) {
        self.color = color
        self.fontSize = Double(UPUnit.parse(fontSize.upCheckboxUnitValue))
        self.underLine = underLine
        self.href = href
        self.mpTips = mpTips
        self.lineColor = lineColor
        self.text = text
        self.customClass = customClass
        self.customStyle = customStyle
        self.onTap = onTap
        self.onClick = onClick
    }

    public var body: some View {
        Text(text)
            .font(.system(size: max(CGFloat(fontSize), 1)))
            .foregroundStyle(UPColor.parse(color, theme: theme))
            .underline(underLine, color: UPColor.parse(lineColor.isEmpty ? color : lineColor, theme: theme))
            .lineSpacing(2)
            .upStyle(customStyle)
            .contentShape(Rectangle())
            .onTapGesture(perform: openLink)
    }

    private func openLink() {
        if !href.isEmpty, let url = URL(string: href) {
            openURL(url)
        }
        onTap?()
        onClick?()
    }
}
