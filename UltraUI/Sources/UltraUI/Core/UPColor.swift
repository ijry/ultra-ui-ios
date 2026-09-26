import SwiftUI

public enum UPColor {
    public static func parse(_ value: String, theme: UPTheme = .default) -> Color {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        // 上游样式里常见的全透明关键字。
        if lower == "transparent" || lower == "none" { return .clear }

        if trimmed.hasPrefix("#") {
            let hex = trimmed.dropFirst()
            // CSS 简写形式：`#rgb` / `#rgba` 每位复写一次，与展开的 6/8 位等价。
            if hex.count == 3 || hex.count == 4, hex.allSatisfy(\.isHexDigit) {
                let expanded = hex.map { String(repeating: String($0), count: 2) }.joined()
                return parse("#" + expanded, theme: theme)
            }
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

        // CSS `rgb()` / `rgba()` 函数式颜色。
        if lower.hasPrefix("rgb"), let color = parseRGBFunction(lower) {
            return color
        }

        switch lower {
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

    /// 解析 `rgb(r, g, b)` / `rgba(r, g, b, a)`。r/g/b 支持 0-255 或百分比，
    /// a 支持 0-1 小数（含省略前导 0 的 `.5`）或百分比。解析失败返回 nil 让上层兜底。
    private static func parseRGBFunction(_ value: String) -> Color? {
        guard let open = value.firstIndex(of: "("),
              let close = value.lastIndex(of: ")") else { return nil }
        let inner = value[value.index(after: open)..<close]
        let parts = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 3 || parts.count == 4 else { return nil }

        func channel(_ s: String) -> Double? {
            if s.hasSuffix("%"), let p = Double(s.dropLast()) { return max(0, min(1, p / 100)) }
            guard let n = Double(s) else { return nil }
            return max(0, min(1, n / 255))
        }
        func alpha(_ s: String) -> Double? {
            if s.hasSuffix("%"), let p = Double(s.dropLast()) { return max(0, min(1, p / 100)) }
            guard let n = Double(s) else { return nil }
            return max(0, min(1, n))
        }

        guard let r = channel(parts[0]), let g = channel(parts[1]), let b = channel(parts[2]) else { return nil }
        let a: Double
        if parts.count == 4 {
            guard let parsed = alpha(parts[3]) else { return nil }
            a = parsed
        } else {
            a = 1
        }
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}
