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

    func testSwiperSelectionBindingEmitsUserChangePayloadAndSuppressesDuplicates() {
        var current = 0
        let items = [UPSwiperItem(id: "a", source: "a"), UPSwiperItem(id: "b", source: "b")]
        var changes: [UPSwiperChange] = []
        let swiper = UPSwiper(list: items, current: Binding(get: { current }, set: { current = $0 }))
            .onChangePayload { changes.append($0) }

        swiper.selectionBinding.wrappedValue = 1
        swiper.selectionBinding.wrappedValue = 1

        XCTAssertEqual(current, 1)
        XCTAssertEqual(changes, [UPSwiperChange(index: 1, item: items[1], source: .user)])
    }

    func testSwiperCurrentItemIdAndNavigationResolveValidItems() {
        let items = [UPSwiperItem(id: "a", source: "a"), UPSwiperItem(id: "b", source: "b")]
        let swiper = UPSwiper(list: items, current: 0, currentItemId: "b", circular: true)

        XCTAssertEqual(swiper.selectedIndex, 1)
        XCTAssertEqual(swiper.previousIndex(from: 0), 1)
    }

    func testSwiperIgnoresInvalidClickIndexes() {
        var clicked: [Int] = []
        let swiper = UPSwiper(list: ["a", "b"]).onClick { clicked.append($0) }

        swiper.triggerClick(-1)
        swiper.triggerClick(2)
        swiper.triggerClick(1)

        XCTAssertEqual(clicked, [1])
    }

    func testSwiperIndicatorGeometryAndClamping() {
        let indicator = UPSwiperIndicator(length: "4", current: "9", indicatorActiveColor: "#fff", indicatorInactiveColor: "#888")
        XCTAssertEqual(indicator.resolvedLength, 4); XCTAssertEqual(indicator.resolvedCurrent, 3); XCTAssertEqual(indicator.lineOffset, 66); XCTAssertEqual(indicator.indicatorMode, "line")
    }

    /// 上游 `libs/config/props/swiper.js` 的默认值。
    func testSwiperPropDefaultsMatchUpstream() {
        XCTAssertFalse(UPConfig.swiper.indicator)
        XCTAssertEqual(UPConfig.swiper.indicatorActiveColor, "#FFFFFF")
        XCTAssertEqual(UPConfig.swiper.indicatorInactiveColor, "rgba(255, 255, 255, 0.35)")
        XCTAssertEqual(UPConfig.swiper.indicatorMode, "line")
        XCTAssertTrue(UPConfig.swiper.autoplay)
        XCTAssertEqual(UPConfig.swiper.interval, 3000)
        XCTAssertEqual(UPConfig.swiper.duration, 300)
        XCTAssertFalse(UPConfig.swiper.circular)
        XCTAssertFalse(UPConfig.swiper.vertical)
        XCTAssertEqual(UPConfig.swiper.displayMultipleItems, 1)
        XCTAssertEqual(UPConfig.swiper.easingFunction, "default")
        XCTAssertEqual(UPConfig.swiper.keyName, "url")
        XCTAssertEqual(UPConfig.swiper.imgMode, "aspectFill")
        XCTAssertEqual(UPConfig.swiper.height, "130")
        XCTAssertEqual(UPConfig.swiper.bgColor, "#f3f4f6")
        XCTAssertEqual(UPConfig.swiper.radius, "4")
        XCTAssertFalse(UPConfig.swiper.loading)
        XCTAssertFalse(UPConfig.swiper.showTitle)

        // 上游 `libs/config/props/swiperIndicator.js`：两个颜色默认都是空串。
        XCTAssertEqual(UPConfig.swiperIndicator.length, "0")
        XCTAssertEqual(UPConfig.swiperIndicator.indicatorActiveColor, "")
        XCTAssertEqual(UPConfig.swiperIndicator.indicatorInactiveColor, "")
        XCTAssertEqual(UPConfig.swiperIndicator.indicatorMode, "line")
        XCTAssertEqual(UPConfig.swiperIndicator.lineWidth, 22)
    }

    /// 上游 `getItemType(item)`：显式 type 优先，其余按后缀嗅探。
    func testSwiperItemTypeMatchesUpstream() {
        let swiper = UPSwiper(list: [] as [UPSwiperItem])
        XCTAssertEqual(swiper.itemType(UPSwiperItem(source: "a.png")), .image)
        XCTAssertEqual(swiper.itemType(UPSwiperItem(source: "a.mp4")), .video)
        XCTAssertEqual(swiper.itemType(UPSwiperItem(source: "a.m3u8")), .video)
        // 显式 type 覆盖后缀嗅探。
        XCTAssertEqual(swiper.itemType(UPSwiperItem(source: "a.mp4", type: "image")), .image)
        XCTAssertEqual(swiper.itemType(UPSwiperItem(source: "a.png", type: "video")), .video)
        // 照抄上游：显式 type 只认 image / video，其余值一律落回 image。
        XCTAssertEqual(swiper.itemType(UPSwiperItem(source: "a.mp4", type: "audio")), .image)
        // 无后缀时不算视频。
        XCTAssertEqual(swiper.itemType(UPSwiperItem(source: "https://example.com/x")), .image)
    }

    /// 上游 `itemStyle(index)`：只有同时设了前后边距才缩放非当前项。
    func testSwiperItemScaleRequiresBothMargins() {
        let plain = UPSwiper(list: ["a.png", "b.png"])
        XCTAssertFalse(plain.hasSideMargins)
        XCTAssertEqual(plain.itemScale(at: 1), 1)

        let onlyOne = UPSwiper(list: ["a.png", "b.png"], previousMargin: 20)
        XCTAssertFalse(onlyOne.hasSideMargins)
        XCTAssertEqual(onlyOne.itemScale(at: 1), 1)

        let both = UPSwiper(list: ["a.png", "b.png"], previousMargin: 20, nextMargin: 20)
        XCTAssertTrue(both.hasSideMargins)
        XCTAssertEqual(both.itemScale(at: 0), 1)
        XCTAssertEqual(both.itemScale(at: 1), 0.92)
    }

    /// 上游标题只在图片项上显示，且 `indicator && !showTitle` 决定是否画内建指示器。
    func testSwiperTitleAndIndicatorVisibility() {
        let titled = UPSwiper(list: [
            UPSwiperItem(source: "a.png", title: "图片标题"),
            UPSwiperItem(source: "b.mp4", title: "视频标题")
        ], indicator: true, showTitle: true)

        XCTAssertTrue(titled.showsTitle(for: titled.items[0]))
        // 照抄上游：视频项的标题走 <video :title>，不走这条横幅。
        XCTAssertFalse(titled.showsTitle(for: titled.items[1]))
        // showTitle 为真时不画内建指示器。
        XCTAssertFalse(titled.showsIndicator)

        let plain = UPSwiper(list: ["a.png"], indicator: true)
        XCTAssertTrue(plain.showsIndicator)
        // loading 时也不画。
        XCTAssertFalse(UPSwiper(list: ["a.png"], indicator: true, loading: true).showsIndicator)
    }

    /// 上游 `:displayMultipleItems="list.length > 0 ? displayMultipleItems : 0"`。
    func testSwiperDisplayMultipleItemsFallsBackToZeroWhenEmpty() {
        XCTAssertEqual(UPSwiper(list: [] as [String], displayMultipleItems: 3).resolvedDisplayMultipleItems, 0)
        XCTAssertEqual(UPSwiper(list: ["a.png"], displayMultipleItems: 3).resolvedDisplayMultipleItems, 3)
    }

    /// 上游 `getPoster(item)` 只在对象形态下返回 poster。
    func testSwiperPosterAndSourceAccessors() {
        let swiper = UPSwiper(list: [UPSwiperItem(source: "a.mp4", poster: "p.png")])
        XCTAssertEqual(swiper.source(of: swiper.items[0]), "a.mp4")
        XCTAssertEqual(swiper.poster(of: swiper.items[0]), "p.png")
        XCTAssertEqual(swiper.poster(of: UPSwiperItem(source: "b.mp4")), "")
    }

    /// 上游 `line` 底槽宽 `lineWidth * length`，`dot` 激活项宽 12。
    func testSwiperIndicatorGeometryPerMode() {
        let line = UPSwiperIndicator(length: 4, current: 2)
        XCTAssertEqual(line.lineTrackWidth, 88)
        XCTAssertEqual(line.lineOffset, 44)

        let dot = UPSwiperIndicator(length: 3, current: 1, indicatorMode: "dot")
        XCTAssertEqual(dot.dotWidth(at: 1), 12)
        XCTAssertEqual(dot.dotWidth(at: 0), 5)
        XCTAssertEqual(dot.dotColor(at: 1), dot.indicatorActiveColor)
        XCTAssertEqual(dot.dotColor(at: 0), dot.indicatorInactiveColor)
    }

    func testSwiperExposesItemAndIndicatorSlots() {
        let plain = UPSwiper(list: ["a.png"])
        XCTAssertFalse(plain.hasItemSlot)
        XCTAssertFalse(plain.hasIndicatorSlot)

        let slotted = plain
            .itemContent { item, index in Text("\(index)-\(item.source)") }
            .indicatorContent { Text("indicator") }
        XCTAssertTrue(slotted.hasItemSlot)
        XCTAssertTrue(slotted.hasIndicatorSlot)
    }
}
