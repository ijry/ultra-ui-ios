import SwiftUI

/// Imperative access to the validation state of a `UPForm`.
@MainActor
public final class UPFormController: ObservableObject {
    @Published public private(set) var errors: [String: String] = [:]

    private weak var context: UPFormContext?

    public init() {}

    /// Validates every field with rules, ignoring per-rule triggers.
    @discardableResult
    public func validate() -> Bool {
        guard let context else { return errors.isEmpty }
        return context.validateAll()
    }

    /// Validates one field, ignoring per-rule triggers.
    @discardableResult
    public func validateField(_ prop: String) -> Bool {
        guard let context else { return errors[prop] == nil }
        return context.validate(prop: prop, trigger: "submit", force: true)
    }

    /// Clears all errors or only the named field errors.
    public func clearValidate(_ props: [String]? = nil) {
        guard let context else {
            if let props {
                for prop in props {
                    errors.removeValue(forKey: prop)
                }
            } else {
                errors.removeAll()
            }
            return
        }
        context.clearValidate(props)
    }

    func connect(to context: UPFormContext) {
        self.context = context
        errors = context.errors
    }

    func receive(errors: [String: String]) {
        self.errors = errors
    }
}
