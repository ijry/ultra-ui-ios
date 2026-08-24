import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/code/code`。
///
/// 上游 `u-code` 本身只负责倒计时文案，按钮与输入框由页面自己组合，
/// 这里保持同样的分工：`UPCodeController` 提供状态，页面决定怎么展示。
struct CodeDemoView: View {
    @StateObject private var controller = UPCodeController(seconds: 10)
    @StateObject private var keepRunning = UPCodeController(seconds: 60)
    @State private var codeInput = ""

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPCode(seconds: 10, controller: controller)
                UPButton(
                    type: "primary",
                    disabled: controller.isRunning,
                    text: controller.isRunning ? controller.displayText : "获取验证码"
                ) {
                    controller.start()
                }
            }

            DemoSection("配合输入框") {
                HStack(spacing: 12) {
                    UPInput(text: $codeInput, placeholder: "请输入验证码", maxlength: 6)
                    UPButton(
                        type: "primary",
                        size: "small",
                        disabled: keepRunning.isRunning,
                        text: keepRunning.isRunning ? keepRunning.displayText : "发送"
                    ) {
                        keepRunning.start()
                    }
                }
            }

            DemoSection("控制器状态") {
                Text("剩余秒数：\(controller.secondsRemaining)")
                Text("是否运行中：\(controller.isRunning ? "是" : "否")")
                Text("当前文案：\(controller.displayText)")
                UPButton(text: "重置") { controller.reset() }
            }
            .font(.system(size: 13))
        }
    }
}
