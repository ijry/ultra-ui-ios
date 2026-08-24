import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/slider/slider`。
struct SliderDemoView: View {
    @State private var basic: Double = 30
    @State private var stepped: Double = 4
    @State private var colored: Double = 60
    @State private var range = UPSliderRangeValue(lower: 20, upper: 70)

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPSlider(modelValue: $basic)
                Text("当前值：\(Int(basic))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("步长 2，范围 0–10") {
                UPSlider(modelValue: $stepped, min: 0, max: 10, step: 2)
                Text("当前值：\(Int(stepped))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("显示数值") {
                UPSlider(modelValue: $colored, showValue: true)
            }

            DemoSection("自定义颜色") {
                UPSlider(
                    modelValue: $colored,
                    activeColor: "#5ac725",
                    inactiveColor: "#e4e7ed",
                    blockColor: "#ffffff"
                )
            }

            DemoSection("自定义滑块大小与轨道高度") {
                UPSlider(modelValue: $basic, blockSize: 26, size: "6px")
                // UPSlider 目前一律渲染原生 SwiftUI Slider，blockSize / size /
                // blockColor / inactiveColor 等外观 prop 只作为兼容元数据保留，
                // 尚未接入渲染。要逐一生效需改为自绘轨道，属库层改动。
                Text("外观 prop 尚未接入渲染，当前与默认样式一致")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            DemoSection("区间选择") {
                UPSlider(rangeValue: $range)
                Text("区间：\(Int(range.lower)) – \(Int(range.upper))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("禁用") {
                UPSlider(value: 40, disabled: true)
            }
        }
    }
}
