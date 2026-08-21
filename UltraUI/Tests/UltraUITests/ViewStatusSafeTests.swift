import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class ViewStatusSafeTests: XCTestCase {
    func testViewDefaultsAndClick() {
        var clicks = 0
        let view = UPView().onClick { clicks += 1 }

        XCTAssertEqual(view.backgroundColor, "")
        XCTAssertEqual(view.flexDirection, "")
        XCTAssertEqual(view.width, "")
        view.triggerClick()
        XCTAssertEqual(clicks, 1)
    }

    func testStatusBarDefaultsAndResolvedHeight() {
        var heights: [CGFloat] = []
        let bar = UPStatusBar(height: 0).onUpdateHeight { heights.append($0) }

        XCTAssertEqual(bar.bgColor, "transparent")
        XCTAssertEqual(bar.resolvedHeight(safeAreaTop: 47, statusBarHeight: nil), 47)
        bar.reportHeight(safeAreaTop: 47, statusBarHeight: 54)
        XCTAssertEqual(heights, [54])
    }

    func testSafeBottomUsesNonnegativeInset() {
        XCTAssertEqual(UPSafeBottom().resolvedHeight(safeAreaBottom: -3), 0)
        XCTAssertEqual(UPSafeBottom().resolvedHeight(safeAreaBottom: 34), 34)
    }
}
