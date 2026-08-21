import SwiftUI

public protocol UPSliderValueInput {
    var upSliderValue: Double? { get }
}

public protocol UPSliderBindingValue: UPSliderValueInput {
    static func upSliderValue(from value: Double) -> Self?
}

extension String: UPSliderBindingValue {
    public var upSliderValue: Double? { Double(trimmingCharacters(in: .whitespacesAndNewlines)) }
    public static func upSliderValue(from value: Double) -> String? {
        guard value.isFinite else { return nil }
        return value.rounded() == value ? String(Int(value)) : String(value)
    }
}

extension Int: UPSliderBindingValue {
    public var upSliderValue: Double? { Double(self) }
    public static func upSliderValue(from value: Double) -> Int? { Int(exactly: value) }
}

extension Double: UPSliderBindingValue {
    public var upSliderValue: Double? { isFinite ? self : nil }
    public static func upSliderValue(from value: Double) -> Double? { value.isFinite ? value : nil }
}

extension CGFloat: UPSliderBindingValue {
    public var upSliderValue: Double? { Double(self) }
    public static func upSliderValue(from value: Double) -> CGFloat? { value.isFinite ? CGFloat(value) : nil }
}

public struct UPSliderRangeValue: Equatable, Sendable {
    public var lower: Double
    public var upper: Double

    public init(lower: Double, upper: Double) {
        self.lower = lower
        self.upper = upper
    }
}

/// Native counterpart of uview-plus `u-slider`, including deterministic
/// normalization helpers for String-or-Number props.
@MainActor
public struct UPSlider: View {
    public var value: Double
    public var blockSize: Double
    public var min: Double
    public var max: Double
    public var step: Double
    public var activeColor: String
    public var inactiveColor: String
    public var blockColor: String
    public var showValue: Bool
    public var disabled: Bool
    public var blockStyle: UPStyle
    public var useNative: Bool
    public var height: String
    public var innerStyle: UPStyle
    public var vertical: Bool
    public var size: String
    public var length: String
    public var isRange: Bool

    private var valueBinding: Binding<Double>?
    private var rangeBinding: Binding<UPSliderRangeValue>?
    private var rangeValue: UPSliderRangeValue
    private var onStartHandler: (() -> Void)?
    private var onChangingHandler: ((Double) -> Void)?
    private var onChangeHandler: ((Double) -> Void)?

    public init<Value: UPSliderValueInput, Block: UPSliderValueInput, Min: UPSliderValueInput, Max: UPSliderValueInput, Step: UPSliderValueInput>(
        value: Value = 0, blockSize: Block = 18, min: Min = 0, max: Max = 100, step: Step = 1,
        activeColor: String = "#2979ff", inactiveColor: String = "#c0c4cc", blockColor: String = "#ffffff",
        showValue: Bool = false, disabled: Bool = false, blockStyle: UPStyle = UPStyle(), useNative: Bool = false,
        height: String = "", innerStyle: UPStyle = UPStyle(), vertical: Bool = false, size: String = "2px",
        length: String = "auto", isRange: Bool = false, rangeValue: UPSliderRangeValue = .init(lower: 0, upper: 0)
    ) {
        self.init(value: value.upSliderValue ?? 0, blockSize: blockSize.upSliderValue ?? 18,
                  min: min.upSliderValue ?? 0, max: max.upSliderValue ?? 100, step: step.upSliderValue ?? 1,
                  activeColor: activeColor, inactiveColor: inactiveColor, blockColor: blockColor,
                  showValue: showValue, disabled: disabled, blockStyle: blockStyle, useNative: useNative,
                  height: height, innerStyle: innerStyle, vertical: vertical, size: size, length: length,
                  isRange: isRange, rangeValue: rangeValue)
    }

    private init(value: Double, blockSize: Double, min: Double, max: Double, step: Double,
                 activeColor: String, inactiveColor: String, blockColor: String, showValue: Bool,
                 disabled: Bool, blockStyle: UPStyle, useNative: Bool, height: String, innerStyle: UPStyle,
                 vertical: Bool, size: String, length: String, isRange: Bool, rangeValue: UPSliderRangeValue) {
        self.value = value
        self.blockSize = blockSize
        self.min = min
        self.max = max
        self.step = step
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.blockColor = blockColor
        self.showValue = showValue
        self.disabled = disabled
        self.blockStyle = blockStyle
        self.useNative = useNative
        self.height = height
        self.innerStyle = innerStyle
        self.vertical = vertical
        self.size = size
        self.length = length
        self.isRange = isRange
        self.rangeValue = rangeValue
        self.valueBinding = nil
        self.rangeBinding = nil
    }

    public init<Value: UPSliderBindingValue>(modelValue: Binding<Value>, blockSize: Double = 18,
        min: Double = 0, max: Double = 100, step: Double = 1, activeColor: String = "#2979ff",
        inactiveColor: String = "#c0c4cc", blockColor: String = "#ffffff", showValue: Bool = false,
        disabled: Bool = false, blockStyle: UPStyle = UPStyle(), useNative: Bool = false, height: String = "",
        innerStyle: UPStyle = UPStyle(), vertical: Bool = false, size: String = "2px", length: String = "auto") {
        self.init(value: modelValue.wrappedValue.upSliderValue ?? 0, blockSize: blockSize, min: min, max: max, step: step,
                  activeColor: activeColor, inactiveColor: inactiveColor, blockColor: blockColor,
                  showValue: showValue, disabled: disabled, blockStyle: blockStyle, useNative: useNative,
                  height: height, innerStyle: innerStyle, vertical: vertical, size: size, length: length,
                  isRange: false, rangeValue: .init(lower: 0, upper: 0))
        self.valueBinding = Binding(
            get: { modelValue.wrappedValue.upSliderValue ?? 0 },
            set: { newValue in
                if let converted = Value.upSliderValue(from: newValue) {
                    modelValue.wrappedValue = converted
                }
            }
        )
    }

    public init(rangeValue: Binding<UPSliderRangeValue>, min: Double = 0, max: Double = 100, step: Double = 1,
        activeColor: String = "#2979ff", inactiveColor: String = "#c0c4cc", blockColor: String = "#ffffff",
        showValue: Bool = false, disabled: Bool = false, blockStyle: UPStyle = UPStyle(), useNative: Bool = false,
        height: String = "", innerStyle: UPStyle = UPStyle(), vertical: Bool = false, size: String = "2px", length: String = "auto") {
        self.init(value: rangeValue.wrappedValue.lower, blockSize: 18, min: min, max: max, step: step,
                  activeColor: activeColor, inactiveColor: inactiveColor, blockColor: blockColor,
                  showValue: showValue, disabled: disabled, blockStyle: blockStyle, useNative: useNative,
                  height: height, innerStyle: innerStyle, vertical: vertical, size: size, length: length,
                  isRange: true, rangeValue: rangeValue.wrappedValue)
        self.rangeBinding = rangeValue
    }

    public var body: some View {
        Group {
            if isRange { rangeBody } else { singleBody }
        }
        .frame(height: vertical ? nil : (height.isEmpty ? 24 : UPUnit.parse(height)))
        .frame(width: vertical ? (length == "auto" ? 24 : UPUnit.parse(length)) : nil)
        .upStyle(innerStyle)
    }

    @ViewBuilder private var singleBody: some View {
        Slider(value: Binding(get: { currentValue }, set: { updateValue($0, changing: true) }),
               in: lowerBound...upperBound, step: normalizedStep)
            .tint(UPColor.parse(activeColor))
            .disabled(disabled)
            .rotationEffect(vertical ? .degrees(-90) : .zero)
        if showValue { Text(format(currentValue)).font(.caption) }
    }

    @ViewBuilder private var rangeBody: some View {
        HStack(spacing: 0) {
            Slider(value: Binding(get: { currentRange.lower }, set: { changeLower(to: $0) }),
                   in: lowerBound...upperBound, step: normalizedStep)
            Slider(value: Binding(get: { currentRange.upper }, set: { changeUpper(to: $0) }),
                   in: lowerBound...upperBound, step: normalizedStep)
        }
        .tint(UPColor.parse(activeColor))
        .disabled(disabled)
    }

    public func onStart(_ action: @escaping () -> Void) -> Self { var c = self; c.onStartHandler = action; return c }
    public func onChanging(_ action: @escaping (Double) -> Void) -> Self { var c = self; c.onChangingHandler = action; return c }
    public func onChange(_ action: @escaping (Double) -> Void) -> Self { var c = self; c.onChangeHandler = action; return c }

    public func startInteraction() { guard !disabled else { return }; onStartHandler?() }
    public func changeInteraction(to value: Double) { guard !disabled else { return }; updateValue(value, changing: true) }
    public func endInteraction() { guard !disabled else { return }; onChangeHandler?(currentValue) }
    public func changeLower(to value: Double) { updateRange(lower: value, upper: nil) }
    public func changeUpper(to value: Double) { updateRange(lower: nil, upper: value) }

    private var lowerBound: Double { Swift.min(min, max) }
    private var upperBound: Double { Swift.max(min, max) }
    private var normalizedStep: Double { step.isFinite && step > 0 ? step : 1 }
    private var currentValue: Double { valueBinding?.wrappedValue ?? normalize(value) }
    private var currentRange: UPSliderRangeValue { rangeBinding?.wrappedValue ?? rangeValue }

    private func normalize(_ raw: Double) -> Double {
        let clamped = Swift.min(Swift.max(raw.isFinite ? raw : lowerBound, lowerBound), upperBound)
        let aligned = lowerBound + ((clamped - lowerBound) / normalizedStep).rounded() * normalizedStep
        return Swift.min(Swift.max(aligned, lowerBound), upperBound)
    }

    private func updateValue(_ raw: Double, changing: Bool) {
        let normalized = normalize(raw)
        if let valueBinding { valueBinding.wrappedValue = normalized }
        onChangingHandler?(normalized)
    }

    private func updateRange(lower: Double?, upper: Double?) {
        guard !disabled else { return }
        var result = currentRange
        if let lower { result.lower = normalize(lower) }
        if let upper { result.upper = normalize(upper) }
        if lower != nil, result.lower > result.upper - normalizedStep {
            result.lower = result.upper - normalizedStep
        }
        if upper != nil, result.upper < result.lower + normalizedStep {
            result.upper = result.lower + normalizedStep
        }
        result.lower = Swift.max(lowerBound, result.lower)
        result.upper = Swift.min(upperBound, result.upper)
        rangeBinding?.wrappedValue = result
        onChangingHandler?(lower ?? upper ?? result.lower)
    }

    private func format(_ value: Double) -> String { value.rounded() == value ? String(Int(value)) : String(value) }
}
