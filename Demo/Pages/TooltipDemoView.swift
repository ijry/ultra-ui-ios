import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/tooltip/tooltip`。
@MainActor
struct TooltipDemoView: View {
    @State private var clicked = "尚未点击"
    @State private var manualShow = false

    private let text1 = "长按文本，上方提示"
    private let text2 = "长按文本，下方提示"
    private let text3 = "显示多个扩展按钮"
    private let text5 = "长按文本，显示背景色"

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                UPTooltip(text: text1)
                    .padding(.top, 34)
            }

            DemoSection("下方显示") {
                UPTooltip(text: text2, direction: "bottom")
                    .padding(.bottom, 34)
            }

            DemoSection("扩展按钮") {
                UPTooltip(text: text3, buttons: ["扩展"])
                    .onClick { clicked = "click 下标：\($0)" }
                    .padding(.top, 34)

                tip(clicked)
                tip("复制固定占下标 0，扩展按钮从 1 起。")
            }

            DemoSection("多个扩展按钮") {
                UPTooltip(text: "自动调整气泡位置", buttons: ["扩展", "搜索", "翻译"])
                    .onClick { clicked = "click 下标：\($0)" }
                    .padding(.top, 34)
            }

            DemoSection("高亮选中文本背景色") {
                UPTooltip(text: text5,
                          bgColor: "#e3e4e6",
                          buttons: ["扩展", "搜索", "翻译"],
                          triggerMode: "click")
                    .padding(.top, 34)
            }

            DemoSection("单例打开") {
                HStack(spacing: 12) {
                    UPTooltip(text: "第一个", triggerMode: "click", singleton: true)
                    UPTooltip(text: "第二个", triggerMode: "click", singleton: true)
                }
                .padding(.top, 34)

                tip("同一时刻只有一个提示打开。")
            }

            DemoSection("自定义触发器") {
                UPTooltip(text: text5,
                          color: "#333",
                          bgColor: "#e3e4e6",
                          popupBgColor: "#f7f7f7",
                          direction: "right",
                          triggerMode: "click") {
                    UPButton(type: "primary", text: "点击")
                        .frame(width: 100)
                }
                .content {
                    Text("自定义内容")
                        .font(.system(size: 14))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                }
                .padding(.top, 34)
            }

            DemoSection("左侧弹出") {
                UPTooltip(text: text5,
                          color: "#fff",
                          bgColor: "#333",
                          popupBgColor: "#333",
                          direction: "left",
                          triggerMode: "click",
                          forcePosition: UPStyle(["right": "108", "top": "0"])) {
                    UPButton(type: "primary", text: "点击")
                        .frame(width: 100)
                }
                .content {
                    Text("自定义内容")
                        .font(.system(size: 14))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                }
                .padding(.top, 34)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            DemoSection("手动控制") {
                UPTooltip(text: "triggerMode 为 manual 时只跟随 show",
                          triggerMode: "manual",
                          show: manualShow)
                    .padding(.top, 34)

                UPButton(type: "primary", size: "small", text: manualShow ? "关闭" : "打开") {
                    manualShow.toggle()
                }
            }

            DemoSection("当前原生范围") {
                Text("原生 UPTooltip 已覆盖上游 16 个 prop：text / copyText / size / color / bgColor / popupBgColor / direction / zIndex / showCopy / buttons / overlay / showToast / triggerMode / forcePosition / show / singleton，事件为 onOpen / onClose / onClick((Int) -> Void)，方法 open() / close()（保留 showTooltip() / hideTooltip() 别名）与 copy() / tapButton(_:)。singleton 用 UPTooltipCenter 复刻上游模块级 activeSingletonTooltip 的互斥。上游会先把气泡挪到屏幕外量尺寸，再做贴边重定位（screenGap: 12），原生用对齐加偏移定位，不做贴边重算，需要精确位置时用 forcePosition（本页左侧弹出即如此）。overlay 上游是 position: fixed 的全屏透明层，原生用超大透明层近似同样的拦截范围。")
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
