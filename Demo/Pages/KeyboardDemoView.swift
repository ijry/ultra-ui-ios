import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/keyboard/keyboard`。
///
/// `UPKeyboard` 是自定义键盘容器：上游按 `mode` 把按键网格转发给
/// `u-number-keyboard`（number/card）或 `u-car-keyboard`（其余），
/// 自身只负责 popup 包装与顶部工具条。
@MainActor
struct KeyboardDemoView: View {
    @State private var showNumber = false
    @State private var input = ""
    @State private var mode = "number"
    @State private var dotDisabled = false
    @State private var random = false
    @State private var autoChange = true
    @State private var plate = ""
    @State private var directPlate = ""
    @State private var directNumber = ""
    @State private var lastEvent = "尚未触发"
    @State private var tick = 0

    private let modes = ["number", "card", "car"]

    private var numberKeys: [UPKeyboardKey] {
        (1...9).map { UPKeyboardKey(value: "\($0)") }
            + [
                UPKeyboardKey(value: "", label: "清空", kind: .cancel),
                UPKeyboardKey(value: "0"),
                UPKeyboardKey(value: "", label: "删除", kind: .delete)
            ]
    }

    var body: some View {
        DemoPage {
            DemoSection("按 mode 自动构建按键") {
                Picker("mode", selection: $mode) {
                    ForEach(modes, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)

                UPSwitch(modelValue: $dotDisabled)
                tip("dotDisabled = \(dotDisabled ? "true" : "false")：只在 mode = number 时生效，card 恒定保留 X。")

                UPSwitch(modelValue: $random)
                tip("random = \(random ? "true" : "false")：打乱按键顺序，车牌号的中文与英文两套网格都会被打乱。")

                UPKeyboard(show: true, mode: mode, dotDisabled: dotDisabled, random: random, autoChange: autoChange)
                    .onChange { lastEvent = "change：\($0)" }
                    .onBackspace { lastEvent = "backspace" }
                    .onCancel { lastEvent = "cancel" }
                    .onConfirm { lastEvent = "confirm" }
                    .id("\(mode)-\(dotDisabled)-\(random)-\(tick)")

                tip("事件：\(lastEvent)")
                UPButton(type: "default", size: "mini", text: "重新生成按键") { tick += 1 }
            }

            DemoSection("车牌号键盘与 autoChange") {
                UPSwitch(modelValue: $autoChange)
                tip("autoChange = \(autoChange ? "true" : "false")：只转发给车牌号键盘，输入一个中文后自动切到英文网格；关闭时停在中文网格，靠左上角「中/英」手动切。")

                Text(plate.isEmpty ? "尚未输入车牌" : "车牌：\(plate)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                UPKeyboard(show: true, mode: "car", autoChange: autoChange, tips: "请输入车牌号")
                    .onChange { plate += $0 }
                    .onBackspace { if !plate.isEmpty { plate.removeLast() } }
                    .onCancel { plate = "" }
                    .id("plate-\(autoChange)")
            }

            DemoSection("UPCarKeyboard 独立使用") {
                tip("车牌键盘自身按 10/10/10/6 切成四行，第四行整体居中、左端是「中/英」、右端是退格（都在上游的 v-for 之外）。")

                Text(directPlate.isEmpty ? "尚未输入" : "车牌：\(directPlate)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                UPCarKeyboard(modelValue: $directPlate, autoChange: autoChange)
                    .onChange { lastEvent = "change：\($0)" }
                    .onBackspace { lastEvent = "backspace：\($0)" }
                    .id("direct-\(autoChange)")

                tip("独立使用时不带提示行与安全区填充 —— 那两块属于外层 u-keyboard 的 popup 包装。")
            }

            DemoSection("UPNumberKeyboard 独立使用") {
                tip("三列网格，退格键在上游的 v-for 之外恒为灰底；非乱序时第 10 键在允许小数点/身份证 X 时变灰，number 模式隐藏小数点时它改成占双格宽。")

                Text(directNumber.isEmpty ? "尚未输入" : "已输入：\(directNumber)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                UPNumberKeyboard(modelValue: $directNumber, dotDisabled: dotDisabled)
                    .onChange { lastEvent = "change：\($0)" }
                    .onBackspace { lastEvent = "backspace：\($0)" }
                    .id("direct-number-\(dotDisabled)")

                tip("照抄上游：拉宽那条判定没有排除乱序，所以 random 为真时被打乱到下标 9 的键同样会被拉宽。")
            }

            DemoSection("弹出与收起") {
                UPButton(
                    type: "primary",
                    text: showNumber ? "收起键盘" : "展开键盘"
                ) {
                    showNumber.toggle()
                }

                Text(input.isEmpty ? "尚未输入" : "已输入：\(input)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                UPKeyboard(show: showNumber, mode: "number", keys: numberKeys)
                    .onInput { input += $0 }
                    .onDelete { if !input.isEmpty { input.removeLast() } }
                    .onCancel { input = "" }
                    .onConfirm { lastEvent = "confirm：\(input)" }

                tip("传入 keys 时容器不再自动补退格键与「中/英」，按键完全由宿主决定，本例用清空/删除两个功能键。")
            }

            DemoSection("提示文案随 mode 兜底") {
                tip("tips 为空串时上游按 mode 兜底：number → 数字键盘，card → 身份证键盘，其余一律车牌号键盘。")
                tip("当前 resolvedTips：\(UPKeyboard(mode: mode).resolvedTips)")

                UPKeyboard(show: true, tips: "请输入支付密码", cancelText: "关闭", confirmText: "提交", keys: numberKeys)
                    .onCancel { lastEvent = "cancel 自定义文案" }
                    .onConfirm { lastEvent = "confirm 自定义文案" }
            }

            DemoSection("隐藏工具条元素") {
                tip("showCancel = false 只隐藏左侧取消。")
                UPKeyboard(show: true, showCancel: false, keys: numberKeys)

                tip("tooltip = false 时整条工具条都不渲染。")
                UPKeyboard(show: true, tooltip: false, keys: numberKeys)
            }

            DemoSection("禁用") {
                UPKeyboard(show: true, disabled: true, keys: numberKeys)
                tip("禁用只拦按键与工具条；close / closed 是 popup 的容器事件，照旧转发。")
            }

            DemoSection("当前原生范围") {
                tip("已覆盖上游全部 16 个 prop：mode / dotDisabled / random / autoChange / tooltip / showTips / tips / showCancel / showConfirm / cancelText / confirmText / show / overlay / closeOnClickOverlay / safeAreaInsetBottom / zIndex，以及 change / backspace / confirm / cancel / close / closed 六个事件；未传 keys 时按 mode 自动构建网格并补退格键、车牌号的「中/英」切换，面板底色按上游 popupStyle 在暗色下取 #2c2c2e、浅色取 rgb(214,218,220)。UPCarKeyboard 独立使用时已按上游 CSS 复刻排版：按键 64rpx × 80rpx、功能键 134rpx、行内 10rpx 间距、底色取 --up-bg-color。上游的 popup 遮罩与上滑动画仍由 UPPopup 负责，本页把键盘直接内联渲染；上游长按退格是 250ms 定时器连删，原生只在长按满 0.25s 时多删一次。")
            }
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
