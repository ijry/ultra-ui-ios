import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/picker/picker`。
/// 上游 `u-picker` 是弹层，由页面用按钮触发 `show`。
struct PickerDemoView: View {
    @State private var showSingle = false
    @State private var showMulti = false
    @State private var single: [String] = ["上海"]
    @State private var multi: [String] = ["男", "北京"]

    var body: some View {
        ZStack {
            DemoPage {
                DemoSection("单列") {
                    UPButton(type: "primary", text: "选择城市") { showSingle = true }
                    Text("当前：\(single.joined(separator: "、"))")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                DemoSection("多列") {
                    UPButton(type: "primary", text: "选择性别和城市") { showMulti = true }
                    Text("当前：\(multi.joined(separator: "、"))")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            UPPicker(
                columns: [["北京", "上海", "广州", "深圳"]],
                modelValue: $single,
                show: $showSingle,
                title: "选择城市"
            )

            UPPicker(
                columns: [["男", "女"], ["北京", "上海", "广州"]],
                modelValue: $multi,
                show: $showMulti,
                title: "选择性别和城市"
            )
        }
    }
}
