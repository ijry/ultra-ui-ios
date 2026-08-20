import Foundation

/// Defaults mirrored from uview-plus `u-back-top`.
public enum UPBackTopConfig {
    public static let mode = "circle"
    public static let icon = "arrow-upward"
    public static let text = ""
    public static let duration = 100
    public static let scrollTop = 0
    public static let top = 400
    public static let bottom = 100
    public static let right = 20
    public static let zIndex = 9
    public static let iconStyle = UPStyle([
        "color": "#909399",
        "font-size": "19px"
    ])
    public static let customClass = ""
    public static let customStyle = UPStyle()
}

public extension UPConfig {
    enum backTop {
        public static let mode = UPBackTopConfig.mode
        public static let icon = UPBackTopConfig.icon
        public static let text = UPBackTopConfig.text
        public static let duration = UPBackTopConfig.duration
        public static let scrollTop = UPBackTopConfig.scrollTop
        public static let top = UPBackTopConfig.top
        public static let bottom = UPBackTopConfig.bottom
        public static let right = UPBackTopConfig.right
        public static let zIndex = UPBackTopConfig.zIndex
        public static let iconStyle = UPBackTopConfig.iconStyle
        public static let customClass = UPBackTopConfig.customClass
        public static let customStyle = UPBackTopConfig.customStyle
    }
}
