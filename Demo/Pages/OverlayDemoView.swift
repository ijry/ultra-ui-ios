import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/overlay/overlay`（清单里 icon 名为 `mask`）。
struct OverlayDemoView: View {
    @State private var showOverlay = false
    @State private var showWithContent = false

    var body: some View {
        ZStack {
            DemoPage {
                DemoSection("基础用法") {
                    UPButton(type: "primary", text: "显示遮罩") {
                        showOverlay = true
                    }
                }

                DemoSection("嵌入内容") {
                    UPButton(type: "primary", text: "显示带内容的遮罩") {
                        showWithContent = true
                    }
                }
            }

            if showOverlay {
                UPOverlay(show: true) { showOverlay = false }
            }

            if showWithContent {
                UPOverlay(show: true) { showWithContent = false }
                VStack(spacing: 12) {
                    Text("u-overlay")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("点击遮罩关闭")
                        .foregroundStyle(.white.opacity(0.8))
                }
                .allowsHitTesting(false)
            }
        }
    }
}
