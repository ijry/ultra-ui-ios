import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/popover/popover`。
@MainActor
struct PopoverDemoView: View {
    @State private var triggerMode = "click"
    @State private var manualShow = false
    @State private var lastEvent = "尚未触发"

    private let triggerModes = ["click", "longpress"]

    var body: some View {
        DemoPage {
            DemoSection("右侧弹出") {
                UPPopover(color: "#333",
                          bgColor: "#e3e4e6",
                          popupBgColor: "#f7f7f7",
                          direction: "right") {
                    UPButton(type: "primary", text: "点击")
                        .frame(width: 100)
                }
                .content {
                    Text("自定义内容")
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                }

                tip("默认 triggerMode 为 click，点击触发器展开，点击气泡外区域收起。")
            }

            DemoSection("左侧弹出及强制定位") {
                UPPopover(color: "#ffffff",
                          bgColor: "#333",
                          popupBgColor: "#333",
                          forcePosition: UPStyle(["right": "108px", "top": "0px"]),
                          direction: "left") {
                    UPButton(type: "primary", text: "点击")
                        .frame(width: 100)
                }
                .content {
                    Text("自定义内容")
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                tip("forcePosition 覆盖算出来的定位，这里等价于上游 `{right: '108px', top: '0px'}`。")
            }

            DemoSection("触发方式") {
                Picker("triggerMode", selection: $triggerMode) {
                    ForEach(triggerModes, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                UPPopover(text: "气泡内容", triggerMode: triggerMode, direction: "bottom") {
                    Text(triggerMode == "click" ? "点击我" : "长按我")
                        .font(.system(size: 14))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .onOpen { lastEvent = "open（\(triggerMode)）" }
                .onClose { lastEvent = "close（\(triggerMode)）" }
                .onClick { lastEvent = "click（\(triggerMode)）" }

                tip("上游只处理 click 与 longpress，hover 没有任何处理器，因此不会自动弹出。")
            }

            DemoSection("manual 手动控制") {
                UPPopover(show: manualShow,
                          text: "由宿主控制",
                          color: "#ffffff",
                          popupBgColor: "#060607",
                          triggerMode: "manual",
                          direction: "top") {
                    UPButton(type: "success", size: "small", text: manualShow ? "收起" : "展开") {
                        manualShow.toggle()
                    }
                    .frame(width: 100)
                }
                .onClose { manualShow = false }

                tip("上游 `watch.show` 只在 triggerMode 为 manual 时生效，其它模式下 show 变化会被忽略。")

                Text("最近事件：\(lastEvent)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("已覆盖 text/color/bgColor/popupBgColor/triggerMode/zIndex/forcePosition/direction 全部 10 个上游 prop、trigger 与 content 插槽、open/close/click 事件与幂等 guard。placement 与上游一致只作记录（u-tooltip 并未声明该 prop，定位由 direction 决定）；上游按 uni-app 测量做的屏幕边沿重定位（screenGap 12px）与 singleton 单例互斥不在原生范围内，气泡改由 SwiftUI overlay 对齐，点击外部拦截用透明层近似上游的 fixed 遮罩。")
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
