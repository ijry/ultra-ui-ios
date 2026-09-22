import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/notify/notify`。
struct NotifyDemoView: View {
    private struct NotifyOption: Identifiable {
        let id: String
        let title: String
        let message: String
        let type: String
        let duration: Int
        var color: String = "#ffffff"
        var bgColor: String = ""
        var fontSize: Double = 15
        var safeAreaInsetTop: Bool = false
    }

    @State private var current: NotifyOption?

    private let options: [NotifyOption] = [
        NotifyOption(id: "primary", title: "主要通知", message: "notify顶部提示", type: "primary", duration: 3_000),
        NotifyOption(id: "success", title: "成功通知", message: "notify顶部提示", type: "success", duration: 3_000),
        NotifyOption(id: "error", title: "危险通知", message: "notify顶部提示", type: "error", duration: 3_000, fontSize: 14),
        NotifyOption(id: "warning", title: "警告通知", message: "notify顶部提示", type: "warning", duration: 3_000),
        // 上游「自定义样式」项没有传 type，`deepMerge` 后仍是默认的 primary，只有 bgColor 覆盖底色。
        NotifyOption(id: "custom", title: "自定义样式", message: "notify顶部提示", type: "primary", duration: 3_000, color: "#fff", bgColor: "#000"),
        NotifyOption(id: "duration", title: "自定义时间", message: "notify顶部提示", type: "primary", duration: 6_000),
        NotifyOption(id: "safeArea", title: "插入状态栏高度", message: "notify顶部提示", type: "primary", duration: 3_000, color: "#fff", safeAreaInsetTop: true)
    ]

    var body: some View {
        ZStack(alignment: .top) {
            DemoPage {
                DemoSection("点击列表项从顶部弹出通知") {
                    UPCellGroup {
                        ForEach(options) { option in
                            UPCell(
                                title: option.title,
                                isLink: true,
                                titleStyle: UPStyle(["fontWeight": "500"]),
                                onTap: { open(option) }
                            )
                        }
                    }
                }

                DemoSection("样式说明") {
                    tip("bgColor 为空时底色跟随 type（primary/success/error/warning），非空则整体覆盖；图标尺寸恒为 1.3 × fontSize。")
                    tip("safeAreaInsetTop 为真时在文字上方插入状态栏高度；top 控制距顶部距离，层级固定 \(Int(UPNotify.overlayZIndex))。")
                }

                DemoSection("当前原生范围") {
                    tip("已覆盖 message、type、duration、top、color、bgColor、fontSize 与 safeAreaInsetTop。上游 H5 端 top 为 0 时回落 44px 导航栏高度，原生端按上游其它平台分支取 0。")
                }
            }

            if let current {
                UPNotify(
                    show: true,
                    message: "\(current.title)：\(current.message)",
                    type: current.type,
                    duration: current.duration,
                    color: current.color,
                    bgColor: current.bgColor,
                    fontSize: current.fontSize,
                    safeAreaInsetTop: current.safeAreaInsetTop
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: current?.id)
    }

    private func open(_ option: NotifyOption) {
        current = option
        let id = option.id
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(option.duration)) {
            if current?.id == id { current = nil }
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
