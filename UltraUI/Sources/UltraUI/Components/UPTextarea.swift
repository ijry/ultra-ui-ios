import SwiftUI

/// A native SwiftUI counterpart of uview-plus `u-textarea`.
@MainActor
public struct UPTextarea: View {
    // Native extension retained for form-path integrations.
    var prop: String
    var text: Binding<String>?
    var readonly: Bool

    // uview-plus props.
    var value: String
    var modelValue: Binding<String>?
    var placeholder: String
    var placeholderClass: String
    var placeholderStyle: UPStyle
    var height: Double
    var confirmType: String
    var disabled: Bool
    var count: Bool
    var focus: Bool
    var autoHeight: Bool
    var fixed: Bool
    var cursorSpacing: Double
    var cursor: Int
    var showConfirmBar: Bool
    var selectionStart: Int
    var selectionEnd: Int
    var adjustPosition: Bool
    var disableDefaultPadding: Bool
    var holdKeyboard: Bool
    var maxlength: Int?
    var border: String
    var formatter: ((String) -> String)?
    var ignoreCompositionEvent: Bool

    // Vue emits represented as typed closures.
    var onLineChange: ((Int) -> Void)?
    var onConfirm: ((String) -> Void)?
    var onKeyboardHeightChange: ((Double) -> Void)?
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
    @FocusState private var isFocused: Bool

    public init(prop: String = UPConfig.textarea.prop,
                text: Binding<String>? = nil,
                placeholder: String = UPConfig.textarea.placeholder,
                maxlength: Int? = UPConfig.textarea.maxlength,
                count: Bool = UPConfig.textarea.count,
                disabled: Bool = UPConfig.textarea.disabled,
                readonly: Bool = UPConfig.textarea.readonly,
                height: Double = UPConfig.textarea.height,
                autoHeight: Bool = UPConfig.textarea.autoHeight,
                modelValue: Binding<String>? = nil,
                value: String = UPConfig.textarea.value,
                placeholderClass: String = UPConfig.textarea.placeholderClass,
                placeholderStyle: UPStyle = UPConfig.textarea.placeholderStyle,
                confirmType: String = UPConfig.textarea.confirmType,
                focus: Bool = UPConfig.textarea.focus,
                fixed: Bool = UPConfig.textarea.fixed,
                cursorSpacing: Double = UPConfig.textarea.cursorSpacing,
                cursor: Int = UPConfig.textarea.cursor,
                showConfirmBar: Bool = UPConfig.textarea.showConfirmBar,
                selectionStart: Int = UPConfig.textarea.selectionStart,
                selectionEnd: Int = UPConfig.textarea.selectionEnd,
                adjustPosition: Bool = UPConfig.textarea.adjustPosition,
                disableDefaultPadding: Bool = UPConfig.textarea.disableDefaultPadding,
                holdKeyboard: Bool = UPConfig.textarea.holdKeyboard,
                border: String = UPConfig.textarea.border,
                formatter: ((String) -> String)? = nil,
                ignoreCompositionEvent: Bool = UPConfig.textarea.ignoreCompositionEvent,
                onLineChange: ((Int) -> Void)? = nil,
                onConfirm: ((String) -> Void)? = nil,
                onKeyboardHeightChange: ((Double) -> Void)? = nil,
                onChange: ((String) -> Void)? = nil,
                onFocus: (() -> Void)? = nil,
                onBlur: (() -> Void)? = nil) {
        self.prop = prop
        self.text = text
        self.readonly = readonly
        self.value = value
        self.modelValue = modelValue
        self.placeholder = placeholder
        self.placeholderClass = placeholderClass
        self.placeholderStyle = placeholderStyle
        self.height = height
        self.confirmType = confirmType
        self.disabled = disabled
        self.count = count
        self.focus = focus
        self.autoHeight = autoHeight
        self.fixed = fixed
        self.cursorSpacing = cursorSpacing
        self.cursor = cursor
        self.showConfirmBar = showConfirmBar
        self.selectionStart = selectionStart
        self.selectionEnd = selectionEnd
        self.adjustPosition = adjustPosition
        self.disableDefaultPadding = disableDefaultPadding
        self.holdKeyboard = holdKeyboard
        self.maxlength = maxlength
        self.border = border
        self.formatter = formatter
        self.ignoreCompositionEvent = ignoreCompositionEvent
        self.onLineChange = onLineChange
        self.onConfirm = onConfirm
        self.onKeyboardHeightChange = onKeyboardHeightChange
        self.onChangeEvent = onChange
        self.onFocusEvent = onFocus
        self.onBlurEvent = onBlur
        _localText = State(initialValue: value)
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if currentValue.isEmpty, !placeholder.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(theme.tips)
                        .padding(.horizontal, disableDefaultPadding ? 0 : 12)
                        .padding(.vertical, disableDefaultPadding ? 0 : 10)
                        .upStyle(placeholderStyle)
                        .allowsHitTesting(false)
                }

                TextField("", text: textBinding, axis: .vertical)
                    .lineLimit(Self.resolvedLineLimit(autoHeight: autoHeight))
                    .focused($isFocused)
                    .fixedSize(horizontal: false, vertical: autoHeight)
                    .padding(.horizontal, disableDefaultPadding ? 0 : 8)
                    .padding(.vertical, disableDefaultPadding ? 0 : 8)
                    .onSubmit(confirmValue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: autoHeight ? nil : max(0, height), alignment: .topLeading)
            .foregroundStyle(disabled ? theme.disabled : theme.main)
            .overlay {
                if UPInput.resolvedBorder(border) == "surround" {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(theme.border, lineWidth: 1)
                }
            }
            .overlay(alignment: .bottom) {
                if UPInput.resolvedBorder(border) == "bottom" {
                    Rectangle()
                        .fill(theme.border)
                        .frame(height: 0.5)
                }
            }
            .disabled(disabled || readonly)

            if count {
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

    /// Applies the single-line input's length limit so both components normalize text identically.
    public static func truncated(_ value: String, maxlength: Int?) -> String {
        UPInput.truncated(value, maxlength: maxlength)
    }

    static func resolvedLineLimit(autoHeight: Bool) -> ClosedRange<Int> {
        autoHeight ? 3...8 : 1...1
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
            onChange: onChange,
            onLineChange: nil
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
                       onChange: ((String) -> Void)?,
                       onLineChange: ((Int) -> Void)?) {
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
        onChange?(resolvedValue)
        onLineChange?(lineCount(in: resolvedValue))
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
        let onLineChange = onLineChange
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
                    onChange: { value in
                        onChangeEvent?(value)
                        onChangeHandler?(value)
                    },
                    onLineChange: onLineChange
                )
            }
        )
    }

    private var countText: String {
        if let maxlength {
            return "\(currentValue.count)/\(max(0, maxlength))"
        }
        return "\(currentValue.count)"
    }

    private func confirmValue() {
        onConfirm?(currentValue)
    }

    private static func lineCount(in value: String) -> Int {
        guard !value.isEmpty else { return 0 }
        return value.split(whereSeparator: \.isNewline).count
    }
}

public extension UPTextarea {
    func onChange(_ action: @escaping (String) -> Void) -> UPTextarea {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    func onFocus(_ action: @escaping () -> Void) -> UPTextarea {
        var copy = self
        copy.onFocusHandler = action
        return copy
    }

    func onBlur(_ action: @escaping () -> Void) -> UPTextarea {
        var copy = self
        copy.onBlurHandler = action
        return copy
    }
}
