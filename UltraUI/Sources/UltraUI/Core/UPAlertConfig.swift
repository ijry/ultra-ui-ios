import Foundation

/// Defaults for the SwiftUI counterpart of uview-plus `u-alert`.
///
/// Kept in a separate extension so the component can be added without
/// changing the shared core configuration declaration.
public extension UPConfig {
    enum alert {
        public static let title = ""
        public static let type = "warning"
        public static let description = ""
        public static let closable = false
        public static let showIcon = false
        public static let effect = "light"
        public static let center = false
        public static let fontSize = 14
        public static let transitionMode = "fade"
        public static let duration: Double = 0
        public static let icon = ""
        public static let value = true
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }
}
