import SwiftUI

/// A uview-plus-style form container that provides model bindings and validation state to its content.
@MainActor
public struct UPForm<Content: View>: View {
    var model: Binding<UPFormModel>
    var rules: UPFormRules
    var controller: UPFormController?
    var errorType: String
    var borderBottom: Bool
    var labelPosition: String
    var labelWidth: String
    var labelAlign: String
    var labelStyle: UPStyle
    @ViewBuilder var content: () -> Content

    @StateObject private var context: UPFormContext

    public init(model: Binding<UPFormModel>,
                rules: UPFormRules = [:],
                controller: UPFormController? = nil,
                errorType: String = UPConfig.form.errorType,
                borderBottom: Bool = UPConfig.form.borderBottom,
                labelPosition: String = UPConfig.form.labelPosition,
                labelWidth: String = UPConfig.form.labelWidth,
                labelAlign: String = UPConfig.form.labelAlign,
                labelStyle: UPStyle = UPConfig.form.labelStyle,
                @ViewBuilder content: @escaping () -> Content) {
        self.model = model
        self.rules = rules
        self.controller = controller
        self.errorType = Self.resolvedErrorType(errorType)
        self.borderBottom = borderBottom
        self.labelPosition = Self.resolvedLabelPosition(labelPosition)
        self.labelWidth = labelWidth
        self.labelAlign = Self.resolvedLabelAlign(labelAlign)
        self.labelStyle = labelStyle
        self.content = content

        let activeController = controller ?? UPFormController()
        _context = StateObject(
            wrappedValue: UPFormContext(
                model: model,
                rules: rules,
                controller: activeController,
                errorType: errorType,
                borderBottom: borderBottom,
                labelPosition: labelPosition,
                labelWidth: labelWidth,
                labelAlign: labelAlign,
                labelStyle: labelStyle
            )
        )
    }

    public var body: some View {
        content()
            .environmentObject(context)
            .environment(\.upFormContext, context)
            .onAppear(perform: synchronizeContext)
            .onChange(of: model.wrappedValue) { _, _ in synchronizeContext() }
            .onChange(of: errorType) { _, _ in synchronizeContext() }
            .onChange(of: ruleSignature) { _, _ in synchronizeContext() }
            .onChange(of: presentationSignature) { _, _ in synchronizeContext() }
    }

    static func resolvedErrorType(_ errorType: String) -> String {
        UPFormContext.resolvedErrorType(errorType)
    }

    static func resolvedLabelPosition(_ labelPosition: String) -> String {
        UPFormContext.resolvedLabelPosition(labelPosition)
    }

    static func resolvedLabelAlign(_ labelAlign: String) -> String {
        UPFormContext.resolvedLabelAlign(labelAlign)
    }

    private var ruleSignature: String {
        rules.keys.sorted().map { prop in
            let fieldRules = rules[prop, default: []]
            let ruleValues = fieldRules.map { rule in
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
            return "\(prop)\u{1D}\(ruleValues)"
        }.joined(separator: "\u{1C}")
    }

    private var presentationSignature: String {
        let style = labelStyle.properties
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "\u{1F}")
        return [
            borderBottom ? "1" : "0",
            labelPosition,
            labelWidth,
            labelAlign,
            style
        ].joined(separator: "\u{1E}")
    }

    private func synchronizeContext() {
        context.update(
            model: model,
            rules: rules,
            errorType: errorType,
            borderBottom: borderBottom,
            labelPosition: labelPosition,
            labelWidth: labelWidth,
            labelAlign: labelAlign,
            labelStyle: labelStyle
        )
        context.connectController()
    }
}
