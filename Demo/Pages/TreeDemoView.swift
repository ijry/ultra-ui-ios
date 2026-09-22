import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/tree/tree`。
@MainActor
struct TreeDemoView: View {
    private nonisolated static let treeData: [UPTreeNode] = [
        UPTreeNode(id: "1", title: "一级 1", children: [
            UPTreeNode(id: "1-1", title: "二级 1-1", children: [
                UPTreeNode(id: "1-1-1", title: "三级 1-1-1"),
                UPTreeNode(id: "1-1-2", title: "三级 1-1-2")
            ]),
            UPTreeNode(id: "1-2", title: "二级 1-2")
        ]),
        UPTreeNode(id: "2", title: "一级 2", children: [
            UPTreeNode(id: "2-1", title: "二级 2-1"),
            UPTreeNode(id: "2-2", title: "二级 2-2")
        ])
    ]

    private nonisolated static let checkTreeData: [UPTreeNode] = [
        UPTreeNode(id: "2", title: "表单组件", children: [
            UPTreeNode(id: "2-1", title: "输入组件", children: [
                UPTreeNode(id: "2-1-1", title: "Input 输入框"),
                UPTreeNode(id: "2-1-2", title: "Textarea 文本域")
            ]),
            UPTreeNode(id: "2-2", title: "选择组件", children: [
                UPTreeNode(id: "2-2-1", title: "Select 选择器"),
                UPTreeNode(id: "2-2-2", title: "Picker 选择器", disabled: true)
            ])
        ])
    ]

    private nonisolated static let accordionTreeData: [UPTreeNode] = [
        UPTreeNode(id: "a", title: "导航组件", children: [
            UPTreeNode(id: "a-1", title: "Navbar 导航栏"),
            UPTreeNode(id: "a-2", title: "Tabbar 底部导航栏")
        ]),
        UPTreeNode(id: "b", title: "反馈组件", children: [
            UPTreeNode(id: "b-1", title: "Toast 消息提示"),
            UPTreeNode(id: "b-2", title: "Notify 通知")
        ])
    ]

    /// 上游 `props` 的字段名映射：数据用自定义键名时由 `UPTreeNode.nodes(from:props:)` 转换。
    private nonisolated static var mappedTreeData: [UPTreeNode] {
        UPTreeNode.nodes(
            from: [
                [
                    "code": "custom-1",
                    "name": "设计资源",
                    "list": [
                        ["code": "custom-1-1", "name": "组件规范"],
                        ["code": "custom-1-2", "name": "图标资产", "locked": true]
                    ]
                ]
            ],
            props: UPTreeProps(label: "name", children: "list", nodeKey: "code", disabled: "locked")
        )
    }

    @State private var checkedIDs: Set<String> = ["2-1-1"]
    @State private var nodeLog = "尚未点击"
    @State private var checkLog = "尚未变化"
    @State private var currentLog = "尚未切换"
    @State private var strictTree = UPTree(
        data: TreeDemoView.checkTreeData,
        showCheckbox: true,
        defaultExpandAll: true,
        checkStrictly: true
    )
    @State private var tick = 0

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                tip("expandOnClickNode 默认为真，点整行即展开；highlightCurrent 打开后当前行有底色。")

                UPTree(
                    data: Self.treeData,
                    defaultExpandedKeys: ["1"],
                    highlightCurrent: true
                )
                .onNodeClick { nodeLog = "node-click：\($0.title)" }
                .onExpand { nodeLog = "node-expand：\($0.title)" }
                .onCollapse { nodeLog = "node-collapse：\($0.title)" }
                .onCurrentChange { node, old in
                    currentLog = "current-change：\(old?.title ?? "无") → \(node.title)"
                }
                .frame(height: 220)

                tip(nodeLog)
                tip(currentLog)
            }

            DemoSection("自定义节点") {
                tip("默认作用域插槽拿到 node / level / expanded / checked / indeterminate / disabled。")

                UPTree(data: Self.mappedTreeData, defaultExpandAll: true, highlightCurrent: true)
                    .nodeContent { item in
                        HStack(spacing: 6) {
                            Text(item.node.title)
                                .font(.system(size: 14))
                                .foregroundStyle(UPColor.parse("main"))

                            Text("L\(item.level + 1)")
                                .font(.system(size: 11))
                                .foregroundStyle(UPColor.parse("primary"))

                            if item.disabled {
                                Text("禁用")
                                    .font(.system(size: 11))
                                    .foregroundStyle(UPColor.parse("error"))
                            }
                        }
                    }
                    .frame(height: 150)

                tip("这一组数据用 code / name / list / locked 作为字段名，由 props 映射成节点。")
            }

            DemoSection("复选框与级联") {
                tip("非严格模式下勾选向下铺开、向上推导；被禁用的子节点既不跟随，也不参与父节点判定。")

                UPTree(
                    data: Self.checkTreeData,
                    showCheckbox: true,
                    defaultExpandAll: true,
                    defaultCheckedKeys: Array(checkedIDs),
                    checkedIDs: $checkedIDs
                )
                .onCheckChange { node, checked in
                    checkLog = "check-change：\(node.title) → \(checked ? "选中" : "取消")"
                }
                .onCheck { _, info in
                    checkLog += "　半选 \(info.halfCheckedKeys.count) 个"
                }
                .frame(height: 260)
                .id(tick)

                HStack(spacing: 8) {
                    UPButton(type: "primary", size: "mini", text: "设置选中") {
                        checkedIDs = ["2-1-2", "2-2-1"]
                        tick += 1
                    }
                    UPButton(size: "mini", text: "读取选中") {
                        checkLog = "读取到 \(checkedIDs.sorted().joined(separator: "、"))"
                    }
                }

                tip("当前选中：\(checkedIDs.sorted().joined(separator: "、"))")
                tip(checkLog)
            }

            DemoSection("checkStrictly 父子不联动") {
                strictTree
                    .frame(height: 220)
                    .id(tick)

                tip("checkStrictly 为真时勾父不带子、勾子不推父，也不会产生半选态。")
            }

            DemoSection("手风琴模式") {
                tip("accordion 为真时同级只能展开一个。")

                UPTree(data: Self.accordionTreeData, accordion: true, highlightCurrent: true)
                    .onNodeClick { nodeLog = "node-click：\($0.title)" }
                    .frame(height: 180)
            }

            DemoSection("缩进与图标") {
                tip("indent 纯数字时按 rpx 处理，每层乘层级；expandIcon / collapseIcon 换成任意图标名。")

                UPTree(
                    data: Self.treeData,
                    defaultExpandAll: true,
                    indent: "48",
                    iconSize: 18,
                    expandIcon: "plus",
                    collapseIcon: "minus"
                )
                .frame(height: 240)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPTree 对齐上游 18 个属性与 node-click / check-change / check / node-expand / node-collapse / current-change 六个事件，以及默认作用域插槽和 getCheckedNodes / getCheckedKeys / getHalfCheckedNodes / getHalfCheckedKeys / setCheckedKeys / setChecked / setCurrentKey / getCurrentKey / getCurrentNode 这一组方法。上游把 expanded / checked / indeterminate 写在克隆节点上，原生数据保持只读、三种状态放进以 key 为索引的集合里，级联规则逐条照抄：向下铺开跳过 disabled 子节点，父节点的全选/半选判定也只看未禁用的子节点。props 是字段名映射，Swift 侧节点强类型，因此映射只在 UPTreeNode.nodes(from:props:) 从字典构造时生效；nodeKey 缺值时上游用「父key-下标-自增序号」兜底，原生用「父key-下标」。渲染换成 ScrollView + VStack，放进 Demo 页仍需固定高度。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
