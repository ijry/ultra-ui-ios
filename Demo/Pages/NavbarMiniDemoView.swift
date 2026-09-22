import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/navbarMini/navbarMini`。
@MainActor
struct NavbarMiniDemoView: View {
    @State private var eventLog = "尚未触发"

    var body: some View {
        DemoPage {
            DemoSection("基础功能") {
                tip("上游是「返回箭头 + 竖分割线 + 首页图标」的胶囊：左半区抛 leftClick，右半区抛 homeClick。")

                HStack {
                    UPNavbarMini(
                        safeAreaInsetTop: false, fixed: false,
                        homeUrl: "/pages/index/index"
                    )
                    .onLeftClick { eventLog = "点击了返回" }
                    .onHomeClick { eventLog = "点击了首页（homeUrl /pages/index/index）" }

                    Spacer()
                }
                .padding(.vertical, 6)

                Text("最近事件：\(eventLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("覆盖在内容之上") {
                ZStack(alignment: .topLeading) {
                    UPImage(
                        src: "https://uview-plus.jiangruyi.com/uview/swiper/swiper1.png",
                        mode: "aspectFill", width: 320, height: 150, radius: 8
                    )

                    UPNavbarMini(safeAreaInsetTop: false, fixed: false)
                        .onLeftClick { eventLog = "覆盖层返回" }
                        .onHomeClick { eventLog = "覆盖层首页" }
                        .padding(12)
                }

                Text("上游示例把 mini 导航栏固定在顶部悬浮于页面内容之上，这里改为放在图片上以便在 Demo 页内看到效果。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("自定义样式") {
                HStack(spacing: 16) {
                    UPNavbarMini(
                        safeAreaInsetTop: false, fixed: false,
                        bgColor: "#00000026", height: "32px", iconSize: "20px", iconColor: "#ffffff"
                    )

                    UPNavbarMini(
                        safeAreaInsetTop: false, fixed: false,
                        bgColor: "#3c9cff", height: "36px", iconSize: "22px", iconColor: "#ffffff"
                    )
                }

                Text("默认 bgColor 是 rgba(0,0,0,.15)，原生 UPColor 只识别十六进制与语义色名，因此这里用等价的 #00000026。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("自定义插槽") {
                tip("left 与 center 是具名插槽，分别替换返回图标与首页图标。")

                HStack {
                    UPNavbarMini(safeAreaInsetTop: false, fixed: false, bgColor: "#00000026")
                        .left {
                            UPIcon(name: "arrow-left", color: "#ffffff", size: "19")
                        }
                        .center {
                            Text("首页")
                                .font(.system(size: 13))
                                .foregroundStyle(.white)
                        }
                        .onLeftClick { eventLog = "插槽返回" }
                        .onHomeClick { eventLog = "插槽首页" }

                    Spacer()
                }
            }

            UPGap(height: 50)

            DemoSection("当前原生范围") {
                Text("原生 UPNavbarMini 对齐上游 9 个属性、leftClick / homeClick 两个事件与 left / center 两个插槽：左右两半区分别可点，中间的竖分割线用 UPLine(direction: \"col\") 复刻。上游 leftClick 之后按 autoBack 调 navigateBack、homeClick 里按 homeUrl 调 reLaunch，页面栈归宿主掌握，原生只抛事件并保留这两个参数。上游 homeClick 虽在 emits 里声明，方法体却从未 $emit，原生按声明补上让宿主能接住点击。safeAreaInsetTop 与 fixed 目前只作为参数保存，不产生布局行为。")
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
