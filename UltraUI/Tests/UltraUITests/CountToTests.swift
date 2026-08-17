import XCTest
@testable import UltraUI

@MainActor
final class CountToTests: XCTestCase {
    func testDefaultsMatchUviewPlusCountTo() {
        let countTo = UPCountTo()

        XCTAssertEqual(countTo.startVal, "0")
        XCTAssertEqual(countTo.endVal, "0")
        XCTAssertEqual(countTo.duration, "2000")
        XCTAssertTrue(countTo.autoplay)
        XCTAssertEqual(countTo.decimals, "0")
        XCTAssertTrue(countTo.useEasing)
        XCTAssertEqual(countTo.decimal, ".")
        XCTAssertEqual(countTo.color, "#606266")
        XCTAssertEqual(countTo.fontSize, "22")
        XCTAssertFalse(countTo.bold)
        XCTAssertEqual(countTo.separator, "")
        XCTAssertEqual(countTo.displayValue, "0")
    }
}

extension CountToTests {
    func testStringAndNumberPropsRetainTheUviewPlusSurfaceAndFormatInitialValue() {
        let style = UPStyle(["opacity": "0.8"])
        let countTo = UPCountTo(
            startVal: Int8(-12),
            endVal: "12345.678",
            duration: UInt16(750),
            autoplay: false,
            decimals: UInt8(2),
            useEasing: false,
            decimal: ",",
            color: "success",
            fontSize: "18px",
            bold: true,
            separator: " ",
            customClass: "sales-total",
            customStyle: style
        )

        XCTAssertEqual(countTo.startVal, "-12")
        XCTAssertEqual(countTo.endVal, "12345.678")
        XCTAssertEqual(countTo.duration, "750")
        XCTAssertEqual(countTo.decimals, "2")
        XCTAssertEqual(countTo.decimal, ",")
        XCTAssertEqual(countTo.displayValue, "-12,00")
        XCTAssertEqual(countTo.resolvedFontSize, 18)
        XCTAssertEqual(countTo.color, "success")
        XCTAssertTrue(countTo.bold)
        XCTAssertEqual(countTo.separator, " ")
        XCTAssertEqual(countTo.customClass, "sales-total")
        XCTAssertEqual(countTo.customStyle, style)
    }
}

extension CountToTests {
    func testFormatterMatchesDecimalAndThousandsSeparatorRules() {
        XCTAssertEqual(
            UPCountTo.formattedValue(12_345.678, decimals: 2, decimal: ",", separator: " "),
            "12 345,68"
        )
        XCTAssertEqual(
            UPCountTo.formattedValue(-12_345.6, decimals: 1, decimal: ".", separator: ","),
            "-12,345.6"
        )
        XCTAssertEqual(
            UPCountTo.formattedValue(12_345, decimals: 0, decimal: ".", separator: "0"),
            "12345"
        )
    }
}

extension CountToTests {
    func testControllerAnimatesLinearlyAndDeliversEndOnce() {
        var endCount = 0
        let controller = UPCountToController(
            startVal: 10,
            endVal: 20,
            duration: 1_000,
            autoplay: false,
            decimals: 1,
            useEasing: false,
            decimal: ".",
            separator: ",",
            onEnd: { endCount += 1 }
        )
        let start = Date(timeIntervalSince1970: 1_000)

        XCTAssertEqual(controller.value, 10)
        XCTAssertEqual(controller.displayValue, "10.0")
        XCTAssertFalse(controller.isRunning)

        controller.start(at: start)
        controller.tick(at: start.addingTimeInterval(0.25))
        XCTAssertEqual(controller.value, 12.5, accuracy: 0.0001)
        XCTAssertEqual(controller.displayValue, "12.5")
        XCTAssertTrue(controller.isRunning)

        controller.tick(at: start.addingTimeInterval(1.1))
        XCTAssertEqual(controller.value, 20)
        XCTAssertEqual(controller.displayValue, "20.0")
        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(endCount, 1)

        controller.tick(at: start.addingTimeInterval(2))
        XCTAssertEqual(endCount, 1)
    }
}

extension CountToTests {
    func testStopResumeRestartAndResetMirrorUpstreamInstanceMethods() {
        let controller = UPCountToController(
            startVal: 0,
            endVal: 100,
            duration: 1_000,
            autoplay: false,
            useEasing: false
        )
        let start = Date(timeIntervalSince1970: 1_000)

        controller.start(at: start)
        controller.tick(at: start.addingTimeInterval(0.4))
        XCTAssertEqual(controller.value, 40, accuracy: 0.0001)

        controller.stop()
        controller.tick(at: start.addingTimeInterval(0.9))
        XCTAssertEqual(controller.value, 40, accuracy: 0.0001)
        XCTAssertFalse(controller.isRunning)

        controller.resume(at: start.addingTimeInterval(2))
        controller.tick(at: start.addingTimeInterval(2.3))
        XCTAssertEqual(controller.value, 70, accuracy: 0.0001)

        controller.reStart(at: start.addingTimeInterval(2.3))
        XCTAssertTrue(controller.isPaused)
        XCTAssertFalse(controller.isRunning)
        controller.reStart(at: start.addingTimeInterval(3))
        XCTAssertFalse(controller.isPaused)
        XCTAssertTrue(controller.isRunning)
        controller.tick(at: start.addingTimeInterval(3.15))
        XCTAssertEqual(controller.value, 85, accuracy: 0.0001)

        controller.reset()
        XCTAssertEqual(controller.value, 0)
        XCTAssertEqual(controller.displayValue, "0")
        XCTAssertFalse(controller.isRunning)
    }
}

extension CountToTests {
    func testEasingAndViewEndModifierUseTheDeferredMountedLifecycle() {
        let eased = UPCountToController(
            startVal: 0,
            endVal: 100,
            duration: 1_000,
            autoplay: false,
            useEasing: true
        )
        let start = Date(timeIntervalSince1970: 1_000)
        eased.start(at: start)
        eased.tick(at: start.addingTimeInterval(0.5))
        XCTAssertGreaterThan(eased.value, 50)
        XCTAssertLessThan(eased.value, 100)

        var endCount = 0
        let countTo = UPCountTo(
            startVal: 2,
            endVal: 9,
            duration: 0,
            autoplay: true
        )
        .onEnd { endCount += 1 }

        XCTAssertEqual(endCount, 0)
        countTo.controller.activateIfNeeded()
        XCTAssertEqual(countTo.displayValue, "9")
        XCTAssertEqual(endCount, 1)
    }
}
