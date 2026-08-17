import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
private final class CountDownSlotCapture {
    var timeData: UPCountDownTimeData?
}

@MainActor
private struct CountDownSlotProbe: View {
    init(timeData: UPCountDownTimeData, capture: CountDownSlotCapture) {
        capture.timeData = timeData
    }

    var body: some View {
        EmptyView()
    }
}

@MainActor
final class CountDownTests: XCTestCase {
    func testDefaultsMatchUviewPlusCountDown() {
        let countDown = UPCountDown()

        XCTAssertEqual(countDown.time, "0")
        XCTAssertEqual(countDown.format, "HH:mm:ss")
        XCTAssertTrue(countDown.autoStart)
        XCTAssertFalse(countDown.millisecond)
        XCTAssertEqual(countDown.customClass, "")
        XCTAssertEqual(countDown.customStyle, UPStyle())
    }
}

extension CountDownTests {
    func testTimeDataSplitsRemainingMillisecondsIntoUviewPlusUnits() {
        let timeData = UPCountDownTimeData(milliseconds: 93_784_005)

        XCTAssertEqual(timeData.days, 1)
        XCTAssertEqual(timeData.hours, 2)
        XCTAssertEqual(timeData.minutes, 3)
        XCTAssertEqual(timeData.seconds, 4)
        XCTAssertEqual(timeData.milliseconds, 5)
    }
}

extension CountDownTests {
    func testFormatterRollsOmittedDaysIntoHoursLikeUviewPlus() {
        let timeData = UPCountDownTimeData(milliseconds: 93_784_005)

        XCTAssertEqual(
            UPCountDown.formattedTime(timeData, format: "HH:mm:ss"),
            "26:03:04"
        )
    }
}

extension CountDownTests {
    func testControllerEmitsTimeDataAndOneFinishWhenCountdownExpires() {
        var changes: [UPCountDownTimeData] = []
        var finishCount = 0
        let controller = UPCountDownController(
            time: 2_000,
            format: "ss.SSS",
            autoStart: false,
            millisecond: true,
            onChange: { changes.append($0) },
            onFinish: { finishCount += 1 }
        )
        let start = Date(timeIntervalSince1970: 1_000)

        XCTAssertEqual(controller.timeData, UPCountDownTimeData(days: 0, hours: 0, minutes: 0, seconds: 2, milliseconds: 0))
        XCTAssertEqual(controller.formattedTime, "02.000")
        XCTAssertFalse(controller.isRunning)

        controller.start(at: start)
        XCTAssertTrue(controller.isRunning)

        controller.tick(at: start.addingTimeInterval(1.25))
        XCTAssertEqual(controller.timeData, UPCountDownTimeData(days: 0, hours: 0, minutes: 0, seconds: 0, milliseconds: 750))
        XCTAssertEqual(controller.formattedTime, "00.750")
        XCTAssertEqual(changes.last, UPCountDownTimeData(days: 0, hours: 0, minutes: 0, seconds: 0, milliseconds: 750))

        controller.tick(at: start.addingTimeInterval(2.1))
        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(controller.remainingTime, 0)
        XCTAssertEqual(finishCount, 1)

        controller.tick(at: start.addingTimeInterval(3))
        XCTAssertEqual(finishCount, 1)
    }
}

extension CountDownTests {
    func testViewAcceptsControllerAndDefaultSlotTimeData() {
        let controller = UPCountDownController(
            time: 90_000,
            format: "mm:ss",
            autoStart: false
        )
        let slotCapture = CountDownSlotCapture()
        let countDown = UPCountDown(
            time: 90_000,
            format: "mm:ss",
            autoStart: false,
            controller: controller
        ) { timeData in
            CountDownSlotProbe(timeData: timeData, capture: slotCapture)
        }

        XCTAssertTrue(countDown.controller === controller)
        XCTAssertEqual(countDown.displayText, "01:30")
        _ = countDown.body
        XCTAssertEqual(
            slotCapture.timeData,
            UPCountDownTimeData(days: 0, hours: 0, minutes: 1, seconds: 30, milliseconds: 0)
        )
    }
}

extension CountDownTests {
    func testViewEventModifiersForwardCountdownEventsToItsController() {
        var changes: [UPCountDownTimeData] = []
        var finishCount = 0
        let countDown = UPCountDown(
            time: 1_000,
            format: "ss",
            autoStart: false
        )
        .onChange { changes.append($0) }
        .onFinish { finishCount += 1 }
        let start = Date(timeIntervalSince1970: 1_000)

        countDown.controller.start(at: start)
        countDown.controller.tick(at: start.addingTimeInterval(1.1))

        XCTAssertEqual(changes.last, .zero)
        XCTAssertEqual(finishCount, 1)
    }
}

extension CountDownTests {
    func testPropConfigurationResetsTimeAndReformatsTheController() {
        let controller = UPCountDownController(
            time: 1_000,
            format: "ss",
            autoStart: false
        )
        let start = Date(timeIntervalSince1970: 1_000)
        controller.start(at: start)
        controller.tick(at: start.addingTimeInterval(0.25))

        controller.configure(
            time: "90000",
            format: "mm:ss",
            autoStart: false,
            millisecond: false
        )

        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(controller.remainingTime, 90_000)
        XCTAssertEqual(
            controller.timeData,
            UPCountDownTimeData(days: 0, hours: 0, minutes: 1, seconds: 30, milliseconds: 0)
        )
        XCTAssertEqual(controller.formattedTime, "01:30")
    }
}

extension CountDownTests {
    func testWholeSecondModeOnlyEmitsChangeWhenTheSecondChanges() {
        var changes: [UPCountDownTimeData] = []
        let controller = UPCountDownController(
            time: 2_500,
            autoStart: false,
            millisecond: false,
            onChange: { changes.append($0) }
        )
        let start = Date(timeIntervalSince1970: 1_000)
        changes.removeAll()

        controller.start(at: start)
        controller.tick(at: start.addingTimeInterval(0.25))
        XCTAssertTrue(changes.isEmpty)

        controller.tick(at: start.addingTimeInterval(1.25))
        XCTAssertEqual(
            changes,
            [UPCountDownTimeData(days: 0, hours: 0, minutes: 0, seconds: 1, milliseconds: 250)]
        )
    }
}

extension CountDownTests {
    func testViewDeliversInitialZeroEventsAfterModifiersAreInstalled() {
        var changes: [UPCountDownTimeData] = []
        var finishCount = 0
        let countDown = UPCountDown(time: 0)
            .onChange { changes.append($0) }
            .onFinish { finishCount += 1 }

        countDown.controller.activateIfNeeded()

        XCTAssertEqual(changes, [.zero])
        XCTAssertEqual(finishCount, 1)
    }
}

extension CountDownTests {
    func testFormatterPadsDaysAndMillisecondsWhenTheirTokensArePresent() {
        let timeData = UPCountDownTimeData(milliseconds: 93_784_005)

        XCTAssertEqual(
            UPCountDown.formattedTime(timeData, format: "DD HH:mm:ss.SSS"),
            "01 02:03:04.005"
        )
    }
}

extension CountDownTests {
    func testPauseFreezesTheCurrentDurationAndResetRestoresTheSourceTime() {
        let controller = UPCountDownController(
            time: 2_500,
            autoStart: false,
            millisecond: true
        )
        let start = Date(timeIntervalSince1970: 1_000)
        controller.start(at: start)
        controller.tick(at: start.addingTimeInterval(0.25))
        controller.pause()

        controller.tick(at: start.addingTimeInterval(5))
        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(controller.remainingTime, 2_250)

        controller.reset(at: start.addingTimeInterval(6))
        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(controller.remainingTime, 2_500)
        XCTAssertEqual(
            controller.timeData,
            UPCountDownTimeData(days: 0, hours: 0, minutes: 0, seconds: 2, milliseconds: 500)
        )
    }
}

extension CountDownTests {
    func testOversizedFiniteTimeClampsWithoutIntegerOverflow() {
        let maximumRepresentableMilliseconds = Double(Int.max).nextDown
        let timeData = UPCountDownTimeData(milliseconds: .greatestFiniteMagnitude)
        // Use the same string prop path exposed to declarative callers. Passing
        // the enormous value as a `Double` would first traverse the shared
        // checkbox unit converter, whose integer-only formatting intentionally
        // cannot represent this value.
        let controller = UPCountDownController(
            time: String(Double.greatestFiniteMagnitude),
            autoStart: false
        )

        XCTAssertGreaterThan(timeData.days, 0)
        XCTAssertTrue((0..<24).contains(timeData.hours))
        XCTAssertTrue((0..<60).contains(timeData.minutes))
        XCTAssertTrue((0..<60).contains(timeData.seconds))
        XCTAssertTrue((0..<1_000).contains(timeData.milliseconds))
        XCTAssertEqual(controller.remainingTime, maximumRepresentableMilliseconds)
    }
}
