import SwiftUI

@MainActor
private final class UPPopoverState { var show: Bool; init(show: Bool) { self.show = show } }

/// Native popover counterpart of uview-plus `u-popover`.
@MainActor
public struct UPPopover<Content: View>: View {
    public var placement: String
    public var closeOnClickOutside: Bool
    public var show: Bool { state.show }
    private let state: UPPopoverState
    private let content: Content
    private var onCloseHandler: (() -> Void)?

    public init(show: Bool = false, placement: String = "bottom", closeOnClickOutside: Bool = true, @ViewBuilder content: () -> Content) {
        self.placement = placement; self.closeOnClickOutside = closeOnClickOutside; self.state = UPPopoverState(show: show); self.content = content()
    }

    public var body: some View {
        content
            .popover(isPresented: Binding(get: { show }, set: { value in if !value { dismiss() } })) { Text("") }
    }

    public func showPopover() { state.show = true }
    public func dismiss() { guard show else { return }; state.show = false; onCloseHandler?() }
    public func onClose(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onCloseHandler = action; return copy }
}

public extension UPPopover where Content == EmptyView {
    init(show: Bool = false, placement: String = "bottom", closeOnClickOutside: Bool = true) {
        self.init(show: show, placement: placement, closeOnClickOutside: closeOnClickOutside, content: EmptyView.init)
    }
}
