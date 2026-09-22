import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/qrcode/qrcode`。
@MainActor
struct QrcodeDemoView: View {
    private nonisolated static let value = "https://click.meituan.com/t?t=1&c=2&p=WhaD2b5zGU-h"
    private nonisolated static let logo = "https://uview-plus.jiangruyi.com/uview/common/logo.png"

    @State private var manual = UPQRCode(
        val: QrcodeDemoView.value,
        size: 150,
        onval: false,
        loadMake: false
    )
    @State private var eventLog = "尚未触发"
    @State private var tick = 0

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPQRCode(val: Self.value, size: 150)
                    .onResult { eventLog = "result：\(($0 as NSString).lastPathComponent)" }

                tip("val 与上游同页一致，size 150；loadMake 默认为真，出现即生成并抛 result。")
            }

            DemoSection("带 Logo") {
                UPQRCode(val: Self.value, size: 150, icon: Self.logo, iconSize: 36)

                tip("icon 与 iconSize 在中心叠一个带背景色圆角垫底的图标，落点是 (size - iconSize) / 2。")
            }

            DemoSection("自定义颜色") {
                UPQRCode(
                    val: Self.value,
                    size: 150,
                    background: "#fff7e6",
                    foreground: "#2979ff",
                    pdground: "#fa3534"
                )

                tip("background 是空格底色、foreground 是普通模块、pdground 只作用在三个定位角点的内圈。")
            }

            DemoSection("静区与纠错级别") {
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 6) {
                        UPQRCode(val: Self.value, size: 120, lv: .low)
                        tip("lv 0（L）")
                    }
                    VStack(spacing: 6) {
                        UPQRCode(val: Self.value, size: 120, lv: .high, quietZone: 4)
                        tip("lv 3（H）+ quietZone 4")
                    }
                }

                tip("lv 是 RS_BLOCK_TABLE 的档位下标（0=L、1=M、2=Q、3=H），quietZone 在四周多留几格空白。")
            }

            DemoSection("手动生成与导出") {
                manual
                    .onResult { eventLog = "result：\(($0 as NSString).lastPathComponent)" }
                    .onPreview { eventLog = $0.isEmpty ? "preview：还没有图" : "preview：\(($0 as NSString).lastPathComponent)" }
                    .onLongpressCallback { eventLog = "longpressCallback：\(($0 as NSString).lastPathComponent)" }
                    .id(tick)

                HStack(spacing: 8) {
                    UPButton(type: "primary", size: "mini", text: "生成") {
                        manual.makeCode()
                        tick += 1
                    }
                    UPButton(size: "mini", text: "清空") {
                        manual.clearCode()
                        tick += 1
                    }
                    UPButton(type: "success", size: "mini", text: "保存") {
                        let path = manual.saveCode()
                        eventLog = path.isEmpty ? "保存失败" : "已导出到 \((path as NSString).lastPathComponent)"
                        tick += 1
                    }
                }

                tip("loadMake / onval 都关掉后不再自动生成，只能手动调 makeCode()；长按二维码走 longpressCallback。")
                tip("最近事件：\(eventLog)")
            }

            DemoSection("useRootHeightAndWidth") {
                UPQRCode(val: Self.value, icon: Self.logo, useRootHeightAndWidth: true)
                    .frame(width: 120, height: 180)

                tip("开启后边长取根节点宽高里较短的一边，这里外框 120 × 180，实际边长 120。")
            }

            DemoSection("二维码内容") {
                Text(Self.value)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPQRCode 对齐上游 19 个属性与 result / preview / longpressCallback 三个事件，以及 makeCode / clearCode / toTempFilePath / saveCode 四个方法。上游用自带的 qrcode.js 算矩阵再往 canvas 逐格填色，原生改用 Core Image 的 CIQRCodeGenerator 拿矩阵、用 SwiftUI Canvas 按同一套规则重绘，因此 background / foreground / pdground / quietZone / icon 都能表达；lv 映射到 inputCorrectionLevel 的 L/M/Q/H，模块数由 Core Image 决定，与上游手写算法可能差一个版本档。getForeGround 的三段判定照抄成开区间，所以 pdground 实际只覆盖角点方块的内圈 3×3。cid 在原生没有 canvas 承载，仅作标识保留，默认值改为按内容取哈希以保持稳定；usingComponents 只影响上游那条 100ms/200ms 的回调延时，原生同步渲染因此不参与行为。saveCode 只负责导出临时 PNG 并 toast，写相册需要宿主自己申请权限。")
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
