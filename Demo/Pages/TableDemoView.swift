import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/table/table`。
struct TableDemoView: View {
    @State private var borderColor = "#e4e7ed"
    @State private var alignment = "center"

    private let rows = [
        ["吕布", "22", "楚河", "男"],
        ["项羽", "28", "汉界", "男"],
        ["木兰", "24", "南国", "女"]
    ]

    var body: some View {
        DemoPage {
            DemoSection("演示效果") {
                UPTable(borderColor: borderColor, align: alignment) {
                    UPTr {
                        UPTh { Text("姓名") }
                        UPTh { Text("年龄") }
                        UPTh { Text("籍贯") }
                        UPTh { Text("性别") }
                    }

                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        UPTr {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, value in
                                UPTd { Text(value) }
                            }
                        }
                    }
                }
            }

            DemoSection("边框颜色") {
                Picker("边框颜色", selection: $borderColor) {
                    Text("gray").tag("#e4e7ed")
                    Text("primary").tag("#2979ff")
                    Text("warning").tag("#ff9900")
                }
                .pickerStyle(.segmented)
            }

            DemoSection("对齐方式") {
                Picker("对齐方式", selection: $alignment) {
                    Text("左").tag("left")
                    Text("中").tag("center")
                    Text("右").tag("right")
                }
                .pickerStyle(.segmented)
            }
        }
    }
}
