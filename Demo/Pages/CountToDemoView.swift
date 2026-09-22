import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/countTo/countTo`。
struct CountToDemoView: View {
    @StateObject private var manualController = UPCountToController(
        startVal: 0,
        endVal: 3_000,
        duration: 3_000,
        autoplay: false
    )
    @State private var eventText = "尚未开始"

    var body: some View {
        DemoPage {
            DemoSection("基础功能") {
                UPCountTo(endVal: 3_000)
                    .onEnd {
                        eventText = "基础动画已结束"
                    }
            }

            DemoSection("倒计数") {
                UPCountTo(startVal: 300, endVal: 0)
            }

            DemoSection("显示小数位") {
                UPCountTo(startVal: 100, endVal: 10.55, decimals: 2)
            }

            DemoSection("千分位分隔符") {
                UPCountTo(
                    startVal: 2_000,
                    endVal: 1_542,
                    decimals: 2,
                    separator: ","
                )
            }

            DemoSection("自定义控制") {
                UPCountTo(
                    endVal: 3_000,
                    duration: 3_000,
                    autoplay: false,
                    controller: manualController
                )
                .onEnd {
                    eventText = "手动动画已结束"
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    UPButton(type: "primary", size: "small", text: "开始", block: true) {
                        manualController.start()
                        eventText = "运行中"
                    }
                    UPButton(size: "small", text: "暂停", block: true) {
                        manualController.stop()
                        eventText = "已暂停"
                    }
                    UPButton(size: "small", text: "继续", block: true) {
                        manualController.resume()
                        eventText = "继续运行"
                    }
                    UPButton(size: "small", text: "重置", block: true) {
                        manualController.reset()
                        eventText = "已重置"
                    }
                }

                Text("状态：\(eventText) · 当前值 \(manualController.displayValue)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("自定义样式") {
                UPCountTo(
                    endVal: 3_000,
                    color: "#909399",
                    fontSize: 40,
                    bold: true
                )
            }
        }
    }
}
