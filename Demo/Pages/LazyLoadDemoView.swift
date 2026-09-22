import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/lazyLoad/lazyLoad`。
@MainActor
struct LazyLoadDemoView: View {
    private nonisolated static let imageSources = [
        "https://uview-plus.jiangruyi.com/uview/swiper/swiper1.png",
        "https://uview-plus.jiangruyi.com/uview/swiper/swiper2.png",
        "https://uview-plus.jiangruyi.com/uview/swiper/swiper3.png",
        // 和上游一样故意放一个会失败的地址，用来看错误占位图
        "https://uview-plus.jiangruyi.com/uview/swiper/swiper1.pngg"
    ]

    private nonisolated static let loadingPlaceholder = "https://uview-plus.jiangruyi.com/uview/swiper/swiper2.png"

    @State private var sources: [String] = []
    @State private var status = "loadmore"
    @State private var eventLog = "尚未触发"
    @State private var tick = 0

    var body: some View {
        DemoPage {
            DemoSection("懒加载列表") {
                tip("组件自己渲染图片：进入可视区前挂 loadingImg，进入后换成 image，失败时换 errorImg，并借 opacity 1 → 0 → 1 做淡入。")

                LazyVStack(spacing: 10) {
                    ForEach(Array(sources.indices), id: \.self) { index in
                        UPLazyLoad(
                            image: sources[index],
                            index: index,
                            imgMode: "aspectFill",
                            threshold: 100,
                            height: 100
                        )
                        .onLoad { eventLog = "load：第 \(($0 as NSString).intValue + 1) 项加载完成" }
                        .onError { eventLog = "error：第 \(($0 as NSString).intValue + 1) 项加载失败" }
                        .onClick { eventLog = "click：点了第 \(($0 as NSString).intValue + 1) 项" }
                    }
                }
                .id(tick)

                UPLoadmore(status: status, loadmoreText: "点击加载更多") {
                    getData()
                }

                tip("共 \(sources.count) 项。最近事件：\(eventLog)")
            }

            DemoSection("threshold 负值") {
                tip("threshold 传负数表示图片超出屏幕底部多少距离后才触发；正数表示提前多少 rpx 预载。")

                UPLazyLoad(
                    image: Self.imageSources[0],
                    index: "threshold",
                    imgMode: "aspectFill",
                    threshold: -450,
                    height: 120
                )
            }

            DemoSection("占位图与圆角") {
                tip("loadingImg 给了具体地址时，占位图那次加载只推进 loadStatus，真图加载完才抛 load。")

                UPLazyLoad(
                    image: Self.imageSources[1],
                    index: "placeholder",
                    imgMode: "aspectFill",
                    loadingImg: Self.loadingPlaceholder,
                    borderRadius: 30,
                    height: 120
                )
            }

            DemoSection("关闭淡入淡出") {
                tip("isEffect 为假时 opacity 恒为 1，不做过渡；duration 与 effect 都不再生效。")

                UPLazyLoad(
                    image: Self.imageSources[2],
                    index: "no-effect",
                    imgMode: "aspectFill",
                    isEffect: false,
                    height: 120
                )
            }

            DemoSection("加载失败") {
                tip("image 加载失败后换成 errorImg，errorImg 加载完成时抛 error。")

                UPLazyLoad(
                    image: Self.imageSources[3],
                    index: "error",
                    imgMode: "aspectFill",
                    errorImg: Self.imageSources[0],
                    height: 120
                )
                .onError { eventLog = "error：\($0)" }
            }

            DemoSection("content / placeholder 插槽") {
                tip("仓库既有形态：组件只做「出现即加载」的开关，图片与占位都由页面自己给。")

                UPLazyLoad(threshold: 0, once: true) {
                    UPImage(src: Self.imageSources[0], mode: "aspectFill", width: 300, height: 100, radius: 10)
                } placeholder: {
                    placeholderBox
                }
                .onLoad { eventLog = "插槽形态：已进入可视区" }
            }

            DemoSection("重新加载") {
                UPButton(type: "primary", size: "small", text: "清空并重新取 10 条") {
                    sources = []
                    status = "loadmore"
                    eventLog = "已重置"
                    tick += 1
                    getData()
                }

                tip("重建列表后每一项都会重新走一遍占位 → 加载的过程。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPLazyLoad 对齐上游 index / image / imgMode / loadingImg / errorImg / threshold / duration / effect / isEffect / borderRadius / height 十一个属性，click / load / error 三个事件，以及 loadStatus 两段式状态机：占位图那次加载只把状态从 '' 推到 'lazyed'，真图加载完才推到 'loaded' 并抛 load。触发时机由 IntersectionObserver 换成 onAppear，所以 threshold 只参与 appear(distanceToBottom:) 的判定，正负号按上游 getThreshold 保留但不改变「出现即加载」的实际时机。上游 loadingImg / errorImg 默认是两段约 4KB 的内联 base64 PNG，原生不搬：默认空串时退回 UPImage 的图标占位，需要像素级一致时自己传图；loadingImg 为空也意味着少了占位图那次加载回调，因此 loadStatus 直接从 'lazyed' 起步。effect 只映射 linear / ease-in / ease-out / ease-in-out，cubic-bezier 兜底 easeInOut。clickImg 里的 whichImg 上游算完没用上，原生照抄成只读的 clickedImage。仓库既有的 content / placeholder 双插槽形态保留。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            guard sources.isEmpty else { return }
            getData()
        }
    }

    private func getData() {
        guard status != "loading" else { return }
        status = "loading"

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            for _ in 0..<10 {
                sources.append(Self.imageSources.randomElement() ?? Self.imageSources[0])
            }

            status = "loadmore"
        }
    }

    private var placeholderBox: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(UPColor.parse("#f3f4f6"))
            .frame(width: 300, height: 100)
            .overlay {
                UPIcon(name: "photo", color: "#c0c4cc", size: "24")
            }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
