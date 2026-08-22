# u-table2 全量对齐设计

> 上游基线：`uview-plus` 3.8.86，`components/u-table2/`（`u-table2.vue` 1106 行 + `tableRow.vue` 416 行）
> iOS 现状：`UPTable2.swift` 91 行
> 决策：**全量对齐（含固定列浮层）**、**照抄上游行为并注释标注**

## 审计结论（已逐条独立复核）

复核方式：直接 `grep -Fn 'emit('` 与逐段 `sed` 读取，不依赖二手结论。

1. **上游声明 11 个事件，实际只 emit 5 个。**
   真实：`current-change`(796)、`row-click`(798)、`sort-change`(814/830)、`selection-change`(856)、`select`(857)、`expand-change`(869)。
   死声明：`select-all`、`cell-click`、`row-dblclick`、`header-click`、`filter-change`。
   其中 `header-click` 尤其误导——`handleHeaderClick` 存在且已绑定在表头，但只做排序，从不 emit。

2. **不存在的功能**（`grep -cE "indeterminate|selectAll|toggleAllSelection|showSummary|summaryMethod|selectable"` → 两文件均 0）：
   全选、半选 indeterminate、合计行、`selectable` 行禁用回调。
   → 按 element-plus 直觉实现会造出上游没有的 API。

3. **`sortable: 'custom'` 不被特殊处理**：`!!column.sortable`（673 行），`'custom'` 是真值 → 走本地排序，没有「交给外部」的分支。

4. **排序第三态是删除条件，不是 `order: null`**：`splice(index,1)` 后 emit 并 return（812–817 行）。

5. **`selection-change` 早于 `select`**（856 → 857），与 element-plus 直觉相反。

## 载荷形状（照抄，不改造）

| 事件 | 上游载荷 | Swift 对应 |
| --- | --- | --- |
| `row-click` | 裸 `row` | `(UPTableRow) -> Void` |
| `current-change` | `(row, oldRow)` 两参；仅 `highlightCurrentRow` 为 true 时 emit | `(UPTableRow, UPTableRow?) -> Void` |
| `sort-change` | 整个 `sortConditions` 数组 `[{field, order, column}]` | `([UPTableSortCondition]) -> Void` |
| `selection-change` | `selectedRows` 数组 | `([UPTableRow]) -> Void` |
| `select` | 裸 `row`，**不带 selection** | `(UPTableRow) -> Void` |
| `expand-change` | `expandedKeys` **key 数组** | `([String]) -> Void` |

死声明的 5 个不实现，在文档注明原因。

## 分批

### 批次 1–2：排序与过滤
- `UPTableSortCondition { field, order, column }`
- 三态轮转：无 → `ascending` → `descending` → 删除条件
- `multiSort`：false 整体替换为单元素；true 原地改或 push
- `sortBy`：Function → `sortBy(row)`；非空 Array → `map.join("")`（**字符串拼接，数字会按串比**）；非空 String → `row[sortBy]`；否则 `row[field]`
- `sortMethod(a,b,field,context)`：**返回 0 时 fallthrough 到内置比较**，非 0 时返回值再乘方向系数
- `filters`：子串 `contains` 匹配，**只过滤顶层 data，不过滤子行**
- 顺序：`sortedData` 基于 `filteredData`

### 批次 3：选择、树形、懒加载
- 选择向下级联：选中/取消都递归全部后代；**不向上更新父行**
- `selection-change` 先、`select` 后
- `expand-change` 载荷为 key 数组；`expandedKeys` 是 flat 列表，**不同层级同 key 会一起展开**
- `level` 从 **1** 起算；缩进 `16*(level-1)+2`
- `hasTree` **只看第一层 children**（上游在 mounted+30ms 算一次）
- `computedMainCol` = `mainCol` 或首个**无 `type` 字段**列的 key
- `defaultExpandAll` 是 **merge 而非替换**，永不移除已展开项
- `load(row, {row, level, expanded, loading: true, context}, resolve)` 三参；`hasChildren` 占位

### 批次 4：props、固定列、空数据
- 34 个 props 与默认值；注意 `fixedHeader` 默认 **true**、`emptyText` 默认 `暂无数据`、`expandWidth` `25px`、`rowHeight` `36px`
- **`maxHeight` 直拼 `px`**（不走 addUnit）→ `'50vh'` 变 `'50vhpx'`。照抄并注释标注为上游笔误
- 左固定列：**仅严格字符串 `'left'`**（`true` 与 `'right'` 静默失效）；重复渲染浮层而非 sticky；`scrollLeft > 0` 才显形
- 空数据判定用**原始 `data`**，过滤后为空不显示 `emptyText`。照抄并注释
- slots：`header`、`headerSort`、`cell`（父行参数名 `prow`）、`empty`

### 批次 5：验证与记录
全量 `swift test` + Demo `xcodebuild`，更新进度表第 120 行，记录死声明事件与照抄的反直觉行为。

## 保留的源兼容

现有 `sortedRows(key:ascending:)`、`flattenedRows(expandedKeys:)`、`toggleSelection(_:)`、`triggerRowClick(_:)`、`UPFlattenedTableRow` 均保留为别名或转发，已有 3 个测试不得回归。

## 不做

- 不实现上游没有的全选/半选/合计行/`selectable`
- 不修正上游 bug（`tableRow.vue` 的 `getCellSpan` 对象分支 ReferenceError 等），仅在文档记录
- `spanMethod` 合并单元格仅在批次 4 做数据层，渲染层保持简化并注明
