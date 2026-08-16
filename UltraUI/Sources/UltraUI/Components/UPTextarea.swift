import SwiftUI

/// A uview-plus-style multiline input with optional form-path binding.
@MainActor
public struct UPTextarea: View {
    var prop: String
    var text: Binding<String>?
    var placeholder: String
    var maxlength: Int?
    var count: Bool
    var disabled: Bool
    var readonly: Bool
    var height: Double
    var autoHeight: Bool
    var onChangeHandler: ((String) -> Void)?
    var onFocusHandler: (() -> Void)?
    var onBlurHandler: (() -> Void)?

    @Environment(\.upFormContext) private var form
    @Environment(\.upTheme) private var theme
    @State private var localText = ""
    @FocusState private var isFocused: Bool

    public init(prop: String = UPConfig.textarea.prop,
                text: Binding<String>? = nil,
                placeholder: String = UPConfig.textarea.placeholder,
                maxlength: Int? = UPConfig.textarea.maxlength,
                count: Bool = UPConfig.textarea.count,
                disabled: Bool = UPConfig.textarea.disabled,
                readonly: Bool = UPConfig.textarea.readonly,
                height: Double = UPConfig.textarea.height,
                autoHeight: Bool = UPConfig.textarea.autoHeight) {
        self.prop = prop
        self.text = text
        self.placeholder = placeholder
        self.maxlength = maxlength
        self.count = count
        self.disabled = disabled
        self.readonly = readonly
        self.height = height
        self.autoHeight = autoHeight
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if currentValue.isEmpty, !placeholder.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(theme.tips)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }

                TextField("", text: textBinding, axis: .vertical)
                    .lineLimit(Self.resolvedLineLimit(autoHeight: autoHeight))
                    .focused($isFocused)
                    .fixedSize(horizontal: false, vertical: autoHeight)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: autoHeight ? nil : max(0, height), alignment: .topLeading)
            .foregroundStyle(disabled ? theme.disabled : theme.main)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(theme.border, lineWidth: 1)
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

    private var countText: String {
        if let maxlength {
            return "\(currentValue.count)/\(max(0, maxlength))"
        }
        return "\(currentValue.count)"
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
