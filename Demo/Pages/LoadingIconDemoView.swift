import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/loading-icon/loading-icon`。
struct LoadingIconDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("加载模式") {
                HStack(spacing: 24) {
                    UPLoadingIcon(mode: "spinner")
                    UPLoadingIcon(mode: "circle")
                    UPLoadingIcon(mode: "semicircle")
                }
            }

            DemoSection("自定义颜色") {
                HStack(spacing: 24) {
                    UPLoadingIcon(color: "primary")
                    UPLoadingIcon(color: "success")
                    UPLoadingIcon(color: "error")
                }
            }

            DemoSection("带文字") {
                UPLoadingIcon(color: "primary", text: "加载中")
            }

            DemoSection("文字纵向排列") {
                UPLoadingIcon(color: "warning", vertical: true, text: "加载中")
            }

            DemoSection("自定义大小") {
                HStack(alignment: .center, spacing: 24) {
                    UPLoadingIcon(size: 20)
                    UPLoadingIcon(size: 30)
                    UPLoadingIcon(size: 40)
                }
            }
        }
    }
}
