import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/color/color`。
/// 上游此页展示主题色板，取自 `UPTheme` 的语义色。
struct ColorDemoView: View {
    private let swatches: [(name: String, token: String)] = [
        ("primary", "primary"),
        ("success", "success"),
        ("error", "error"),
        ("warning", "warning"),
        ("info", "info")
    ]

    private let textTokens: [(name: String, token: String)] = [
        ("main", "main"),
        ("content", "content"),
        ("tips", "tips"),
        ("light", "light")
    ]

    var body: some View {
        DemoPage {
            DemoSection("主题色") {
                ForEach(swatches, id: \.token) { item in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(UPColor.parse(item.token))
                            .frame(width: 48, height: 32)
                        Text(item.name)
                            .font(.system(size: 14))
                    }
                }
            }

            DemoSection("文字色阶") {
                ForEach(textTokens, id: \.token) { item in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(UPColor.parse(item.token))
                            .frame(width: 48, height: 32)
                        Text(item.name)
                            .font(.system(size: 14))
                    }
                }
            }

            DemoSection("十六进制") {
                HStack(spacing: 12) {
                    ForEach(["#3c9cff", "#5ac725", "#f56c6c", "#f9ae3d"], id: \.self) { hex in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(UPColor.parse(hex))
                            .frame(width: 56, height: 32)
                    }
                }
            }
        }
    }
}
