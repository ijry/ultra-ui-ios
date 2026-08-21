import Foundation

public struct UPKeyboardKey: Identifiable, Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable { case input, delete, confirm, cancel, spacer }
    public let id: String
    public var value: String
    public var label: String
    public var kind: Kind
    public var disabled: Bool

    public init(id: String? = nil, value: String, label: String? = nil, kind: Kind = .input, disabled: Bool = false) {
        self.id = id ?? "\(kind.rawValue):\(value)"
        self.value = value
        self.label = label ?? value
        self.kind = kind
        self.disabled = disabled
    }
}

public enum UPCarKeyboardStage: String, Equatable, Sendable { case province, letter }
