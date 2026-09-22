import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/indexList/indexList`。
@MainActor
struct IndexListDemoView: View {
    private struct Friend: Identifiable {
        let id = UUID()
        let name: String
        let url: String
    }

    private static let anchors: [String] = ["↑", "☆"]
        + (0..<16).map { String(UnicodeScalar(UInt8(65 + $0))) }
        + ["#"]

    private static let names = [
        "勇往无敌", "疯狂的迪飙", "磊爱可", "梦幻梦幻梦", "枫中飘瓢", "飞翔天使",
        "曾经第一", "追风幻影族长", "麦小姐", "胡格罗雅", "Red磊磊", "乐乐立立",
        "青龙爆风", "跑跑卡叮车", "山里狼", "supersonic超"
    ]

    private static let headerRows: [(title: String, icon: String)] = [
        ("新的朋友", "man-add-fill"),
        ("标签", "tags-fill"),
        ("朋友圈", "chrome-circle-fill"),
        ("QQ", "qq-fill")
    ]

    private static let sections: [(anchor: String, friends: [Friend])] = anchors.enumerated().map { offset, anchor in
        let friends = (0..<10).map { row -> Friend in
            let seed = offset * 10 + row
            return Friend(
                name: names[seed % names.count],
                url: "https://uview-plus.jiangruyi.com/album/\(seed % 10 + 1).jpg"
            )
        }
        return (anchor, friends)
    }

    @State private var activeIndex = ""
    @State private var changeLog = "尚未切换"

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                UPIndexList(indexList: Self.anchors, activeIndex: $activeIndex, itemMargin: "20rpx") {
                    header

                    ForEach(Self.sections, id: \.anchor) { section in
                        UPIndexItem(index: section.anchor) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(section.friends) { friend in
                                    friendRow(friend)
                                    UPLine()
                                }
                            }
                        }
                    }

                    footer
                }
                .frame(height: 420)

                Text("当前锚点：\(activeIndex.isEmpty ? "未选中" : activeIndex)　\(changeLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("默认 A-Z 字母表") {
                UPIndexList(customNavHeight: "44px", safeBottomFix: true) {
                    ForEach(UPIndexList<EmptyView>.alphabetIndexList, id: \.self) { letter in
                        UPIndexItem(index: letter) {
                            Text("\(letter) 分组内容")
                                .font(.system(size: 15))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .frame(height: 240)

                tip("不传 indexList 时按上游 uIndexList 回落到内部生成的 A-Z 26 个字母。")
                tip("customNavHeight 44px 会在滚动联动时抵消宿主导航栏高度；safeBottomFix 为真时列表末尾补一段底部安全区留白。")
            }

            DemoSection("锚点样式") {
                UPIndexAnchor(index: "A")

                UPIndexAnchor(index: "B", text: "热门城市", color: "#ffffff", size: 16, bgColor: "#3c9cff", height: 44)

                Text("锚点默认 color #606266 / size 14 / bgColor #f1f1f1 / height 32，text 非空时优先于锚点标识渲染。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPIndexList 自带 ScrollView 与右侧字母栏，放在 Demo 页里需要固定高度。已覆盖上游 7 个 prop：indexList / activeColor / inactiveColor / sticky / customNavHeight / itemMargin / safeBottomFix；默认色 #5677fc、#606266 按上游当作主题哨兵，命中默认时改取 primary / content 主题色。字母栏按上游样式为 30pt 宽、16×16 圆点、12pt 字号，拖动时显示 50×50 旋转 -45° 的放大指示器，松手 300ms 后隐藏。滚动联动公式（累加 item 高度加 itemMargin、偏移加 customNavHeight、越界清空高亮）由 scrollActiveIndex(scrollTop:itemHeights:headerHeight:) 提供，宿主可在自定义容器里复用；上游 safeBottomFix 的唯一使用处已被注释，故只映射为底部安全区留白。锚点头部默认渲染 UPIndexAnchor 的文本，已覆盖 text / color / size / bgColor / height；上游的 header / footer 插槽在这里作为列表内容的首尾视图传入，sticky 由 SwiftUI 的 Section 头部行为提供。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            changeLog = "上下滑动或点击右侧字母跳转"
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Self.headerRows, id: \.title) { row in
                HStack(spacing: 10) {
                    UPAvatar(
                        shape: "square", size: 35, fontSize: 26,
                        icon: row.icon, randomBgColor: true
                    )

                    Text(row.title)
                        .font(.system(size: 16))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)

                UPLine()
            }
        }
    }

    private var footer: some View {
        Text("共305位好友")
            .font(.system(size: 14))
            .foregroundStyle(UPColor.parse("#909399"))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
    }

    private func friendRow(_ friend: Friend) -> some View {
        HStack(spacing: 10) {
            UPImage(src: friend.url, width: 35, height: 35, radius: 3)

            Text(friend.name)
                .font(.system(size: 16))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
