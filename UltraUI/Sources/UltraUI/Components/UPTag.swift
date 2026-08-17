import Foundation
import SwiftUI

/// Semantic alias for the `String | Number` `text` prop accepted by
/// uview-plus `u-tag`.
public typealias UPTagTextValue = UPCheckboxTextValue

/// Typed payload carried by uview-plus `u-tag` `click` and `close` events.
public typealias UPTagName = UPCellName

/// Semantic alias for the `String | Number` `name` prop accepted by
/// uview-plus `u-tag`.
public typealias UPTagNameValue = UPCellNameValue

/// Values accepted by uview-plus `u-tag`'s `Boolean | String` `disabled` prop.
/// String inputs preserve JavaScript truthiness: only the empty string is false.
public protocol UPTagDisabledValue {
    var upTagDisabledValue: Bool { get }
}

extension Bool: UPTagDisabledValue {
    public var upTagDisabledValue: Bool { self }
}

extension String: UPTagDisabledValue {
    public var upTagDisabledValue: Bool { !isEmpty }
}

/// Numeric values accepted by uview-plus `u-tag`'s `autoBgColor` prop.
public protocol UPTagAutoBgColorValue {
    var upTagAutoBgColorValue: Double { get }
}

public extension UPTagAutoBgColorValue where Self: BinaryInteger {
    var upTagAutoBgColorValue: Double {
        let value = Double(self)
        return value.isFinite ? value : 0
    }
}

extension Int: UPTagAutoBgColorValue {}
extension Int8: UPTagAutoBgColorValue {}
extension Int16: UPTagAutoBgColorValue {}
extension Int32: UPTagAutoBgColorValue {}
extension Int64: UPTagAutoBgColorValue {}
extension UInt: UPTagAutoBgColorValue {}
extension UInt8: UPTagAutoBgColorValue {}
extension UInt16: UPTagAutoBgColorValue {}
extension UInt32: UPTagAutoBgColorValue {}
extension UInt64: UPTagAutoBgColorValue {}

public extension UPTagAutoBgColorValue where Self: BinaryFloatingPoint {
    var upTagAutoBgColorValue: Double {
        guard isFinite else { return 0 }
        let value = Double(self)
        return value.isFinite ? value : 0
    }
}

extension Double: UPTagAutoBgColorValue {}
extension Float: UPTagAutoBgColorValue {}
extension CGFloat: UPTagAutoBgColorValue {}

/// Native SwiftUI counterpart of uview-plus `u-tag`.
///
/// Public prop names and defaults mirror uview-plus. The caller owns `show`,
/// just as Vue owns the `show` prop after receiving the upstream `close` event.
public struct UPTag: View {
    var type: String
    var disabled: Bool
    var size: String
    var shape: String
    var text: String
    var bgColor: String
    var color: String
    var borderColor: String
    var closeColor: String
    var name: UPTagName
    var plainFill: Bool
    var plain: Bool
    var closable: Bool
    var show: Bool
    var icon: String
    var iconColor: String
    var textSize: String
    var height: String
    var padding: String
    var borderRadius: String
    var autoBgColor: Double
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no CSS-class analogue.
    var customClass: String
    var customStyle: UPStyle
    private var onTapHandler: (() -> Void)?
    private var onClickHandler: ((UPTagName) -> Void)?
    private var onCloseHandler: ((UPTagName) -> Void)?

    private var defaultSlotContent: AnyView?
    private var iconSlotContent: AnyView?
    private var contentSlotContent: AnyView?

    var hasDefaultSlot: Bool { defaultSlotContent != nil }
    var hasIconSlot: Bool { iconSlotContent != nil }
    var hasContentSlot: Bool { contentSlotContent != nil }

    @Environment(\.upTheme) private var theme

    public init(type: String = UPConfig.tag.type,
                disabled: some UPTagDisabledValue = UPConfig.tag.disabled,
                size: String = UPConfig.tag.size,
                shape: String = UPConfig.tag.shape,
                text: some UPTagTextValue = UPConfig.tag.text,
                bgColor: String = UPConfig.tag.bgColor,
                color: String = UPConfig.tag.color,
                borderColor: String = UPConfig.tag.borderColor,
                closeColor: String = UPConfig.tag.closeColor,
                name: some UPTagNameValue = UPConfig.tag.name,
                plainFill: Bool = UPConfig.tag.plainFill,
                plain: Bool = UPConfig.tag.plain,
                closable: Bool = UPConfig.tag.closable,
                show: Bool = UPConfig.tag.show,
                icon: String = UPConfig.tag.icon,
                iconColor: String = UPConfig.tag.iconColor,
                textSize: String = UPConfig.tag.textSize,
                height: String = UPConfig.tag.height,
                padding: String = UPConfig.tag.padding,
                borderRadius: String = UPConfig.tag.borderRadius,
                autoBgColor: some UPTagAutoBgColorValue = UPConfig.tag.autoBgColor,
                customClass: String = UPConfig.tag.customClass,
                customStyle: UPStyle = UPConfig.tag.customStyle,
                onTap: (() -> Void)? = nil,
                onClick: ((UPTagName) -> Void)? = nil,
                onClose: ((UPTagName) -> Void)? = nil) {
        self.type = type
        self.disabled = disabled.upTagDisabledValue
        self.size = size
        self.shape = shape
        self.text = text.upCheckboxTextValue
        self.bgColor = bgColor
        self.color = color
        self.borderColor = borderColor
        self.closeColor = closeColor
        self.name = name.upCellNameValue
        self.plainFill = plainFill
        self.plain = plain
        self.closable = closable
        self.show = show
        self.icon = icon
        self.iconColor = iconColor
        self.textSize = textSize
        self.height = height
        self.padding = padding
        self.borderRadius = borderRadius
        self.autoBgColor = autoBgColor.upTagAutoBgColorValue
        self.customClass = customClass
        self.customStyle = customStyle
        self.onTapHandler = onTap
        self.onClickHandler = onClick
        self.onCloseHandler = onClose
    }

    public init<Content: View>(
        type: String = UPConfig.tag.type,
        disabled: some UPTagDisabledValue = UPConfig.tag.disabled,
        size: String = UPConfig.tag.size,
        shape: String = UPConfig.tag.shape,
        text: some UPTagTextValue = UPConfig.tag.text,
        bgColor: String = UPConfig.tag.bgColor,
        color: String = UPConfig.tag.color,
        borderColor: String = UPConfig.tag.borderColor,
        closeColor: String = UPConfig.tag.closeColor,
        name: some UPTagNameValue = UPConfig.tag.name,
        plainFill: Bool = UPConfig.tag.plainFill,
        plain: Bool = UPConfig.tag.plain,
        closable: Bool = UPConfig.tag.closable,
        show: Bool = UPConfig.tag.show,
        icon: String = UPConfig.tag.icon,
        iconColor: String = UPConfig.tag.iconColor,
        textSize: String = UPConfig.tag.textSize,
        height: String = UPConfig.tag.height,
        padding: String = UPConfig.tag.padding,
        borderRadius: String = UPConfig.tag.borderRadius,
        autoBgColor: some UPTagAutoBgColorValue = UPConfig.tag.autoBgColor,
        customClass: String = UPConfig.tag.customClass,
        customStyle: UPStyle = UPConfig.tag.customStyle,
        onTap: (() -> Void)? = nil,
        onClick: ((UPTagName) -> Void)? = nil,
        onClose: ((UPTagName) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            type: type,
            disabled: disabled,
            size: size,
            shape: shape,
            text: text,
            bgColor: bgColor,
            color: color,
            borderColor: borderColor,
            closeColor: closeColor,
            name: name,
            plainFill: plainFill,
            plain: plain,
            closable: closable,
            show: show,
            icon: icon,
            iconColor: iconColor,
            textSize: textSize,
            height: height,
            padding: padding,
            borderRadius: borderRadius,
            autoBgColor: autoBgColor,
            customClass: customClass,
            customStyle: customStyle,
            onTap: onTap,
            onClick: onClick,
            onClose: onClose
        )
        defaultSlotContent = AnyView(content())
    }

    public var body: some View {
        Group {
            if show {
                ZStack(alignment: .topTrailing) {
                    tagBody
                    if closable {
                        closeButton
                            .offset(x: 8, y: -8)
                    }
                }
                .padding(.top, closable ? 8 : 0)
                .padding(.trailing, closable ? 8 : 0)
            }
        }
    }

    private var tagBody: some View {
        HStack(spacing: 4) {
            renderedIcon
            renderedContent
        }
        .padding(.top, contentInsets.top)
        .padding(.leading, contentInsets.leading)
        .padding(.bottom, contentInsets.bottom)
        .padding(.trailing, contentInsets.trailing)
        .frame(height: resolvedTagHeight)
        .background(resolvedBackgroundColor)
        .overlay {
            RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous)
                .stroke(resolvedBorderColor, lineWidth: hasBorder ? 1 : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous))
        .opacity(disabled ? 0.6 : 1)
        .upStyle(customStyle)
        .contentShape(Rectangle())
        .onTapGesture {
            triggerClick()
        }
    }

    @ViewBuilder
    private var renderedIcon: some View {
        if let iconSlotContent {
            iconSlotContent
        } else if usesImageIcon {
            imageIcon
        } else if !icon.isEmpty {
            UPIcon(
                name: icon,
                color: iconColor.isEmpty ? resolvedTextColorName : iconColor,
                size: "\(Int(resolvedIconSize))px"
            )
        }
    }

    @ViewBuilder
    private var imageIcon: some View {
        if let remoteImageURL {
            AsyncImage(url: remoteImageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.clear
                }
            }
            .frame(width: resolvedImageIconSize, height: resolvedImageIconSize)
        } else {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: resolvedImageIconSize, height: resolvedImageIconSize)
        }
    }

    @ViewBuilder
    private var renderedContent: some View {
        if let contentSlotContent {
            contentSlotContent
                .font(.system(size: resolvedTextSize))
                .foregroundStyle(resolvedTextColor)
        } else if let defaultSlotContent {
            defaultSlotContent
                .font(.system(size: resolvedTextSize))
                .foregroundStyle(resolvedTextColor)
        } else {
            Text(text)
                .font(.system(size: resolvedTextSize))
                .foregroundStyle(resolvedTextColor)
        }
    }

    private var closeButton: some View {
        Button {
            triggerClose()
        } label: {
            UPIcon(
                name: "close",
                color: "#ffffff",
                size: "\(Int(resolvedCloseIconSize))px"
            )
            .frame(width: resolvedCloseButtonSize, height: resolvedCloseButtonSize)
            .background(UPColor.parse(closeColor, theme: theme))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close tag")
    }

    func triggerClick() {
        guard show, !disabled else { return }
        onTapHandler?()
        onClickHandler?(name)
    }

    func triggerClose() {
        guard show, closable, !disabled else { return }
        onCloseHandler?(name)
    }

    private struct Metrics {
        let fontSize: CGFloat
        let iconSize: CGFloat
        let imageIconSize: CGFloat
        let closeIconSize: CGFloat
        let closeButtonSize: CGFloat
        let height: CGFloat
        let horizontalPadding: CGFloat
    }

    private var metrics: Metrics {
        switch size.lowercased() {
        case "large":
            return Metrics(
                fontSize: 15,
                iconSize: 21,
                imageIconSize: 17,
                closeIconSize: 15,
                closeButtonSize: 25,
                height: 32,
                horizontalPadding: 15
            )
        case "mini":
            return Metrics(
                fontSize: 12,
                iconSize: 16,
                imageIconSize: 13,
                closeIconSize: 12,
                closeButtonSize: 18,
                height: 22,
                horizontalPadding: 5
            )
        default:
            return Metrics(
                fontSize: 13,
                iconSize: 19,
                imageIconSize: 15,
                closeIconSize: 13,
                closeButtonSize: 22,
                height: 26,
                horizontalPadding: 10
            )
        }
    }

    var resolvedContentInsets: UPInsets {
        guard !padding.isEmpty else {
            return UPInsets(
                top: 0,
                leading: metrics.horizontalPadding,
                bottom: 0,
                trailing: metrics.horizontalPadding
            )
        }
        return UPStyle(["padding": padding]).padding
    }

    private var contentInsets: UPInsets { resolvedContentInsets }

    var resolvedTextSize: CGFloat {
        let configured = UPUnit.parse(textSize)
        return configured > 0 ? configured : metrics.fontSize
    }

    var resolvedTagHeight: CGFloat {
        let configured = UPUnit.parse(height)
        return configured > 0 ? configured : metrics.height
    }

    var resolvedIconSize: CGFloat { metrics.iconSize }
    var resolvedImageIconSize: CGFloat { metrics.imageIconSize }
    var resolvedCloseIconSize: CGFloat { metrics.closeIconSize }
    var resolvedCloseButtonSize: CGFloat { metrics.closeButtonSize }

    var resolvedCornerRadius: CGFloat {
        let configured = UPUnit.parse(borderRadius)
        if configured > 0 { return configured }
        return shape.lowercased() == "circle" ? 100 : 3
    }

    /// Matches uview-plus' `test.image` helper, which uses a file extension
    /// rather than URL validity to choose the image branch.
    var usesImageIcon: Bool {
        let pathWithoutQuery = icon.split(separator: "?", maxSplits: 1).first.map(String.init) ?? icon
        let lowercasedPath = pathWithoutQuery.lowercased()
        return Self.imageFileExtensions.contains { lowercasedPath.contains(".\($0)") }
    }

    private var remoteImageURL: URL? {
        guard let url = URL(string: icon), let scheme = url.scheme?.lowercased() else {
            return nil
        }
        return ["http", "https"].contains(scheme) ? url : nil
    }

    private static let imageFileExtensions: Set<String> = [
        "jpeg", "jpg", "gif", "png", "svg", "webp", "jfif", "bmp", "dpg",
    ]

    /// Reproduces uview-plus' `genLightColor`: retain hue/saturation and set
    /// HSL lightness to the requested value, capped at 95 percent.
    static func autoBackgroundHex(for color: String, lightness: Double) -> String? {
        guard let rgb = rgbComponents(from: color) else { return nil }
        let hsl = hslComponents(red: rgb.red, green: rgb.green, blue: rgb.blue)
        return hslHex(hue: hsl.hue, saturation: hsl.saturation, lightness: min(lightness, 95))
    }

    private static func rgbComponents(from color: String) -> (red: Double, green: Double, blue: Double)? {
        let value = color.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if value.hasPrefix("#") {
            let shorthandOrHex = String(value.dropFirst())
            let hex = shorthandOrHex.count == 3
                ? shorthandOrHex.map { String(repeating: $0, count: 2) }.joined()
                : shorthandOrHex
            guard hex.count >= 6,
                  let red = UInt8(hex.prefix(2), radix: 16),
                  let green = UInt8(hex.dropFirst(2).prefix(2), radix: 16),
                  let blue = UInt8(hex.dropFirst(4).prefix(2), radix: 16)
            else {
                return nil
            }
            return (Double(red), Double(green), Double(blue))
        }

        let prefix: String
        if value.hasPrefix("rgba(") {
            prefix = "rgba("
        } else if value.hasPrefix("rgb(") {
            prefix = "rgb("
        } else {
            return nil
        }

        let components = value.dropFirst(prefix.count).split(separator: ",", omittingEmptySubsequences: false)
        guard components.count >= 3,
              let red = numericComponent(components[0]),
              let green = numericComponent(components[1]),
              let blue = numericComponent(components[2])
        else {
            return nil
        }
        return (red, green, blue)
    }

    private static func numericComponent(_ component: Substring) -> Double? {
        let value = component
            .split(separator: ")", maxSplits: 1, omittingEmptySubsequences: false)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Double(value)
    }

    private static func hslComponents(red: Double, green: Double, blue: Double) -> (hue: Double, saturation: Double) {
        let red = red / 255
        let green = green / 255
        let blue = blue / 255
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let lightness = (maximum + minimum) / 2

        guard maximum != minimum else { return (0, 0) }

        let delta = maximum - minimum
        let saturation = lightness > 0.5
            ? delta / (2 - maximum - minimum)
            : delta / (maximum + minimum)
        let hue: Double
        if maximum == red {
            hue = (green - blue) / delta + (green < blue ? 6 : 0)
        } else if maximum == green {
            hue = (blue - red) / delta + 2
        } else {
            hue = (red - green) / delta + 4
        }

        return (
            roundedToOneDecimal(hue * 60),
            roundedToOneDecimal(saturation * 100)
        )
    }

    private static func hslHex(hue: Double, saturation: Double, lightness: Double) -> String {
        let normalizedLightness = lightness / 100
        let chroma = saturation * min(normalizedLightness, 1 - normalizedLightness) / 100

        func component(_ index: Double) -> String {
            let key = (index + hue / 30).truncatingRemainder(dividingBy: 12)
            let channel = normalizedLightness - chroma * max(min(key - 3, 9 - key, 1), -1)
            return String(format: "%02x", Int((255 * channel).rounded()))
        }

        return "#\(component(0))\(component(8))\(component(4))"
    }

    private static func roundedToOneDecimal(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    private var resolvedBaseColor: Color {
        UPColor.parse(type, theme: theme)
    }

    private var resolvedTextColorName: String {
        if !color.isEmpty { return color }
        return plain ? type : "#ffffff"
    }

    private var resolvedTextColor: Color {
        UPColor.parse(resolvedTextColorName, theme: theme)
    }

    private var resolvedBackgroundColor: Color {
        if !bgColor.isEmpty {
            return UPColor.parse(bgColor, theme: theme)
        }
        if autoBgColor > 0, !color.isEmpty {
            if let backgroundHex = Self.autoBackgroundHex(for: color, lightness: autoBgColor) {
                return UPColor.parse(backgroundHex, theme: theme)
            }
            return UPColor.parse(color, theme: theme).opacity(min(max(autoBgColor / 100, 0), 1))
        }
        if plain {
            return plainFill ? resolvedBaseColor.opacity(0.12) : .clear
        }
        return resolvedBaseColor
    }

    private var resolvedBorderColor: Color {
        if !borderColor.isEmpty {
            return UPColor.parse(borderColor, theme: theme)
        }
        return plain ? resolvedBaseColor : .clear
    }

    private var hasBorder: Bool {
        plain || !borderColor.isEmpty
    }
}

public extension UPTag {
    /// Registers a native tap callback in addition to uview-plus's `click(name)` event.
    func onTap(_ action: @escaping () -> Void) -> UPTag {
        var copy = self
        copy.onTapHandler = action
        return copy
    }

    /// SwiftUI equivalent of uview-plus `u-tag`'s `click(name)` event listener.
    func onClick(_ action: @escaping (UPTagName) -> Void) -> UPTag {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    /// SwiftUI equivalent of uview-plus `u-tag`'s `close(name)` event listener.
    func onClose(_ action: @escaping (UPTagName) -> Void) -> UPTag {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }

    /// SwiftUI equivalent of uview-plus `u-tag`'s named `icon` slot.
    func icon<Content: View>(@ViewBuilder _ content: () -> Content) -> UPTag {
        var copy = self
        copy.iconSlotContent = AnyView(content())
        return copy
    }

    /// SwiftUI equivalent of uview-plus `u-tag`'s named `content` slot.
    func content<Content: View>(@ViewBuilder _ content: () -> Content) -> UPTag {
        var copy = self
        copy.contentSlotContent = AnyView(content())
        return copy
    }
}
