import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/empty/empty`。
struct EmptyDemoView: View {
    private static let iconBaseUrl = "https://uview-plus.jiangruyi.com/uview/empty/"
    private static let cellIconBaseUrl = "https://uview-plus.jiangruyi.com/uview/demo/empty/"

    private static let list: [(mode: String, title: String)] = [
        ("car", "购物车为空(同时传入slot)"),
        ("data", "数据为空"),
        ("comment", "评论为空"),
        ("coupon", "没有优惠券"),
        ("history", "无历史记录"),
        ("list", "列表为空"),
        ("message", "消息列表为空"),
        ("news", "无新闻列表"),
        ("order", "订单为空"),
        ("page", "页面不存在"),
        ("permission", "无权限"),
        ("search", "没有搜索结果"),
        ("wifi", "没有WiFi")
    ]

    @State private var mode = "car"

    var body: some View {
        DemoPage {
            DemoSection("演示效果") {
                if mode == "car" {
                    UPEmpty(icon: Self.iconBaseUrl + mode + ".png", mode: mode) {
                        UPButton(type: "primary", size: "small", text: "查看更多商品")
                            .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    UPEmpty(icon: Self.iconBaseUrl + mode + ".png", mode: mode)
                        .frame(maxWidth: .infinity)
                }

                Text("当前 mode=\(mode)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("切换空状态类型") {
                VStack(spacing: 0) {
                    ForEach(Self.list, id: \.mode) { item in
                        UPCell(
                            title: item.title,
                            isLink: true,
                            titleStyle: UPStyle(),
                            onTap: { mode = item.mode }
                        )
                        .icon {
                            UPImage(
                                src: Self.cellIconBaseUrl + item.mode + ".png",
                                mode: "widthFix", width: 22, height: 22
                            )
                        }
                    }
                }
            }

            DemoSection("内置文案") {
                Text("不传 text 时按 mode 取内置文案，例如 data → 数据为空、search → 没有搜索结果、message → 消息列表为空。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                HStack(spacing: 20) {
                    UPEmpty(mode: "data", width: 90, height: 90)
                    UPEmpty(mode: "search", width: 90, height: 90)
                }
            }

            DemoSection("当前原生范围") {
                Text("icon 含「/」时按图片加载，否则回退到内置 UPIcon 名（message 用 chat，其余用 empty-<mode>）。show=false 时不渲染，marginTop 与 customStyle 会应用到容器。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
