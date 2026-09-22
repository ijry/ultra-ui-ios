import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class AlbumAndColorPickerTests: XCTestCase {
    func testAlbumSelectionEmitsIndexAndSource() {
        var selected: (Int, String)?
        let album = UPAlbum(images: ["one", "two"], singleSize: 80)
            .onClick { index, source in selected = (index, source) }

        XCTAssertEqual(album.images, ["one", "two"])
        album.select(1)
        XCTAssertEqual(album.current, 1)
        XCTAssertEqual(selected?.0, 1)
        XCTAssertEqual(selected?.1, "two")
    }

    /// `album.js`：`keyName: ''`、`singleSize: 180`、`multipleSize: 70`、
    /// `space: 6`、`singleMode: 'scaleToFill'`、`multipleMode: 'aspectFill'`、
    /// `maxCount: 9`、`previewFullImage: true`、`rowCount: 3`、`showMore: true`、
    /// `autoWrap: false`、`unit: 'px'`、`stop: true`；`shape` / `radius` 取
    /// `defProps.image`。
    func testAlbumPropDefaultsMatchUpstream() {
        let album = UPAlbum(urls: [String]())
        XCTAssertEqual(album.keyName, "")
        XCTAssertEqual(album.singleSize, 180)
        XCTAssertEqual(album.multipleSize, 70)
        XCTAssertEqual(album.space, 6)
        XCTAssertEqual(album.singleMode, "scaleToFill")
        XCTAssertEqual(album.multipleMode, "aspectFill")
        XCTAssertEqual(album.maxCount, 9)
        XCTAssertTrue(album.previewFullImage)
        XCTAssertEqual(album.rowCount, 3)
        XCTAssertTrue(album.showMore)
        XCTAssertEqual(album.shape, UPConfig.image.shape)
        XCTAssertEqual(album.radius, 0)
        XCTAssertFalse(album.autoWrap)
        XCTAssertEqual(album.unit, "px")
        XCTAssertTrue(album.stop)
        XCTAssertTrue(album.items.isEmpty)
    }

    /// 上游 `urls` 支持 `Array<Object>`，`keyName` 指定字段，缺省回落 `src`。
    func testAlbumReadsSourceFromObjectEntries() {
        let album = UPAlbum(urls: [["url": "a.png", "src": "b.png"], ["src": "c.png"]],
                            keyName: "url")
        XCTAssertEqual(album.sources, ["a.png", "c.png"])
        XCTAssertEqual(UPAlbum(urls: [["url": "a.png", "src": "b.png"]]).sources, ["b.png"])
        XCTAssertEqual(UPAlbumItem.object(["src": "x"]).source(keyName: "missing"), "x")
    }

    /// 上游 `showUrls`：按 `rowCount` 分行并截到 `maxCount`，`autoWrap` 时只有一行。
    func testAlbumRowsFollowRowCountAndMaxCount() {
        let sources = (1...8).map { "\($0).png" }
        let album = UPAlbum(urls: sources, maxCount: 5, rowCount: 2)
        XCTAssertEqual(album.rows, [["1.png", "2.png"], ["3.png", "4.png"], ["5.png"]])
        XCTAssertEqual(Array(album.displayedImages).count, 5)

        let wrapped = UPAlbum(urls: sources, maxCount: 5, rowCount: 2, autoWrap: true)
        XCTAssertEqual(wrapped.rows.count, 1)
        XCTAssertEqual(wrapped.rows[0].count, 5)
        XCTAssertTrue(UPAlbum(urls: [String](), autoWrap: true).rows.isEmpty)
    }

    /// 上游超出 `maxCount` 时在最后一格盖 `+N`，`showMore` 为假则不显示。
    func testAlbumOverflowBadgeCountsHiddenImages() {
        let album = UPAlbum(urls: (1...12).map { "\($0).png" }, maxCount: 9)
        XCTAssertEqual(album.overflowCount, 3)
        XCTAssertTrue(album.showsOverflowBadge)
        XCTAssertFalse(UPAlbum(urls: (1...12).map { "\($0).png" }, maxCount: 9, showMore: false)
            .showsOverflowBadge)
        XCTAssertFalse(UPAlbum(urls: ["1.png"]).showsOverflowBadge)
    }

    /// 上游 `albumWidth` 事件：多图取首行宽度加间隔，单图取图片实际宽度。
    func testAlbumWidthMatchesFirstRow() {
        var widths: [CGFloat] = []
        let album = UPAlbum(urls: (1...6).map { "\($0).png" }, multipleSize: 70, space: 6, rowCount: 3)
            .onAlbumWidth { widths.append($0) }
        XCTAssertEqual(album.albumWidth, 70 * 3 + 6 * 2)
        XCTAssertTrue(widths.isEmpty)
        XCTAssertEqual(UPAlbum(urls: ["1.png"], singleSize: 180).albumWidth, 180)
        XCTAssertEqual(UPAlbum(urls: [String]()).albumWidth, 0)
    }

    /// 上游 `onPreviewTap`：`previewFullImage` 为真时走系统预览、不抛 `preview`。
    func testAlbumPreviewEventOnlyFiresWhenFullPreviewDisabled() {
        var previews: [UPAlbumPreview] = []
        let system = UPAlbum(urls: ["a.png", "b.png"]).onPreview { previews.append($0) }
        system.select(1)
        XCTAssertTrue(previews.isEmpty)

        let custom = UPAlbum(urls: ["a.png", "b.png"], previewFullImage: false)
            .onPreview { previews.append($0) }
        custom.select(1)
        XCTAssertEqual(previews.map(\.currentIndex), [1])
        XCTAssertEqual(previews.first?.urls, ["a.png", "b.png"])
    }

    /// 单图模式：上游拿不到原图尺寸时退化成 `widthFix`；`shape: circle` 圆角写死。
    func testAlbumImageModeAndShapeFollowUpstream() {
        XCTAssertEqual(UPAlbum(urls: ["a.png"]).imageMode, "widthFix")
        XCTAssertEqual(UPAlbum(urls: ["a.png", "b.png"]).imageMode, "aspectFill")
        XCTAssertEqual(UPAlbum(urls: ["a.png", "b.png"], multipleMode: "widthFix").imageMode, "widthFix")
        XCTAssertEqual(UPAlbum(urls: ["a.png"], singleSize: 180).singleImageSize,
                       CGSize(width: 180, height: 180))
        XCTAssertEqual(UPAlbum(urls: ["a.png"], radius: 8).cornerRadius, 8)
        XCTAssertEqual(UPAlbum(urls: ["a.png", "b.png"], multipleSize: 70, shape: "circle").cornerRadius, 180)
    }

    /// `singleSize` / `multipleSize` / `space` / `maxCount` / `rowCount` / `radius`
    /// 上游都是 `String | Number`，走 `UPUnit` 解析。
    func testAlbumAcceptsStringUnitProps() {
        let album = UPAlbum(urls: ["a.png"],
                            singleSize: "200",
                            multipleSize: "80",
                            space: "10",
                            maxCount: "4",
                            rowCount: "2",
                            radius: "6")
        XCTAssertEqual(album.singleSize, 200)
        XCTAssertEqual(album.multipleSize, 80)
        XCTAssertEqual(album.space, 10)
        XCTAssertEqual(album.maxCount, 4)
        XCTAssertEqual(album.rowCount, 2)
        XCTAssertEqual(album.radius, 6)
        // 上游 rowCount 参与除法，0 会算出 Infinity，原生兜到 1。
        XCTAssertEqual(UPAlbum(urls: ["a.png"], rowCount: 0).rowCount, 1)
    }

    func testColorPickerBindingAndChangeEventUseHexValue() {
        var value = "#ff0000"
        var changed = ""
        let picker = UPColorPicker(color: Binding(get: { value }, set: { value = $0 }))
            .onChange { changed = $0 }

        picker.select("#00ff00")
        XCTAssertEqual(value, "#00ff00")
        XCTAssertEqual(changed, "#00ff00")
    }

    /// `u-color-picker.vue` 的内联 props：`modelValue: '#ff0000'`、`commonColors: []`。
    func testColorPickerPropDefaultsMatchUpstream() {
        let picker = UPColorPicker(color: .constant(""))
        XCTAssertEqual(UPConfig.colorPicker.modelValue, "#ff0000")
        XCTAssertTrue(picker.commonColors.isEmpty)
        XCTAssertFalse(picker.show)
        XCTAssertEqual(picker.colorTypeIndex, 0)
        XCTAssertFalse(picker.hasTriggerSlot)
        // 上游 `gradientColors` 初值是红→蓝。
        XCTAssertEqual(picker.stops.map(\.color), ["#ff0000", "#0000ff"])
        XCTAssertEqual(picker.direction, .toRight)
        XCTAssertEqual(picker.editingStopIndex, -1)
    }

    /// 上游 `initColor()`：空值回落 `#ff0000`，渐变串会切到渐变模式并还原节点。
    func testColorPickerInitColorRestoresState() {
        let solid = UPColorPicker(color: .constant("#00ff00"))
        solid.initColor()
        XCTAssertEqual(solid.colorTypeIndex, 0)
        XCTAssertEqual(solid.hue, 120, accuracy: 0.5)
        XCTAssertEqual(solid.saturation, 100, accuracy: 0.5)
        XCTAssertEqual(solid.lightness, 50, accuracy: 0.5)

        let gradient = UPColorPicker(color: .constant("linear-gradient(to bottom, #ff0000 0%, #0000ff 100%)"))
        gradient.initColor()
        XCTAssertEqual(gradient.colorTypeIndex, 1)
        XCTAssertEqual(gradient.direction, .toBottom)
        XCTAssertEqual(gradient.stops.map(\.color), ["#ff0000", "#0000ff"])
        XCTAssertEqual(gradient.stops.map(\.percent), [0, 1])

        let empty = UPColorPicker(color: .constant(""))
        empty.initColor()
        XCTAssertEqual(empty.currentColor, "#ff0000")
    }

    /// 上游 `updateSolidColor()` 把游标折算成 `rgba()`；渐变模式写进编辑中的节点。
    func testColorPickerUpdatesSolidAndEditingStop() {
        let picker = UPColorPicker(color: .constant("#ff0000"))
        picker.initColor()
        picker.setHue(240)
        XCTAssertEqual(picker.currentColor, "rgba(0, 0, 255, 1.00)")
        picker.setAlpha(0.5)
        XCTAssertEqual(picker.currentColor, "rgba(0, 0, 255, 0.50)")
        picker.setSaturationPoint(CGPoint(x: 0, y: 0), in: CGSize(width: 100, height: 100))
        XCTAssertEqual(picker.saturation, 0)
        XCTAssertEqual(picker.lightness, 100)
        XCTAssertEqual(picker.currentColor, "rgba(255, 255, 255, 0.50)")

        picker.changeColorType(1)
        picker.editStop(1)
        XCTAssertEqual(picker.editingStopIndex, 1)
        picker.setHue(0)
        XCTAssertEqual(picker.stops[1].color, "rgba(255, 0, 0, 1.00)")
    }

    /// 上游 `addGradientColor` / `removeGradientColor` 的 5 / 2 限制与拖动排序。
    func testColorPickerGradientStopLimitsAndOrdering() {
        let picker = UPColorPicker(color: .constant("#ff0000"))
        picker.changeColorType(1)
        for _ in 0..<5 { picker.addStop() }
        XCTAssertEqual(picker.stops.count, UPColorPicker.maxStops)
        picker.removeStop(0)
        XCTAssertEqual(picker.stops.count, 4)
        while picker.stops.count > UPColorPicker.minStops { picker.removeStop(0) }
        picker.removeStop(0)
        XCTAssertEqual(picker.stops.count, UPColorPicker.minStops)

        picker.moveStop(0, percent: 0.9)
        XCTAssertEqual(picker.stops.map(\.percent).sorted(), picker.stops.map(\.percent))
        XCTAssertEqual(picker.pointerPosition(at: 1), UPColorPicker.trackWidth)
    }

    /// 上游 `confirm()`：渐变模式写回 `linear-gradient(...)`，并依次抛 confirm/close。
    func testColorPickerConfirmWritesGradientAndEmitsEvents() {
        var value = "#ff0000"
        var confirmed: [String] = []
        var closed = 0
        let picker = UPColorPicker(color: Binding(get: { value }, set: { value = $0 }))
            .onConfirm { confirmed.append($0) }
            .onClose { closed += 1 }
        picker.open()
        XCTAssertTrue(picker.show)
        picker.changeColorType(1)
        picker.setDirection(.toBottomRight)
        picker.confirm()
        XCTAssertFalse(picker.show)
        XCTAssertEqual(value, "linear-gradient(to bottom right, #ff0000 0%, #0000ff 100%)")
        XCTAssertEqual(confirmed, [value])
        XCTAssertEqual(closed, 1)
    }

    /// 上游 `selectCommonColor`：纯色模式改当前色，渐变模式改编辑中的节点。
    func testColorPickerCommonColorTargetsEditingStop() {
        let picker = UPColorPicker(color: .constant("#ff0000"), commonColors: ["#123456"])
        picker.selectCommonColor("#123456")
        XCTAssertEqual(picker.currentColor, "#123456")

        picker.changeColorType(1)
        picker.editStop(0)
        picker.selectCommonColor("#abcdef")
        XCTAssertEqual(picker.stops[0].color, "#abcdef")
    }

    /// HSL ↔ RGB 与渐变串的换算工具。
    func testColorMathHelpers() {
        XCTAssertEqual(UPColorMath.rgbaText(hue: 0, saturation: 100, lightness: 50, alpha: 1),
                       "rgba(255, 0, 0, 1.00)")
        XCTAssertEqual(UPColorMath.rgbaText(hue: 0, saturation: 0, lightness: 0, alpha: 0),
                       "rgba(0, 0, 0, 0.00)")
        XCTAssertEqual(UPColorMath.components(of: "#0f0")?.green, 1)
        XCTAssertEqual(UPColorMath.components(of: "rgba(0, 0, 0, 0.5)")?.alpha, 0.5)
        XCTAssertNil(UPColorMath.components(of: "var(--main)"))
        XCTAssertEqual(UPColorMath.hsl(of: "#000000")?.lightness, 0)
        XCTAssertTrue(UPColorMath.isGradient("linear-gradient(to right, #fff 0%, #000 100%)"))
        let parsed = UPColorMath.gradient(of: "linear-gradient(to top, rgba(0, 0, 0, 1.00) 0%, #fff 50%)")
        XCTAssertEqual(parsed?.direction, .toTop)
        XCTAssertEqual(parsed?.stops.map(\.percent), [0, 0.5])
        XCTAssertEqual(parsed?.stops.first?.color, "rgba(0, 0, 0, 1.00)")
        XCTAssertNil(UPColorMath.gradient(of: "#fff"))
        XCTAssertEqual(UPColorPickerDirection.toBottomLeft.angle, 135)
        XCTAssertEqual(UPColorPickerDirection.toRight.label, "从左到右")
    }
}

@MainActor
final class DrawingComponentTests: XCTestCase {
    func testCanvasCommandsPreserveOrderAndClear() {
        let canvas = UPCanvas(width: 120, height: 80)
            .appending(.line(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 10, y: 10)))
            .appending(.rectangle(CGRect(x: 2, y: 3, width: 20, height: 30)))

        XCTAssertEqual(canvas.commands.count, 2)
        XCTAssertEqual(canvas.commands[0].kind, .line)
        XCTAssertEqual(canvas.cleared.commands, [])
    }

    /// `u-canvas.vue` 的内联 props：`width: 300`、`height: 300`、`unit: 'px'`、
    /// `useRootHeightAndWidth: false`、`bgColor: '#ffffff'`、`disableScroll: false`。
    func testCanvasPropDefaultsMatchUpstream() {
        let canvas = UPCanvas()
        XCTAssertEqual(canvas.width, 300)
        XCTAssertEqual(canvas.height, 300)
        XCTAssertEqual(canvas.unit, "px")
        XCTAssertFalse(canvas.useRootHeightAndWidth)
        XCTAssertEqual(canvas.bgColor, "#ffffff")
        XCTAssertFalse(canvas.disableScroll)
        XCTAssertTrue(canvas.commands.isEmpty)
        XCTAssertTrue(canvas.canvasId.hasPrefix("u-canvas"))
        XCTAssertEqual(canvas.resolvedSize, CGSize(width: 300, height: 300))
        // 上游 `useRootHeightAndWidth` 为真时宽高走 100%，原生交给父级。
        XCTAssertNil(UPCanvas(useRootHeightAndWidth: true).resolvedSize)
    }

    /// 上游 `parseSize(value)`：`rpx`/`upx` 走 `upx2px`，`px` 取数值，其余 `parseFloat`。
    func testCanvasParseSizeMatchesUpstream() {
        XCTAssertEqual(UPCanvas.parseSize("300"), 300)
        XCTAssertEqual(UPCanvas.parseSize("300px"), 300)
        XCTAssertEqual(UPCanvas.parseSize("750rpx"), UPUnit.rpx(CGFloat(750)))
        XCTAssertEqual(UPCanvas.parseSize("750upx"), UPUnit.rpx(CGFloat(750)))
        // 非数值前缀取不到数字，退回 0。
        XCTAssertEqual(UPCanvas.parseSize("auto"), 0)

        let canvas = UPCanvas(width: 120, height: 80)
        XCTAssertEqual(canvas.getWidth(), 120)
        XCTAssertEqual(canvas.getHeight(), 80)
    }

    /// 上游 `data` 里画笔状态的初始值，以及 `setLineStyle` 一次设四项。
    func testCanvasContextDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.canvas.fontSize, 12)
        XCTAssertEqual(UPConfig.canvas.fontFamily, "sans-serif")
        XCTAssertEqual(UPConfig.canvas.fontWeight, "normal")
        XCTAssertEqual(UPConfig.canvas.lineCap, "round")
        XCTAssertEqual(UPConfig.canvas.textAlign, "left")
        XCTAssertEqual(UPConfig.canvas.textBaseline, "alphabetic")

        let context = UPCanvasContext()
        XCTAssertEqual(context.fillStyle, "#000000")
        XCTAssertEqual(context.strokeStyle, "#000000")
        XCTAssertEqual(context.lineWidth, 1)
        XCTAssertEqual(context.lineCap, "round")
        XCTAssertEqual(context.lineJoin, "round")
        XCTAssertEqual(context.textAlign, "left")
        XCTAssertEqual(context.textBaseline, "alphabetic")
        XCTAssertEqual(context.fontSize, 12)
        XCTAssertEqual(context.globalAlpha, 1)
        // 上游 applyFont：fontWeight 为 normal 时不拼进字符串。
        XCTAssertEqual(context.font, "12px sans-serif")

        context.setLineStyle("#ff0000", 4)
        XCTAssertEqual(context.strokeStyle, "#ff0000")
        XCTAssertEqual(context.lineWidth, 4)
        XCTAssertEqual(context.lineCap, "round")
        XCTAssertEqual(context.lineJoin, "round")
    }

    /// 上游 `setFontSize`：`Number(fontSize) || this.fontSize`，0 与非法值保留原值。
    func testCanvasContextFontSizeAndFontParsing() {
        let context = UPCanvasContext()
        context.setFontSize(20)
        XCTAssertEqual(context.fontSize, 20)
        // 照抄上游：0 是假值，保留原字号。
        context.setFontSize(0)
        XCTAssertEqual(context.fontSize, 20)

        // 上游 setFont 从字符串里抽 `\d+px`。
        context.setFont("bold 30px sans-serif")
        XCTAssertEqual(context.fontSize, 30)
        // 抽不到 px 时保留原值。
        context.setFont("bold sans-serif")
        XCTAssertEqual(context.fontSize, 30)

        XCTAssertEqual(UPCanvasContext.fontSize(in: "14px Arial"), 14)
        XCTAssertEqual(UPCanvasContext.fontSize(in: "italic 16.5px Arial"), 16.5)
        XCTAssertNil(UPCanvasContext.fontSize(in: "bold Arial"))
    }

    /// 上游 `estimateTextWidth`：全角占一个字号、空白 0.28、半角 0.56。
    func testCanvasContextEstimateTextWidthMatchesUpstream() {
        XCTAssertEqual(UPCanvasContext.estimateTextWidth("汉字", fontSize: 10), 20)
        XCTAssertEqual(UPCanvasContext.estimateTextWidth("ab", fontSize: 10), 11.2, accuracy: 0.0001)
        XCTAssertEqual(UPCanvasContext.estimateTextWidth(" ", fontSize: 10), 2.8, accuracy: 0.0001)
        // 全角标点也算一个字号。
        XCTAssertEqual(UPCanvasContext.estimateTextWidth("，", fontSize: 10), 10)
        // 字号非法时退回上游的 12。
        XCTAssertEqual(UPCanvasContext.estimateTextWidth("汉", fontSize: 0), 12)

        XCTAssertTrue(UPCanvasContext.isFullWidth("中"))
        XCTAssertTrue(UPCanvasContext.isFullWidth("あ"))
        XCTAssertTrue(UPCanvasContext.isFullWidth("한"))
        XCTAssertFalse(UPCanvasContext.isFullWidth("A"))
    }

    /// 上游 `draw(isLastDraw)`：为真时先清屏再画，为假时叠加。
    func testCanvasContextDrawAccumulatesOrReplaces() {
        let context = UPCanvasContext()
        context.fillRect(0, 0, 10, 10)
        XCTAssertTrue(context.commands.isEmpty)

        context.draw()
        XCTAssertEqual(context.commands.count, 1)

        context.strokeRect(0, 0, 20, 20)
        context.draw()
        XCTAssertEqual(context.commands.count, 2)

        // isLastDraw 为真时替换而不是叠加。
        context.fillRect(0, 0, 5, 5)
        context.draw(true)
        XCTAssertEqual(context.commands.count, 1)

        var callbacks = 0
        context.draw(false) { callbacks += 1 }
        XCTAssertEqual(callbacks, 1)
    }

    /// 上游 `beginPath` / `moveTo` / `lineTo` 攒路径，`fill` / `stroke` 才落笔。
    func testCanvasContextPathAndRectCommitOnFillOrStroke() {
        let context = UPCanvasContext()
        context.beginPath()
        context.moveTo(0, 0)
        context.lineTo(10, 10)
        context.stroke()
        context.draw()
        XCTAssertEqual(context.commands.count, 1)
        XCTAssertFalse(context.commands[0].filled)

        // 单点路径不成线，上游 canvas 也画不出东西。
        context.beginPath()
        context.moveTo(5, 5)
        context.stroke()
        context.draw()
        XCTAssertEqual(context.commands.count, 1)

        // rect 塞进路径后由 fill 落笔，颜色取 fillStyle。
        context.setFillStyle("#ff0000")
        context.beginPath()
        context.rect(0, 0, 20, 20)
        context.fill()
        context.draw()
        XCTAssertEqual(context.commands.count, 2)
        XCTAssertTrue(context.commands[1].filled)
        XCTAssertEqual(context.commands[1].color, "#ff0000")
    }

    /// 上游 `save()` / `restore()` 的状态栈。
    func testCanvasContextSaveRestoreRoundTripsState() {
        let context = UPCanvasContext()
        context.setFillStyle("#111111")
        context.setLineWidth(2)
        context.save()

        context.setFillStyle("#222222")
        context.setLineWidth(8)
        XCTAssertEqual(context.fillStyle, "#222222")

        context.restore()
        XCTAssertEqual(context.fillStyle, "#111111")
        XCTAssertEqual(context.lineWidth, 2)

        // 栈空时 restore 是空操作。
        context.restore()
        XCTAssertEqual(context.fillStyle, "#111111")
    }

    /// 上游 `clearCanvas()`：先 clearRect 再按 bgColor 铺底，最后 draw。
    func testCanvasContextClearCanvasFillsBackground() {
        let context = UPCanvasContext()
        context.clearCanvas(width: 100, height: 50, bgColor: "#ffffff")
        XCTAssertEqual(context.commands.count, 2)
        XCTAssertEqual(context.commands[1].color, "#ffffff")

        // transparent 时只擦不铺。
        let transparent = UPCanvasContext()
        transparent.clearCanvas(width: 100, height: 50, bgColor: "transparent")
        XCTAssertEqual(transparent.commands.count, 1)
    }

    /// 上游 `setTextAlign` 的三档对齐映射到锚点。
    func testCanvasTextAnchorMapsUpstreamAlignment() {
        XCTAssertEqual(UPCanvas.textAnchor("left"), UnitPoint(x: 0, y: 1))
        XCTAssertEqual(UPCanvas.textAnchor("center"), UnitPoint(x: 0.5, y: 1))
        XCTAssertEqual(UPCanvas.textAnchor("right"), UnitPoint(x: 1, y: 1))
        XCTAssertEqual(UPCanvas.textAnchor("start"), UnitPoint(x: 0, y: 1))
    }

    func testSignatureSupportsUndoClearAndDeterministicExport() {
        let signature = UPSignature(width: 200, height: 100)
        signature.addStroke([CGPoint(x: 1, y: 2), CGPoint(x: 4, y: 8)])
        signature.addStroke([CGPoint(x: 10, y: 12), CGPoint(x: 14, y: 18)])

        XCTAssertEqual(signature.strokes.count, 2)
        XCTAssertTrue(signature.undo())
        XCTAssertEqual(signature.strokes.count, 1)
        XCTAssertFalse(signature.isEmpty)
        XCTAssertFalse(signature.exportData().isEmpty)
        signature.clear()
        XCTAssertTrue(signature.isEmpty)
    }

    /// `u-signature.vue` 的内联 props：`width: 300`、`height: 200`、
    /// `bgColor: '#ffffff'`、`color: '#000000'`、`thickness: 3`、`showToolbar: true`。
    func testSignaturePropDefaultsMatchUpstream() {
        let signature = UPSignature()
        XCTAssertEqual(signature.width, 300)
        XCTAssertEqual(signature.height, 200)
        XCTAssertEqual(signature.bgColor, "#ffffff")
        XCTAssertEqual(signature.color, "#000000")
        XCTAssertEqual(signature.thickness, 3)
        XCTAssertTrue(signature.showToolbar)
        XCTAssertEqual(signature.presetColors.count, 8)
        XCTAssertEqual(signature.presetColors.first, "#000000")
        // 上游 `data.lineColor` / `lineWidth` 由 props 播种。
        XCTAssertEqual(signature.lineColor, "#000000")
        XCTAssertEqual(signature.lineWidth, 3)
        XCTAssertFalse(signature.showBrushSettings)
        XCTAssertFalse(signature.showColorSettings)
    }

    /// 上游改色/改粗后旧笔画保持原样，新笔画用新设置。
    func testSignatureStrokesCaptureCurrentPenSettings() {
        let signature = UPSignature(color: "#000000", thickness: 3)
        signature.addStroke([.zero, CGPoint(x: 1, y: 1)])
        signature.selectColor("#ff0000")
        signature.setLineWidth(8)
        signature.addStroke([.zero, CGPoint(x: 2, y: 2)])
        XCTAssertEqual(signature.strokes.map(\.color), ["#000000", "#ff0000"])
        XCTAssertEqual(signature.strokes.map(\.lineWidth), [3, 8])
        // 上游滑块范围 1…20。
        signature.setLineWidth(100)
        XCTAssertEqual(signature.lineWidth, 20)
        signature.setLineWidth(0)
        XCTAssertEqual(signature.lineWidth, 1)
    }

    /// 上游 `toggleBrushSettings` / `toggleColorSettings` 两个面板开关。
    func testSignatureTogglesSettingPanels() {
        let signature = UPSignature()
        signature.toggleBrushSettings()
        XCTAssertTrue(signature.showBrushSettings)
        signature.toggleColorSettings()
        XCTAssertTrue(signature.showColorSettings)
        signature.toggleBrushSettings()
        XCTAssertFalse(signature.showBrushSettings)
    }

    /// 上游 `clear()` 抛 `clear`；`exportSignature()` 空签名直接返回，
    /// 有内容时抛 `confirm(path)`。
    func testSignatureClearAndExportEvents() throws {
        var cleared = 0
        var paths: [String] = []
        let signature = UPSignature(width: 40, height: 30)
            .onClear { cleared += 1 }
            .onConfirm { paths.append($0) }

        XCTAssertNil(signature.exportSignature())
        XCTAssertTrue(paths.isEmpty)

        signature.addStroke([CGPoint(x: 1, y: 1), CGPoint(x: 20, y: 20)])
        let path = try XCTUnwrap(signature.exportSignature())
        XCTAssertEqual(paths, [path])
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        try? FileManager.default.removeItem(atPath: path)

        signature.clear()
        XCTAssertEqual(cleared, 1)
        XCTAssertTrue(signature.isEmpty)
    }

    /// 上游 `resolvedBgColor`：显式传入的底色原样使用。
    func testSignatureResolvedBackgroundKeepsExplicitColor() {
        XCTAssertEqual(UPSignature(bgColor: "#f0f0f0").resolvedBgColor, "#f0f0f0")
    }
}

@MainActor
final class ImageCompositionTests: XCTestCase {
    func testCropperClampsCropRectAndConfirmsResult() {
        var result: UPCropResult?
        let cropper = UPCropper(src: "photo", sourceSize: CGSize(width: 400, height: 300))
            .onConfirm { result = $0 }

        cropper.setCropRect(CGRect(x: -20, y: 20, width: 500, height: 200))
        XCTAssertEqual(cropper.cropRect, CGRect(x: 0, y: 20, width: 400, height: 200))
        let confirmed = cropper.confirm()
        XCTAssertEqual(confirmed.rect, cropper.cropRect)
        XCTAssertEqual(result, confirmed)
    }

    /// `u-cropper.vue` 的内联 props（对象简写形式）：`canScale: true`、
    /// `canRotate: true`、`canChangeSize: false`、`noTab: true`、`inner: false`、
    /// `fillColor: 'transparent'`、`areaWidth/areaHeight: '300rpx'`、
    /// `exportWidth/exportHeight: '260rpx'`；`created` 里 quality/minScale/maxScale
    /// 分别兜底 0.9 / 0.3 / 4。
    func testCropperPropDefaultsMatchUpstream() {
        let cropper = UPCropper(sourceSize: CGSize(width: 400, height: 400))
        XCTAssertTrue(cropper.canScale)
        XCTAssertTrue(cropper.canRotate)
        XCTAssertFalse(cropper.canChangeSize)
        XCTAssertTrue(cropper.noTab)
        XCTAssertFalse(cropper.inner)
        XCTAssertEqual(cropper.fillColor, "transparent")
        XCTAssertEqual(cropper.areaWidth, "300rpx")
        XCTAssertEqual(cropper.exportWidth, "260rpx")
        XCTAssertEqual(cropper.quality, 0.9)
        XCTAssertEqual(cropper.minScale, 0.3)
        XCTAssertEqual(cropper.maxScale, 4)
        XCTAssertEqual(cropper.rotation, 0)
        XCTAssertEqual(cropper.scale, 1)
        XCTAssertFalse(cropper.previewing)
        XCTAssertEqual(cropper.exportSize, CGSize(width: UPUnit.rpx(CGFloat(260)),
                                                 height: UPUnit.rpx(CGFloat(260))))
        // 裁剪框按 areaWidth/areaHeight 居中。
        XCTAssertEqual(cropper.cropRect.width, UPUnit.rpx(CGFloat(300)))
        XCTAssertEqual(cropper.cropRect.midX, 200)
    }

    /// 上游 `letRotate = (canRotate === false || inner === true) ? 0 : 1`，
    /// `rotate()` 补到下一个 90° 整数倍；`inner` 时按钮少一个。
    func testCropperRotationHonoursCanRotateAndInner() {
        let cropper = UPCropper(sourceSize: CGSize(width: 100, height: 100))
        XCTAssertTrue(cropper.rotationEnabled)
        cropper.rotate()
        XCTAssertEqual(cropper.rotation, 90)
        cropper.rotate()
        XCTAssertEqual(cropper.rotation, 180)
        XCTAssertEqual(cropper.buttonTitles.count, 5)

        let inner = UPCropper(sourceSize: CGSize(width: 100, height: 100), inner: true)
        XCTAssertFalse(inner.rotationEnabled)
        inner.rotate()
        XCTAssertEqual(inner.rotation, 0)
        XCTAssertEqual(inner.buttonTitles.count, 4)
        XCTAssertFalse(inner.buttonTitles.contains("旋转"))

        let noRotate = UPCropper(sourceSize: CGSize(width: 100, height: 100), canRotate: false)
        noRotate.rotate()
        XCTAssertEqual(noRotate.rotation, 0)
    }

    /// 上游缩放夹在 `minScale`…`maxScale`，`canScale` 为假时不响应。
    func testCropperScaleClampsToRange() {
        let cropper = UPCropper(sourceSize: CGSize(width: 100, height: 100), minScale: 0.5, maxScale: 2)
        cropper.setScale(5)
        XCTAssertEqual(cropper.scale, 2)
        cropper.setScale(0.1)
        XCTAssertEqual(cropper.scale, 0.5)

        let fixed = UPCropper(sourceSize: CGSize(width: 100, height: 100), canScale: false)
        fixed.setScale(3)
        XCTAssertEqual(fixed.scale, 1)
    }

    /// 上游 `letChangeSize` 为假时手势只能平移。
    func testCropperResizeRequiresCanChangeSize() {
        let fixed = UPCropper(sourceSize: CGSize(width: 200, height: 200), areaWidth: "0", areaHeight: "0")
        let original = fixed.cropRect.size
        fixed.resizeCropRect(to: CGSize(width: 50, height: 50))
        XCTAssertEqual(fixed.cropRect.size, original)

        let resizable = UPCropper(sourceSize: CGSize(width: 200, height: 200), canChangeSize: true)
        resizable.resizeCropRect(to: CGSize(width: 50, height: 50))
        XCTAssertEqual(resizable.cropRect.size, CGSize(width: 50, height: 50))

        // 平移不受限制，但会 clamp 在画布内。
        resizable.dragCropRect(by: CGSize(width: 500, height: 500))
        XCTAssertEqual(resizable.cropRect.origin, CGPoint(x: 150, y: 150))
    }

    /// 上游 `chooseImage(index, params, data)` 把 index/data 带进 `confirm` 负载。
    func testCropperChooseImageCarriesIndexAndData() {
        var requests: [UPCropperPickRequest] = []
        var results: [UPCropResult] = []
        let cropper = UPCropper(src: "photo", sourceSize: CGSize(width: 100, height: 100))
            .onSelect { requests.append($0) }
            .onConfirm { results.append($0) }
        cropper.chooseImage(index: 2, data: "extra")
        XCTAssertEqual(requests.count, 1)
        XCTAssertTrue(requests[0].needsPicker)
        _ = cropper.confirm()
        XCTAssertEqual(results.first?.index, 2)
        XCTAssertEqual(results.first?.data, "extra")

        // 直接给 imageSrc 时不需要弹相册。
        cropper.chooseImage(index: 0, imageSrc: "/a.png")
        XCTAssertFalse(requests.last?.needsPicker ?? true)
    }

    /// 上游 `preview()` / `hideImg()` / `close()`。
    func testCropperPreviewAndCancel() {
        var cancelled = 0
        let cropper = UPCropper(sourceSize: CGSize(width: 100, height: 100))
            .onCancel { cancelled += 1 }
        cropper.preview()
        XCTAssertTrue(cropper.previewing)
        cropper.hidePreview()
        XCTAssertFalse(cropper.previewing)
        cropper.preview()
        cropper.cancel()
        XCTAssertFalse(cropper.previewing)
        XCTAssertEqual(cancelled, 1)
    }

    /// 对应上游 `avtinit` 事件。
    func testCropperInitEvent() {
        var inited = 0
        UPCropper().onInit { inited += 1 }.initialized()
        XCTAssertEqual(inited, 1)
    }

    func testPosterRetainsLayersAndRendersConfiguredCanvasSize() {
        let poster = UPPoster(size: CGSize(width: 320, height: 480), layers: [
            UPPosterLayer.text("Hello", frame: CGRect(x: 10, y: 20, width: 100, height: 30)),
            UPPosterLayer.rectangle(frame: CGRect(x: 0, y: 0, width: 320, height: 480), color: "#ffffff")
        ])

        XCTAssertEqual(poster.views.count, 2)
        XCTAssertEqual(poster.renderSize, CGSize(width: 320, height: 480))
        XCTAssertEqual(poster.renderedCommands.count, 2)
    }

    /// 上游 `json` 是唯一 prop：`json.css` 定画布，`json.views` 是四种类型的图层。
    func testPosterJSONDrivesCanvasAndCommands() {
        let poster = UPPoster(json: UPPosterJSON(
            css: UPPosterCSS(width: "750rpx", height: "1114rpx", background: "#ffffff"),
            views: [
                UPPosterView(type: "view", css: UPPosterCSS(left: "40rpx", top: "144rpx",
                                                           width: "670rpx", height: "930rpx",
                                                           background: "#ffffff", radius: "16rpx")),
                UPPosterView(type: "text", text: "标题",
                             css: UPPosterCSS(left: "72rpx", top: "90rpx", width: "460rpx",
                                              color: "#333333", fontSize: "32rpx",
                                              fontWeight: "bold", lineClamp: 2)),
                UPPosterView(type: "image", src: "/a.png",
                             css: UPPosterCSS(left: "72rpx", top: "176rpx",
                                              width: "606rpx", height: "606rpx")),
                UPPosterView(type: "qrcode", text: "https://a.com",
                             css: UPPosterCSS(left: "500rpx", top: "900rpx",
                                              width: "178rpx", height: "178rpx")),
                UPPosterView(type: "unknown")
            ]
        ))
        XCTAssertEqual(poster.renderSize, CGSize(width: UPUnit.rpx(CGFloat(750)), height: UPUnit.rpx(CGFloat(1114))))
        // 未知 type 上游 switch 不命中，原生同样跳过。
        XCTAssertEqual(poster.renderedCommands.count, 4)
        guard case .qrcode(let value, let frame) = poster.renderedCommands[3] else {
            return XCTFail("expected qrcode command")
        }
        XCTAssertEqual(value, "https://a.com")
        XCTAssertEqual(frame.width, UPUnit.rpx(178))
    }

    /// 缺省画布尺寸对应上游 `'750rpx'` / `'1114rpx'`。
    func testPosterDefaultCanvasFallsBackToUpstreamSize() {
        let poster = UPPoster()
        XCTAssertEqual(poster.renderSize, CGSize(width: UPUnit.rpx(CGFloat(750)), height: UPUnit.rpx(CGFloat(1114))))
        XCTAssertTrue(poster.views.isEmpty)
    }

    /// 仓库既有的 `UPPosterLayer` 会转成上游 `views` 元素。
    func testPosterLayerMapsToUpstreamView() {
        let text = UPPosterLayer.text("x", frame: CGRect(x: 1, y: 2, width: 3, height: 4), color: "#f00")
        XCTAssertEqual(text.posterView.type, "text")
        XCTAssertEqual(text.posterView.css.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
        XCTAssertEqual(text.posterView.css.color, "#f00")
        XCTAssertEqual(UPPosterLayer.qrcode("v", frame: .zero).posterView.type, "qrcode")
        XCTAssertEqual(UPPosterLayer.image(source: "/a.png", frame: .zero).posterView.src, "/a.png")
    }

    /// `UPPosterCSS.length` 对应上游 `convertRpxToPx`。
    func testPosterCSSLengthMatchesConvertRpxToPx() {
        XCTAssertEqual(UPPosterCSS.length("750rpx"), UPUnit.rpx(750))
        XCTAssertEqual(UPPosterCSS.length("20px"), 20)
        XCTAssertEqual(UPPosterCSS.length("36"), 36)
        XCTAssertEqual(UPPosterCSS.length(""), 0)
        XCTAssertTrue(UPPosterCSS(fontWeight: "bold").isBold)
        XCTAssertTrue(UPPosterCSS(fontWeight: "700").isBold)
        XCTAssertFalse(UPPosterCSS(fontWeight: "normal").isBold)
    }

    /// 上游 `drawGradientBackground` 的角度与颜色解析，取不到角度时默认 135°。
    func testPosterGradientParsing() {
        XCTAssertTrue(UPPosterGradient.isGradient("linear-gradient(45deg, #fff, #000)"))
        XCTAssertTrue(UPPosterGradient.isGradient("radial-gradient(#fff, #000)"))
        XCTAssertFalse(UPPosterGradient.isGradient("#ffffff"))
        XCTAssertEqual(UPPosterGradient.angle(of: "linear-gradient(45deg, #fff, #000)"), 45)
        XCTAssertEqual(UPPosterGradient.angle(of: "linear-gradient(to right, #fff, #000)"), 135)
        XCTAssertEqual(UPPosterGradient.colors(of: "linear-gradient(45deg, #ffffff 0%, #000000 100%)"),
                       ["#ffffff", "#000000"])
        let points = UPPosterGradient.unitPoints(angle: 180)
        XCTAssertEqual(points.start.y, 0, accuracy: 0.001)
        XCTAssertEqual(points.end.y, 1, accuracy: 0.001)
    }

    /// `exportImage()` 对应上游同名方法：返回尺寸、临时文件路径与图片数据。
    func testPosterExportImageWritesTemporaryFile() throws {
        let poster = UPPoster(size: CGSize(width: 40, height: 60), layers: [
            UPPosterLayer.rectangle(frame: CGRect(x: 0, y: 0, width: 40, height: 60), color: "#ff0000")
        ])
        let export = try XCTUnwrap(poster.exportImage(scale: 1))
        XCTAssertEqual(export.width, 40)
        XCTAssertEqual(export.height, 60)
        XCTAssertFalse(export.data.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: export.path))
        try? FileManager.default.removeItem(atPath: export.path)
    }
}

@MainActor
final class CodeGenerationTests: XCTestCase {
    func testQRCodeProducesCoreImageOutput() {
        let code = UPQRCode(value: "https://example.com", size: 128)
        XCTAssertFalse(code.payload.isEmpty)
        XCTAssertNotNil(code.generatedImage)
    }

    /// 上游 props 内联在 `.vue` 里：`size: 200`、`unit: 'px'`、`show: true`、`val: ''`、
    /// `background: '#ffffff'`、`foreground: '#000000'`、`pdground: '#000000'`、
    /// `icon: ''`、`iconSize: 40`、`lv: 3`、`quietZone: 0`、`onval: true`、
    /// `loadMake: true`、`usingComponents: true`、`showLoading: true`、
    /// `loadingText: '生成中'`、`allowPreview: false`、`useRootHeightAndWidth: false`。
    func testQRCodePropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.qrcode.size, 200)
        XCTAssertEqual(UPConfig.qrcode.unit, "px")
        XCTAssertTrue(UPConfig.qrcode.show)
        XCTAssertEqual(UPConfig.qrcode.val, "")
        XCTAssertEqual(UPConfig.qrcode.background, "#ffffff")
        XCTAssertEqual(UPConfig.qrcode.foreground, "#000000")
        XCTAssertEqual(UPConfig.qrcode.pdground, "#000000")
        XCTAssertEqual(UPConfig.qrcode.icon, "")
        XCTAssertEqual(UPConfig.qrcode.iconSize, 40)
        XCTAssertEqual(UPConfig.qrcode.lv, 3)
        XCTAssertEqual(UPConfig.qrcode.quietZone, 0)
        XCTAssertTrue(UPConfig.qrcode.onval)
        XCTAssertTrue(UPConfig.qrcode.loadMake)
        XCTAssertTrue(UPConfig.qrcode.usingComponents)
        XCTAssertTrue(UPConfig.qrcode.showLoading)
        XCTAssertEqual(UPConfig.qrcode.loadingText, "生成中")
        XCTAssertFalse(UPConfig.qrcode.allowPreview)
        XCTAssertFalse(UPConfig.qrcode.useRootHeightAndWidth)
        XCTAssertEqual(UPConfig.qrcode.emptyToast, "二维码内容不能为空")

        let code = UPQRCode(val: "https://example.com")
        XCTAssertEqual(code.size, 200)
        XCTAssertEqual(code.sizeLocal, 200)
        XCTAssertEqual(code.unit, "px")
        XCTAssertTrue(code.show)
        XCTAssertEqual(code.background, "#ffffff")
        XCTAssertEqual(code.foreground, "#000000")
        XCTAssertEqual(code.pdground, "#000000")
        XCTAssertEqual(code.icon, "")
        XCTAssertEqual(code.iconSize, 40)
        // 上游 lv 默认 3，对应 Core Image 的 H。
        XCTAssertEqual(code.lv, .high)
        XCTAssertEqual(code.lv.coreImageValue, "H")
        XCTAssertEqual(code.quietZone, 0)
        XCTAssertTrue(code.onval)
        XCTAssertTrue(code.loadMake)
        XCTAssertFalse(code.allowPreview)
        XCTAssertFalse(code.useRootHeightAndWidth)
        XCTAssertFalse(code.cid.isEmpty)
    }

    /// 上游 `_empty(v)`：空串与 `'undefined'` / `'null'` / `'{}'` / `'[]'` 都算空。
    func testQRCodeEmptyValueMatchesUpstream() {
        XCTAssertTrue(UPQRCode.isEmpty(""))
        XCTAssertTrue(UPQRCode.isEmpty("undefined"))
        XCTAssertTrue(UPQRCode.isEmpty("null"))
        XCTAssertTrue(UPQRCode.isEmpty("{}"))
        XCTAssertTrue(UPQRCode.isEmpty("[]"))
        XCTAssertFalse(UPQRCode.isEmpty("0"))

        XCTAssertTrue(UPQRCode(val: "").isEmptyValue)
        XCTAssertNil(UPQRCode(val: "").modules)
    }

    /// 上游 `setNewSize()`：取根节点宽高里较短的一边。
    func testQRCodeRootSideLengthTakesShorterEdge() {
        XCTAssertEqual(UPQRCode.rootSideLength(CGSize(width: 200, height: 120)), 120)
        XCTAssertEqual(UPQRCode.rootSideLength(CGSize(width: 80, height: 300)), 80)
        // 相等时上游走 else 分支取 width。
        XCTAssertEqual(UPQRCode.rootSideLength(CGSize(width: 90, height: 90)), 90)
    }

    /// 上游 `renderCount = moduleCount + quietZone * 2`，`tileW = size / renderCount`。
    func testQRCodeQuietZoneExpandsRenderGrid() {
        let plain = UPQRCode(val: "HI", size: 100, lv: .medium)
        let count = plain.moduleCount
        XCTAssertGreaterThan(count, 0)
        XCTAssertEqual(plain.renderCount, count)
        XCTAssertEqual(plain.tileSize, 100 / CGFloat(count), accuracy: 0.0001)

        let padded = UPQRCode(val: "HI", size: 100, lv: .medium, quietZone: 4)
        XCTAssertEqual(padded.renderCount, count + 8)
        // 静区范围内一律当白格。
        XCTAssertFalse(padded.isDark(row: 0, col: 0))
        XCTAssertFalse(padded.isDark(row: padded.renderCount - 1, col: padded.renderCount - 1))
    }

    /// 上游 `getForeGround`：三段开区间判定，只覆盖角点方块的内圈。
    func testQRCodePositionDetectorRegionsMatchUpstream() {
        let code = UPQRCode(val: "HI", size: 100, lv: .medium)
        let count = code.moduleCount

        XCTAssertTrue(code.isPositionDetector(row: 2, col: 2))
        XCTAssertTrue(code.isPositionDetector(row: 4, col: 4))
        // 开区间，边界本身不算。
        XCTAssertFalse(code.isPositionDetector(row: 1, col: 2))
        XCTAssertFalse(code.isPositionDetector(row: 5, col: 2))
        // 左下角与右上角的内圈。
        XCTAssertTrue(code.isPositionDetector(row: count - 4, col: 3))
        XCTAssertTrue(code.isPositionDetector(row: 3, col: count - 4))
        // 正中心不是定位角点。
        XCTAssertFalse(code.isPositionDetector(row: count / 2, col: count / 2))
    }

    /// Core Image 的纠错级别越高、模块数越多，`lv` 映射必须落到不同矩阵。
    func testQRCodeCorrectLevelMapsToCoreImage() {
        XCTAssertEqual(UPQRCodeCorrectLevel.low.coreImageValue, "L")
        XCTAssertEqual(UPQRCodeCorrectLevel.medium.coreImageValue, "M")
        XCTAssertEqual(UPQRCodeCorrectLevel.quartile.coreImageValue, "Q")
        XCTAssertEqual(UPQRCodeCorrectLevel.high.coreImageValue, "H")

        let low = UPQRCode(val: "https://example.com", lv: .low).moduleCount
        let high = UPQRCode(val: "https://example.com", lv: .high).moduleCount
        XCTAssertGreaterThan(high, low)
    }

    /// 上游 `_makeCode()` 内容为空时直接返回空串；`_clearCode()` 抛一次空 result。
    func testQRCodeMakeAndClearReportResult() {
        var results: [String] = []
        let empty = UPQRCode(val: "").onResult { results.append($0) }
        XCTAssertEqual(empty.makeCode(), "")
        XCTAssertTrue(results.isEmpty)

        let code = UPQRCode(val: "https://example.com", size: 60).onResult { results.append($0) }
        let path = code.makeCode()
        XCTAssertFalse(path.isEmpty)
        XCTAssertEqual(code.result, path)
        XCTAssertFalse(code.loading)
        XCTAssertEqual(results, [path])

        code.clearCode()
        XCTAssertEqual(code.result, "")
        XCTAssertEqual(results, [path, ""])
    }

    /// 上游 `preview` 事件总会抛，`allowPreview` 只决定是否调系统预览。
    func testQRCodePreviewAndLongpressEmitPaths() {
        var previews: [String] = []
        var longpresses: [String] = []
        let code = UPQRCode(val: "https://example.com", size: 60)
            .onPreview { previews.append($0) }
            .onLongpressCallback { longpresses.append($0) }

        code.preview()
        XCTAssertEqual(previews, [""])

        code.longpress()
        XCTAssertEqual(longpresses.count, 1)
        XCTAssertFalse(longpresses[0].isEmpty)
        XCTAssertEqual(code.result, longpresses[0])

        code.preview()
        XCTAssertEqual(previews.last, code.result)
    }

    func testBarcodeProducesCoreImageOutputAndPreservesValue() {
        let barcode = UPBarcode(value: "1234567890", width: 240, height: 80)
        XCTAssertEqual(barcode.value, "1234567890")
        XCTAssertNotNil(barcode.generatedImage)
    }

    /// 上游 props 内联在 `.vue` 里：`format: 'auto'`、`width: 200`、`height: 80`、
    /// `displayValue: true`、`fontOptions: ''`、`font: 'monospace'`、
    /// `textAlign: 'center'`、`textPosition: 'bottom'`、`textMargin: 2`、
    /// `fontSize: 14`、`background: '#ffffff'`、`lineColor: '#000000'`、
    /// `margin: 10`、四个方向 margin 未定义、`useCanvas: true`。
    func testBarcodePropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.barcode.format, "auto")
        XCTAssertEqual(UPConfig.barcode.width, 200)
        XCTAssertEqual(UPConfig.barcode.height, 80)
        XCTAssertTrue(UPConfig.barcode.displayValue)
        XCTAssertEqual(UPConfig.barcode.font, "monospace")
        XCTAssertEqual(UPConfig.barcode.textAlign, "center")
        XCTAssertEqual(UPConfig.barcode.textPosition, "bottom")
        XCTAssertEqual(UPConfig.barcode.textMargin, 2)
        XCTAssertEqual(UPConfig.barcode.fontSize, 14)
        XCTAssertEqual(UPConfig.barcode.background, "#ffffff")
        XCTAssertEqual(UPConfig.barcode.lineColor, "#000000")
        XCTAssertEqual(UPConfig.barcode.margin, 10)
        XCTAssertTrue(UPConfig.barcode.useCanvas)
        XCTAssertEqual(UPConfig.barcode.errorText, "生成条码失败")

        let barcode = UPBarcode(value: "123")
        XCTAssertEqual(barcode.format, "auto")
        XCTAssertEqual(barcode.width, 200)
        XCTAssertEqual(barcode.height, 80)
        XCTAssertTrue(barcode.displayValue)
        XCTAssertNil(barcode.text)
        XCTAssertEqual(barcode.resolvedText, "123")
        XCTAssertEqual(barcode.fontOptions, "")
        XCTAssertEqual(barcode.font, "monospace")
        XCTAssertEqual(barcode.textAlign, "center")
        XCTAssertEqual(barcode.textPosition, "bottom")
        XCTAssertEqual(barcode.textMargin, 2)
        XCTAssertEqual(barcode.fontSize, 14)
        XCTAssertEqual(barcode.margin, 10)
        // 四个方向都回落 margin。
        XCTAssertEqual(barcode.resolvedMarginTop, 10)
        XCTAssertEqual(barcode.resolvedMarginBottom, 10)
        XCTAssertEqual(barcode.resolvedMarginLeft, 10)
        XCTAssertEqual(barcode.resolvedMarginRight, 10)
        XCTAssertTrue(barcode.useCanvas)
    }

    /// 上游 `calculateCanvasSize`：宽下限 100、高下限 `60 + textHeight`，
    /// 文字在上/下时高度里要算进 `fontSize + textMargin`。
    func testBarcodeCanvasSizeMatchesUpstream() {
        let bottom = UPBarcode(value: "123", width: 200, height: 80)
        XCTAssertEqual(bottom.textHeight, 16)
        XCTAssertEqual(bottom.canvasWidth, 220)
        XCTAssertEqual(bottom.canvasHeight, 116)

        // displayValue 为假时 textHeight 归零。
        let noText = UPBarcode(value: "123", width: 200, height: 80, displayValue: false)
        XCTAssertEqual(noText.textHeight, 0)
        XCTAssertEqual(noText.canvasHeight, 100)

        // 上游 `textPosition` 只有 top / bottom 会加 textHeight。
        let side = UPBarcode(value: "123", width: 200, height: 80, textPosition: "left")
        XCTAssertEqual(side.canvasHeight, 100)

        // 下限：宽 100、高 60 + textHeight。
        let tiny = UPBarcode(value: "123", width: 10, height: 5, margin: 0)
        XCTAssertEqual(tiny.canvasWidth, 100)
        XCTAssertEqual(tiny.canvasHeight, 76)
    }

    /// 上游 `drawBarcode` 里的模块宽度、条码 Y、文字 X/Y。
    func testBarcodeDrawingGeometryMatchesUpstream() {
        let barcode = UPBarcode(value: "123", width: 200, height: 80)
        // (220 - 10 - 10) / 100 = 2
        XCTAssertEqual(barcode.moduleWidth(dataLength: 100), 2)
        // 上游 max(1, ...)。
        XCTAssertEqual(barcode.moduleWidth(dataLength: 10_000), 1)
        XCTAssertEqual(barcode.barcodeY, 10)
        XCTAssertEqual(barcode.textX, 110)
        // barcodeY + height + textMargin + fontSize = 10 + 80 + 2 + 14 = 106，
        // 未超过 canvasHeight - marginBottom = 106，故不夹紧。
        XCTAssertEqual(barcode.textY, 106)

        let top = UPBarcode(value: "123", width: 200, height: 80, textPosition: "top")
        XCTAssertEqual(top.barcodeY, 26)
        // 上游 top 分支：marginTop + fontSize - 3。
        XCTAssertEqual(top.textY, 21)

        let leftAligned = UPBarcode(value: "123", width: 200, height: 80, textAlign: "left")
        XCTAssertEqual(leftAligned.textX, 10)
        let rightAligned = UPBarcode(value: "123", width: 200, height: 80, textAlign: "right")
        XCTAssertEqual(rightAligned.textX, 210)
    }

    /// 上游 `encodeCode128`：起始符 104、校验位 `checksum % 103`、结束符 106、
    /// 末尾 5 位安静区。这里的期望值由上游 JS 同一份编码表实跑得出。
    func testBarcodeEncodesCode128LikeUpstream() throws {
        let encoded = try UPBarcodeEncoder.encodeCode128("123")
        XCTAssertEqual(encoded,
                       "11010010000100111001101100111001011001011100100011001001100011101000000")
        XCTAssertEqual(encoded.count, 71)
        XCTAssertTrue(encoded.hasSuffix("00000"))

        // auto 与 CODE128 同路径，未覆盖的格式一律退回 CODE128。
        XCTAssertEqual(try UPBarcodeEncoder.encode("123", format: "auto"), encoded)
        XCTAssertEqual(try UPBarcodeEncoder.encode("123", format: "codabar"), encoded)

        XCTAssertThrowsError(try UPBarcodeEncoder.encodeCode128("中")) { error in
            XCTAssertEqual(error as? UPBarcodeError,
                           .invalidCharacter(format: "CODE128", character: "中"))
        }
    }

    /// 上游 `encodeEAN13`：13 位数字 + 校验位，首位决定左侧奇偶排布。
    func testBarcodeEncodesEAN13LikeUpstream() throws {
        let encoded = try UPBarcodeEncoder.encodeEAN13("5901234123457")
        XCTAssertEqual(
            encoded,
            "10100010110100111011001100100110111101001110101010110011011011001000010101110010011101000100101"
        )
        XCTAssertEqual(encoded.count, 95)

        XCTAssertThrowsError(try UPBarcodeEncoder.encodeEAN13("123")) { error in
            XCTAssertEqual(error as? UPBarcodeError, .invalidLength("EAN13 must be 13 digits"))
        }
        XCTAssertThrowsError(try UPBarcodeEncoder.encodeEAN13("5901234123456")) { error in
            XCTAssertEqual(error as? UPBarcodeError, .invalidCheckDigit("Invalid EAN13 check digit"))
        }

        // UPCA 是 '0' + 12 位后走 EAN13。
        XCTAssertEqual(try UPBarcodeEncoder.encodeUPCA("59012341234"),
                       try UPBarcodeEncoder.encodeEAN13("0590123412342"))
    }

    /// 上游 `encodeCode39`：转大写、首尾 `*`、字符间一位 `0`。
    func testBarcodeEncodesCode39LikeUpstream() throws {
        let encoded = try UPBarcodeEncoder.encodeCode39("a1")
        let star = "100010111011101"
        XCTAssertTrue(encoded.hasPrefix(star))
        XCTAssertTrue(encoded.hasSuffix(star))
        // * + 0 + A + 0 + 1 + 0 + *，每个字符 15 位、三个 0 间隔。
        XCTAssertEqual(encoded.count, 15 * 4 + 3)

        XCTAssertThrowsError(try UPBarcodeEncoder.encodeCode39("=")) { error in
            XCTAssertEqual(error as? UPBarcodeError,
                           .invalidCharacter(format: "CODE39", character: "="))
        }
    }

    /// 上游 `encodeEAN8` 的校验和权重是 `3, 1, 3, 1...`，与 EAN13 相反。
    func testBarcodeEncodesEAN8AndShortFormats() throws {
        let encoded = try UPBarcodeEncoder.encodeEAN8("96385074")
        XCTAssertEqual(encoded.count, 67)
        XCTAssertTrue(encoded.hasPrefix("101"))
        XCTAssertTrue(encoded.hasSuffix("101"))

        // 照抄上游：EAN5/EAN2 算出的 patterns 压根没用，每位都走 leftOdd。
        let ean2 = try UPBarcodeEncoder.encodeEAN52("12", format: "EAN2")
        XCTAssertEqual(ean2, "1011" + "0011001" + "01" + "0010011")
        let ean5 = try UPBarcodeEncoder.encodeEAN52("12345", format: "EAN5")
        XCTAssertEqual(ean5.count, 4 + 7 * 5 + 2 * 4)

        XCTAssertThrowsError(try UPBarcodeEncoder.encodeEAN52("1", format: "EAN2")) { error in
            XCTAssertEqual(error as? UPBarcodeError, .invalidLength("EAN2 must be 2 digits"))
        }
    }

    /// 上游 `encodeUPCE`：7 位补校验位，首位只能是 0 或 1。
    func testBarcodeEncodesUPCEWithPrefixCheck() throws {
        let encoded = try UPBarcodeEncoder.encodeUPCE("0123456")
        XCTAssertTrue(encoded.hasPrefix("101"))
        XCTAssertTrue(encoded.hasSuffix("010101101"))

        XCTAssertThrowsError(try UPBarcodeEncoder.encodeUPCE("2123456")) { error in
            XCTAssertEqual(error as? UPBarcodeError, .invalidPrefix("UPC-E must start with 0 or 1"))
        }
        XCTAssertThrowsError(try UPBarcodeEncoder.encodeUPCE("12")) { error in
            XCTAssertEqual(error as? UPBarcodeError, .invalidLength("UPC-E must be 7 or 8 digits"))
        }
    }

    /// 编码失败时上游把 `error.message` 显示在灰底红字容器里。
    func testBarcodeSurfacesEncodingErrorMessage() {
        let bad = UPBarcode(value: "123", format: "EAN13")
        XCTAssertNil(bad.encodedData)
        XCTAssertEqual(bad.errorMessage, "EAN13 must be 13 digits")

        let good = UPBarcode(value: "5901234123457", format: "EAN13")
        XCTAssertNotNil(good.encodedData)
        XCTAssertNil(good.errorMessage)
    }
}
