import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Native safe-area-backed counterpart of uview-plus `u-status-bar`.
@MainActor
public struct UPStatusBar<Content: View>: View {
    var bgColor: String
    var height: CGFloat
    var customStyle: UPStyle

    private let content: Content
    private var onUpdateHeightHandler: ((CGFloat) -> Void)?

    public init(
        bgColor: String = "transparent",
        height: CGFloat = 0,
        customStyle: UPStyle = UPStyle(),
        @ViewBuilder content: () -> Content
    ) {
        self.bgColor = bgColor
        self.height = height
        self.customStyle = customStyle
        self.content = content()
    }

    public var body: some View {
        GeometryReader { proxy in
            let resolved = resolvedHeight(
                safeAreaTop: proxy.safeAreaInsets.top,
                statusBarHeight: Self.platformStatusBarHeight
            )
            ZStack { content }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(UPColor.parse(bgColor))
                .onAppear { onUpdateHeightHandler?(resolved) }
                .onChange(of: resolved) { _, newValue in
                    onUpdateHeightHandler?(newValue)
                }
        }
        .frame(height: max(Self.platformStatusBarHeight ?? height, 0))
        .upStyle(customStyle)
    }

    public func resolvedHeight(safeAreaTop: CGFloat, statusBarHeight: CGFloat?) -> CGFloat {
        max(statusBarHeight ?? safeAreaTop, 0)
    }

    public func onUpdateHeight(_ action: @escaping (CGFloat) -> Void) -> Self {
        var copy = self
        copy.onUpdateHeightHandler = action
        return copy
    }

    func reportHeight(safeAreaTop: CGFloat, statusBarHeight: CGFloat?) {
        onUpdateHeightHandler?(resolvedHeight(safeAreaTop: safeAreaTop, statusBarHeight: statusBarHeight))
    }

    private static var platformStatusBarHeight: CGFloat? {
        #if canImport(UIKit)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \ .isKeyWindow)?
            .windowScene?.statusBarManager?.statusBarFrame.height
        #else
        return nil
        #endif
    }
}

public extension UPStatusBar where Content == EmptyView {
    init(bgColor: String = "transparent", height: CGFloat = 0, customStyle: UPStyle = UPStyle()) {
        self.init(bgColor: bgColor, height: height, customStyle: customStyle, content: EmptyView.init)
    }
}
