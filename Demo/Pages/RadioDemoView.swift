import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/radio/radio`。
struct RadioDemoView: View {
    @State private var language: UPCheckboxName = "swift"
    @State private var shaped: UPCheckboxName = "a"

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPRadioGroup(modelValue: $language) {
                    UPRadio(name: "swift", label: "Swift")
                    UPRadio(name: "kotlin", label: "Kotlin")
                    UPRadio(name: "dart", label: "Dart")
                }
                Text("已选：\(language.description)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("横向排列") {
                UPRadioGroup(placement: "row") {
                    UPRadio(name: "x", label: "选项 X")
                    UPRadio(name: "y", label: "选项 Y")
                    UPRadio(name: "z", label: "选项 Z")
                }
            }

            DemoSection("方形") {
                UPRadioGroup(modelValue: $shaped, shape: "square") {
                    UPRadio(name: "a", label: "方形一")
                    UPRadio(name: "b", label: "方形二")
                }
            }

            DemoSection("自定义颜色") {
                UPRadioGroup(activeColor: "#f56c6c") {
                    UPRadio(name: "m", label: "红色选中")
                    UPRadio(name: "n", label: "红色选中")
                }
            }

            DemoSection("禁用") {
                UPRadioGroup(disabled: true) {
                    UPRadio(name: "d1", label: "禁用一")
                    UPRadio(name: "d2", label: "禁用二")
                }
            }
        }
    }
}
