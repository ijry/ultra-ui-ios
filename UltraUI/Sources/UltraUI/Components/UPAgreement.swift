import Observation
import SwiftUI

/// 上游 `data.show` 与本仓既有的勾选态；值类型 View 无法直接持有可变状态。
@MainActor
@Observable
private final class UPAgreementState {
    var checked: Bool
    var show = false

    init(checked: Bool) {
        self.checked = checked
    }
}

/// Native SwiftUI counterpart of uview-plus `u-agreement`.
///
/// 上游是一个「首次启动必须同意」的隐私弹窗：`up-modal` 里放一段带两个链接的
/// 声明，`confirm` 关窗并抛 `confirm(1)`，`cancel` 直接退出应用
/// （H5 `window.close()`、APP `plus.runtime.quit()`）。
/// 原生保留这套弹窗语义，同时保留仓库既有的「协议勾选行」形态：
/// 不调 `showModal()` 时它就是一行可勾选的文案。
///
/// 「退出应用」在 iOS 上没有合规的公开 API（`exit(0)` 会被审核拒绝），
/// 因此 `cancel` 只关窗并回调 `onCancel`，由宿主决定后续动作。
@MainActor
public struct UPAgreement: View {
    public var urlProtocol: String
    public var urlPrivacy: String
    /// 上游 `up-modal` 的 `confirmText="阅读并同意"`。
    public var confirmText: String
    /// 上游模板里那段默认声明文案。
    public static let defaultDeclaration = """
    我们非常重视您的个人信息和隐私保护。为了更好地保障您的个人权益，在您使用我们的产品前，\
    请务必审慎阅读《用户协议》和《隐私政策》内的所有条款，尤其是:1.我们对您的个人信息的\
    收集/保存/使用/对外提供/保护等规则条款，以及您的用户权利等条款;2. 约定我们的限制责任、\
    免责条款;3.其他以颜色或加粗进行标识的重要条款。如您对以上协议有任何疑问，请先不要同意，\
    您点击“同意并继续”的行为即表示您已阅读完毕并同意以上协议的全部内容。
    """

    /// 勾选行的文案（原生扩展，上游没有这一形态）。
    public var displayText: String
    public var disabled: Bool
    public var checked: Bool { checkedBinding?.wrappedValue ?? state.checked }
    /// 对应上游 `data.show`。
    public var show: Bool { state.show }

    private var checkedBinding: Binding<Bool>?
    @State private var state: UPAgreementState
    private var onChangeHandler: ((Bool) -> Void)?
    private var onConfirmHandler: ((Int) -> Void)?
    private var onCancelHandler: (() -> Void)?
    private var onURLTapHandler: ((String) -> Void)?
    private var declarationSlot: AnyView?
    @Environment(\.upTheme) private var theme
    @Environment(\.openURL) private var openURL

    public init(checked: Bool = false,
                text: String = "我已阅读并同意",
                disabled: Bool = false,
                urlProtocol: String = UPConfig.agreement.urlProtocol,
                urlPrivacy: String = UPConfig.agreement.urlPrivacy,
                confirmText: String = "阅读并同意") {
        self.checkedBinding = nil
        self._state = State(initialValue: UPAgreementState(checked: checked))
        self.displayText = text
        self.disabled = disabled
        self.urlProtocol = urlProtocol
        self.urlPrivacy = urlPrivacy
        self.confirmText = confirmText
    }

    public init(checked: Binding<Bool>,
                text: String = "我已阅读并同意",
                disabled: Bool = false,
                urlProtocol: String = UPConfig.agreement.urlProtocol,
                urlPrivacy: String = UPConfig.agreement.urlPrivacy,
                confirmText: String = "阅读并同意") {
        self.init(checked: checked.wrappedValue,
                  text: text,
                  disabled: disabled,
                  urlProtocol: urlProtocol,
                  urlPrivacy: urlPrivacy,
                  confirmText: confirmText)
        self.checkedBinding = checked
    }

    // MARK: - 上游方法

    /// 对应上游 `showModal()`。
    public func showModal() { state.show = true }

    /// 对应上游 `confirm()`：关窗、抛 `confirm(1)`，顺带把勾选态置为真。
    public func confirm() {
        state.show = false
        if !checked {
            state.checked = true
            checkedBinding?.wrappedValue = true
            onChangeHandler?(true)
        }
        onConfirmHandler?(1)
    }

    /// 对应上游 `close()`：上游在这里退出应用，iOS 无合规 API，只关窗并回调。
    public func cancel() {
        state.show = false
        onCancelHandler?()
    }

    /// 对应上游 `urlClick(type)`：`type` 是 `urlProtocol` / `urlPrivacy`。
    public func openAgreement(_ type: String) {
        let target = type == "urlPrivacy" ? urlPrivacy : urlProtocol
        guard !target.isEmpty else { return }
        onURLTapHandler?(target)
        // 上游走 `uni.navigateTo` 的应用内路由；原生没有路由表，能识别的 URL 交给系统。
        if let url = URL(string: target), url.scheme != nil { openURL(url) }
    }

    /// 仓库既有 API。
    public func toggle() {
        guard !disabled else { return }
        let value = !checked
        state.checked = value
        checkedBinding?.wrappedValue = value
        onChangeHandler?(value)
    }

    // MARK: - 事件

    public func onChange(_ action: @escaping (Bool) -> Void) -> UPAgreement {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    /// 对应上游 `confirm` 事件，负载固定是 `1`。
    public func onConfirm(_ action: @escaping (Int) -> Void) -> UPAgreement {
        var copy = self
        copy.onConfirmHandler = action
        return copy
    }

    /// 上游取消即退出应用，没有事件；原生把它暴露给宿主。
    public func onCancel(_ action: @escaping () -> Void) -> UPAgreement {
        var copy = self
        copy.onCancelHandler = action
        return copy
    }

    /// 点击声明里的《用户协议》/《隐私政策》时触发，负载是对应地址。
    public func onURLTap(_ action: @escaping (String) -> Void) -> UPAgreement {
        var copy = self
        copy.onURLTapHandler = action
        return copy
    }

    /// 等价于上游默认插槽是否存在。
    public var hasDeclarationSlot: Bool { declarationSlot != nil }

    /// 对应上游默认插槽：替换整段声明文案。
    public func declaration<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPAgreement {
        var copy = self
        copy.declarationSlot = AnyView(builder())
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        checkboxRow
            .overlay { modal }
    }

    /// 仓库既有形态：一行可勾选的协议文案。
    private var checkboxRow: some View {
        Button {
            toggle()
        } label: {
            Label(displayText, systemImage: checked ? "checkmark.circle.fill" : "circle")
        }
        .disabled(disabled)
    }

    @ViewBuilder
    private var modal: some View {
        UPModal(show: Binding(get: { state.show }, set: { state.show = $0 }),
                confirmText: confirmText,
                showCancelButton: true,
                onConfirm: { confirm() },
                onCancel: { cancel() }) {
            declarationView
        }
    }

    /// 上游把两个书名号内的文字做成可点击链接。
    @ViewBuilder
    private var declarationView: some View {
        if let declarationSlot {
            declarationSlot
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(Self.defaultDeclaration)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.main)

                HStack(spacing: 12) {
                    linkButton("《用户协议》", type: "urlProtocol")
                    linkButton("《隐私政策》", type: "urlPrivacy")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func linkButton(_ title: String, type: String) -> some View {
        Text(title)
            .font(.system(size: 14))
            .foregroundStyle(theme.primary)
            .contentShape(Rectangle())
            .onTapGesture { openAgreement(type) }
    }
}
