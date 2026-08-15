import SwiftUI

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
    var text: String
    var icon: String
    var iconColor: String
    var color: String
    var hairline: Bool
    var block: Bool
    var throttleTime: Double
    var onTap: (() -> Void)?

    @State private var lastTap = Date.distantPast
    @Environment(\.upTheme) private var theme

    public init(type: String = UPConfig.button.type,
                size: String = UPConfig.button.size,
                shape: String = UPConfig.button.shape,
                plain: Bool = UPConfig.button.plain,
                disabled: Bool = UPConfig.button.disabled,
                loading: Bool = UPConfig.button.loading,
                loadingText: String = UPConfig.button.loadingText,
                loadingMode: String = UPConfig.button.loadingMode,
                loadingSize: Double = UPConfig.button.loadingSize,
                text: String = UPConfig.button.text,
                icon: String = UPConfig.button.icon,
                iconColor: String = UPConfig.button.iconColor,
                color: String = UPConfig.button.color,
                hairline: Bool = UPConfig.button.hairline,
                block: Bool = UPConfig.button.block,
                throttleTime: Double = UPConfig.button.throttleTime,
                onTap: (() -> Void)? = nil) {
        self.type = type
        self.size = size
        self.shape = shape
        self.plain = plain
        self.disabled = disabled
        self.loading = loading
        self.loadingText = loadingText
        self.loadingMode = loadingMode
        self.loadingSize = loadingSize
        self.text = text
        self.icon = icon
        self.iconColor = iconColor
        self.color = color
        self.hairline = hairline
        self.block = block
        self.throttleTime = throttleTime
        self.onTap = onTap
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
        case "small": return 14
        case "mini": return 12
        default: return 15
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
                if !displayText.isEmpty {
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
        if throttleTime > 0 {
            let now = Date()
            if now.timeIntervalSince(lastTap) < throttleTime / 1000 { return }
            lastTap = now
        }
        onTap?()
    }
}

public extension UPButton {
    func onTap(_ action: @escaping () -> Void) -> UPButton {
        var copy = self
        copy.onTap = action
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
