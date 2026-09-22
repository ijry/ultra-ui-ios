import SwiftUI
import UltraUI

/// 对应上游 `u-agreement`（上游示例仓库没有这一页，按组件文档搭）。
@MainActor
struct AgreementDemoView: View {
    @State private var accepted = false
    @State private var notificationAccepted = true
    @State private var disabledAccepted = true
    @State private var changeText = "尚未操作"
    @State private var modalLog = "尚未触发"
    @State private var gate = UPAgreement(text: "首次启动的隐私弹窗")
    @State private var tick = 0

    var body: some View {
        DemoPage {
            DemoSection("隐私弹窗（上游主形态）") {
                gate
                    .id(tick)

                HStack(spacing: 12) {
                    UPButton(type: "primary", size: "small", text: "弹出协议") {
                        gate.showModal()
                        tick += 1
                    }
                }

                Text(modalLog)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("上游 confirm 抛 confirm(1) 并关窗，cancel 直接退出应用；iOS 没有合规的退出 API，原生改为关窗并回调 onCancel。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("基础用法") {
                UPAgreement(
                    checked: $accepted,
                    text: "我已阅读并同意《用户协议》和《隐私政策》"
                )
                .onChange { value in
                    changeText = value ? "已同意协议" : "已取消同意"
                }

                Text("当前状态：\(accepted ? "已勾选" : "未勾选")")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("事件：\(changeText)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("自定义文案") {
                UPAgreement(
                    checked: $notificationAccepted,
                    text: "同意接收产品更新与服务通知"
                )

                Text("协议文本可以按业务场景自由组合")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("禁用状态") {
                UPAgreement(
                    checked: $disabledAccepted,
                    text: "已勾选但不可修改",
                    disabled: true
                )

                UPAgreement(
                    checked: .constant(false),
                    text: "未勾选且不可修改",
                    disabled: true
                )
            }

            DemoSection("当前原生范围") {
                Text("原生 UPAgreement 已覆盖上游 2 个 prop（urlProtocol / urlPrivacy）与 confirm 事件，方法 showModal() / confirm() / cancel() / openAgreement(_:)，并提供替换整段声明的 declaration 插槽。上游取消分支执行 window.close() 或 plus.runtime.quit()，iOS 上 exit(0) 会被审核拒绝，因此只关窗并抛 onCancel 由宿主处置；两个地址上游走 uni.navigateTo 的应用内路由，原生只把能识别成 URL 的交给系统打开，并同时抛 onURLTap 供宿主自己导航。仓库既有的「协议勾选行」形态（checked / text / disabled + onChange + toggle()）保留，不调 showModal() 时组件就是这一行。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: bindEvents)
    }

    private func bindEvents() {
        gate = gate
            .onConfirm { value in modalLog = "confirm：\(value)" }
            .onCancel { modalLog = "cancel：宿主决定后续动作" }
            .onURLTap { url in modalLog = "urltap：\(url)" }
    }
}
