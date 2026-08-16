import SwiftUI

public struct UPOverlay: View {
    var show: Bool
    var zIndex: Double
    var duration: Double
    var opacity: Double
    var onTap: (() -> Void)?

    public init(show: Bool = UPConfig.overlay.show,
                zIndex: Double = UPConfig.overlay.zIndex,
                duration: Double = UPConfig.overlay.duration,
                opacity: Double = UPConfig.overlay.opacity,
                onTap: (() -> Void)? = nil) {
        self.show = show
        self.zIndex = zIndex
        self.duration = duration
        self.opacity = opacity
        self.onTap = onTap
    }

    public static func allowsHitTesting(show: Bool) -> Bool {
        show
    }

    public var body: some View {
        Color.black
            .opacity(show ? opacity : 0)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .allowsHitTesting(Self.allowsHitTesting(show: show))
            .onTapGesture { if show { onTap?() } }
            .animation(.easeInOut(duration: duration / 1000), value: show)
    }
}
