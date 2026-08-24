import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/choose/choose`。
struct ChooseDemoView: View {
    @State private var single = "a"
    @State private var multi = "1"

    var body: some View {
        DemoPage {
            DemoSection("单选") {
                UPChoose(
                    options: [
                        UPChooseOption(value: "a", title: "选项 A"),
                        UPChooseOption(value: "b", title: "选项 B"),
                        UPChooseOption(value: "c", title: "选项 C")
                    ],
                    modelValue: $single
                )
                Text("当前：\(single)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("多列换行") {
                UPChoose(
                    options: (1...6).map { UPChooseOption(value: "\($0)", title: "标签 \($0)") },
                    modelValue: $multi,
                    wrap: true
                )
            }
        }
    }
}
