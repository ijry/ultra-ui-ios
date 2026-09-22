import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/navbar/navbar`。
@MainActor
struct NavbarDemoView: View {
    @State private var eventLog = "尚未触发"

    var body: some View {
        DemoPage {
            DemoSection("基础功能") {
                UPNavbar(placeholder: false, fixed: false, title: "个人中心")
                    .onLeftClick { eventLog = "点击了左侧区域" }
                    .onRightClick { eventLog = "点击了右侧区域" }

                Text("最近事件：\(eventLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("自定义文本") {
                UPNavbar(
                    placeholder: false, fixed: false, leftText: "返回",
                    rightText: "问题", rightIcon: "map", title: "个人中心"
                )
                .onLeftClick { eventLog = "返回" }
                .onRightClick { eventLog = "问题" }
            }

            DemoSection("自定义插槽") {
                HStack(spacing: 0) {
                    UPIcon(name: "arrow-left", size: "19")
                    UPLine(length: "16", direction: "column", margin: 8)
                    UPIcon(name: "home", size: "20")
                    Spacer()
                    Text("个人中心")
                        .font(.system(size: 16))
                    Spacer()
                    UPIcon(name: "map", size: "19")
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color(.systemBackground))

                Text("原生 UPNavbar 暂无 left/right 插槽，这里用 UPIcon + UPLine 手工拼出上游 left 插槽的效果。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("自定义标题样式与背景") {
                UPNavbar(
                    placeholder: false, fixed: false, border: true, title: "标题居中",
                    bgColor: "#3c9cff",
                    titleStyle: UPStyle(["color": "#ffffff"])
                )
            }

            UPGap(height: 50)

            DemoSection("当前原生范围") {
                Text("原生 UPNavbar 渲染左右按钮、标题与底部边框，leftIcon 固定使用 chevron.left（只判断是否为空），rightIcon 需为 SF Symbol 名。leftIconSize、leftIconColor、statusBarBgColor、safeAreaInsetTop、fixed、placeholder、autoBack 目前只作为参数保存，未落地视觉与页面栈行为。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
