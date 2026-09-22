import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/box/box`。
struct BoxDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("基础功能") {
                UPBox(height: 160, gap: 12) {
                    Text("左")
                        .font(.system(size: 16))
                } rightTop: {
                    Text("右上")
                        .font(.system(size: 15))
                } rightBottom: {
                    Text("右下")
                        .font(.system(size: 15))
                }
            }

            DemoSection("默认图标与标题") {
                UPBox(
                    height: 150,
                    gap: 10,
                    leftIcon: "home",
                    leftTitle: "首页",
                    rightTopIcon: "setting",
                    rightTopTitle: "设置",
                    rightBottomIcon: "heart",
                    rightBottomTitle: "收藏"
                )
            }

            DemoSection("自定义插槽") {
                UPBox(height: 180, gap: 12) {
                    UPIcon(name: "arrow-left", size: "19")
                } rightTop: {
                    UPIcon(name: "arrow-left", size: "19")
                } rightBottom: {
                    UPIcon(name: "arrow-left", size: "19")
                }

                Text("left、rightTop 和 rightBottom 都可以替换为任意 SwiftUI 内容。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
