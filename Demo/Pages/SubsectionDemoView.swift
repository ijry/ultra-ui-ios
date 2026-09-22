import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/subsection/subsection`。
@MainActor
struct SubsectionDemoView: View {
    private static let list1 = ["未付款", "待评价", "已付款"]

    private static let list3: [UPSubsectionItem] = [
        UPSubsectionItem(name: "禁用", activeColorKey: "#FF4D4D"),
        UPSubsectionItem(name: "启用", activeColorKey: "#00CC88"),
        UPSubsectionItem(name: "未激活文字", inactiveColorKey: "#ff69b4")
    ]

    @State private var current1 = 0
    @State private var current2 = 0
    @State private var current3 = 0
    @State private var current4 = 1
    @State private var current5 = 0
    @State private var current6 = 0
    @State private var current7 = 0
    @State private var changeLog = "尚未切换"

    var body: some View {
        DemoPage {
            DemoSection("基础使用") {
                UPSubsection(list: Self.list1, current: $current1, mode: "subsection")
                    .onChangePayload { change in
                        changeLog = "index=\(change.index) name=\(change.item.name)"
                    }

                Text("最近切换：\(changeLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("按钮模式") {
                UPSubsection(list: Self.list1, current: $current2, mode: "button")
            }

            DemoSection("更换主题") {
                UPSubsection(list: Self.list1, current: $current3, activeColor: "#f56c6c")
            }

            DemoSection("默认位置") {
                UPSubsection(list: Self.list1, current: $current4, activeColor: "#f9ae3d")

                Text("初值 current=1，当前 index=\(current4)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("按钮模式通过list自定义颜色") {
                UPSubsection(
                    list: Self.list3, current: $current5,
                    mode: "button", activeColorKeyName: "textColor"
                )

                Text("每项可用 activeColorKey / inactiveColorKey 覆盖整体的激活与未激活文字色。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("禁用") {
                UPSubsection(list: Self.list1, current: $current6, mode: "subsection", disabled: true)
                UPSubsection(list: Self.list1, current: $current7, mode: "button", disabled: true)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPSubsection 用文字色与半透明背景表示选中，mode 影响间距、内边距与圆角；上游 subsection 模式里的滑块动画目前没有对应实现。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
