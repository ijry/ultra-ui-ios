import Foundation
import SwiftUI

/// Semantic alias for the `String | Number` props accepted by `u-badge`.
public typealias UPBadgeUnitValue = UPCheckboxUnitValue

/// Native SwiftUI counterpart of uview-plus `u-badge`.
///
/// The public prop names and defaults mirror the upstream component. SwiftUI
/// callers place an absolute badge in a `ZStack`; `absolute` then maps the
/// uview-plus `[top, right]` offset to native view positioning.
public struct UPBadge: View {
    var isDot: Bool
    var value: String
    var modelValue: String?
    var show: Bool
    var max: Int
    var type: String
    var showZero: Bool
    var bgColor: String?
    var color: String?
    var shape: String
    var numberType: String
    var offset: [CGFloat]
    var inverted: Bool
    var absolute: Bool
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no CSS-class analogue.
    var customClass: String
    var customStyle: UPStyle

    @Environment(\.upTheme) private var theme

    /// Creates a badge while accepting the upstream `String | Number` values
    /// independently. Native layout keeps `value` as a string and normalizes
    /// `max` to the numeric threshold used by uview-plus formatting.
    public init(isDot: Bool = UPConfig.badge.isDot,
                value: some UPBadgeUnitValue = UPConfig.badge.value,
                modelValue: (any UPBadgeUnitValue)? = UPConfig.badge.modelValue,
                show: Bool = UPConfig.badge.show,
                max: some UPBadgeUnitValue = UPConfig.badge.max,
                type: String = UPConfig.badge.type,
                showZero: Bool = UPConfig.badge.showZero,
                bgColor: String? = UPConfig.badge.bgColor,
                color: String? = UPConfig.badge.color,
                shape: String = UPConfig.badge.shape,
                numberType: String = UPConfig.badge.numberType,
                offset: [CGFloat] = UPConfig.badge.offset,
                inverted: Bool = UPConfig.badge.inverted,
                absolute: Bool = UPConfig.badge.absolute,
                customClass: String = UPConfig.badge.customClass,
                customStyle: UPStyle = UPConfig.badge.customStyle) {
        self.isDot = isDot
        self.value = value.upCheckboxUnitValue
        self.modelValue = modelValue?.upCheckboxUnitValue
        self.show = show
        self.max = Self.integerValue(max.upCheckboxUnitValue)
        self.type = type
        self.showZero = showZero
        self.bgColor = bgColor
        self.color = color
        self.shape = shape
        self.numberType = numberType
        self.offset = offset
        self.inverted = inverted
        self.absolute = absolute
        self.customClass = customClass
        self.customStyle = customStyle
    }

    public var body: some View {
        Group {
            if shouldDisplay {
                badgeContent
                    .offset(x: horizontalOffset, y: verticalOffset)
                    .upStyle(customStyle)
            }
        }
    }

    /// The text shown by the non-dot badge after applying uview-plus `numberType`.
    var displayValue: String {
        Self.formattedValue(resolvedValue, max: max, numberType: numberType)
    }

    static func formattedValue(_ value: String, max: Int, numberType: String) -> String {
        guard let numericValue = Double(value) else { return value }
        switch numberType.lowercased() {
        case "overflow":
            return numericValue > Double(max) ? "\(max)+" : value
        case "ellipsis":
            return numericValue > Double(max) ? "..." : value
        case "limit":
            guard numericValue > 999 else { return value }
            let divisor = numericValue >= 9_999 ? 10_000.0 : 1_000.0
            let suffix = numericValue >= 9_999 ? "w" : "k"
            let truncated = floor(numericValue / divisor * 100) / 100
            return "\(Self.compactDecimal(truncated))\(suffix)"
        default:
            return value
        }
    }

    private static func integerValue(_ value: String) -> Int {
        Int(UPUnit.parse(value))
    }

    private static func compactDecimal(_ value: Double) -> String {
        let formatted = String(format: "%.2f", value)
        return formatted
            .replacingOccurrences(of: #"(?<=\d)0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }

    /// uview-plus renders the `value` prop; `modelValue` remains part of the
    /// public Vue-facing surface but does not replace the rendered value.
    private var resolvedValue: String {
        value
    }

    private var shouldDisplay: Bool {
        guard show else { return false }
        guard isDot || !resolvedValue.isEmpty else { return false }
        guard showZero || Double(resolvedValue) != 0 else { return false }
        return true
    }

    @ViewBuilder
    private var badgeContent: some View {
        if isDot {
            Circle()
                .fill(resolvedBackgroundColor)
                .frame(width: 8, height: 8)
        } else {
            Text(displayValue)
                .font(.system(size: inverted ? 13 : 11))
                .foregroundStyle(resolvedTextColor)
                .lineLimit(1)
                .padding(.vertical, 2)
                .padding(.horizontal, 5)
                .background(resolvedBackgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(resolvedBorderColor, lineWidth: inverted ? 1 : 0)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    private var resolvedBaseColor: Color {
        UPColor.parse(type, theme: theme)
    }

    private var resolvedBackgroundColor: Color {
        if inverted { return .clear }
        if let bgColor, !bgColor.isEmpty {
            return UPColor.parse(bgColor, theme: theme)
        }
        return resolvedBaseColor
    }

    private var resolvedTextColor: Color {
        if let color, !color.isEmpty {
            return UPColor.parse(color, theme: theme)
        }
        return inverted ? resolvedBaseColor : .white
    }

    private var resolvedBorderColor: Color {
        if let bgColor, !bgColor.isEmpty {
            return UPColor.parse(bgColor, theme: theme)
        }
        return resolvedBaseColor
    }

    private var cornerRadius: CGFloat {
        shape.lowercased() == "horn" ? 4 : 100
    }

    private var verticalOffset: CGFloat {
        absolute ? (offset.first ?? 0) : 0
    }

    private var horizontalOffset: CGFloat {
        guard absolute else { return 0 }
        let right = offset.count > 1 ? offset[1] : (offset.first ?? 0)
        return -right
    }
}
