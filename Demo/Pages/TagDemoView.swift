import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/tag/tag`。
struct TagDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("主题类型") {
                HStack(spacing: 8) {
                    UPTag(type: "primary", text: "primary")
                    UPTag(type: "success", text: "success")
                    UPTag(type: "error", text: "error")
                }
                HStack(spacing: 8) {
                    UPTag(type: "warning", text: "warning")
                    UPTag(type: "info", text: "info")
                }
            }

            DemoSection("尺寸") {
                HStack(spacing: 8) {
                    UPTag(size: "large", text: "large")
                    UPTag(text: "medium")
                    UPTag(size: "mini", text: "mini")
                }
            }

            DemoSection("形状") {
                HStack(spacing: 8) {
                    UPTag(shape: "square", text: "square")
                    UPTag(shape: "circle", text: "circle")
                }
            }

            DemoSection("镂空") {
                HStack(spacing: 8) {
                    UPTag(type: "primary", text: "plain", plain: true)
                    UPTag(type: "success", text: "plainFill", plainFill: true, plain: true)
                }
            }

            DemoSection("禁用与可关闭") {
                HStack(spacing: 8) {
                    UPTag(disabled: true, text: "disabled")
                    UPTag(text: "closable", closable: true)
                }
            }
        }
    }
}
