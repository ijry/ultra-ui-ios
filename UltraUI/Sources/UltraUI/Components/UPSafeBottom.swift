import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Bottom safe-area spacer corresponding to uview-plus `u-safe-bottom`.
@MainActor
public struct UPSafeBottom: View {
    var customStyle: UPStyle

    public init(customStyle: UPStyle = UPStyle()) {
        self.customStyle = customStyle
    }

    public var body: some View {
        Color.clear
            .frame(height: resolvedHeight(safeAreaBottom: Self.platformSafeAreaBottom))
            .upStyle(customStyle)
            .accessibilityHidden(true)
    }

    public func resolvedHeight(safeAreaBottom: CGFloat) -> CGFloat {
        max(safeAreaBottom, 0)
    }

    private static var platformSafeAreaBottom: CGFloat {
        #if canImport(UIKit)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \ .isKeyWindow)?
            .safeAreaInsets.bottom ?? 0
        #else
        return 0
        #endif
    }
}
