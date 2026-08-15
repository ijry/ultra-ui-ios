import SwiftUI

public enum UPColor {
    public static func parse(_ value: String, theme: UPTheme = .default) -> Color {
        if value.hasPrefix("#") {
            let hex = value.dropFirst()
            if hex.count == 6, let v = UInt32(hex, radix: 16) {
                return Color(hex: v)
            }
            if hex.count == 8, let v = UInt32(hex, radix: 16) {
                return Color(red: Double((v >> 24) & 0xFF) / 255,
                             green: Double((v >> 16) & 0xFF) / 255,
                             blue: Double((v >> 8) & 0xFF) / 255,
                             opacity: Double(v & 0xFF) / 255)
            }
        }
        switch value {
        case "primary": return theme.primary
        case "success": return theme.success
        case "error": return theme.error
        case "warning": return theme.warning
        case "info", "default": return theme.info
        case "main": return theme.main
        case "content": return theme.content
        case "tips": return theme.tips
        case "light": return theme.light
        case "border": return theme.border
        case "bg": return theme.bg
        case "disabled": return theme.disabled
        default: return theme.content
        }
    }
}
