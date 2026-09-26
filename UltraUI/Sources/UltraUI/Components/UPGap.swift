import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-gap`.
///
/// 上游 `gapStyle`：`height`/`marginTop`/`marginBottom` 走 `addUnit`（`String | Number`），
/// 背景色 `resolvedBg = (bgColor && bgColor !== 'transparent') ? bgColor
/// : upThemeVar('--up-gap-bg-color', upThemeIsDark ? '#111111' : 'transparent')`，
/// 最后 `deepMerge(style, addStyle(customStyle))`。
public struct UPGap: View {
    public var bgColor: String
    public var height: Double
    public var marginTop: Double
    public var marginBottom: Double
    /// 上游 mixin 提供的 `customStyle`，`gapStyle` 末尾 `deepMerge` 叠加、可覆盖内建样式。
    public var customStyle: UPStyle

    public init(bgColor: String = UPConfig.gap.bgColor,
                height: some UPImageUnitValue = UPConfig.gap.height,
                marginTop: some UPImageUnitValue = UPConfig.gap.marginTop,
                marginBottom: some UPImageUnitValue = UPConfig.gap.marginBottom,
                customStyle: UPStyle = UPStyle()) {
        self.bgColor = bgColor
        self.height = Double(UPUnit.parse(height.upImageUnitValue))
        self.marginTop = Double(UPUnit.parse(marginTop.upImageUnitValue))
        self.marginBottom = Double(UPUnit.parse(marginBottom.upImageUnitValue))
        self.customStyle = customStyle
    }

    @Environment(\.upTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    /// 上游 `gapStyle.backgroundColor`：给了非 transparent 颜色时原样用；否则回落
    /// `--up-gap-bg-color`（亮 transparent / 暗 #111111）。
    public func resolvedBackgroundValue(isDark: Bool) -> String {
        if !bgColor.isEmpty, bgColor != "transparent" { return bgColor }
        return isDark ? "#111111" : "transparent"
    }

    public var body: some View {
        let bg = resolvedBackgroundValue(isDark: colorScheme == .dark)
        Color.clear
            .frame(height: height)
            .background(bg == "transparent" ? Color.clear : UPColor.parse(bg, theme: theme))
            .padding(.top, marginTop)
            .padding(.bottom, marginBottom)
            .upStyle(customStyle)
    }
}
