import SwiftUI

/// Semantic alias for the `String | Number` props accepted by uview-plus
/// `u-code-input` (`maxlength`, `space`, `value`, `fontSize`, and `size`).
public typealias UPCodeInputUnitValue = UPCheckboxUnitValue

/// Native representation of uview-plus `u-code-input` display modes.
public enum UPCodeInputMode: String, Equatable, Sendable {
    case box
    case line

    /// uview-plus only recognizes the exact `line` value. Native invalid
    /// string values fall back to its default box presentation.
    public init(_ value: String) {
        self = value == Self.line.rawValue ? .line : .box
    }
}

/// Stateful native counterpart of a uview-plus `u-code-input` instance.
///
/// It owns the component's rendered value and upstream event ordering. The
/// SwiftUI view supplies a `Binding<String>` as the native equivalent of
/// `v-model`; external/custom keyboards may also call ``input(_:)`` directly.
@MainActor
public final class UPCodeInputController: ObservableObject {
    @Published public private(set) var inputValue: String
    @Published public private(set) var isFocused: Bool
    @Published public private(set) var resolvedMaxlength: Int

    private var disabledDot: Bool
    private var pendingModelValue: String?
    private var onChangeHandler: ((String) -> Void)?
    private var onModelValueUpdateHandler: ((String) -> Void)?
    private var onFinishHandler: ((String) -> Void)?

    /// Creates a controller using the same defaults as uview-plus
    /// `u-code-input`.
    public convenience init(
        maxlength: some UPCodeInputUnitValue = UPConfig.codeInput.maxlength,
        disabledDot: Bool = UPConfig.codeInput.disabledDot,
        value: String = UPConfig.codeInput.value,
        focus: Bool = UPConfig.codeInput.focus,
        onChange: ((String) -> Void)? = nil,
        onFinish: ((String) -> Void)? = nil
    ) {
        self.init(
            maxlength: maxlength.upCheckboxUnitValue,
            disabledDot: disabledDot,
            value: value,
            focus: focus,
            onChange: onChange,
            onModelValueUpdate: nil,
            onFinish: onFinish
        )
    }

    init(
        maxlength: String,
        disabledDot: Bool,
        value: String,
        focus: Bool,
        onChange: ((String) -> Void)?,
        onModelValueUpdate: ((String) -> Void)?,
        onFinish: ((String) -> Void)?
    ) {
        let maximumLength = Self.parseMaxlength(maxlength)
        self.resolvedMaxlength = maximumLength
        self.disabledDot = disabledDot
        self.inputValue = Self.truncated(value, maxlength: maximumLength)
        self.isFocused = focus
        self.pendingModelValue = nil
        self.onChangeHandler = onChange
        self.onModelValueUpdateHandler = onModelValueUpdate
        self.onFinishHandler = onFinish
    }

    /// Delivers a native input event. As upstream does, `change` is emitted
    /// before the model update and `finish` observes the already-written model.
    public func input(_ value: String) {
        inputValue = Self.displayValueAfterNativeInput(value, disabledDot: disabledDot)
        onChangeHandler?(value)

        if let onModelValueUpdateHandler {
            pendingModelValue = value
            onModelValueUpdateHandler(value)
        }

        if value.count >= resolvedMaxlength {
            onFinishHandler?(value)
        }
    }

    /// Mirrors the source `modelValue` watcher: values received externally are
    /// truncated to `maxlength`, but are not dot-filtered.
    public func synchronizeExternalValue(_ value: String) {
        if pendingModelValue == value {
            pendingModelValue = nil
            return
        }
        inputValue = Self.truncated(value, maxlength: resolvedMaxlength)
    }

    /// Sets the cursor/focus presentation state.
    public func focus() {
        isFocused = true
    }

    /// Clears the cursor/focus presentation state.
    public func blur() {
        isFocused = false
    }

    func setFocused(_ focused: Bool) {
        isFocused = focused
    }

    func configure(
        maxlength: String,
        disabledDot: Bool,
        focus: Bool,
        onChange: ((String) -> Void)?,
        onModelValueUpdate: ((String) -> Void)?,
        onFinish: ((String) -> Void)?
    ) {
        let maximumLength = Self.parseMaxlength(maxlength)
        resolvedMaxlength = maximumLength
        self.disabledDot = disabledDot
        isFocused = focus
        onChangeHandler = onChange
        onModelValueUpdateHandler = onModelValueUpdate
        onFinishHandler = onFinish
    }

    func setOnChangeHandler(_ handler: ((String) -> Void)?) {
        onChangeHandler = handler
    }

    func setOnFinishHandler(_ handler: ((String) -> Void)?) {
        onFinishHandler = handler
    }

    private static func parseMaxlength(_ value: String) -> Int {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let number = Double(trimmed),
              number.isFinite,
              number >= 0,
              number.rounded(.towardZero) == number,
              number <= Double(Int.max) else {
            return UPConfig.codeInput.maxlength
        }
        return Int(number)
    }

    private static func truncated(_ value: String, maxlength: Int) -> String {
        String(value.prefix(Swift.max(0, maxlength)))
    }

    private static func displayValueAfterNativeInput(_ value: String, disabledDot: Bool) -> String {
        guard disabledDot, let dotIndex = value.firstIndex(of: ".") else {
            return value
        }
        var value = value
        value.remove(at: dotIndex)
        return value
    }
}

/// Native SwiftUI counterpart of uview-plus `u-code-input`.
///
/// `modelValue` is the direct SwiftUI equivalent of Vue's `v-model`; `value`
/// remains available as the uncontrolled `String | Number` source prop. A
/// transparent native `TextField` provides keyboard/focus behavior while the
/// visible cells retain uview-plus's box and line visual modes.
@MainActor
public struct UPCodeInput: View {
    public let adjustPosition: Bool
    public let maxlength: String
    public let dot: Bool
    public let mode: String
    public let hairline: Bool
    public let space: String
    public let value: String
    public let focus: Bool
    public let bold: Bool
    public let color: String
    public let fontSize: String
    public let size: String
    public let disabledKeyboard: Bool
    public let borderColor: String
    public let disabledDot: Bool
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no CSS class analogue.
    public let customClass: String
    public let customStyle: UPStyle

    private var modelValue: Binding<String>?
    private var onChangeHandler: ((String) -> Void)?
    private var onFinishHandler: ((String) -> Void)?

    @StateObject private var stateController: UPCodeInputController
    @FocusState private var nativeInputIsFocused: Bool
    @Environment(\.upTheme) private var theme

    /// The native controller corresponding to a uview-plus component ref.
    public var controller: UPCodeInputController {
        stateController
    }

    /// The current component display value after the same truncation/filtering
    /// rules used by the source component.
    public var inputValue: String {
        stateController.inputValue
    }

    /// The source component renders its code string one character per cell.
    public var codeArray: [String] {
        stateController.inputValue.map(String.init)
    }

    public var resolvedMode: UPCodeInputMode {
        UPCodeInputMode(mode)
    }

    public var resolvedMaxlength: Int {
        stateController.resolvedMaxlength
    }

    public var resolvedSpace: Double {
        Self.dimension(space, fallback: UPConfig.codeInput.space)
    }

    public var resolvedFontSize: Double {
        Self.dimension(fontSize, fallback: UPConfig.codeInput.fontSize)
    }

    public var resolvedSize: Double {
        Self.dimension(size, fallback: UPConfig.codeInput.size)
    }

    public init(
        adjustPosition: Bool = UPConfig.codeInput.adjustPosition,
        maxlength: some UPCodeInputUnitValue = UPConfig.codeInput.maxlength,
        dot: Bool = UPConfig.codeInput.dot,
        mode: String = UPConfig.codeInput.mode,
        hairline: Bool = UPConfig.codeInput.hairline,
        space: some UPCodeInputUnitValue = UPConfig.codeInput.space,
        modelValue: Binding<String>? = nil,
        value: some UPCodeInputUnitValue = UPConfig.codeInput.value,
        focus: Bool = UPConfig.codeInput.focus,
        bold: Bool = UPConfig.codeInput.bold,
        color: String = UPConfig.codeInput.color,
        fontSize: some UPCodeInputUnitValue = UPConfig.codeInput.fontSize,
        size: some UPCodeInputUnitValue = UPConfig.codeInput.size,
        disabledKeyboard: Bool = UPConfig.codeInput.disabledKeyboard,
        borderColor: String = UPConfig.codeInput.borderColor,
        disabledDot: Bool = UPConfig.codeInput.disabledDot,
        customClass: String = UPConfig.codeInput.customClass,
        customStyle: UPStyle = UPConfig.codeInput.customStyle,
        onChange: ((String) -> Void)? = nil,
        onFinish: ((String) -> Void)? = nil,
        controller: UPCodeInputController? = nil
    ) {
        let maxlength = maxlength.upCheckboxUnitValue
        let space = space.upCheckboxUnitValue
        let value = value.upCheckboxUnitValue
        let fontSize = fontSize.upCheckboxUnitValue
        let size = size.upCheckboxUnitValue

        self.adjustPosition = adjustPosition
        self.maxlength = maxlength
        self.dot = dot
        self.mode = mode
        self.hairline = hairline
        self.space = space
        self.modelValue = modelValue
        self.value = value
        self.focus = focus
        self.bold = bold
        self.color = color
        self.fontSize = fontSize
        self.size = size
        self.disabledKeyboard = disabledKeyboard
        self.borderColor = borderColor
        self.disabledDot = disabledDot
        self.customClass = customClass
        self.customStyle = customStyle
        self.onChangeHandler = onChange
        self.onFinishHandler = onFinish

        let externalValue = modelValue?.wrappedValue ?? value
        let activeController = controller ?? UPCodeInputController(
            maxlength: maxlength,
            disabledDot: disabledDot,
            value: externalValue,
            focus: focus,
            onChange: onChange,
            onModelValueUpdate: modelValue.map { binding in
                { binding.wrappedValue = $0 }
            },
            onFinish: onFinish
        )
        _stateController = StateObject(wrappedValue: activeController)
    }

    /// Binding-first overload matching the argument ordering used by the
    /// other model-backed uview-plus SwiftUI components in this package.
    /// The prop-first initializer above remains available for callers that
    /// mirror the source component's declaration order.
    public init<Maxlength: UPCodeInputUnitValue, Space: UPCodeInputUnitValue, Value: UPCodeInputUnitValue, FontSize: UPCodeInputUnitValue, Size: UPCodeInputUnitValue>(
        modelValue: Binding<String>,
        adjustPosition: Bool = UPConfig.codeInput.adjustPosition,
        maxlength: Maxlength = UPConfig.codeInput.maxlength,
        dot: Bool = UPConfig.codeInput.dot,
        mode: String = UPConfig.codeInput.mode,
        hairline: Bool = UPConfig.codeInput.hairline,
        space: Space = UPConfig.codeInput.space,
        value: Value = UPConfig.codeInput.value,
        focus: Bool = UPConfig.codeInput.focus,
        bold: Bool = UPConfig.codeInput.bold,
        color: String = UPConfig.codeInput.color,
        fontSize: FontSize = UPConfig.codeInput.fontSize,
        size: Size = UPConfig.codeInput.size,
        disabledKeyboard: Bool = UPConfig.codeInput.disabledKeyboard,
        borderColor: String = UPConfig.codeInput.borderColor,
        disabledDot: Bool = UPConfig.codeInput.disabledDot,
        customClass: String = UPConfig.codeInput.customClass,
        customStyle: UPStyle = UPConfig.codeInput.customStyle,
        onChange: ((String) -> Void)? = nil,
        onFinish: ((String) -> Void)? = nil,
        controller: UPCodeInputController? = nil
    ) {
        self.init(
            adjustPosition: adjustPosition,
            maxlength: maxlength,
            dot: dot,
            mode: mode,
            hairline: hairline,
            space: space,
            modelValue: modelValue,
            value: value,
            focus: focus,
            bold: bold,
            color: color,
            fontSize: fontSize,
            size: size,
            disabledKeyboard: disabledKeyboard,
            borderColor: borderColor,
            disabledDot: disabledDot,
            customClass: customClass,
            customStyle: customStyle,
            onChange: onChange,
            onFinish: onFinish,
            controller: controller
        )
    }

    public var body: some View {
        ZStack {
            visibleInput
            nativeInput
        }
        .frame(height: CGFloat(resolvedSize))
        .upStyle(customStyle)
        .onAppear {
            synchronizeController()
            nativeInputIsFocused = focus
        }
        .onChange(of: configurationSignature) { _, _ in
            synchronizeController()
            nativeInputIsFocused = focus
        }
        .onChange(of: externalModelValue) { _, _ in
            synchronizeExternalModelValue()
        }
    }

    /// Testable/native bridge corresponding to a source `<input @input>` event.
    func triggerInput(_ value: String) {
        stateController.input(value)
    }

    /// Synchronizes a `v-model` update received outside the native text field.
    func synchronizeExternalModelValue() {
        stateController.synchronizeExternalValue(externalModelValue)
    }

    private var externalModelValue: String {
        modelValue?.wrappedValue ?? value
    }

    private var configurationSignature: String {
        [
            maxlength,
            disabledDot ? "1" : "0",
            focus ? "1" : "0"
        ].joined(separator: "\u{1F}")
    }

    private func synchronizeController() {
        stateController.setOnChangeHandler(onChangeHandler)
        stateController.setOnFinishHandler(onFinishHandler)
        stateController.configure(
            maxlength: maxlength,
            disabledDot: disabledDot,
            focus: focus,
            onChange: onChangeHandler,
            onModelValueUpdate: modelValue.map { binding in
                { binding.wrappedValue = $0 }
            },
            onFinish: onFinishHandler
        )
    }

    private var nativeInputValue: Binding<String> {
        Binding(
            get: { stateController.inputValue },
            set: { proposedValue in
                let truncated = String(proposedValue.prefix(stateController.resolvedMaxlength))
                stateController.input(truncated)
            }
        )
    }

    @ViewBuilder
    private var visibleInput: some View {
        if resolvedMode == .box && resolvedSpace == 0 {
            HStack(spacing: 0) {
                ForEach(0..<resolvedMaxlength, id: \.self) { index in
                    codeCell(index, connectedBox: true)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(resolvedBorderColor, lineWidth: borderLineWidth)
            }
        } else {
            HStack(spacing: CGFloat(resolvedSpace)) {
                ForEach(0..<resolvedMaxlength, id: \.self) { index in
                    codeCell(index, connectedBox: false)
                }
            }
        }
    }

    @ViewBuilder
    private var nativeInput: some View {
        TextField("", text: nativeInputValue)
#if os(iOS)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
#endif
            .font(.system(size: 1))
            .foregroundStyle(Color.clear)
            .tint(Color.clear)
            .opacity(0.01)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .focused($nativeInputIsFocused)
            .disabled(disabledKeyboard)
            .onChange(of: nativeInputIsFocused) { _, isFocused in
                stateController.setFocused(isFocused)
            }
            .accessibilityLabel("Verification code input")
    }

    @ViewBuilder
    private func codeCell(_ index: Int, connectedBox: Bool) -> some View {
        ZStack {
            if dot && codeArray.indices.contains(index) {
                Circle()
                    .fill(theme.content)
                    .frame(width: 7, height: 7)
            } else if codeArray.indices.contains(index) {
                Text(codeArray[index])
                    .font(.system(size: CGFloat(resolvedFontSize), weight: bold ? .bold : .regular))
                    .foregroundStyle(resolvedTextColor)
            }

            if resolvedMode == .line {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Capsule()
                        .fill(resolvedBorderColor)
                        .frame(height: hairline ? 2 : 4)
                }
            }

            if controller.isFocused && codeArray.count == index {
                Rectangle()
                    .fill(resolvedTextColor)
                    .frame(width: 1, height: 20)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: CGFloat(resolvedSize), height: CGFloat(resolvedSize))
        .overlay {
            if resolvedMode == .box && !connectedBox {
                Rectangle()
                    .stroke(resolvedBorderColor, lineWidth: borderLineWidth)
            }
        }
        .overlay(alignment: .leading) {
            if connectedBox && index > 0 {
                Rectangle()
                    .fill(resolvedBorderColor)
                    .frame(width: borderLineWidth)
            }
        }
    }

    private var borderLineWidth: CGFloat {
        hairline ? 0.5 : 1
    }

    private var resolvedTextColor: Color {
        UPColor.parse(color, theme: theme)
    }

    private var resolvedBorderColor: Color {
        UPColor.parse(borderColor, theme: theme)
    }

    private static func dimension(_ value: String, fallback: Double) -> Double {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !value.isEmpty else { return fallback }

        let numericString: Substring
        let usesRpx: Bool
        if value.hasSuffix("rpx") {
            numericString = value.dropLast(3)
            usesRpx = true
        } else if value.hasSuffix("px") {
            numericString = value.dropLast(2)
            usesRpx = false
        } else {
            numericString = Substring(value)
            usesRpx = false
        }

        guard let number = Double(numericString), number.isFinite, number >= 0 else {
            return fallback
        }
        return usesRpx ? UPUnit.rpx(number) : number
    }
}

public extension UPCodeInput {
    /// Registers the upstream `change(value)` event callback.
    func onChange(_ action: @escaping (String) -> Void) -> UPCodeInput {
        var copy = self
        copy.onChangeHandler = action
        copy.controller.setOnChangeHandler(action)
        return copy
    }

    /// Registers the upstream `finish(value)` event callback.
    func onFinish(_ action: @escaping (String) -> Void) -> UPCodeInput {
        var copy = self
        copy.onFinishHandler = action
        copy.controller.setOnFinishHandler(action)
        return copy
    }
}
