import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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

/// 触摸事件负载，对应上游 `touchstart` / `touchmove` / `touchend`
/// 里 `{ detail: { x, y }, canvasWidth, canvasHeight }` 这部分。
public struct UPCanvasTouch: Equatable, Sendable {
    public let point: CGPoint
    public let canvasWidth: CGFloat
    public let canvasHeight: CGFloat

    public init(point: CGPoint, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        self.point = point
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
    }
}

/// Native SwiftUI counterpart of uview-plus `u-canvas`.
///
/// 上游是对 `<canvas>` 的跨端封装：`canvasId` 供 `createSelectorQuery` 取节点、
/// `unit` 决定宽高的 CSS 单位、`useRootHeightAndWidth` 让画布铺满父级、
/// `bgColor` 铺底、`disableScroll` 阻止画布内滚动，`ready` 在拿到上下文后抛出。
///
/// 原生用 SwiftUI 的 `Canvas` + 命令数组渲染：`canvasId` / `unit` 只保留取值
/// （SwiftUI 不需要节点查询，尺寸也统一按 pt），其余 prop 与四个事件都落到实处。
@MainActor
public struct UPCanvas: View {
    public var canvasId: String
    public var width: CGFloat
    public var height: CGFloat
    /// 上游 `unit` 会拼到宽高样式上；原生已折算成 pt，保留取值。
    public var unit: String
    public var useRootHeightAndWidth: Bool
    public var bgColor: String
    /// 上游给 `<canvas disable-scroll>`；原生用 `.simultaneousGesture` 吞掉拖动。
    public var disableScroll: Bool
    public var commands: [UPCanvasCommand]
    /// 上游 `getRawContext()` 拿到的那个 CanvasContext。给了它就按命令式重放，
    /// 否则走仓库既有的 `commands` 声明式数组。
    public var context: UPCanvasContext?

    private var onReadyHandler: ((CGSize) -> Void)?
    private var onTouchStartHandler: ((UPCanvasTouch) -> Void)?
    private var onTouchMoveHandler: ((UPCanvasTouch) -> Void)?
    private var onTouchEndHandler: ((UPCanvasTouch) -> Void)?

    public init(canvasId: String = UPCanvas.generatedId(),
                width: some UPImageUnitValue = UPConfig.canvas.width,
                height: some UPImageUnitValue = UPConfig.canvas.height,
                unit: String = UPConfig.canvas.unit,
                useRootHeightAndWidth: Bool = UPConfig.canvas.useRootHeightAndWidth,
                bgColor: String = UPConfig.canvas.bgColor,
                disableScroll: Bool = UPConfig.canvas.disableScroll,
                commands: [UPCanvasCommand] = [],
                context: UPCanvasContext? = nil) {
        self.canvasId = canvasId
        self.width = max(0, UPUnit.parse(width.upImageUnitValue))
        self.height = max(0, UPUnit.parse(height.upImageUnitValue))
        self.unit = unit
        self.useRootHeightAndWidth = useRootHeightAndWidth
        self.bgColor = bgColor
        self.disableScroll = disableScroll
        self.commands = commands
        self.context = context
    }

    /// 上游 `canvasId` 默认是 `u-canvas` + 随机数。
    public static func generatedId() -> String {
        "u-canvas\(Int.random(in: 0..<1_000_000))"
    }

    /// 上游 `actualWidth` / `actualHeight`：`useRootHeightAndWidth` 为真时铺满父级。
    public var resolvedSize: CGSize? {
        useRootHeightAndWidth ? nil : CGSize(width: width, height: height)
    }

    /// 上游 `getWidth()` / `getHeight()`。
    public func getWidth() -> CGFloat { width }
    public func getHeight() -> CGFloat { height }

    /// 上游 `parseSize(value)`：`rpx` / `upx` 走 `upx2px`，`px` 取数值，
    /// 其余一律 `parseFloat`（非字符串非数字得 0）。
    nonisolated static func parseSize(_ value: String) -> CGFloat {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("rpx") || trimmed.hasSuffix("upx") {
            return UPUnit.rpx(CGFloat(Double(trimmed.dropLast(3)) ?? 0))
        }
        if trimmed.hasSuffix("px") { return CGFloat(Double(trimmed.dropLast(2)) ?? 0) }
        let digits = trimmed.prefix { $0.isNumber || $0 == "." || $0 == "-" || $0 == "+" }
        return CGFloat(Double(digits) ?? 0)
    }

    /// 上游 `clearCanvas()`：擦掉整块画布，`bgColor` 非 transparent 时再铺一层底色。
    public func clearCanvas() {
        context?.clearCanvas(width: width, height: height, bgColor: bgColor)
    }

    /// 上游 `toTempFilePath(options)`：把画布导出成临时文件。
    ///
    /// 上游默认导出尺寸会乘 `dpr`，原生用 `ImageRenderer.scale` 表达同一件事。
    @discardableResult
    public func toTempFilePath(scale: CGFloat = 2) -> String? {
        let renderer = ImageRenderer(content: canvas.frame(width: width, height: height)
            .background(UPColor.parse(bgColor)))
        renderer.scale = scale
        guard let data = Self.pngData(from: renderer) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("up-canvas-\(UUID().uuidString).png")
        guard (try? data.write(to: url)) != nil else { return nil }
        return url.path
    }

    /// `ImageRenderer` 在 iOS 出 `UIImage`、在 macOS 出 `NSImage`，统一转成 PNG。
    private static func pngData(from renderer: ImageRenderer<some View>) -> Data? {
        #if canImport(UIKit)
        return renderer.uiImage?.pngData()
        #elseif canImport(AppKit)
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let representation = NSBitmapImageRep(data: tiff) else { return nil }
        return representation.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }

    public func appending(_ command: UPCanvasCommand) -> UPCanvas {
        var copy = self
        copy.commands.append(command)
        return copy
    }

    public var cleared: UPCanvas {
        var copy = self
        copy.commands = []
        return copy
    }

    /// 对应上游 `ready` 事件，负载是画布实际尺寸。
    public func onReady(_ action: @escaping (CGSize) -> Void) -> UPCanvas {
        var copy = self
        copy.onReadyHandler = action
        return copy
    }

    public func onTouchStart(_ action: @escaping (UPCanvasTouch) -> Void) -> UPCanvas {
        var copy = self
        copy.onTouchStartHandler = action
        return copy
    }

    public func onTouchMove(_ action: @escaping (UPCanvasTouch) -> Void) -> UPCanvas {
        var copy = self
        copy.onTouchMoveHandler = action
        return copy
    }

    public func onTouchEnd(_ action: @escaping (UPCanvasTouch) -> Void) -> UPCanvas {
        var copy = self
        copy.onTouchEndHandler = action
        return copy
    }

    public var body: some View {
        GeometryReader { proxy in
            canvas
                .frame(width: resolvedSize?.width, height: resolvedSize?.height)
                .background(UPColor.parse(bgColor))
                .contentShape(Rectangle())
                .modifier(UPCanvasTouchModifier(gesture: touchGesture(in: proxy.size),
                                                exclusive: disableScroll))
                .onAppear { onReadyHandler?(size(in: proxy.size)) }
        }
        .frame(width: resolvedSize?.width, height: resolvedSize?.height)
    }

    private func size(in proposed: CGSize) -> CGSize {
        resolvedSize ?? proposed
    }

    private func touchGesture(in proposed: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let touch = UPCanvasTouch(point: value.location,
                                         canvasWidth: size(in: proposed).width,
                                         canvasHeight: size(in: proposed).height)
                if value.translation == .zero {
                    onTouchStartHandler?(touch)
                } else {
                    onTouchMoveHandler?(touch)
                }
            }
            .onEnded { value in
                onTouchEndHandler?(UPCanvasTouch(point: value.location,
                                                canvasWidth: size(in: proposed).width,
                                                canvasHeight: size(in: proposed).height))
            }
    }

    private var canvas: some View {
        Canvas { context, _ in
            // 命令式上下文（上游 getRawContext 那条路径）先重放。
            if let contextCommands = self.context?.commands {
                for command in contextCommands { draw(command, in: &context) }
            }

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
    }

    /// 重放一条 `UPCanvasContext` 命令，映射规则与上游 CanvasContext 一致。
    private func draw(_ command: UPCanvasDrawCommand, in context: inout GraphicsContext) {
        let shading = GraphicsContext.Shading.color(UPColor.parse(command.color).opacity(command.alpha))
        let style = StrokeStyle(lineWidth: command.lineWidth,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: command.lineDash)

        switch command.shape {
        case let .rect(rect):
            let path = Path(rect)
            if command.filled { context.fill(path, with: shading) }
            else { context.stroke(path, with: shading, style: style) }
        case let .clearRect(rect):
            // 上游 clearRect 擦掉像素，SwiftUI 用 destinationOut 混合表达。
            context.blendMode = .destinationOut
            context.fill(Path(rect), with: .color(.black))
            context.blendMode = .normal
        case let .path(points, closed):
            guard let first = points.first else { return }
            var path = Path()
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
            if closed { path.closeSubpath() }
            if command.filled { context.fill(path, with: shading) }
            else { context.stroke(path, with: shading, style: style) }
        case let .arc(center, radius, start, end, anticlockwise):
            var path = Path()
            path.addArc(center: center,
                        radius: radius,
                        startAngle: .radians(start),
                        endAngle: .radians(end),
                        clockwise: anticlockwise)
            if command.filled { context.fill(path, with: shading) }
            else { context.stroke(path, with: shading, style: style) }
        case let .ellipse(center, radiusX, radiusY, rotation):
            let rect = CGRect(x: center.x - radiusX, y: center.y - radiusY,
                              width: radiusX * 2, height: radiusY * 2)
            var path = Path(ellipseIn: rect)
            if rotation != 0 {
                path = path.applying(CGAffineTransform(translationX: center.x, y: center.y)
                    .rotated(by: rotation)
                    .translatedBy(x: -center.x, y: -center.y))
            }
            if command.filled { context.fill(path, with: shading) }
            else { context.stroke(path, with: shading, style: style) }
        case let .text(text, point, _):
            let resolved = context.resolve(Text(text)
                .font(.system(size: command.fontSize))
                .foregroundColor(UPColor.parse(command.color).opacity(command.alpha)))
            context.draw(resolved, at: point, anchor: Self.textAnchor(command.textAlign))
        }
    }

    /// 上游 `setTextAlign` 的三档对齐；canvas 的 `fillText` 以基线定位，
    /// SwiftUI 只能锚文本框，取底边最接近。
    nonisolated static func textAnchor(_ align: String) -> UnitPoint {
        switch align {
        case "center": return UnitPoint(x: 0.5, y: 1)
        case "right", "end": return UnitPoint(x: 1, y: 1)
        default: return UnitPoint(x: 0, y: 1)
        }
    }
}

/// 上游 `disable-scroll` 为真时画布内的拖动不会带动页面滚动，
/// 原生用 `gesture`（独占）与 `simultaneousGesture`（与滚动共存）区分。
private struct UPCanvasTouchModifier<G: Gesture>: ViewModifier {
    let gesture: G
    let exclusive: Bool

    func body(content: Content) -> some View {
        if exclusive {
            content.gesture(gesture)
        } else {
            content.simultaneousGesture(gesture)
        }
    }
}
