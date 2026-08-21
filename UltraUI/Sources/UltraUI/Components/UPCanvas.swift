import SwiftUI

public enum UPCanvasCommandKind: String, Equatable, Sendable {
    case line
    case rectangle
    case circle
}

public enum UPCanvasCommand: Equatable, Sendable {
    case line(from: CGPoint, to: CGPoint, color: String = "#000000", lineWidth: CGFloat = 1)
    case rectangle(CGRect, color: String = "#000000", filled: Bool = false, lineWidth: CGFloat = 1)
    case circle(center: CGPoint, radius: CGFloat, color: String = "#000000", filled: Bool = false, lineWidth: CGFloat = 1)

    public var kind: UPCanvasCommandKind {
        switch self {
        case .line: return .line
        case .rectangle: return .rectangle
        case .circle: return .circle
        }
    }
}

/// A deterministic command-backed wrapper for SwiftUI `Canvas`.
public struct UPCanvas: View {
    public var width: CGFloat
    public var height: CGFloat
    public var commands: [UPCanvasCommand]

    public init(width: some UPImageUnitValue = 300, height: some UPImageUnitValue = 150,
                commands: [UPCanvasCommand] = []) {
        self.width = max(0, UPUnit.parse(width.upImageUnitValue))
        self.height = max(0, UPUnit.parse(height.upImageUnitValue))
        self.commands = commands
    }

    public func appending(_ command: UPCanvasCommand) -> UPCanvas {
        var copy = self
        copy.commands.append(command)
        return copy
    }

    public var cleared: UPCanvas {
        UPCanvas(width: width, height: height)
    }

    public var body: some View {
        Canvas { context, _ in
            for command in commands {
                switch command {
                case let .line(from, to, color, lineWidth):
                    var path = Path()
                    path.move(to: from)
                    path.addLine(to: to)
                    context.stroke(path, with: .color(UPColor.parse(color)), lineWidth: lineWidth)
                case let .rectangle(rect, color, filled, lineWidth):
                    let path = Path(rect)
                    if filled { context.fill(path, with: .color(UPColor.parse(color))) }
                    else { context.stroke(path, with: .color(UPColor.parse(color)), lineWidth: lineWidth) }
                case let .circle(center, radius, color, filled, lineWidth):
                    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                    let path = Path(ellipseIn: rect)
                    if filled { context.fill(path, with: .color(UPColor.parse(color))) }
                    else { context.stroke(path, with: .color(UPColor.parse(color)), lineWidth: lineWidth) }
                }
            }
        }
        .frame(width: width, height: height)
    }
}
