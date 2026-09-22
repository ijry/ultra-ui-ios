import SwiftUI
import UltraUI

struct AlertDemoView: View {
    @State private var showClosable = true
    @State private var eventText = "尚未操作"

    var body: some View {
        DemoPage {
            DemoSection("基础功能") {
                VStack(spacing: 10) {
                    UPAlert(description: "山不在于高，有了神仙就出名")
                    UPAlert(type: "primary", description: "水不在深，有龙则灵")
                    UPAlert(type: "error", description: "斯是陋室，惟吾德馨")
                    UPAlert(type: "info", description: "谈笑有鸿儒，往来无白丁")
                    UPAlert(type: "success", description: "可以调素琴，阅金经")
                }
            }

            DemoSection("深浅色") {
                VStack(spacing: 10) {
                    UPAlert(
                        type: "warning",
                        description: "无丝竹之乱耳，无案牍之劳形"
                    )
                    UPAlert(
                        type: "warning",
                        description: "南阳诸葛庐，西蜀子云亭",
                        effect: "dark"
                    )
                }
            }

            DemoSection("显示图标") {
                VStack(spacing: 10) {
                    UPAlert(
                        type: "error",
                        description: "六王毕，四海一；蜀山兀，阿房出",
                        showIcon: true
                    )
                    UPAlert(
                        type: "error",
                        description: "覆压三百余里，隔离天日",
                        showIcon: true,
                        effect: "dark"
                    )
                }
            }

            DemoSection("可关闭与事件") {
                if showClosable {
                    UPAlert(
                        show: $showClosable,
                        title: "提示",
                        type: "success",
                        description: "点击右侧关闭按钮，观察绑定和回调状态。",
                        closable: true,
                        showIcon: true,
                        onClose: {
                            eventText = "已触发 close"
                        },
                        onClosed: {
                            eventText = "已触发 closed"
                        }
                    )
                }

                UPButton(type: "primary", text: "重新显示") {
                    showClosable = true
                    eventText = "已重新显示"
                }

                Text("事件：\(eventText)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
