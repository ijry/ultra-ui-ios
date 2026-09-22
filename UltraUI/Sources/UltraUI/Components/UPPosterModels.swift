import Foundation
import SwiftUI

/// 上游 `json.views[].css` 与 `json.css` 的样式子集。
/// 值沿用上游写法（`'750rpx'` / `'32rpx'`），由 `UPPosterCSS.length(_:)` 折算。
public struct UPPosterCSS: Equatable, Sendable {
    public var left: String
    public var top: String
    public var width: String
    public var height: String
    public var background: String
    public var color: String
    public var fontSize: String
    public var fontWeight: String
    public var lineHeight: String
    public var textAlign: String
    public var radius: String
    /// 最多显示几行，超出用省略号，对应上游 `lineClamp`。
    public var lineClamp: Int

    public init(left: String = "",
                top: String = "",
                width: String = "",
                height: String = "",
                background: String = "",
                color: String = "",
                fontSize: String = "",
                fontWeight: String = "",
                lineHeight: String = "",
                textAlign: String = "",
                radius: String = "",
                lineClamp: Int = 0) {
        self.left = left
        self.top = top
        self.width = width
        self.height = height
        self.background = background
        self.color = color
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.lineHeight = lineHeight
        self.textAlign = textAlign
        self.radius = radius
        self.lineClamp = lineClamp
    }

    /// 对应上游 `convertRpxToPx`：`rpx` 走 `UPUnit.rpx`，其余按 `parseFloat` 取值。
    /// 上游为了保住宽高比，整张海报只取一次 rpx 比例，原生的 `UPUnit.rpx` 本身
    /// 就是固定的 375 设计基准，天然满足这一点。
    public static func length(_ value: String) -> CGFloat {
        let raw = value.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return 0 }
        if raw.hasSuffix("rpx") {
            return UPUnit.rpx(CGFloat(Double(raw.dropLast(3)) ?? 0))
        }
        if raw.hasSuffix("px") {
            return CGFloat(Double(raw.dropLast(2)) ?? 0)
        }
        return CGFloat(Double(raw) ?? 0)
    }

    public var frame: CGRect {
        CGRect(x: Self.length(left), y: Self.length(top),
               width: Self.length(width), height: Self.length(height))
    }

    public var isBold: Bool { fontWeight.lowercased() == "bold" || (Int(fontWeight) ?? 0) >= 600 }

    public var alignment: TextAlignment {
        switch textAlign.lowercased() {
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }

    public var frameAlignment: Alignment {
        switch textAlign.lowercased() {
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }
}

/// `json.views` 的一项，对应上游四种 `type`。
public struct UPPosterView: Equatable, Sendable {
    /// `text` / `image` / `qrcode` / `view`。
    public var type: String
    public var text: String
    public var src: String
    public var css: UPPosterCSS

    public init(type: String, text: String = "", src: String = "", css: UPPosterCSS = UPPosterCSS()) {
        self.type = type
        self.text = text
        self.src = src
        self.css = css
    }
}

/// 对应上游 `json` prop。
public struct UPPosterJSON: Equatable, Sendable {
    public var css: UPPosterCSS
    public var views: [UPPosterView]

    public init(css: UPPosterCSS = UPPosterCSS(), views: [UPPosterView] = []) {
        self.css = css
        self.views = views
    }

    /// 上游 `exportImage` 里 `json.css.width || '750rpx'`、`height || '1114rpx'`。
    public var size: CGSize {
        CGSize(width: css.width.isEmpty ? UPPosterCSS.length("750rpx") : UPPosterCSS.length(css.width),
               height: css.height.isEmpty ? UPPosterCSS.length("1114rpx") : UPPosterCSS.length(css.height))
    }
}

/// `exportImage()` 的返回值，对应上游 `{ width, height, path, blob }`。
/// 原生直接给出图片数据，`path` 是写入临时目录后的文件路径。
public struct UPPosterExport: Equatable, Sendable {
    public let width: CGFloat
    public let height: CGFloat
    public let path: String
    public let data: Data

    public init(width: CGFloat, height: CGFloat, path: String, data: Data) {
        self.width = width
        self.height = height
        self.path = path
        self.data = data
    }
}

/// 海报里的渐变背景，对应上游 `drawGradientBackground` 支持的 `linear-gradient`。
/// 上游同时提到 `radial-gradient`，但只解析出颜色列表后仍按线性绘制，此处只做线性。
public enum UPPosterGradient {
    /// 上游 `background.match(/linear-gradient\((\d+)deg/)`，取不到时默认 135°。
    public static func angle(of background: String) -> Double {
        guard let range = background.range(of: "linear-gradient(") else { return 135 }
        let rest = background[range.upperBound...]
        let digits = rest.prefix(while: { $0.isNumber })
        guard !digits.isEmpty, rest.dropFirst(digits.count).hasPrefix("deg") else { return 135 }
        return Double(digits) ?? 135
    }

    /// 取出 `linear-gradient(...)` 里的颜色列表（忽略百分比）。
    public static func colors(of background: String) -> [String] {
        guard let open = background.firstIndex(of: "("), let close = background.lastIndex(of: ")"),
              open < close else { return [] }
        return background[background.index(after: open)..<close]
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap { segment in
                guard !segment.isEmpty, !segment.hasSuffix("deg"),
                      !segment.hasPrefix("to ") else { return nil }
                // 去掉 `#fff 20%` 里的百分比。
                guard let separator = segment.lastIndex(of: " ") else { return segment }
                let tail = segment[segment.index(after: separator)...]
                return tail.hasSuffix("%")
                    ? String(segment[segment.startIndex..<separator]).trimmingCharacters(in: .whitespaces)
                    : segment
            }
    }

    /// 角度换算成 SwiftUI 的起止点：CSS 的 0deg 是自下而上，顺时针增加。
    public static func unitPoints(angle: Double) -> (start: UnitPoint, end: UnitPoint) {
        let radians = (angle - 90) * .pi / 180
        let dx = cos(radians) / 2
        let dy = sin(radians) / 2
        return (UnitPoint(x: 0.5 - dx, y: 0.5 - dy), UnitPoint(x: 0.5 + dx, y: 0.5 + dy))
    }

    public static func isGradient(_ background: String) -> Bool {
        background.contains("linear-gradient") || background.contains("radial-gradient")
    }
}
