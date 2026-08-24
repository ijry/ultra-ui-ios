import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/switch/switch`。
struct SwitchDemoView: View {
    @State private var basic = true
    @State private var custom = false
    @State private var stringValue = "on"
    @State private var lastChange = ""

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPSwitch(modelValue: $basic)
            }

            DemoSection("自定义颜色") {
                UPSwitch(activeColor: "#5ac725", modelValue: $custom)
            }

            DemoSection("自定义尺寸") {
                HStack(spacing: 20) {
                    UPSwitch(size: 20)
                    UPSwitch(size: 30)
                    UPSwitch(size: 40)
                }
            }

            DemoSection("加载中") {
                UPSwitch(loading: true)
            }

            DemoSection("禁用") {
                UPSwitch(disabled: true)
            }

            DemoSection("自定义开关值") {
                UPSwitch(
                    modelValue: $stringValue,
                    activeValue: "on",
                    inactiveValue: "off"
                )
                Text("当前：\(stringValue)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("change 事件") {
                UPSwitch { value in
                    lastChange = value.description
                }
                Text(lastChange.isEmpty ? "尚未切换" : "最近值：\(lastChange)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
