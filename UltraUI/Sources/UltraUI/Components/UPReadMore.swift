import SwiftUI

@MainActor
private final class UPReadMoreState { var expanded: Bool; init(_ expanded: Bool) { self.expanded = expanded } }

/// Expandable text container corresponding to uview-plus `u-read-more`.
@MainActor
public struct UPReadMore<Content: View>: View {
    public var lines: Int
    public var isExpanded: Bool { state.expanded }
    public var showToggle: Bool
    private let state: UPReadMoreState
    private let content: Content
    private var onChangeHandler: ((Bool) -> Void)?

    public init(lines: Int = 3, expanded: Bool = false, showToggle: Bool = true, @ViewBuilder content: () -> Content) {
        self.lines = max(lines, 0); self.showToggle = showToggle; self.state = UPReadMoreState(expanded); self.content = content()
    }
    public init(lines: Int = 3, expanded: Bool = false, showToggle: Bool = true) where Content == EmptyView {
        self.lines = max(lines, 0); self.showToggle = showToggle; self.state = UPReadMoreState(expanded); self.content = EmptyView()
    }
    public var body: some View { VStack(alignment: .leading) { content.lineLimit(isExpanded ? nil : lines); if showToggle { Button(isExpanded ? "收起" : "展开", action: toggle) } } }
    public func toggle() { state.expanded.toggle(); onChangeHandler?(state.expanded) }
    public func expand() { guard !isExpanded else { return }; state.expanded = true; onChangeHandler?(true) }
    public func collapse() { guard isExpanded else { return }; state.expanded = false; onChangeHandler?(false) }
    public func onChange(_ action: @escaping (Bool) -> Void) -> Self { var copy = self; copy.onChangeHandler = action; return copy }
}
