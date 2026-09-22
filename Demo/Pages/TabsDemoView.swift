import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/tabs/tabs`。
@MainActor
struct TabsDemoView: View {
    private static let list1 = ["关注", "推荐", "电影", "科技", "音乐", "美食", "文化", "财经", "手工"]
    private static let list6 = ["关注", "推荐", "电影", "科技"]
    private static let listShape = ["关注", "推荐", "电影"]
    private static let listCard = ["账号登录", "免密登录"]
    private static let listPillArrow = ["关注", "精选", "热门"]
    private static let listTag = ["全部", "待付款", "待发货", "已发货", "已完成", "已关闭"]

    private static let list2: [UPTabsItem] = [
        UPTabsItem(name: "关注"),
        UPTabsItem(name: "推荐", badge: "●"),
        UPTabsItem(name: "电影", badge: "5"),
        UPTabsItem(name: "科技"),
        UPTabsItem(name: "音乐")
    ]

    private static let list3: [UPTabsItem] = [
        UPTabsItem(name: "关注"),
        UPTabsItem(name: "推荐"),
        UPTabsItem(name: "电影", disabled: true),
        UPTabsItem(name: "科技"),
        UPTabsItem(name: "音乐")
    ]

    @State private var basicCurrent = 3
    @State private var stickyCurrent = 0
    @State private var badgeCurrent = 0
    @State private var noScrollCurrent = 0
    @State private var disabledCurrent = 0
    @State private var customCurrent = 0
    @State private var lineBgCurrent = 0
    @State private var slotCurrent = 0
    @State private var list1Current = 1
    @State private var swiperCurrent = 0
    @State private var shapeCurrent = 0
    @State private var cardCurrent = 0
    @State private var pillArrowCurrent = 0
    @State private var tagCurrent = 0
    @State private var clickLog = "尚未点击"

    var body: some View {
        DemoPage {
            DemoSection("基础演示") {
                UPTabs(list: Self.list1, current: $basicCurrent)
                    .onClick { event in clickLog = "点击 \(event.item.name)(index=\(event.index))" }

                Text("最近点击：\(clickLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("粘性布局") {
                UPSticky(offsetTop: 0, bgColor: "#ffffff", index: "tabs-sticky") {
                    UPTabs(list: Self.list1, current: $stickyCurrent)
                }
            }

            DemoSection("显示徽标") {
                UPTabs(list: Self.list2, current: $badgeCurrent)

                Text("原生 UPTabsItem 的 badge 是字符串，上游的 isDot 用「●」表达，数值徽标直接给数字文本。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("禁止滚动") {
                UPTabs(list: Self.list6, current: $noScrollCurrent, scrollable: false)
            }

            DemoSection("禁用菜单") {
                UPTabs(list: Self.list3, current: $disabledCurrent)
            }

            DemoSection("自定义样式") {
                UPTabs(
                    list: Self.list1, current: $customCurrent,
                    lineColor: "#f56c6c",
                    activeStyle: UPStyle(["color": "#303133"]),
                    inactiveStyle: UPStyle(["color": "#606266"]),
                    lineWidth: "30",
                    itemStyle: UPStyle([
                        "padding-left": "15px", "padding-right": "15px", "height": "34px"
                    ])
                )

                Text("上游还在 activeStyle 里用 fontWeight 与 transform: scale(1.05)，原生 UPStyle 不支持这两个声明。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("滑块设置背景图") {
                UPTabs(
                    list: Self.list1, current: $lineBgCurrent,
                    lineColor: "#3c9cff", lineWidth: 20, lineHeight: 7
                )

                Text("上游用 base64 背景图做滑块，原生滑块是纯色 Capsule，这里以加粗滑块近似。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("自定义内容插槽") {
                UPTabs(
                    list: Self.list1, current: $slotCurrent,
                    activeStyle: UPStyle(["color": "#f56c6c"]),
                    inactiveStyle: UPStyle(["color": "#606266"])
                )

                Text("原生 UPTabs 暂无 default 插槽，这里用 activeStyle 的红色文字近似上游插槽里的红字效果。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("右侧自定义插槽") {
                HStack(spacing: 8) {
                    UPTabs(list: Self.list1, current: $list1Current)
                    UPIcon(name: "list", size: "21", bold: true)
                }

                UPButton(type: "primary", size: "small", text: "切换下一个\(list1Current)") {
                    list1Current = (list1Current + 1) % Self.list1.count
                }
                .frame(width: 120)
            }

            DemoSection("在swiper中使用") {
                UPTabs(list: Self.list1, current: $swiperCurrent)

                TabView(selection: $swiperCurrent) {
                    ForEach(Array(Self.list1.indices), id: \.self) { index in
                        Text(Self.list1[index])
                            .font(.system(size: 15))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemGroupedBackground))
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 120)
            }

            DemoSection("胶囊模式") {
                UPTabs(list: Self.listShape, current: $shapeCurrent, scrollable: false, shapeMode: "capsule")
            }

            DemoSection("卡片模式") {
                UPTabs(
                    list: Self.listCard, current: $cardCurrent,
                    lineWidth: "26", scrollable: false, shapeMode: "card"
                )
            }

            DemoSection("圆角矩形箭头模式") {
                UPTabs(list: Self.listPillArrow, current: $pillArrowCurrent, scrollable: false, shapeMode: "pill-arrow")
            }

            DemoSection("Tag模式") {
                UPTabs(list: Self.listTag, current: $tagCurrent, shapeMode: "tag")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPTabs 渲染标题、图标、徽标文本与底部滑块，并支持 scrollable、activeStyle/inactiveStyle/itemStyle 与 lineColor/lineWidth/lineHeight。shapeMode（capsule/card/pill-arrow/tag）、duration、lineBgSize、iconStyle、keyName 目前只作为参数保存，不产生视觉差异；default 与 right 插槽在这里用相邻视图近似。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
