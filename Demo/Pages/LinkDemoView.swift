import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/link/link`。
struct LinkDemoView: View {
    private static let docUrl = "https://uview-plus.jiangruyi.com/"
    private static let uniappUrl = "https://uniapp.dcloud.io/"

    @State private var eventLog = "尚未点击"

    var body: some View {
        DemoPage {
            DemoSection("基本案例") {
                UPLink(href: Self.docUrl, text: "打开uview-plus文档") {
                    eventLog = "click"
                }

                tip("最近事件：\(eventLog)")
            }

            DemoSection("显示下划线") {
                UPLink(underLine: true, href: Self.docUrl, text: "Go to uview-plus doc")

                tip("underLine 为 true 时下划线用 lineColor，未设置时回落到 color。")
            }

            DemoSection("自定义颜色") {
                UPLink(
                    color: "#19be6b",
                    underLine: true,
                    href: Self.docUrl,
                    lineColor: "#19be6b",
                    text: "打开uview-plus文档"
                )
            }

            DemoSection("自定义链接内容") {
                UPLink(href: Self.uniappUrl, text: "打开uni-app文档")

                tip("href 指向 uni-app 文档，点击后由系统浏览器打开。")
            }

            DemoSection("当前原生范围") {
                Text("color / fontSize / underLine / href / lineColor / text 与 click 回调都已对齐，点击走 SwiftUI 的 openURL 打开系统浏览器。上游 mpTips 是小程序端复制链接后的提示语，iOS 上不需要复制兜底，属性保留但不会触发。上游默认不显示下划线，这里第 2、3 节显式传 underLine 才可见。")
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
