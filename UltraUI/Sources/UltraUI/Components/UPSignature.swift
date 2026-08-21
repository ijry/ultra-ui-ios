import SwiftUI

public struct UPSignatureStroke: Equatable, Sendable, Codable {
    public var points: [CGPoint]
    public init(points: [CGPoint]) { self.points = points }
}

/// Touch signature model with a Canvas renderer and deterministic export.
@MainActor
public final class UPSignature: View {
    public let width: CGFloat
    public let height: CGFloat
    public var color: String
    public var lineWidth: CGFloat
    public private(set) var strokes: [UPSignatureStroke] = []
    private var onChangeHandler: (([UPSignatureStroke]) -> Void)?

    public init(width: some UPImageUnitValue = 300, height: some UPImageUnitValue = 150,
                color: String = "#000000", lineWidth: some UPImageUnitValue = 2,
                onChange: (([UPSignatureStroke]) -> Void)? = nil) {
        self.width = max(0, UPUnit.parse(width.upImageUnitValue))
        self.height = max(0, UPUnit.parse(height.upImageUnitValue))
        self.color = color
        self.lineWidth = max(0, UPUnit.parse(lineWidth.upImageUnitValue))
        self.onChangeHandler = onChange
    }

    public var isEmpty: Bool { strokes.isEmpty }

    public func onChange(_ action: @escaping ([UPSignatureStroke]) -> Void) -> UPSignature {
        onChangeHandler = action
        return self
    }

    public func addStroke(_ points: [CGPoint]) {
        guard points.count > 1 else { return }
        strokes.append(UPSignatureStroke(points: points))
        onChangeHandler?(strokes)
    }

    @discardableResult
    public func undo() -> Bool {
        guard !strokes.isEmpty else { return false }
        strokes.removeLast()
        onChangeHandler?(strokes)
        return true
    }

    public func clear() {
        strokes.removeAll()
        onChangeHandler?(strokes)
    }

    public func exportData() -> Data {
        (try? JSONEncoder().encode(strokes)) ?? Data()
    }

    public var body: some View {
        Canvas { context, _ in
            for stroke in self.strokes {
                guard let first = stroke.points.first else { continue }
                var path = Path()
                path.move(to: first)
                for point in stroke.points.dropFirst() { path.addLine(to: point) }
                context.stroke(path, with: .color(UPColor.parse(self.color)), lineWidth: self.lineWidth)
            }
        }
        .frame(width: width, height: height)
        .background(Color.white)
    }
}
