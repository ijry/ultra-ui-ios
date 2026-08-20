import Foundation

/// Defaults mirrored from uview-plus `u-circle-progress`.
public enum UPCircleProgressConfig {
    public static let percentage = 30
    public static let customClass = ""
    public static let customStyle = UPStyle()
}

public extension UPConfig {
    enum circleProgress {
        public static let percentage = UPCircleProgressConfig.percentage
        public static let customClass = UPCircleProgressConfig.customClass
        public static let customStyle = UPCircleProgressConfig.customStyle
    }
}
