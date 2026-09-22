import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/countDown/countDown`。
struct CountDownDemoView: View {
    @StateObject private var manualController = UPCountDownController(
        time: 3_000,
        format: "ss:SSS",
        autoStart: false,
        millisecond: true
    )
    @State private var eventText = "尚未完成"

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPCountDown(
                    time: 30 * 60 * 60 * 1_000,
                    format: "HH:mm:ss",
                    autoStart: true,
                    millisecond: true
                )
            }

            DemoSection("自定义格式") {
                UPCountDown(
                    time: 30 * 60 * 60 * 1_000,
                    format: "DD:HH:mm:ss",
                    autoStart: true,
                    millisecond: true
                ) { timeData in
                    HStack(spacing: 10) {
                        timeLabel(timeData.days, unit: "天")
                        timeLabel(timeData.hours, unit: "时")
                        timeLabel(timeData.minutes, unit: "分")
                        timeLabel(timeData.seconds, unit: "秒")
                    }
                }
            }

            DemoSection("毫秒级渲染") {
                UPCountDown(
                    time: 30 * 60 * 60 * 1_000,
                    format: "HH:mm:ss:SSS",
                    autoStart: true,
                    millisecond: true
                )
            }

            DemoSection("自定义样式") {
                UPCountDown(
                    time: 30 * 60 * 60 * 1_000,
                    format: "HH:mm:ss",
                    autoStart: true,
                    millisecond: true
                ) { timeData in
                    HStack(spacing: 6) {
                        timeBox(timeData.hours)
                        Text(":").foregroundStyle(Color.blue)
                        timeBox(timeData.minutes)
                        Text(":").foregroundStyle(Color.blue)
                        timeBox(timeData.seconds)
                    }
                }
            }

            DemoSection("手动控制") {
                UPCountDown(
                    time: 3_000,
                    format: "ss:SSS",
                    autoStart: false,
                    millisecond: true,
                    controller: manualController
                )
                .onFinish {
                    eventText = "倒计时已完成"
                }

                HStack(spacing: 10) {
                    UPButton(size: "small", text: "重置") {
                        manualController.reset()
                        eventText = "已重置"
                    }
                    UPButton(type: "primary", size: "small", text: "开始") {
                        manualController.start()
                        eventText = "运行中"
                    }
                    UPButton(size: "small", text: "暂停") {
                        manualController.pause()
                        eventText = "已暂停"
                    }
                }

                Text("状态：\(eventText) · 剩余 \(Int(manualController.remainingTime))ms")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func timeLabel(_ value: Int, unit: String) -> some View {
        HStack(spacing: 2) {
            Text("\(value)")
            Text(unit)
        }
        .font(.system(size: 14))
        .foregroundStyle(.secondary)
    }

    private func timeBox(_ value: Int) -> some View {
        Text(value < 10 ? "0\(value)" : "\(value)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 24)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
