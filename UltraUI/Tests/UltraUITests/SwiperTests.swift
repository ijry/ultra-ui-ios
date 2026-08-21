import SwiftUI
import XCTest
@testable import UltraUI

@MainActor final class SwiperTests: XCTestCase {
    func testSwiperDefaultsAndStringListCompatibility() {
        let swiper = UPSwiper(list: ["https://example.com/a.png", "https://example.com/b.png"])
        XCTAssertFalse(swiper.indicator); XCTAssertTrue(swiper.autoplay); XCTAssertEqual(swiper.current, 0)
        XCTAssertEqual(swiper.interval, 3000); XCTAssertEqual(swiper.duration, 300); XCTAssertFalse(swiper.circular)
        XCTAssertEqual(swiper.height, 130); XCTAssertEqual(swiper.radius, 4)
        XCTAssertEqual(swiper.items.map(\.source), ["https://example.com/a.png", "https://example.com/b.png"])
    }

    func testSwiperBindingChangeClickAndAdvance() {
        var current = 0; var changes: [Int] = []; var clicked: [Int] = []
        let items = [UPSwiperItem(source: "a", title: "A"), UPSwiperItem(source: "b", title: "B")]
        let swiper = UPSwiper(list: items, current: Binding(get: { current }, set: { current = $0 }), circular: true).onChange { changes.append($0) }.onClick { clicked.append($0) }
        swiper.select(1); swiper.triggerClick(1)
        XCTAssertEqual(current, 1); XCTAssertEqual(changes, [1]); XCTAssertEqual(clicked, [1]); XCTAssertEqual(swiper.nextIndex(from: 1), 0)
    }

    func testSwiperIndicatorGeometryAndClamping() {
        let indicator = UPSwiperIndicator(length: "4", current: "9", indicatorActiveColor: "#fff", indicatorInactiveColor: "#888")
        XCTAssertEqual(indicator.resolvedLength, 4); XCTAssertEqual(indicator.resolvedCurrent, 3); XCTAssertEqual(indicator.lineOffset, 66); XCTAssertEqual(indicator.indicatorMode, "line")
    }
}
