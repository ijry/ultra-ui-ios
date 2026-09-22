import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/cateTab/cateTab`。
@MainActor
struct CateTabDemoView: View {
    private static let cover = "https://uview-plus.jiangruyi.com/uview/ext/59c256f85a8c3757.jpg"

    /// 上游 `tabList` 是「栏目 + children」的对象数组。
    private static let tabList: [UPCateTabItem] = (1...4).map { index in
        UPCateTabItem(title: "选项\(["一", "二", "三", "四"][index - 1])",
                      children: (1...6).map { child in
                          UPCateTabChild(name: "菜品 \(index)-\(child)",
                                         icon: CateTabDemoView.cover,
                                         id: "\(index)-\(child)")
                      })
    }

    @State private var current = 0
    @State private var changeLog = "尚未切换"

    var body: some View {
        DemoPage {
            DemoSection("基础使用（follow 联动）") {
                UPCateTab(tabList: Self.tabList, height: "420")
                    .onChangePayload { change in
                        current = change.index
                        changeLog = "index=\(change.index) title=\(change.item.title)"
                    }
                    .frame(height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                tip("左栏点击滚到对应分组，右栏滚动反查高亮左栏（对应上游 rightScroll）。")
                tip("最近切换：\(changeLog)")
            }

            DemoSection("tab 模式（只显示当前分组）") {
                UPCateTab(tabList: Self.tabList, mode: "tab", height: "320", current: current)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                tip("mode 为 tab 时右侧只铺当前分组，不做滚动联动。")
            }

            DemoSection("对象数组 + keyName") {
                UPCateTab(tabList: [["label": "热菜"], ["label": "凉菜"]],
                          children: [
                              [["dish": "水煮肉片", "icon": Self.cover], ["dish": "酸菜鱼", "icon": Self.cover]],
                              [["dish": "拍黄瓜", "icon": Self.cover]]
                          ],
                          height: "280",
                          tabKeyName: "label",
                          itemKeyName: "dish")
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                tip("tabKeyName / itemKeyName 指定从对象里取哪个字段当标题与子项名。")
            }

            DemoSection("自定义插槽") {
                UPCateTab(tabList: Self.tabList, height: "320")
                    .tabItem { item in
                        VStack(spacing: 2) {
                            Text(item.title).font(.system(size: 13))
                            Text("\(item.children.count) 项")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .pageItem { child in
                        HStack(spacing: 6) {
                            UPImage(src: child.icon, mode: "aspectFill", width: 32, height: 32, radius: 4)
                            Text(child.name).font(.system(size: 12))
                        }
                        .padding(6)
                    }
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                tip("tabItem / rightTop / itemList / pageItem 四个作用域插槽都可用。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPCateTab 已覆盖上游 6 个 prop：mode / height / tabList / tabKeyName / itemKeyName / current，`update:current` 落成 current 绑定与 onChange / onChangePayload，四个作用域插槽 tabItem / rightTop / itemList / pageItem 都提供。左右分栏、左栏选中态（白底 + 主题色竖线）、按 rpx 折算的 200rpx 宽与 110rpx 行高都照抄上游 CSS。上游用 selectorQuery 量每组的 top 再在 rightScroll 里比对区间，原生用 GeometryReader 记录偏移、滚动探针反查，判断式连 `!height2` 对 0 也成立这一点都照抄。仓库既有的 items: [String] / [UPCateTabItem] 与 Binding<Int> 三个初始化器保留。")
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
