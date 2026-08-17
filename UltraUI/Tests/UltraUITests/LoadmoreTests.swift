import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class LoadmoreTests: XCTestCase {
    func testDefaultsMatchUviewPlusLoadmore() {
        let loadmore = UPLoadmore()

        XCTAssertEqual(loadmore.status, "loadmore")
        XCTAssertEqual(loadmore.bgColor, "transparent")
        XCTAssertTrue(loadmore.icon)
        XCTAssertEqual(loadmore.fontSize, "14")
        XCTAssertEqual(loadmore.iconSize, "17")
        XCTAssertEqual(loadmore.color, "#606266")
        XCTAssertEqual(loadmore.loadingIcon, "spinner")
        XCTAssertEqual(loadmore.loadmoreText, "加载更多")
        XCTAssertEqual(loadmore.loadingText, "正在加载...")
        XCTAssertEqual(loadmore.nomoreText, "没有更多了")
        XCTAssertFalse(loadmore.isDot)
        XCTAssertEqual(loadmore.iconColor, "#b7b7b7")
        XCTAssertEqual(loadmore.marginTop, "10")
        XCTAssertEqual(loadmore.marginBottom, "10")
        XCTAssertEqual(loadmore.height, "auto")
        XCTAssertFalse(loadmore.line)
        XCTAssertEqual(loadmore.lineColor, "#E6E8EB")
        XCTAssertFalse(loadmore.dashed)
        XCTAssertEqual(loadmore.showText, "加载更多")
        XCTAssertFalse(loadmore.showsLoadingIcon)
        XCTAssertFalse(loadmore.showsLines)
    }
}

extension LoadmoreTests {
    func testStatusTextIconAndLoadmoreEventFollowUviewPlusRules() {
        let loading = UPLoadmore(status: "loading", icon: true)
        XCTAssertEqual(loading.showText, "正在加载...")
        XCTAssertTrue(loading.showsLoadingIcon)

        let hiddenLoadingIcon = UPLoadmore(status: "loading", icon: false)
        XCTAssertFalse(hiddenLoadingIcon.showsLoadingIcon)

        let dot = UPLoadmore(status: "nomore", isDot: true)
        XCTAssertEqual(dot.showText, "●")

        let unsupportedStatus = UPLoadmore(status: "unsupported")
        XCTAssertEqual(unsupportedStatus.showText, "没有更多了")

        var emissions = 0
        let ready = UPLoadmore(status: "loadmore")
            .onLoadmore { emissions += 1 }
        ready.triggerLoadmore()
        XCTAssertEqual(emissions, 1)

        UPLoadmore(status: "loading")
            .onLoadmore { emissions += 1 }
            .triggerLoadmore()
        UPLoadmore(status: "nomore")
            .onLoadmore { emissions += 1 }
            .triggerLoadmore()
        XCTAssertEqual(emissions, 1)
    }
}

extension LoadmoreTests {
    func testStringOrNumberPropsStylesAndNativeMeasurementsRemainAvailable() {
        let style = UPStyle(["borderRadius": "6px", "opacity": "0.8"])
        let loadmore = UPLoadmore(
            fontSize: Int8(16),
            iconSize: UInt16(20),
            marginTop: CGFloat(8),
            marginBottom: "12rpx",
            height: 36,
            line: true,
            dashed: true,
            customClass: "catalog-loadmore",
            customStyle: style
        )

        XCTAssertEqual(loadmore.fontSize, "16")
        XCTAssertEqual(loadmore.iconSize, "20")
        XCTAssertEqual(loadmore.marginTop, "8")
        XCTAssertEqual(loadmore.marginBottom, "12rpx")
        XCTAssertEqual(loadmore.height, "36")
        XCTAssertEqual(loadmore.resolvedFontSize, 16)
        XCTAssertEqual(loadmore.resolvedIconSize, 20)
        XCTAssertEqual(loadmore.resolvedMarginTop, 8)
        XCTAssertEqual(loadmore.resolvedMarginBottom, 12)
        XCTAssertEqual(loadmore.resolvedHeight, 36)
        XCTAssertTrue(loadmore.showsLines)
        XCTAssertTrue(loadmore.dashed)
        XCTAssertEqual(loadmore.customClass, "catalog-loadmore")
        XCTAssertEqual(loadmore.customStyle, style)

        XCTAssertNil(UPLoadmore(height: "auto").resolvedHeight)
        XCTAssertNil(UPLoadmore(height: "not-a-length").resolvedHeight)
    }
}
