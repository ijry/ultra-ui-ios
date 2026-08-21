import SwiftUI

@MainActor
private final class UPAgreementState { var checked: Bool; init(checked: Bool) { self.checked = checked } }

/// Agreement checkbox row corresponding to uview-plus `u-agreement`.
@MainActor
public struct UPAgreement: View {
    public var checked: Bool { checkedBinding?.wrappedValue ?? state.checked }
    public var displayText: String
    public var disabled: Bool
    private var checkedBinding: Binding<Bool>?
    private let state: UPAgreementState
    private var onChangeHandler: ((Bool) -> Void)?

    public init(checked: Bool = false, text: String = "我已阅读并同意", disabled: Bool = false) {
        self.checkedBinding = nil; self.state = UPAgreementState(checked: checked); self.displayText = text; self.disabled = disabled
    }
    public init(checked: Binding<Bool>, text: String = "我已阅读并同意", disabled: Bool = false) {
        self.checkedBinding = checked; self.state = UPAgreementState(checked: checked.wrappedValue); self.displayText = text; self.disabled = disabled
    }
    public var body: some View { Button { toggle() } label: { Label(displayText, systemImage: checked ? "checkmark.circle.fill" : "circle") }.disabled(disabled) }
    public func toggle() { guard !disabled else { return }; let value = !checked; state.checked = value; checkedBinding?.wrappedValue = value; onChangeHandler?(value) }
    public func onChange(_ action: @escaping (Bool) -> Void) -> Self { var copy = self; copy.onChangeHandler = action; return copy }
}
