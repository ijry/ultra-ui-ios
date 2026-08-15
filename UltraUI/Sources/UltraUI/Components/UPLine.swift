import SwiftUI

public struct UPLine: View {
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

    @Environment(\.upTheme) private var theme

    public var body: some View {
        let isRow = direction == "row"
        let lineColor = UPColor.parse(color, theme: theme)
        let lineWidth: CGFloat = hairline ? 0.5 : 1
        let lineView = Group {
            if dashed {
                DashedLine(color: lineColor, width: lineWidth)
            } else {
                Rectangle().fill(lineColor).frame(height: lineWidth)
            }
        }
        return Group {
            if isRow {
                HStack {
                    lineView.frame(maxWidth: .infinity)
                }
                .frame(height: 1)
                .padding(.vertical, margin)
            } else {
                VStack {
                    lineView.frame(width: lineWidth)
                }
                .frame(width: 1)
                .padding(.horizontal, margin)
            }
        }
    }
}

private struct DashedLine: View {
    let color: Color
    let width: CGFloat
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: geo.size.width, y: 0))
            }
            .stroke(color, style: StrokeStyle(lineWidth: width, dash: [4, 3]))
        }
        .frame(height: width)
    }
}
