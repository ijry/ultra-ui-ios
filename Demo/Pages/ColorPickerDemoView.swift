import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/colorPicker/colorPicker`。
@MainActor
struct ColorPickerDemoView: View {
    private static let commonColors = [
        "#ff0000", "#00ff00", "#0000ff", "#ffff00",
        "#00ffff", "#ff00ff", "#ffffff", "#000000"
    ]

    @State private var basic = "#ff0000"
    @State private var custom = "#00ff00"
    @State private var gradient = "linear-gradient(to right, #ff0000 0%, #0000ff 100%)"
    @State private var slotted = "#3c9cff"
    @State private var eventLog = "尚未选择"

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                row(title: basic) {
                    UPColorPicker(color: $basic)
                        .onConfirm { eventLog = "confirm：\($0)" }
                        .onClose { eventLog = "close" }
                }

                tip("点击色块弹出取色面板：分段切纯色/渐变，饱和度方块、色相条与透明度条都可拖动。")
                tip("最近事件：\(eventLog)")
            }

            DemoSection("自定义常用颜色") {
                row(title: custom) {
                    UPColorPicker(color: $custom, commonColors: Self.commonColors)
                }

                tip("commonColors 由组件内部渲染成一排色板，点击直接落到当前色或编辑中的渐变节点。")
            }

            DemoSection("渐变色") {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [UPColor.parse("#ff0000"), UPColor.parse("#0000ff")],
                                             startPoint: .leading,
                                             endPoint: .trailing))
                        .frame(width: 56, height: 28)

                    Spacer()

                    UPColorPicker(color: $gradient, commonColors: Self.commonColors)
                }

                Text(gradient)
                    .font(.system(size: 12).monospaced())
                    .foregroundStyle(.secondary)

                tip("传入 linear-gradient(...) 时面板会自动切到渐变模式并还原节点与方向；节点最多 5 个、最少 2 个。")
            }

            DemoSection("自定义触发器") {
                UPColorPicker(color: $slotted, commonColors: Self.commonColors)
                    .trigger {
                        UPButton(type: "primary", size: "small", text: "选择颜色")
                    }

                Text(slotted)
                    .font(.system(size: 12).monospaced())
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPColorPicker 已覆盖上游 2 个 prop（modelValue 即 Binding<String>、commonColors）与 confirm / close / closed 三个事件，方法 open() / close() / confirm() / initColor() / changeColorType(_:) / setHue(_:) / setAlpha(_:) / setSaturationPoint(_:in:) / selectCommonColor(_:) / editStop(_:) / addStop() / removeStop(_:) / moveStop(_:percent:) / setDirection(_:)，另保留仓库既有的 select(_:) 与 onChange。数值模型走 UPColorMath：HSL ↔ RGB 与上游 hslToRgb 同算法，确认值同样是 rgba(r, g, b, a) 或 linear-gradient(dir, color pct%, ...)。两处差异：饱和度方块与三条滑轨用 DragGesture 取点，上游是 boundingClientRect 加 touch 坐标；圆形方向盘换成八个方向按钮，角度仍按上游 getDirectionAngle 定义。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func row(title: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(UPColor.parse(title))
                .frame(width: 28, height: 28)
                .overlay {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                }

            Text(title)
                .font(.system(size: 14).monospaced())

            Spacer()

            trailing()
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
