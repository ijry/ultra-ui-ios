import Foundation

/// Defaults mirrored from uview-plus `u-grid` and `u-grid-item`.
///
/// The standalone namespace keeps the component usable while applications
/// gradually adopt the larger `UPConfig` table. The nested `UPConfig` values
/// below provide the same lookup shape used by the other native components.
public enum UPGridConfig {
    public static let col = "3"
    public static let border = false
    public static let align = "left"
    public static let gap = "0px"

    public enum item {
        public static let name: UPGridName = .string("")
        public static let bgColor = "transparent"
    }
}

public extension UPConfig {
    enum grid {
        public static let col = UPGridConfig.col
        public static let border = UPGridConfig.border
        public static let align = UPGridConfig.align
        public static let gap = UPGridConfig.gap
    }

    enum gridItem {
        public static let name = UPGridConfig.item.name
        public static let bgColor = UPGridConfig.item.bgColor
    }
}
