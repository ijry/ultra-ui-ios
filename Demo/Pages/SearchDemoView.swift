import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/search/search`。
struct SearchDemoView: View {
    @State private var basic = ""
    @State private var shaped = ""
    @State private var noAction = ""
    @State private var lastSearch = ""

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPSearch(value: $basic)
            }

            DemoSection("方形") {
                UPSearch(value: $shaped, shape: "square")
            }

            DemoSection("隐藏右侧按钮") {
                UPSearch(value: $noAction, showAction: false)
            }

            DemoSection("自定义按钮文字") {
                UPSearch(actionText: "搜一下")
            }

            DemoSection("对齐方式") {
                UPSearch(placeholder: "居中", inputAlign: "center")
            }

            DemoSection("禁用") {
                UPSearch(placeholder: "禁用状态", disabled: true)
            }

            DemoSection("搜索事件") {
                UPSearch(placeholder: "输入后点击搜索")
                    .onSearch { lastSearch = $0 }
                Text(lastSearch.isEmpty ? "尚未触发 search" : "最近搜索：\(lastSearch)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
