import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/scrollList/scrollList`。
@MainActor
struct ScrollListDemoView: View {
    private struct Goods: Identifiable {
        let id = UUID()
        let price: String
        let thumbnail: String
    }

    private struct Menu: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
    }

    private static let goodsBaseURL = "https://uview-plus.jiangruyi.com/uview/goods/"
    private static let menuBaseURL = "https://uview-plus.jiangruyi.com/uview/menu/"
    private static let itemWidth: CGFloat = 90
    private static let itemSpacing: CGFloat = 10
    private static let goodsArr: [Goods] = [
        Goods(price: "230.5", thumbnail: "1.jpg"),
        Goods(price: "74.1", thumbnail: "2.jpg"),
        Goods(price: "8457", thumbnail: "6.jpg"),
        Goods(price: "1442", thumbnail: "5.jpg"),
        Goods(price: "541", thumbnail: "2.jpg"),
        Goods(price: "234", thumbnail: "3.jpg"),
        Goods(price: "562", thumbnail: "4.jpg"),
        Goods(price: "251.5", thumbnail: "1.jpg")
    ]

    private static let menuArr: [[Menu]] = [
        [
            Menu(name: "天猫新品", icon: "11.png"),
            Menu(name: "今日爆款", icon: "9.png"),
            Menu(name: "天猫国际", icon: "17.png"),
            Menu(name: "饿了么", icon: "6.png"),
            Menu(name: "天猫超市", icon: "11.png"),
            Menu(name: "分类", icon: "2.png"),
            Menu(name: "天猫美食", icon: "3.png"),
            Menu(name: "阿里健康", icon: "12.png"),
            Menu(name: "口碑生活", icon: "7.png")
        ],
        [
            Menu(name: "充值中心", icon: "8.png"),
            Menu(name: "机票酒店", icon: "10.png"),
            Menu(name: "金币庄园", icon: "18.png"),
            Menu(name: "阿里拍卖", icon: "15.png"),
            Menu(name: "淘宝吃货", icon: "16.png"),
            Menu(name: "闲鱼", icon: "4.png"),
            Menu(name: "会员中心", icon: "6.png"),
            Menu(name: "造点新货", icon: "13.png"),
            Menu(name: "土货鲜食", icon: "14.png")
        ]
    ]

    @State private var edgeLog = "尚未触边"
    @State private var moreLog = "尚未点击"

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                Text("指示条位移按 scrollLeft / (内容宽 - 容器宽) × (indicatorWidth - indicatorBarWidth) 算；两个宽度由组件自己量。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                UPScrollList(
                    indicatorColor: "#fff0f0",
                    indicatorActiveColor: "#f56c6c"
                ) {
                    HStack(spacing: Self.itemSpacing) {
                        ForEach(Self.goodsArr) { item in
                            goodsCell(item)
                        }

                        showMoreCell
                    }
                }
                .onLeft { edgeLog = "left" }
                .onRight { edgeLog = "right" }

                Text("边缘事件：\(edgeLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("查看更多：\(moreLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("多菜单扩展") {
                UPScrollList {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(Array(Self.menuArr.enumerated()), id: \.offset) { _, line in
                            HStack(spacing: Self.itemSpacing) {
                                ForEach(line) { item in
                                    menuCell(item)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            DemoSection("隐藏指示器") {
                UPScrollList(indicator: false) {
                    HStack(spacing: Self.itemSpacing) {
                        ForEach(Self.goodsArr) { item in
                            goodsCell(item)
                        }
                    }
                }
            }

            DemoSection("指示器尺寸与定位") {
                UPScrollList(
                    indicatorWidth: 80,
                    indicatorBarWidth: 40,
                    indicatorColor: "#ecf5ff",
                    indicatorActiveColor: "#3c9cff",
                    indicatorStyle: UPStyle(["marginTop": "24px"])
                ) {
                    HStack(spacing: Self.itemSpacing) {
                        ForEach(Self.goodsArr) { item in
                            goodsCell(item)
                        }
                    }
                }

                Text("indicatorStyle 是上游的 String | Object，可用来微调指示器定位。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPScrollList 对齐上游 6 个 props 与 left / right 两个事件：横向 ScrollView + 底部线型指示器，滑块位移按上游 barStyle 的比例公式算，内容宽与容器宽都由组件内部的 GeometryReader 量（对应上游 scroll 事件里的 scrollWidth 与 getComponentWidth()）。scrollToUpper / scrollToLower 对应上游两个边界处理器，照抄上游那处反直觉：scrolltolower 之后塞进 scrollLeft 的是「指示器坐标系」的 indicatorWidth - indicatorBarWidth，而不是真实滚动距离，只为让比例公式算出满格位移。上游 CSS 里 .__line 写死 60px、.__bar 写死 20px，但内联 style 会用两个 prop 覆盖，因此原生直接用 prop。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }


    private func goodsCell(_ item: Goods) -> some View {
        VStack(spacing: 5) {
            UPImage(
                src: Self.goodsBaseURL + item.thumbnail,
                mode: "aspectFill",
                width: Self.itemWidth,
                height: Self.itemWidth,
                radius: 4
            )

            Text("￥\(item.price)")
                .font(.system(size: 14))
                .foregroundStyle(UPColor.parse("error"))
        }
        .frame(width: Self.itemWidth)
    }

    private func menuCell(_ item: Menu) -> some View {
        VStack(spacing: 5) {
            UPImage(
                src: Self.menuBaseURL + item.icon,
                mode: "aspectFit",
                width: 44,
                height: 44
            )

            Text(item.name)
                .font(.system(size: 12))
                .foregroundStyle(UPColor.parse("content"))
        }
        .frame(width: 60)
    }

    private var showMoreCell: some View {
        VStack(spacing: 6) {
            Text("查看更多")
                .font(.system(size: 12))
                .foregroundStyle(UPColor.parse("error"))

            UPIcon(name: "arrow-leftward", color: "#f56c6c", size: "12")
        }
        .frame(width: Self.itemWidth, height: Self.itemWidth)
        .contentShape(Rectangle())
        .onTapGesture { moreLog = "查看更多" }
    }
}
