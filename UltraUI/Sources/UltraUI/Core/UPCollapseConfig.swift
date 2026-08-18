import Foundation

/// Defaults mirrored from uview-plus `u-collapse` and `u-collapse-item`.
///
/// The dedicated namespace keeps collapse defaults independently consumable and
/// lets this component extend `UPConfig` without modifying the shared config
/// file while other components are being developed.
public enum UPCollapseConfig {
    public static let value = UPCollapseValue.none
    public static let accordion = false
    public static let border = true

    public enum item {
        public static let title = ""
        public static let value = ""
        public static let label = ""
        public static let disabled = false
        public static let isLink = true
        public static let clickable = true
        public static let border = true
        public static let align = "left"
        public static let name: UPCollapseName = ""
        public static let icon = ""
        public static let duration = 300
        public static let showRight = true
        public static let titleStyle = UPStyle()
        public static let iconStyle = UPStyle()
        public static let rightIconStyle = UPStyle()
        public static let cellCustomStyle = UPStyle()
        public static let cellCustomClass = ""
    }
}

public extension UPConfig {
    enum collapse {
        public static let value = UPCollapseConfig.value
        public static let accordion = UPCollapseConfig.accordion
        public static let border = UPCollapseConfig.border
    }

    enum collapseItem {
        public static let title = UPCollapseConfig.item.title
        public static let value = UPCollapseConfig.item.value
        public static let label = UPCollapseConfig.item.label
        public static let disabled = UPCollapseConfig.item.disabled
        public static let isLink = UPCollapseConfig.item.isLink
        public static let clickable = UPCollapseConfig.item.clickable
        public static let border = UPCollapseConfig.item.border
        public static let align = UPCollapseConfig.item.align
        public static let name = UPCollapseConfig.item.name
        public static let icon = UPCollapseConfig.item.icon
        public static let duration = UPCollapseConfig.item.duration
        public static let showRight = UPCollapseConfig.item.showRight
        public static let titleStyle = UPCollapseConfig.item.titleStyle
        public static let iconStyle = UPCollapseConfig.item.iconStyle
        public static let rightIconStyle = UPCollapseConfig.item.rightIconStyle
        public static let cellCustomStyle = UPCollapseConfig.item.cellCustomStyle
        public static let cellCustomClass = UPCollapseConfig.item.cellCustomClass
    }
}
