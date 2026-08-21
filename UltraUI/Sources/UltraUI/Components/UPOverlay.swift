import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-overlay`.
public struct UPOverlay: View {
    var show: Bool
    var zIndex: Double
    var duration: Double
    var opacity: Double
    var onTap: (() -> Void)?
    var onClick: (() -> Void)?

    public init(show: Bool = UPConfig.overlay.show,
                zIndex: Double = UPConfig.overlay.zIndex,
                duration: Double = UPConfig.overlay.duration,
                opacity: Double = UPConfig.overlay.opacity,
                onTap: (() -> Void)? = nil,
                onClick: (() -> Void)? = nil) {
        self.show = show
        self.zIndex = zIndex
        self.duration = duration
        self.opacity = opacity
        self.onTap = onTap
        self.onClick = onClick
    }

    public static func allowsHitTesting(show: Bool) -> Bool {
        show
    }

    public var body: some View {
        Color.black
            .opacity(show ? min(max(opacity, 0), 1) : 0)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .allowsHitTesting(Self.allowsHitTesting(show: show))
            .onTapGesture {
                guard show else { return }
                onTap?()
                onClick?()
            }
            .animation(.easeInOut(duration: max(0, duration) / 1_000), value: show)
            .zIndex(zIndex)
    }
}

public extension UPOverlay {
    func onTap(_ action: @escaping () -> Void) -> UPOverlay {
        var copy = self
        copy.onTap = action
        return copy
    }

    func onClick(_ action: @escaping () -> Void) -> UPOverlay {
        var copy = self
        copy.onClick = action
        return copy
    }
}
