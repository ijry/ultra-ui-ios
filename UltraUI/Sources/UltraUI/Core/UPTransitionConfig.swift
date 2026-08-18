import Foundation

/// Defaults mirrored from uview-plus `u-transition`.
///
/// The dedicated namespace keeps the component defaults available even in
/// integrations that do not use the larger ``UPConfig`` table directly.
public enum UPTransitionConfig {
    public static let show = false
    public static let mode = "fade"
    public static let duration = "300"
    public static let timingFunction = "ease-out"
    public static let customStyle = UPStyle()
}

/// Adds the upstream-style `UPConfig.transition` lookup without changing the
/// generated/configuration source file that other components may be editing.
public extension UPConfig {
    enum transition {
        public static let show = UPTransitionConfig.show
        public static let mode = UPTransitionConfig.mode
        public static let duration = UPTransitionConfig.duration
        public static let timingFunction = UPTransitionConfig.timingFunction
        public static let customStyle = UPTransitionConfig.customStyle
    }
}
