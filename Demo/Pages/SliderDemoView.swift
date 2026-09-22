import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/slider/slider`。
@MainActor
struct SliderDemoView: View {
    @State private var basic: Double = 30
    @State private var stepped: Double = 4
    @State private var colored: Double = 60
    @State private var custom: Double = 45
    @State private var verticalValue: Double = 40
    @State private var nativeValue: Double = 55
    @State private var range = UPSliderRangeValue(lower: 20, upper: 70)
    @State private var eventLog = "尚未触发"

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPSlider(modelValue: $basic)
                    .onStart { eventLog = "start" }
                    .onChanging { eventLog = "changing：\(Int($0))" }
                    .onChange { eventLog = "change：\(Int($0))" }

                tip("当前值：\(Int(basic))")
                tip("事件：\(eventLog)")
            }

            DemoSection("步长 2，范围 0–10") {
                UPSlider(modelValue: $stepped, min: 0, max: 10, step: 2)
                tip("当前值：\(Int(stepped))")
            }

            DemoSection("显示数值") {
                UPSlider(modelValue: $colored, showValue: true)
                tip("非区间时数值渲染在轨道右侧（上游 .u-slider__show-value）。")
            }

            DemoSection("自定义颜色") {
                UPSlider(
                    modelValue: $colored,
                    activeColor: "#5ac725",
                    inactiveColor: "#e4e7ed",
                    blockColor: "#ffffff"
                )

                tip("activeColor 是填充段、inactiveColor 是底轨、blockColor 是滑块。")
            }

            DemoSection("滑块大小与轨道高度") {
                UPSlider(modelValue: $custom, blockSize: 26, size: "6px")
                tip("blockSize 决定滑块直径与容器厚度；size 决定轨道粗细，height 一给就盖掉 size。")

                UPSlider(modelValue: $custom, blockSize: 20, height: "10px")
                tip("height = 10px 时轨道变成 10pt 粗。")
            }

            DemoSection("自定义滑块样式") {
                UPSlider(
                    modelValue: $custom,
                    blockSize: 24,
                    activeColor: "#f9ae3d",
                    blockStyle: UPStyle(["borderRadius": "4px"])
                )

                tip("blockStyle 直接叠在滑块上，可改圆角、边框等。")
            }

            DemoSection("区间选择") {
                UPSlider(rangeValue: $range, showValue: true)
                    .onRangeChanging { eventLog = "range changing：\(Int($0.lower))–\(Int($0.upper))" }
                    .onRangeChange { eventLog = "range change：\(Int($0.lower))–\(Int($0.upper))" }

                tip("区间：\(Int(range.lower)) – \(Int(range.upper))")
                tip("区间 + showValue 时上游给容器多留 24pt 放两个数值标签。")
            }

            DemoSection("纵向") {
                UPSlider(modelValue: $verticalValue, vertical: true, length: "160px")
                    .frame(height: 200)

                tip("vertical 为真时轨道竖排，length 决定轨道长度（默认 auto 随容器）。")
            }

            DemoSection("useNative") {
                UPSlider(modelValue: $nativeValue, showValue: true, useNative: true)
                tip("useNative 为真且非区间时上游直接用平台原生 slider，原生这边落到 SwiftUI 的 Slider。")
            }

            DemoSection("禁用") {
                UPSlider(value: 40, disabled: true)
                tip("disabled 时整块 opacity 0.5，手势全程空转。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPSlider 覆盖上游全部 17 个 prop 与 start / changing / change 三个事件（区间另有 rangeChanging / rangeChange）。本轮补自绘渲染：底轨 __base 取 inactiveColor、填充段 __gap 取 activeColor 并带 0.2s 过渡、滑块 __button 是 blockSize 直径的圆点（scale 0.9 + 一层浅阴影，可被 blockStyle 覆盖），容器按 innerStyleCpu 取 blockSize 厚度、区间 + showValue 时多留 24pt。sizeLocal（height 优先于 size）、sliderLength 的占比公式、touchButtonStyle 的半个 blockSize 偏移与 onTouchMove 的 (distance / trackLength) × (max - min) + min 换算都可单测。useNative 为真且非区间时退回 SwiftUI 原生 Slider，与上游走 <slider> 的分支对应。上游 onTouchStart2 / onTouchMove2 / onTouchEnd2 三个方法体全被注释掉了（空实现），故不建模。")
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
