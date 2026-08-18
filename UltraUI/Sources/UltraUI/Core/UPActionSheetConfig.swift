import CoreGraphics

/// Unit-compatible prop values accepted by the SwiftUI counterpart of
/// uview-plus `u-action-sheet`.
public typealias UPActionSheetUnitValue = UPCheckboxUnitValue

/// Defaults for the SwiftUI counterpart of uview-plus `u-action-sheet`.
///
/// Kept in a separate extension so this component can be added without
/// changing the shared core configuration declaration.
public extension UPConfig {
    enum actionSheet {
        public static let show = false
        public static let title = ""
        public static let description = ""
        public static let actions: [UPActionSheetAction] = []
        public static let nameKey = "name"
        public static let subnameKey = "subnameKey"
        public static let cancelText = ""
        public static let closeOnClickAction = true
        public static let safeAreaInsetBottom = true
        public static let openType = ""
        public static let closeOnClickOverlay = true
        public static let round = "0"
        public static let wrapMaxHeight = "600px"
    }
}
