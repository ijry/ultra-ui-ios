import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/cell/cell`。
struct CellDemoView: View {
    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPCellGroup {
                    UPCell(title: "单元格")
                    UPCell(title: "单元格", value: "内容")
                    UPCell(title: "单元格", label: "描述信息")
                }
            }

            DemoSection("带图标与箭头") {
                UPCellGroup {
                    UPCell(title: "个人信息", icon: "account", isLink: true)
                    UPCell(title: "设置", icon: "setting", isLink: true)
                    UPCell(title: "帮助", value: "常见问题", icon: "question-circle", isLink: true)
                }
            }

            DemoSection("分组标题") {
                UPCellGroup(title: "分组一") {
                    UPCell(title: "选项 A")
                    UPCell(title: "选项 B")
                }
            }

            DemoSection("必填与禁用") {
                UPCellGroup {
                    UPCell(title: "必填项", required: true)
                    UPCell(title: "禁用项", disabled: true)
                }
            }
        }
    }
}
