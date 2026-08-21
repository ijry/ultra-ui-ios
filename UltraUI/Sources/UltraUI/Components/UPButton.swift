import SwiftUI

/// Leading-edge millisecond throttle used by `UPButton` click handling.
///
/// This mirrors uview-plus `throttleTime`: the first tap is delivered,
/// taps strictly inside the interval are ignored, and a tap at the interval
/// boundary is delivered.
struct UPButtonTapThrottle {
    private(set) var lastAcceptedTap: Date?

    mutating func acceptsTap(at date: Date, throttleTime: Double) -> Bool {
        guard throttleTime > 0 else { return true }

        if let lastAcceptedTap,
           date.timeIntervalSince(lastAcceptedTap) < throttleTime / 1_000 {
            return false
        }

        lastAcceptedTap = date
        return true
    }
}

public typealias UPButtonUnitValue = UPCheckboxUnitValue

public enum UPButtonOpenCapability: CaseIterable, Equatable, Sendable {
    case getPhoneNumber
    case getUserInfo
    case error
    case openSetting
    case launchApp
    case agreePrivacyAuthorization
}

/// Native SwiftUI counterpart of uview-plus `u-button`.
public struct UPButton: View {
    var type: String
    var size: String
    var shape: String
    var plain: Bool
    var disabled: Bool
    var loading: Bool
    var loadingText: String
    var loadingMode: String
    var loadingSize: Double
    // uni-app open capability props are accepted for source compatibility.
    var openType: String
    var formType: String
    var appParameter: String
    var hoverStopPropagation: Bool
    var lang: String
    var sessionFrom: String
    var sendMessageTitle: String
    var sendMessagePath: String
    var sendMessageImg: String
    var showMessageCard: Bool
    var dataName: String
    var throttleTime: Double
    var hoverStartTime: Double
    var hoverStayTime: Double
    var text: String
    var icon: String
    var iconColor: String
    var color: String
    var stop: Bool
    var hairline: Bool
    /// Native convenience retained from the first SwiftUI implementation.
    var block: Bool
    var onTap: (() -> Void)?
    var onClick: (() -> Void)?
    var onGetPhoneNumber: (() -> Void)?
    var onGetUserInfo: (() -> Void)?
    var onError: (() -> Void)?
    var onOpenSetting: (() -> Void)?
    var onLaunchApp: (() -> Void)?
    var onAgreePrivacyAuthorization: (() -> Void)?
    private var defaultSlotContent: AnyView?

    @State private var tapThrottle = UPButtonTapThrottle()
    @Environment(\.upTheme) private var theme

    public init<LoadingText: UPButtonUnitValue,
                LoadingSize: UPButtonUnitValue,
                ThrottleTime: UPButtonUnitValue,
                HoverStartTime: UPButtonUnitValue,
                HoverStayTime: UPButtonUnitValue,
                TextValue: UPButtonUnitValue>(type: String = UPConfig.button.type,
                size: String = UPConfig.button.size,
                shape: String = UPConfig.button.shape,
                plain: Bool = UPConfig.button.plain,
                disabled: Bool = UPConfig.button.disabled,
                loading: Bool = UPConfig.button.loading,
                loadingText: LoadingText = UPConfig.button.loadingText,
                loadingMode: String = UPConfig.button.loadingMode,
                loadingSize: LoadingSize = UPConfig.button.loadingSize,
                openType: String = UPConfig.button.openType,
                formType: String = UPConfig.button.formType,
                appParameter: String = UPConfig.button.appParameter,
                hoverStopPropagation: Bool = UPConfig.button.hoverStopPropagation,
                lang: String = UPConfig.button.lang,
                sessionFrom: String = UPConfig.button.sessionFrom,
                sendMessageTitle: String = UPConfig.button.sendMessageTitle,
                sendMessagePath: String = UPConfig.button.sendMessagePath,
                sendMessageImg: String = UPConfig.button.sendMessageImg,
                showMessageCard: Bool = UPConfig.button.showMessageCard,
                dataName: String = UPConfig.button.dataName,
                throttleTime: ThrottleTime = UPConfig.button.throttleTime,
                hoverStartTime: HoverStartTime = UPConfig.button.hoverStartTime,
                hoverStayTime: HoverStayTime = UPConfig.button.hoverStayTime,
                text: TextValue = UPConfig.button.text,
                icon: String = UPConfig.button.icon,
                iconColor: String = UPConfig.button.iconColor,
                color: String = UPConfig.button.color,
                stop: Bool = UPConfig.button.stop,
                hairline: Bool = UPConfig.button.hairline,
                block: Bool = UPConfig.button.block,
                onTap: (() -> Void)? = nil,
                onClick: (() -> Void)? = nil,
                onGetPhoneNumber: (() -> Void)? = nil,
                onGetUserInfo: (() -> Void)? = nil,
                onError: (() -> Void)? = nil,
                onOpenSetting: (() -> Void)? = nil,
                onLaunchApp: (() -> Void)? = nil,
                onAgreePrivacyAuthorization: (() -> Void)? = nil) {
        self.type = type
        self.size = size
        self.shape = shape
        self.plain = plain
        self.disabled = disabled
        self.loading = loading
        self.loadingText = loadingText.upCheckboxUnitValue
        self.loadingMode = loadingMode
        self.loadingSize = Double(loadingSize.upCheckboxUnitValue) ?? 0
        self.openType = openType
        self.formType = formType
        self.appParameter = appParameter
        self.hoverStopPropagation = hoverStopPropagation
        self.lang = lang
        self.sessionFrom = sessionFrom
        self.sendMessageTitle = sendMessageTitle
        self.sendMessagePath = sendMessagePath
        self.sendMessageImg = sendMessageImg
        self.showMessageCard = showMessageCard
        self.dataName = dataName
        self.throttleTime = Double(throttleTime.upCheckboxUnitValue) ?? 0
        self.hoverStartTime = Double(hoverStartTime.upCheckboxUnitValue) ?? 0
        self.hoverStayTime = Double(hoverStayTime.upCheckboxUnitValue) ?? 0
        self.text = text.upCheckboxUnitValue
        self.icon = icon
        self.iconColor = iconColor
        self.color = color
        self.stop = stop
        self.hairline = hairline
        self.block = block
        self.onTap = onTap
        self.onClick = onClick
        self.onGetPhoneNumber = onGetPhoneNumber
        self.onGetUserInfo = onGetUserInfo
        self.onError = onError
        self.onOpenSetting = onOpenSetting
        self.onLaunchApp = onLaunchApp
        self.onAgreePrivacyAuthorization = onAgreePrivacyAuthorization
    }

    /// SwiftUI mapping of uview-plus `u-button`'s default slot.
    ///
    /// The supplied content replaces `text` while the button is not loading.
    public init<Content: View,
                               LoadingText: UPButtonUnitValue,
                               LoadingSize: UPButtonUnitValue,
                               ThrottleTime: UPButtonUnitValue,
                               HoverStartTime: UPButtonUnitValue,
                               HoverStayTime: UPButtonUnitValue,
                               TextValue: UPButtonUnitValue>(type: String = UPConfig.button.type,
                               size: String = UPConfig.button.size,
                               shape: String = UPConfig.button.shape,
                               plain: Bool = UPConfig.button.plain,
                               disabled: Bool = UPConfig.button.disabled,
                               loading: Bool = UPConfig.button.loading,
                               loadingText: LoadingText = UPConfig.button.loadingText,
                               loadingMode: String = UPConfig.button.loadingMode,
                               loadingSize: LoadingSize = UPConfig.button.loadingSize,
                               openType: String = UPConfig.button.openType,
                               formType: String = UPConfig.button.formType,
                               appParameter: String = UPConfig.button.appParameter,
                               hoverStopPropagation: Bool = UPConfig.button.hoverStopPropagation,
                               lang: String = UPConfig.button.lang,
                               sessionFrom: String = UPConfig.button.sessionFrom,
                               sendMessageTitle: String = UPConfig.button.sendMessageTitle,
                               sendMessagePath: String = UPConfig.button.sendMessagePath,
                               sendMessageImg: String = UPConfig.button.sendMessageImg,
                               showMessageCard: Bool = UPConfig.button.showMessageCard,
                               dataName: String = UPConfig.button.dataName,
                               throttleTime: ThrottleTime = UPConfig.button.throttleTime,
                               hoverStartTime: HoverStartTime = UPConfig.button.hoverStartTime,
                               hoverStayTime: HoverStayTime = UPConfig.button.hoverStayTime,
                               text: TextValue = UPConfig.button.text,
                               icon: String = UPConfig.button.icon,
                               iconColor: String = UPConfig.button.iconColor,
                               color: String = UPConfig.button.color,
                               stop: Bool = UPConfig.button.stop,
                               hairline: Bool = UPConfig.button.hairline,
                               block: Bool = UPConfig.button.block,
                               onTap: (() -> Void)? = nil,
                               onClick: (() -> Void)? = nil,
                               onGetPhoneNumber: (() -> Void)? = nil,
                               onGetUserInfo: (() -> Void)? = nil,
                               onError: (() -> Void)? = nil,
                               onOpenSetting: (() -> Void)? = nil,
                               onLaunchApp: (() -> Void)? = nil,
                               onAgreePrivacyAuthorization: (() -> Void)? = nil,
                               @ViewBuilder content: () -> Content) {
        self.init(type: type,
                  size: size,
                  shape: shape,
                  plain: plain,
                  disabled: disabled,
                  loading: loading,
                  loadingText: loadingText,
                  loadingMode: loadingMode,
                  loadingSize: loadingSize,
                  openType: openType,
                  formType: formType,
                  appParameter: appParameter,
                  hoverStopPropagation: hoverStopPropagation,
                  lang: lang,
                  sessionFrom: sessionFrom,
                  sendMessageTitle: sendMessageTitle,
                  sendMessagePath: sendMessagePath,
                  sendMessageImg: sendMessageImg,
                  showMessageCard: showMessageCard,
                  dataName: dataName,
                  throttleTime: throttleTime,
                  hoverStartTime: hoverStartTime,
                  hoverStayTime: hoverStayTime,
                  text: text,
                  icon: icon,
                  iconColor: iconColor,
                  color: color,
                  stop: stop,
                  hairline: hairline,
                  block: block,
                  onTap: onTap,
                  onClick: onClick,
                  onGetPhoneNumber: onGetPhoneNumber,
                  onGetUserInfo: onGetUserInfo,
                  onError: onError,
                  onOpenSetting: onOpenSetting,
                  onLaunchApp: onLaunchApp,
                  onAgreePrivacyAuthorization: onAgreePrivacyAuthorization)
        defaultSlotContent = AnyView(content())
    }

    var hasDefaultSlot: Bool {
        defaultSlotContent != nil
    }

    public func triggerOpenCapability(_ capability: UPButtonOpenCapability) {
        switch capability {
        case .getPhoneNumber: onGetPhoneNumber?()
        case .getUserInfo: onGetUserInfo?()
        case .error: onError?()
        case .openSetting: onOpenSetting?()
        case .launchApp: onLaunchApp?()
        case .agreePrivacyAuthorization: onAgreePrivacyAuthorization?()
        }
    }

    public static func height(for size: String) -> CGFloat {
        switch size {
        case "large": return 50
        case "small": return 30
        case "mini": return 22
        default: return 40
        }
    }

    public static func fontSize(for size: String) -> CGFloat {
        switch size {
        case "large": return 16
        case "small": return 12
        case "mini": return 10
        default: return 14
        }
    }

    public var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 6) {
                if loading {
                    UPLoadingIcon(show: true,
                                  color: foregroundColor.upHexString,
                                  mode: loadingMode,
                                  size: loadingSize)
                } else if !icon.isEmpty {
                    UPIcon(name: icon,
                           color: iconColor.isEmpty ? foregroundColor.upHexString : iconColor,
                           size: "\(loadingSize)px")
                }
                if let defaultSlotContent, !loading {
                    defaultSlotContent
                        .font(.system(size: Self.fontSize(for: size)))
                        .foregroundStyle(foregroundColor)
                } else if !displayText.isEmpty {
                    Text(displayText)
                        .font(.system(size: Self.fontSize(for: size)))
                        .foregroundStyle(foregroundColor)
                }
            }
            .frame(maxWidth: block || size == "large" || size == "normal" ? .infinity : nil)
            .frame(minWidth: minWidth, minHeight: Self.height(for: size))
            .padding(.horizontal, horizontalPadding)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: hairline ? 0.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled || loading)
    }

    private var displayText: String {
        if loading && !loadingText.isEmpty { return loadingText }
        return text
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case "large": return 20
        case "small": return 12
        case "mini": return 8
        default: return 16
        }
    }

    private var minWidth: CGFloat? {
        switch size {
        case "small": return 60
        case "mini": return 50
        default: return nil
        }
    }

    private var cornerRadius: CGFloat {
        shape == "circle" ? Self.height(for: size) / 2 : 3
    }

    private var themeColor: Color {
        switch type {
        case "primary": return theme.primary
        case "success": return theme.success
        case "error": return theme.error
        case "warning": return theme.warning
        default: return theme.info
        }
    }

    private var backgroundColor: Color {
        if plain { return .clear }
        if !color.isEmpty { return UPColor.parse(color, theme: theme) }
        return themeColor
    }

    private var foregroundColor: Color {
        if plain { return !color.isEmpty ? UPColor.parse(color, theme: theme) : themeColor }
        return .white
    }

    private var borderColor: Color {
        if !color.isEmpty { return UPColor.parse(color, theme: theme) }
        return themeColor
    }

    private func handleTap() {
        guard !disabled, !loading else { return }
        guard tapThrottle.acceptsTap(at: Date(), throttleTime: throttleTime) else { return }
        onTap?()
        onClick?()
    }
}

public extension UPButton {
    func onTap(_ action: @escaping () -> Void) -> UPButton {
        var copy = self
        copy.onTap = action
        return copy
    }

    /// uview-plus compatible click event. It is invoked after `onTap` for each accepted tap.
    func onClick(_ action: @escaping () -> Void) -> UPButton {
        var copy = self
        copy.onClick = action
        return copy
    }
}

extension Color {
    var upHexString: String {
        #if canImport(UIKit)
        let nativeColor = UIColor(self)
        #else
        let nativeColor = NSColor(self)
        #endif
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        nativeColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
