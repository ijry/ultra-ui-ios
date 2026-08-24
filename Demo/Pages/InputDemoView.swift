import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/input/input`。
struct InputDemoView: View {
    @State private var basic = ""
    @State private var placeholderText = ""
    @State private var clearable = "可清除的内容"
    @State private var password = "123456"
    @State private var counted = ""
    @State private var formatted = ""

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPInput(modelValue: $basic)
            }

            DemoSection("占位符") {
                UPInput(text: $placeholderText, placeholder: "请输入内容")
            }

            DemoSection("边框类型") {
                UPInput(placeholder: "surround 四周边框", border: "surround")
                UPInput(placeholder: "bottom 底部边框", border: "bottom")
                UPInput(placeholder: "none 无边框", border: "none")
            }

            DemoSection("对齐方式") {
                UPInput(placeholder: "居中", inputAlign: "center")
                UPInput(placeholder: "靠右", inputAlign: "right")
            }

            DemoSection("可清除") {
                UPInput(text: $clearable, clearable: true, onlyClearableOnFocused: false)
            }

            DemoSection("禁用与只读") {
                UPInput(placeholder: "禁用状态", disabled: true)
                UPInput(placeholder: "只读状态", readonly: true)
            }

            DemoSection("前后图标") {
                UPInput(placeholder: "前置图标", prefixIcon: "search")
                UPInput(placeholder: "后置图标", suffixIcon: "arrow-right")
            }

            DemoSection("密码与可见性切换") {
                UPInput(text: $password, password: true)
            }

            DemoSection("字数统计") {
                UPInput(text: $counted, placeholder: "最多 20 字", maxlength: 20, count: true)
            }

            DemoSection("formatter 过滤") {
                UPInput(
                    text: $formatted,
                    placeholder: "只保留数字",
                    formatter: { $0.filter(\.isNumber) }
                )
            }
        }
    }
}
