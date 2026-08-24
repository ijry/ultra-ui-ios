import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/checkbox/checkbox`。
struct CheckboxDemoView: View {
    @State private var interests: [UPCheckboxName] = ["swift"]
    @State private var shaped: [UPCheckboxName] = []

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPCheckboxGroup(modelValue: $interests) {
                    UPCheckbox(name: "swift", label: "Swift")
                    UPCheckbox(name: "kotlin", label: "Kotlin")
                    UPCheckbox(name: "dart", label: "Dart")
                }
                Text("已选：\(interests.map(\.description).joined(separator: "、"))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("横向排列") {
                UPCheckboxGroup(placement: "row") {
                    UPCheckbox(name: "a", label: "选项 A")
                    UPCheckbox(name: "b", label: "选项 B")
                    UPCheckbox(name: "c", label: "选项 C")
                }
            }

            DemoSection("形状对比") {
                // 组内 shape 未指定时回落 square，所以这里显式给出两种以便对比。
                UPCheckboxGroup(modelValue: $shaped, shape: "circle") {
                    UPCheckbox(name: "x", label: "圆形一")
                    UPCheckbox(name: "y", label: "圆形二")
                }
                UPCheckboxGroup(shape: "square") {
                    UPCheckbox(name: "x2", label: "方形一")
                    UPCheckbox(name: "y2", label: "方形二")
                }
            }

            DemoSection("自定义颜色") {
                UPCheckboxGroup(activeColor: "#5ac725") {
                    UPCheckbox(name: "m", label: "绿色选中")
                    UPCheckbox(name: "n", label: "绿色选中")
                }
            }

            DemoSection("禁用") {
                UPCheckboxGroup(disabled: true) {
                    UPCheckbox(name: "d1", label: "禁用一")
                    UPCheckbox(name: "d2", label: "禁用二")
                }
            }
        }
    }
}
