import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CodeTests: XCTestCase {
    func testDefaultsMatchUviewPlusCode() {
        let code = UPCode()

        XCTAssertEqual(code.seconds, "60")
        XCTAssertEqual(code.startText, "获取验证码")
        XCTAssertEqual(code.changeText, "X秒重新获取")
        XCTAssertEqual(code.endText, "重新获取")
        XCTAssertFalse(code.keepRunning)
        XCTAssertEqual(code.uniqueKey, "")
        XCTAssertEqual(code.displayText, "获取验证码")
        XCTAssertTrue(code.canGetCode)
        XCTAssertFalse(code.isRunning)
        XCTAssertEqual(code.customClass, "")
        XCTAssertEqual(code.customStyle, UPStyle())
    }
}

extension CodeTests {
    func testControllerStartsChangesEverySecondEndsOnceAndRestoresSourceSeconds() {
        var starts = 0
        var ends = 0
        var changes: [String] = []
        let controller = UPCodeController(
            seconds: 3,
            startText: "获取",
            changeText: "X秒后再试",
            endText: "重新获取",
            onChange: { changes.append($0) },
            onStart: { starts += 1 },
            onEnd: { ends += 1 },
            deferredInitialActivation: false
        )
        let start = Date(timeIntervalSince1970: 1_000)

        XCTAssertEqual(changes, ["获取"])
        changes.removeAll()

        controller.start(at: start)
        XCTAssertEqual(starts, 1)
        XCTAssertFalse(controller.canGetCode)
        XCTAssertTrue(controller.isRunning)
        XCTAssertEqual(controller.secondsRemaining, 3)
        XCTAssertEqual(changes, ["3秒后再试"])

        controller.tick(at: start.addingTimeInterval(1))
        controller.tick(at: start.addingTimeInterval(2))
        XCTAssertEqual(changes, ["3秒后再试", "2秒后再试", "1秒后再试"])
        XCTAssertEqual(controller.secondsRemaining, 1)

        controller.tick(at: start.addingTimeInterval(3))
        XCTAssertEqual(changes.last, "重新获取")
        XCTAssertEqual(ends, 1)
        XCTAssertTrue(controller.canGetCode)
        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(controller.secondsRemaining, 3)

        controller.tick(at: start.addingTimeInterval(4))
        XCTAssertEqual(ends, 1)
    }
}

extension CodeTests {
    func testChangeTextReplacesOnlyTheFirstUpperOrLowercaseX() {
        let upper = UPCodeController(
            seconds: 8,
            changeText: "X秒后重试 x",
            deferredInitialActivation: true
        )
        upper.start(at: Date(timeIntervalSince1970: 1_000))
        XCTAssertEqual(upper.displayText, "8秒后重试 x")

        let lower = UPCodeController(
            seconds: 8,
            changeText: "请等待x秒 x",
            deferredInitialActivation: true
        )
        lower.start(at: Date(timeIntervalSince1970: 1_000))
        XCTAssertEqual(lower.displayText, "请等待8秒 x")

        let mixed = UPCodeController(
            seconds: 8,
            changeText: "x X",
            deferredInitialActivation: true
        )
        mixed.start(at: Date(timeIntervalSince1970: 1_000))
        XCTAssertEqual(mixed.displayText, "8 X")
    }
}

extension CodeTests {
    func testResetMakesCodeAvailableAndEmitsEndText() {
        var changes: [String] = []
        let controller = UPCodeController(
            seconds: 5,
            startText: "获取",
            changeText: "X",
            endText: "再次获取",
            onChange: { changes.append($0) },
            deferredInitialActivation: true
        )
        let start = Date(timeIntervalSince1970: 1_000)

        controller.start(at: start)
        controller.tick(at: start.addingTimeInterval(1))
        controller.reset()

        XCTAssertTrue(controller.canGetCode)
        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(controller.secondsRemaining, 5)
        XCTAssertEqual(changes.last, "再次获取")
    }
}

extension CodeTests {
    func testViewEventModifiersInstallBeforeMountedLifecycleRuns() {
        var changes: [String] = []
        var starts = 0
        var ends = 0
        let code = UPCode(
            seconds: 0,
            startText: "开始",
            changeText: "X",
            endText: "结束"
        )
        .onChange { changes.append($0) }
        .onStart { starts += 1 }
        .onEnd { ends += 1 }

        XCTAssertTrue(changes.isEmpty)
        code.controller.activateIfNeeded(at: Date(timeIntervalSince1970: 1_000))

        XCTAssertEqual(changes, ["开始"])
        XCTAssertEqual(starts, 0)
        XCTAssertEqual(ends, 0)
    }
}

extension CodeTests {
    func testKeepRunningRestoresFutureTimestampAndRefreshesStoredValue() {
        let suiteName = "UltraUI.CodeTests.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        let uniqueKey = "signup"
        let storageKey = uniqueKey + "_$uCountDownTimestamp"
        storage.set(1_004, forKey: storageKey)
        var changes: [String] = []
        var starts = 0
        let controller = UPCodeController(
            seconds: 60,
            startText: "获取",
            changeText: "X秒后",
            endText: "重试",
            keepRunning: true,
            uniqueKey: uniqueKey,
            storage: storage,
            onChange: { changes.append($0) },
            onStart: { starts += 1 },
            deferredInitialActivation: true
        )

        controller.activateIfNeeded(at: Date(timeIntervalSince1970: 1_000))

        XCTAssertEqual(controller.secondsRemaining, 4)
        XCTAssertTrue(controller.isRunning)
        XCTAssertFalse(controller.canGetCode)
        XCTAssertEqual(starts, 1)
        XCTAssertEqual(changes, ["4秒后"])
        XCTAssertEqual(storage.integer(forKey: storageKey), 1_004)

        storage.removePersistentDomain(forName: suiteName)
    }
}

extension CodeTests {
    func testRunningCodePersistsTheExpectedUnixEndTimestamp() {
        let suiteName = "UltraUI.CodeTests.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        let uniqueKey = "login"
        let controller = UPCodeController(
            seconds: 5,
            keepRunning: true,
            uniqueKey: uniqueKey,
            storage: storage,
            deferredInitialActivation: true
        )
        let start = Date(timeIntervalSince1970: 1_000)

        controller.start(at: start)
        controller.tick(at: start.addingTimeInterval(1))
        controller.persistRunningState(at: start.addingTimeInterval(1.75))

        XCTAssertEqual(
            storage.integer(forKey: uniqueKey + "_$uCountDownTimestamp"),
            1_005
        )

        storage.removePersistentDomain(forName: suiteName)
    }
}

extension CodeTests {
    func testStringAndNumberPropsAreExposedWithCustomMetadata() {
        let style = UPStyle([
            "background-color": "#f5f5f5",
            "padding": "8px"
        ])
        let code = UPCode(
            seconds: "12",
            startText: "发送验证码",
            changeText: "还剩X秒",
            endText: "再次发送",
            keepRunning: true,
            uniqueKey: "profile",
            customClass: "verification-code",
            customStyle: style
        )

        XCTAssertEqual(code.seconds, "12")
        XCTAssertEqual(code.startText, "发送验证码")
        XCTAssertEqual(code.changeText, "还剩X秒")
        XCTAssertEqual(code.endText, "再次发送")
        XCTAssertTrue(code.keepRunning)
        XCTAssertEqual(code.uniqueKey, "profile")
        XCTAssertEqual(code.customClass, "verification-code")
        XCTAssertEqual(code.customStyle, style)
        XCTAssertEqual(code.controller.secondsRemaining, 12)
    }
}

extension CodeTests {
    func testDeactivationPersistsAndMountedActivationCanResume() {
        let suiteName = "UltraUI.CodeTests.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        let uniqueKey = "checkout"
        let controller = UPCodeController(
            seconds: 5,
            keepRunning: true,
            uniqueKey: uniqueKey,
            storage: storage,
            deferredInitialActivation: true
        )
        let start = Date(timeIntervalSince1970: 1_000)

        controller.start(at: start)
        controller.tick(at: start.addingTimeInterval(1))
        controller.deactivate(at: start.addingTimeInterval(1.75))

        XCTAssertFalse(controller.isRunning)
        XCTAssertTrue(controller.canGetCode)
        XCTAssertEqual(storage.integer(forKey: uniqueKey + "_$uCountDownTimestamp"), 1_005)

        controller.activateIfNeeded(at: start.addingTimeInterval(2))
        XCTAssertTrue(controller.isRunning)
        XCTAssertEqual(controller.secondsRemaining, 3)

        storage.removePersistentDomain(forName: suiteName)
    }
}
