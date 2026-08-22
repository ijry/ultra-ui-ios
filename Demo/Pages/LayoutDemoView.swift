import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/layout/layout`。
/// 上游 `u-col` 的 `gridNum` 默认 12，所以一行的 span 之和是 12（不是 24）。
struct LayoutDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("等分栅格") {
                UPRow {
                    UPCol(span: 6) { block("6") }
                    UPCol(span: 6) { block("6") }
                }
                UPRow {
                    UPCol(span: 4) { block("4") }
                    UPCol(span: 4) { block("4") }
                    UPCol(span: 4) { block("4") }
                }
                UPRow {
                    UPCol(span: 3) { block("3") }
                    UPCol(span: 3) { block("3") }
                    UPCol(span: 3) { block("3") }
                    UPCol(span: 3) { block("3") }
                }
            }

            DemoSection("间距 gutter") {
                UPRow(gutter: 10) {
                    UPCol(span: 4) { block("4") }
                    UPCol(span: 4) { block("4") }
                    UPCol(span: 4) { block("4") }
                }
            }

            DemoSection("偏移 offset") {
                UPRow {
                    UPCol(span: 3) { block("3") }
                    UPCol(span: 3, offset: 3) { block("offset 3") }
                }
            }

            DemoSection("水平对齐") {
                UPRow(justify: "center") {
                    UPCol(span: 4) { block("center") }
                }
                UPRow(justify: "flex-end") {
                    UPCol(span: 4) { block("end") }
                }
            }
        }
    }

    private func block(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 12))
            .foregroundStyle(.white)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(UPColor.parse("primary"))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
