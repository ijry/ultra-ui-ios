import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/numberBox/numberBox`。
struct NumberBoxDemoView: View {
    @State private var basic = 1
    @State private var ranged = 3
    @State private var stepped = 1.0
    @State private var lastValue = ""

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPNumberBox(modelValue: $basic)
            }

            DemoSection("范围限制 1–5") {
                UPNumberBox(modelValue: $ranged, min: 1, max: 5)
            }

            DemoSection("步长 0.5") {
                UPNumberBox(modelValue: $stepped, step: 0.5, decimalLength: 1)
            }

            DemoSection("禁用") {
                UPNumberBox(disabled: true)
            }

            DemoSection("禁用输入框") {
                UPNumberBox(disabledInput: true)
            }

            DemoSection("隐藏按钮") {
                UPNumberBox(showMinus: false)
                UPNumberBox(showPlus: false)
            }

            DemoSection("自定义颜色与尺寸") {
                UPNumberBox(color: "#3c9cff", buttonWidth: 36, buttonSize: 36)
            }

            DemoSection("change 事件") {
                UPNumberBox(name: "qty") { detail in
                    lastValue = detail.value.description
                }
                Text(lastValue.isEmpty ? "尚未变更" : "当前值：\(lastValue)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
