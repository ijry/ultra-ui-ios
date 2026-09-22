import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/list/list`。
@MainActor
struct ListDemoView: View {
    @State private var itemCount = 30
    @State private var statusText = "已加载 30 条"
    @State private var scrollLog = "尚未滚动"
    @State private var refreshLog = "尚未下拉"
    @State private var anchor = ""

    private let imageURLs = (1...10).map {
        "https://uview-plus.jiangruyi.com/album/\($0).jpg"
    }

    var body: some View {
        DemoPage {
            DemoSection("滚动加载") {
                UPList(items: Array(0..<itemCount),
                       lowerThreshold: 50,
                       upperThreshold: 10,
                       height: 360,
                       loadmore: true,
                       finished: itemCount >= 90) { index in
                    UPListItem(anchor: "item-\(index)") {
                        row(index)
                    }
                }
                .onLoad { statusText = "初始加载 30 条" }
                .onScroll { scrollLog = "scroll：\(Int($0))pt" }
                .onScrolltolower {
                    let nextCount = min(itemCount + 30, 90)
                    itemCount = nextCount
                    statusText = nextCount == 90 ? "已加载全部 90 条" : "滚动到底部，已加载 \(nextCount) 条"
                }
                .onScrolltoupper { scrollLog = "已回到顶部" }

                tip(statusText)
                tip(scrollLog)
            }

            DemoSection("滚动到指定项") {
                UPList(items: Array(0..<40),
                       scrollIntoView: anchor,
                       scrollWithAnimation: true,
                       height: 240) { index in
                    UPListItem(anchor: "anchor-\(index)") {
                        row(index)
                    }
                }

                HStack(spacing: 12) {
                    UPButton(type: "primary", size: "small", text: "第 10 项") { anchor = "anchor-9" }
                    UPButton(type: "primary", size: "small", text: "第 30 项") { anchor = "anchor-29" }
                    UPButton(size: "small", text: "回到顶部") { anchor = "anchor-0" }
                }

                tip("scrollIntoView 变化时按 scrollWithAnimation 决定是否带动画。")
            }

            DemoSection("下拉刷新") {
                UPList(items: Array(0..<12),
                       height: 240,
                       refresherEnabled: true) { index in
                    UPListItem(anchor: index) { row(index) }
                }
                .onRefresher { phase in refreshLog = "refresher：\(phase.rawValue)" }

                tip(refreshLog)
            }

            DemoSection("分页与禁止滚动") {
                UPList(items: Array(0..<6),
                       pagingEnabled: true,
                       height: 160) { index in
                    row(index).frame(height: 160)
                }

                UPList(items: Array(0..<6), scrollable: false, height: 120) { index in
                    row(index)
                }

                tip("上面按屏翻页，下面 scrollable 为 false 无法滚动。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPList 已覆盖上游 19 个 prop：showScrollbar / lowerThreshold / upperThreshold / scrollTop / offsetAccuracy / enableFlex / pagingEnabled / scrollable / scrollIntoView / scrollWithAnimation / enableBackToTop / height / width / preLoadScreen 与 5 个 refresher*，事件为 onScroll((CGFloat) -> Void) / onScrolltolower / onScrolltoupper / onRefresher((UPListRefreshPhase) -> Void) 外加原生的 onLoad。UPListItem 的 anchor 落成 SwiftUI 的 .id(_:)，配合 scrollIntoView 滚动。offsetAccuracy 仅 nvue 有效、enableFlex 与 enableBackToTop 仅微信小程序有效，refresherThreshold / refresherDefaultStyle / refresherBackground 也没有可配的系统 API，这几项只保留取值。preLoadScreen 在上游用于按屏预渲染的偏移复用，原生的 LazyVStack 自带复用，不需要这层测量。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func row(_ index: Int) -> some View {
        HStack(spacing: 10) {
            UPAvatar(src: imageURLs[index % imageURLs.count],
                     shape: "square",
                     size: 35,
                     mode: "aspectFill")

            Text("列表长度-\(index + 1)")
                .font(.system(size: 15))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
