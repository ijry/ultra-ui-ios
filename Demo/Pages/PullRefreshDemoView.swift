import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/pullRefresh/pullRefresh`。
@MainActor
struct PullRefreshDemoView: View {
    @State private var basicRefreshing = false
    @State private var customRefreshing = false
    @State private var virtualRefreshing = false
    @State private var loadmoreRefreshing = false
    @State private var plainRefreshing = false
    @State private var loadmoreStatus = "loadmore"
    @State private var loadmoreCount = 8
    @State private var refreshLog = "尚未刷新"
    @State private var scrollLog = "尚未滚动"

    private nonisolated static let rows = Array(0..<8)

    var body: some View {
        DemoPage {
            UPAlert(description: "PC端查看时需要触摸仿真模式")

            DemoSection("基本使用") {
                tip("下拉位移乘 damping 后夹到 maxDistance，越过 threshold 状态从 pull 切到 release，松手才触发 refresh。")

                UPPullRefresh(refreshing: $basicRefreshing, threshold: 50) {
                    VStack(spacing: 0) {
                        ForEach(Self.rows, id: \.self) { index in
                            listRow("Item \(index)")
                        }
                    }
                }
                .onRefresh {
                    Task { @MainActor in
                        refreshLog = "基本使用 刷新中"
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        basicRefreshing = false
                        refreshLog = "基本使用 刷新完成"
                    }
                }
                .frame(height: 180)

                tip("threshold 50 · 状态：\(basicRefreshing ? "刷新中" : "空闲")")
                tip("最近一次：\(refreshLog)")
            }

            DemoSection("自定义下拉动画") {
                tip("pull / release 是作用域插槽，参数是当前 distance 与 threshold；refreshing 是具名插槽。")

                UPPullRefresh(refreshing: $customRefreshing, threshold: 60, damping: 0.6) {
                    VStack(spacing: 0) {
                        ForEach(Self.rows, id: \.self) { index in
                            listRow("Item \(index)")
                        }
                    }
                }
                .pullContent { distance, threshold in
                    Text("👇 继续下拉 \(Int(max(threshold - distance, 0)))")
                        .font(.system(size: 13))
                        .foregroundStyle(UPColor.parse("content"))
                }
                .releaseContent { _, _ in
                    Text("👆 松手就刷新")
                        .font(.system(size: 13))
                        .foregroundStyle(UPColor.parse("primary"))
                }
                .refreshingContent {
                    HStack(spacing: 6) {
                        UPLoadingIcon(show: true, size: 22)
                        Text("客官别急，马上就好")
                            .font(.system(size: 13))
                            .foregroundStyle(UPColor.parse("primary"))
                    }
                }
                .onRefresh {
                    Task { @MainActor in
                        refreshLog = "自定义动画 刷新中"
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        customRefreshing = false
                        refreshLog = "自定义动画 刷新完成"
                    }
                }
                .frame(height: 180)

                tip("threshold 60 · damping 0.6 · 状态：\(customRefreshing ? "刷新中" : "空闲")")
            }

            DemoSection("上拉加载") {
                tip("showLoadmore 为真时内容末尾挂 u-loadmore，只有 loadmoreProps.status 是 loadmore 时触底才抛 loadmore。")

                UPPullRefresh(
                    refreshing: $loadmoreRefreshing,
                    showLoadmore: true,
                    loadmoreProps: UPPullRefreshLoadmoreProps(
                        status: loadmoreStatus,
                        loadmoreText: "上拉加载更多",
                        loadingText: "努力加载中...",
                        nomoreText: "我们是有底线的"
                    ),
                    lowerThreshold: 50
                ) {
                    VStack(spacing: 0) {
                        ForEach(0..<loadmoreCount, id: \.self) { index in
                            listRow("Item \(index)")
                        }
                    }
                }
                .onRefresh {
                    Task { @MainActor in
                        refreshLog = "上拉加载 刷新中"
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        loadmoreRefreshing = false
                        refreshLog = "上拉加载 刷新完成"
                    }
                }
                .onLoadmore { appendMore() }
                .onScroll { scrollLog = "scrollTop \(Int($0))" }
                .frame(height: 200)

                tip("当前 \(loadmoreCount) 条 · \(scrollLog)")
            }

            DemoSection("不用 scroll-view") {
                tip("useScrollView 为假时内容不套滚动容器，整块跟着下拉位移一起走。")

                UPPullRefresh(refreshing: $plainRefreshing, threshold: 50, useScrollView: false) {
                    VStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { index in
                            listRow("Plain \(index)")
                        }
                    }
                }
                .onRefresh {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        plainRefreshing = false
                        refreshLog = "无滚动容器 刷新完成"
                    }
                }
                .frame(height: 180)
            }

            DemoSection("结合虚拟列表") {
                UPPullRefresh(refreshing: $virtualRefreshing) {
                    UPVirtualList(items: Self.rows, itemHeight: 32, viewportHeight: 150) { index in
                        Text("Item \(index): Item \(index)")
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                    }
                }
                .onRefresh {
                    Task { @MainActor in
                        refreshLog = "虚拟列表 刷新中"
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        virtualRefreshing = false
                        refreshLog = "虚拟列表 刷新完成"
                    }
                }
                .frame(height: 170)

                tip("行高 32、视口 150，内层虚拟列表自带滚动容器")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPPullRefresh 对齐上游 refreshing / threshold / damping / maxDistance / showLoadmore / loadmoreProps / useScrollView / enableBackToTop / lowerThreshold / scrollTop 十个属性，refresh / loadmore / scroll 三个事件，pull / release / refreshing 三个插槽，以及 onTouchStart / onTouchMove / onTouchEnd / startRefresh / finishRefresh / resetRefresh 这套状态机。手势由 touch 事件换成 DragGesture，scroll 负载从原生事件对象收敛成 scrollTop。照抄上游 isScrollViewAtTop() 恒为 true 这一处简化：内容已经滚下去时下拉依然会被当成刷新手势，上游注释里也承认这点。enableBackToTop 与 scrollTop 是 scroll-view 的属性，SwiftUI 的 ScrollView 没有对应开关，目前只做解析与保存。仓库既有的 refreshable 系统下拉入口、pull(distance:) / beginRefresh / endRefresh 与 enabled 都保留；组件内部已含 ScrollView，嵌进本页时必须给固定高度。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func appendMore() {
        guard loadmoreStatus == "loadmore" else { return }
        loadmoreStatus = "loading"
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            loadmoreCount += 4
            loadmoreStatus = loadmoreCount >= 20 ? "nomore" : "loadmore"
        }
    }

    private func listRow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .padding(.horizontal, 12)
            .overlay(alignment: .bottom) {
                UPLine()
            }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
