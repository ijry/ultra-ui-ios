import Foundation

/// A recursive value used by `UPForm` to keep uview-plus-style string `prop` paths bindable in SwiftUI.
public enum UPFormValue: Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: UPFormValue])
    case array([UPFormValue])
    case null

    /// Stable text representation used by text-based form controls.
    public var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            guard value.isFinite else { return String(value) }
            return value.rounded() == value ? String(format: "%.0f", value) : String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .object, .array, .null:
            return ""
        }
    }

    /// Reads a nested object key or array index from a dot-separated `prop` path.
    public static func value(at prop: String, in model: UPFormModel) -> UPFormValue {
        let segments = pathSegments(from: prop)
        guard !segments.isEmpty else { return .null }
        return value(in: .object(model), segments: ArraySlice(segments))
    }

    /// Writes a nested object key or array index at a dot-separated `prop` path.
    public static func set(_ value: UPFormValue, at prop: String, in model: inout UPFormModel) {
        let segments = pathSegments(from: prop)
        guard !segments.isEmpty else { return }

        var root = UPFormValue.object(model)
        set(value, segments: ArraySlice(segments), in: &root)
        if case .object(let updatedModel) = root {
            model = updatedModel
        }
    }

    private static func pathSegments(from prop: String) -> [String] {
        prop
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ".", omittingEmptySubsequences: true)
            .map(String.init)
    }

    private static func value(in value: UPFormValue, segments: ArraySlice<String>) -> UPFormValue {
        guard let segment = segments.first else { return value }
        let remaining = segments.dropFirst()

        switch value {
        case .object(let object):
            guard let child = object[segment] else { return .null }
            return Self.value(in: child, segments: remaining)
        case .array(let array):
            guard let index = arrayIndex(from: segment), array.indices.contains(index) else { return .null }
            return Self.value(in: array[index], segments: remaining)
        case .string, .number, .bool, .null:
            return .null
        }
    }

    private static func set(_ value: UPFormValue, segments: ArraySlice<String>, in current: inout UPFormValue) {
        guard let segment = segments.first else {
            current = value
            return
        }

        let remaining = segments.dropFirst()
        switch current {
        case .object(var object):
            if remaining.isEmpty {
                object[segment] = value
            } else {
                var child = object[segment] ?? container(for: remaining.first)
                if !child.isContainer {
                    child = container(for: remaining.first)
                }
                set(value, segments: remaining, in: &child)
                object[segment] = child
            }
            current = .object(object)

        case .array(var array):
            guard let index = arrayIndex(from: segment) else {
                current = .object([:])
                set(value, segments: segments, in: &current)
                return
            }

            while array.count <= index {
                array.append(.null)
            }

            if remaining.isEmpty {
                array[index] = value
            } else {
                var child = array[index]
                if !child.isContainer {
                    child = container(for: remaining.first)
                }
                set(value, segments: remaining, in: &child)
                array[index] = child
            }
            current = .array(array)

        case .string, .number, .bool, .null:
            current = container(for: segment)
            set(value, segments: segments, in: &current)
        }
    }

    private static func arrayIndex(from segment: String) -> Int? {
        guard let value = Int(segment), value >= 0 else { return nil }
        return value
    }

    private static func container(for nextSegment: String?) -> UPFormValue {
        guard let nextSegment, arrayIndex(from: nextSegment) != nil else {
            return .object([:])
        }
        return .array([])
    }

    private var isContainer: Bool {
        if case .object = self { return true }
        if case .array = self { return true }
        return false
    }
}

public typealias UPFormModel = [String: UPFormValue]

extension UPFormValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension UPFormValue: ExpressibleByExtendedGraphemeClusterLiteral {
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }
}

extension UPFormValue: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }
}

extension UPFormValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension UPFormValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension UPFormValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension UPFormValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension UPFormValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, UPFormValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension UPFormValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: UPFormValue...) {
        self = .array(elements)
    }
}
