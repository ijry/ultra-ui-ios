import Foundation
import SwiftUI

/// Shared state supplied by `UPForm` to form fields and controllers.
@MainActor
public final class UPFormContext: ObservableObject {
    public private(set) var model: Binding<UPFormModel>
    public private(set) var rules: UPFormRules
    public let controller: UPFormController

    @Published public private(set) var errors: [String: String] = [:]
    @Published public private(set) var errorType: String
    @Published public private(set) var borderBottom: Bool
    @Published public private(set) var labelPosition: String
    @Published public private(set) var labelWidth: String
    @Published public private(set) var labelAlign: String
    @Published public private(set) var labelStyle: UPStyle

    private struct ItemRuleRegistration {
        var prop: String
        var rules: [UPFormRule]
    }

    private var itemRuleRegistrations: [UUID: ItemRuleRegistration] = [:]
    private var itemRuleRegistrationOrder: [UUID] = []

    /// Snapshot of the model taken when the form was created, corresponding to
    /// upstream's `originalModel`. `resetFields` and `resetField` restore from it.
    private var originalModel: UPFormModel

    public init(model: Binding<UPFormModel>,
                rules: UPFormRules = [:],
                controller: UPFormController,
                errorType: String = UPConfig.form.errorType,
                borderBottom: Bool = UPConfig.form.borderBottom,
                labelPosition: String = UPConfig.form.labelPosition,
                labelWidth: String = UPConfig.form.labelWidth,
                labelAlign: String = UPConfig.form.labelAlign,
                labelStyle: UPStyle = UPConfig.form.labelStyle) {
        self.model = model
        self.rules = rules
        self.controller = controller
        self.originalModel = model.wrappedValue
        self.errorType = Self.resolvedErrorType(errorType)
        self.borderBottom = borderBottom
        self.labelPosition = Self.resolvedLabelPosition(labelPosition)
        self.labelWidth = labelWidth
        self.labelAlign = Self.resolvedLabelAlign(labelAlign)
        self.labelStyle = labelStyle
    }

    /// Connects this latest context to its controller without retaining it cyclically.
    public func connectController() {
        controller.connect(to: self)
    }

    /// Registers a mounted `UPFormItem`'s local rules. Nonempty local rules take
    /// precedence over the form-level rules for the same property, matching uview-plus.
    func registerItemRules(_ rules: [UPFormRule], for prop: String, registrationID: UUID) {
        guard !prop.isEmpty else {
            unregisterItemRules(registrationID: registrationID)
            return
        }

        if itemRuleRegistrations[registrationID] == nil {
            itemRuleRegistrationOrder.append(registrationID)
        }
        itemRuleRegistrations[registrationID] = ItemRuleRegistration(prop: prop, rules: rules)
        reconcileErrorsForCurrentRules()
    }

    /// Removes the local rules registered by a disappearing `UPFormItem`.
    func unregisterItemRules(registrationID: UUID) {
        guard itemRuleRegistrations.removeValue(forKey: registrationID) != nil else { return }
        itemRuleRegistrationOrder.removeAll { $0 == registrationID }
        reconcileErrorsForCurrentRules()
    }

    /// Updates the bindings and validation configuration retained by a stable form context.
    public func update(model: Binding<UPFormModel>,
                       rules: UPFormRules,
                       errorType: String) {
        update(
            model: model,
            rules: rules,
            errorType: errorType,
            borderBottom: borderBottom,
            labelPosition: labelPosition,
            labelWidth: labelWidth,
            labelAlign: labelAlign,
            labelStyle: labelStyle
        )
    }

    /// Updates both the validation values and uview-plus inherited form-item presentation props.
    public func update(model: Binding<UPFormModel>,
                       rules: UPFormRules,
                       errorType: String,
                       borderBottom: Bool,
                       labelPosition: String,
                       labelWidth: String,
                       labelAlign: String,
                       labelStyle: UPStyle) {
        self.model = model
        self.rules = rules
        self.errorType = Self.resolvedErrorType(errorType)
        self.borderBottom = borderBottom
        self.labelPosition = Self.resolvedLabelPosition(labelPosition)
        self.labelWidth = labelWidth
        self.labelAlign = Self.resolvedLabelAlign(labelAlign)
        self.labelStyle = labelStyle

        reconcileErrorsForCurrentRules()
    }

    static func resolvedErrorType(_ errorType: String) -> String {
        switch errorType {
        case "none", "toast", "border-bottom": return errorType
        default: return "message"
        }
    }

    static func resolvedLabelPosition(_ labelPosition: String) -> String {
        labelPosition == "top" ? "top" : "left"
    }

    static func resolvedLabelAlign(_ labelAlign: String) -> String {
        switch labelAlign {
        case "center", "right": return labelAlign
        default: return "left"
        }
    }

    /// The message upstream passes to `toast()` when `errorType` is `toast`.
    /// Upstream reports the first error; properties are sorted so the choice is
    /// deterministic across dictionary orderings.
    public static func toastMessage(errorType: String, errors: [String: String]) -> String? {
        guard resolvedErrorType(errorType) == "toast" else { return nil }
        guard let prop = errors.keys.sorted().first else { return nil }
        return errors[prop]
    }

    /// The first error to surface through the toast centre, or nil when the
    /// form is valid or not in `toast` mode.
    public var toastMessage: String? {
        Self.toastMessage(errorType: errorType, errors: errors)
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

    /// Validates a field. Set `force` to ignore per-rule trigger filters, and
    /// `showErrorMsg` to false to report validity without recording a message
    /// (upstream `validate({showErrorMsg: false})`).
    @discardableResult
    public func validate(prop: String,
                         trigger: String = "submit",
                         force: Bool = false,
                         showErrorMsg: Bool = true) -> Bool {
        let fieldRules = effectiveRules(for: prop)
        guard !fieldRules.isEmpty else {
            if showErrorMsg { removeError(for: prop) }
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
                if showErrorMsg { setError(error, for: prop) }
                return false
            }
        }

        if showErrorMsg { removeError(for: prop) }
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

    /// Replaces the form-level rules. Mirrors upstream `setRules`, which exists
    /// because小程序 cannot pass functions through props.
    public func setRules(_ rules: UPFormRules) {
        self.rules = rules
        reconcileErrorsForCurrentRules()
    }

    /// Restores every property present in the original snapshot and clears the
    /// validation messages, matching upstream `resetFields`.
    public func resetFields() {
        model.wrappedValue = originalModel
        clearValidate()
    }

    /// Restores a single property from the original snapshot and clears its
    /// error, matching upstream `resetField`.
    public func resetField(_ prop: String) {
        guard !prop.isEmpty else { return }
        var updatedModel = model.wrappedValue
        UPFormValue.set(
            UPFormValue.value(at: prop, in: originalModel),
            at: prop,
            in: &updatedModel
        )
        model.wrappedValue = updatedModel
        removeError(for: prop)
    }

    func validateAll(showErrorMsg: Bool = true) -> Bool {
        var isValid = true
        for prop in activeRuleProperties.sorted() {
            if !validate(prop: prop, force: true, showErrorMsg: showErrorMsg) {
                isValid = false
            }
        }
        return isValid
    }

    private var activeRuleProperties: Set<String> {
        let formRuleProperties = rules.compactMap { prop, fieldRules in
            fieldRules.isEmpty ? nil : prop
        }
        let itemRuleProperties = itemRuleRegistrations.values.compactMap { registration in
            registration.rules.isEmpty ? nil : registration.prop
        }
        return Set(formRuleProperties).union(itemRuleProperties)
    }

    private func effectiveRules(for prop: String) -> [UPFormRule] {
        for registrationID in itemRuleRegistrationOrder.reversed() {
            guard let registration = itemRuleRegistrations[registrationID],
                  registration.prop == prop,
                  !registration.rules.isEmpty else {
                continue
            }
            return registration.rules
        }
        return rules[prop] ?? []
    }

    private func reconcileErrorsForCurrentRules() {
        let retainedErrors = errors.filter { activeRuleProperties.contains($0.key) }
        if retainedErrors != errors {
            errors = retainedErrors
            mirrorErrorsToController()
        }
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

private struct UPFormContextEnvironmentKey: EnvironmentKey {
    static let defaultValue: UPFormContext? = nil
}

extension EnvironmentValues {
    var upFormContext: UPFormContext? {
        get { self[UPFormContextEnvironmentKey.self] }
        set { self[UPFormContextEnvironmentKey.self] = newValue }
    }
}
