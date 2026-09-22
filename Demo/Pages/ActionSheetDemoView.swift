import SwiftUI
import UltraUI

struct ActionSheetDemoView: View {
    @State private var showBasic = false
    @State private var showStatus = false
    @State private var showCancel = false
    @State private var showDescription = false
    @State private var showCustom = false
    @State private var lastSelection = "尚未选择"
    @State private var lastEvent = "尚未关闭"
    @State private var cityValue = ""

    private let cityOptions = [
        UPActionSheetAction(name: "北京", values: ["name": "北京", "value": "bj"]),
        UPActionSheetAction(name: "上海", values: ["name": "上海", "value": "sh"]),
        UPActionSheetAction(name: "广州", values: ["name": "广州", "value": "gz"])
    ]

    private let standardActions = [
        UPActionSheetAction(name: "选项 1"),
        UPActionSheetAction(name: "选项 2"),
        UPActionSheetAction(name: "选项 3", subname: "描述文本")
    ]

    private let statusActions = [
        UPActionSheetAction(name: "可用选项"),
        UPActionSheetAction(name: "加载中", loading: true),
        UPActionSheetAction(name: "已禁用", disabled: true)
    ]

    var body: some View {
        ZStack {
            DemoPage {
                DemoSection("基础用法") {
                    UPButton(type: "primary", text: "打开上拉菜单") {
                        showBasic = true
                    }

                    Text("选择结果：\(lastSelection)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                DemoSection("加载与禁用") {
                    UPButton(type: "primary", text: "查看选项状态") {
                        showStatus = true
                    }

                    Text("loading 和 disabled 项不会触发选择回调")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                DemoSection("取消按钮") {
                    UPButton(type: "primary", text: "显示取消按钮") {
                        showCancel = true
                    }
                }

                DemoSection("描述内容") {
                    UPButton(type: "primary", text: "显示描述") {
                        showDescription = true
                    }
                }

                DemoSection("自定义内容") {
                    UPButton(type: "primary", text: "打开自定义面板") {
                        showCustom = true
                    }

                    Text("最近事件：\(lastEvent)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                DemoSection("u-action-sheet-data 表单化用法") {
                    Text("上游 u-action-sheet-data 把面板包成一个只读输入框：点输入框打开面板，选中后按 valueKey 写回 modelValue、按 labelKey 回显。")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    UPActionSheetData(
                        modelValue: $cityValue,
                        title: "请选择城市",
                        description: "valueKey 默认 value、labelKey 默认 name",
                        options: cityOptions
                    )
                    .onChange { value in lastSelection = "action-sheet-data：\(value)" }

                    Text("当前 modelValue：\(cityValue.isEmpty ? "空" : cityValue)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    UPActionSheetData(
                        modelValue: $cityValue,
                        title: "自定义触发器",
                        options: cityOptions
                    )
                    .trigger {
                        HStack {
                            Text(cityValue.isEmpty ? "点我选择" : "已选 \(cityValue)")
                                .font(.system(size: 14))
                                .foregroundStyle(UPColor.parse("primary"))
                            Spacer()
                            UPIcon(name: "arrow-right", color: "#909193", size: "14")
                        }
                        .padding(.vertical, 10)
                    }

                    Text("trigger 插槽给了就不再渲染内建输入框，透明遮盖层仍负责接点击。")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            UPActionSheet(
                show: $showBasic,
                actions: standardActions,
                closeOnClickOverlay: false,
                onSelect: { action in
                    lastSelection = action.name
                },
                onClose: {
                    lastEvent = "基础菜单已关闭"
                }
            )

            UPActionSheet(
                show: $showStatus,
                title: "选项状态",
                actions: statusActions,
                cancelText: "取消",
                onSelect: { action in
                    lastSelection = action.name
                }
            )

            UPActionSheet(
                show: $showCancel,
                title: "带取消按钮",
                actions: standardActions,
                cancelText: "取消"
            )

            UPActionSheet(
                show: $showDescription,
                title: "描述内容",
                description: "这是一段描述文本，字号偏小，颜色偏淡。",
                actions: standardActions,
                cancelText: "取消"
            )

            UPActionSheet(
                show: $showCustom,
                title: "自定义内容",
                cancelText: "关闭",
                round: 12
            ) {
                VStack(spacing: 12) {
                    Text("这里是通过 SwiftUI slot 传入的内容")
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Button("完成") {
                        lastEvent = "自定义内容已确认"
                        showCustom = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }
}
