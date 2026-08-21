import SwiftUI

@MainActor private final class UPKeyboardTextState { var value: String; init(_ value: String) { self.value = value } }

@MainActor
public struct UPNumberKeyboard: View {
    public var show: Bool; public var title: String; public var mode: String; public var dotDisabled: Bool
    public var random: Bool; public var maxlength: Int; public var disabled: Bool; public var keys: [UPKeyboardKey]
    private var modelValue: Binding<String>?; private let state: UPKeyboardTextState
    private var onChangeHandler: ((String) -> Void)?; private var onConfirmHandler: ((String) -> Void)?; private var onCancelHandler: (() -> Void)?; private var onBackspaceHandler: ((String) -> Void)?

    public init(modelValue: Binding<String>? = nil, show: Bool = false, title: String = "", mode: String = "number",
                dotDisabled: Bool = false, random: Bool = false, maxlength: Int = .max, disabled: Bool = false,
                randomSource: () -> [String] = { ["1", "2", "3", "4", "5", "6", "7", "8", "9"] }) {
        self.modelValue = modelValue; self.show = show; self.title = title; self.mode = mode; self.dotDisabled = dotDisabled
        self.random = random; self.maxlength = max(0, maxlength); self.disabled = disabled
        let values = random ? randomSource() : ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
        self.keys = values.prefix(9).map { UPKeyboardKey(value: $0) }
        self.state = UPKeyboardTextState(modelValue?.wrappedValue ?? "")
    }
    public var body: some View { UPKeyboard(show: show, mode: mode, disabled: disabled, keys: keys).onInput { press($0) } }
    public func press(_ value: String) { guard !disabled, state.value.count < maxlength, value != "." || !dotDisabled else { return }; state.value.append(contentsOf: value); commit() }
    public func delete() { guard !disabled, !state.value.isEmpty else { return }; state.value.removeLast(); modelValue?.wrappedValue = state.value; onBackspaceHandler?(state.value); onChangeHandler?(state.value) }
    public func confirm() { guard !disabled else { return }; onConfirmHandler?(state.value) }
    public func cancel() { guard !disabled else { return }; onCancelHandler?() }
    private func commit() { modelValue?.wrappedValue = state.value; onChangeHandler?(state.value) }
    public func onChange(_ a: @escaping (String) -> Void) -> Self { var c = self; c.onChangeHandler = a; return c }
    public func onConfirm(_ a: @escaping (String) -> Void) -> Self { var c = self; c.onConfirmHandler = a; return c }
    public func onCancel(_ a: @escaping () -> Void) -> Self { var c = self; c.onCancelHandler = a; return c }
    public func onBackspace(_ a: @escaping (String) -> Void) -> Self { var c = self; c.onBackspaceHandler = a; return c }
}
