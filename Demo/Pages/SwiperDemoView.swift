import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/swiper/swiper`。
@MainActor
struct SwiperDemoView: View {
    private static let baseURL = "https://uview-plus.jiangruyi.com/uview/swiper/"

    private static let list1 = [
        baseURL + "swiper1.png",
        baseURL + "swiper2.png",
        baseURL + "swiper3.png"
    ]

    private static let list2 = [
        UPSwiperItem(source: baseURL + "swiper2.png", title: "昨夜星辰昨夜风，画楼西畔桂堂东"),
        UPSwiperItem(source: baseURL + "swiper1.png", title: "身无彩凤双飞翼，心有灵犀一点通"),
        UPSwiperItem(source: baseURL + "swiper3.png", title: "谁念西风独自凉，萧萧黄叶闭疏窗，沉思往事立残阳")
    ]

    private static let items1 = list1.map { UPSwiperItem(source: $0) }

    @State private var current = 0
    @State private var currentNum = 0
    @State private var changeLog = "尚未切换"
    @State private var clickLog = "尚未点击"

    var body: some View {
        DemoPage {
            DemoSection("基础功能") {
                basicSwiper

                Text("最近 change：\(changeLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("最近 click：\(clickLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("纵向滑动") {
                UPSwiper(
                    list: Self.list1,
                    indicator: true,
                    indicatorMode: "dot",
                    autoplay: false,
                    vertical: true,
                    height: "200"
                )
            }

            DemoSection("带标题") {
                UPSwiper(
                    list: Self.list2,
                    autoplay: false,
                    circular: true,
                    keyName: "image",
                    showTitle: true
                )

                Text("标题只在图片项上显示（上游模板要求 testImage(getSource(item))）；showTitle 为真时不再画内建指示器。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("带指示器") {
                UPSwiper(
                    list: Self.list1.reversed(),
                    indicator: true,
                    indicatorMode: "line",
                    circular: true
                )
            }

            DemoSection("加载中") {
                UPSwiper(list: Self.list1.reversed(), loading: true)
            }

            DemoSection("自定义指示器") {
                VStack(spacing: 15) {
                    ZStack(alignment: .bottom) {
                        UPSwiper(
                            list: Self.items1,
                            autoplay: false,
                            current: $current
                        )

                        UPSwiperIndicator(
                            length: Self.list1.count,
                            current: current,
                            indicatorActiveColor: "#ffffff",
                            indicatorInactiveColor: "rgba(255, 255, 255, 0.35)",
                            indicatorMode: "dot"
                        )
                        .padding(.bottom, 10)
                    }

                    ZStack(alignment: .bottomTrailing) {
                        UPSwiper(
                            list: Self.items1.reversed(),
                            autoplay: false,
                            current: $currentNum
                        )

                        Text("\(currentNum + 1)/\(Self.list1.count)")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Capsule())
                            .padding([.bottom, .trailing], 10)
                    }
                }
            }

            DemoSection("卡片式") {
                UPSwiper(
                    list: Self.list1.reversed(),
                    autoplay: false,
                    circular: true,
                    previousMargin: "30",
                    nextMargin: "30",
                    radius: "5"
                )

                Text("只有 previousMargin 与 nextMargin 同时为真值时，非当前项才缩到 0.92 并加上圆角。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("视频项") {
                UPSwiper(
                    list: [
                        UPSwiperItem(source: Self.baseURL + "swiper1.png"),
                        UPSwiperItem(source: "https://www.w3schools.com/html/mov_bbb.mp4",
                                     poster: Self.baseURL + "swiper2.png")
                    ],
                    autoplay: false,
                    height: "200"
                )

                Text("上游按后缀嗅探 image / video，也可用 item.type 显式指定；视频项用 poster 兜底封面。照抄上游：type 一旦是真值就不再嗅探，且只认 image / video，其余值一律落回 image。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("默认插槽") {
                UPSwiper(list: Self.items1, autoplay: false, height: "160")
                    .itemContent { item, index in
                        ZStack {
                            UPImage(src: item.source, mode: "aspectFill", width: 360, height: 160)
                            Text("第 \(index + 1) 张")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                Text("默认作用域插槽拿到 item 与 index；indicator 也是一个具名插槽。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPSwiper 对齐上游 24 个 props、click / change / update:current 三个事件与 default / indicator 两个插槽：图片走 UPImage、视频走 UPShortVideo（poster 兜底封面），loading 时渲染 circle 模式的 UPLoadingIcon，标题横幅与内建指示器按上游条件显示。getItemType / itemStyle / showTitle 的判定都可单测。照抄上游三处反直觉：item.type 一旦是真值就不再按后缀嗅探且只认 image / video（其余落回 image）、标题横幅只在图片项上显示（视频标题上游走 <video :title>）、displayMultipleItems 在 list 为空时被强制成 0。autoplay 由原生 swiper 的 interval 换成 Task 轮转；vertical / acceleration / easingFunction 是 uni-app swiper 的能力，SwiftUI TabView 没有对应开关，目前只保留参数。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var basicSwiper: some View {
        UPSwiper(list: Self.list1)
            .onChange { index in
                changeLog = "index=\(index)"
            }
            .onClick { index in
                clickLog = "index=\(index)"
            }
    }
}
