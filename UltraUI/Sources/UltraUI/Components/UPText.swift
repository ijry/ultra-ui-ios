import Foundation
import SwiftUI

/// A String-or-Number value accepted by uview-plus `u-text` props.
public protocol UPTextValue {
    var upTextValue: String { get }
}

extension String: UPTextValue {
    public var upTextValue: String { self }
}

extension Int: UPTextValue {
    public var upTextValue: String { String(self) }
}

extension Double: UPTextValue {
    public var upTextValue: String { Self.upTextFormatted(self) }
}

extension Float: UPTextValue {
    public var upTextValue: String { Double(self).upTextValue }
}

extension CGFloat: UPTextValue {
    public var upTextValue: String { Double(self).upTextValue }
}

private extension Double {
    static func upTextFormatted(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        return value.rounded() == value ? String(Int(value)) : String(value)
    }
}

/// Native SwiftUI counterpart of uview-plus `u-text`.
///
/// The public initializer deliberately mirrors the uview-plus prop names. Props
/// that are specific to uni-app capabilities are retained as metadata so SwiftUI
/// call sites can stay source-compatible while using native rendering.
public struct UPText: View {
    var type: String
    var show: Bool
    var text: String
    var prefixIcon: String
    var suffixIcon: String
    var mode: String
    var href: String
    var format: String
    var call: Bool
    var openType: String
    var bold: Bool
    var block: Bool
    var lines: String
    var color: String
    var size: String
    var iconStyle: UPStyle
    var decoration: String
    var margin: String
    var lineHeight: String
    var align: String
    var wordWrap: String
    var flex1: Bool
    var customStyle: UPStyle
    var formatter: ((String) -> String)?
    var onTap: (() -> Void)?
    var onClick: (() -> Void)?

    @Environment(\.upTheme) private var theme
    @Environment(\.openURL) private var openURL

    public init(type: String = UPConfig.text.type,
                show: Bool = UPConfig.text.show,
                text: some UPTextValue = UPConfig.text.text,
                prefixIcon: String = UPConfig.text.prefixIcon,
                suffixIcon: String = UPConfig.text.suffixIcon,
                mode: String = UPConfig.text.mode,
                href: String = UPConfig.text.href,
                format: String = UPConfig.text.format,
                call: Bool = UPConfig.text.call,
                openType: String = UPConfig.text.openType,
                bold: Bool = UPConfig.text.bold,
                block: Bool = UPConfig.text.block,
                lines: some UPTextValue = UPConfig.text.lines,
                color: String = UPConfig.text.color,
                size: some UPTextValue = UPConfig.text.size,
                iconStyle: UPStyle = UPConfig.text.iconStyle,
                decoration: String = UPConfig.text.decoration,
                margin: some UPTextValue = UPConfig.text.margin,
                lineHeight: some UPTextValue = UPConfig.text.lineHeight,
                align: String = UPConfig.text.align,
                wordWrap: String = UPConfig.text.wordWrap,
                flex1: Bool = UPConfig.text.flex1,
                customStyle: UPStyle = UPStyle(),
                formatter: ((String) -> String)? = nil,
                onTap: (() -> Void)? = nil,
                onClick: (() -> Void)? = nil) {
        self.type = type
        self.show = show
        self.text = text.upTextValue
        self.prefixIcon = prefixIcon
        self.suffixIcon = suffixIcon
        self.mode = mode
        self.href = href
        self.format = format
        self.call = call
        self.openType = openType
        self.bold = bold
        self.block = block
        self.lines = lines.upTextValue
        self.color = color
        self.size = size.upTextValue
        self.iconStyle = iconStyle
        self.decoration = decoration
        self.margin = margin.upTextValue
        self.lineHeight = lineHeight.upTextValue
        self.align = align
        self.wordWrap = wordWrap
        self.flex1 = flex1
        self.customStyle = customStyle
        self.formatter = formatter
        self.onTap = onTap
        self.onClick = onClick
    }

    public var body: some View {
        Group {
            if show {
                content
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 4) {
            if !prefixIcon.isEmpty {
                icon(named: prefixIcon)
            }

            valueView

            if !suffixIcon.isEmpty {
                icon(named: suffixIcon)
            }
        }
        .frame(maxWidth: maximumWidth, alignment: frameAlignment)
        .padding(Self.edgeInsets(resolvedMargin))
        .upStyle(customStyle)
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
    }

    private var valueView: some View {
        Text(displayText)
            .font(.system(size: max(resolvedSize, 1)))
            .fontWeight(bold ? .bold : .regular)
            .foregroundStyle(resolvedColor)
            .underline(decoration == "underline")
            .strikethrough(decoration == "line-through")
            .lineLimit(resolvedLineLimit)
            .lineSpacing(resolvedLineSpacing)
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: flex1 ? .infinity : nil, alignment: frameAlignment)
    }

    /// Value after applying the uview-plus `mode` and optional function formatter.
    /// Kept internal for testable compatibility checks; SwiftUI renders this value.
    var displayText: String {
        if let formatter {
            return formatter(text)
        }

        switch mode.lowercased() {
        case "price":
            return Self.priceFormatted(text)
        case "date":
            return Self.dateFormatted(text, format: format.isEmpty ? "yyyy-mm-dd" : format)
        case "phone" where format == "encrypt":
            return Self.encryptedPhone(text)
        case "name" where format == "encrypt":
            return Self.encryptedName(text)
        default:
            return text
        }
    }

    var resolvedSize: CGFloat { UPUnit.parse(size) }

    var resolvedLineLimit: Int? {
        guard let limit = Int(lines), limit > 0 else { return nil }
        return limit
    }

    var resolvedMargin: UPInsets {
        UPStyle(["padding": margin]).padding
    }

    var resolvedLineSpacing: CGFloat {
        let requestedHeight = UPUnit.parse(lineHeight)
        guard requestedHeight > 0 else { return 0 }
        return max(requestedHeight - resolvedSize, 0)
    }

    private static func dateFormatted(_ value: String, format: String) -> String {
        guard let date = parsedDate(value) else { return value }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let values: [Character: String] = [
            "y": String(format: "%04d", components.year ?? 0),
            "m": String(format: "%02d", components.month ?? 0),
            "d": String(format: "%02d", components.day ?? 0),
            "h": String(format: "%02d", components.hour ?? 0),
            "M": String(format: "%02d", components.minute ?? 0),
            "s": String(format: "%02d", components.second ?? 0)
        ]

        var result = ""
        var index = format.startIndex
        while index < format.endIndex {
            let symbol = format[index]
            guard let value = values[symbol] else {
                result.append(symbol)
                index = format.index(after: index)
                continue
            }

            var end = format.index(after: index)
            while end < format.endIndex, format[end] == symbol {
                end = format.index(after: end)
            }
            let runLength = format.distance(from: index, to: end)
            if symbol == "y", runLength == 2 {
                result += String(value.suffix(2))
            } else {
                result += value
            }
            index = end
        }
        return result
    }

    private static func parsedDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Date() }

        if trimmed.allSatisfy(\.isNumber), let timestamp = TimeInterval(trimmed) {
            let seconds = trimmed.count == 10 ? timestamp : timestamp / 1_000
            return Date(timeIntervalSince1970: seconds)
        }

        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: trimmed) {
            return date
        }

        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd HH:mm",
            "yyyy/MM/dd"
        ]
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .current
            formatter.dateFormat = format
            formatter.isLenient = false
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    private static func priceFormatted(_ value: String) -> String {
        guard let decimal = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
            return "0.00"
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter.string(from: decimal as NSDecimalNumber) ?? value
    }

    private static func encryptedPhone(_ value: String) -> String {
        guard value.count > 7 else { return value }
        let prefix = value.prefix(3)
        let suffix = value.dropFirst(7)
        return "\(prefix)****\(suffix)"
    }

    private static func encryptedName(_ value: String) -> String {
        switch value.count {
        case 0...1:
            return value
        case 2:
            return "\(value.prefix(1))*"
        default:
            return "\(value.prefix(1))\(String(repeating: "*", count: value.count - 2))\(value.suffix(1))"
        }
    }

    private func icon(named name: String) -> UPIcon {
        UPIcon(
            name: name,
            color: iconStyle.foregroundColor ?? resolvedColorName,
            size: iconStyle.value(for: "fontSize") ?? "15px"
        )
    }

    private var resolvedColorName: String {
        if !color.isEmpty { return color }
        return type.isEmpty ? "content" : type
    }

    private var resolvedColor: Color {
        UPColor.parse(resolvedColorName, theme: theme)
    }

    private var maximumWidth: CGFloat? {
        (block || flex1) ? .infinity : nil
    }

    private var frameAlignment: Alignment {
        switch align.lowercased() {
        case "center": return .center
        case "right", "end", "trailing": return .trailing
        default: return .leading
        }
    }

    private var textAlignment: TextAlignment {
        switch align.lowercased() {
        case "center": return .center
        case "right", "end", "trailing": return .trailing
        default: return .leading
        }
    }

    private func handleTap() {
        if mode == "link", let url = URL(string: href), !href.isEmpty {
            openURL(url)
        } else if mode == "phone", call,
                  let url = URL(string: "tel://\(text)") {
            openURL(url)
        }
        onTap?()
        onClick?()
    }

    private static func edgeInsets(_ insets: UPInsets) -> EdgeInsets {
        EdgeInsets(
            top: insets.top,
            leading: insets.leading,
            bottom: insets.bottom,
            trailing: insets.trailing
        )
    }
}
