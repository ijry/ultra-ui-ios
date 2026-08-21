import SwiftUI

public struct UPSwipeAction: Identifiable, Equatable, Sendable {
    public let id: String
    public var title: String
    public var color: String
    public var disabled: Bool
    public init(id: String, title: String, color: String = "#f56c6c", disabled: Bool = false) { self.id = id; self.title = title; self.color = color; self.disabled = disabled }
}

@MainActor
private final class UPSwipeActionState { var opened = false }

/// Swipeable row corresponding to uview-plus `u-swipe-action-item`.
@MainActor
public struct UPSwipeActionItem<Content: View>: View {
    public var id: String
    public var actions: [UPSwipeAction]
    public var threshold: CGFloat
    public var opened: Bool { state.opened }
    private let state = UPSwipeActionState()
    private let content: Content
    private var onActionHandler: ((UPSwipeAction) -> Void)?
    private var onOpenHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?

    public init(id: String, actions: [UPSwipeAction] = [], threshold: CGFloat = 50, @ViewBuilder content: () -> Content) {
        self.id = id; self.actions = actions; self.threshold = max(threshold, 0); self.content = content()
    }
    public init(id: String, actions: [UPSwipeAction] = [], threshold: CGFloat = 50) where Content == EmptyView {
        self.id = id; self.actions = actions; self.threshold = max(threshold, 0); self.content = EmptyView()
    }
    public var body: some View { HStack { content; if opened { ForEach(actions) { action in Button(action.title) { trigger(action.id) } } } }.contentShape(Rectangle()) }
    public func open() { guard !opened else { return }; state.opened = true; onOpenHandler?() }
    public func close() { guard opened else { return }; state.opened = false; onCloseHandler?() }
    public func trigger(_ id: String) { guard let action = actions.first(where: { $0.id == id }), !action.disabled else { return }; onActionHandler?(action) }
    public func onAction(_ action: @escaping (UPSwipeAction) -> Void) -> Self { var copy = self; copy.onActionHandler = action; return copy }
    public func onOpen(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onOpenHandler = action; return copy }
    public func onClose(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onCloseHandler = action; return copy }
}

/// Coordinator for uview-plus `u-swipe-action` mutual exclusion.
@MainActor
public final class UPSwipeActionGroup {
    public private(set) var openedID: String?
    private var registeredIDs: Set<String>
    public init() { openedID = nil; registeredIDs = [] }
    @discardableResult public func register(_ id: String) -> Self { registeredIDs.insert(id); return self }
    @discardableResult public func open(_ id: String) -> Self { guard registeredIDs.contains(id) else { return self }; openedID = id; return self }
    public func close() { openedID = nil }
}
