import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/title/title`。
struct TitleDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("默认") {
                UPTitle {
                    Text("默认标题")
                        .font(.system(size: 15))
                }
            }

            DemoSection("自定义前缀") {
                UPTitle {
                    UPIcon(name: "level", color: "red", size: "16px")
                } content: {
                    Text("等级3")
                        .font(.system(size: 15))
                }
            }

            DemoSection("当前原生范围") {
                Text("上游 u-title 无 props 与 emits，只有默认插槽和 prefix 插槽；前缀默认是 4x18 的主色圆角条。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
