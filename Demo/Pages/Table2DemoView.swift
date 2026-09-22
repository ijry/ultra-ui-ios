import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/table2/table2`。
struct Table2DemoView: View {
    @State private var onlyZhang = false
    @State private var sortDescending = false

    private let people = [
        UPTableRow(id: "1", values: ["name": "张三", "age": "25", "city": "北京"]),
        UPTableRow(id: "2", values: ["name": "李四", "age": "30", "city": "上海"]),
        UPTableRow(id: "3", values: ["name": "张小明", "age": "22", "city": "深圳"])
    ]

    private let columns = [
        UPTableColumn(key: "name", title: "姓名", width: "100px", align: "center"),
        UPTableColumn(key: "age", title: "年龄", width: "80px", align: "right"),
        UPTableColumn(key: "city", title: "城市", width: "100px")
    ]

    private let wideColumns = [
        UPTableColumn(key: "name", title: "姓名", width: "90px", fixed: "left"),
        UPTableColumn(key: "age", title: "年龄", width: "80px"),
        UPTableColumn(key: "city", title: "城市", width: "100px"),
        UPTableColumn(key: "department", title: "部门", width: "120px"),
        UPTableColumn(key: "role", title: "岗位", width: "120px")
    ]

    private let wideRows = [
        UPTableRow(
            id: "1",
            values: [
                "name": "张三", "age": "25", "city": "北京",
                "department": "技术部", "role": "iOS 工程师"
            ]
        ),
        UPTableRow(
            id: "2",
            values: [
                "name": "李四", "age": "30", "city": "上海",
                "department": "产品部", "role": "产品经理"
            ]
        )
    ]

    private let treeColumns = [
        UPTableColumn(key: "name", title: "名称", width: "150px", fixed: "left"),
        UPTableColumn(key: "age", title: "年龄", width: "80px"),
        UPTableColumn(key: "role", title: "类型", width: "100px")
    ]

    private let treeRows = [
        UPTableRow(
            id: "department-a",
            values: ["name": "部门 A", "age": "", "role": "部门"],
            children: [
                UPTableRow(
                    id: "employee-1",
                    values: ["name": "员工 1", "age": "22", "role": "成员"],
                    children: [
                        UPTableRow(
                            id: "intern-1",
                            values: ["name": "实习生 1", "age": "20", "role": "实习"]
                        )
                    ]
                ),
                UPTableRow(
                    id: "employee-2",
                    values: ["name": "员工 2", "age": "24", "role": "成员"]
                )
            ]
        ),
        UPTableRow(
            id: "department-b",
            values: ["name": "部门 B", "age": "", "role": "部门"]
        )
    ]

    var body: some View {
        DemoPage {
            DemoSection("基础表格（斑马纹 + 边框）") {
                UPTable2(
                    data: people,
                    columns: columns,
                    stripe: true,
                    border: true,
                    maxHeight: "210"
                )
            }

            DemoSection("排序与筛选") {
                Toggle("仅显示姓张", isOn: $onlyZhang)

                Picker("年龄排序", selection: $sortDescending) {
                    Text("升序").tag(false)
                    Text("降序").tag(true)
                }
                .pickerStyle(.segmented)

                UPTable2(
                    data: processedRows,
                    columns: columns,
                    stripe: true,
                    maxHeight: "180"
                )

                Text("结果：\(processedRows.count) 行")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("横向滚动与固定列元数据") {
                UPTable2(
                    data: wideRows,
                    columns: wideColumns,
                    maxHeight: "180"
                )

                Text("fixed: left → 姓名")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("树形结构") {
                UPTable2(
                    data: treeRows,
                    columns: treeColumns,
                    stripe: true,
                    maxHeight: "240",
                    expandedKeys: ["department-a", "employee-1"]
                )
            }

            DemoSection("rowStyle 与 rowClassName") {
                tip("rowStyle 支持对象与函数两种形态，函数入参是 { row, rowIndex, level, parentRow, context }。")

                UPTable2(data: people, columns: columns, context: ["scene": "demo"])
                    .rowStyle { scope in
                        UPStyle(["backgroundColor": scope.rowIndex % 2 == 0 ? "#ffffff" : "#f7fbff"])
                    }
                    .rowClassName { _, rowIndex, context in
                        "\(context["scene"] ?? "")-row-\(rowIndex)"
                    }

                tip("rowClassName / cellClassName / headerCellClassName 返回的是 class 名，原生没有 class 体系，值通过 resolvedXxx 方法暴露给页面自己用。")
            }

            DemoSection("cellStyle") {
                tip("cellStyle 的返回值会覆盖 cellStyleInner 先算出的 width / flex / paddingLeft。")

                UPTable2(data: people, columns: columns)
                    .cellStyle { scope in
                        scope.column.key == "age" && Int(scope.row["age"]) ?? 0 >= 30
                            ? UPStyle(["color": "#fa3534"])
                            : UPStyle()
                    }
            }

            DemoSection("spanMethod 合并单元格") {
                tip("spanMethod 返回 { rowspan, colspan }：任一为 0 时单元格 opacity 归零，大于 1 时按 rowHeight 折算高度、按 colspan 折算 flex。")

                UPTable2(data: people, columns: columns, rowHeight: "36px")
                    .spanMethod { scope in
                        // 第一行的城市列并进年龄列。
                        guard scope.rowIndex == 0 else { return UPTableCellSpan() }
                        if scope.column.key == "age" { return UPTableCellSpan(rowspan: 1, colspan: 2) }
                        if scope.column.key == "city" { return UPTableCellSpan(rowspan: 1, colspan: 0) }
                        return UPTableCellSpan()
                    }
            }

            DemoSection("当前原生范围") {
                Text("已展示数据、边框、斑马纹、排序筛选计算、横向滚动、树形展开，以及 context / rowStyle / cellStyle / cellClassName / headerCellClassName / rowClassName / spanMethod 这七个回调型属性。context 上游是 Object，原生收敛成字符串字典后原样透传给六个回调。三个 className 回调在上游返回的是 CSS class，原生没有 class 体系，因此只把值算出来交给页面，样式由 rowStyle / cellStyle 承担。spanMethod 照抄上游 getCellSpan 的兜底：返回 nil 等价于上游返回非数组非对象，都按 1×1 处理；rowspan 或 colspan 为 0 时上游是 opacity: 0 而不是真正移除单元格。复选框、固定列浮层与自定义单元格插槽目前仍只保留兼容 API。")
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

    private var processedRows: [UPTableRow] {
        let table = UPTable2(
            data: people,
            columns: columns,
            filters: onlyZhang ? ["name": "张"] : [:]
        )
        let order = sortDescending ? "descending" : "ascending"
        return table.sortedData(
            conditions: [UPTableSortCondition(field: "age", order: order)]
        )
    }
}
