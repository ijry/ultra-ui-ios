import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/loading-page/loading-page`。
struct LoadingPageDemoView: View {
    @State private var showCircle = false
    @State private var showSpinner = false

    var body: some View {
        ZStack {
            DemoPage {
                DemoSection("circle 模式") {
                    UPButton(type: "primary", text: "显示加载页") {
                        showCircle = true
                    }
                }

                DemoSection("spinner 模式") {
                    UPButton(type: "primary", text: "显示 spinner 加载页") {
                        showSpinner = true
                    }
                }

                DemoSection("说明") {
                    Text("加载页会铺满全屏，点按任意处关闭。")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            if showCircle {
                UPLoadingPage(loadingText: "正在加载", loadingMode: "circle", loading: true)
                    .onTapGesture { showCircle = false }
            }

            if showSpinner {
                UPLoadingPage(loadingText: "请稍候", loadingMode: "spinner", loading: true)
                    .onTapGesture { showSpinner = false }
            }
        }
    }
}
