import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/rate/rate`。
struct RateDemoView: View {
    @State private var lastValue: Double = 0

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPRate(value: 3)
            }

            DemoSection("自定义数量") {
                UPRate(value: 4, count: 7)
            }

            DemoSection("允许半星") {
                UPRate(value: 3.5, allowHalf: true)
            }

            DemoSection("自定义颜色") {
                UPRate(value: 4, inactiveColor: "#e4e7ed", activeColor: "#f56c6c")
                UPRate(value: 4, activeColor: "#5ac725")
            }

            DemoSection("自定义大小与间距") {
                UPRate(value: 3, size: 26, gutter: 12)
            }

            DemoSection("最少选中") {
                UPRate(value: 2, minCount: 2)
            }

            DemoSection("禁用与只读") {
                UPRate(value: 3, disabled: true)
                UPRate(value: 3, readonly: true)
            }

            DemoSection("自定义图标") {
                UPRate(value: 3, activeIcon: "heart-fill", inactiveIcon: "heart")
            }

            DemoSection("change 事件") {
                UPRate(value: 3, onChange: { lastValue = $0 })
                Text("当前值：\(lastValue, specifier: "%.1f")")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
