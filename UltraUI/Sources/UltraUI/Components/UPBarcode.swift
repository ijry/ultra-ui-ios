import CoreImage
import SwiftUI

/// A number value accepted by uview-plus `u-barcode` size props.
public typealias UPBarcodeUnitValue = UPImageUnitValue

/// 上游 `rendered` 事件的负载。
///
/// `useCanvas` 为真时是 `{ type: 'canvas', id }`，为假时是
/// `{ type: 'image', value, path }`。
public struct UPBarcodeRenderedEvent: Equatable, Sendable {
    public var type: String
    public var id: String
    public var value: String
    public var path: String

    public init(type: String, id: String = "", value: String = "", path: String = "") {
        self.type = type
        self.id = id
        self.value = value
        self.path = path
    }
}

/// Native SwiftUI counterpart of uview-plus `u-barcode`.
///
/// 上游先把 `value` 按 `format` 编成一串 `'0'` / `'1'`，再按
/// `moduleWidth = (canvasWidth - marginLeft - marginRight) / data.length` 逐位画黑条，
/// 最后按 `textPosition` / `textAlign` 画一行文字；`useCanvas` 为假时改画到离屏 canvas
/// 再导出临时图片。原生保留同一套尺寸与坐标计算（都可单测），绘制换成 SwiftUI `Canvas`，
/// 导出换成 `ImageRenderer`。
@MainActor
public struct UPBarcode: View {
    /// 上游 `value`：条码值，必填。
    public var value: String
    /// 上游 `format`：见 `UPBarcodeEncoder.supportedFormats`。
    public var format: String
    /// 上游 `width`：条码区宽度，不含边距。
    public var width: CGFloat
    /// 上游 `height`：条码区高度，不含文字与边距。
    public var height: CGFloat
    /// 上游 `displayValue`：是否画文字。
    public var displayValue: Bool
    /// 上游 `text`：默认 `undefined`，画文字时回落 `value`。
    public var text: String?
    /// 上游 `fontOptions`：`'bold'` / `'italic'` 这类修饰。
    public var fontOptions: String
    /// 上游 `font`：默认 `monospace`。
    public var font: String
    /// 上游 `textAlign`：`left` / `center` / `right`。
    public var textAlign: String
    /// 上游 `textPosition`：`top` / `bottom`。
    public var textPosition: String
    /// 上游 `textMargin`。
    public var textMargin: CGFloat
    /// 上游 `fontSize`。
    public var fontSize: CGFloat
    /// 上游 `background`。
    public var background: String
    /// 上游 `lineColor`。
    public var lineColor: String
    /// 上游 `margin`：四个方向的默认边距。
    public var margin: CGFloat
    /// 上游 `marginTop`：`undefined` 时回落 `margin`。
    public var marginTop: CGFloat?
    public var marginBottom: CGFloat?
    public var marginLeft: CGFloat?
    public var marginRight: CGFloat?
    /// 上游 `useCanvas`：真走 canvas 直绘，假走「离屏绘制 + 导出图片」。
    public var useCanvas: Bool

    private var onRenderedHandler: ((UPBarcodeRenderedEvent) -> Void)?
    private var onErrorHandler: ((UPBarcodeError) -> Void)?

    /// 与上游 `props` 对齐的初始化器。参数顺序同上游 `props` 声明顺序。
    public init(value: String = "",
                format: String = UPConfig.barcode.format,
                width: any UPBarcodeUnitValue = UPConfig.barcode.width,
                height: any UPBarcodeUnitValue = UPConfig.barcode.height,
                displayValue: Bool = UPConfig.barcode.displayValue,
                text: String? = nil,
                fontOptions: String = UPConfig.barcode.fontOptions,
                font: String = UPConfig.barcode.font,
                textAlign: String = UPConfig.barcode.textAlign,
                textPosition: String = UPConfig.barcode.textPosition,
                textMargin: any UPBarcodeUnitValue = UPConfig.barcode.textMargin,
                fontSize: any UPBarcodeUnitValue = UPConfig.barcode.fontSize,
                background: String = UPConfig.barcode.background,
                lineColor: String = UPConfig.barcode.lineColor,
                margin: any UPBarcodeUnitValue = UPConfig.barcode.margin,
                marginTop: (any UPBarcodeUnitValue)? = nil,
                marginBottom: (any UPBarcodeUnitValue)? = nil,
                marginLeft: (any UPBarcodeUnitValue)? = nil,
                marginRight: (any UPBarcodeUnitValue)? = nil,
                useCanvas: Bool = UPConfig.barcode.useCanvas) {
        self.value = value
        // 上游 `options.format = this.format || 'auto'`。
        self.format = format.isEmpty ? UPConfig.barcode.format : format
        self.width = max(0, UPUnit.parse(width.upImageUnitValue))
        self.height = max(0, UPUnit.parse(height.upImageUnitValue))
        self.displayValue = displayValue
        self.text = text
        self.fontOptions = fontOptions
        // 上游 `this.font || 'monospace'`。
        self.font = font.isEmpty ? UPConfig.barcode.font : font
        self.textAlign = textAlign.isEmpty ? UPConfig.barcode.textAlign : textAlign
        self.textPosition = textPosition.isEmpty ? UPConfig.barcode.textPosition : textPosition
        self.textMargin = UPUnit.parse(textMargin.upImageUnitValue)
        // 上游 `this.fontSize || 20`：只有 0 这类假值才会变 20。
        let parsedFontSize = UPUnit.parse(fontSize.upImageUnitValue)
        self.fontSize = parsedFontSize > 0 ? parsedFontSize : 20
        self.background = background.isEmpty ? UPConfig.barcode.background : background
        self.lineColor = lineColor.isEmpty ? UPConfig.barcode.lineColor : lineColor
        self.margin = UPUnit.parse(margin.upImageUnitValue)
        self.marginTop = marginTop.map { UPUnit.parse($0.upImageUnitValue) }
        self.marginBottom = marginBottom.map { UPUnit.parse($0.upImageUnitValue) }
        self.marginLeft = marginLeft.map { UPUnit.parse($0.upImageUnitValue) }
        self.marginRight = marginRight.map { UPUnit.parse($0.upImageUnitValue) }
        self.useCanvas = useCanvas
    }

    // MARK: - 解析后的呈现值

    /// 上游 `options.marginTop = this.marginTop !== undefined ? this.marginTop : margin`。
    public var resolvedMarginTop: CGFloat { marginTop ?? margin }
    public var resolvedMarginBottom: CGFloat { marginBottom ?? margin }
    public var resolvedMarginLeft: CGFloat { marginLeft ?? margin }
    public var resolvedMarginRight: CGFloat { marginRight ?? margin }

    /// 上游 `textHeight = fontSize + textMargin`（`displayValue` 为假时是 0）。
    public var textHeight: CGFloat { displayValue ? fontSize + textMargin : 0 }

    /// 上游 `calculateCanvasSize` 的宽：`width + marginLeft + marginRight`，下限 100。
    public var canvasWidth: CGFloat {
        max(width + resolvedMarginLeft + resolvedMarginRight, UPConfig.barcode.minCanvasWidth)
    }

    /// 上游 `calculateCanvasSize` 的高：文字在上/下时才加 `textHeight`，下限 `60 + textHeight`。
    public var canvasHeight: CGFloat {
        var value = height
        if textPosition == "top" || textPosition == "bottom" { value += textHeight }
        value += resolvedMarginTop + resolvedMarginBottom
        return max(value, UPConfig.barcode.minCanvasHeight + textHeight)
    }

    /// 上游 `encodeBarcode(value, format)`。
    public var encodedData: String? {
        try? UPBarcodeEncoder.encode(value, format: format)
    }

    /// 编码失败时上游把 `error.message` 显示在灰底红字容器里。
    public var errorMessage: String? {
        do {
            _ = try UPBarcodeEncoder.encode(value, format: format)
            return nil
        } catch let error as UPBarcodeError {
            return error.message
        } catch {
            return UPConfig.barcode.errorText
        }
    }

    /// 上游 `moduleWidth = max(1, (canvasWidth - marginLeft - (marginRight || 10)) / data.length)`。
    public func moduleWidth(dataLength: Int) -> CGFloat {
        guard dataLength > 0 else { return 1 }
        let right = resolvedMarginRight > 0 ? resolvedMarginRight : UPConfig.barcode.fallbackMarginRight
        return max(1, (canvasWidth - resolvedMarginLeft - right) / CGFloat(dataLength))
    }

    /// 上游 `barcodeY`：文字在顶部时条码整体下移一个 `textHeight`。
    public var barcodeY: CGFloat {
        displayValue && textPosition == "top" ? resolvedMarginTop + textHeight : resolvedMarginTop
    }

    /// 上游画文字时的 `textX`：按 `textAlign` 三分。
    public var textX: CGFloat {
        switch textAlign {
        case "left": return resolvedMarginLeft
        case "right": return canvasWidth - resolvedMarginRight
        default: return canvasWidth / 2
        }
    }

    /// 上游画文字时的 `textY`（基线）。底部分支会被夹进画布内。
    public var textY: CGFloat {
        if textPosition == "top" { return resolvedMarginTop + fontSize - 3 }
        let raw = barcodeY + height + textMargin + fontSize
        let limit = canvasHeight - resolvedMarginBottom
        return raw > limit ? limit - 2 : raw
    }

    /// 上游 `options.text || this.value`。
    public var resolvedText: String {
        guard let text, !text.isEmpty else { return value }
        return text
    }

    /// 仓库既有属性：Core Image 生成的 Code 128 位图，保留作源兼容。
    public var generatedImage: CIImage? {
        upGeneratedImage(filterName: "CICode128BarcodeGenerator",
                         value: value,
                         width: width,
                         height: height)
    }

    // MARK: - 事件

    /// 对应上游 `rendered` 事件。
    public func onRendered(_ action: @escaping (UPBarcodeRenderedEvent) -> Void) -> Self {
        var copy = self
        copy.onRenderedHandler = action
        return copy
    }

    /// 对应上游 `error` 事件。
    public func onError(_ action: @escaping (UPBarcodeError) -> Void) -> Self {
        var copy = self
        copy.onErrorHandler = action
        return copy
    }

    // MARK: - 导出

    /// 对应上游 `renderToImage`：离屏画一遍再导出临时 PNG，成功时抛 `rendered`。
    @discardableResult
    public func exportImage(scale: CGFloat = 2) -> UPBarcodeRenderedEvent? {
        let renderer = ImageRenderer(content: canvasView)
        renderer.scale = scale
        guard let data = Self.pngData(from: renderer) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("up-barcode-\(UUID().uuidString).png")
        guard (try? data.write(to: url)) != nil else { return nil }
        let event = UPBarcodeRenderedEvent(type: "image", value: value, path: url.path)
        onRenderedHandler?(event)
        return event
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

    // MARK: - 视图

    public var body: some View {
        Group {
            if let errorMessage {
                errorView(errorMessage)
            } else {
                canvasView
            }
        }
        // 上游 `.u-barcode { display: flex; justify-content: center; align-items: center }`。
        .frame(width: canvasWidth, height: canvasHeight)
        .task(id: renderTaskID) { report() }
    }

    private var renderTaskID: String { "\(value)|\(format)|\(useCanvas)" }

    /// 上游 canvas 分支画完抛 `{ type: 'canvas', id }`，编码失败抛 `error`。
    private func report() {
        if let error = encodeError() {
            onErrorHandler?(error)
            return
        }
        guard useCanvas else { return }
        onRenderedHandler?(UPBarcodeRenderedEvent(type: "canvas", id: canvasID))
    }

    private func encodeError() -> UPBarcodeError? {
        do {
            _ = try UPBarcodeEncoder.encode(value, format: format)
            return nil
        } catch let error as UPBarcodeError {
            return error
        } catch {
            return .invalidLength(UPConfig.barcode.errorText)
        }
    }

    /// 上游 `canvasId` 是随机串，原生用稳定值（同一 value/format 得同一 id）。
    public var canvasID: String { "barcode-\(abs(renderTaskID.hashValue))" }

    private var canvasView: some View {
        Canvas { context, _ in
            context.fill(Path(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)),
                         with: .color(UPColor.parse(background)))
            guard let data = encodedData else { return }
            drawBars(data, in: &context)
            if displayValue { drawText(in: &context) }
        }
    }

    /// 上游 `drawBarcode` 的画条部分：每一位都占一个模块宽度，`'1'` 才填色。
    private func drawBars(_ data: String, in context: inout GraphicsContext) {
        let module = moduleWidth(dataLength: data.count)
        var x = resolvedMarginLeft
        let color = GraphicsContext.Shading.color(UPColor.parse(lineColor))
        for character in data {
            if character == "1" {
                context.fill(Path(CGRect(x: x, y: barcodeY, width: module, height: height)),
                             with: color)
            }
            x += module
        }
    }

    /// 上游 `drawBarcode` 的画字部分：`fillText(text, textX, textY)`，`textY` 是基线。
    private func drawText(in context: inout GraphicsContext) {
        let resolved = context.resolve(
            Text(resolvedText)
                .font(.system(size: fontSize, design: font == "monospace" ? .monospaced : .default))
                .bold(fontOptions.localizedCaseInsensitiveContains("bold"))
                .italic(fontOptions.localizedCaseInsensitiveContains("italic"))
                .foregroundColor(UPColor.parse(lineColor))
        )
        context.draw(resolved, at: CGPoint(x: textX, y: textY), anchor: textAnchor)
    }

    /// canvas 的 `fillText` 以基线为准，SwiftUI 只能锚到文本框，取底边最接近。
    private var textAnchor: UnitPoint {
        switch textAlign {
        case "left": return UnitPoint(x: 0, y: 1)
        case "right": return UnitPoint(x: 1, y: 1)
        default: return UnitPoint(x: 0.5, y: 1)
        }
    }

    /// 上游 `.error-container`：灰底 `#f0f0f0`、红字 14pt。
    private func errorView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 14))
            .foregroundStyle(UPColor.parse("#ff0000"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(UPColor.parse("#f0f0f0"))
    }
}
