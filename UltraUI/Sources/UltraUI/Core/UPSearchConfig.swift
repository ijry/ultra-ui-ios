import Foundation

/// Defaults for the SwiftUI counterpart of uview-plus `u-search`.
///
/// Kept in a separate extension so consumers can adopt the component without
/// requiring a change to the shared core configuration declaration.
public extension UPConfig {
    enum search {
        public static let shape = "round"
        public static let bgColor = ""
        public static let placeholder = "请输入关键字"
        public static let clearabled = true
        public static let focus = false
        public static let showAction = true
        public static let actionText = "搜索"
        public static let inputAlign = "left"
        public static let disabled = false
        public static let animation = false
        public static let borderColor = "transparent"
        public static let searchIconColor = "#909399"
        public static let searchIconSize: Double = 22
        public static let color = ""
        public static let placeholderColor = ""
        public static let searchIcon = "search"
        public static let margin = "0"
        public static let iconPosition = "left"
        public static let maxlength = "-1"
        public static let height: Double = 32
        public static let adjustPosition = true
        public static let autoBlur = true
        public static let value = ""
        public static let label: String? = nil
        public static let onlyClearableOnFocused = true
        public static let inputStyle = UPStyle()
        public static let actionStyle = UPStyle()
        public static let customStyle = UPStyle()
    }
}
