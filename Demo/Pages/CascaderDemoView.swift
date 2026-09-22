import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/cascader/cascader`。
@MainActor
struct CascaderDemoView: View {
    private nonisolated static let data = [
        UPCascaderNode(value: "zhejiang", label: "浙江", children: [
            UPCascaderNode(value: "hangzhou", label: "杭州", children: [
                UPCascaderNode(value: "xihu", label: "西湖区"),
                UPCascaderNode(value: "yuhang", label: "余杭区")
            ]),
            UPCascaderNode(value: "ningbo", label: "宁波", children: [
                UPCascaderNode(value: "haishu", label: "海曙区")
            ])
        ]),
        UPCascaderNode(value: "jiangsu", label: "江苏", children: [
            UPCascaderNode(value: "nanjing", label: "南京", children: [
                UPCascaderNode(value: "xuanwu", label: "玄武区")
            ]),
            UPCascaderNode(value: "suzhou", label: "苏州")
        ])
    ]

    @State private var value: [String] = []
    @State private var autoValue: [String] = ["zhejiang", "ningbo", "haishu"]
    @State private var columnValue: [String] = []
    @State private var showBasic = false
    @State private var showAuto = false
    @State private var showColumn = false
    @State private var eventLog = "尚未操作"

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                tip("点某项后截断其后所有层级：有子级就推进下一级并切 tab，没有子级就抛 change 但不关闭。")

                UPButton(type: "primary", text: "选择地区") { showBasic = true }

                UPCascader(
                    data: Self.data,
                    modelValue: $value,
                    showBinding: $showBasic
                )
                .onChange { eventLog = "change：\($0.joined(separator: " / "))" }
                .onConfirm { eventLog = "confirm：\($0.joined(separator: " / "))" }
                .onCancel { eventLog = "cancel" }

                tip(value.isEmpty ? "尚未选择" : "modelValue：\(value.joined(separator: " / "))")
                tip("最近事件：\(eventLog)")
            }

            DemoSection("autoClose 自动确认") {
                tip("选到最后一级时先抛 change 再直接 confirm 并关闭；默认值会回显成层级导航。")

                UPButton(text: "选择地区（自动确认）") { showAuto = true }

                UPCascader(
                    data: Self.data,
                    modelValue: $autoValue,
                    showBinding: $showAuto,
                    autoClose: true
                )
                .onConfirm { eventLog = "autoClose confirm：\($0.joined(separator: " / "))" }

                tip("modelValue：\(autoValue.joined(separator: " / "))")
            }

            DemoSection("竖向导航与单列") {
                tip("headerDirection 为 column 时顶部换成竖向 steps（点某级可跳回该级）；optionsCols 为 1 时只显示当前级。")

                UPButton(text: "竖向导航 + 单列") { showColumn = true }

                UPCascader(
                    data: Self.data,
                    modelValue: $columnValue,
                    showBinding: $showColumn,
                    headerDirection: "column",
                    optionsCols: 1
                )
                .onConfirm { eventLog = "column confirm：\($0.joined(separator: " / "))" }

                tip(columnValue.isEmpty ? "尚未选择" : "modelValue：\(columnValue.joined(separator: " / "))")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPCascader 对齐上游 12 个 props、change / confirm / cancel 三个事件（confirm 同时写回 modelValue、cancel 同时写回 show）与 levelChange / emitChange / handleConfirm / handleCancel / toFatherIndex 这套方法：层级推进与截断算法、genTabsList 的「请选择」占位规则、setDefaultValue 的逐级回显都照抄上游并可单测。渲染沿用 UPPopup 底部弹层 + UPTabs/UPSteps 导航 + UPCell 选项列 + 取消/确定按钮，两列模式按上游做 33.33% 宽与 tabsIndex > 1 时的整体左移。照抄上游一处反直觉：确认路径最后也会走 close()，因此 confirm 之后紧跟着还会抛一次 cancel；autoClose 时 emitChange 与 handleConfirm 各走一次 close，cancel 会连抛两次。上游 tabsChange 是空实现，原生保留同名入口。")
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
