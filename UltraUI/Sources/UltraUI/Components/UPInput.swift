import SwiftUI

/// A uview-plus-style single-line input with optional form-path binding.
@MainActor
public struct UPInput: View {
    var prop: String
    var text: Binding<String>?
    var type: String
    var placeholder: String
    var border: String
    var inputAlign: String
    var clearable: Bool
    var disabled: Bool
    var readonly: Bool
    var prefixIcon: String
    var suffixIcon: String
    var maxlength: Int?
    var count: Bool
    var onChangeHandler: ((String) -> Void)?
    var onFocusHandler: (() -> Void)?
    var onBlurHandler: (() -> Void)?

    @Environment(\.upFormContext) private var form
    @Environment(\.upTheme) private var theme
    @State private var localText = ""
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
                count: Bool = UPConfig.input.count) {
        self.prop = prop
        self.text = text
        self.type = type
        self.placeholder = placeholder
        self.border = border
        self.inputAlign = inputAlign
        self.clearable = clearable
        self.disabled = disabled
        self.readonly = readonly
        self.prefixIcon = prefixIcon
        self.suffixIcon = suffixIcon
        self.maxlength = maxlength
        self.count = count
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                if !prefixIcon.isEmpty {
                    UPIcon(name: prefixIcon, color: "#909399", size: "16px")
                }

                field
                    .frame(maxWidth: .infinity)

                if shouldShowClearButton {
                    Button {
                        commitValue("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.tips)
                    }
                    .buttonStyle(.plain)
                }

                if !suffixIcon.isEmpty {
                    UPIcon(name: suffixIcon, color: "#909399", size: "16px")
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 42)
            .foregroundStyle(disabled ? theme.disabled : theme.main)
            .background(Color.clear)
            .overlay {
                if Self.resolvedBorder(border) == "surround" {
                    RoundedRectangle(cornerRadius: 4)
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
            .disabled(disabled)

            if count {
                Text(countText)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.tips)
            }
        }
        .onChange(of: isFocused) { _, focused in
            if focused {
                onFocusHandler?()
            } else {
                if !prop.isEmpty, let form {
                    _ = form.validate(prop: prop, trigger: "blur")
                }
                onBlurHandler?()
            }
        }
    }

    /// Applies the same user-input limit used by form and directly bound text fields.
    public static func truncated(_ value: String, maxlength: Int?) -> String {
        guard let maxlength else { return value }
        return String(value.prefix(max(0, maxlength)))
    }

    static func resolvedBorder(_ border: String) -> String {
        switch border {
        case "bottom", "none": return border
        default: return "surround"
        }
    }

    static func resolvedType(_ type: String) -> String {
        type == "password" ? "password" : "text"
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
        if !prop.isEmpty, let form {
            return form.value(for: prop).stringValue
        }
        return directText?.wrappedValue ?? fallbackText.wrappedValue
    }

    static func commit(_ proposedValue: String,
                       prop: String,
                       form: UPFormContext?,
                       directText: Binding<String>?,
                       fallbackText: Binding<String>,
                       maxlength: Int?,
                       readonly: Bool,
                       onChange: ((String) -> Void)?) {
        guard !readonly else { return }

        let value = truncated(proposedValue, maxlength: maxlength)
        if !prop.isEmpty, let form {
            form.set(.string(value), for: prop, trigger: "change")
        } else if let directText {
            directText.wrappedValue = value
        } else {
            fallbackText.wrappedValue = value
        }
        onChange?(value)
    }

    private var currentValue: String {
        Self.value(prop: prop, form: form, directText: text, fallbackText: $localText)
    }

    private var textBinding: Binding<String> {
        let form = form
        let directText = text
        let fallbackText = $localText
        let prop = prop
        let maxlength = maxlength
        let readonly = readonly
        let onChange = onChangeHandler

        return Binding(
            get: {
                Self.value(
                    prop: prop,
                    form: form,
                    directText: directText,
                    fallbackText: fallbackText
                )
            },
            set: { proposedValue in
                Self.commit(
                    proposedValue,
                    prop: prop,
                    form: form,
                    directText: directText,
                    fallbackText: fallbackText,
                    maxlength: maxlength,
                    readonly: readonly,
                    onChange: onChange
                )
            }
        )
    }

    @ViewBuilder
    private var field: some View {
        if Self.resolvedType(type) == "password" {
            SecureField(placeholder, text: textBinding)
                .multilineTextAlignment(Self.resolvedTextAlignment(inputAlign))
                .focused($isFocused)
        } else {
            TextField(placeholder, text: textBinding)
                .multilineTextAlignment(Self.resolvedTextAlignment(inputAlign))
                .focused($isFocused)
        }
    }

    private var shouldShowClearButton: Bool {
        clearable && !currentValue.isEmpty && !disabled && !readonly
    }

    private var countText: String {
        if let maxlength {
            return "\(currentValue.count)/\(max(0, maxlength))"
        }
        return "\(currentValue.count)"
    }

    private func commitValue(_ value: String) {
        Self.commit(
            value,
            prop: prop,
            form: form,
            directText: text,
            fallbackText: $localText,
            maxlength: maxlength,
            readonly: readonly,
            onChange: onChangeHandler
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
