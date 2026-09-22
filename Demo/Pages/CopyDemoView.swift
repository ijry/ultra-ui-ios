import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/copy/copy`。
@MainActor
struct CopyDemoView: View {
    @State private var lastCopied = "尚未复制"

    private let content = "uview-plus is great !"

    var body: some View {
        DemoPage {
            DemoSection("点击文字复制") {
                UPCopy(content: content) {
                    Text("点击复制")
                        .font(.system(size: 15))
                        .foregroundStyle(UPColor.parse("primary"))
                }
                .onSuccess {
                    lastCopied = "已复制文字：\(content)"
                }
            }

            DemoSection("点击按钮复制") {
                UPCopy(content: content) {
                    UPButton(type: "primary", text: "点击复制")
                        .allowsHitTesting(false)
                }
                .onSuccess {
                    lastCopied = "已通过按钮复制：\(content)"
                }

                Text(lastCopied)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("已展示 content 复制与 success 回调，剪贴板写入走 UIPasteboard。alertStyle 与 notice 只作为兼容参数保留，复制成功提示需宿主自行接入；按钮插槽用 allowsHitTesting(false) 让点击落到外层复制手势上。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
