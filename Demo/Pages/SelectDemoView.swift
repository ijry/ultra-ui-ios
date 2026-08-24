import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/select/select`。
///
/// `UPSelect` 目前是基线实现，用原生 `Menu` 承载选项。
struct SelectDemoView: View {
    @State private var current = "swift"
    @State private var picked = ""

    private let options = [
        UPSelectOption(id: "swift", name: "Swift"),
        UPSelectOption(id: "kotlin", name: "Kotlin"),
        UPSelectOption(id: "dart", name: "Dart")
    ]

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPSelect(options: options, current: $current, label: "选择语言")
                Text("当前：\(current)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("select 事件") {
                UPSelect(options: options, label: "点选一项")
                    .onSelect { picked = $0.name }
                Text(picked.isEmpty ? "尚未选择" : "已选：\(picked)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("禁用") {
                UPSelect(options: options, label: "禁用状态", disabled: true)
            }
        }
    }
}
