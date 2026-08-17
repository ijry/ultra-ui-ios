import SwiftUI

/// Native representation of the supported subset of uview-plus `customStyle`.
///
/// Keys accept either uview-style kebab case (`"background-color"`) or camel
/// case (`"backgroundColor"`). Unsupported declarations are retained as
/// metadata but intentionally have no rendering effect.
public struct UPStyle: Equatable, Sendable {
    public let properties: [String: String]

    public init(_ properties: [String: String] = [:]) {
        var normalized: [String: String] = [:]
        for (key, value) in properties {
            normalized[Self.normalizedKey(key)] = value
        }
        self.properties = normalized
    }

    public subscript(_ key: String) -> String? {
        value(for: key)
    }

    public func value(for key: String) -> String? {
        properties[Self.normalizedKey(key)]
    }

    /// Resolves a uview unit value (`rpx`, `px`, or a bare number) when valid.
    /// Percentages and unsupported CSS expressions deliberately return `nil`.
    public func length(for key: String) -> CGFloat? {
        Self.length(value(for: key))
    }

    public var padding: UPInsets {
        insets(for: "padding")
    }

    public var margin: UPInsets {
        insets(for: "margin")
    }

    public var width: CGFloat? { length(for: "width") }
    public var height: CGFloat? { length(for: "height") }
    public var minWidth: CGFloat? { length(for: "min-width") }
    public var minHeight: CGFloat? { length(for: "min-height") }
    public var maxWidth: CGFloat? { length(for: "max-width") }
    public var maxHeight: CGFloat? { length(for: "max-height") }
    public var cornerRadius: CGFloat? { length(for: "border-radius") }

    public var foregroundColor: String? {
        firstValue(for: ["color", "foreground-color"])
    }

    public var backgroundColor: String? {
        firstValue(for: ["background-color", "background"])
    }

    public var opacity: Double? {
        guard let raw = value(for: "opacity"), let parsed = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        return min(max(parsed, 0), 1)
    }

    public var textAlignment: UPTextAlignment? {
        switch value(for: "text-align")?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "left", "start", "leading": return .leading
        case "center": return .center
        case "right", "end", "trailing": return .trailing
        default: return nil
        }
    }

    private func firstValue(for keys: [String]) -> String? {
        for key in keys {
            if let value = value(for: key), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func insets(for prefix: String) -> UPInsets {
        let fallback = Self.shorthandInsets(value(for: prefix))
        return UPInsets(
            top: length(for: "\(prefix)-top") ?? fallback.top,
            leading: length(for: "\(prefix)-left") ?? fallback.leading,
            bottom: length(for: "\(prefix)-bottom") ?? fallback.bottom,
            trailing: length(for: "\(prefix)-right") ?? fallback.trailing
        )
    }

    private static func shorthandInsets(_ raw: String?) -> UPInsets {
        guard let raw else { return .zero }
        let values = raw
            .split(whereSeparator: { $0.isWhitespace })
            .compactMap { length(String($0)) }
        switch values.count {
        case 1:
            return UPInsets(top: values[0], leading: values[0], bottom: values[0], trailing: values[0])
        case 2:
            return UPInsets(top: values[0], leading: values[1], bottom: values[0], trailing: values[1])
        case 3:
            return UPInsets(top: values[0], leading: values[1], bottom: values[2], trailing: values[1])
        case 4...:
            return UPInsets(top: values[0], leading: values[3], bottom: values[2], trailing: values[1])
        default:
            return .zero
        }
    }

    private static func length(_ raw: String?) -> CGFloat? {
        guard var raw else { return nil }
        raw = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !raw.isEmpty, !raw.hasSuffix("%") else { return nil }

        if raw.hasSuffix("rpx") {
            guard let value = Double(raw.dropLast(3)), value.isFinite else { return nil }
            return UPUnit.rpx(CGFloat(value))
        }
        if raw.hasSuffix("px") {
            guard let value = Double(raw.dropLast(2)), value.isFinite else { return nil }
            return CGFloat(value)
        }
        guard let value = Double(raw), value.isFinite else { return nil }
        return CGFloat(value)
    }

    private static func normalizedKey(_ key: String) -> String {
        key
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
    }
}

public struct UPInsets: Equatable, Sendable {
    public var top: CGFloat
    public var leading: CGFloat
    public var bottom: CGFloat
    public var trailing: CGFloat

    public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    public static let zero = UPInsets()
}

public enum UPTextAlignment: String, Equatable, Sendable {
    case leading
    case center
    case trailing

    var swiftUIValue: TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

public extension View {
    /// Applies the deterministic native subset of a uview-plus `customStyle`.
    func upStyle(_ style: UPStyle) -> some View {
        modifier(UPStyleModifier(style: style))
    }
}

private struct UPStyleModifier: ViewModifier {
    let style: UPStyle

    func body(content: Content) -> some View {
        content
            .frame(width: style.width, height: style.height)
            .padding(.top, style.padding.top)
            .padding(.leading, style.padding.leading)
            .padding(.bottom, style.padding.bottom)
            .padding(.trailing, style.padding.trailing)
            .foregroundColor(style.foregroundColor.map { UPColor.parse($0) })
            .background {
                if let backgroundColor = style.backgroundColor {
                    UPColor.parse(backgroundColor)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius ?? 0))
            .opacity(style.opacity ?? 1)
            .padding(.top, style.margin.top)
            .padding(.leading, style.margin.leading)
            .padding(.bottom, style.margin.bottom)
            .padding(.trailing, style.margin.trailing)
    }
}
