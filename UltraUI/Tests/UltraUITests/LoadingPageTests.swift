import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class LoadingPageTests: XCTestCase {
    func testDefaultsMirrorUviewPlusLoadingPage() {
        let page = UPLoadingPage()

        XCTAssertEqual(page.loadingText, "正在加载")
        XCTAssertEqual(page.image, "")
        XCTAssertEqual(page.loadingMode, "circle")
        XCTAssertFalse(page.loading)
        XCTAssertEqual(page.bgColor, "")
        XCTAssertEqual(page.color, "#C8C8C8")
        XCTAssertEqual(page.fontSize, "19")
        XCTAssertEqual(page.iconSize, "28")
        XCTAssertEqual(page.loadingColor, "#C8C8C8")
        XCTAssertEqual(page.zIndex, 10)
        XCTAssertEqual(page.customClass, "")
        XCTAssertEqual(page.customStyle, UPStyle())
        XCTAssertEqual(page.resolvedLoadingMode, "circle")
        XCTAssertEqual(page.resolvedFontSize, 19, accuracy: 0.001)
        XCTAssertEqual(page.resolvedIconSize, 28, accuracy: 0.001)
        XCTAssertEqual(page.effectiveBackgroundToken, "bg")
        XCTAssertFalse(page.shouldRender)
        XCTAssertFalse(page.usesImage)
        XCTAssertFalse(page.hasContentSlot)
    }

    func testStringAndNumericPropsNormalizeLikeUpstreamUnits() {
        let style = UPStyle(["background-color": "#101010", "z-index": "ignored"])
        let page = UPLoadingPage(
            loadingText: 42,
            image: "https://example.com/logo.png",
            loadingMode: "spinner",
            loading: true,
            bgColor: "#eeeeee",
            color: "#666666",
            fontSize: "24px",
            iconSize: 36.5,
            loadingColor: "primary",
            zIndex: 99,
            customClass: "loading-page",
            customStyle: style
        )

        XCTAssertEqual(page.loadingText, "42")
        XCTAssertEqual(page.image, "https://example.com/logo.png")
        XCTAssertEqual(page.loadingMode, "spinner")
        XCTAssertTrue(page.loading)
        XCTAssertEqual(page.bgColor, "#eeeeee")
        XCTAssertEqual(page.color, "#666666")
        XCTAssertEqual(page.fontSize, "24px")
        XCTAssertEqual(page.iconSize, "36.5")
        XCTAssertEqual(page.loadingColor, "primary")
        XCTAssertEqual(page.zIndex, 99)
        XCTAssertEqual(page.customClass, "loading-page")
        XCTAssertEqual(page.customStyle, style)
        XCTAssertEqual(page.resolvedFontSize, 24, accuracy: 0.001)
        XCTAssertEqual(page.resolvedIconSize, 36.5, accuracy: 0.001)
        XCTAssertEqual(page.effectiveBackgroundToken, "#101010")
        XCTAssertTrue(page.shouldRender)
        XCTAssertTrue(page.usesImage)
    }

    func testLoadingModesNormalizeAndUnsupportedValuesFallBackToCircle() {
        XCTAssertEqual(UPLoadingPage.normalizedLoadingMode("circle"), "circle")
        XCTAssertEqual(UPLoadingPage.normalizedLoadingMode("spinner"), "spinner")
        XCTAssertEqual(UPLoadingPage.normalizedLoadingMode("semicircle"), "semicircle")
        XCTAssertEqual(UPLoadingPage.normalizedLoadingMode(" unsupported "), "circle")
        XCTAssertEqual(UPLoadingPage.normalizedLoadingMode(""), "circle")

        XCTAssertEqual(UPLoadingPage(loadingMode: "semicircle").resolvedLoadingMode, "semicircle")
        XCTAssertEqual(UPLoadingPage(loadingMode: "other").resolvedLoadingMode, "circle")
    }

    func testEmptyBackgroundFollowsThemeAndExplicitBackgroundWins() {
        let followsTheme = UPLoadingPage(bgColor: "")
        let explicit = UPLoadingPage(bgColor: "warning")
        let customStyle = UPLoadingPage(
            bgColor: "",
            customStyle: UPStyle(["background-color": "#123456"])
        )

        XCTAssertEqual(followsTheme.effectiveBackgroundToken, "bg")
        XCTAssertEqual(explicit.effectiveBackgroundToken, "warning")
        XCTAssertEqual(customStyle.effectiveBackgroundToken, "#123456")
    }

    func testTrailingBuilderRepresentsTheUpstreamDefaultSlot() {
        let page = UPLoadingPage(loading: true) {
            Text("正在处理")
        }

        XCTAssertTrue(page.hasContentSlot)
        XCTAssertTrue(page.shouldRender)
    }

    #if os(macOS)
    func testLoadingPageCanRenderIntoAFixedNativeCanvas() {
        let renderer = ImageRenderer(
            content: UPLoadingPage(loadingText: "加载中", loading: true)
                .frame(width: 320, height: 640)
        )

        XCTAssertEqual(renderer.cgImage?.width, 320)
        XCTAssertEqual(renderer.cgImage?.height, 640)
    }
    #endif
}
