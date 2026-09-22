import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/divider/divider`。
struct DividerDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("基本案例") {
                UPDivider(text: "分割线")
            }

            DemoSection("是否虚线") {
                UPDivider(dashed: true, text: "分割线")
            }

            DemoSection("是否细线") {
                UPDivider(hairline: true, text: "分割线")
            }

            DemoSection("是否以点代替文字") {
                UPDivider(dot: true, text: "分割线")
            }

            DemoSection("文本内容靠左") {
                UPDivider(textPosition: "left", text: "分割线")
            }

            DemoSection("文本内容靠右") {
                UPDivider(textPosition: "right", text: "分割线")
            }

            DemoSection("自定义文本颜色") {
                UPDivider(text: "分割线", textColor: "#2979ff", lineColor: "#2979ff")
            }

            DemoSection("默认插槽") {
                UPDivider(lineColor: "#3c9cff") {
                    HStack(spacing: 4) {
                        UPIcon(name: "star-fill", color: "#f9ae3d", size: "14")
                        Text("自定义内容")
                            .font(.system(size: 13))
                            .foregroundStyle(UPColor.parse("#3c9cff"))
                    }
                }
            }
        }
    }
}
