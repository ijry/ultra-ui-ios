import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-tree` unit props.
public typealias UPTreeUnitValue = UPImageUnitValue

/// 上游 `props`：把节点对象里的字段名映射成 label / children / nodeKey / disabled。
///
/// Swift 侧节点是强类型的 `UPTreeNode`，字段名映射只在从字典构造节点时才有意义
/// （见 `UPTreeNode.nodes(from:props:)`），组件仍保留这个 prop 以对齐上游契约。
public struct UPTreeProps: Equatable, Sendable {
    public var label: String
    public var children: String
    public var nodeKey: String
    public var disabled: String

    public init(label: String = UPConfig.tree.labelKey,
                children: String = UPConfig.tree.childrenKey,
                nodeKey: String = UPConfig.tree.propsNodeKey,
                disabled: String = UPConfig.tree.disabledKey) {
        self.label = label
        self.children = children
        self.nodeKey = nodeKey
        self.disabled = disabled
    }
}

public struct UPTreeNode: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public var children: [UPTreeNode]
    public let disabled: Bool
    /// 上游 `clone.expanded === true`：数据里可以直接带展开态。
    public let expanded: Bool
    /// 上游 `clone.checked === true`：数据里可以直接带选中态。
    public let checked: Bool

    public init(id: String,
                title: String,
                children: [UPTreeNode] = [],
                disabled: Bool = false,
                expanded: Bool = false,
                checked: Bool = false) {
        self.id = id
        self.title = title
        self.children = children
        self.disabled = disabled
        self.expanded = expanded
        self.checked = checked
    }

    /// 上游 `cloneNodes` 那套「按 `props` 的字段名读取节点」的原生入口。
    ///
    /// 上游 `resolveNodeKey`：`nodeKey` 字段取不到值时用 `父key-下标-自增序号` 兜底，
    /// 这里同样在缺 key 时按 `父key-下标` 生成（原生不需要自增种子来避重）。
    public static func nodes(from dictionaries: [[String: Any]],
                            props: UPTreeProps = UPTreeProps(),
                            parentKey: String = "root") -> [UPTreeNode] {
        dictionaries.enumerated().map { index, dictionary in
            let rawKey = dictionary[props.nodeKey]
            let key: String
            if let value = rawKey as? String, !value.isEmpty {
                key = value
            } else if let value = rawKey as? Int {
                key = String(value)
            } else {
                key = "\(parentKey)-\(index)"
            }
            let children = dictionary[props.children] as? [[String: Any]] ?? []
            return UPTreeNode(
                id: key,
                title: dictionary[props.label] as? String ?? "",
                children: nodes(from: children, props: props, parentKey: key),
                disabled: dictionary[props.disabled] as? Bool ?? false,
                expanded: dictionary["expanded"] as? Bool ?? false,
                checked: dictionary["checked"] as? Bool ?? false
            )
        }
    }
}

/// 上游 `emitCheck` 第二个参数的四个字段。
public struct UPTreeCheckInfo: Equatable, Sendable {
    public var checkedNodes: [UPTreeNode]
    public var checkedKeys: [String]
    public var halfCheckedNodes: [UPTreeNode]
    public var halfCheckedKeys: [String]

    public init(checkedNodes: [UPTreeNode] = [],
                checkedKeys: [String] = [],
                halfCheckedNodes: [UPTreeNode] = [],
                halfCheckedKeys: [String] = []) {
        self.checkedNodes = checkedNodes
        self.checkedKeys = checkedKeys
        self.halfCheckedNodes = halfCheckedNodes
        self.halfCheckedKeys = halfCheckedKeys
    }
}

/// 上游 `visibleNodes` 的一项，也是默认插槽的作用域参数。
public struct UPTreeVisibleNode: Identifiable, Equatable, Sendable {
    public var key: String
    public var node: UPTreeNode
    /// 上游 `level` 从 0 起算，插槽里透出的是 `level + 1`。
    public var level: Int
    public var hasChildren: Bool
    public var expanded: Bool
    public var checked: Bool
    public var indeterminate: Bool
    public var disabled: Bool

    public var id: String { key }
}

@MainActor
@Observable
private final class UPTreeState {
    var expandedIDs: Set<String> = []
    var selectedIDs: [String] = []
    var checkedIDs: Set<String> = []
    /// 上游 `node.indeterminate`：半选态。
    var indeterminateIDs: Set<String> = []
    /// 上游 `currentKey`。
    var currentKey = ""
    var seeded = false
}

/// Native SwiftUI counterpart of uview-plus `u-tree`.
///
/// 上游把传入的 `data` 克隆一份，把 `expanded` / `checked` / `indeterminate` 直接写在
/// 克隆节点上，再用 `nodeMap` 反查父节点做级联。原生保持数据只读，把三种状态放进
/// 以 key 为索引的集合里，级联规则（跳过 disabled 子节点、父节点全选/半选推导）逐条照抄。
@MainActor
public struct UPTree: View {
    public var nodes: [UPTreeNode]
    /// 上游 `props`：字段名映射。
    public var props: UPTreeProps
    /// 上游 `nodeKey`：优先级高于 `props.nodeKey`。
    public var nodeKey: String
    public var showCheckbox: Bool
    public var defaultExpandAll: Bool
    public var defaultExpandedKeys: [String]
    public var defaultCheckedKeys: [String]
    /// 上游 `expandOnClickNode`：点整行是否切换展开。
    public var expandOnClickNode: Bool
    /// 上游 `checkOnClickNode`：点整行是否切换勾选。
    public var checkOnClickNode: Bool
    /// 上游 `checkStrictly`：为真时父子不再联动。
    public var checkStrictly: Bool
    /// 上游 `accordion`：同级只能展开一个。
    public var accordion: Bool
    public var highlightCurrent: Bool
    public var currentNodeKey: String
    /// 上游 `indent`：每层缩进，纯数字时按 rpx 处理。
    public var indent: String
    public var iconSize: String
    public var checkboxSize: String
    public var expandIcon: String
    public var collapseIcon: String
    /// 仓库既有属性：多选（作用在「选中行」而非复选框上）。
    public var multiple: Bool

    @State private var state: UPTreeState
    private var selectedIDsBinding: Binding<[String]>?
    private var checkedIDsBinding: Binding<Set<String>>?
    private var onSelectHandler: ((UPTreeNode) -> Void)?
    private var onNodeClickHandler: ((UPTreeNode) -> Void)?
    private var onCheckChangeHandler: ((UPTreeNode, Bool) -> Void)?
    private var onCheckHandler: ((UPTreeNode, UPTreeCheckInfo) -> Void)?
    private var onExpandHandler: ((UPTreeNode) -> Void)?
    private var onCollapseHandler: ((UPTreeNode) -> Void)?
    private var onCurrentChangeHandler: ((UPTreeNode, UPTreeNode?) -> Void)?
    private var nodeSlot: ((UPTreeVisibleNode) -> AnyView)?

    @Environment(\.upTheme) private var theme

    /// 与上游 `props` 对齐的初始化器。
    public init(data: [UPTreeNode],
                props: UPTreeProps = UPTreeProps(),
                nodeKey: String = UPConfig.tree.nodeKey,
                showCheckbox: Bool = UPConfig.tree.showCheckbox,
                defaultExpandAll: Bool = UPConfig.tree.defaultExpandAll,
                defaultExpandedKeys: [String] = [],
                defaultCheckedKeys: [String] = [],
                expandOnClickNode: Bool = UPConfig.tree.expandOnClickNode,
                checkOnClickNode: Bool = UPConfig.tree.checkOnClickNode,
                checkStrictly: Bool = UPConfig.tree.checkStrictly,
                accordion: Bool = UPConfig.tree.accordion,
                highlightCurrent: Bool = UPConfig.tree.highlightCurrent,
                currentNodeKey: any UPTreeUnitValue = UPConfig.tree.currentNodeKey,
                indent: any UPTreeUnitValue = UPConfig.tree.indent,
                iconSize: any UPTreeUnitValue = UPConfig.tree.iconSize,
                checkboxSize: any UPTreeUnitValue = UPConfig.tree.checkboxSize,
                expandIcon: String = UPConfig.tree.expandIcon,
                collapseIcon: String = UPConfig.tree.collapseIcon,
                multiple: Bool = false,
                selectedIDs: Binding<[String]>? = nil,
                checkedIDs: Binding<Set<String>>? = nil) {
        self.nodes = data
        self.props = props
        self.nodeKey = nodeKey
        self.showCheckbox = showCheckbox
        self.defaultExpandAll = defaultExpandAll
        self.defaultExpandedKeys = defaultExpandedKeys
        self.defaultCheckedKeys = defaultCheckedKeys
        self.expandOnClickNode = expandOnClickNode
        self.checkOnClickNode = checkOnClickNode
        self.checkStrictly = checkStrictly
        self.accordion = accordion
        self.highlightCurrent = highlightCurrent
        self.currentNodeKey = currentNodeKey.upImageUnitValue
        self.indent = indent.upImageUnitValue
        self.iconSize = iconSize.upImageUnitValue
        self.checkboxSize = checkboxSize.upImageUnitValue
        self.expandIcon = expandIcon
        self.collapseIcon = collapseIcon
        self.multiple = multiple
        self.selectedIDsBinding = selectedIDs
        self.checkedIDsBinding = checkedIDs
        self._state = State(initialValue: UPTree.seededState(
            data: data,
            defaultExpandAll: defaultExpandAll,
            defaultExpandedKeys: defaultExpandedKeys,
            defaultCheckedKeys: defaultCheckedKeys,
            checkStrictly: checkStrictly,
            currentNodeKey: currentNodeKey.upImageUnitValue,
            selectedIDs: selectedIDs?.wrappedValue ?? [],
            checkedIDs: checkedIDs?.wrappedValue
        ))
    }

    /// 仓库既有签名：只给节点与选中回调。
    public init(nodes: [UPTreeNode] = [], onSelect: ((UPTreeNode) -> Void)? = nil) {
        self.init(data: nodes)
        self.onSelectHandler = onSelect
    }

    /// 仓库既有签名。
    public init(nodes: [UPTreeNode] = [],
                multiple: Bool = false,
                selectedIDs: Binding<[String]>? = nil,
                checkedIDs: Binding<Set<String>>? = nil,
                showCheckbox: Bool = false,
                defaultExpandedIDs: Set<String> = [],
                onSelect: ((UPTreeNode) -> Void)? = nil) {
        self.init(data: nodes,
                  showCheckbox: showCheckbox,
                  defaultExpandedKeys: Array(defaultExpandedIDs),
                  defaultCheckedKeys: Array(checkedIDs?.wrappedValue ?? []),
                  multiple: multiple,
                  selectedIDs: selectedIDs,
                  checkedIDs: checkedIDs)
        self.onSelectHandler = onSelect
    }

    // MARK: - 初始状态

    /// 上游 `initTree` + `cloneNodes`：把默认展开/选中键与节点自带的标记合进状态，
    /// 非严格模式下再向下铺开选中、向上推导父节点。
    private static func seededState(data: [UPTreeNode],
                                    defaultExpandAll: Bool,
                                    defaultExpandedKeys: [String],
                                    defaultCheckedKeys: [String],
                                    checkStrictly: Bool,
                                    currentNodeKey: String,
                                    selectedIDs: [String],
                                    checkedIDs: Set<String>?) -> UPTreeState {
        let state = UPTreeState()
        state.selectedIDs = selectedIDs
        state.currentKey = currentNodeKey
        state.seeded = true

        var expanded: Set<String> = []
        var checked = checkedIDs ?? []
        walk(data) { node in
            if defaultExpandAll || defaultExpandedKeys.contains(node.id) || node.expanded {
                expanded.insert(node.id)
            }
            if defaultCheckedKeys.contains(node.id) || node.checked {
                checked.insert(node.id)
            }
        }
        if !checkStrictly {
            for id in checked {
                if let node = find(id, in: data) {
                    checkDescendants(node, checked: true, into: &checked)
                }
            }
            syncParentChecked(data, checked: &checked, indeterminate: &state.indeterminateIDs)
        }
        state.expandedIDs = expanded
        state.checkedIDs = checked
        return state
    }

    // MARK: - 只读状态

    public var expandedIDs: Set<String> { state.expandedIDs }
    public var selectedIDs: [String] { state.selectedIDs }
    public var checkedIDs: Set<String> { state.checkedIDs }
    /// 上游 `node.indeterminate`。
    public var indeterminateIDs: Set<String> { state.indeterminateIDs }
    /// 上游 `currentKey`。
    public var currentKey: String { state.currentKey }

    /// 上游 `keyField = nodeKey || props.nodeKey || 'id'`。
    public var keyField: String {
        if !nodeKey.isEmpty { return nodeKey }
        return props.nodeKey.isEmpty ? "id" : props.nodeKey
    }

    /// 上游 `visibleNodes`：只铺开已展开的分支。
    public var visibleNodes: [UPTreeVisibleNode] {
        var result: [UPTreeVisibleNode] = []
        collectVisibleNodes(nodes, level: 0, into: &result)
        return result
    }

    private func collectVisibleNodes(_ list: [UPTreeNode], level: Int, into result: inout [UPTreeVisibleNode]) {
        for node in list {
            result.append(UPTreeVisibleNode(key: node.id,
                                            node: node,
                                            level: level,
                                            hasChildren: !node.children.isEmpty,
                                            expanded: state.expandedIDs.contains(node.id),
                                            checked: state.checkedIDs.contains(node.id),
                                            indeterminate: state.indeterminateIDs.contains(node.id),
                                            disabled: node.disabled))
            if !node.children.isEmpty, state.expandedIDs.contains(node.id) {
                collectVisibleNodes(node.children, level: level + 1, into: &result)
            }
        }
    }

    /// 上游 `getIndentValue(level)`：数字前缀乘层级再拼单位，纯非数字原样返回。
    public func indentValue(level: Int) -> String {
        Self.indentValue(indent, level: level)
    }

    nonisolated static func indentValue(_ indent: String, level: Int) -> String {
        let digits = indent.prefix { $0.isNumber || $0 == "." }
        guard !digits.isEmpty, let number = Double(digits) else { return indent }
        let unit = String(indent.dropFirst(digits.count))
        let resolved = unit.isEmpty ? UPConfig.tree.indentUnit : unit
        let scaled = number * Double(level)
        let text = scaled.rounded() == scaled ? String(Int(scaled)) : String(scaled)
        return text + resolved
    }

    public func indentPadding(level: Int) -> CGFloat {
        max(UPUnit.parse(indentValue(level: level)), 0)
    }

    // MARK: - 遍历工具

    nonisolated static func walk(_ list: [UPTreeNode], _ body: (UPTreeNode) -> Void) {
        for node in list {
            body(node)
            walk(node.children, body)
        }
    }

    nonisolated static func find(_ id: String, in list: [UPTreeNode]) -> UPTreeNode? {
        for node in list {
            if node.id == id { return node }
            if let found = find(id, in: node.children) { return found }
        }
        return nil
    }

    nonisolated static func parent(of id: String, in list: [UPTreeNode], parent: UPTreeNode? = nil) -> UPTreeNode? {
        for node in list {
            if node.id == id { return parent }
            if let found = self.parent(of: id, in: node.children, parent: node) { return found }
        }
        return nil
    }

    /// 上游 `setChildrenChecked`：跳过 disabled 子节点，其余递归写入。
    nonisolated static func checkDescendants(_ node: UPTreeNode, checked: Bool, into set: inout Set<String>) {
        for child in node.children where !child.disabled {
            if checked { set.insert(child.id) } else { set.remove(child.id) }
            checkDescendants(child, checked: checked, into: &set)
        }
    }

    /// 上游 `syncParentChecked`：自底向上推导父节点的全选/半选，
    /// 判定只看未禁用的子节点。
    nonisolated static func syncParentChecked(_ list: [UPTreeNode],
                                              checked: inout Set<String>,
                                              indeterminate: inout Set<String>) {
        for node in list where !node.children.isEmpty {
            syncParentChecked(node.children, checked: &checked, indeterminate: &indeterminate)
            let enabled = node.children.filter { !$0.disabled }
            let allChecked = !enabled.isEmpty && enabled.allSatisfy { checked.contains($0.id) }
            let someChecked = enabled.contains { checked.contains($0.id) || indeterminate.contains($0.id) }
            if allChecked { checked.insert(node.id) } else { checked.remove(node.id) }
            if !allChecked, someChecked { indeterminate.insert(node.id) } else { indeterminate.remove(node.id) }
        }
    }

    // MARK: - 上游 methods

    public func find(_ id: String) -> UPTreeNode? { Self.find(id, in: nodes) }

    /// 上游 `getNodeByKey(key)`。
    public func nodeByKey(_ key: String) -> UPTreeNode? { Self.find(key, in: nodes) }

    public func isExpanded(_ id: String) -> Bool { state.expandedIDs.contains(id) }

    /// 上游 `handleNodeClick(item)`：先记 current，再按两个开关决定展开/勾选，
    /// 最后抛 `node-click`，current 变化时补一发 `current-change`。
    public func handleNodeClick(_ id: String) {
        guard let node = find(id) else { return }
        let oldCurrent = currentNode
        state.currentKey = id
        if expandOnClickNode, !node.children.isEmpty { toggleExpand(id) }
        if checkOnClickNode, showCheckbox, !node.disabled {
            setNodeChecked(node, checked: !state.checkedIDs.contains(id), deep: true)
            emitCheck(node)
        }
        onNodeClickHandler?(node)
        onSelectHandler?(node)
        if oldCurrent?.id != node.id {
            onCurrentChangeHandler?(node, oldCurrent)
        }
    }

    /// 上游 `handleExpandClick(item)`：无子节点直接 return。
    public func handleExpandClick(_ id: String) {
        guard let node = find(id), !node.children.isEmpty else { return }
        toggleExpand(id)
    }

    /// 上游 `toggleExpand(item)`：`accordion` 为真且即将展开时先收起同级。
    public func toggleExpand(_ id: String) {
        guard let node = find(id) else { return }
        let nextExpanded = !state.expandedIDs.contains(id)
        if accordion, nextExpanded { collapseSiblingNodes(of: id) }
        if nextExpanded {
            state.expandedIDs.insert(id)
            onExpandHandler?(node)
        } else {
            state.expandedIDs.remove(id)
            onCollapseHandler?(node)
        }
    }

    /// 仓库既有名。上游对无子节点的 `toggleExpand` 不设防，
    /// 但仓库既有语义是「只有带子节点的行才能切换」，保留该判定。
    public func toggle(_ id: String) {
        guard let node = find(id), !node.children.isEmpty else { return }
        toggleExpand(id)
    }

    /// 上游 `collapseSiblingNodes(node)`。
    private func collapseSiblingNodes(of id: String) {
        let siblings = Self.parent(of: id, in: nodes).map(\.children) ?? nodes
        for sibling in siblings where sibling.id != id {
            state.expandedIDs.remove(sibling.id)
        }
    }

    /// 上游 `handleCheckboxChange(item, checked)`：disabled 直接 return，
    /// 之后依次抛 `check-change` 与 `check`。
    public func handleCheckboxChange(_ id: String, checked: Bool) {
        guard let node = find(id), !node.disabled else { return }
        setNodeChecked(node, checked: checked, deep: true)
        onCheckChangeHandler?(node, checked)
        emitCheck(node)
    }

    /// 仓库既有名。
    public func check(_ id: String, checked: Bool) {
        handleCheckboxChange(id, checked: checked)
    }

    /// 上游 `setNodeChecked(node, checked, deep)`。
    public func setNodeChecked(_ node: UPTreeNode, checked: Bool, deep: Bool = true) {
        if checked { state.checkedIDs.insert(node.id) } else { state.checkedIDs.remove(node.id) }
        state.indeterminateIDs.remove(node.id)
        if !checkStrictly, deep {
            Self.checkDescendants(node, checked: checked, into: &state.checkedIDs)
            for child in node.children { state.indeterminateIDs.remove(child.id) }
        }
        if !checkStrictly { updateParentChecked(of: node.id) }
    }

    /// 上游 `setChecked(key, checked, deep)`。
    public func setChecked(_ key: String, checked: Bool, deep: Bool = true) {
        guard let node = find(key) else { return }
        setNodeChecked(node, checked: checked, deep: deep)
    }

    /// 上游 `updateParentChecked(node)`：一路向上推导。
    private func updateParentChecked(of id: String) {
        guard let parent = Self.parent(of: id, in: nodes) else { return }
        let enabled = parent.children.filter { !$0.disabled }
        let allChecked = !enabled.isEmpty && enabled.allSatisfy { state.checkedIDs.contains($0.id) }
        let someChecked = enabled.contains {
            state.checkedIDs.contains($0.id) || state.indeterminateIDs.contains($0.id)
        }
        if allChecked { state.checkedIDs.insert(parent.id) } else { state.checkedIDs.remove(parent.id) }
        if !allChecked, someChecked {
            state.indeterminateIDs.insert(parent.id)
        } else {
            state.indeterminateIDs.remove(parent.id)
        }
        updateParentChecked(of: parent.id)
    }

    /// 上游 `getCheckedNodes(leafOnly)`。
    public func checkedNodes(leafOnly: Bool = false) -> [UPTreeNode] {
        var result: [UPTreeNode] = []
        Self.walk(nodes) { node in
            guard state.checkedIDs.contains(node.id) else { return }
            if !leafOnly || node.children.isEmpty { result.append(node) }
        }
        return result
    }

    /// 上游 `getCheckedKeys(leafOnly)`。
    public func checkedKeys(leafOnly: Bool = false) -> [String] {
        checkedNodes(leafOnly: leafOnly).map(\.id)
    }

    /// 上游 `getHalfCheckedNodes()`。
    public func halfCheckedNodes() -> [UPTreeNode] {
        var result: [UPTreeNode] = []
        Self.walk(nodes) { node in
            if state.indeterminateIDs.contains(node.id) { result.append(node) }
        }
        return result
    }

    /// 上游 `getHalfCheckedKeys()`。
    public func halfCheckedKeys() -> [String] { halfCheckedNodes().map(\.id) }

    /// 上游 `setCheckedKeys(keys, leafOnly)`：先全清，再逐个写入，最后统一推导父节点。
    public func setCheckedKeys(_ keys: [String], leafOnly: Bool = false) {
        state.checkedIDs = []
        state.indeterminateIDs = []
        for key in keys {
            guard let node = find(key) else { continue }
            if !leafOnly || node.children.isEmpty {
                setNodeChecked(node, checked: true, deep: !checkStrictly)
            }
        }
        if !checkStrictly {
            Self.syncParentChecked(nodes, checked: &state.checkedIDs, indeterminate: &state.indeterminateIDs)
        }
        checkedIDsBinding?.wrappedValue = state.checkedIDs
    }

    /// 上游 `setCurrentKey(key)`。
    public func setCurrentKey(_ key: String) { state.currentKey = key }

    /// 上游 `getCurrentKey()`。
    public func getCurrentKey() -> String { state.currentKey }

    /// 上游 `getCurrentNode()`。
    public var currentNode: UPTreeNode? {
        state.currentKey.isEmpty ? nil : find(state.currentKey)
    }

    /// 上游 `emitCheck(node)`：第二个参数带四个字段。
    private func emitCheck(_ node: UPTreeNode) {
        checkedIDsBinding?.wrappedValue = state.checkedIDs
        onCheckHandler?(node, UPTreeCheckInfo(checkedNodes: checkedNodes(),
                                             checkedKeys: checkedKeys(),
                                             halfCheckedNodes: halfCheckedNodes(),
                                             halfCheckedKeys: halfCheckedKeys()))
    }

    /// 仓库既有方法：维护「选中行」列表，与上游的 `currentKey` 并存。
    public func select(_ id: String) {
        guard let node = find(id), !node.disabled else { return }
        if multiple {
            if state.selectedIDs.contains(id) {
                state.selectedIDs.removeAll { $0 == id }
            } else {
                state.selectedIDs.append(id)
            }
        } else {
            state.selectedIDs = [id]
        }
        selectedIDsBinding?.wrappedValue = state.selectedIDs
        state.currentKey = id
        onSelectHandler?(node)
        onNodeClickHandler?(node)
    }

    // MARK: - 事件

    public func onSelect(_ action: @escaping (UPTreeNode) -> Void) -> UPTree {
        var copy = self
        copy.onSelectHandler = action
        return copy
    }

    /// 对应上游 `node-click` 事件。
    public func onNodeClick(_ action: @escaping (UPTreeNode) -> Void) -> UPTree {
        var copy = self
        copy.onNodeClickHandler = action
        return copy
    }

    /// 对应上游 `check-change` 事件，负载是 `(node, checked)`。
    public func onCheckChange(_ action: @escaping (UPTreeNode, Bool) -> Void) -> UPTree {
        var copy = self
        copy.onCheckChangeHandler = action
        return copy
    }

    /// 对应上游 `check` 事件，负载是 `(node, { checkedNodes, checkedKeys, halfCheckedNodes, halfCheckedKeys })`。
    public func onCheck(_ action: @escaping (UPTreeNode, UPTreeCheckInfo) -> Void) -> UPTree {
        var copy = self
        copy.onCheckHandler = action
        return copy
    }

    /// 对应上游 `node-expand` 事件。
    public func onExpand(_ action: @escaping (UPTreeNode) -> Void) -> UPTree {
        var copy = self
        copy.onExpandHandler = action
        return copy
    }

    /// 对应上游 `node-collapse` 事件。
    public func onCollapse(_ action: @escaping (UPTreeNode) -> Void) -> UPTree {
        var copy = self
        copy.onCollapseHandler = action
        return copy
    }

    /// 对应上游 `current-change` 事件，负载是 `(node, oldNode)`。
    public func onCurrentChange(_ action: @escaping (UPTreeNode, UPTreeNode?) -> Void) -> UPTree {
        var copy = self
        copy.onCurrentChangeHandler = action
        return copy
    }

    // MARK: - 插槽

    /// 对应上游默认作用域插槽，参数含 node / level / expanded / checked / indeterminate / disabled。
    public func nodeContent<Slot: View>(@ViewBuilder _ builder: @escaping (UPTreeVisibleNode) -> Slot) -> UPTree {
        var copy = self
        copy.nodeSlot = { AnyView(builder($0)) }
        return copy
    }

    public var hasNodeSlot: Bool { nodeSlot != nil }

    // MARK: - 视图

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(visibleNodes) { item in
                    nodeRow(item)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func nodeRow(_ item: UPTreeVisibleNode) -> some View {
        HStack(spacing: 0) {
            switcher(item)

            if showCheckbox {
                UPCheckbox(size: checkboxSize,
                           checked: item.checked,
                           disabled: UPCheckboxFlag(item.disabled),
                           usedAlone: true) { checked, _ in
                    handleCheckboxChange(item.key, checked: checked)
                }
                .padding(.horizontal, UPUnit.rpx(CGFloat(8)))
            }

            Group {
                if let nodeSlot {
                    nodeSlot(item)
                } else {
                    Text(item.node.title)
                        .font(.system(size: UPConfig.tree.fontSize))
                        .foregroundStyle(UPColor.parse("main", theme: theme))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, indentPadding(level: item.level))
        .frame(minHeight: UPConfig.tree.nodeMinHeight)
        .background(rowBackground(item))
        .clipShape(RoundedRectangle(cornerRadius: UPUnit.rpx(CGFloat(8))))
        // 上游 `.u-tree-node--disabled { opacity: 0.55 }`。
        .opacity(item.disabled ? UPConfig.tree.disabledOpacity : 1)
        .contentShape(Rectangle())
        .onTapGesture { handleNodeClick(item.key) }
    }

    /// 上游 `.u-tree-node__switcher`：只有带子节点的行才画箭头，点击不冒泡到整行。
    private func switcher(_ item: UPTreeVisibleNode) -> some View {
        Group {
            if item.hasChildren {
                UPIcon(name: item.expanded ? collapseIcon : expandIcon,
                       color: UPConfig.tree.switcherColor,
                       size: iconSize)
            } else {
                Color.clear
            }
        }
        .frame(width: UPConfig.tree.switcherSize, height: UPConfig.tree.switcherSize)
        .contentShape(Rectangle())
        .onTapGesture { handleExpandClick(item.key) }
    }

    private func rowBackground(_ item: UPTreeVisibleNode) -> Color {
        highlightCurrent && item.key == state.currentKey
            ? UPColor.parse(UPConfig.tree.currentBackgroundColor, theme: theme)
            : .clear
    }
}
