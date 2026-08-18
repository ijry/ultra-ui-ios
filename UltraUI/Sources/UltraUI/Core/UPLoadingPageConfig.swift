import Foundation

/// Defaults mirrored from uview-plus `u-loading-page`.
///
/// The upstream locale resolves `loadingText` to “正在加载” for the default
/// Chinese locale. Keeping the resolved string here makes the SwiftUI surface
/// deterministic while callers can still provide any String-or-Number value.
public enum UPLoadingPageConfig {
    public static let loadingText = "正在加载"
    public static let image = ""
    public static let loadingMode = "circle"
    public static let loading = false
    public static let bgColor = ""
    public static let color = "#C8C8C8"
    public static let fontSize = 19
    public static let iconSize = 28
    public static let loadingColor = "#C8C8C8"
    public static let zIndex = 10
    public static let customClass = ""
    public static let customStyle = UPStyle()
}

/// Adds the upstream-style `UPConfig.loadingPage` lookup without changing
/// the central config file, which may be edited by another integration.
public extension UPConfig {
    enum loadingPage {
        public static let loadingText = UPLoadingPageConfig.loadingText
        public static let image = UPLoadingPageConfig.image
        public static let loadingMode = UPLoadingPageConfig.loadingMode
        public static let loading = UPLoadingPageConfig.loading
        public static let bgColor = UPLoadingPageConfig.bgColor
        public static let color = UPLoadingPageConfig.color
        public static let fontSize = UPLoadingPageConfig.fontSize
        public static let iconSize = UPLoadingPageConfig.iconSize
        public static let loadingColor = UPLoadingPageConfig.loadingColor
        public static let zIndex = UPLoadingPageConfig.zIndex
        public static let customClass = UPLoadingPageConfig.customClass
        public static let customStyle = UPLoadingPageConfig.customStyle
    }
}
