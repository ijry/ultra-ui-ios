import SwiftUI

@MainActor
private final class UPNotifyState { var show: Bool; init(show: Bool) { self.show = show } }

/// Top notification overlay corresponding to uview-plus `u-notify`.
@MainActor
public struct UPNotify: View {
    /// 上游 `containerStyle` 把层级写死为 10076，不作为 prop 暴露。
    public static let overlayZIndex: Double = 10_076

    public var message: String
    public var type: String
    public var duration: Int
    public var top: CGFloat
    public var color: String
    public var bgColor: String
    public var fontSize: CGFloat
    public var safeAreaInsetTop: Bool
    public var show: Bool { state.show }
    private let state: UPNotifyState
    private var onOpenHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?
    @Environment(\.upTheme) private var theme

    public init(show: Bool = false,
                message: String = UPConfig.notify.message,
                type: String = UPConfig.notify.type,
                duration: Int = UPConfig.notify.duration,
                top: some UPImageUnitValue = UPConfig.notify.top,
                color: String = UPConfig.notify.color,
                bgColor: String = UPConfig.notify.bgColor,
                fontSize: some UPImageUnitValue = UPConfig.notify.fontSize,
                safeAreaInsetTop: Bool = UPConfig.notify.safeAreaInsetTop) {
        self.message = message
        self.type = type
        self.duration = max(duration, 0)
        self.top = UPUnit.parse(top.upImageUnitValue)
        self.color = color
        self.bgColor = bgColor
        self.fontSize = UPUnit.parse(fontSize.upImageUnitValue)
        self.safeAreaInsetTop = safeAreaInsetTop
        self.state = UPNotifyState(show: show)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if safeAreaInsetTop { UPStatusBar() }
            HStack(spacing: 0) {
                if showsIcon {
                    UPIcon(name: iconName, color: color, size: "\(iconSize)px")
                        .padding(.trailing, 4)
                }
                Text(message)
                    .font(.system(size: fontSize))
                    .foregroundStyle(UPColor.parse(color, theme: theme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
        .background(resolvedBackgroundColor)
        .padding(.top, top)
        .zIndex(Self.overlayZIndex)
        .opacity(show ? 1 : 0)
        .allowsHitTesting(show)
    }

    /// 上游只在 `bgColor` 非空时覆盖 `.u-notify--{type}` 的 SCSS 底色。
    public var backgroundColorToken: String { Self.backgroundColorToken(bgColor: bgColor, type: type) }

    public var iconName: String { Self.iconName(for: type) }

    public var showsIcon: Bool { !iconName.isEmpty }

    /// 上游图标尺寸为 `1.3 * fontSize`。
    public var iconSize: CGFloat { 1.3 * fontSize }

    nonisolated public static func backgroundColorToken(bgColor: String, type: String) -> String {
        guard bgColor.isEmpty else { return bgColor }
        switch type {
        case "primary", "success", "error", "warning": return type
        default: return ""
        }
    }

    nonisolated public static func iconName(for type: String) -> String {
        switch type {
        case "success": return "checkmark-circle"
        case "error": return "close-circle"
        case "warning": return "error-circle"
        default: return ""
        }
    }

    private var resolvedBackgroundColor: Color {
        let token = backgroundColorToken
        return token.isEmpty ? .clear : UPColor.parse(token, theme: theme)
    }

    public func open() { guard !show else { return }; state.show = true; onOpenHandler?() }
    public func close() { guard show else { return }; state.show = false; onCloseHandler?() }

    public func onOpen(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onOpenHandler = action; return copy }
    public func onClose(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onCloseHandler = action; return copy }
}
