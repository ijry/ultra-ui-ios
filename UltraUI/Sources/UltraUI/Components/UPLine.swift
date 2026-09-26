import SwiftUI

public struct UPLine: View {
    public enum Length: Equatable {
        case fraction(CGFloat)
        case points(CGFloat)
    }

    public var color: String
    public var length: String
    public var direction: String
    public var hairline: Bool
    public var margin: String
    public var dashed: Bool
    /// 上游 mixin 提供的 `customStyle`，`lineStyle` 末尾 `deepMerge` 叠加、可覆盖内建样式。
    public var customStyle: UPStyle

    public init(color: String = UPConfig.line.color,
                length: some UPImageUnitValue = UPConfig.line.length,
                direction: String = UPConfig.line.direction,
                hairline: Bool = UPConfig.line.hairline,
                margin: some UPImageUnitValue = UPConfig.line.margin,
                dashed: Bool = UPConfig.line.dashed,
                customStyle: UPStyle = UPStyle()) {
        self.color = color
        self.length = length.upImageUnitValue
        self.direction = direction
        self.hairline = hairline
        self.margin = margin.upImageUnitValue
        self.dashed = dashed
        self.customStyle = customStyle
    }

    /// 上游 CSS `margin` 简写解析（1/2/3/4 值）。值走 `UPUnit.parse`（支持 px/rpx），
    /// 空串或解析不到时按 0 处理。
    public static func marginInsets(_ value: String) -> EdgeInsets {
        let parts = value.split(whereSeparator: { $0 == " " })
            .map { UPUnit.parse(String($0)) }
        switch parts.count {
        case 0:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        case 1:
            let v = parts[0]
            return EdgeInsets(top: v, leading: v, bottom: v, trailing: v)
        case 2:
            // 上下 / 左右
            return EdgeInsets(top: parts[0], leading: parts[1], bottom: parts[0], trailing: parts[1])
        case 3:
            // 上 / 左右 / 下
            return EdgeInsets(top: parts[0], leading: parts[1], bottom: parts[2], trailing: parts[1])
        default:
            // 上 / 右 / 下 / 左（CSS 顺序）
            return EdgeInsets(top: parts[0], leading: parts[3], bottom: parts[2], trailing: parts[1])
        }
    }

    /// 实例级 margin insets。
    public var marginInsets: EdgeInsets { Self.marginInsets(margin) }

    /// Parses uview-plus `length` values such as `"100%"`, `"20px"`, and `"650rpx"`.
    public static func parsedLength(_ value: String) -> Length {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.hasSuffix("%"), let percentage = Double(normalized.dropLast()) {
            return .fraction(CGFloat(percentage / 100))
        }
        return .points(UPUnit.parse(normalized))
    }

    @Environment(\.upTheme) private var theme

    public var body: some View {
        Group {
            if direction == "row" {
                horizontalLine
            } else {
                verticalLine
            }
        }
        .padding(marginInsets)
        .upStyle(customStyle)
    }

    private var lineColor: Color {
        UPColor.parse(color, theme: theme)
    }

    private var lineWidth: CGFloat {
        hairline ? 0.5 : 1
    }

    private var configuredLength: Length {
        Self.parsedLength(length)
    }

    private var horizontalLine: some View {
        Group {
            switch configuredLength {
            case .points(let points):
                lineShape(horizontal: true)
                    .frame(width: points, height: lineWidth)
            case .fraction(let fraction):
                GeometryReader { proxy in
                    lineShape(horizontal: true)
                        .frame(width: proxy.size.width * fraction, height: lineWidth)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: lineWidth)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var verticalLine: some View {
        Group {
            switch configuredLength {
            case .points(let points):
                lineShape(horizontal: false)
                    .frame(width: lineWidth, height: points)
            case .fraction(let fraction):
                GeometryReader { proxy in
                    lineShape(horizontal: false)
                        .frame(width: lineWidth, height: proxy.size.height * fraction)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(width: lineWidth)
            }
        }
        .frame(width: lineWidth, alignment: .top)
    }

    @ViewBuilder
    private func lineShape(horizontal: Bool) -> some View {
        if dashed {
            DashedLine(color: lineColor, width: lineWidth, horizontal: horizontal)
        } else {
            Rectangle().fill(lineColor)
        }
    }
}

private struct DashedLine: View {
    let color: Color
    let width: CGFloat
    let horizontal: Bool

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                if horizontal {
                    let y = proxy.size.height / 2
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                } else {
                    let x = proxy.size.width / 2
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: width, dash: [4, 3]))
        }
    }
}
