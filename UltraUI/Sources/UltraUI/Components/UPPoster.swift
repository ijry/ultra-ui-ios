import SwiftUI

public enum UPPosterLayer: Equatable, Sendable {
    case text(String, frame: CGRect, color: String = "#000000")
    case rectangle(frame: CGRect, color: String = "#ffffff")
    case image(source: String, frame: CGRect)
}

public enum UPPosterRenderCommand: Equatable, Sendable {
    case text(String, CGRect, String)
    case rectangle(CGRect, String)
    case image(String, CGRect)
}

public struct UPPoster: View {
    public let size: CGSize
    public var layers: [UPPosterLayer]

    public init(size: CGSize = CGSize(width: 300, height: 450), layers: [UPPosterLayer] = []) {
        self.size = CGSize(width: max(0, size.width), height: max(0, size.height))
        self.layers = layers
    }

    public var renderSize: CGSize { size }

    public var renderedCommands: [UPPosterRenderCommand] {
        layers.map {
            switch $0 {
            case let .text(value, frame, color): return .text(value, frame, color)
            case let .rectangle(frame, color): return .rectangle(frame, color)
            case let .image(source, frame): return .image(source, frame)
            }
        }
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(layers.enumerated()), id: \.offset) { _, layer in
                switch layer {
                case let .text(value, frame, color):
                    Text(value).foregroundStyle(UPColor.parse(color)).frame(width: frame.width, height: frame.height).position(x: frame.midX, y: frame.midY)
                case let .rectangle(frame, color):
                    Rectangle().fill(UPColor.parse(color)).frame(width: frame.width, height: frame.height).position(x: frame.midX, y: frame.midY)
                case let .image(source, frame):
                    UPImage(src: source, width: frame.width, height: frame.height).position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}
