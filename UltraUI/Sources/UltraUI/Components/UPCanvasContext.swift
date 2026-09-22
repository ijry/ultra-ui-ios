import Foundation
import SwiftUI

/// 上游 `u-canvas` 暴露的那套 CanvasContext 方法在原生侧收敿成一串可重放的绘图命令。
///
/// 上游本质是把 `uni.createCanvasContext` 的调用逐条转发给平台上下文，
/// 命令式攒够后再 `draw()` 落屏。原生保留同一套调用顺序：
/// `UPCanvasContext` 记录命令，`UPCanvas` 用 SwiftUI `Canvas` 一次性重放。
public struct UPCanvasDrawCommand: Equatable, Sendable {
    public enum Shape: Equatable, Sendable {
        /// 上游 `fillRect` / `strokeRect` / `rect` + `fill` / `stroke`。
        case rect(CGRect)
        /// 上游 `clearRect`。
        case clearRect(CGRect)
        /// 上游 `moveTo` / `lineTo` 攒出的折线。
        case path([CGPoint], closed: Bool)
        /// 上游 `arc`。
        case arc(center: CGPoint, radius: CGFloat, start: Double, end: Double, anticlockwise: Bool)
        /// 上游 `ellipse`。
        case ellipse(center: CGPoint, radiusX: CGFloat, radiusY: CGFloat, rotation: Double)
        /// 上游 `fillText` / `strokeText`。
        case text(String, at: CGPoint, maxWidth: CGFloat?)
    }

    public var shape: Shape
    public var filled: Bool
    /// 上游 `setFillStyle` / `setStrokeStyle` 的当前值。
    public var color: String
    /// 上游 `setLineWidth`。
    public var lineWidth: CGFloat
    /// 上游 `setGlobalAlpha`。
    public var alpha: Double
    /// 上游 `applyFont` 拼出来的字号。
    public var fontSize: CGFloat
    /// 上游 `setTextAlign`。
    public var textAlign: String
    /// 上游 `setLineDash`。
    public var lineDash: [CGFloat]

    public init(shape: Shape,
                filled: Bool,
                color: String,
                lineWidth: CGFloat,
                alpha: Double = 1,
                fontSize: CGFloat = UPConfig.canvas.fontSize,
                textAlign: String = UPConfig.canvas.textAlign,
                lineDash: [CGFloat] = []) {
        self.shape = shape
        self.filled = filled
        self.color = color
        self.lineWidth = lineWidth
        self.alpha = alpha
        self.fontSize = fontSize
        self.textAlign = textAlign
        self.lineDash = lineDash
    }
}

/// Native counterpart of the CanvasContext surface exposed by uview-plus `u-canvas`.
///
/// 上游每个方法都是 `callContext(name, ...args)` 的薄封装，拿不到平台上下文时
/// 静默返回 `undefined`。原生把同一套调用记成命令数组，`draw()` 时提交给视图。
@MainActor
@Observable
public final class UPCanvasContext {
    /// 已提交（`draw()` 过）的命令，供视图重放。
    public private(set) var commands: [UPCanvasDrawCommand] = []
    /// 尚未 `draw()` 的命令，对应上游攒在平台上下文里的那批调用。
    private var pending: [UPCanvasDrawCommand] = []
    /// 当前正在攒的路径（`beginPath` 起、`moveTo` / `lineTo` 续）。
    private var currentPath: [CGPoint] = []
    private var pathClosed = false

    // MARK: - 上游 data 里的画笔状态

    public private(set) var fillStyle = "#000000"
    public private(set) var strokeStyle = "#000000"
    public private(set) var lineWidth: CGFloat = 1
    public private(set) var lineCap = UPConfig.canvas.lineCap
    public private(set) var lineJoin = UPConfig.canvas.lineJoin
    public private(set) var lineDash: [CGFloat] = []
    public private(set) var miterLimit: CGFloat = 10
    public private(set) var textAlign = UPConfig.canvas.textAlign
    public private(set) var textBaseline = UPConfig.canvas.textBaseline
    public private(set) var fontSize: CGFloat = UPConfig.canvas.fontSize
    public private(set) var fontFamily = UPConfig.canvas.fontFamily
    public private(set) var fontWeight = UPConfig.canvas.fontWeight
    public private(set) var globalAlpha: Double = 1
    public private(set) var globalCompositeOperation = "source-over"

    /// 上游 `save()` / `restore()` 的状态栈。
    private var stack: [State] = []

    private struct State {
        var fillStyle: String
        var strokeStyle: String
        var lineWidth: CGFloat
        var lineDash: [CGFloat]
        var textAlign: String
        var textBaseline: String
        var fontSize: CGFloat
        var globalAlpha: Double
    }

    public init() {}

    // MARK: - 画笔设置

    public func setFillStyle(_ color: String) { fillStyle = color }
    public func setStrokeStyle(_ color: String) { strokeStyle = color }
    public func setLineWidth(_ width: CGFloat) { lineWidth = max(width, 0) }
    public func setLineCap(_ value: String = UPConfig.canvas.lineCap) { lineCap = value }
    public func setLineJoin(_ value: String = UPConfig.canvas.lineJoin) { lineJoin = value }
    public func setMiterLimit(_ value: CGFloat) { miterLimit = value }
    public func setLineDash(_ segments: [CGFloat] = []) { lineDash = segments }
    public func getLineDash() -> [CGFloat] { lineDash }
    public func setTextAlign(_ align: String = UPConfig.canvas.textAlign) { textAlign = align }
    public func setTextBaseline(_ baseline: String = UPConfig.canvas.textBaseline) { textBaseline = baseline }
    public func setGlobalAlpha(_ alpha: Double) { globalAlpha = Swift.min(Swift.max(alpha, 0), 1) }
    public func setGlobalCompositeOperation(_ operation: String) { globalCompositeOperation = operation }

    /// 上游 `setFontSize`：`Number(fontSize) || this.fontSize`，非法值保留原值。
    public func setFontSize(_ size: CGFloat) {
        guard size.isFinite, size != 0 else { return }
        fontSize = size
    }

    /// 上游 `setFont`：从字符串里正则抽 `\d+px` 当字号。
    public func setFont(_ font: String) {
        guard let size = Self.fontSize(in: font) else { return }
        fontSize = size
    }

    nonisolated static func fontSize(in font: String) -> CGFloat? {
        var digits = ""
        var index = font.startIndex
        while index < font.endIndex {
            let character = font[index]
            if character.isNumber || character == "." {
                digits.append(character)
            } else if !digits.isEmpty {
                if font[index...].hasPrefix("px"), let value = Double(digits) { return CGFloat(value) }
                digits = ""
            }
            index = font.index(after: index)
        }
        return nil
    }

    /// 上游 `applyFont` 拼出来的 CSS font 串。
    public var font: String {
        let weight = fontWeight == UPConfig.canvas.fontWeight ? "" : "\(fontWeight) "
        return "\(weight)\(Self.trimmed(fontSize))px \(fontFamily)"
    }

    nonisolated static func trimmed(_ value: CGFloat) -> String {
        value.rounded() == value ? String(Int(value)) : String(describing: Double(value))
    }

    /// 上游 `setLineStyle(lineColor, lineWidth)`：一次设四项。
    public func setLineStyle(_ color: String, _ width: CGFloat) {
        setLineCap()
        setLineJoin()
        setStrokeStyle(color)
        setLineWidth(width)
    }

    /// 上游 `setShadow`。SwiftUI `Canvas` 的阴影要按图元单独加，
    /// 这里只记录取值以保持调用兼容。
    public private(set) var shadow = (offsetX: CGFloat(0), offsetY: CGFloat(0), blur: CGFloat(0), color: "rgba(0,0,0,0)")

    public func setShadow(offsetX: CGFloat = 0,
                          offsetY: CGFloat = 0,
                          blur: CGFloat = 0,
                          color: String = "rgba(0,0,0,0)") {
        shadow = (offsetX, offsetY, blur, color)
    }

    // MARK: - 状态栈

    public func save() {
        stack.append(State(fillStyle: fillStyle,
                           strokeStyle: strokeStyle,
                           lineWidth: lineWidth,
                           lineDash: lineDash,
                           textAlign: textAlign,
                           textBaseline: textBaseline,
                           fontSize: fontSize,
                           globalAlpha: globalAlpha))
    }

    public func restore() {
        guard let state = stack.popLast() else { return }
        fillStyle = state.fillStyle
        strokeStyle = state.strokeStyle
        lineWidth = state.lineWidth
        lineDash = state.lineDash
        textAlign = state.textAlign
        textBaseline = state.textBaseline
        fontSize = state.fontSize
        globalAlpha = state.globalAlpha
    }

    // MARK: - 路径

    public func beginPath() {
        currentPath = []
        pathClosed = false
    }

    public func closePath() { pathClosed = true }
    public func moveTo(_ x: CGFloat, _ y: CGFloat) { currentPath = [CGPoint(x: x, y: y)] }
    public func lineTo(_ x: CGFloat, _ y: CGFloat) { currentPath.append(CGPoint(x: x, y: y)) }

    /// 上游 `rect(x, y, w, h)`：把矩形塞进当前路径，等 `fill` / `stroke` 落笔。
    public func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        pendingRect = CGRect(x: x, y: y, width: width, height: height)
    }

    private var pendingRect: CGRect?
    private var pendingArc: UPCanvasDrawCommand.Shape?

    public func arc(_ x: CGFloat,
                    _ y: CGFloat,
                    _ radius: CGFloat,
                    _ startAngle: Double,
                    _ endAngle: Double,
                    _ anticlockwise: Bool = false) {
        pendingArc = .arc(center: CGPoint(x: x, y: y),
                          radius: radius,
                          start: startAngle,
                          end: endAngle,
                          anticlockwise: anticlockwise)
    }

    public func ellipse(_ x: CGFloat,
                        _ y: CGFloat,
                        _ radiusX: CGFloat,
                        _ radiusY: CGFloat,
                        _ rotation: Double = 0,
                        _ startAngle: Double = 0,
                        _ endAngle: Double = .pi * 2,
                        _ anticlockwise: Bool = false) {
        pendingArc = .ellipse(center: CGPoint(x: x, y: y),
                              radiusX: radiusX,
                              radiusY: radiusY,
                              rotation: rotation)
    }

    // MARK: - 落笔

    public func fill() { commit(filled: true) }
    public func stroke() { commit(filled: false) }

    private func commit(filled: Bool) {
        if let pendingRect {
            append(.rect(pendingRect), filled: filled)
            self.pendingRect = nil
            return
        }
        if let pendingArc {
            append(pendingArc, filled: filled)
            self.pendingArc = nil
            return
        }
        guard currentPath.count > 1 else { return }
        append(.path(currentPath, closed: pathClosed), filled: filled)
    }

    public func fillRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        append(.rect(CGRect(x: x, y: y, width: width, height: height)), filled: true)
    }

    public func strokeRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        append(.rect(CGRect(x: x, y: y, width: width, height: height)), filled: false)
    }

    /// 上游 `clearRect`：擦掉指定区域。原生记成一条命令，重放时用 blendMode 抹除。
    public func clearRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        append(.clearRect(CGRect(x: x, y: y, width: width, height: height)), filled: true)
    }

    public func fillText(_ text: String, _ x: CGFloat, _ y: CGFloat) {
        append(.text(text, at: CGPoint(x: x, y: y), maxWidth: nil), filled: true)
    }

    public func strokeText(_ text: String, _ x: CGFloat, _ y: CGFloat, _ maxWidth: CGFloat? = nil) {
        append(.text(text, at: CGPoint(x: x, y: y), maxWidth: maxWidth), filled: false)
    }

    private func append(_ shape: UPCanvasDrawCommand.Shape, filled: Bool) {
        pending.append(UPCanvasDrawCommand(shape: shape,
                                           filled: filled,
                                           color: filled ? fillStyle : strokeStyle,
                                           lineWidth: lineWidth,
                                           alpha: globalAlpha,
                                           fontSize: fontSize,
                                           textAlign: textAlign,
                                           lineDash: lineDash))
    }

    /// 上游 `draw(isLastDraw, callback)`：`isLastDraw` 为真时先清屏再画。
    public func draw(_ isLastDraw: Bool = false, _ callback: (() -> Void)? = nil) {
        if isLastDraw { commands = pending } else { commands += pending }
        pending = []
        callback?()
    }

    /// 上游 `clearCanvas()`：清整块画布，`bgColor` 非 transparent 时再铺一层底。
    public func clearCanvas(width: CGFloat, height: CGFloat, bgColor: String) {
        clearRect(0, 0, width, height)
        if !bgColor.isEmpty, bgColor != "transparent" {
            beginPath()
            rect(0, 0, width, height)
            setFillStyle(bgColor)
            fill()
        }
        draw()
    }

    /// 清掉所有已提交与待提交命令（原生扩展，方便宿主重画）。
    public func reset() {
        commands = []
        pending = []
        currentPath = []
        pendingRect = nil
        pendingArc = nil
    }

    // MARK: - 文本测量

    /// 上游 `estimateTextWidth(text, fontSize)`：全角字符占一个字号、
    /// 空白占 0.28、其余半角占 0.56。
    ///
    /// 照抄上游那份全角字符集（`FULL_WIDTH` 正则）。注意其中一段的起点是
    /// `豈`（U+8C48）而不是兼容区起点 U+F900，上游这处笔误让 U+8C48–U+9FFF
    /// 被同一段重复覆盖，实际不影响结果，故原样保留。
    public func estimateTextWidth(_ text: String, fontSize: CGFloat? = nil) -> CGFloat {
        Self.estimateTextWidth(text, fontSize: fontSize ?? self.fontSize)
    }

    nonisolated static let fullWidthRanges: [ClosedRange<UInt32>] = [
        0x1100...0x115F, 0x2E80...0x303E, 0x3041...0x33FF, 0x3400...0x4DBF,
        0x4E00...0x9FFF, 0xA000...0xA4CF, 0xAC00...0xD7A3, 0x8C48...0xFAFF,
        0xFE30...0xFE6F, 0xFF00...0xFF60, 0xFFE0...0xFFE6
    ]

    nonisolated static func isFullWidth(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        return fullWidthRanges.contains { $0.contains(scalar.value) }
    }

    nonisolated static func estimateTextWidth(_ text: String, fontSize: CGFloat) -> CGFloat {
        let size = fontSize > 0 ? fontSize : UPConfig.canvas.fontSize
        return text.reduce(CGFloat(0)) { width, character in
            if isFullWidth(character) { return width + size * UPConfig.canvas.fullWidthRatio }
            if character.isWhitespace { return width + size * UPConfig.canvas.whitespaceRatio }
            return width + size * UPConfig.canvas.halfWidthRatio
        }
    }

    /// 上游 `measureText(text)`：平台测量值大于 0 才用，否则退回估算。
    /// 原生用 `NSAttributedString` 实测，取不到再退回同一套估算。
    public func measureText(_ text: String) -> CGFloat {
        #if canImport(UIKit) || canImport(AppKit)
        let attributed = NSAttributedString(string: text, attributes: [
            .font: platformFont(size: fontSize)
        ])
        let measured = attributed.size().width
        if measured > 0 { return measured }
        #endif
        return estimateTextWidth(text)
    }

    #if canImport(UIKit)
    private func platformFont(size: CGFloat) -> UIFont { UIFont.systemFont(ofSize: size) }
    #elseif canImport(AppKit)
    private func platformFont(size: CGFloat) -> NSFont { NSFont.systemFont(ofSize: size) }
    #endif
}
