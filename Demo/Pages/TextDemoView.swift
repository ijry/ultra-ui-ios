import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/text/text`。
struct TextDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPText(text: "上游 u-text 的默认渲染")
            }

            DemoSection("主题类型") {
                UPText(type: "primary", text: "primary")
                UPText(type: "success", text: "success")
                UPText(type: "error", text: "error")
                UPText(type: "warning", text: "warning")
                UPText(type: "info", text: "info")
            }

            DemoSection("带图标") {
                UPText(text: "前置图标", prefixIcon: "map")
                UPText(text: "后置图标", suffixIcon: "arrow-right")
            }

            DemoSection("mode 格式化") {
                UPText(text: "13800138000", mode: "phone")
                UPText(text: "1610513121", mode: "date")
                UPText(text: "1234567.89", mode: "price")
                UPText(text: "uview-plus", mode: "link", href: "https://uview-plus.jiangruyi.com")
            }

            DemoSection("加粗与行数限制") {
                UPText(text: "加粗文本", bold: true)
                UPText(
                    text: "这是一段很长的文本，用于演示 lines 限制生效后的省略效果。这是一段很长的文本，用于演示 lines 限制生效后的省略效果。",
                    lines: 2
                )
            }
        }
    }
}
