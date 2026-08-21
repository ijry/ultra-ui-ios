import SwiftUI

public struct UPFloatButtonItem: Identifiable, Equatable, Sendable {
    public let id: String
    public var title: String
    public var icon: String
    public init(id: String, title: String = "", icon: String = "") { self.id = id; self.title = title; self.icon = icon }
}

@MainActor
private final class UPFloatButtonState { var expanded = false }

/// Floating action button corresponding to uview-plus `u-float-button`.
@MainActor
public struct UPFloatButton: View {
    public var items: [UPFloatButtonItem]
    public var expanded: Bool { state.expanded }
    public var direction: String
    private let state = UPFloatButtonState()
    private var onClickHandler: (() -> Void)?
    private var onItemClickHandler: ((UPFloatButtonItem) -> Void)?

    public init(items: [UPFloatButtonItem] = [], direction: String = "up") { self.items = items; self.direction = direction }
    public var body: some View { VStack { if expanded { ForEach(items) { item in Button(item.title) { select(item.id) } } }; Button("+") { toggle() } }.padding() }
    public func toggle() { state.expanded.toggle() }
    public func close() { state.expanded = false }
    public func select(_ id: String) { guard let item = items.first(where: { $0.id == id }) else { return }; onItemClickHandler?(item) }
    public func onClick(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onClickHandler = action; return copy }
    public func onItemClick(_ action: @escaping (UPFloatButtonItem) -> Void) -> Self { var copy = self; copy.onItemClickHandler = action; return copy }
}
