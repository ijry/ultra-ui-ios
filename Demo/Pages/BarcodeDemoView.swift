import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/barcode/barcode`。
@MainActor
struct BarcodeDemoView: View {
    @State private var eventLog = "尚未触发"
    @State private var exportedPath = ""

    var body: some View {
        DemoPage {
            DemoSection("CODE128 条形码") {
                UPBarcode(value: "1234567890", format: "CODE128", height: 70, fontSize: 16)
                    .onRendered { eventLog = "rendered · \($0.type) · \($0.id)" }
                    .onError { eventLog = "error · \($0.message)" }
            }

            DemoSection("EAN-13 条形码") {
                UPBarcode(value: "5901234123457", format: "EAN13", height: 70, fontSize: 16)
            }

            DemoSection("EAN-8 条形码") {
                UPBarcode(value: "96385074", format: "EAN8", height: 70, fontSize: 11)
            }

            DemoSection("UPC-A 条形码") {
                UPBarcode(value: "123456789012", format: "UPCA", height: 70, fontSize: 16)
            }

            DemoSection("CODE39 条形码") {
                UPBarcode(value: "CODE39", format: "CODE39", height: 70, fontSize: 16)
            }

            DemoSection("EAN-5 / EAN-2 补充码") {
                UPBarcode(value: "12345", format: "EAN5", width: 100, height: 60, fontSize: 14)
                UPBarcode(value: "12", format: "EAN2", width: 100, height: 60, fontSize: 14)
            }

            DemoSection("自定义样式条形码") {
                UPBarcode(
                    value: "CUSTOM123",
                    format: "CODE128",
                    width: 200,
                    height: 70,
                    textPosition: "top",
                    fontSize: 14,
                    background: "#F0F0F0",
                    lineColor: "#FF0000"
                )

                tip("textPosition 为 top 时条码整体下移一个 fontSize + textMargin，文字基线落在 marginTop + fontSize - 3。")
            }

            DemoSection("文本与边距") {
                UPBarcode(
                    value: "1234567890",
                    height: 60,
                    text: "自定义文本",
                    fontOptions: "bold",
                    textAlign: "left",
                    textMargin: 8,
                    margin: 4,
                    marginLeft: 24
                )

                tip("text 覆盖显示文案，fontOptions 支持 bold / italic，四个方向 margin 未给时都回落 margin。")

                UPBarcode(value: "1234567890", height: 60, displayValue: false)

                tip("displayValue 为假时不画文字，画布高度里也不再计入 fontSize + textMargin。")
            }

            DemoSection("编码失败") {
                UPBarcode(value: "123", format: "EAN13", height: 60)

                tip("EAN13 要求 13 位数字且校验位正确，编码失败时上游把 error.message 显示在灰底红字容器里。")
            }

            DemoSection("useCanvas 与导出") {
                let exporter = UPBarcode(value: "EXPORT123", height: 60, useCanvas: false)

                exporter

                UPButton(type: "primary", size: "small", text: "导出 PNG") {
                    if let event = exporter.exportImage() {
                        exportedPath = event.path
                        eventLog = "rendered · image"
                    } else {
                        eventLog = "导出失败"
                    }
                }

                if !exportedPath.isEmpty {
                    tip("已写入：\(exportedPath)")
                }

                tip("最近事件：\(eventLog)")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPBarcode 对齐上游 20 个属性与 rendered / error 两个事件：编码器逐位照抄上游那套手写实现（CODE128 Code B、CODE39、EAN13、EAN8、EAN5、EAN2、UPC、UPCA、UPCE），canvas 尺寸、模块宽度、条码 Y 与文字 X/Y 的公式也照抄，可单测。照抄的反直觉点有三处：format 的 validator 放行 ITF / MSI / pharmacode / codabar，但 encodeBarcode 的 switch 没有这些分支，实际都退回 CODE128；EAN5/EAN2 里算出的 patterns 压根没被用上，每位都走 leftOdd；UPCE 的 systemDigit 取出来没用、checkDigit 为 0/1/2/3 都落到同一个 pattern 分支。fontSize 那句 this.fontSize || 20 只在传 0 时才生效，正常路径仍是 prop 默认的 14。绘制换成 SwiftUI Canvas：canvas 的 fillText 以基线定位，SwiftUI 只能锚文本框，因此底部文字位置有亚像素级差异。useCanvas 为假时上游走离屏 canvas 导出临时图片，原生对应 exportImage()，用 ImageRenderer 写 PNG 到临时目录。fontOptions 只映射 bold / italic 两个关键字。")
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
