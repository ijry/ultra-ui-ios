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

    func testColorPickerBindingAndChangeEventUseHexValue() {
        var value = "#ff0000"
        var changed = ""
        let picker = UPColorPicker(color: Binding(get: { value }, set: { value = $0 }))
            .onChange { changed = $0 }

        picker.select("#00ff00")
        XCTAssertEqual(value, "#00ff00")
        XCTAssertEqual(changed, "#00ff00")
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

    func testPosterRetainsLayersAndRendersConfiguredCanvasSize() {
        let poster = UPPoster(size: CGSize(width: 320, height: 480), layers: [
            UPPosterLayer.text("Hello", frame: CGRect(x: 10, y: 20, width: 100, height: 30)),
            UPPosterLayer.rectangle(frame: CGRect(x: 0, y: 0, width: 320, height: 480), color: "#ffffff")
        ])

        XCTAssertEqual(poster.layers.count, 2)
        XCTAssertEqual(poster.renderSize, CGSize(width: 320, height: 480))
        XCTAssertEqual(poster.renderedCommands.count, 2)
    }
}

@MainActor
final class CodeGenerationTests: XCTestCase {
    func testQRCodeProducesCoreImageOutput() {
        let code = UPQRCode(value: "https://example.com", size: 128)
        XCTAssertFalse(code.payload.isEmpty)
        XCTAssertNotNil(code.generatedImage)
    }

    func testBarcodeProducesCoreImageOutputAndPreservesValue() {
        let barcode = UPBarcode(value: "1234567890", width: 240, height: 80)
        XCTAssertEqual(barcode.value, "1234567890")
        XCTAssertNotNil(barcode.generatedImage)
    }
}
