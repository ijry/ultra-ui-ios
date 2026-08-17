import Foundation

/// Defaults for the SwiftUI counterparts of uview-plus `u-row` and `u-col`.
///
/// This lives in an extension so the component defaults can be added without
/// requiring callers to know whether the main configuration file has changed.
public extension UPConfig {
    enum row {
        public static let gutter = 0
        public static let justify = "start"
        public static let align = "center"
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }

    enum col {
        public static let span = 12
        public static let offset = 0
        public static let justify = "start"
        public static let align = "stretch"
        public static let textAlign = "left"
        public static let customClass = ""
        public static let customStyle = UPStyle()
    }
}
