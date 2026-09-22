import Foundation
import SwiftUI

/// 渐变色的一个节点，对应上游 `gradientColors` 的元素。
public struct UPColorPickerStop: Equatable, Sendable {
    public var color: String
    /// 0…1，对应上游 `percent`。
    public var percent: Double

    public init(color: String, percent: Double) {
        self.color = color
        self.percent = min(max(percent, 0), 1)
    }
}

/// 渐变方向，对应上游 `gradientDirections` 与 `getDirectionAngle`。
public enum UPColorPickerDirection: String, CaseIterable, Sendable {
    case toRight = "to right"
    case toBottom = "to bottom"
    case toLeft = "to left"
    case toTop = "to top"
    case toBottomRight = "to bottom right"
    case toBottomLeft = "to bottom left"
    case toTopLeft = "to top left"
    case toTopRight = "to top right"

    /// 上游模板里只给了四个可选方向的中文标签。
    public var label: String {
        switch self {
        case .toRight: return "从左到右"
        case .toBottom: return "从上到下"
        case .toLeft: return "从右到左"
        case .toTop: return "从下到上"
        case .toBottomRight: return "从左上到右下"
        case .toBottomLeft: return "从右上到左下"
        case .toTopLeft: return "从右下到左上"
        case .toTopRight: return "从左下到右上"
        }
    }

    /// 对应上游 `getDirectionAngle`。
    public var angle: Double {
        switch self {
        case .toRight: return 0
        case .toBottom: return 90
        case .toLeft: return 180
        case .toTop: return 270
        case .toBottomRight: return 45
        case .toBottomLeft: return 135
        case .toTopLeft: return 225
        case .toTopRight: return 315
        }
    }

    /// SwiftUI 的渐变起止点。
    public var unitPoints: (start: UnitPoint, end: UnitPoint) {
        switch self {
        case .toRight: return (.leading, .trailing)
        case .toBottom: return (.top, .bottom)
        case .toLeft: return (.trailing, .leading)
        case .toTop: return (.bottom, .top)
        case .toBottomRight: return (.topLeading, .bottomTrailing)
        case .toBottomLeft: return (.topTrailing, .bottomLeading)
        case .toTopLeft: return (.bottomTrailing, .topLeading)
        case .toTopRight: return (.bottomLeading, .topTrailing)
        }
    }
}

/// 取色器用到的颜色换算，集中放这里方便单测。
public enum UPColorMath {
    /// 对应上游 `hslToRgb(h, s, l, a)`：输出 `rgba(r, g, b, a.toFixed(2))`。
    /// `h` 取 0…360，`s` / `l` 取 0…100。
    public static func rgbaText(hue: Double, saturation: Double, lightness: Double, alpha: Double) -> String {
        let components = rgb(hue: hue, saturation: saturation, lightness: lightness)
        let alphaText = String(format: "%.2f", min(max(alpha, 0), 1))
        return "rgba(\(Int(components.red.rounded())), \(Int(components.green.rounded())), "
            + "\(Int(components.blue.rounded())), \(alphaText))"
    }

    /// HSL → RGB（0…255），算法与上游 `hue2rgb` 一致。
    public static func rgb(hue: Double,
                           saturation: Double,
                           lightness: Double) -> (red: Double, green: Double, blue: Double) {
        let h = ((hue.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360) / 360
        let s = min(max(saturation, 0), 100) / 100
        let l = min(max(lightness, 0), 100) / 100
        guard s > 0 else { return (l * 255, l * 255, l * 255) }
        func component(_ p: Double, _ q: Double, _ raw: Double) -> Double {
            var t = raw
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1 / 6 { return p + (q - p) * 6 * t }
            if t < 1 / 2 { return q }
            if t < 2 / 3 { return p + (q - p) * (2 / 3 - t) * 6 }
            return p
        }
        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q
        return (component(p, q, h + 1 / 3) * 255,
                component(p, q, h) * 255,
                component(p, q, h - 1 / 3) * 255)
    }

    /// `#rgb` / `#rrggbb` / `#rrggbbaa` / `rgb()` / `rgba()` → 0…1 的四个通道。
    public static func components(of value: String) -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        let raw = value.trimmingCharacters(in: .whitespaces).lowercased()
        if raw.hasPrefix("#") {
            var hex = String(raw.dropFirst())
            guard hex.allSatisfy(\.isHexDigit) else { return nil }
            if hex.count == 3 || hex.count == 4 {
                hex = hex.map { String(repeating: String($0), count: 2) }.joined()
            }
            guard hex.count == 6 || hex.count == 8, let number = UInt32(hex, radix: 16) else { return nil }
            if hex.count == 6 {
                return (Double((number >> 16) & 0xFF) / 255,
                        Double((number >> 8) & 0xFF) / 255,
                        Double(number & 0xFF) / 255,
                        1)
            }
            return (Double((number >> 24) & 0xFF) / 255,
                    Double((number >> 16) & 0xFF) / 255,
                    Double((number >> 8) & 0xFF) / 255,
                    Double(number & 0xFF) / 255)
        }
        guard raw.hasPrefix("rgb"),
              let open = raw.firstIndex(of: "("),
              let close = raw.lastIndex(of: ")"), open < close else { return nil }
        let parts = raw[raw.index(after: open)..<close]
            .split(whereSeparator: { $0 == "," || $0 == "/" || $0 == " " })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard parts.count == 3 || parts.count == 4 else { return nil }
        func channel(_ text: String) -> Double {
            if text.hasSuffix("%"), let percent = Double(text.dropLast()) { return min(max(percent / 100, 0), 1) }
            return min(max((Double(text) ?? 0) / 255, 0), 1)
        }
        let alpha: Double
        if parts.count == 4 {
            let text = parts[3]
            alpha = text.hasSuffix("%") ? (Double(text.dropLast()) ?? 100) / 100 : (Double(text) ?? 1)
        } else {
            alpha = 1
        }
        return (channel(parts[0]), channel(parts[1]), channel(parts[2]), min(max(alpha, 0), 1))
    }

    /// RGB → HSL，供把外部传入的色值还原成上游的三个游标位置。
    public static func hsl(of value: String) -> (hue: Double, saturation: Double, lightness: Double, alpha: Double)? {
        guard let parts = components(of: value) else { return nil }
        let maxValue = max(parts.red, parts.green, parts.blue)
        let minValue = min(parts.red, parts.green, parts.blue)
        let lightness = (maxValue + minValue) / 2
        guard maxValue > minValue else { return (0, 0, lightness * 100, parts.alpha) }
        let delta = maxValue - minValue
        let saturation = lightness > 0.5 ? delta / (2 - maxValue - minValue) : delta / (maxValue + minValue)
        var hue: Double
        if maxValue == parts.red {
            hue = (parts.green - parts.blue) / delta + (parts.green < parts.blue ? 6 : 0)
        } else if maxValue == parts.green {
            hue = (parts.blue - parts.red) / delta + 2
        } else {
            hue = (parts.red - parts.green) / delta + 4
        }
        hue *= 60
        return (hue, saturation * 100, lightness * 100, parts.alpha)
    }

    /// 对应上游 `gradientStyle`：`linear-gradient(dir, color pct%, ...)`。
    public static func gradientText(stops: [UPColorPickerStop], direction: UPColorPickerDirection) -> String {
        let colors = stops
            .map { "\($0.color) \(Int(($0.percent * 100).rounded()))%" }
            .joined(separator: ", ")
        return "linear-gradient(\(direction.rawValue), \(colors))"
    }

    /// 解析 `linear-gradient(...)`，取出方向与节点；解析不出来返回 nil。
    public static func gradient(of value: String) -> (direction: UPColorPickerDirection, stops: [UPColorPickerStop])? {
        let raw = value.trimmingCharacters(in: .whitespaces)
        guard raw.lowercased().hasPrefix("linear-gradient("), raw.hasSuffix(")") else { return nil }
        let inner = String(raw.dropFirst("linear-gradient(".count).dropLast())
        var segments: [String] = []
        var depth = 0
        var current = ""
        for character in inner {
            if character == "(" { depth += 1 }
            if character == ")" { depth -= 1 }
            if character == ",", depth == 0 {
                segments.append(current)
                current = ""
                continue
            }
            current.append(character)
        }
        if !current.isEmpty { segments.append(current) }
        guard segments.count >= 2 else { return nil }
        let directionText = segments[0].trimmingCharacters(in: .whitespaces).lowercased()
        let direction = UPColorPickerDirection(rawValue: directionText) ?? .toRight
        let stops = segments.dropFirst().compactMap { segment -> UPColorPickerStop? in
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            guard let separator = trimmed.lastIndex(of: " ") else {
                return UPColorPickerStop(color: trimmed, percent: 0)
            }
            let colorText = String(trimmed[trimmed.startIndex..<separator]).trimmingCharacters(in: .whitespaces)
            let percentText = String(trimmed[trimmed.index(after: separator)...])
                .trimmingCharacters(in: .whitespaces)
            guard percentText.hasSuffix("%"), let percent = Double(percentText.dropLast()) else {
                return UPColorPickerStop(color: trimmed, percent: 0)
            }
            return UPColorPickerStop(color: colorText, percent: percent / 100)
        }
        guard stops.count >= 2 else { return nil }
        return (direction, stops)
    }

    public static func isGradient(_ value: String) -> Bool {
        value.lowercased().contains("linear-gradient")
    }
}
