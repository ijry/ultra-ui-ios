import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CircleProgressTests: XCTestCase {
    func testDefaultsMirrorUviewPlusCircleProgress() {
        let progress = UPCircleProgress()

        XCTAssertEqual(progress.percentage, "30")
        XCTAssertEqual(progress.customClass, "")
        XCTAssertEqual(progress.customStyle, UPStyle())
        XCTAssertEqual(progress.resolvedPercentage, 30, accuracy: 0.001)
        XCTAssertEqual(progress.progressFraction, 0.3, accuracy: 0.001)
        XCTAssertEqual(progress.resolvedDiameter, 100, accuracy: 0.001)
        XCTAssertEqual(progress.resolvedLineWidth, 5, accuracy: 0.001)
    }

    func testPercentageAcceptsStringAndNumericValues() {
        let stringValue = UPCircleProgress(percentage: "72.5")
        let integerValue = UPCircleProgress(percentage: 80)
        let floatingValue = UPCircleProgress(percentage: 45.25)

        XCTAssertEqual(stringValue.percentage, "72.5")
        XCTAssertEqual(stringValue.resolvedPercentage, 72.5, accuracy: 0.001)
        XCTAssertEqual(integerValue.percentage, "80")
        XCTAssertEqual(integerValue.resolvedPercentage, 80, accuracy: 0.001)
        XCTAssertEqual(floatingValue.percentage, "45.25")
        XCTAssertEqual(floatingValue.resolvedPercentage, 45.25, accuracy: 0.001)
    }

    func testPercentageClampsToDocumentedRangeAndInvalidInputUsesDefault() {
        XCTAssertEqual(UPCircleProgress(percentage: -1).resolvedPercentage, 0, accuracy: 0.001)
        XCTAssertEqual(UPCircleProgress(percentage: 120).resolvedPercentage, 100, accuracy: 0.001)
        XCTAssertEqual(UPCircleProgress(percentage: "invalid").resolvedPercentage, 30, accuracy: 0.001)
        XCTAssertEqual(UPCircleProgress(percentage: "").resolvedPercentage, 30, accuracy: 0.001)
    }

    func testSharedMixinStyleSurfaceIsRetained() {
        let style = UPStyle([
            "width": "120px",
            "height": "120px",
            "marginTop": "8px"
        ])
        let progress = UPCircleProgress(
            percentage: 60,
            customClass: "upload-circle",
            customStyle: style
        )

        XCTAssertEqual(progress.customClass, "upload-circle")
        XCTAssertEqual(progress.customStyle, style)
        XCTAssertEqual(progress.resolvedDiameter, 120, accuracy: 0.001)
    }

    #if os(macOS)
    func testCircleProgressRendersIntoItsNativeCanvas() {
        let renderer = ImageRenderer(content: UPCircleProgress(percentage: 65))

        XCTAssertEqual(renderer.cgImage?.width, 100)
        XCTAssertEqual(renderer.cgImage?.height, 100)
    }
    #endif
}
