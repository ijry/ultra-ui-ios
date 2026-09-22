import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/transition/transition`。
@MainActor
struct TransitionDemoView: View {
    private struct ModeEntry: Identifiable {
        let mode: String
        let iconName: String

        var id: String { mode }

        var iconUrl: String {
            "https://uview-plus.jiangruyi.com/uview/demo/transition/\(iconName).png"
        }
    }

    private static let modes: [ModeEntry] = [
        ModeEntry(mode: "fade", iconName: "fade"),
        ModeEntry(mode: "fade-up", iconName: "fadeUp"),
        ModeEntry(mode: "zoom", iconName: "zoom"),
        ModeEntry(mode: "fade-zoom", iconName: "fadeZoom"),
        ModeEntry(mode: "fade-down", iconName: "fadeDown"),
        ModeEntry(mode: "fade-left", iconName: "fadeLeft"),
        ModeEntry(mode: "fade-right", iconName: "fadeRight"),
        ModeEntry(mode: "slide-up", iconName: "slideUp"),
        ModeEntry(mode: "slide-down", iconName: "slideDown"),
        ModeEntry(mode: "slide-left", iconName: "slideLeft"),
        ModeEntry(mode: "slide-right", iconName: "slideRight")
    ]

    @State private var mode = "fade"
    @State private var show = false
    @State private var eventLog = "尚未播放"
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            DemoPage {
                DemoSection("点击任意模式播放 1.5 秒") {
                    UPCellGroup(border: true) {
                        ForEach(Self.modes) { entry in
                            UPCell(
                                title: entry.mode,
                                icon: entry.iconUrl,
                                isLink: true,
                                onTap: { play(entry.mode) }
                            )
                        }
                    }
                }

                DemoSection("生命周期事件") {
                    tip("当前 mode：\(mode)")
                    tip("最近事件：\(eventLog)")
                    tip("上游同页把 7 个事件都打到 console，这里改成显示最近一次触发的事件名，顺序是 beforeEnter → enter → afterEnter → beforeLeave → leave → afterLeave。")
                }

                DemoSection("当前原生范围") {
                    Text("mode 的 11 个内置模式、duration、timingFunction 与 7 个事件都已对齐，slide-top / slide-bottom / zoom-in / zoom-out 这些历史别名也会归一化到对应模式，未知模式回落成 fade。上游用 custom-style 把方块做成 position:fixed 的屏幕居中层，而原生 UPStyle 只支持 width / height / border-radius / color / background-color / opacity / padding / margin / text-align 这一小撮属性，不支持 position、百分比与渐变，所以这里把居中交给外层 ZStack，只用 customStyle 传 120×120 与 #1989fa 背景色。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            UPTransition(
                show: $show,
                mode: mode,
                duration: "300",
                customStyle: UPStyle([
                    "width": "120",
                    "height": "120",
                    "background-color": "#1989fa",
                    "border-radius": "8"
                ]),
                onClick: { eventLog = "click" },
                onBeforeEnter: { eventLog = "beforeEnter" },
                onEnter: { eventLog = "enter" },
                onAfterEnter: { eventLog = "afterEnter" },
                onBeforeLeave: { eventLog = "beforeLeave" },
                onLeave: { eventLog = "leave" },
                onAfterLeave: { eventLog = "afterLeave" }
            ) {
                Color.clear
            }
        }
        .onDisappear {
            hideTask?.cancel()
            hideTask = nil
        }
    }

    private func play(_ value: String) {
        hideTask?.cancel()
        mode = value
        show = true
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            show = false
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
