import SwiftUI

@MainActor
private final class UPLazyLoadState {
    var loaded = false
}

/// Appearance-driven lazy loading trigger corresponding to uview-plus `u-lazy-load`.
@MainActor
public struct UPLazyLoad<Content: View, Placeholder: View>: View {
    public var threshold: CGFloat
    public var once: Bool
    private let content: Content
    private let placeholder: Placeholder
    private let state = UPLazyLoadState()
    private var onLoadHandler: (() -> Void)?

    public init(
        threshold: CGFloat = 0,
        once: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.threshold = max(threshold, 0)
        self.once = once
        self.content = content()
        self.placeholder = placeholder()
    }

    public var body: some View {
        Group {
            if state.loaded { content } else { placeholder }
        }
        .onAppear { appear(distanceToBottom: 0) }
    }

    public func appear(distanceToBottom: CGFloat) {
        guard distanceToBottom <= threshold, !once || !state.loaded else { return }
        state.loaded = true
        onLoadHandler?()
    }

    public func reset() {
        state.loaded = false
    }

    public func onLoad(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onLoadHandler = action
        return copy
    }
}

public extension UPLazyLoad where Placeholder == EmptyView {
    init(
        threshold: CGFloat = 0,
        once: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.init(threshold: threshold, once: once, content: content, placeholder: EmptyView.init)
    }
}

public extension UPLazyLoad where Content == EmptyView, Placeholder == EmptyView {
    init(threshold: CGFloat = 0, once: Bool = true) {
        self.init(
            threshold: threshold,
            once: once,
            content: EmptyView.init,
            placeholder: EmptyView.init
        )
    }
}
