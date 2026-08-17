import SwiftUI

/// Values accepted by uview-plus `u-rate` `value` and `modelValue` props.
///
/// The upstream component accepts strings and numbers, then normalizes them
/// through JavaScript's `Number(...)`. `UPRateValueInput` preserves that public
/// surface while using `Double` internally for whole- and half-star ratings.
public protocol UPRateValueInput {
    var upRateValue: Double? { get }
}

extension String: UPRateValueInput {
    public var upRateValue: Double? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        guard let number = Double(value), number.isFinite else { return nil }
        return number
    }
}

public extension UPRateValueInput where Self: BinaryInteger {
    var upRateValue: Double? {
        let number = Double(self)
        return number.isFinite ? number : nil
    }
}

extension Int: UPRateValueInput {}
extension Int8: UPRateValueInput {}
extension Int16: UPRateValueInput {}
extension Int32: UPRateValueInput {}
extension Int64: UPRateValueInput {}
extension UInt: UPRateValueInput {}
extension UInt8: UPRateValueInput {}
extension UInt16: UPRateValueInput {}
extension UInt32: UPRateValueInput {}
extension UInt64: UPRateValueInput {}

public extension UPRateValueInput where Self: BinaryFloatingPoint {
    var upRateValue: Double? {
        guard isFinite else { return nil }
        let number = Double(self)
        return number.isFinite ? number : nil
    }
}

extension Double: UPRateValueInput {}
extension Float: UPRateValueInput {}
extension CGFloat: UPRateValueInput {}

/// Native values whose bindings can receive a normalized uview-plus rating.
///
/// `Binding<Int>` intentionally writes only whole-star values. Use
/// `Binding<Double>`, `Binding<CGFloat>`, or `Binding<String>` when
/// `allowHalf` is enabled and the model must retain half-star choices.
public protocol UPRateBindingValue: UPRateValueInput {
    static func upRateBindingValue(from value: Double) -> Self?
}

extension String: UPRateBindingValue {
    public static func upRateBindingValue(from value: Double) -> String? {
        guard value.isFinite else { return nil }
        return UPRate.format(value)
    }
}

public extension UPRateBindingValue where Self: BinaryInteger {
    static func upRateBindingValue(from value: Double) -> Self? {
        guard value.isFinite, value.rounded() == value else { return nil }
        return Self(exactly: value)
    }
}

extension Int: UPRateBindingValue {}
extension Int8: UPRateBindingValue {}
extension Int16: UPRateBindingValue {}
extension Int32: UPRateBindingValue {}
extension Int64: UPRateBindingValue {}
extension UInt: UPRateBindingValue {}
extension UInt8: UPRateBindingValue {}
extension UInt16: UPRateBindingValue {}
extension UInt32: UPRateBindingValue {}
extension UInt64: UPRateBindingValue {}

public extension UPRateBindingValue where Self: BinaryFloatingPoint {
    static func upRateBindingValue(from value: Double) -> Self? {
        guard value.isFinite else { return nil }
        let converted = Self(value)
        return converted.isFinite ? converted : nil
    }
}

extension Double: UPRateBindingValue {}
extension Float: UPRateBindingValue {}
extension CGFloat: UPRateBindingValue {}

/// Semantic alias for uview-plus `u-rate` size, gutter, count, and minCount
/// props. They accept the same String-or-Number call surface as the upstream
/// component.
public typealias UPRateUnitValue = UPCheckboxUnitValue

/// Native SwiftUI counterpart of uview-plus `u-rate`.
///
/// `modelValue` maps to a SwiftUI `Binding`, while the `value` initializer
/// retains the legacy Vue 2 prop as an uncontrolled initial value. `change`
/// is represented by `onChange`; just like the upstream component it is
/// invoked *before* the bound `modelValue` is written.
@MainActor
public struct UPRate: View {
    var customClass: String
    var value: Double
    var count: String
    var disabled: Bool
    var readonly: Bool
    var size: String
    var inactiveColor: String
    var activeColor: String
    var gutter: String
    var minCount: String
    var allowHalf: Bool
    var activeIcon: String
    var inactiveIcon: String
    var touchable: Bool
    var customStyle: UPStyle

    private var modelValue: Binding<Double>?
    private var onChangeHandler: ((Double) -> Void)?
    @State private var localValue: Double
    @Environment(\.upTheme) private var theme

    public init<Value: UPRateValueInput, Count: UPRateUnitValue, Size: UPRateUnitValue, Gutter: UPRateUnitValue, MinCount: UPRateUnitValue>(
        customClass: String = UPConfig.rate.customClass,
        value: Value = UPConfig.rate.value,
        count: Count = UPConfig.rate.count,
        disabled: Bool = UPConfig.rate.disabled,
        readonly: Bool = UPConfig.rate.readonly,
        size: Size = UPConfig.rate.size,
        inactiveColor: String = UPConfig.rate.inactiveColor,
        activeColor: String = UPConfig.rate.activeColor,
        gutter: Gutter = UPConfig.rate.gutter,
        minCount: MinCount = UPConfig.rate.minCount,
        allowHalf: Bool = UPConfig.rate.allowHalf,
        activeIcon: String = UPConfig.rate.activeIcon,
        inactiveIcon: String = UPConfig.rate.inactiveIcon,
        touchable: Bool = UPConfig.rate.touchable,
        customStyle: UPStyle = UPConfig.rate.customStyle,
        onChange: ((Double) -> Void)? = nil
    ) {
        self.init(
            customClass: customClass,
            modelValue: nil,
            value: value.upRateValue ?? Self.number(from: minCount.upCheckboxUnitValue, fallback: 0),
            count: count.upCheckboxUnitValue,
            disabled: disabled,
            readonly: readonly,
            size: size.upCheckboxUnitValue,
            inactiveColor: inactiveColor,
            activeColor: activeColor,
            gutter: gutter.upCheckboxUnitValue,
            minCount: minCount.upCheckboxUnitValue,
            allowHalf: allowHalf,
            activeIcon: activeIcon,
            inactiveIcon: inactiveIcon,
            touchable: touchable,
            customStyle: customStyle,
            onChange: onChange
        )
    }

    /// Native `Binding` equivalent of Vue 3 `v-model:modelValue`.
    public init<Model: UPRateBindingValue, Count: UPRateUnitValue, Size: UPRateUnitValue, Gutter: UPRateUnitValue, MinCount: UPRateUnitValue>(
        customClass: String = UPConfig.rate.customClass,
        modelValue: Binding<Model>,
        count: Count = UPConfig.rate.count,
        disabled: Bool = UPConfig.rate.disabled,
        readonly: Bool = UPConfig.rate.readonly,
        size: Size = UPConfig.rate.size,
        inactiveColor: String = UPConfig.rate.inactiveColor,
        activeColor: String = UPConfig.rate.activeColor,
        gutter: Gutter = UPConfig.rate.gutter,
        minCount: MinCount = UPConfig.rate.minCount,
        allowHalf: Bool = UPConfig.rate.allowHalf,
        activeIcon: String = UPConfig.rate.activeIcon,
        inactiveIcon: String = UPConfig.rate.inactiveIcon,
        touchable: Bool = UPConfig.rate.touchable,
        customStyle: UPStyle = UPConfig.rate.customStyle,
        onChange: ((Double) -> Void)? = nil
    ) {
        let erasedBinding = Self.erase(modelValue)
        self.init(
            customClass: customClass,
            modelValue: erasedBinding,
            value: erasedBinding.wrappedValue,
            count: count.upCheckboxUnitValue,
            disabled: disabled,
            readonly: readonly,
            size: size.upCheckboxUnitValue,
            inactiveColor: inactiveColor,
            activeColor: activeColor,
            gutter: gutter.upCheckboxUnitValue,
            minCount: minCount.upCheckboxUnitValue,
            allowHalf: allowHalf,
            activeIcon: activeIcon,
            inactiveIcon: inactiveIcon,
            touchable: touchable,
            customStyle: customStyle,
            onChange: onChange
        )
    }

    private init(
        customClass: String,
        modelValue: Binding<Double>?,
        value: Double,
        count: String,
        disabled: Bool,
        readonly: Bool,
        size: String,
        inactiveColor: String,
        activeColor: String,
        gutter: String,
        minCount: String,
        allowHalf: Bool,
        activeIcon: String,
        inactiveIcon: String,
        touchable: Bool,
        customStyle: UPStyle,
        onChange: ((Double) -> Void)?
    ) {
        self.customClass = customClass
        self.modelValue = modelValue
        self.value = value
        self.count = count
        self.disabled = disabled
        self.readonly = readonly
        self.size = size
        self.inactiveColor = inactiveColor
        self.activeColor = activeColor
        self.gutter = gutter
        self.minCount = minCount
        self.allowHalf = allowHalf
        self.activeIcon = activeIcon
        self.inactiveIcon = inactiveIcon
        self.touchable = touchable
        self.customStyle = customStyle
        self.onChangeHandler = onChange
        self._localValue = State(initialValue: Self.normalize(value, count: count, minCount: minCount))
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<resolvedCount, id: \.self) { index in
                rateItem(index)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            SpatialTapGesture(coordinateSpace: .local)
                .onEnded { gesture in
                    triggerTap(at: gesture.location.x)
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .local)
                .onChanged { gesture in
                    triggerTouch(at: gesture.location.x)
                }
                .onEnded { gesture in
                    triggerTouch(at: gesture.location.x)
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityValue(UPRate.format(activeIndex))
        .accessibilityAddTraits(disabled || readonly ? .isStaticText : .isButton)
        .upStyle(customStyle)
        .onChange(of: value) { _, newValue in
            guard modelValue == nil else { return }
            $localValue.wrappedValue = Self.normalize(newValue, count: count, minCount: minCount)
        }
    }

    /// Current normalized rating, mirroring uview-plus's `activeIndex`.
    var activeIndex: Double {
        Self.normalize(currentValue, count: count, minCount: minCount)
    }

    /// Effective display count. uview-plus treats non-positive or invalid
    /// counts as an empty rating control.
    var resolvedCount: Int {
        let number = resolvedCountValue
        guard number.isFinite, number > 0 else { return 0 }
        let clamped = min(number, Double(Int.max))
        return Int(clamped.rounded(.up))
    }

    var resolvedSize: CGFloat {
        let parsed = UPUnit.parse(size)
        return parsed > 0 ? parsed : 18
    }

    var resolvedGutter: CGFloat {
        max(UPUnit.parse(gutter), 0)
    }

    /// Upstream measures each padded icon wrapper, so both the glyph size and
    /// the full `gutter` participate in click and drag selection geometry.
    var resolvedItemWidth: CGFloat {
        max(resolvedSize + resolvedGutter, 1)
    }

    /// Native/testable counterpart of tapping an icon wrapper. `index` is
    /// one-based, matching the `index + 1` argument passed by uview-plus.
    func triggerTap(index: Int, fraction: CGFloat = 1) {
        let x = (CGFloat(index - 1) + fraction) * resolvedItemWidth
        updateSelection(at: x, isClick: true)
    }

    /// Native/testable counterpart of an upstream click/tap at a local x
    /// coordinate. Unlike drag selection, it remains active when
    /// `touchable == false`.
    func triggerTap(at x: CGFloat) {
        updateSelection(at: x, isClick: true)
    }

    /// Native/testable counterpart of upstream `touchmove` / `touchend`.
    /// `touchable` only gates these drag paths; it does not disable taps.
    func triggerTouch(at x: CGFloat) {
        guard touchable else { return }
        updateSelection(at: x, isClick: false)
    }

    /// Formats an upstream numeric change payload for String model bindings.
    public nonisolated static func format(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        if value.rounded() == value,
           value >= Double(Int.min),
           value <= Double(Int.max) {
            return String(Int(value))
        }
        return String(value)
    }

    private static func erase<Model: UPRateBindingValue>(_ binding: Binding<Model>) -> Binding<Double> {
        Binding<Double>(
            get: { binding.wrappedValue.upRateValue ?? 0 },
            set: { incomingValue in
                guard let typedValue = Model.upRateBindingValue(from: incomingValue) else { return }
                binding.wrappedValue = typedValue
            }
        )
    }

    private static func number(from raw: String, fallback: Double) -> Double {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed), value.isFinite else { return fallback }
        return value
    }

    private static func normalize(_ value: Double, count: String, minCount: String) -> Double {
        let min = number(from: minCount, fallback: 0)
        let maximum = number(from: count, fallback: 0)
        var normalized = value.isFinite ? value : min
        if normalized < min {
            normalized = min
        }
        if maximum > 0, normalized > maximum {
            normalized = maximum
        }
        return normalized
    }

    private var currentValue: Double {
        modelValue?.wrappedValue ?? localValue
    }

    private var selectionBinding: Binding<Double> {
        modelValue ?? $localValue
    }

    private var resolvedCountValue: Double {
        Self.number(from: count, fallback: 0)
    }

    private var resolvedMinCount: Double {
        Self.number(from: minCount, fallback: 0)
    }

    private func updateSelection(at x: CGFloat, isClick: Bool) {
        guard !disabled, !readonly,
              resolvedCountValue > 0,
              resolvedItemWidth > 0,
              x.isFinite else {
            return
        }

        let totalWidth = resolvedItemWidth * CGFloat(resolvedCountValue)
        let distance = min(max(x, 0), totalWidth)
        let width = resolvedItemWidth
        var proposed: Double

        if allowHalf {
            let whole = floor(distance / width)
            let decimal = distance.truncatingRemainder(dividingBy: width)
            if decimal > 0, decimal <= width / 2 {
                proposed = whole + 0.5
            } else if decimal > width / 2 {
                proposed = whole + 1
            } else {
                proposed = whole
            }
        } else {
            let whole = floor(distance / width)
            let decimal = distance.truncatingRemainder(dividingBy: width)
            proposed = whole
            if isClick {
                if decimal > 0 {
                    proposed += 1
                }
            } else if decimal > width / 2 {
                proposed += 1
            }
        }

        proposed = Self.normalize(min(proposed, resolvedCountValue), count: count, minCount: minCount)
        // u-rate applies this extra lower-bound clamp after click/drag
        // normalization. It matters when callers supply `minCount > count`.
        if proposed < resolvedMinCount {
            proposed = resolvedMinCount
        }

        guard proposed != activeIndex else { return }

        // `activeIndex`'s Vue watcher emits change before update:modelValue.
        onChangeHandler?(proposed)
        selectionBinding.wrappedValue = proposed
    }

    @ViewBuilder
    private func rateItem(_ index: Int) -> some View {
        let isWholeActive = floor(activeIndex) > Double(index)
        let isHalfActive = allowHalf && ceil(activeIndex) > Double(index)
        let inactive = disabled ? "disabled" : resolvedInactiveColor
        let active = disabled ? "disabled" : resolvedActiveColor

        ZStack(alignment: .leading) {
            UPIcon(
                name: isWholeActive ? activeIcon : inactiveIcon,
                color: isWholeActive ? active : inactive,
                size: UPRate.format(Double(resolvedSize))
            )
            .frame(width: resolvedSize, height: resolvedSize)

            if isHalfActive {
                UPIcon(
                    name: activeIcon,
                    color: active,
                    size: UPRate.format(Double(resolvedSize))
                )
                .frame(width: resolvedSize, height: resolvedSize)
                .frame(width: resolvedSize / 2, alignment: .leading)
                .clipped()
            }
        }
        .frame(width: resolvedItemWidth, height: resolvedSize, alignment: .center)
    }

    private var resolvedActiveColor: String {
        activeColor.isEmpty ? "primary" : activeColor
    }

    private var resolvedInactiveColor: String {
        inactiveColor.isEmpty ? "tips" : inactiveColor
    }
}

public extension UPRate {
    /// Registers the uview-plus `change(value)` callback.
    func onChange(_ action: @escaping (Double) -> Void) -> UPRate {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }
}
