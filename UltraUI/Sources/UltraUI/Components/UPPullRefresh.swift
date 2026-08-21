import SwiftUI

@MainActor
private final class UPPullRefreshState { var refreshing: Bool; init(_ refreshing: Bool) { self.refreshing = refreshing } }

/// Pull-to-refresh container corresponding to uview-plus `u-pull-refresh`.
@MainActor
public struct UPPullRefresh<Content: View>: View {
    public var threshold: CGFloat
    public var enabled: Bool
    public var refreshing: Bool { binding?.wrappedValue ?? state.refreshing }
    private var binding: Binding<Bool>?
    private let state: UPPullRefreshState
    private let content: Content
    private var onRefreshHandler: (() -> Void)?

    public init(refreshing: Bool = false, threshold: CGFloat = 45, enabled: Bool = true, @ViewBuilder content: () -> Content) {
        self.binding = nil; self.state = UPPullRefreshState(refreshing); self.threshold = max(threshold, 0); self.enabled = enabled; self.content = content()
    }
    public init(refreshing: Binding<Bool>, threshold: CGFloat = 45, enabled: Bool = true, @ViewBuilder content: () -> Content) {
        self.binding = refreshing; self.state = UPPullRefreshState(refreshing.wrappedValue); self.threshold = max(threshold, 0); self.enabled = enabled; self.content = content()
    }
    public var body: some View { ScrollView { content }.refreshable { beginRefresh() } }

    @discardableResult
    public func pull(distance: CGFloat) -> Bool {
        guard enabled, distance >= threshold else { return false }
        beginRefresh(); return refreshing
    }
    public func beginRefresh() { guard enabled, !refreshing else { return }; state.refreshing = true; binding?.wrappedValue = true; onRefreshHandler?() }
    public func endRefresh() { state.refreshing = false; binding?.wrappedValue = false }
    public func onRefresh(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onRefreshHandler = action; return copy }
}

public extension UPPullRefresh where Content == EmptyView {
    init(refreshing: Bool = false, threshold: CGFloat = 45, enabled: Bool = true) { self.init(refreshing: refreshing, threshold: threshold, enabled: enabled, content: EmptyView.init) }
    init(refreshing: Binding<Bool>, threshold: CGFloat = 45, enabled: Bool = true) { self.init(refreshing: refreshing, threshold: threshold, enabled: enabled, content: EmptyView.init) }
}
