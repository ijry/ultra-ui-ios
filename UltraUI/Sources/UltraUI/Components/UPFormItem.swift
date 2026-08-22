import SwiftUI

/// A labeled field container that renders form errors from the surrounding `UPForm`.
@MainActor
public struct UPFormItem<Content: View>: View {
    var label: String
    var prop: String
    var rules: [UPFormRule]
    var borderBottom: Bool
    var labelPosition: String
    var labelWidth: String
    var rightIcon: String
    var leftIcon: String
    var required: Bool
    var leftIconStyle: UPStyle
    var help: String
    var onClick: (() -> Void)?
    @ViewBuilder var content: () -> Content
    private var rightContent: () -> AnyView
    private var inheritsBorderBottom: Bool
    private var inheritsLabelPosition: Bool
    private var inheritsLabelWidth: Bool

    // Upstream `label` and `error` named slots.
    private var labelContent: AnyView?
    private var errorContent: AnyView?

    var hasLabelSlot: Bool { labelContent != nil }
    var hasErrorSlot: Bool { errorContent != nil }

    @Environment(\.upFormContext) private var form
    @Environment(\.upTheme) private var theme
    @State private var ruleRegistrationID = UUID()

    public init(label: String = UPConfig.formItem.label,
                prop: String = UPConfig.formItem.prop,
                rules: [UPFormRule] = [],
                borderBottom: Bool? = UPConfig.formItem.borderBottom,
                labelPosition: String = UPConfig.formItem.labelPosition,
                labelWidth: String = UPConfig.formItem.labelWidth,
                rightIcon: String = UPConfig.formItem.rightIcon,
                leftIcon: String = UPConfig.formItem.leftIcon,
                leftIconStyle: UPStyle = UPConfig.formItem.leftIconStyle,
                required: Bool = UPConfig.formItem.required,
                help: String = UPConfig.formItem.help,
                onClick: (() -> Void)? = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.prop = prop
        self.rules = rules
        self.inheritsBorderBottom = borderBottom == nil
        self.borderBottom = borderBottom ?? UPConfig.form.borderBottom
        self.inheritsLabelPosition = labelPosition.isEmpty
        self.labelPosition = Self.resolvedLabelPosition(
            labelPosition.isEmpty ? UPConfig.form.labelPosition : labelPosition
        )
        self.inheritsLabelWidth = labelWidth.isEmpty
        self.labelWidth = labelWidth.isEmpty ? UPConfig.form.labelWidth : labelWidth
        self.rightIcon = rightIcon
        self.leftIcon = leftIcon
        self.required = required
        self.leftIconStyle = leftIconStyle
        self.help = help
        self.onClick = onClick
        self.content = content
        self.rightContent = { AnyView(EmptyView()) }
    }

    public init<Right: View>(label: String = UPConfig.formItem.label,
                             prop: String = UPConfig.formItem.prop,
                             rules: [UPFormRule] = [],
                             borderBottom: Bool? = UPConfig.formItem.borderBottom,
                             labelPosition: String = UPConfig.formItem.labelPosition,
                             labelWidth: String = UPConfig.formItem.labelWidth,
                             rightIcon: String = UPConfig.formItem.rightIcon,
                             leftIcon: String = UPConfig.formItem.leftIcon,
                             leftIconStyle: UPStyle = UPConfig.formItem.leftIconStyle,
                             required: Bool = UPConfig.formItem.required,
                             help: String = UPConfig.formItem.help,
                             onClick: (() -> Void)? = nil,
                             @ViewBuilder content: @escaping () -> Content,
                             @ViewBuilder right: @escaping () -> Right) {
        self.label = label
        self.prop = prop
        self.rules = rules
        self.inheritsBorderBottom = borderBottom == nil
        self.borderBottom = borderBottom ?? UPConfig.form.borderBottom
        self.inheritsLabelPosition = labelPosition.isEmpty
        self.labelPosition = Self.resolvedLabelPosition(
            labelPosition.isEmpty ? UPConfig.form.labelPosition : labelPosition
        )
        self.inheritsLabelWidth = labelWidth.isEmpty
        self.labelWidth = labelWidth.isEmpty ? UPConfig.form.labelWidth : labelWidth
        self.rightIcon = rightIcon
        self.leftIcon = leftIcon
        self.required = required
        self.leftIconStyle = leftIconStyle
        self.help = help
        self.onClick = onClick
        self.content = content
        self.rightContent = { AnyView(right()) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if effectiveLabelPosition == "top" {
                VStack(alignment: .leading, spacing: 8) {
                    labelView
                    fieldContent
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    labelView
                        .frame(width: UPUnit.parse(effectiveLabelWidth), alignment: labelFrameAlignment)
                    fieldContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if !help.isEmpty {
                Text(help)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.tips)
            }

            let error = form?.errors[prop] ?? ""
            if let errorContent, !error.isEmpty {
                errorContent
            } else if Self.shouldShowError(errorType: form?.errorType ?? UPConfig.form.errorType, error: error) {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.error)
            }

            if effectiveBorderBottom {
                UPLine(color: tintsBorder ? "#f56c6c" : UPConfig.line.color)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { onClick?() }
        .onAppear(perform: synchronizeItemRules)
        .onChange(of: prop) { _, _ in synchronizeItemRules() }
        .onChange(of: itemRulesSignature) { _, _ in synchronizeItemRules() }
        .onDisappear { form?.unregisterItemRules(registrationID: ruleRegistrationID) }
    }

    static func resolvedLabelPosition(_ labelPosition: String) -> String {
        UPFormContext.resolvedLabelPosition(labelPosition)
    }

    static func resolvedLabelAlign(_ labelAlign: String) -> String {
        UPFormContext.resolvedLabelAlign(labelAlign)
    }

    static func shouldShowError(errorType: String, error: String) -> Bool {
        !error.isEmpty && UPFormContext.resolvedErrorType(errorType) == "message"
    }

    /// `border-bottom` reports the failure by tinting the underline red rather
    /// than printing a message below the field.
    static func shouldTintBorder(errorType: String, error: String) -> Bool {
        !error.isEmpty && UPFormContext.resolvedErrorType(errorType) == "border-bottom"
    }

    private var itemRulesSignature: String {
        rules.map { rule in
            [
                rule.required ? "1" : "0",
                rule.min.map(String.init) ?? "",
                rule.max.map(String.init) ?? "",
                rule.length.map(String.init) ?? "",
                rule.pattern ?? "",
                rule.message,
                rule.trigger,
                rule.validator == nil ? "0" : "1"
            ].joined(separator: "\u{1F}")
        }.joined(separator: "\u{1E}")
    }

    private func synchronizeItemRules() {
        form?.registerItemRules(rules, for: prop, registrationID: ruleRegistrationID)
    }

    private var effectiveBorderBottom: Bool {
        inheritsBorderBottom ? (form?.borderBottom ?? borderBottom) : borderBottom
    }

    private var effectiveLabelPosition: String {
        inheritsLabelPosition ? (form?.labelPosition ?? labelPosition) : labelPosition
    }

    private var effectiveLabelWidth: String {
        inheritsLabelWidth ? (form?.labelWidth ?? labelWidth) : labelWidth
    }

    private var effectiveLabelStyle: UPStyle {
        form?.labelStyle ?? UPConfig.form.labelStyle
    }

    private var effectiveLabelAlign: String {
        form?.labelAlign ?? UPConfig.form.labelAlign
    }

    private var labelFrameAlignment: Alignment {
        switch Self.resolvedLabelAlign(effectiveLabelAlign) {
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }

    @ViewBuilder
    private var fieldContent: some View {
        HStack(spacing: 8) {
            if !leftIcon.isEmpty {
                UPIcon(name: leftIcon, color: "#909399", size: "16px")
                    .upStyle(leftIconStyle)
            }

            content()
                .frame(maxWidth: .infinity, alignment: .leading)

            rightContent()

            if !rightIcon.isEmpty {
                UPIcon(name: rightIcon, color: "#909399", size: "16px")
            }
        }
    }

    @ViewBuilder
    private var labelView: some View {
        if let labelContent {
            labelContent
                .frame(maxWidth: .infinity, alignment: labelFrameAlignment)
                .upStyle(effectiveLabelStyle)
        } else if !label.isEmpty {
            HStack(spacing: 2) {
                if required {
                    Text("*")
                        .foregroundStyle(theme.error)
                }
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(theme.main)
            }
            .frame(maxWidth: .infinity, alignment: labelFrameAlignment)
            .upStyle(effectiveLabelStyle)
        }
    }

    private var tintsBorder: Bool {
        Self.shouldTintBorder(
            errorType: form?.errorType ?? UPConfig.form.errorType,
            error: form?.errors[prop] ?? ""
        )
    }
}

public extension UPFormItem {
    /// Upstream `label` named slot, replacing the built-in label rendering.
    func label<Slot: View>(@ViewBuilder _ content: () -> Slot) -> UPFormItem {
        var copy = self
        copy.labelContent = AnyView(content())
        return copy
    }

    /// Upstream `error` named slot, replacing the built-in message rendering
    /// while an error is present.
    func error<Slot: View>(@ViewBuilder _ content: () -> Slot) -> UPFormItem {
        var copy = self
        copy.errorContent = AnyView(content())
        return copy
    }
}

public extension UPFormItem {
    func onClick(_ action: @escaping () -> Void) -> UPFormItem {
        var copy = self
        copy.onClick = action
        return copy
    }
}
