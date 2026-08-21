import SwiftUI

public struct UPCropResult: Equatable, Sendable {
    public let source: String
    public let rect: CGRect
    public init(source: String, rect: CGRect) { self.source = source; self.rect = rect }
}

@MainActor
public final class UPCropper: View {
    public let src: String
    public let sourceSize: CGSize
    public private(set) var cropRect: CGRect
    private var onConfirmHandler: ((UPCropResult) -> Void)?
    private var onCancelHandler: (() -> Void)?

    public init(src: String = "", sourceSize: CGSize = CGSize(width: 300, height: 300),
                cropRect: CGRect? = nil, onConfirm: ((UPCropResult) -> Void)? = nil,
                onCancel: (() -> Void)? = nil) {
        self.src = src
        self.sourceSize = CGSize(width: max(0, sourceSize.width), height: max(0, sourceSize.height))
        self.cropRect = cropRect ?? CGRect(origin: .zero, size: sourceSize)
        self.onConfirmHandler = onConfirm
        self.onCancelHandler = onCancel
        self.cropRect = Self.clamped(self.cropRect, to: self.sourceSize)
    }

    public func onConfirm(_ action: @escaping (UPCropResult) -> Void) -> UPCropper { onConfirmHandler = action; return self }
    public func onCancel(_ action: @escaping () -> Void) -> UPCropper { onCancelHandler = action; return self }

    public func setCropRect(_ rect: CGRect) { cropRect = Self.clamped(rect, to: sourceSize) }

    @discardableResult
    public func confirm() -> UPCropResult {
        let result = UPCropResult(source: src, rect: cropRect)
        onConfirmHandler?(result)
        return result
    }

    public func cancel() { onCancelHandler?() }

    public var body: some View {
        Rectangle().fill(Color.black.opacity(0.08))
            .overlay(Rectangle().stroke(Color.white, lineWidth: 2).padding(8))
            .aspectRatio(sourceSize.width > 0 && sourceSize.height > 0 ? sourceSize.width / sourceSize.height : 1, contentMode: .fit)
    }

    private static func clamped(_ rect: CGRect, to size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0 else { return .zero }
        let width = min(max(rect.width, 0), size.width)
        let height = min(max(rect.height, 0), size.height)
        let x = min(max(rect.minX, 0), size.width - width)
        let y = min(max(rect.minY, 0), size.height - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
