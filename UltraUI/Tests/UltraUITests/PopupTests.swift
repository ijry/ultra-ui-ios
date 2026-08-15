import XCTest
import SwiftUI
@testable import UltraUI

final class PopupTests: XCTestCase {
    func testOverlayDefaults() {
        let o = UPOverlay()
        XCTAssertEqual(o.opacity, 0.5)
        XCTAssertEqual(o.duration, 300)
    }
}
