import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class PrimitiveBatchCompatibilityTests: XCTestCase {
    func testComponentsExposeDefaultAndSlotConstructors() {
        _ = UPView { Text("view") }
        _ = UPStatusBar { Text("status") }
        _ = UPSafeBottom()
        _ = UPSection { Text("section") }
        _ = UPToolbar { Text("right") }
        _ = UPSlider()
        _ = UPSubsection(list: ["one", "two"])
        _ = UPPagination(total: 20)
        XCTAssertTrue(true)
    }
}
