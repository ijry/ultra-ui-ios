import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class ListVirtualizationTests: XCTestCase {
    func testListEmitsLoadAndScrollToLower() {
        var events: [String] = []
        let list = UPList(items: ["a", "b"], loadmore: true)
            .onLoad { events.append("load") }
            .onScrolltolower { events.append("lower") }
        list.load()
        list.reachBottom()
        XCTAssertEqual(events, ["load", "lower"])
        XCTAssertEqual(list.items, ["a", "b"])
    }

    func testVirtualListCalculatesClampedVisibleRangeAndSpacer() {
        let list = UPVirtualList(items: Array(0..<100), itemHeight: 20, viewportHeight: 100, overscan: 2)
        XCTAssertEqual(list.visibleRange(offset: 200), 8...16)
        XCTAssertEqual(list.topSpacer(offset: 200), 160)
        XCTAssertEqual(list.bottomSpacer(offset: 200), 1660)
    }

    func testRefreshVirtualListTracksRefreshLifecycleAndLazyLoadThreshold() {
        var refreshed = 0
        let refresh = UPRefreshVirtualList(refreshing: false).onRefresh { refreshed += 1 }
        refresh.beginRefresh()
        XCTAssertTrue(refresh.refreshing)
        refresh.endRefresh()
        XCTAssertFalse(refresh.refreshing)
        XCTAssertEqual(refreshed, 1)

        var loaded = 0
        let lazy = UPLazyLoad(threshold: 10).onLoad { loaded += 1 }
        lazy.appear(distanceToBottom: 5)
        XCTAssertEqual(loaded, 1)
    }
}
@MainActor
final class WaterfallTests: XCTestCase {
    func testWaterfallAssignsItemsToShortestColumnDeterministically() {
        let waterfall = UPWaterfall(columnCount: 2, columnGap: 8)
        XCTAssertEqual(waterfall.columnAssignments(heights: [100, 80, 60, 40]), [0, 1, 1, 0])
        XCTAssertEqual(waterfall.columnHeights(heights: [100, 80, 60, 40]), [148, 148])
    }
}

@MainActor
final class IndexListTests: XCTestCase {
    func testIndexListSelectsAnchorAndEmitsActiveIndex() {
        var selected = ""
        let list = UPIndexList(anchors: ["A", "B", "C"]).onChange { selected = $0 }
        list.select("B")
        XCTAssertEqual(list.activeIndex, "B")
        XCTAssertEqual(selected, "B")
        XCTAssertEqual(list.index(of: "missing"), -1)
        XCTAssertEqual(UPIndexAnchor(index: "A").displayIndex, "A")
    }
}
