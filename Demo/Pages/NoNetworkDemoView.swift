import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/noNetwork/noNetwork`。
@MainActor
struct NoNetworkDemoView: View {
    @State private var network = UPNoNetwork(status: .wifi)
    @State private var customImageNetwork = UPNoNetwork(status: .offline,
                                                       tips: "网络连接已断开，请检查后重试",
                                                       image: NoNetworkDemoView.offlineImage,
                                                       zIndex: "10090")
    @State private var eventLog = "尚未触发"
    @State private var statusTick = 0

    private static let offlineImage = "https://uview-plus.jiangruyi.com/common/logo.png"

    private static let statuses: [(label: String, value: UPNetworkStatus)] = [
        ("wifi", .wifi),
        ("cellular", .cellular),
        ("wired", .wired),
        ("offline", .offline),
        ("unknown", .unknown)
    ]

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                network
                    .id(statusTick)

                HStack(spacing: 8) {
                    ForEach(Self.statuses, id: \.label) { item in
                        UPButton(size: "mini", text: item.label) {
                            network.update(item.value)
                            statusTick += 1
                        }
                    }
                }

                Text("上游示例依赖 uni-app 的 onNetworkStatusChange，需要断开 WiFi 与数据连接才能看到效果。这里用按钮直接切换网络状态。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("网络正常时的页面内容") {
                VStack(spacing: 15) {
                    UPIcon(name: "checkbox-mark", color: "#fff", size: "30")
                        .frame(width: 60, height: 60)
                        .background(UPColor.parse("success"))
                        .clipShape(Circle())

                    Text("网络正常")
                        .font(.system(size: 15))
                        .foregroundStyle(UPColor.parse("success"))

                    Text("请您断开设备的WiFi和数据连接(或开启飞行模式)，即可看到效果")
                        .font(.system(size: 13))
                        .foregroundStyle(UPColor.parse("tips"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            DemoSection("自定义图片与层级") {
                customImageNetwork
                    .frame(maxWidth: .infinity)

                tip("上游 image 传入图片地址或 base64 时，会替换默认的断网插画，图标固定 size=\"150\"、imgMode=\"widthFit\"。")
                tip("zIndex 为 String | Number，传空串时回落 u-overlay 的默认层级 \(Int(UPNoNetwork().resolvedZIndex))；此处传 \"10090\" 覆盖为 \(Int(customImageNetwork.resolvedZIndex))。")
            }

            DemoSection("事件") {
                tip("emitEvent 按 networkType 是否为 'none' 抛 disconnected / connected；retry 会重新取一次状态、toast 后再抛 retry。")

                HStack(spacing: 8) {
                    UPButton(type: "primary", size: "mini", text: "retry（断网）") {
                        network.retry(status: .offline)
                        statusTick += 1
                    }
                    UPButton(type: "success", size: "mini", text: "retry（联网）") {
                        network.retry(status: .wifi)
                        statusTick += 1
                    }
                }

                Text("当前状态：\(String(describing: network.status))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("最近事件：\(eventLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("已支持 status / isOffline / tips / image / zIndex 与 connected / disconnected / retry 三个事件：image 为空时把 tips（默认与上游一致的「哎呀，网络信号丢失」）渲染进系统 ContentUnavailableView，非空时按上游布局渲染图片 + 14pt 提示语，下面再跟上游的「请检查网络，或前往 设置」一行与 mini plain 重试按钮。emitEvent 照抄上游按 networkType 是否为 'none' 二分，因此 unknown 也走 connected 分支。retry() 的顺序也照抄：先写状态、抛 connected/disconnected、toast，最后才抛 retry。openSettings() 在联网状态下直接 return，真正的跳转（上游走 5+ 的 plus 环境）由宿主通过 onOpenSettings 执行。retry 事件上游只写在文档注释的 @event 里，emits 数组没声明，但方法体确实 emit，原生按实际行为建模。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: bindEvents)
    }

    private func bindEvents() {
        network = network.onChange { status in
            eventLog = status == .offline ? "disconnected · \(status)" : "connected · \(status)"
        }
        network = network
            .onConnected { eventLog = "connected" }
            .onDisconnected { eventLog = "disconnected" }
            .onRetry { eventLog = "retry" }
            .onOpenSettings { eventLog = "openSettings（宿主负责跳转）" }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
