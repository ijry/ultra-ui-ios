import SwiftUI

@MainActor
private final class UPRefreshVirtualListState {
    var refreshing: Bool

    init(refreshing: Bool) {
        self.refreshing = refreshing
    }
}

/// Pull-to-refresh wrapper corresponding to uview-plus `u-refresh-virtual-list`.
@MainActor
public struct UPRefreshVirtualList<Content: View>: View {
    public var refresherEnabled: Bool
    public var refresherThreshold: CGFloat
    public var refreshing: Bool {
        refreshingBinding?.wrappedValue ?? state.refreshing
    }

    private var refreshingBinding: Binding<Bool>?
    private let state: UPRefreshVirtualListState
    private let content: Content
    private var onRefreshHandler: (() -> Void)?

    public init(
        refreshing: Bool = false,
        refresherEnabled: Bool = true,
        refresherThreshold: CGFloat = 45,
        @ViewBuilder content: () -> Content
    ) {
        self.refreshingBinding = nil
        self.state = UPRefreshVirtualListState(refreshing: refreshing)
        self.refresherEnabled = refresherEnabled
        self.refresherThreshold = max(refresherThreshold, 0)
        self.content = content()
    }

    public init(
        refreshing: Binding<Bool>,
        refresherEnabled: Bool = true,
        refresherThreshold: CGFloat = 45,
        @ViewBuilder content: () -> Content
    ) {
        self.refreshingBinding = refreshing
        self.state = UPRefreshVirtualListState(refreshing: refreshing.wrappedValue)
        self.refresherEnabled = refresherEnabled
        self.refresherThreshold = max(refresherThreshold, 0)
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            content
        }
        .refreshable {
            guard refresherEnabled else { return }
            beginRefresh()
        }
    }

    public func beginRefresh() {
        guard refresherEnabled, !refreshing else { return }
        state.refreshing = true
        refreshingBinding?.wrappedValue = true
        onRefreshHandler?()
    }

    public func endRefresh() {
        state.refreshing = false
        refreshingBinding?.wrappedValue = false
    }

    public func onRefresh(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onRefreshHandler = action
        return copy
    }
}

public extension UPRefreshVirtualList where Content == EmptyView {
    init(
        refreshing: Bool = false,
        refresherEnabled: Bool = true,
        refresherThreshold: CGFloat = 45
    ) {
        self.init(
            refreshing: refreshing,
            refresherEnabled: refresherEnabled,
            refresherThreshold: refresherThreshold,
            content: EmptyView.init
        )
    }

    init(
        refreshing: Binding<Bool>,
        refresherEnabled: Bool = true,
        refresherThreshold: CGFloat = 45
    ) {
        self.init(
            refreshing: refreshing,
            refresherEnabled: refresherEnabled,
            refresherThreshold: refresherThreshold,
            content: EmptyView.init
        )
    }
}
