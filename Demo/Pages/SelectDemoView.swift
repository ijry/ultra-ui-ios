import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/select/select`。
@MainActor
struct SelectDemoView: View {
    @State private var current = "swift"
    @State private var bordered = ""
    @State private var picked = "尚未选择"

    private let options = [
        UPSelectOption(id: "swift", name: "Swift"),
        UPSelectOption(id: "kotlin", name: "Kotlin"),
        UPSelectOption(id: "dart", name: "Dart")
    ]

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPSelect(options: options, current: $current, label: "选择语言")
                    .onSelect { picked = "select：\($0.name)" }

                tip("当前：\(current)")
                tip(picked)
            }

            DemoSection("显示选中项") {
                UPSelect(options: options,
                         current: $current,
                         label: "选择语言",
                         showOptionsLabel: true)

                tip("showOptionsLabel 为真时触发行显示 currentLabel 而不是 label。")
            }

            DemoSection("带边框与固定面板宽度") {
                UPSelect(options: options,
                         current: $bordered,
                         label: "请选择",
                         showOptionsLabel: true,
                         border: true,
                         optionsWidth: "240")

                tip("border 补上 8×10 内边距与 36pt 最小高度，optionsWidth 固定面板宽度。")
            }

            DemoSection("对象数组 + keyName") {
                UPSelect(options: [["code": "bj", "label": "北京"], ["code": "sh", "label": "上海"]],
                         current: $bordered,
                         label: "选择城市",
                         keyName: "code",
                         labelName: "label",
                         showOptionsLabel: true)
            }

            DemoSection("自定义插槽") {
                UPSelect(options: options, current: $current, label: "自定义")
                    .text { label in
                        Text(label.isEmpty ? "点我选择" : label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(UPColor.parse("#3c9cff"))
                    }
                    .icon {
                        UPIcon(name: "uicon-list", color: "#3c9cff", size: "16")
                    }
                    .optionItem { option in
                        HStack(spacing: 6) {
                            UPIcon(name: "uicon-checkmark", color: "#5ac725", size: "12")
                            Text(option.name).font(.system(size: 14))
                        }
                    }

                tip("text / icon / optionItem 三个插槽都可用。")
            }

            DemoSection("禁用") {
                UPSelect(options: options, label: "禁用状态", disabled: true)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPSelect 已覆盖上游 18 个 prop：maxHeight / overlay / overlayOpacity / overlayStyle / duration / label / options / keyName / labelName / showOptionsLabel / current / zIndex / itemColor / iconColor / iconSize / disabled / border / optionsWidth，`update:current` 落成 current 绑定、`select` 落成 onSelect，三个插槽 text / icon / optionItem 都提供，方法 openSelect() / closeSelect() / select(_:)。上游 adjustOptionsWrapPosition 会用 selectorQuery 判断面板右侧是否超屏再左右翻转，原生交给 SwiftUI 的对齐，不做超屏重定位；maxHeight 默认 90vh、optionsWidth 支持百分比这两类视口相关值原生取 nil 交给布局决定。")
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
