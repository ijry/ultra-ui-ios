import SwiftUI

public struct UPTreeNode: Identifiable, Equatable, Sendable { public let id: String; public let title: String; public var children: [UPTreeNode]; public init(id: String, title: String, children: [UPTreeNode] = []) { self.id = id; self.title = title; self.children = children } }

@MainActor
public final class UPTree: View {
    public let nodes: [UPTreeNode]; public private(set) var expandedIDs: Set<String> = []; public private(set) var selectedIDs: [String] = []
    private var onSelectHandler: ((UPTreeNode) -> Void)?
    public init(nodes: [UPTreeNode] = [], onSelect: ((UPTreeNode) -> Void)? = nil) { self.nodes = nodes; self.onSelectHandler = onSelect }
    public func onSelect(_ action: @escaping (UPTreeNode) -> Void) -> UPTree { onSelectHandler = action; return self }
    public func toggle(_ id: String) { if expandedIDs.contains(id) { expandedIDs.remove(id) } else { expandedIDs.insert(id) } }
    public func isExpanded(_ id: String) -> Bool { expandedIDs.contains(id) }
    public func select(_ id: String) { guard let node = find(id, in: nodes) else { return }; selectedIDs = [id]; onSelectHandler?(node) }
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
                Button(node.title) { self.select(node.id) }.buttonStyle(.plain)
            }
            .padding(.leading, CGFloat(depth * 16))
            if self.isExpanded(node.id) {
                ForEach(node.children) { child in self.treeNode(child, depth: depth + 1) }
            }
        })
    }
}
