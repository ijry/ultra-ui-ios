import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/gap/gap`。
struct GapDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("默认间隔") {
                Text("上方内容")
                UPGap()
                Text("下方内容")
            }

            DemoSection("指定高度与背景") {
                Text("上方内容")
                UPGap(bgColor: "#f3f4f6", height: 30)
                Text("间隔 30")
                UPGap(bgColor: "#e4e7ed", height: 60)
                Text("间隔 60")
            }
        }
    }
}
