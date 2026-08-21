import SwiftUI

@MainActor private final class UPMessageInputState { var value: String; var focused = false; init(_ value: String) { self.value = value } }

@MainActor
public struct UPMessageInput: View {
    public var maxlength: Int; public var mode: String; public var dotFill: Bool; public var bold: Bool
    public var disabled: Bool; public var error: Bool; public var activeColor: String; public var inactiveColor: String
    private var modelValue: Binding<String>?; private let state: UPMessageInputState
    private var onChangeHandler: ((String) -> Void)?; private var onFinishHandler: ((String) -> Void)?; private var onFocusHandler: (() -> Void)?; private var onBlurHandler: (() -> Void)?
    public var inputValue: String { state.value }

    public init(modelValue: Binding<String>? = nil, maxlength: Int = 4, mode: String = "box", dotFill: Bool = false,
                bold: Bool = false, disabled: Bool = false, error: Bool = false, activeColor: String = "#2979ff", inactiveColor: String = "#c9cacc") {
        self.modelValue = modelValue; self.maxlength = max(0, maxlength); self.mode = mode; self.dotFill = dotFill
        self.bold = bold; self.disabled = disabled; self.error = error; self.activeColor = activeColor; self.inactiveColor = inactiveColor
        self.state = UPMessageInputState(String((modelValue?.wrappedValue ?? "").prefix(max(0, maxlength))))
    }
    public var body: some View { HStack { ForEach(0..<maxlength, id: \.self) { index in Text(display(at: index)).frame(minWidth: 32, minHeight: 40).overlay(Rectangle().stroke(UPColor.parse(error ? "#fa3534" : inactiveColor))) } }.onTapGesture { focus() } }
    public func input(_ value: String) { guard !disabled else { return }; let next = String(value.prefix(maxlength)); state.value = next; modelValue?.wrappedValue = next; onChangeHandler?(next); if next.count == maxlength { onFinishHandler?(next) } }
    public func focus() { guard !disabled else { return }; state.focused = true; onFocusHandler?() }
    public func blur() { guard !disabled else { return }; state.focused = false; onBlurHandler?() }
    private func display(at index: Int) -> String { guard index < state.value.count else { return "" }; return dotFill ? "●" : String(state.value[state.value.index(state.value.startIndex, offsetBy: index)]) }
    public func onChange(_ a: @escaping (String) -> Void) -> Self { var c = self; c.onChangeHandler = a; return c }
    public func onFinish(_ a: @escaping (String) -> Void) -> Self { var c = self; c.onFinishHandler = a; return c }
    public func onFocus(_ a: @escaping () -> Void) -> Self { var c = self; c.onFocusHandler = a; return c }
    public func onBlur(_ a: @escaping () -> Void) -> Self { var c = self; c.onBlurHandler = a; return c }
}
