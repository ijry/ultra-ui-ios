import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/textarea/textarea`。
struct TextareaDemoView: View {
    @State private var basic = ""
    @State private var counted = ""
    @State private var autoHeight = ""

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPTextarea(text: $basic, placeholder: "请输入内容")
            }

            DemoSection("字数统计") {
                UPTextarea(text: $counted, placeholder: "最多 50 字", maxlength: 50, count: true)
            }

            DemoSection("自动增高") {
                UPTextarea(text: $autoHeight, placeholder: "输入多行文本试试", autoHeight: true)
            }

            DemoSection("指定高度") {
                UPTextarea(placeholder: "高度 120", height: 120)
            }

            DemoSection("禁用与只读") {
                UPTextarea(placeholder: "禁用状态", disabled: true)
                UPTextarea(placeholder: "只读状态", readonly: true)
            }

            DemoSection("边框类型") {
                UPTextarea(placeholder: "bottom 底部边框", border: "bottom")
            }
        }
    }
}
