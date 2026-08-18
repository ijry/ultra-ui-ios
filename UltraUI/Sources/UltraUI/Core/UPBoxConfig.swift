import Foundation

/// Defaults mirrored from uview-plus `u-box`.
public enum UPBoxConfig {
    public static let bgColors = ["#EEFCFF", "#FCF8FF", "#FDF8F2"]
    public static let height = "160px"
    public static let borderRadius = "6px"
    public static let gap = "15px"
    public static let leftIcon = ""
    public static let leftTitle = "左"
    public static let rightTopIcon = ""
    public static let rightTopTitle = "右上"
    public static let rightBottomIcon = ""
    public static let rightBottomTitle = "右下"
    public static let customClass = ""
    public static let customStyle = UPStyle()
}

public extension UPConfig {
    enum box {
        public static let bgColors = UPBoxConfig.bgColors
        public static let height = UPBoxConfig.height
        public static let borderRadius = UPBoxConfig.borderRadius
        public static let gap = UPBoxConfig.gap
        public static let leftIcon = UPBoxConfig.leftIcon
        public static let leftTitle = UPBoxConfig.leftTitle
        public static let rightTopIcon = UPBoxConfig.rightTopIcon
        public static let rightTopTitle = UPBoxConfig.rightTopTitle
        public static let rightBottomIcon = UPBoxConfig.rightBottomIcon
        public static let rightBottomTitle = UPBoxConfig.rightBottomTitle
        public static let customClass = UPBoxConfig.customClass
        public static let customStyle = UPBoxConfig.customStyle
    }
}
