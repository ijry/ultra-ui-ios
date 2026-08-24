import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/cascader/cascader`。
///
/// `UPCascader` 目前是基线实现，用原生 `List` 平铺首层节点。
struct CascaderDemoView: View {
    @State private var value: [String] = []

    private let data = [
        UPCascaderNode(value: "zhejiang", label: "浙江", children: [
            UPCascaderNode(value: "hangzhou", label: "杭州", children: [
                UPCascaderNode(value: "xihu", label: "西湖区"),
                UPCascaderNode(value: "yuhang", label: "余杭区")
            ]),
            UPCascaderNode(value: "ningbo", label: "宁波")
        ]),
        UPCascaderNode(value: "jiangsu", label: "江苏", children: [
            UPCascaderNode(value: "nanjing", label: "南京"),
            UPCascaderNode(value: "suzhou", label: "苏州")
        ])
    ]

    var body: some View {
        DemoPage {
            DemoSection("级联数据") {
                UPCascader(data: data, modelValue: $value)
                    .frame(height: 160)
                Text(value.isEmpty ? "尚未选择" : "路径：\(value.joined(separator: " / "))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("说明") {
                Text("UPCascader 当前为基线实现，平铺展示首层节点。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
