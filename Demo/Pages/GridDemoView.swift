import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/grid/grid`。
struct GridDemoView: View {
    private struct GridEntry: Identifiable {
        let id = UUID()
        let name: String
        let title: String
    }

    private static let baseList: [GridEntry] = [
        GridEntry(name: "photo", title: "图片"),
        GridEntry(name: "lock", title: "锁头"),
        GridEntry(name: "star", title: "星星"),
        GridEntry(name: "hourglass", title: "沙漏"),
        GridEntry(name: "home", title: "首页"),
        GridEntry(name: "volume", title: "音量")
    ]

    private static let swiperIcons = [
        "integral", "kefu-ermai", "coupon",
        "gift", "scan", "pause-circle",
        "wifi", "email", "list"
    ]

    @State private var clickLog = "尚未点击"

    var body: some View {
        DemoPage {
            DemoSection("基本案例") {
                UPGrid(
                    border: false,
                    align: "center",
                    onClick: { name in
                        clickLog = "grid click: \(name?.description ?? "-")"
                    }
                ) {
                    ForEach(Self.baseList) { item in
                        UPGridItem(name: item.title) {
                            gridCell(icon: item.name, title: item.title)
                        }
                    }
                }

                Text("最近点击：\(clickLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("显示边框") {
                UPGrid(border: true) {
                    ForEach(Self.baseList) { item in
                        UPGridItem(name: item.title) {
                            gridCell(icon: item.name, title: item.title)
                        }
                    }
                }
            }

            DemoSection("绑定点击事件 & 自定义列数") {
                UPGrid(
                    col: "4",
                    border: false,
                    onClick: { name in
                        clickLog = "col=4 click: \(name?.description ?? "-")"
                    }
                ) {
                    ForEach(Self.baseList) { item in
                        UPGridItem(name: item.title) {
                            gridCell(icon: item.name, title: item.title)
                        }
                    }
                }
            }

            DemoSection("自定义间距") {
                UPGrid(col: 3, gap: "10px") {
                    ForEach(Self.baseList) { item in
                        UPGridItem(name: item.title, bgColor: "#f3f4f6") {
                            gridCell(icon: item.name, title: item.title)
                        }
                    }
                }
            }

            DemoSection("可滑动") {
                TabView {
                    ForEach(Array(0..<3), id: \.self) { page in
                        UPGrid(border: true) {
                            ForEach(Array(Self.swiperIcons.enumerated()), id: \.offset) { index, icon in
                                UPGridItem(name: page * 9 + index) {
                                    gridCell(icon: icon, title: "宫格\(index + 1)")
                                }
                            }
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 240)
            }

            DemoSection("末行对齐（align）") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(["left", "center", "right"], id: \.self) { align in
                        Text("align = \(align)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        UPGrid(col: 3, align: align) {
                            ForEach(Self.baseList.prefix(4)) { item in
                                UPGridItem(name: item.title, bgColor: "#f3f4f6") {
                                    gridCell(icon: item.name, title: item.title)
                                }
                            }
                        }
                    }
                }
            }

            DemoSection("当前原生范围") {
                Text("已支持 col / border / align / gap 与 grid、gridItem 两级 click 事件（先 item 后 grid）。上游用 swiper 包裹宫格实现分页，这里换成原生 TabView(.page)。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func gridCell(icon: String, title: String) -> some View {
        VStack(spacing: 6) {
            UPIcon(name: icon, size: "22")
                .padding(.top, 10)

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(UPColor.parse("tips"))
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
    }
}
