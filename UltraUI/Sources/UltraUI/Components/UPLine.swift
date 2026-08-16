import SwiftUI

public struct UPLine: View {
    public enum Length: Equatable {
        case fraction(CGFloat)
        case points(CGFloat)
    }

    var color: String
    var length: String
    var direction: String
    var hairline: Bool
    var margin: Double
    var dashed: Bool

    public init(color: String = UPConfig.line.color,
                length: String = UPConfig.line.length,
                direction: String = UPConfig.line.direction,
                hairline: Bool = UPConfig.line.hairline,
                margin: Double = UPConfig.line.margin,
                dashed: Bool = UPConfig.line.dashed) {
        self.color = color
        self.length = length
        self.direction = direction
        self.hairline = hairline
        self.margin = margin
        self.dashed = dashed
    }

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
        .padding(CGFloat(margin))
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
