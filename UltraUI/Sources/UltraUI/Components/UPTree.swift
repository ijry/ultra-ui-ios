import SwiftUI

public struct UPTreeNode: Identifiable, Equatable, Sendable { public let id: String; public let title: String; public var children: [UPTreeNode]; public let disabled: Bool; public init(id: String, title: String, children: [UPTreeNode] = [], disabled: Bool = false) { self.id = id; self.title = title; self.children = children; self.disabled = disabled } }

@MainActor
public final class UPTree: View {
    public let nodes: [UPTreeNode]; public let multiple: Bool; public let showCheckbox: Bool
    public private(set) var expandedIDs: Set<String> = []; public private(set) var selectedIDs: [String] = []; public private(set) var checkedIDs: Set<String> = []
    private var selectedIDsBinding: Binding<[String]>?; private var checkedIDsBinding: Binding<Set<String>>?; private var onSelectHandler: ((UPTreeNode) -> Void)?; private var onCheckChangeHandler: ((UPTreeNode, Bool) -> Void)?; private var onExpandHandler: ((UPTreeNode) -> Void)?; private var onCollapseHandler: ((UPTreeNode) -> Void)?
    public init(nodes: [UPTreeNode] = [], onSelect: ((UPTreeNode) -> Void)? = nil) { self.nodes = nodes; self.multiple = false; self.showCheckbox = false; self.onSelectHandler = onSelect }
    public init(nodes: [UPTreeNode] = [], multiple: Bool = false, selectedIDs: Binding<[String]>? = nil, checkedIDs: Binding<Set<String>>? = nil, showCheckbox: Bool = false, defaultExpandedIDs: Set<String> = [], onSelect: ((UPTreeNode) -> Void)? = nil) { self.nodes = nodes; self.multiple = multiple; self.showCheckbox = showCheckbox; self.selectedIDsBinding = selectedIDs; self.checkedIDsBinding = checkedIDs; self.selectedIDs = selectedIDs?.wrappedValue ?? []; self.checkedIDs = checkedIDs?.wrappedValue ?? []; self.expandedIDs = defaultExpandedIDs; self.onSelectHandler = onSelect }
    public func onSelect(_ action: @escaping (UPTreeNode) -> Void) -> UPTree { onSelectHandler = action; return self }
    public func onCheckChange(_ action: @escaping (UPTreeNode, Bool) -> Void) -> UPTree { onCheckChangeHandler = action; return self }
    public func onExpand(_ action: @escaping (UPTreeNode) -> Void) -> UPTree { onExpandHandler = action; return self }
    public func onCollapse(_ action: @escaping (UPTreeNode) -> Void) -> UPTree { onCollapseHandler = action; return self }
    public func toggle(_ id: String) {
        guard let node = find(id, in: nodes), !node.children.isEmpty else { return }
        if expandedIDs.contains(id) {
            expandedIDs.remove(id)
            onCollapseHandler?(node)
        } else {
            expandedIDs.insert(id)
            onExpandHandler?(node)
        }
    }
    public func isExpanded(_ id: String) -> Bool { expandedIDs.contains(id) }
    public func select(_ id: String) { guard let node = find(id, in: nodes), !node.disabled else { return }; if multiple { if selectedIDs.contains(id) { selectedIDs.removeAll { $0 == id } } else { selectedIDs.append(id) } } else { selectedIDs = [id] }; selectedIDsBinding?.wrappedValue = selectedIDs; onSelectHandler?(node) }
    public func check(_ id: String, checked: Bool) { guard let node = find(id, in: nodes), !node.disabled else { return }; if checked { checkedIDs.insert(id) } else { checkedIDs.remove(id) }; checkedIDsBinding?.wrappedValue = checkedIDs; onCheckChangeHandler?(node, checked) }
    private func find(_ id: String, in nodes: [UPTreeNode]) -> UPTreeNode? { for node in nodes { if node.id == id { return node }; if let found = find(id, in: node.children) { return found } }; return nil }
    public var body: some View { List { ForEach(self.nodes) { node in self.treeNode(node, depth: 0) } } }
    private func treeNode(_ node: UPTreeNode, depth: Int) -> AnyView {
        AnyView(VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !node.children.isEmpty {
                    Button { self.toggle(node.id) } label: {
                        Image(systemName: self.isExpanded(node.id) ? "chevron.down" : "chevron.right")
                    }.buttonStyle(.plain)
                }
                if showCheckbox {
                    Button { self.check(node.id, checked: !self.checkedIDs.contains(node.id)) } label: {
                        Image(systemName: self.checkedIDs.contains(node.id) ? "checkmark.square.fill" : "square")
                    }
                    .buttonStyle(.plain)
                    .disabled(node.disabled)
                }
                Button(node.title) { self.select(node.id) }
                    .buttonStyle(.plain)
                    .disabled(node.disabled)
            }
            .padding(.leading, CGFloat(depth * 16))
            if self.isExpanded(node.id) {
                ForEach(node.children) { child in
                    self.treeNode(child, depth: depth + 1)
                }
            }
        })
    }
}
