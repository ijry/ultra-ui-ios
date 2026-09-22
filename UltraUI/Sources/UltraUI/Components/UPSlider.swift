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
    private var onRangeChangingHandler: ((UPSliderRangeValue) -> Void)?
    private var onRangeChangeHandler: ((UPSliderRangeValue) -> Void)?

    @Environment(\.upTheme) private var theme

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

    // MARK: - 上游 computed

    /// 上游 `sizeLocal`：`height` 非空时取它，否则取 `size`（默认 `2px`）。
    public var resolvedTrackThickness: CGFloat {
        let raw = height.isEmpty ? size : height
        let parsed = UPUnit.parse(raw)
        return parsed > 0 ? parsed : UPUnit.parse(UPConfig.slider.size)
    }

    /// 上游 `innerStyleCpu`：容器厚度是 `blockSize`，区间 + showValue 时再多 24。
    public var resolvedInnerThickness: CGFloat {
        let base = CGFloat(blockSize)
        return isRange && showValue ? base + UPConfig.slider.rangeValueExtraSpace : base
    }

    /// 上游 `updateValue` 里的 `sliderLength`：值在轨道上的占比长度。
    public func fillLength(for value: Double, trackLength: CGFloat) -> CGFloat {
        let range = upperBound - lowerBound
        guard range > 0, trackLength > 0 else { return 0 }
        let ratio = (normalize(value) - lowerBound) / range
        return Swift.min(CGFloat(ratio) * trackLength, trackLength)
    }

    /// 上游 `touchButtonStyle`：滑块中心落在填充长度加半个 `blockSize` 处。
    public func blockOffset(for value: Double, trackLength: CGFloat) -> CGFloat {
        fillLength(for: value, trackLength: trackLength) + CGFloat(blockSize) / 2
    }

    // MARK: - 视图

    public var body: some View {
        Group {
            if useNative, !isRange { nativeBody } else { customBody }
        }
        // 上游 `--disabled { opacity: 0.5 }`。
        .opacity(disabled ? UPConfig.slider.disabledOpacity : 1)
    }

    /// 上游 `useNative && !isRange` 时直接用平台原生 `<slider>`。
    private var nativeBody: some View {
        HStack(spacing: UPConfig.slider.showValueSpacing) {
            Slider(value: Binding(get: { currentValue }, set: { updateValue($0, changing: true) }),
                   in: lowerBound...upperBound,
                   step: normalizedStep,
                   onEditingChanged: { editing in
                       if editing { startInteraction() } else { endInteraction() }
                   })
                .tint(UPColor.parse(activeColor))
                .disabled(disabled)

            if showValue { Text(format(currentValue)).font(.system(size: 14)) }
        }
    }

    /// 上游自绘形态：底轨 `__base` + 填充 `__gap` + 一或两个 `__button`。
    private var customBody: some View {
        HStack(spacing: UPConfig.slider.showValueSpacing) {
            trackArea

            // 上游 `.__show-value` 只在非区间时渲染在轨道右侧。
            if showValue, !isRange { Text(format(currentValue)).font(.system(size: 14)) }
        }
        .upStyle(innerStyle)
    }

    private var trackArea: some View {
        GeometryReader { proxy in
            let trackLength = vertical ? proxy.size.height : proxy.size.width
            ZStack(alignment: vertical ? .top : .leading) {
                // 上游 `__base`：全长底轨，颜色取 `inactiveColor`。
                Capsule()
                    .fill(UPColor.parse(inactiveColor, theme: theme))
                    .frame(width: vertical ? resolvedTrackThickness : nil,
                           height: vertical ? nil : resolvedTrackThickness)
                    .frame(maxWidth: vertical ? nil : .infinity,
                           maxHeight: vertical ? .infinity : nil)

                // 上游 `__gap`：填充段，颜色取 `activeColor`。区间模式下另有一段
                // `__gap-0` 用 `inactiveColor` 盖住下把手左侧。
                fill(from: isRange ? currentRange.lower : lowerBound,
                     to: isRange ? currentRange.upper : currentValue,
                     trackLength: trackLength)

                if isRange {
                    block(for: currentRange.lower, trackLength: trackLength) { changeLower(to: $0) }
                    block(for: currentRange.upper, trackLength: trackLength) { changeUpper(to: $0) }
                } else {
                    block(for: currentValue, trackLength: trackLength) { updateValue($0, changing: true) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: vertical ? .top : .leading)
        }
        .frame(width: vertical ? resolvedInnerThickness : resolvedTrackLength,
               height: vertical ? resolvedTrackLength : resolvedInnerThickness)
        .padding(vertical ? .vertical : .horizontal, UPConfig.slider.innerHorizontalPadding)
        .padding(vertical ? .horizontal : .vertical, UPConfig.slider.innerVerticalPadding)
    }

    /// 上游 `length` 默认 `auto`，此时轨道随容器伸展。
    private var resolvedTrackLength: CGFloat? {
        guard length != "auto" else { return nil }
        let parsed = UPUnit.parse(length)
        return parsed > 0 ? parsed : nil
    }

    private func fill(from lower: Double, to upper: Double, trackLength: CGFloat) -> some View {
        let start = fillLength(for: lower, trackLength: trackLength)
        let end = fillLength(for: upper, trackLength: trackLength)
        return Capsule()
            .fill(UPColor.parse(activeColor, theme: theme))
            .frame(width: vertical ? resolvedTrackThickness : Swift.max(end - start, 0),
                   height: vertical ? Swift.max(end - start, 0) : resolvedTrackThickness)
            .offset(x: vertical ? 0 : start, y: vertical ? start : 0)
            .animation(.easeOut(duration: UPConfig.slider.gapAnimationDuration), value: end - start)
    }

    /// 上游 `__button`：24pt 圆点、`scale(0.9)`、带一层浅阴影，可被 `blockStyle` 覆盖。
    private func block(for value: Double,
                       trackLength: CGFloat,
                       onDrag: @escaping (Double) -> Void) -> some View {
        Circle()
            .fill(UPColor.parse(blockColor, theme: theme))
            .frame(width: CGFloat(blockSize), height: CGFloat(blockSize))
            .scaleEffect(UPConfig.slider.blockScale)
            .shadow(color: .black.opacity(0.5),
                    radius: UPConfig.slider.blockShadowRadius,
                    y: UPConfig.slider.blockShadowOffsetY)
            .upStyle(blockStyle)
            .offset(x: vertical ? 0 : fillLength(for: value, trackLength: trackLength) - CGFloat(blockSize) / 2,
                    y: vertical ? fillLength(for: value, trackLength: trackLength) - CGFloat(blockSize) / 2 : 0)
            .gesture(dragGesture(trackLength: trackLength, onDrag: onDrag))
            .allowsHitTesting(!disabled)
    }

    /// 上游 `onTouchStart` / `onTouchMove` / `onTouchEnd`：位置按
    /// `(distance / trackLength) * (max - min) + min` 换算成值。
    private func dragGesture(trackLength: CGFloat,
                             onDrag: @escaping (Double) -> Void) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                guard !disabled else { return }
                startInteraction()
                let distance = vertical ? gesture.location.y : gesture.location.x
                onDrag(value(atDistance: distance, trackLength: trackLength))
            }
            .onEnded { _ in
                guard !disabled else { return }
                if isRange { endRangeInteraction() } else { endInteraction() }
            }
    }

    /// 上游那条换算公式，供单测直接验证。
    public func value(atDistance distance: CGFloat, trackLength: CGFloat) -> Double {
        guard trackLength > 0 else { return lowerBound }
        let ratio = Double(distance / trackLength)
        return normalize(ratio * (upperBound - lowerBound) + lowerBound)
    }

    public func onStart(_ action: @escaping () -> Void) -> Self { var c = self; c.onStartHandler = action; return c }
    public func onChanging(_ action: @escaping (Double) -> Void) -> Self { var c = self; c.onChangingHandler = action; return c }
    public func onChange(_ action: @escaping (Double) -> Void) -> Self { var c = self; c.onChangeHandler = action; return c }
    public func onRangeChanging(_ action: @escaping (UPSliderRangeValue) -> Void) -> Self { var c = self; c.onRangeChangingHandler = action; return c }
    public func onRangeChange(_ action: @escaping (UPSliderRangeValue) -> Void) -> Self { var c = self; c.onRangeChangeHandler = action; return c }

    public func startInteraction() { guard !disabled else { return }; onStartHandler?() }
    public func changeInteraction(to value: Double) { guard !disabled else { return }; updateValue(value, changing: true) }
    public func endInteraction() { guard !disabled else { return }; onChangeHandler?(currentValue) }
    public func endRangeInteraction() { guard !disabled else { return }; onRangeChangeHandler?(currentRange) }
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
        if changing { onChangingHandler?(normalized) }
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
        onRangeChangingHandler?(result)
    }

    private func format(_ value: Double) -> String { value.rounded() == value ? String(Int(value)) : String(value) }
}
