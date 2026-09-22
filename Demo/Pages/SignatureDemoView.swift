import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/signature/signature`。
@MainActor
struct SignatureDemoView: View {
    /// 上游画板是 700×200 rpx，原生 `UPUnit` 按 375 设计基准折算后仍偏宽，
    /// 这里按屏宽给到 330×200。
    @State private var basic = UPSignature(width: 330)
    @State private var custom = UPSignature(width: 330, bgColor: "#f7f8fa", color: "#ff0000", thickness: 6)
    @State private var plain = UPSignature(width: 330, height: 120, showToolbar: false)
    @State private var log = "尚未导出"
    @State private var tick = 0

    var body: some View {
        DemoPage {
            UPAlert(description: "在画板上拖动即可签名，工具栏依次是撤销、清空、笔画粗细、颜色与导出")

            DemoSection("基础签名示例") {
                basic
                    .id(tick)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(UPColor.parse("#e0e0e0"), lineWidth: 1)
                            .allowsHitTesting(false)
                    }

                tip("width 330 · height 200 · color #000000 · thickness 3 · showToolbar true")
                tip(log)
            }

            DemoSection("自定义颜色和底色") {
                custom
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(UPColor.parse("#e0e0e0"), lineWidth: 1)
                            .allowsHitTesting(false)
                    }

                tip("bgColor #f7f8fa · color #ff0000 · thickness 6；改色改粗只影响后续笔画。")
            }

            DemoSection("隐藏工具栏") {
                plain
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(UPColor.parse("#e0e0e0"), lineWidth: 1)
                            .allowsHitTesting(false)
                    }

                HStack(spacing: 12) {
                    UPButton(size: "small", text: "撤销一笔") { plain.undo() }
                    UPButton(size: "small", text: "清除签名") { plain.clear() }
                    UPButton(type: "primary", size: "small", text: "导出") {
                        log = plain.exportSignature().map { "confirm：\($0)" } ?? "签名为空，未导出"
                    }
                }

                tip("showToolbar 为 false 时由宿主自己调 undo() / clear() / exportSignature()。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPSignature 已覆盖上游 6 个 prop：width / height / bgColor / color / thickness / showToolbar（另把 presetColors 从 data 提成 prop），事件为 onClear / onConfirm((String) -> Void) / onError，方法 undo() / clear() / selectColor(_:) / setLineWidth(_:) / toggleBrushSettings() / toggleColorSettings() / exportSignature(scale:)，并保留仓库既有的 addStroke / exportData / strokes / isEmpty。上游用 canvas 的 touchstart/move/end 收笔、exportImage 出临时文件，原生用 Canvas 渲染加 DragGesture 收笔、ImageRenderer 出 PNG 写临时目录，confirm 负载同样是文件路径。每笔会记下当时的颜色与粗细，改设置后旧笔画不变，与上游一致；bgColor 仍是默认白底时会跟随暗色主题换成 #1c1c1e。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: bindEvents)
    }

    private func bindEvents() {
        basic = basic
            .onConfirm { path in log = "confirm：\(path)" }
            .onClear { log = "clear：已清空" }
            .onError { message in log = "error：\(message)" }
        tick += 1
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
