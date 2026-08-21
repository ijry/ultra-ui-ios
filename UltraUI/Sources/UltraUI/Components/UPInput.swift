import SwiftUI

/// A native SwiftUI counterpart of uview-plus `u-input`.
///
/// `modelValue` is the direct SwiftUI equivalent of Vue's `v-model`. The
/// earlier `text` and `prop` bindings remain available for source compatibility
/// with the original UltraUI API.
@MainActor
public struct UPInput: View {
    // Native extension retained for form-path integrations.
    var prop: String
    var text: Binding<String>?

    // uview-plus props.
    var modelValue: Binding<String>?
    var value: String
    var type: String
    var fixed: Bool
    var disabled: Bool
    var disabledColor: String
    var clearable: Bool
    var onlyClearableOnFocused: Bool
    var password: Bool
    var maxlength: Int?
    var placeholder: String
    var placeholderClass: String
    var placeholderStyle: UPStyle
    var showWordLimit: Bool
    /// Existing native alias for uview-plus `showWordLimit`.
    var count: Bool
    var confirmType: String
    var confirmHold: Bool
    var holdKeyboard: Bool
    var focus: Bool
    var autoBlur: Bool
    var disableDefaultPadding: Bool
    var cursor: Int
    var cursorSpacing: Double
    var selectionStart: Int
    var selectionEnd: Int
    var adjustPosition: Bool
    var inputAlign: String
    var fontSize: String
    var color: String
    var prefixIcon: String
    var prefixIconStyle: UPStyle
    var suffixIcon: String
    var suffixIconStyle: UPStyle
    var border: String
    var readonly: Bool
    var shape: String
    var formatter: ((String) -> String)?
    var ignoreCompositionEvent: Bool
    var cursorColor: String
    var passwordVisibilityToggle: Bool

    // Vue emits represented as typed closures.
    var onInput: ((String) -> Void)?
    var onConfirm: ((String) -> Void)?
    var onClear: (() -> Void)?
    var onKeyboardHeightChange: ((Double) -> Void)?
    var onNicknameReview: (() -> Void)?
    var onChangeEvent: ((String) -> Void)?
    var onFocusEvent: (() -> Void)?
    var onBlurEvent: (() -> Void)?

    // Earlier native modifier hooks.
    var onChangeHandler: ((String) -> Void)?
    var onFocusHandler: (() -> Void)?
    var onBlurHandler: (() -> Void)?

    @Environment(\.upFormContext) private var form
    @Environment(\.upTheme) private var theme
    @State private var localText: String
    @State private var passwordVisible = false
    @FocusState private var isFocused: Bool

    public init(prop: String = UPConfig.input.prop,
                text: Binding<String>? = nil,
                type: String = UPConfig.input.type,
                placeholder: String = UPConfig.input.placeholder,
                border: String = UPConfig.input.border,
                inputAlign: String = UPConfig.input.inputAlign,
                clearable: Bool = UPConfig.input.clearable,
                disabled: Bool = UPConfig.input.disabled,
                readonly: Bool = UPConfig.input.readonly,
                prefixIcon: String = UPConfig.input.prefixIcon,
                suffixIcon: String = UPConfig.input.suffixIcon,
                maxlength: Int? = UPConfig.input.maxlength,
                count: Bool = UPConfig.input.count,
                modelValue: Binding<String>? = nil,
                value: String = UPConfig.input.value,
                fixed: Bool = UPConfig.input.fixed,
                disabledColor: String = UPConfig.input.disabledColor,
                onlyClearableOnFocused: Bool = UPConfig.input.onlyClearableOnFocused,
                password: Bool = UPConfig.input.password,
                placeholderClass: String = UPConfig.input.placeholderClass,
                placeholderStyle: UPStyle = UPConfig.input.placeholderStyle,
                showWordLimit: Bool = UPConfig.input.showWordLimit,
                confirmType: String = UPConfig.input.confirmType,
                confirmHold: Bool = UPConfig.input.confirmHold,
                holdKeyboard: Bool = UPConfig.input.holdKeyboard,
                focus: Bool = UPConfig.input.focus,
                autoBlur: Bool = UPConfig.input.autoBlur,
                disableDefaultPadding: Bool = UPConfig.input.disableDefaultPadding,
                cursor: Int = UPConfig.input.cursor,
                cursorSpacing: Double = UPConfig.input.cursorSpacing,
                selectionStart: Int = UPConfig.input.selectionStart,
                selectionEnd: Int = UPConfig.input.selectionEnd,
                adjustPosition: Bool = UPConfig.input.adjustPosition,
                fontSize: String = UPConfig.input.fontSize,
                color: String = UPConfig.input.color,
                prefixIconStyle: UPStyle = UPConfig.input.prefixIconStyle,
                suffixIconStyle: UPStyle = UPConfig.input.suffixIconStyle,
                shape: String = UPConfig.input.shape,
                formatter: ((String) -> String)? = nil,
                ignoreCompositionEvent: Bool = UPConfig.input.ignoreCompositionEvent,
                cursorColor: String = UPConfig.input.cursorColor,
                passwordVisibilityToggle: Bool = UPConfig.input.passwordVisibilityToggle,
                onInput: ((String) -> Void)? = nil,
                onConfirm: ((String) -> Void)? = nil,
                onClear: (() -> Void)? = nil,
                onKeyboardHeightChange: ((Double) -> Void)? = nil,
                onNicknameReview: (() -> Void)? = nil,
                onChange: ((String) -> Void)? = nil,
                onFocus: (() -> Void)? = nil,
                onBlur: (() -> Void)? = nil) {
        self.prop = prop
        self.text = text
        self.modelValue = modelValue
        self.value = value
        self.type = type
        self.fixed = fixed
        self.disabled = disabled
        self.disabledColor = disabledColor
        self.clearable = clearable
        self.onlyClearableOnFocused = onlyClearableOnFocused
        self.password = password
        self.maxlength = maxlength
        self.placeholder = placeholder
        self.placeholderClass = placeholderClass
        self.placeholderStyle = placeholderStyle
        self.showWordLimit = showWordLimit
        self.count = count
        self.confirmType = confirmType
        self.confirmHold = confirmHold
        self.holdKeyboard = holdKeyboard
        self.focus = focus
        self.autoBlur = autoBlur
        self.disableDefaultPadding = disableDefaultPadding
        self.cursor = cursor
        self.cursorSpacing = cursorSpacing
        self.selectionStart = selectionStart
        self.selectionEnd = selectionEnd
        self.adjustPosition = adjustPosition
        self.inputAlign = inputAlign
        self.fontSize = fontSize
        self.color = color
        self.prefixIcon = prefixIcon
        self.prefixIconStyle = prefixIconStyle
        self.suffixIcon = suffixIcon
        self.suffixIconStyle = suffixIconStyle
        self.border = border
        self.readonly = readonly
        self.shape = shape
        self.formatter = formatter
        self.ignoreCompositionEvent = ignoreCompositionEvent
        self.cursorColor = cursorColor
        self.passwordVisibilityToggle = passwordVisibilityToggle
        self.onInput = onInput
        self.onConfirm = onConfirm
        self.onClear = onClear
        self.onKeyboardHeightChange = onKeyboardHeightChange
        self.onNicknameReview = onNicknameReview
        self.onChangeEvent = onChange
        self.onFocusEvent = onFocus
        self.onBlurEvent = onBlur
        _localText = State(initialValue: value)
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                if !prefixIcon.isEmpty {
                    UPIcon(name: prefixIcon, color: "#909399", size: "16px")
                        .upStyle(prefixIconStyle)
                }

                field
                    .frame(maxWidth: .infinity)

                if shouldShowClearButton {
                    Button(action: clearValue) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.tips)
                    }
                    .buttonStyle(.plain)
                }

                if !suffixIcon.isEmpty {
                    UPIcon(name: suffixIcon, color: "#909399", size: "16px")
                        .upStyle(suffixIconStyle)
                }
            }
            .padding(.horizontal, disableDefaultPadding ? 0 : 12)
            .frame(minHeight: 42)
            .font(.system(size: resolvedFontSize))
            .foregroundStyle(displayColor)
            .background(disabled && !disabledColor.isEmpty ? UPColor.parse(disabledColor, theme: theme) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if Self.resolvedBorder(border) == "surround" {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(theme.border, lineWidth: 1)
                }
            }
            .overlay(alignment: .bottom) {
                if Self.resolvedBorder(border) == "bottom" {
                    Rectangle()
                        .fill(theme.border)
                        .frame(height: 0.5)
                }
            }
            .disabled(disabled || readonly)

            if showWordLimit || count {
                Text(countText)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.tips)
            }
        }
        .onAppear {
            if focus && !disabled && !readonly {
                isFocused = true
            }
        }
        .onChange(of: focus) { _, requestedFocus in
            if !disabled && !readonly {
                isFocused = requestedFocus
            }
        }
        .onChange(of: isFocused) { _, focused in
            if focused {
                onFocusHandler?()
                onFocusEvent?()
            } else {
                if !prop.isEmpty, let form {
                    _ = form.validate(prop: prop, trigger: "blur")
                }
                onBlurHandler?()
                onBlurEvent?()
            }
        }
    }

    /// Applies the same user-input limit used by form and directly bound text fields.
    public static func truncated(_ value: String, maxlength: Int?) -> String {
        guard let maxlength, maxlength >= 0 else { return value }
        return String(value.prefix(maxlength))
    }

    static func resolvedBorder(_ border: String) -> String {
        switch border {
        case "bottom", "none": return border
        default: return "surround"
        }
    }

    static func resolvedType(_ type: String) -> String {
        switch type {
        case "password": return "password"
        case "number", "digit", "idcard", "text": return type
        default: return "text"
        }
    }

    static func resolvedTextAlignment(_ inputAlign: String) -> TextAlignment {
        switch inputAlign {
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }

    static func value(prop: String,
                      form: UPFormContext?,
                      directText: Binding<String>?,
                      fallbackText: Binding<String>) -> String {
        value(
            prop: prop,
            form: form,
            modelValue: nil,
            directText: directText,
            fallbackText: fallbackText
        )
    }

    static func value(prop: String,
                      form: UPFormContext?,
                      modelValue: Binding<String>?,
                      directText: Binding<String>?,
                      fallbackText: Binding<String>) -> String {
        if !prop.isEmpty, let form {
            return form.value(for: prop).stringValue
        }
        return modelValue?.wrappedValue ?? directText?.wrappedValue ?? fallbackText.wrappedValue
    }

    static func commit(_ proposedValue: String,
                       prop: String,
                       form: UPFormContext?,
                       directText: Binding<String>?,
                       fallbackText: Binding<String>,
                       maxlength: Int?,
                       readonly: Bool,
                       onChange: ((String) -> Void)?) {
        commit(
            proposedValue,
            prop: prop,
            form: form,
            modelValue: nil,
            directText: directText,
            fallbackText: fallbackText,
            maxlength: maxlength,
            readonly: readonly,
            formatter: nil,
            onInput: nil,
            onChange: onChange
        )
    }

    static func commit(_ proposedValue: String,
                       prop: String,
                       form: UPFormContext?,
                       modelValue: Binding<String>?,
                       directText: Binding<String>?,
                       fallbackText: Binding<String>,
                       maxlength: Int?,
                       readonly: Bool,
                       formatter: ((String) -> String)?,
                       onInput: ((String) -> Void)?,
                       onChange: ((String) -> Void)?) {
        guard !readonly else { return }

        let formatted = formatter?(proposedValue) ?? proposedValue
        let resolvedValue = truncated(formatted, maxlength: maxlength)
        if !prop.isEmpty, let form {
            form.set(.string(resolvedValue), for: prop, trigger: "change")
        } else if let modelValue {
            modelValue.wrappedValue = resolvedValue
        } else if let directText {
            directText.wrappedValue = resolvedValue
        } else {
            fallbackText.wrappedValue = resolvedValue
        }
        onInput?(resolvedValue)
        onChange?(resolvedValue)
    }

    private var currentValue: String {
        Self.value(
            prop: prop,
            form: form,
            modelValue: modelValue,
            directText: text,
            fallbackText: $localText
        )
    }

    private var textBinding: Binding<String> {
        let form = form
        let modelValue = modelValue
        let directText = text
        let fallbackText = $localText
        let prop = prop
        let maxlength = maxlength
        let readonly = readonly
        let formatter = formatter
        let onInput = onInput
        let onChangeEvent = onChangeEvent
        let onChangeHandler = onChangeHandler

        return Binding(
            get: {
                Self.value(
                    prop: prop,
                    form: form,
                    modelValue: modelValue,
                    directText: directText,
                    fallbackText: fallbackText
                )
            },
            set: { proposedValue in
                Self.commit(
                    proposedValue,
                    prop: prop,
                    form: form,
                    modelValue: modelValue,
                    directText: directText,
                    fallbackText: fallbackText,
                    maxlength: maxlength,
                    readonly: readonly,
                    formatter: formatter,
                    onInput: onInput,
                    onChange: { value in
                        onChangeEvent?(value)
                        onChangeHandler?(value)
                    }
                )
            }
        )
    }

    @ViewBuilder
    private var field: some View {
        if isPassword && !passwordVisible {
            SecureField(placeholder, text: textBinding)
                .multilineTextAlignment(Self.resolvedTextAlignment(inputAlign))
                .focused($isFocused)
                .tint(UPColor.parse(cursorColor, theme: theme))
                .onSubmit(confirmValue)
        } else {
            TextField(placeholder, text: textBinding)
                .multilineTextAlignment(Self.resolvedTextAlignment(inputAlign))
                .focused($isFocused)
                .tint(UPColor.parse(cursorColor, theme: theme))
                .onSubmit(confirmValue)
        }

        if isPassword && passwordVisibilityToggle {
            Button {
                passwordVisible.toggle()
            } label: {
                Image(systemName: passwordVisible ? "eye.slash" : "eye")
                    .foregroundStyle(theme.tips)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(passwordVisible ? "隐藏密码" : "显示密码")
        }
    }

    private var isPassword: Bool {
        password || Self.resolvedType(type) == "password"
    }

    private var shouldShowClearButton: Bool {
        clearable && !currentValue.isEmpty && !disabled && !readonly && (!onlyClearableOnFocused || isFocused)
    }

    private var countText: String {
        if let maxlength {
            return "\(currentValue.count)/\(max(0, maxlength))"
        }
        return "\(currentValue.count)"
    }

    private var cornerRadius: CGFloat {
        shape == "circle" ? 21 : 4
    }

    private var resolvedFontSize: CGFloat {
        let value = UPUnit.parse(fontSize)
        return value > 0 ? value : 15
    }

    private var displayColor: Color {
        if disabled { return theme.disabled }
        return color.isEmpty ? theme.main : UPColor.parse(color, theme: theme)
    }

    private func clearValue() {
        commitValue("")
        onClear?()
    }

    private func confirmValue() {
        onConfirm?(currentValue)
        if autoBlur {
            isFocused = false
        }
    }

    private func commitValue(_ proposedValue: String) {
        Self.commit(
            proposedValue,
            prop: prop,
            form: form,
            modelValue: modelValue,
            directText: text,
            fallbackText: $localText,
            maxlength: maxlength,
            readonly: readonly,
            formatter: formatter,
            onInput: onInput,
            onChange: { value in
                onChangeEvent?(value)
                onChangeHandler?(value)
            }
        )
    }
}

public extension UPInput {
    func onChange(_ action: @escaping (String) -> Void) -> UPInput {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    func onFocus(_ action: @escaping () -> Void) -> UPInput {
        var copy = self
        copy.onFocusHandler = action
        return copy
    }

    func onBlur(_ action: @escaping () -> Void) -> UPInput {
        var copy = self
        copy.onBlurHandler = action
        return copy
    }
}
