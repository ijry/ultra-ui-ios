import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class TitleTests: XCTestCase {
    func testDefaultPrefixMatchesTheUviewPlusTemplateAndFinalCSSValues() {
        let title = UPTitle { Text("订单信息") }

        XCTAssertFalse(title.hasCustomPrefix)
        XCTAssertEqual(title.defaultPrefixWidth, 4)
        XCTAssertEqual(title.defaultPrefixHeight, 18)
        XCTAssertEqual(title.defaultPrefixCornerRadius, 2)
        // The upstream stylesheet declares margin-right twice; the final
        // 10px declaration wins in CSS cascade order.
        XCTAssertEqual(title.defaultPrefixTrailingMargin, 10)
    }

    func testNamedPrefixSlotReplacesTheBuiltInPrefix() {
        let title = UPTitle(prefix: { Image(systemName: "star.fill") }) {
            Text("收藏")
        }

        XCTAssertTrue(title.hasCustomPrefix)
    }

    func testDefaultSlotAndEmptyInitializerAreAvailableWithoutSyntheticPropsOrEvents() {
        let empty = UPTitle()
        let slotted = UPTitle { Text("标题") }

        XCTAssertFalse(empty.hasCustomPrefix)
        XCTAssertFalse(slotted.hasCustomPrefix)
    }
}
