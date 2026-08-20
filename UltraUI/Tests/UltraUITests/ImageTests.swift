import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class ImageTests: XCTestCase {
    func testDefaultsMatchUviewPlusImage() {
        let image = UPImage()

        XCTAssertEqual(image.src, "")
        XCTAssertEqual(image.mode, "aspectFill")
        XCTAssertEqual(image.width, "300")
        XCTAssertEqual(image.height, "225")
        XCTAssertEqual(image.shape, "square")
        XCTAssertEqual(image.radius, "0")
        XCTAssertTrue(image.lazyLoad)
        XCTAssertTrue(image.showMenuByLongpress)
        XCTAssertEqual(image.loadingIcon, "photo")
        XCTAssertEqual(image.errorIcon, "error-circle")
        XCTAssertTrue(image.showLoading)
        XCTAssertTrue(image.showError)
        XCTAssertTrue(image.fade)
        XCTAssertFalse(image.webp)
        XCTAssertEqual(image.duration, 500)
        XCTAssertEqual(image.bgColor, "#f3f4f6")
    }

    func testInitialPresentationUsesErrorForEmptySourceAndLoadingForNonemptySource() {
        let empty = UPImage()
        let pending = UPImage(src: "https://example.com/avatar.png")

        XCTAssertEqual(empty.initialLoadState, .error)
        XCTAssertTrue(empty.showsErrorPlaceholder)
        XCTAssertFalse(empty.showsLoadingPlaceholder)
        XCTAssertEqual(pending.initialLoadState, .loading)
        XCTAssertTrue(pending.showsLoadingPlaceholder)
        XCTAssertFalse(pending.showsErrorPlaceholder)
    }

    func testStringUnitPropsAndDurationNormalizeForNativeRendering() {
        let image = UPImage(
            width: "120rpx",
            height: "60px",
            radius: "12px",
            duration: "250"
        )

        XCTAssertEqual(image.resolvedWidth, 120)
        XCTAssertEqual(image.resolvedHeight, 60)
        XCTAssertEqual(image.resolvedRadius, 12)
        XCTAssertEqual(image.duration, 250)
    }

    func testNumericDimensionInitializerPreservesNumberProps() {
        let image = UPImage(width: 120, height: 60, radius: 12, duration: 250)

        XCTAssertEqual(image.width, "120")
        XCTAssertEqual(image.height, "60")
        XCTAssertEqual(image.radius, "12")
        XCTAssertEqual(image.duration, 250)
    }

    func testStringAndNumberPropsCanBeMixedIndependently() {
        let image = UPImage(
            width: 120,
            height: "60rpx",
            radius: 12,
            duration: "250"
        )

        XCTAssertEqual(image.width, "120")
        XCTAssertEqual(image.height, "60rpx")
        XCTAssertEqual(image.radius, "12")
        XCTAssertEqual(image.duration, 250)
    }

    func testLoadingAndErrorSlotsAreAvailableAlongsideNativeProps() {
        let image = UPImage(
            src: "https://example.com/avatar.png",
            loading: { Text("加载中") },
            error: { Text("加载失败") }
        )

        XCTAssertTrue(image.hasLoadingSlot)
        XCTAssertTrue(image.hasErrorSlot)
    }

    func testEventModifiersRegisterNativeEquivalentCallbacks() {
        var clickCount = 0
        var loadedSource = ""
        var failedMessage = ""
        let image = UPImage(src: "https://example.com/avatar.png")
            .onClick { clickCount += 1 }
            .onLoad { loadedSource = $0.source }
            .onError { failedMessage = $0.message }

        image.onClickHandler?()
        image.onLoadHandler?(UPImageLoadEvent(source: "https://example.com/avatar.png"))
        image.onErrorHandler?(UPImageErrorEvent(source: "https://example.com/avatar.png", message: "offline"))

        XCTAssertEqual(clickCount, 1)
        XCTAssertEqual(loadedSource, "https://example.com/avatar.png")
        XCTAssertEqual(failedMessage, "offline")
    }
}
