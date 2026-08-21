import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class GestureRefreshTests: XCTestCase {
    func testDragsortMovesItemsAndEmitsOrder() {
        var emitted: [String] = []
        let sort = UPDragsort(items: ["A", "B", "C"]).onChange { emitted = $0 }
        XCTAssertEqual(sort.move(from: 0, to: 2), ["B", "C", "A"])
        XCTAssertEqual(sort.items, ["A", "B", "C"])
        XCTAssertEqual(emitted, ["B", "C", "A"])
    }

    func testPullRefreshTracksThresholdAndLifecycle() {
        var calls = 0
        let refresh = UPPullRefresh(refreshing: false, threshold: 50).onRefresh { calls += 1 }
        XCTAssertFalse(refresh.pull(distance: 20))
        XCTAssertTrue(refresh.pull(distance: 60))
        XCTAssertTrue(refresh.refreshing)
        refresh.endRefresh()
        XCTAssertFalse(refresh.refreshing)
        XCTAssertEqual(calls, 1)
    }
}

@MainActor
final class SwipeActionTests: XCTestCase {
    func testSwipeActionItemOpensAndInvokesAction() {
        var selected = ""
        let item = UPSwipeActionItem(id: "row", actions: [UPSwipeAction(id: "delete", title: "Delete")])
            .onAction { selected = $0.id }
        item.open()
        XCTAssertTrue(item.opened)
        item.trigger("delete")
        XCTAssertEqual(selected, "delete")
        item.close()
        XCTAssertFalse(item.opened)
    }

    func testSwipeActionTracksSingleOpenItem() {
        let action = UPSwipeAction(id: "archive", title: "Archive")
        let group = UPSwipeActionGroup().register("first").open("first")
        XCTAssertEqual(group.openedID, "first")
        XCTAssertEqual(action.title, "Archive")
        group.close()
        XCTAssertNil(group.openedID)
    }
}

@MainActor
final class ReadMoreTests: XCTestCase {
    func testReadMoreTogglesAndEmitsExpandedState() {
        var emitted = false
        let readMore = UPReadMore(lines: 2, expanded: false).onChange { emitted = $0 }
        XCTAssertFalse(readMore.isExpanded)
        readMore.toggle()
        XCTAssertTrue(readMore.isExpanded)
        XCTAssertTrue(emitted)
        readMore.collapse()
        XCTAssertFalse(readMore.isExpanded)
    }
}
