import SwiftUI

@MainActor private final class UPCarKeyboardState { var value: String; var stage: UPCarKeyboardStage; init(_ value: String) { self.value = value; self.stage = value.isEmpty ? .province : .letter } }

@MainActor
public struct UPCarKeyboard: View {
    public static let provinces = ["京", "津", "沪", "渝", "冀", "豫", "云", "辽", "黑", "湘", "皖", "鲁", "新", "苏", "浙", "赣", "鄂", "桂", "甘", "晋", "蒙", "陕", "吉", "闽", "贵", "粤", "青", "藏", "川", "宁", "琼"]
    public static let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ0123456789").map(String.init)
    public var show: Bool; public var maxlength: Int; public var disabled: Bool
    private var modelValue: Binding<String>?; private let state: UPCarKeyboardState
    private var onChangeHandler: ((String) -> Void)?; private var onConfirmHandler: ((String) -> Void)?; private var onBackspaceHandler: ((String) -> Void)?
    public var stage: UPCarKeyboardStage { state.stage }
    public var keys: [UPKeyboardKey] { (stage == .province ? Self.provinces : Self.letters).map { UPKeyboardKey(value: $0) } }

    public init(modelValue: Binding<String>? = nil, show: Bool = false, maxlength: Int = 8, disabled: Bool = false) {
        self.modelValue = modelValue; self.show = show; self.maxlength = max(0, maxlength); self.disabled = disabled
        self.state = UPCarKeyboardState(modelValue?.wrappedValue ?? "")
    }
    public var body: some View { UPKeyboard(show: show, mode: "car", disabled: disabled, keys: keys).onInput { press($0) } }
    public func press(_ value: String) { guard !disabled, state.value.count < maxlength, keys.contains(where: { $0.value == value }) else { return }; state.value.append(contentsOf: value); state.stage = .letter; commit() }
    public func delete() { guard !disabled, !state.value.isEmpty else { return }; state.value.removeLast(); state.stage = state.value.isEmpty ? .province : .letter; modelValue?.wrappedValue = state.value; onBackspaceHandler?(state.value); onChangeHandler?(state.value) }
    public func confirm() { guard !disabled else { return }; onConfirmHandler?(state.value) }
    private func commit() { modelValue?.wrappedValue = state.value; onChangeHandler?(state.value) }
    public func onChange(_ a: @escaping (String) -> Void) -> Self { var c = self; c.onChangeHandler = a; return c }
    public func onConfirm(_ a: @escaping (String) -> Void) -> Self { var c = self; c.onConfirmHandler = a; return c }
    public func onBackspace(_ a: @escaping (String) -> Void) -> Self { var c = self; c.onBackspaceHandler = a; return c }
}
