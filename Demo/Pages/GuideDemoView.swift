import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/guide/guide`。
@MainActor
struct GuideDemoView: View {
    @State private var show = true
    @State private var current = 0
    @State private var indicator = true
    @State private var showSkip = true
    @State private var once = true
    @State private var lastEvent = "首次进入自动显示"

    private static let storageKey = "up-guide-demo"
    private static let cover = "https://uview-plus.jiangruyi.com/common/logo.png"

    private let steps = [
        UPGuideStep(id: "welcome", title: "欢迎使用 uview-plus", image: Self.cover, desc: "一套跨端可复用的高质量组件库。", backgroundColor: "#111111"),
        UPGuideStep(id: "pages", title: "引导页支持多页切换", image: Self.cover, desc: "可配置指示器、跳过与主按钮文案。", backgroundColor: "#2979FF"),
        UPGuideStep(id: "once", title: "只显示一次", message: "storage-key 记忆能力由 UserDefaults 承载。")
    ]

    var body: some View {
        ZStack {
            DemoPage {
                DemoSection("基础使用（首次进入显示）") {
                    UPButton(type: "primary", text: "打开引导（open）", block: true) {
                        current = 0
                        guide.open()
                        show = true
                        lastEvent = "open 打开引导"
                    }

                    UPButton(text: "重置记忆后打开（reset + open）", block: true) {
                        current = 0
                        guide.reset()
                        guide.open()
                        show = true
                        lastEvent = "reset + open 已清除 \(Self.storageKey)"
                    }

                    tip("记忆标记：\(guide.readRemembered() ? "已看过（once 生效）" : "未看过")")
                    tip("storage-key：\(guide.resolvedStorageKey) · z-index：\(Int(guide.zIndex))")
                    tip("事件：\(lastEvent)")
                    tip("once 为真且已记忆时，上游 bootstrap() 会拦下显示，需先 reset() 或关掉 once。")
                }

                DemoSection("底部与记忆开关") {
                    HStack {
                        Text("indicator 指示器").font(.system(size: 14))
                        Spacer()
                        UPSwitch(size: 20, modelValue: $indicator, space: "2")
                    }

                    HStack {
                        Text("showSkip 跳过按钮").font(.system(size: 14))
                        Spacer()
                        UPSwitch(size: 20, modelValue: $showSkip, space: "2")
                    }

                    HStack {
                        Text("once 只显示一次").font(.system(size: 14))
                        Spacer()
                        UPSwitch(size: 20, modelValue: $once, space: "2")
                    }

                    tip("关闭 once 后 skip / finish 不再写入记忆，每次进入都会展示。")
                }

                DemoSection("页面数据（list）") {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        tip("第 \(index + 1) 页：\(step.title.isEmpty ? "无标题" : step.title) · 背景 \(step.backgroundColor.isEmpty ? guide.bgColor + "（回落 bgColor）" : step.backgroundColor) · \(step.image.isEmpty ? "无图（占位「暂无引导图」）" : "配图")")
                    }
                }

                DemoSection("当前原生范围") {
                    Text("已覆盖 list（image/title/desc/backgroundColor）、show 双向绑定、once + storage-key 记忆、showSkip / skipText / nextText / finishText、indicator、bgColor、zIndex，以及 change/skip/finish/close/update:show 与 open()/close()/reset() 方法。上游 swiper 的横向滑动手势未原生化，翻页请用主按钮或 select(_:)/previous()。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            if show {
                guide

                VStack {
                    HStack(spacing: 8) {
                        UPButton(type: "info", size: "mini", plain: true, disabled: current == 0, text: "上一步") {
                            let instance = guide
                            if instance.previous() { current = instance.current }
                        }

                        ForEach(Array(steps.indices), id: \.self) { index in
                            UPButton(type: index == current ? "primary" : "info", size: "mini", plain: index != current, text: "第 \(index + 1) 页") {
                                let instance = guide
                                instance.select(index)
                                current = instance.current
                            }
                        }
                    }
                    .padding(.top, 8)

                    Spacer()
                }
            }
        }
    }

    private var guide: UPGuide {
        UPGuide(
            steps: steps,
            show: $show,
            storageKey: Self.storageKey,
            once: once,
            showSkip: showSkip,
            indicator: indicator,
            current: current
        )
        .onChange { index in
            current = index
            lastEvent = "change 到第 \(index + 1) 页"
        }
        .onSkip { lastEvent = "skip 跳过引导" }
        .onFinish { lastEvent = "finish 引导结束" }
        .onClose { lastEvent = "close 引导已关闭" }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
