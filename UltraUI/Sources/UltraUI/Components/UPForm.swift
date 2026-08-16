import SwiftUI

/// A uview-plus-style form container that provides model bindings and validation state to its content.
@MainActor
public struct UPForm<Content: View>: View {
    var model: Binding<UPFormModel>
    var rules: UPFormRules
    var controller: UPFormController?
    var errorType: String
    @ViewBuilder var content: () -> Content

    @StateObject private var context: UPFormContext

    public init(model: Binding<UPFormModel>,
                rules: UPFormRules = [:],
                controller: UPFormController? = nil,
                errorType: String = UPConfig.form.errorType,
                @ViewBuilder content: @escaping () -> Content) {
        self.model = model
        self.rules = rules
        self.controller = controller
        self.errorType = Self.resolvedErrorType(errorType)
        self.content = content

        let activeController = controller ?? UPFormController()
        _context = StateObject(
            wrappedValue: UPFormContext(
                model: model,
                rules: rules,
                controller: activeController,
                errorType: errorType
            )
        )
    }

    public var body: some View {
        content()
            .environmentObject(context)
            .environment(\.upFormContext, context)
            .onAppear {
                synchronizeContext()
            }
            .onChange(of: model.wrappedValue) { _, _ in
                synchronizeContext()
            }
            .onChange(of: errorType) { _, _ in
                synchronizeContext()
            }
            .onChange(of: ruleSignature) { _, _ in
                synchronizeContext()
            }
    }

    static func resolvedErrorType(_ errorType: String) -> String {
        UPFormContext.resolvedErrorType(errorType)
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

    private func synchronizeContext() {
        context.update(model: model, rules: rules, errorType: errorType)
        context.connectController()
    }
}
