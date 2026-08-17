import Foundation
import SwiftUI

/// Values accepted by uview-plus `u-number-box` `value` and `modelValue` props.
///
/// JavaScript keeps numeric and string values distinct when emitting events. The
/// SwiftUI bridge retains that distinction so a configured `decimalLength`
/// continues to produce fixed-precision strings, while an unconstrained number
/// box emits a numeric value.
public enum UPNumberBoxValue: Equatable, Sendable, CustomStringConvertible {
    case string(String)
    case number(Double)

    public init(_ value: String) {
        self = .string(value)
    }

    public init(_ value: Int) {
        self = .number(Double(value))
    }

    public init(_ value: Double) {
        self = .number(value.isFinite ? value : 0)
    }

    public var description: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return UPNumberBox.formatNumber(value)
        }
    }

    /// Numeric form used by range checks and increment/decrement calculations.
    public var numberValue: Double? {
        switch self {
        case .string(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let number = Double(trimmed), number.isFinite else { return nil }
            return number
        case .number(let value):
            return value.isFinite ? value : nil
        }
    }
}

extension UPNumberBoxValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension UPNumberBoxValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension UPNumberBoxValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value.isFinite ? value : 0)
    }
}

/// Input values accepted by the uview-plus `value` prop.
public protocol UPNumberBoxValueInput {
    var upNumberBoxValue: UPNumberBoxValue? { get }
}

extension UPNumberBoxValue: UPNumberBoxValueInput {
    public var upNumberBoxValue: UPNumberBoxValue? { self }
}

extension String: UPNumberBoxValueInput {
    public var upNumberBoxValue: UPNumberBoxValue? { .string(self) }
}

public extension UPNumberBoxValueInput where Self: BinaryInteger {
    var upNumberBoxValue: UPNumberBoxValue? {
        let value = Double(self)
        return value.isFinite ? .number(value) : nil
    }
}

extension Int: UPNumberBoxValueInput {}
extension Int8: UPNumberBoxValueInput {}
extension Int16: UPNumberBoxValueInput {}
extension Int32: UPNumberBoxValueInput {}
extension Int64: UPNumberBoxValueInput {}
extension UInt: UPNumberBoxValueInput {}
extension UInt8: UPNumberBoxValueInput {}
extension UInt16: UPNumberBoxValueInput {}
extension UInt32: UPNumberBoxValueInput {}
extension UInt64: UPNumberBoxValueInput {}

public extension UPNumberBoxValueInput where Self: BinaryFloatingPoint {
    var upNumberBoxValue: UPNumberBoxValue? {
        guard isFinite else { return nil }
        let value = Double(self)
        return value.isFinite ? .number(value) : nil
    }
}

extension Double: UPNumberBoxValueInput {}
extension Float: UPNumberBoxValueInput {}
extension CGFloat: UPNumberBoxValueInput {}

/// Native values whose bindings can receive a normalized number-box value.
///
/// Use `Binding<String>` when a fixed `decimalLength` representation matters;
/// the upstream component emits that mode as a string via JavaScript `toFixed`.
public protocol UPNumberBoxBindingValue: UPNumberBoxValueInput {
    static func upNumberBoxBindingValue(from value: UPNumberBoxValue) -> Self?
}

extension UPNumberBoxValue: UPNumberBoxBindingValue {
    public static func upNumberBoxBindingValue(from value: UPNumberBoxValue) -> UPNumberBoxValue? {
        value
    }
}

extension String: UPNumberBoxBindingValue {
    public static func upNumberBoxBindingValue(from value: UPNumberBoxValue) -> String? {
        value.description
    }
}

public extension UPNumberBoxBindingValue where Self: BinaryInteger {
    static func upNumberBoxBindingValue(from value: UPNumberBoxValue) -> Self? {
        guard let number = value.numberValue,
              number.isFinite,
              number.rounded() == number else {
            return nil
        }
        return Self(exactly: number)
    }
}

extension Int: UPNumberBoxBindingValue {}
extension Int8: UPNumberBoxBindingValue {}
extension Int16: UPNumberBoxBindingValue {}
extension Int32: UPNumberBoxBindingValue {}
extension Int64: UPNumberBoxBindingValue {}
extension UInt: UPNumberBoxBindingValue {}
extension UInt8: UPNumberBoxBindingValue {}
extension UInt16: UPNumberBoxBindingValue {}
extension UInt32: UPNumberBoxBindingValue {}
extension UInt64: UPNumberBoxBindingValue {}

public extension UPNumberBoxBindingValue where Self: BinaryFloatingPoint {
    static func upNumberBoxBindingValue(from value: UPNumberBoxValue) -> Self? {
        guard let number = value.numberValue, number.isFinite else { return nil }
        let converted = Self(number)
        return converted.isFinite ? converted : nil
    }
}

extension Double: UPNumberBoxBindingValue {}
extension Float: UPNumberBoxBindingValue {}
extension CGFloat: UPNumberBoxBindingValue {}

/// String-or-number input accepted by the upstream `decimalLength` prop.
public protocol UPNumberBoxDecimalLengthValue {
    var upNumberBoxDecimalLength: Int? { get }
}

extension String: UPNumberBoxDecimalLengthValue {
    public var upNumberBoxDecimalLength: Int? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        guard let number = Double(value), number.isFinite else { return nil }
        return UPNumberBox.clampedDecimalLength(number)
    }
}

public extension UPNumberBoxDecimalLengthValue where Self: BinaryInteger {
    var upNumberBoxDecimalLength: Int? {
        guard let value = Int(exactly: self) else { return nil }
        return Swift.min(Swift.max(value, 0), 100)
    }
}

extension Int: UPNumberBoxDecimalLengthValue {}
extension Int8: UPNumberBoxDecimalLengthValue {}
extension Int16: UPNumberBoxDecimalLengthValue {}
extension Int32: UPNumberBoxDecimalLengthValue {}
extension Int64: UPNumberBoxDecimalLengthValue {}
extension UInt: UPNumberBoxDecimalLengthValue {}
extension UInt8: UPNumberBoxDecimalLengthValue {}
extension UInt16: UPNumberBoxDecimalLengthValue {}
extension UInt32: UPNumberBoxDecimalLengthValue {}
extension UInt64: UPNumberBoxDecimalLengthValue {}

public extension UPNumberBoxDecimalLengthValue where Self: BinaryFloatingPoint {
    var upNumberBoxDecimalLength: Int? {
        guard isFinite else { return nil }
        return UPNumberBox.clampedDecimalLength(Double(self))
    }
}

extension Double: UPNumberBoxDecimalLengthValue {}
extension Float: UPNumberBoxDecimalLengthValue {}
extension CGFloat: UPNumberBoxDecimalLengthValue {}

/// Semantic alias for `u-number-box`'s String-or-Number sizing and range props.
public typealias UPNumberBoxUnitValue = UPCheckboxUnitValue

/// Identifies the add or subtract button in uview-plus number-box callbacks.
public enum UPNumberBoxButtonType: String, CaseIterable, Equatable, Sendable, CustomStringConvertible {
    case minus
    case plus

    public var description: String { rawValue }
}

/// Payload emitted by uview-plus `change`.
public struct UPNumberBoxChange: Equatable, Sendable {
    public let value: UPNumberBoxValue
    public let name: UPCheckboxName
    public let type: UPNumberBoxButtonType?

    public init(value: UPNumberBoxValue, name: UPCheckboxName, type: UPNumberBoxButtonType? = nil) {
        self.value = value
        self.name = name
        self.type = type
    }
}

/// Payload emitted by the native counterpart of `focus`.
public struct UPNumberBoxFocusEvent: Equatable, Sendable {
    public let name: UPCheckboxName

    public init(name: UPCheckboxName) {
        self.name = name
    }
}

/// Payload emitted by the native counterpart of `blur`.
public struct UPNumberBoxBlurEvent: Equatable, Sendable {
    public let value: UPNumberBoxValue
    public let name: UPCheckboxName

    public init(value: UPNumberBoxValue, name: UPCheckboxName) {
        self.value = value
        self.name = name
    }
}

/// Parameters supplied to the SwiftUI equivalent of the named `minus` and
/// `plus` slots.
public struct UPNumberBoxButtonSlotContext: Equatable, Sendable {
    public let type: UPNumberBoxButtonType
    public let value: UPNumberBoxValue
    public let isDisabled: Bool

    public init(type: UPNumberBoxButtonType, value: UPNumberBoxValue, isDisabled: Bool) {
        self.type = type
        self.value = value
        self.isDisabled = isDisabled
    }
}

/// Parameters supplied to the SwiftUI equivalent of the named `input` slot.
public struct UPNumberBoxInputSlotContext: Equatable, Sendable {
    public let value: UPNumberBoxValue
    public let isDisabled: Bool

    public init(value: UPNumberBoxValue, isDisabled: Bool) {
        self.value = value
        self.isDisabled = isDisabled
    }
}

@MainActor
private final class UPNumberBoxInteractionState {
    var localValue: UPNumberBoxValue
    var editingText: String?

    init(localValue: UPNumberBoxValue) {
        self.localValue = localValue
    }
}

/// Native SwiftUI counterpart of uview-plus `u-number-box`.
///
/// `modelValue` is a SwiftUI `Binding`, while `value` retains the uncontrolled
/// Vue 2-style prop. `onChange` mirrors the source event ordering: the callback
/// runs before the component writes its normalized value through the binding.
@MainActor
public struct UPNumberBox: View {
    var customClass: String
    var name: UPCheckboxName
    var value: UPNumberBoxValue
    var min: String
    var max: String
    var step: String
    var integer: Bool
    var disabled: Bool
    var disabledInput: Bool
    var asyncChange: Bool
    var inputWidth: String
    var showMinus: Bool
    var showPlus: Bool
    var decimalLength: Int?
    var longPress: Bool
    var color: String
    var buttonWidth: String
    var buttonSize: String
    var buttonRadius: String
    var bgColor: String
    var disabledBgColor: String
    var inputBgColor: String
    var cursorSpacing: String
    var disableMinus: Bool
    var disablePlus: Bool
    var iconStyle: UPStyle
    var miniMode: Bool
    var customStyle: UPStyle

    private var modelValue: Binding<UPNumberBoxValue>?
    private var onChangeHandler: ((UPNumberBoxChange) -> Void)?
    private var onOverlimitHandler: ((UPNumberBoxButtonType) -> Void)?
    private var onPlusHandler: (() -> Void)?
    private var onMinusHandler: (() -> Void)?
    private var onFocusHandler: ((UPNumberBoxFocusEvent) -> Void)?
    private var onBlurHandler: ((UPNumberBoxBlurEvent) -> Void)?
    private var minusSlot: ((UPNumberBoxButtonSlotContext) -> AnyView)?
    private var inputSlot: ((UPNumberBoxInputSlotContext) -> AnyView)?
    private var plusSlot: ((UPNumberBoxButtonSlotContext) -> AnyView)?
    private let interactionState: UPNumberBoxInteractionState

    @State private var localValue: UPNumberBoxValue
    @State private var longPressTask: Task<Void, Never>?
    @State private var didLongPress = false
    @FocusState private var inputIsFocused: Bool
    @Environment(\.upTheme) private var theme

    public init<Name: UPCheckboxNameValue, Value: UPNumberBoxValueInput, Min: UPNumberBoxUnitValue, Max: UPNumberBoxUnitValue, Step: UPNumberBoxUnitValue, InputWidth: UPNumberBoxUnitValue, ButtonWidth: UPNumberBoxUnitValue, ButtonSize: UPNumberBoxUnitValue, CursorSpacing: UPNumberBoxUnitValue>(
        customClass: String = UPConfig.numberBox.customClass,
        name: Name = UPConfig.numberBox.name,
        value: Value = UPConfig.numberBox.value,
        min: Min = UPConfig.numberBox.min,
        max: Max = UPConfig.numberBox.max,
        step: Step = UPConfig.numberBox.step,
        integer: Bool = UPConfig.numberBox.integer,
        disabled: Bool = UPConfig.numberBox.disabled,
        disabledInput: Bool = UPConfig.numberBox.disabledInput,
        asyncChange: Bool = UPConfig.numberBox.asyncChange,
        inputWidth: InputWidth = UPConfig.numberBox.inputWidth,
        showMinus: Bool = UPConfig.numberBox.showMinus,
        showPlus: Bool = UPConfig.numberBox.showPlus,
        decimalLength: (any UPNumberBoxDecimalLengthValue)? = UPConfig.numberBox.decimalLength,
        longPress: Bool = UPConfig.numberBox.longPress,
        color: String = UPConfig.numberBox.color,
        buttonWidth: ButtonWidth = UPConfig.numberBox.buttonWidth,
        buttonSize: ButtonSize = UPConfig.numberBox.buttonSize,
        buttonRadius: String = UPConfig.numberBox.buttonRadius,
        bgColor: String = UPConfig.numberBox.bgColor,
        disabledBgColor: String = UPConfig.numberBox.disabledBgColor,
        inputBgColor: String = UPConfig.numberBox.inputBgColor,
        cursorSpacing: CursorSpacing = UPConfig.numberBox.cursorSpacing,
        disableMinus: Bool = UPConfig.numberBox.disableMinus,
        disablePlus: Bool = UPConfig.numberBox.disablePlus,
        iconStyle: UPStyle = UPConfig.numberBox.iconStyle,
        miniMode: Bool = UPConfig.numberBox.miniMode,
        customStyle: UPStyle = UPConfig.numberBox.customStyle,
        onChange: ((UPNumberBoxChange) -> Void)? = nil,
        onOverlimit: ((UPNumberBoxButtonType) -> Void)? = nil,
        onPlus: (() -> Void)? = nil,
        onMinus: (() -> Void)? = nil,
        onFocus: ((UPNumberBoxFocusEvent) -> Void)? = nil,
        onBlur: ((UPNumberBoxBlurEvent) -> Void)? = nil
    ) {
        self.init(
            customClass: customClass,
            name: name.upCheckboxNameValue,
            modelValue: nil,
            value: value.upNumberBoxValue ?? .number(0),
            min: min.upCheckboxUnitValue,
            max: max.upCheckboxUnitValue,
            step: step.upCheckboxUnitValue,
            integer: integer,
            disabled: disabled,
            disabledInput: disabledInput,
            asyncChange: asyncChange,
            inputWidth: inputWidth.upCheckboxUnitValue,
            showMinus: showMinus,
            showPlus: showPlus,
            decimalLength: decimalLength?.upNumberBoxDecimalLength,
            longPress: longPress,
            color: color,
            buttonWidth: buttonWidth.upCheckboxUnitValue,
            buttonSize: buttonSize.upCheckboxUnitValue,
            buttonRadius: buttonRadius,
            bgColor: bgColor,
            disabledBgColor: disabledBgColor,
            inputBgColor: inputBgColor,
            cursorSpacing: cursorSpacing.upCheckboxUnitValue,
            disableMinus: disableMinus,
            disablePlus: disablePlus,
            iconStyle: iconStyle,
            miniMode: miniMode,
            customStyle: customStyle,
            onChange: onChange,
            onOverlimit: onOverlimit,
            onPlus: onPlus,
            onMinus: onMinus,
            onFocus: onFocus,
            onBlur: onBlur
        )
    }

    /// Native `Binding` equivalent of Vue 3 `v-model:modelValue`.
    public init<Model: UPNumberBoxBindingValue, Name: UPCheckboxNameValue, Min: UPNumberBoxUnitValue, Max: UPNumberBoxUnitValue, Step: UPNumberBoxUnitValue, InputWidth: UPNumberBoxUnitValue, ButtonWidth: UPNumberBoxUnitValue, ButtonSize: UPNumberBoxUnitValue, CursorSpacing: UPNumberBoxUnitValue>(
        customClass: String = UPConfig.numberBox.customClass,
        name: Name = UPConfig.numberBox.name,
        modelValue: Binding<Model>,
        min: Min = UPConfig.numberBox.min,
        max: Max = UPConfig.numberBox.max,
        step: Step = UPConfig.numberBox.step,
        integer: Bool = UPConfig.numberBox.integer,
        disabled: Bool = UPConfig.numberBox.disabled,
        disabledInput: Bool = UPConfig.numberBox.disabledInput,
        asyncChange: Bool = UPConfig.numberBox.asyncChange,
        inputWidth: InputWidth = UPConfig.numberBox.inputWidth,
        showMinus: Bool = UPConfig.numberBox.showMinus,
        showPlus: Bool = UPConfig.numberBox.showPlus,
        decimalLength: (any UPNumberBoxDecimalLengthValue)? = UPConfig.numberBox.decimalLength,
        longPress: Bool = UPConfig.numberBox.longPress,
        color: String = UPConfig.numberBox.color,
        buttonWidth: ButtonWidth = UPConfig.numberBox.buttonWidth,
        buttonSize: ButtonSize = UPConfig.numberBox.buttonSize,
        buttonRadius: String = UPConfig.numberBox.buttonRadius,
        bgColor: String = UPConfig.numberBox.bgColor,
        disabledBgColor: String = UPConfig.numberBox.disabledBgColor,
        inputBgColor: String = UPConfig.numberBox.inputBgColor,
        cursorSpacing: CursorSpacing = UPConfig.numberBox.cursorSpacing,
        disableMinus: Bool = UPConfig.numberBox.disableMinus,
        disablePlus: Bool = UPConfig.numberBox.disablePlus,
        iconStyle: UPStyle = UPConfig.numberBox.iconStyle,
        miniMode: Bool = UPConfig.numberBox.miniMode,
        customStyle: UPStyle = UPConfig.numberBox.customStyle,
        onChange: ((UPNumberBoxChange) -> Void)? = nil,
        onOverlimit: ((UPNumberBoxButtonType) -> Void)? = nil,
        onPlus: (() -> Void)? = nil,
        onMinus: (() -> Void)? = nil,
        onFocus: ((UPNumberBoxFocusEvent) -> Void)? = nil,
        onBlur: ((UPNumberBoxBlurEvent) -> Void)? = nil
    ) {
        let erasedBinding = Self.erase(modelValue)
        self.init(
            customClass: customClass,
            name: name.upCheckboxNameValue,
            modelValue: erasedBinding,
            value: erasedBinding.wrappedValue,
            min: min.upCheckboxUnitValue,
            max: max.upCheckboxUnitValue,
            step: step.upCheckboxUnitValue,
            integer: integer,
            disabled: disabled,
            disabledInput: disabledInput,
            asyncChange: asyncChange,
            inputWidth: inputWidth.upCheckboxUnitValue,
            showMinus: showMinus,
            showPlus: showPlus,
            decimalLength: decimalLength?.upNumberBoxDecimalLength,
            longPress: longPress,
            color: color,
            buttonWidth: buttonWidth.upCheckboxUnitValue,
            buttonSize: buttonSize.upCheckboxUnitValue,
            buttonRadius: buttonRadius,
            bgColor: bgColor,
            disabledBgColor: disabledBgColor,
            inputBgColor: inputBgColor,
            cursorSpacing: cursorSpacing.upCheckboxUnitValue,
            disableMinus: disableMinus,
            disablePlus: disablePlus,
            iconStyle: iconStyle,
            miniMode: miniMode,
            customStyle: customStyle,
            onChange: onChange,
            onOverlimit: onOverlimit,
            onPlus: onPlus,
            onMinus: onMinus,
            onFocus: onFocus,
            onBlur: onBlur
        )
    }

    private init(
        customClass: String,
        name: UPCheckboxName,
        modelValue: Binding<UPNumberBoxValue>?,
        value: UPNumberBoxValue,
        min: String,
        max: String,
        step: String,
        integer: Bool,
        disabled: Bool,
        disabledInput: Bool,
        asyncChange: Bool,
        inputWidth: String,
        showMinus: Bool,
        showPlus: Bool,
        decimalLength: Int?,
        longPress: Bool,
        color: String,
        buttonWidth: String,
        buttonSize: String,
        buttonRadius: String,
        bgColor: String,
        disabledBgColor: String,
        inputBgColor: String,
        cursorSpacing: String,
        disableMinus: Bool,
        disablePlus: Bool,
        iconStyle: UPStyle,
        miniMode: Bool,
        customStyle: UPStyle,
        onChange: ((UPNumberBoxChange) -> Void)?,
        onOverlimit: ((UPNumberBoxButtonType) -> Void)?,
        onPlus: (() -> Void)?,
        onMinus: (() -> Void)?,
        onFocus: ((UPNumberBoxFocusEvent) -> Void)?,
        onBlur: ((UPNumberBoxBlurEvent) -> Void)?
    ) {
        self.customClass = customClass
        self.name = name
        self.modelValue = modelValue
        self.value = value
        self.min = min
        self.max = max
        self.step = step
        self.integer = integer
        self.disabled = disabled
        self.disabledInput = disabledInput
        self.asyncChange = asyncChange
        self.inputWidth = inputWidth
        self.showMinus = showMinus
        self.showPlus = showPlus
        self.decimalLength = decimalLength
        self.longPress = longPress
        self.color = color
        self.buttonWidth = buttonWidth
        self.buttonSize = buttonSize
        self.buttonRadius = buttonRadius
        self.bgColor = bgColor
        self.disabledBgColor = disabledBgColor
        self.inputBgColor = inputBgColor
        self.cursorSpacing = cursorSpacing
        self.disableMinus = disableMinus
        self.disablePlus = disablePlus
        self.iconStyle = iconStyle
        self.miniMode = miniMode
        self.customStyle = customStyle
        self.onChangeHandler = onChange
        self.onOverlimitHandler = onOverlimit
        self.onPlusHandler = onPlus
        self.onMinusHandler = onMinus
        self.onFocusHandler = onFocus
        self.onBlurHandler = onBlur
        let normalizedInitialValue = Self.format(
            value,
            min: min,
            max: max,
            integer: integer,
            decimalLength: decimalLength
        )
        self.interactionState = UPNumberBoxInteractionState(localValue: normalizedInitialValue)
        self._localValue = State(initialValue: normalizedInitialValue)
    }

    public var body: some View {
        HStack(spacing: 2) {
            if showMinus && !hidesMinus {
                button(for: .minus)
            }

            if showsInput {
                input
            }

            if showPlus {
                button(for: .plus)
            }
        }
        .upStyle(customStyle)
        .onChange(of: value) { _, newValue in
            guard modelValue == nil else { return }
            setCurrentValue(Self.format(newValue, min: min, max: max, integer: integer, decimalLength: decimalLength))
        }
        .onChange(of: externalModelValue) { _, newValue in
            guard modelValue != nil else { return }
            let formatted = Self.format(newValue, min: min, max: max, integer: integer, decimalLength: decimalLength)
            guard formatted != currentValue else { return }
            setCurrentValue(formatted)
        }
        .onDisappear {
            stopLongPress()
        }
    }

    /// Current internal value, equivalent to the source component's
    /// `currentValue`. It is initialized through uview-plus `format`.
    var currentValue: UPNumberBoxValue {
        if let editingText = interactionState.editingText {
            return .string(editingText)
        }
        if let modelValue {
            return Self.format(
                modelValue.wrappedValue,
                min: min,
                max: max,
                integer: integer,
                decimalLength: decimalLength
            )
        }
        return interactionState.localValue
    }

    var resolvedInputWidth: CGFloat {
        Swift.max(UPUnit.parse(inputWidth), 0)
    }

    var resolvedButtonWidth: CGFloat {
        Swift.max(UPUnit.parse(buttonWidth), 0)
    }

    var resolvedButtonSize: CGFloat {
        Swift.max(UPUnit.parse(buttonSize), 0)
    }

    var resolvedButtonRadius: CGFloat {
        Swift.max(UPUnit.parse(buttonRadius), 0)
    }

    var resolvedCursorSpacing: CGFloat {
        Swift.max(UPUnit.parse(cursorSpacing), 0)
    }

    /// Matches the source `hideMinus` computed prop. In mini mode both the
    /// minus button and input slot disappear while the current value is zero.
    var hidesMinus: Bool {
        miniMode && resolvedCurrentNumber == 0
    }

    var showsInput: Bool {
        !hidesMinus
    }

    var hasMinusSlot: Bool {
        minusSlot != nil
    }

    var hasInputSlot: Bool {
        inputSlot != nil
    }

    var hasPlusSlot: Bool {
        plusSlot != nil
    }

    /// The source uses `disabled || disable{Plus,Minus} || boundary` for the
    /// two button states. `disabledInput` intentionally does not disable the
    /// step buttons.
    func isDisabled(_ type: UPNumberBoxButtonType) -> Bool {
        switch type {
        case .plus:
            return disabled || disablePlus || resolvedCurrentNumber >= resolvedMaximum
        case .minus:
            return disabled || disableMinus || resolvedCurrentNumber <= resolvedMinimum
        }
    }

    /// Native/testable counterpart of tapping the plus control.
    func triggerPlus() {
        triggerButton(.plus)
    }

    /// Native/testable counterpart of tapping the minus control.
    func triggerMinus() {
        triggerButton(.minus)
    }

    /// Native/testable counterpart of an input event. Empty values deliberately
    /// remain editable until `triggerBlur()`, as in the upstream component.
    func triggerInput(_ rawValue: String) {
        guard !disabled, !disabledInput else { return }

        if rawValue.isEmpty {
            setEditingText("")
            return
        }

        interactionState.editingText = nil
        let filtered = Self.filter(rawValue, integer: integer)
        // u-number-box emits the raw input before it emits the filtered and
        // formatted result. This is observable with decimalLength enabled.
        emitChange(.string(rawValue))

        var constrained = filtered
        if let decimalLength,
           let point = constrained.firstIndex(of: ".") {
            let integerPart = String(constrained[..<point])
            let fractionStart = constrained.index(after: point)
            let fraction = String(constrained[fractionStart...].prefix(decimalLength))
            constrained = "\(integerPart).\(fraction)"
        }

        emitChange(
            Self.format(
                .string(constrained),
                min: min,
                max: max,
                integer: integer,
                decimalLength: decimalLength
            )
        )
    }

    /// Native/testable counterpart of the source focus event.
    func triggerFocus() {
        guard !disabled, !disabledInput else { return }
        onFocusHandler?(UPNumberBoxFocusEvent(name: name))
    }

    /// Native/testable counterpart of the source blur event.
    func triggerBlur() {
        guard !disabled, !disabledInput else { return }
        let formatted: UPNumberBoxValue
        if interactionState.editingText?.isEmpty == true || currentValue.description.isEmpty {
            formatted = Self.format(.string(min), min: min, max: max, integer: integer, decimalLength: decimalLength)
        } else {
            formatted = Self.format(currentValue, min: min, max: max, integer: integer, decimalLength: decimalLength)
        }
        emitChange(formatted)
        onBlurHandler?(UPNumberBoxBlurEvent(value: formatted, name: name))
    }

    /// A single long-press repetition tick. It intentionally does nothing when
    /// `longPress` is false; normal taps continue to use `triggerPlus` and
    /// `triggerMinus` regardless of that setting.
    func triggerLongPressTick(_ type: UPNumberBoxButtonType) {
        guard longPress else { return }
        triggerButton(type)
    }

    /// Formats a numeric payload exactly as the upstream's non-fixed mode does.
    public nonisolated static func formatNumber(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        if value.rounded() == value,
           value >= Double(Int.min),
           value <= Double(Int.max) {
            return String(Int(value))
        }
        return String(value)
    }

    private var externalModelValue: UPNumberBoxValue {
        modelValue?.wrappedValue ?? currentValue
    }

    private var resolvedMinimum: Double {
        Self.number(from: min, fallback: 0)
    }

    private var resolvedMaximum: Double {
        Self.number(from: max, fallback: Double.greatestFiniteMagnitude)
    }

    private var resolvedStep: Double {
        Self.number(from: step, fallback: 0)
    }

    private var resolvedCurrentNumber: Double {
        currentValue.numberValue ?? 0
    }

    private var inputText: Binding<String> {
        Binding(
            get: { currentValue.description },
            set: { triggerInput($0) }
        )
    }

    @ViewBuilder
    private var input: some View {
        if let inputSlot {
            inputSlot(
                UPNumberBoxInputSlotContext(
                    value: currentValue,
                    isDisabled: disabled || disabledInput
                )
            )
            .frame(width: resolvedInputWidth, height: resolvedButtonSize)
        } else {
            TextField("", text: inputText)
                .multilineTextAlignment(.center)
                .font(.system(size: 15))
                .foregroundStyle(resolvedColor)
                .frame(width: resolvedInputWidth, height: resolvedButtonSize)
                .background(resolvedInputBackground)
                .disabled(disabled || disabledInput)
                .focused($inputIsFocused)
                .onChange(of: inputIsFocused) { _, focused in
                    if focused {
                        triggerFocus()
                    } else {
                        triggerBlur()
                    }
                }
                .accessibilityLabel("Number input")
        }
    }

    @ViewBuilder
    private func button(for type: UPNumberBoxButtonType) -> some View {
        let context = UPNumberBoxButtonSlotContext(
            type: type,
            value: currentValue,
            isDisabled: isDisabled(type)
        )
        Button {
            if didLongPress {
                setDidLongPress(false)
            } else {
                triggerButton(type)
            }
        } label: {
            Group {
                switch type {
                case .minus:
                    if let minusSlot {
                        minusSlot(context)
                    } else {
                        defaultIcon(for: type, disabled: context.isDisabled)
                    }
                case .plus:
                    if let plusSlot {
                        plusSlot(context)
                    } else {
                        defaultIcon(for: type, disabled: context.isDisabled)
                    }
                }
            }
            .frame(width: resolvedButtonWidth, height: resolvedButtonSize)
            .background(buttonBackground(for: type))
            .clipShape(RoundedRectangle(cornerRadius: resolvedButtonRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onLongPressGesture(
            minimumDuration: 0.6,
            maximumDistance: 30,
            pressing: { isPressing in
                if !isPressing {
                    stopLongPress()
                }
            },
            perform: {
                startLongPress(for: type)
            }
        )
        .accessibilityAddTraits(isDisabled(type) ? .isStaticText : .isButton)
    }

    private func defaultIcon(for type: UPNumberBoxButtonType, disabled: Bool) -> some View {
        UPIcon(
            name: type.rawValue,
            color: disabled ? "disabled" : resolvedColorName,
            size: "15",
            bold: true
        )
        .upStyle(iconStyle)
    }

    private var resolvedColorName: String {
        color.isEmpty ? "main" : color
    }

    private var resolvedColor: Color {
        UPColor.parse(resolvedColorName, theme: theme)
    }

    private var resolvedBackground: Color {
        UPColor.parse(bgColor.isEmpty ? "#EBECEE" : bgColor, theme: theme)
    }

    private var resolvedDisabledBackground: Color {
        UPColor.parse(disabledBgColor.isEmpty ? "#f7f8fa" : disabledBgColor, theme: theme)
    }

    private var resolvedInputBackground: Color {
        UPColor.parse(
            inputBgColor.isEmpty ? (bgColor.isEmpty ? "#EBECEE" : bgColor) : inputBgColor,
            theme: theme
        )
    }

    private func buttonBackground(for type: UPNumberBoxButtonType) -> Color {
        isDisabled(type) ? resolvedDisabledBackground : resolvedBackground
    }

    private func triggerButton(_ type: UPNumberBoxButtonType) {
        guard !isDisabled(type) else {
            onOverlimitHandler?(type)
            return
        }

        let delta = type == .minus ? -resolvedStep : resolvedStep
        let next = Self.add(resolvedCurrentNumber, delta)
        let formatted = Self.format(
            .number(next),
            min: min,
            max: max,
            integer: integer,
            decimalLength: decimalLength
        )
        emitChange(formatted, type: type)

        switch type {
        case .minus:
            onMinusHandler?()
        case .plus:
            onPlusHandler?()
        }
    }

    private func emitChange(_ emittedValue: UPNumberBoxValue, type: UPNumberBoxButtonType? = nil) {
        // The source emits `change` now and schedules update:modelValue for the
        // next tick. Calling the callback first gives a SwiftUI Binding observer
        // the same visible ordering.
        onChangeHandler?(UPNumberBoxChange(value: emittedValue, name: name, type: type))
        guard !asyncChange else { return }
        setCurrentValue(emittedValue)
        modelValue?.wrappedValue = emittedValue
    }

    private func setCurrentValue(_ value: UPNumberBoxValue) {
        interactionState.editingText = nil
        interactionState.localValue = value
        $localValue.wrappedValue = value
    }

    private func setEditingText(_ text: String) {
        interactionState.editingText = text
        interactionState.localValue = .string(text)
        $localValue.wrappedValue = .string(text)
    }

    private func setDidLongPress(_ value: Bool) {
        $didLongPress.wrappedValue = value
    }

    private func startLongPress(for type: UPNumberBoxButtonType) {
        guard longPress else { return }
        stopLongPress()
        setDidLongPress(true)
        triggerLongPressTick(type)
        $longPressTask.wrappedValue = Task { @MainActor in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(250))
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                triggerLongPressTick(type)
            }
        }
    }

    private func stopLongPress() {
        longPressTask?.cancel()
        $longPressTask.wrappedValue = nil
    }

    private static func erase<Model: UPNumberBoxBindingValue>(_ binding: Binding<Model>) -> Binding<UPNumberBoxValue> {
        Binding<UPNumberBoxValue>(
            get: { binding.wrappedValue.upNumberBoxValue ?? .number(0) },
            set: { incomingValue in
                guard let typedValue = Model.upNumberBoxBindingValue(from: incomingValue) else { return }
                binding.wrappedValue = typedValue
            }
        )
    }

    private static func filter(_ rawValue: String, integer: Bool) -> String {
        let accepted = CharacterSet(charactersIn: "0123456789.-")
        var filtered = String(rawValue.unicodeScalars.filter { accepted.contains($0) })
        if integer, let point = filtered.firstIndex(of: ".") {
            filtered = String(filtered[..<point])
        }
        return filtered
    }

    private static func format(
        _ rawValue: UPNumberBoxValue,
        min: String,
        max: String,
        integer: Bool,
        decimalLength: Int?
    ) -> UPNumberBoxValue {
        let filtered = filter(rawValue.description, integer: integer)
        let parsed = Double(filtered)
        let numeric = parsed?.isFinite == true ? parsed! : 0
        let minimum = number(from: min, fallback: 0)
        let maximum = number(from: max, fallback: Double.greatestFiniteMagnitude)
        let constrained = Swift.max(Swift.min(maximum, numeric), minimum)

        if let decimalLength {
            let digits = Swift.min(Swift.max(decimalLength, 0), 100)
            return .string(
                String(
                    format: "%.*f",
                    locale: Locale(identifier: "en_US_POSIX"),
                    arguments: [digits, constrained]
                )
            )
        }
        return .number(constrained)
    }

    private static func number(from rawValue: String, fallback: Double) -> Double {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed), value.isFinite else { return fallback }
        return value
    }

    private static func add(_ first: Double, _ second: Double) -> Double {
        let cardinal: Double = 10_000_000_000
        return ((first + second) * cardinal).rounded() / cardinal
    }

    nonisolated static func clampedDecimalLength(_ value: Double) -> Int? {
        guard value.isFinite,
              value >= Double(Int.min),
              value <= Double(Int.max) else {
            return nil
        }
        return Swift.min(Swift.max(Int(value.rounded(.towardZero)), 0), 100)
    }
}

public extension UPNumberBox {
    /// Registers the uview-plus `change({ value, name, type })` callback.
    func onChange(_ action: @escaping (UPNumberBoxChange) -> Void) -> UPNumberBox {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    /// Registers the uview-plus `overlimit(type)` callback.
    func onOverlimit(_ action: @escaping (UPNumberBoxButtonType) -> Void) -> UPNumberBox {
        var copy = self
        copy.onOverlimitHandler = action
        return copy
    }

    /// Registers the uview-plus `plus` callback.
    func onPlus(_ action: @escaping () -> Void) -> UPNumberBox {
        var copy = self
        copy.onPlusHandler = action
        return copy
    }

    /// Registers the uview-plus `minus` callback.
    func onMinus(_ action: @escaping () -> Void) -> UPNumberBox {
        var copy = self
        copy.onMinusHandler = action
        return copy
    }

    /// Registers the uview-plus `focus` callback.
    func onFocus(_ action: @escaping (UPNumberBoxFocusEvent) -> Void) -> UPNumberBox {
        var copy = self
        copy.onFocusHandler = action
        return copy
    }

    /// Registers the uview-plus `blur` callback.
    func onBlur(_ action: @escaping (UPNumberBoxBlurEvent) -> Void) -> UPNumberBox {
        var copy = self
        copy.onBlurHandler = action
        return copy
    }

    /// Supplies the SwiftUI equivalent of the named `minus` slot.
    func minus<Content: View>(@ViewBuilder _ content: @escaping (UPNumberBoxButtonSlotContext) -> Content) -> UPNumberBox {
        var copy = self
        copy.minusSlot = { context in AnyView(content(context)) }
        return copy
    }

    /// Supplies the SwiftUI equivalent of the named `input` slot.
    func input<Content: View>(@ViewBuilder _ content: @escaping (UPNumberBoxInputSlotContext) -> Content) -> UPNumberBox {
        var copy = self
        copy.inputSlot = { context in AnyView(content(context)) }
        return copy
    }

    /// Supplies the SwiftUI equivalent of the named `plus` slot.
    func plus<Content: View>(@ViewBuilder _ content: @escaping (UPNumberBoxButtonSlotContext) -> Content) -> UPNumberBox {
        var copy = self
        copy.plusSlot = { context in AnyView(content(context)) }
        return copy
    }
}
