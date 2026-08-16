import SwiftUI

/// Shared form state propagated by `UPForm` to form items and input controls.
@MainActor
public final class UPFormContext: ObservableObject {
    public private(set) var model: Binding<UPFormModel>
    public private(set) var rules: UPFormRules
    public let controller: UPFormController

    @Published public private(set) var errors: [String: String] = [:]
    @Published public private(set) var errorType: String

    public init(model: Binding<UPFormModel>,
                rules: UPFormRules = [:],
                controller: UPFormController,
                errorType: String = UPConfig.form.errorType) {
        self.model = model
        self.rules = rules
        self.controller = controller
        self.errorType = Self.resolvedErrorType(errorType)
    }

    /// Connects this latest context to its controller without retaining it cyclically.
    public func connectController() {
        controller.connect(to: self)
    }

    /// Updates the bindings and presentation configuration retained by a stable form context.
    public func update(model: Binding<UPFormModel>,
                       rules: UPFormRules,
                       errorType: String) {
        self.model = model
        self.rules = rules
        self.errorType = Self.resolvedErrorType(errorType)

        let retainedErrors = errors.filter { rules[$0.key] != nil }
        if retainedErrors != errors {
            errors = retainedErrors
            mirrorErrorsToController()
        }
    }

    static func resolvedErrorType(_ errorType: String) -> String {
        errorType == "none" ? "none" : "message"
    }

    /// Resolves a uview-plus-style dotted property path from the bound model.
    public func value(for prop: String) -> UPFormValue {
        UPFormValue.value(at: prop, in: model.wrappedValue)
    }

    /// Writes a form value and evaluates rules matching the supplied event trigger.
    public func set(_ value: UPFormValue, for prop: String, trigger: String = "change") {
        var updatedModel = model.wrappedValue
        UPFormValue.set(value, at: prop, in: &updatedModel)
        model.wrappedValue = updatedModel
        _ = validate(prop: prop, trigger: trigger)
    }

    /// Validates a field. Set `force` to ignore per-rule trigger filters.
    @discardableResult
    public func validate(prop: String,
                         trigger: String = "submit",
                         force: Bool = false) -> Bool {
        guard let fieldRules = rules[prop], !fieldRules.isEmpty else {
            removeError(for: prop)
            return true
        }

        let rulesToEvaluate = force
            ? fieldRules
            : fieldRules.filter { $0.trigger == trigger }
        guard !rulesToEvaluate.isEmpty else { return true }

        let currentModel = model.wrappedValue
        let currentValue = UPFormValue.value(at: prop, in: currentModel)
        for rule in rulesToEvaluate {
            if let error = rule.errorMessage(for: currentValue, model: currentModel) {
                setError(error, for: prop)
                return false
            }
        }

        removeError(for: prop)
        return true
    }

    /// Clears all field errors or a caller-specified subset.
    public func clearValidate(_ props: [String]? = nil) {
        if let props {
            for prop in props {
                errors.removeValue(forKey: prop)
            }
        } else {
            errors.removeAll()
        }
        mirrorErrorsToController()
    }

    func validateAll() -> Bool {
        var isValid = true
        for prop in rules.keys.sorted() {
            if !validate(prop: prop, force: true) {
                isValid = false
            }
        }
        return isValid
    }

    private func setError(_ error: String, for prop: String) {
        errors[prop] = error
        mirrorErrorsToController()
    }

    private func removeError(for prop: String) {
        errors.removeValue(forKey: prop)
        mirrorErrorsToController()
    }

    private func mirrorErrorsToController() {
        controller.receive(errors: errors)
    }
}
