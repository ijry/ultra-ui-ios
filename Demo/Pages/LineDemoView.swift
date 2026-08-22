import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/line/line`。
struct LineDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPLine()
            }

            DemoSection("虚线") {
                UPLine(color: "primary", dashed: true)
            }

            DemoSection("自定义颜色") {
                UPLine(color: "error")
                UPLine(color: "success")
                UPLine(color: "warning")
            }

            DemoSection("垂直线条") {
                HStack(spacing: 12) {
                    Text("左")
                    UPLine(color: "error", direction: "col")
                        .frame(height: 30)
                    Text("右")
                }
            }
        }
    }
}
