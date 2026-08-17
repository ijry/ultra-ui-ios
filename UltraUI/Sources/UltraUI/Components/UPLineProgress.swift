import SwiftUI

/// A string-or-number value accepted by uview-plus `u-line-progress` props.
///
/// The original spelling is retained on the component so callers can use the
/// same String/Number surface as the Vue component while SwiftUI gets a
/// deterministic numeric representation for layout.
public protocol UPLineProgressUnitValue {
    var upLineProgressUnitValue: String { get }
}

extension String: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { self }
}

extension Int: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { String(self) }
}

extension Int8: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { String(self) }
}

extension Int16: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { String(self) }
}

extension Int32: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { String(self) }
}

extension Int64: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { String(self) }
}

extension UInt: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { String(self) }
}

extension UInt8: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { String(self) }
}

extension UInt16: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { String(self) }
}

extension UInt32: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { String(self) }
}

extension UInt64: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String { String(self) }
}

extension Double: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String {
        guard isFinite else { return "0" }
        return rounded() == self ? String(Int(self)) : String(self)
    }
}

extension Float: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String {
        Double(self).upLineProgressUnitValue
    }
}

extension CGFloat: UPLineProgressUnitValue {
    public var upLineProgressUnitValue: String {
        Double(self).upLineProgressUnitValue
    }
}

/// Native SwiftUI counterpart of uview-plus `u-line-progress`.
///
/// Props, defaults, percentage clamping, right-to-left placement, custom
/// styling, and the default slot follow the checked-in uview-plus component.
/// The trailing `ViewBuilder` initializer maps to the Vue default slot.
public struct UPLineProgress: View {
    var activeColor: String
    var inactiveColor: String
    var percentage: String
    var showText: Bool
    var height: String
    var fromRight: Bool
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no CSS-class analogue.
    var customClass: String
    var customStyle: UPStyle
    private var defaultSlotContent: AnyView?

    @Environment(\.upTheme) private var theme

    public init<Percentage: UPLineProgressUnitValue, Height: UPLineProgressUnitValue>(
        activeColor: String = UPConfig.lineProgress.activeColor,
        inactiveColor: String = UPConfig.lineProgress.inactiveColor,
        percentage: Percentage = UPConfig.lineProgress.percentage,
        showText: Bool = UPConfig.lineProgress.showText,
        height: Height = UPConfig.lineProgress.height,
        fromRight: Bool = UPConfig.lineProgress.fromRight,
        customClass: String = UPConfig.lineProgress.customClass,
        customStyle: UPStyle = UPConfig.lineProgress.customStyle
    ) {
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.percentage = percentage.upLineProgressUnitValue
        self.showText = showText
        self.height = height.upLineProgressUnitValue
        self.fromRight = fromRight
        self.customClass = customClass
        self.customStyle = customStyle
        self.defaultSlotContent = nil
    }

    /// Maps the uview-plus default slot to native SwiftUI content.
    public init<Content: View, Percentage: UPLineProgressUnitValue, Height: UPLineProgressUnitValue>(
        activeColor: String = UPConfig.lineProgress.activeColor,
        inactiveColor: String = UPConfig.lineProgress.inactiveColor,
        percentage: Percentage = UPConfig.lineProgress.percentage,
        showText: Bool = UPConfig.lineProgress.showText,
        height: Height = UPConfig.lineProgress.height,
        fromRight: Bool = UPConfig.lineProgress.fromRight,
        customClass: String = UPConfig.lineProgress.customClass,
        customStyle: UPStyle = UPConfig.lineProgress.customStyle,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            percentage: percentage,
            showText: showText,
            height: height,
            fromRight: fromRight,
            customClass: customClass,
            customStyle: customStyle
        )
        self.defaultSlotContent = AnyView(content())
    }

    public var body: some View {
        GeometryReader { proxy in
            progressBar(containerWidth: proxy.size.width)
        }
        .frame(height: resolvedHeight)
        .upStyle(customStyle)
    }

    /// The spelling intentionally mirrors uview-plus' public computed prop.
    /// The upstream implementation clamps the numeric percentage to 0...100.
    var innserPercentage: Double {
        Self.clampedPercentage(from: percentage)
    }

    /// Height after resolving the String/Number prop to native points.
    var resolvedHeight: CGFloat {
        max(UPUnit.parse(height), 0)
    }

    /// Active-line width for a measured background width.
    func resolvedLineWidth(in containerWidth: CGFloat) -> CGFloat {
        max(containerWidth, 0) * CGFloat(innserPercentage) / 100
    }

    /// Text rendered by the component's default slot when no custom slot is
    /// supplied and the upstream threshold permits it.
    var defaultText: String {
        "\(Self.formattedPercentage(innserPercentage))%"
    }

    /// Whether uview-plus would render its built-in percentage text.
    var showsDefaultText: Bool {
        !hasDefaultSlot && showText && (Self.numericValue(from: percentage) ?? 0) >= 10
    }

    var hasDefaultSlot: Bool {
        defaultSlotContent != nil
    }

    @ViewBuilder
    private func progressBar(containerWidth: CGFloat) -> some View {
        let lineWidth = resolvedLineWidth(in: containerWidth)
        let cornerRadius = max(resolvedHeight / 2, 0)

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(UPColor.parse(inactiveColor, theme: theme))

            HStack(spacing: 0) {
                if fromRight {
                    Spacer(minLength: 0)
                }

                activeLine
                    .frame(width: lineWidth, height: resolvedHeight)

                if !fromRight {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .animation(.easeInOut(duration: 0.5), value: innserPercentage)
    }

    private var activeLine: some View {
        HStack(spacing: 0) {
            if let defaultSlotContent {
                defaultSlotContent
            } else if showsDefaultText {
                Text(defaultText)
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                    .padding(.trailing, 5)
                    .scaleEffect(0.9)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .background(UPColor.parse(activeColor, theme: theme))
        .clipShape(RoundedRectangle(cornerRadius: max(resolvedHeight / 2, 0), style: .continuous))
    }

    private static func numericValue(from raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Double(trimmed), value.isFinite else {
            return trimmed.isEmpty ? 0 : nil
        }
        return value
    }

    private static func clampedPercentage(from raw: String) -> Double {
        let value = numericValue(from: raw) ?? 0
        return min(max(value, 0), 100)
    }

    private static func formattedPercentage(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        return value.rounded() == value ? String(Int(value)) : String(value)
    }
}
