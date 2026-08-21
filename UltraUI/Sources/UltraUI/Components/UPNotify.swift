import SwiftUI

@MainActor
private final class UPNotifyState { var show: Bool; init(show: Bool) { self.show = show } }

/// Top notification overlay corresponding to uview-plus `u-notify`.
@MainActor
public struct UPNotify: View {
    public var message: String
    public var type: String
    public var duration: Int
    public var show: Bool { state.show }
    private let state: UPNotifyState
    private var onOpenHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?

    public init(show: Bool = false, message: String = "", type: String = "primary", duration: Int = 2_500) {
        self.message = message; self.type = type; self.duration = max(duration, 0); self.state = UPNotifyState(show: show)
    }

    public var body: some View {
        Text(message)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .opacity(show ? 1 : 0)
            .allowsHitTesting(show)
    }

    public func open() { guard !show else { return }; state.show = true; onOpenHandler?() }
    public func close() { guard show else { return }; state.show = false; onCloseHandler?() }

    public func onOpen(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onOpenHandler = action; return copy }
    public func onClose(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onCloseHandler = action; return copy }
}
