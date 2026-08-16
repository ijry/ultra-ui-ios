import Foundation

/// A synchronous validation rule compatible with uview-plus-style form rules.
public struct UPFormRule {
    public var required: Bool
    public var min: Int?
    public var max: Int?
    public var length: Int?
    public var pattern: String?
    public var message: String
    public var trigger: String
    public var validator: ((UPFormValue, UPFormModel) -> String?)?

    public init(required: Bool = false,
                min: Int? = nil,
                max: Int? = nil,
                length: Int? = nil,
                pattern: String? = nil,
                message: String = "",
                trigger: String = "submit",
                validator: ((UPFormValue, UPFormModel) -> String?)? = nil) {
        self.required = required
        self.min = min
        self.max = max
        self.length = length
        self.pattern = pattern
        self.message = message
        self.trigger = trigger
        self.validator = validator
    }

    func errorMessage(for value: UPFormValue, model: UPFormModel) -> String? {
        if required, value.isMissingFormValue {
            return message
        }

        if let count = value.validationLength {
            if let min, count < min {
                return message
            }
            if let max, count > max {
                return message
            }
            if let length, count != length {
                return message
            }
        }

        if let pattern, case .string(let text) = value {
            do {
                let expression = try NSRegularExpression(pattern: pattern)
                let range = NSRange(text.startIndex..., in: text)
                guard expression.firstMatch(in: text, range: range) != nil else {
                    return message
                }
            } catch {
                return message
            }
        }

        if let customError = validator?(value, model), !customError.isEmpty {
            return customError
        }

        return nil
    }
}

public typealias UPFormRules = [String: [UPFormRule]]

private extension UPFormValue {
    var isMissingFormValue: Bool {
        switch self {
        case .string(let value):
            return value.isEmpty
        case .array(let values):
            return values.isEmpty
        case .object(let values):
            return values.isEmpty
        case .null:
            return true
        case .number, .bool:
            return false
        }
    }

    var validationLength: Int? {
        switch self {
        case .string(let value):
            return value.count
        case .array(let values):
            return values.count
        case .number, .bool, .object, .null:
            return nil
        }
    }
}
