import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/codeInput/codeInput`。
@MainActor
struct CodeInputDemoView: View {
    @State private var value1 = ""
    @State private var value2 = ""
    @State private var value3 = ""
    @State private var value4 = ""
    @State private var value5 = ""
    @State private var value6 = ""
    @State private var value7 = ""
    @State private var value8 = ""
    @State private var value9 = "123"
    @State private var value10 = "34"
    @State private var eventLog = "尚未输入"

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                UPCodeInput(modelValue: $value1, maxlength: 4)
                    .onChange { value in eventLog = "change：\(value)" }
                    .onFinish { value in eventLog = "finish：\(value)" }

                tip("最近事件：\(eventLog)")
            }

            DemoSection("横线模式") {
                UPCodeInput(modelValue: $value2, maxlength: 4, mode: "line", bold: true)
            }

            DemoSection("设置长度") {
                UPCodeInput(modelValue: $value3, maxlength: 6)

                tip("maxlength 6，输入满 6 位才触发 finish。")
            }

            DemoSection("设置间距") {
                UPCodeInput(modelValue: $value4, maxlength: 4, mode: "box", space: 0)

                tip("box 模式下 space 为 0 时渲染成连体格子。")
            }

            DemoSection("细边框") {
                UPCodeInput(modelValue: $value5, maxlength: 4, mode: "box", hairline: true, space: 0)

                UPCodeInput(modelValue: $value6, maxlength: 4, mode: "line", hairline: true, space: 10)
            }

            DemoSection("调整颜色") {
                UPCodeInput(
                    modelValue: $value7, maxlength: 4, mode: "box", hairline: true, space: 0,
                    color: "#f56c6c", borderColor: "#f56c6c"
                )

                UPCodeInput(
                    modelValue: $value10, maxlength: 4, mode: "line", hairline: true,
                    color: "#3c9cff", size: 30, borderColor: "#3c9cff"
                )
            }

            DemoSection("点模式") {
                UPCodeInput(modelValue: $value8, maxlength: 4, dot: true, mode: "box", hairline: true, space: 0)

                tip("dot 为 true 时用圆点代替字符，适合密码场景。")
            }

            DemoSection("预置内容") {
                UPCodeInput(
                    modelValue: $value9, maxlength: 4, mode: "box", hairline: true, space: 0,
                    fontSize: 17
                )

                tip("初值 \"123\"，还差 1 位补满。")
            }

            DemoSection("当前原生范围") {
                Text("modelValue / maxlength / mode / dot / space / hairline / bold / color / borderColor / fontSize / size / disabledDot / disabledKeyboard / focus 与 change、finish 事件都已对齐，mode 只区分 line 与 box。组件在格子上叠了一个透明 TextField 来接系统数字键盘，所以点击任意格子都会聚焦整个输入框，不像上游那样逐格定位光标；上游的 adjustPosition（键盘弹起时页面上推）由 SwiftUI 自己处理，属性保留但不生效。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
