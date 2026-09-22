import Foundation
import SwiftUI

/// Values accepted by uview-plus `u-parse`'s `Boolean | String` props
/// (`copyLink`, `lazyLoad`, `pauseVideo`, `previewImg`, `scrollTable`,
/// `selectable`, `setTitle`, `showImgMenu`). String inputs keep JavaScript
/// truthiness so only the empty string is false, and the raw text is kept
/// because upstream's parser treats `previewImg === 'all'` specially.
public protocol UPParseFlagValue {
    var upParseFlagValue: Bool { get }
    var upParseFlagText: String { get }
}

extension Bool: UPParseFlagValue {
    public var upParseFlagValue: Bool { self }
    public var upParseFlagText: String { "" }
}

extension String: UPParseFlagValue {
    public var upParseFlagValue: Bool { !isEmpty }
    public var upParseFlagText: String { self }
}

/// Values accepted by `u-parse`'s `Boolean | Number` `useAnchor` prop. A number
/// doubles as the scroll offset, and `0` stays falsy exactly like JavaScript.
public protocol UPParseAnchorValue {
    var upParseAnchorEnabled: Bool { get }
    var upParseAnchorOffset: CGFloat { get }
}

extension Bool: UPParseAnchorValue {
    public var upParseAnchorEnabled: Bool { self }
    public var upParseAnchorOffset: CGFloat { 0 }
}

public extension UPParseAnchorValue where Self: BinaryInteger {
    var upParseAnchorEnabled: Bool { self != 0 }
    var upParseAnchorOffset: CGFloat { CGFloat(Double(self)) }
}

extension Int: UPParseAnchorValue {}
extension Int8: UPParseAnchorValue {}
extension Int16: UPParseAnchorValue {}
extension Int32: UPParseAnchorValue {}
extension Int64: UPParseAnchorValue {}
extension UInt: UPParseAnchorValue {}
extension UInt8: UPParseAnchorValue {}
extension UInt16: UPParseAnchorValue {}
extension UInt32: UPParseAnchorValue {}
extension UInt64: UPParseAnchorValue {}

public extension UPParseAnchorValue where Self: BinaryFloatingPoint {
    var upParseAnchorEnabled: Bool { self != 0 }
    var upParseAnchorOffset: CGFloat {
        let value = Double(self)
        return value.isFinite ? CGFloat(value) : 0
    }
}

extension Double: UPParseAnchorValue {}
extension Float: UPParseAnchorValue {}

/// CSS color parsing for the declarations produced by the `u-parse` HTML
/// parser. Unlike `UPColor.parse(_:theme:)` an unsupported input returns `nil`
/// so the renderer keeps the inherited color instead of silently falling back
/// to the theme's content color.
public enum UPParseColor {
    public static func parse(_ value: String) -> Color? {
        let raw = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !raw.isEmpty else { return nil }
        if raw == "transparent" { return .clear }
        if raw.hasPrefix("#") {
            let hex = String(raw.dropFirst())
            guard hex.allSatisfy(\.isHexDigit), [3, 4, 6, 8].contains(hex.count) else { return nil }
            return UPColor.parse("#" + hex)
        }
        if raw.hasPrefix("rgb") { return functional(raw) }
        return named[raw]
    }

    private static func functional(_ raw: String) -> Color? {
        guard let open = raw.firstIndex(of: "("), let close = raw.lastIndex(of: ")"), open < close else {
            return nil
        }
        let parts = raw[raw.index(after: open)..<close]
            .split(whereSeparator: { $0 == "," || $0 == "/" || $0 == " " })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard parts.count == 3 || parts.count == 4 else { return nil }
        let channels = parts.prefix(3).map { component -> Double in
            if component.hasSuffix("%"), let percent = Double(component.dropLast()) {
                return min(max(percent / 100, 0), 1)
            }
            return min(max((Double(component) ?? 0) / 255, 0), 1)
        }
        var alpha = 1.0
        if parts.count == 4 {
            let raw = parts[3]
            if raw.hasSuffix("%"), let percent = Double(raw.dropLast()) {
                alpha = percent / 100
            } else {
                alpha = Double(raw) ?? 1
            }
        }
        return Color(red: channels[0], green: channels[1], blue: channels[2], opacity: min(max(alpha, 0), 1))
    }

    /// The CSS named colors upstream's demo content and built-in `tagStyle`
    /// rely on, plus the most common neighbours.
    private static let named: [String: Color] = [
        "black": Color(hex: 0x000000), "silver": Color(hex: 0xC0C0C0),
        "gray": Color(hex: 0x808080), "grey": Color(hex: 0x808080),
        "white": Color(hex: 0xFFFFFF), "maroon": Color(hex: 0x800000),
        "red": Color(hex: 0xFF0000), "purple": Color(hex: 0x800080),
        "fuchsia": Color(hex: 0xFF00FF), "magenta": Color(hex: 0xFF00FF),
        "green": Color(hex: 0x008000), "lime": Color(hex: 0x00FF00),
        "olive": Color(hex: 0x808000), "yellow": Color(hex: 0xFFFF00),
        "navy": Color(hex: 0x000080), "blue": Color(hex: 0x0000FF),
        "teal": Color(hex: 0x008080), "aqua": Color(hex: 0x00FFFF),
        "cyan": Color(hex: 0x00FFFF), "orange": Color(hex: 0xFFA500),
        "pink": Color(hex: 0xFFC0CB), "brown": Color(hex: 0xA52A2A),
        "gold": Color(hex: 0xFFD700), "violet": Color(hex: 0xEE82EE),
        "indigo": Color(hex: 0x4B0082), "lightgray": Color(hex: 0xD3D3D3),
        "lightgrey": Color(hex: 0xD3D3D3), "darkgray": Color(hex: 0xA9A9A9),
        "darkgrey": Color(hex: 0xA9A9A9)
    ]
}

/// A single resolved CSS border side.
public struct UPParseBorder: Equatable, Sendable {
    public let width: CGFloat
    public let color: Color?

    public init(width: CGFloat, color: Color?) {
        self.width = width
        self.color = color
    }
}

/// The declaration bag `u-parse` builds for every node: upstream merges the
/// resolved `tagStyle` entry with the element's own inline `style`, so the same
/// merge order is reproduced here.
public struct UPParseStyle: Equatable, Sendable {
    public let declarations: [String: String]

    public init(_ css: String = "") {
        self.init(declarations: Self.declarations(from: css))
    }

    public init(declarations: [String: String]) {
        var normalized: [String: String] = [:]
        for (key, value) in declarations {
            let name = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !text.isEmpty else { continue }
            normalized[name] = text
        }
        self.declarations = normalized
    }

    /// Merges CSS strings the way upstream `parseStyle` concatenates
    /// `tagStyle[name]` with `attrs.style`: later declarations win.
    public static func merging(_ sources: [String]) -> UPParseStyle {
        var merged: [String: String] = [:]
        for css in sources {
            for (key, value) in declarations(from: css) { merged[key] = value }
        }
        return UPParseStyle(declarations: merged)
    }

    public func merging(_ other: UPParseStyle) -> UPParseStyle {
        var merged = declarations
        for (key, value) in other.declarations { merged[key] = value }
        return UPParseStyle(declarations: merged)
    }

    public func setting(_ key: String, _ value: String) -> UPParseStyle {
        var merged = declarations
        merged[key.lowercased()] = value
        return UPParseStyle(declarations: merged)
    }

    public var isEmpty: Bool { declarations.isEmpty }

    public func value(for key: String) -> String? { declarations[key.lowercased()] }

    /// Deterministic serialization used for the `style` attribute exposed on
    /// `linktap` / `imgtap` payloads.
    public var cssText: String {
        declarations.keys.sorted().compactMap { key in
            declarations[key].map { "\(key): \($0)" }
        }.joined(separator: "; ")
    }

    public var display: String? { value(for: "display")?.lowercased() }

    /// Upstream keeps whitespace when the declaration set mentions both
    /// `white-space` and `pre`.
    public var isPre: Bool {
        guard let whiteSpace = value(for: "white-space")?.lowercased() else { return false }
        return whiteSpace.contains("pre")
    }

    public var textAlignment: UPTextAlignment? {
        switch value(for: "text-align")?.lowercased() {
        case "left", "start": return .leading
        case "center": return .center
        case "right", "end": return .trailing
        default: return nil
        }
    }

    public var foregroundColor: Color? {
        value(for: "color").flatMap(UPParseColor.parse)
    }

    public var backgroundColor: Color? {
        for key in ["background-color", "background"] {
            if let raw = value(for: key), let color = UPParseColor.parse(raw) { return color }
        }
        return nil
    }

    public var isBold: Bool? {
        guard let weight = value(for: "font-weight")?.lowercased() else { return nil }
        if weight == "bold" || weight == "bolder" { return true }
        if weight == "normal" || weight == "lighter" { return false }
        if let numeric = Double(weight) { return numeric >= 600 }
        return nil
    }

    public var isItalic: Bool? {
        guard let style = value(for: "font-style")?.lowercased() else { return nil }
        if style == "italic" || style == "oblique" { return true }
        if style == "normal" { return false }
        return nil
    }

    public var isMonospaced: Bool {
        value(for: "font-family")?.lowercased().contains("monospace") ?? false
    }

    /// `nil` when the element does not declare `text-decoration` at all, so the
    /// inherited decorations stay untouched.
    public var textDecoration: (underline: Bool, strikethrough: Bool)? {
        let raw = value(for: "text-decoration") ?? value(for: "text-decoration-line")
        guard let decoration = raw?.lowercased() else { return nil }
        if decoration.contains("none") { return (false, false) }
        return (decoration.contains("underline"), decoration.contains("line-through"))
    }

    public func fontSize(base: CGFloat) -> CGFloat? {
        length(for: "font-size", base: base)
    }

    public func length(for key: String, base: CGFloat) -> CGFloat? {
        Self.length(value(for: key), base: base)
    }

    /// Resolves the CSS lengths `u-parse` content actually uses: `px`, `rpx`,
    /// `em` / `rem`, percentages, the absolute font-size keywords produced by
    /// the `<font size>` mapping, and bare numbers.
    public static func length(_ raw: String?, base: CGFloat) -> CGFloat? {
        guard let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !text.isEmpty else {
            return nil
        }
        switch text {
        case "xx-small": return 9
        case "x-small": return 10
        case "small": return 13
        case "medium": return 16
        case "large": return 18
        case "x-large": return 22
        case "xx-large": return 28
        case "xxx-large": return 34
        case "smaller": return base * 0.8
        case "larger": return base * 1.2
        case "auto", "inherit", "initial", "unset", "none": return nil
        default: break
        }
        if text.hasSuffix("rpx") {
            guard let value = Double(text.dropLast(3)), value.isFinite else { return nil }
            return UPUnit.rpx(CGFloat(value))
        }
        if text.hasSuffix("px") {
            guard let value = Double(text.dropLast(2)), value.isFinite else { return nil }
            return CGFloat(value)
        }
        if text.hasSuffix("rem") {
            guard let value = Double(text.dropLast(3)), value.isFinite else { return nil }
            return CGFloat(value) * base
        }
        if text.hasSuffix("em") {
            guard let value = Double(text.dropLast(2)), value.isFinite else { return nil }
            return CGFloat(value) * base
        }
        if text.hasSuffix("%") {
            guard let value = Double(text.dropLast()), value.isFinite else { return nil }
            return CGFloat(value) / 100 * base
        }
        if text.hasSuffix("pt") {
            guard let value = Double(text.dropLast(2)), value.isFinite else { return nil }
            return CGFloat(value) * 4 / 3
        }
        guard let value = Double(text), value.isFinite else { return nil }
        return CGFloat(value)
    }

    /// Shorthand aware `padding` / `margin` resolution mirroring `UPStyle`.
    public func insets(for prefix: String, base: CGFloat) -> UPInsets {
        let shorthand = Self.shorthandInsets(value(for: prefix), base: base)
        return UPInsets(
            top: length(for: "\(prefix)-top", base: base) ?? shorthand.top,
            leading: length(for: "\(prefix)-left", base: base) ?? shorthand.leading,
            bottom: length(for: "\(prefix)-bottom", base: base) ?? shorthand.bottom,
            trailing: length(for: "\(prefix)-right", base: base) ?? shorthand.trailing
        )
    }

    public func border(for side: String) -> UPParseBorder? {
        Self.border(value(for: "border-\(side)") ?? value(for: "border"))
            ?? Self.border(shorthandWidth: value(for: "border-\(side)-width") ?? value(for: "border-width"),
                           color: value(for: "border-\(side)-color") ?? value(for: "border-color"))
    }

    private static func border(_ raw: String?) -> UPParseBorder? {
        guard let raw, !raw.isEmpty else { return nil }
        var width: CGFloat?
        var color: Color?
        for token in raw.split(whereSeparator: { $0.isWhitespace }).map(String.init) {
            let lowered = token.lowercased()
            if lowered == "none" || lowered == "hidden" { return nil }
            if ["solid", "dashed", "dotted", "double", "groove", "ridge", "inset", "outset"].contains(lowered) {
                continue
            }
            if let value = length(token, base: 16), width == nil {
                width = value
                continue
            }
            if color == nil { color = UPParseColor.parse(token) }
        }
        guard let resolved = width, resolved > 0 else { return nil }
        return UPParseBorder(width: resolved, color: color)
    }

    private static func border(shorthandWidth: String?, color: String?) -> UPParseBorder? {
        guard let width = length(shorthandWidth, base: 16), width > 0 else { return nil }
        return UPParseBorder(width: width, color: color.flatMap(UPParseColor.parse))
    }

    private static func shorthandInsets(_ raw: String?, base: CGFloat) -> UPInsets {
        guard let raw else { return .zero }
        let values = raw.split(whereSeparator: { $0.isWhitespace }).compactMap { length(String($0), base: base) }
        switch values.count {
        case 1: return UPInsets(top: values[0], leading: values[0], bottom: values[0], trailing: values[0])
        case 2: return UPInsets(top: values[0], leading: values[1], bottom: values[0], trailing: values[1])
        case 3: return UPInsets(top: values[0], leading: values[1], bottom: values[2], trailing: values[1])
        case 4...: return UPInsets(top: values[0], leading: values[3], bottom: values[2], trailing: values[1])
        default: return .zero
        }
    }

    private static func declarations(from css: String) -> [String: String] {
        var result: [String: String] = [:]
        for declaration in css.split(separator: ";") {
            guard let separator = declaration.firstIndex(of: ":") else { continue }
            let key = declaration[declaration.startIndex..<separator]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let value = declaration[declaration.index(after: separator)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !value.isEmpty else { continue }
            result[key] = value
        }
        return result
    }
}
