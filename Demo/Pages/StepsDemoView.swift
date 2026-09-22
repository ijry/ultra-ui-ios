import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/steps/steps`。
@MainActor
struct StepsDemoView: View {
    private static let basic: [(title: String, desc: String)] = [
        ("已下单", "10:30"), ("已出库", "10:35"), ("运输中", "11:40"),
        ("已签收", "19:50"), ("已拒收", "20:10"), ("已退回", "23:20")
    ]

    private static let short: [(title: String, desc: String)] = Array(basic.prefix(3))

    @State private var current1 = 1
    @State private var clickLog = "尚未点击"

    var body: some View {
        DemoPage {
            DemoSection("基础演示") {
                UPSteps(current: current1) {
                    ForEach(Array(Self.basic.enumerated()), id: \.offset) { index, step in
                        UPStepsItem(
                            title: step.title, desc: step.desc,
                            itemStyle: index == 0 ? UPStyle(["background-color": "#eeeeef"]) : UPStyle()
                        )
                        .onClick { clickLog = "点击了 \(step.title)" }
                    }
                }

                HStack(spacing: 8) {
                    UPButton(size: "mini", text: "上一步") {
                        current1 = max(0, current1 - 1)
                    }
                    UPButton(size: "mini", text: "下一步") {
                        current1 = min(Self.basic.count - 1, current1 + 1)
                    }
                }

                Text("current=\(current1)　\(clickLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("显示点类型") {
                UPSteps(current: 1, dot: true) {
                    stepItems(Self.short)
                }

                UPSteps(direction: "column", current: 1, dot: true) {
                    stepItems(Self.short)
                }
            }

            DemoSection("错误状态") {
                UPSteps(current: 1) {
                    UPStepsItem(title: "已下单", desc: "10:30")
                    UPStepsItem(title: "仓库着火", desc: "10:35", error: true)
                    UPStepsItem(title: "破产清算", desc: "11:40", error: true)
                }
            }

            DemoSection("自定义图标") {
                UPSteps(current: 1, activeIcon: "checkmark", inactiveIcon: "arrow-right") {
                    stepItems(Self.short)
                }
            }

            DemoSection("自定义插槽") {
                UPSteps(current: 2) {
                    UPStepsItem(title: "已下单", desc: "10:30")
                    UPStepsItem(title: "已出库", desc: "10:35")
                    UPStepsItem(title: "运输中", desc: "11:40")
                        .icon {
                            Text("运")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(UPColor.parse("warning"))
                                .clipShape(Circle())
                        }
                }

                tip("icon / title / desc 三个具名插槽与 content 作用域插槽（参数是 index）都可用；给了 content 就不再渲染标题与描述。")

                UPSteps(direction: "column", current: 1) {
                    UPStepsItem(title: "第一步")
                    UPStepsItem()
                        .stepContent { index in
                            HStack(spacing: 6) {
                                Text("自定义第 \(index + 1) 步")
                                    .font(.system(size: 14))
                                    .foregroundStyle(UPColor.parse("primary"))
                                UPTag(type: "warning", size: "mini", text: "进行中")
                            }
                        }
                    UPStepsItem(title: "第三步")
                }
            }

            DemoSection("自定义颜色") {
                UPSteps(current: 1, activeColor: "#3c9cff") {
                    stepItems(Self.short)
                }
            }

            DemoSection("竖向展示") {
                UPSteps(direction: "column", current: 1) {
                    stepItems(Self.short)
                }
            }

            DemoSection("当前原生范围") {
                Text("原生 UPSteps 对齐上游 7 个 props，UPStepsItem 对齐 5 个 props 与 icon / title / desc / content 四个插槽：序号圈（process 实心填 activeColor 并显示白色序号、wait 显示灰序号、finish 显示对勾、error 显示叉）、dot 模式的 10pt 圆点、activeIcon/inactiveIcon 的图标模式与连接线都已落地，尺寸与字号按上游 CSS 复刻（wrapper 20pt、圆点 10pt、序号 11pt、状态图标 12pt、连线 1pt 且偏移 10pt）。statusClass / statusColor / lineColor 三个推导都可单测。照抄上游两处反直觉：statusClass 里非当前项只要自身 error 为真就一律算 error（哪怕已经 finish），以及连线颜色看的是下一个兄弟节点的 error 而不是自己的。父子通信从 getParentData 换成 Environment 下发 + PreferenceKey 回报，因此 index 在首帧是 0、第二帧才稳定，与上游 mounted 里先 updateFromChild 再重排的两段式一致。UPStepsItem.onClick 是原生扩展，上游只在 H5 给标题加了 cursor: pointer，没有点击回调。")
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

    private func stepItems(_ steps: [(title: String, desc: String)]) -> some View {
        ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
            UPStepsItem(title: step.title, desc: step.desc)
        }
    }
}
