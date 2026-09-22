import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/loadmore/loadmore`。
struct LoadmoreDemoView: View {
    @State private var eventLog = "尚未触发"

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                UPLoadmore(status: "loading", iconSize: 17, isDot: true)
            }

            DemoSection("无更多数据") {
                UPLoadmore(status: "nomore", line: true)
            }

            DemoSection("加载更多(点击触发事件)") {
                UPLoadmore(status: "loadmore", line: true) {
                    eventLog = "loadmore"
                    UPToast.show(message: "加载更多")
                }

                tip("最近事件：\(eventLog)")
            }

            DemoSection("自定义图标") {
                UPLoadmore(status: "loading", loadingIcon: "circle")
            }

            DemoSection("显示点") {
                UPLoadmore(status: "nomore", color: "#909399", isDot: true, line: true)
            }

            DemoSection("自定义提示语") {
                UPLoadmore(status: "loading", color: "#909399", loadingText: "努力加载中,先喝杯茶")
            }

            DemoSection("自定义线条颜色") {
                UPLoadmore(
                    color: "#1CD29B", loadmoreText: "看,我和别人不一样",
                    line: true, lineColor: "#1CD29B", dashed: true
                )
            }

            DemoSection("当前原生范围") {
                Text("status / bgColor / icon / fontSize / iconSize / color / loadingIcon / loadmoreText / loadingText / nomoreText / isDot / iconColor / marginTop / marginBottom / height / line / lineColor / dashed 与 loadmore 事件都已对齐：status 为 nomore 且 isDot 时文案换成圆点，line 为真时两侧各画一条 140rpx 分割线。点击只在 status 为 loadmore 时触发事件，和上游一致；上游示例用 toast('加载更多') 提示，这里换成 UPToast。")
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
