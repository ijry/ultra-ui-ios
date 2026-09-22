import SwiftUI

/// A string-or-number value accepted by uview-plus `u-overlay` unit props.
public typealias UPOverlayUnitValue = UPImageUnitValue

/// Native SwiftUI counterpart of uview-plus `u-overlay`.
///
/// 上游是 `u-transition` 包一层：`overlayStyle` 固定 `position: fixed` 铺满四边、
/// 底色是 `rgba(0, 0, 0, opacity)`，`customStyle` 由 `deepMerge` 叠在上面，
/// 点击抛 `click`，`touchmove` 被 `stop.prevent` 吞掉以锁住底层滚动。
public struct UPOverlay<Content: View>: View {
    var show: Bool
    var zIndex: Double
    /// 上游 `duration`：`u-transition` 的淡入淡出时长，单位 ms。
    var duration: Double
    /// 上游 `opacity`：当作 `rgba` 的第四个参数。
    var opacity: Double
    /// 上游 mixin 提供的 `customStyle`，`deepMerge` 时在内建样式之后，故可覆盖。
    var customStyle: UPStyle
    var onTap: (() -> Void)?
    var onClick: (() -> Void)?

    private let content: Content

    public init(show: Bool = UPConfig.overlay.show,
                zIndex: any UPOverlayUnitValue = UPConfig.overlay.zIndex,
                duration: any UPOverlayUnitValue = UPConfig.overlay.duration,
                opacity: any UPOverlayUnitValue = UPConfig.overlay.opacity,
                customStyle: UPStyle = UPStyle(),
                onTap: (() -> Void)? = nil,
                onClick: (() -> Void)? = nil,
                @ViewBuilder content: () -> Content) {
        self.show = show
        self.zIndex = Double(UPUnit.parse(zIndex.upImageUnitValue))
        self.duration = Double(UPUnit.parse(duration.upImageUnitValue))
        self.opacity = Self.parseOpacity(opacity.upImageUnitValue)
        self.customStyle = customStyle
        self.onTap = onTap
        self.onClick = onClick
        self.content = content()
    }

    /// `opacity` 上游是 `String | Number`，小数不能走 `UPUnit.parse`（会丢精度）。
    nonisolated static func parseOpacity(_ value: String) -> Double {
        guard let parsed = Double(value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return UPConfig.overlay.opacity
        }
        return parsed.isFinite ? parsed : UPConfig.overlay.opacity
    }

    public static func allowsHitTesting(show: Bool) -> Bool {
        show
    }

    /// 上游 `overlayStyle['background-color'] = rgba(0, 0, 0, opacity)`，
    /// 隐藏时由 `u-transition` 把整层淡出。
    public var resolvedOpacity: Double {
        show ? Swift.min(Swift.max(opacity, 0), 1) : 0
    }

    public var body: some View {
        Color.black
            .opacity(resolvedOpacity)
            .ignoresSafeArea()
            // 上游默认插槽渲染在遮罩之上（`u-transition` 的子节点）。
            .overlay { content }
            .contentShape(Rectangle())
            .allowsHitTesting(Self.allowsHitTesting(show: show))
            .onTapGesture {
                guard show else { return }
                onTap?()
                onClick?()
            }
            .animation(.easeInOut(duration: Swift.max(0, duration) / 1_000), value: show)
            // 上游 `customStyle` 走 deepMerge 覆盖内建样式，因此叠在最后。
            .upStyle(customStyle)
            .zIndex(zIndex)
    }
}

public extension UPOverlay where Content == EmptyView {
    init(show: Bool = UPConfig.overlay.show,
         zIndex: any UPOverlayUnitValue = UPConfig.overlay.zIndex,
         duration: any UPOverlayUnitValue = UPConfig.overlay.duration,
         opacity: any UPOverlayUnitValue = UPConfig.overlay.opacity,
         customStyle: UPStyle = UPStyle(),
         onTap: (() -> Void)? = nil,
         onClick: (() -> Void)? = nil) {
        self.init(show: show,
                  zIndex: zIndex,
                  duration: duration,
                  opacity: opacity,
                  customStyle: customStyle,
                  onTap: onTap,
                  onClick: onClick,
                  content: EmptyView.init)
    }
}

public extension UPOverlay {
    func onTap(_ action: @escaping () -> Void) -> UPOverlay {
        var copy = self
        copy.onTap = action
        return copy
    }

    func onClick(_ action: @escaping () -> Void) -> UPOverlay {
        var copy = self
        copy.onClick = action
        return copy
    }
}
