import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class SwitchTests: XCTestCase {
    func testDefaultsAndResolvedGeometryMatchUviewPlus() {
        let toggle = UPSwitch()

        XCTAssertEqual(toggle.customClass, "")
        XCTAssertFalse(toggle.loading)
        XCTAssertFalse(toggle.disabled)
        XCTAssertEqual(toggle.size, "25")
        XCTAssertEqual(toggle.activeColor, "#2979ff")
        XCTAssertEqual(toggle.inactiveColor, "#ffffff")
        XCTAssertEqual(toggle.dotActiveColor, "#ffffff")
        XCTAssertEqual(toggle.dotInactiveColor, "#ffffff")
        XCTAssertEqual(toggle.value, false)
        XCTAssertEqual(toggle.activeValue, true)
        XCTAssertEqual(toggle.inactiveValue, false)
        XCTAssertFalse(toggle.asyncChange)
        XCTAssertEqual(toggle.space, "0")
        XCTAssertEqual(toggle.customStyle, UPStyle())
        XCTAssertFalse(toggle.isActive)
        XCTAssertEqual(toggle.resolvedSize, 25)
        XCTAssertEqual(toggle.resolvedTrackWidth, 52)
        XCTAssertEqual(toggle.resolvedTrackHeight, 27)
        XCTAssertEqual(toggle.resolvedNodeSize, 25)
    }

    func testBindingSupportsBooleanStringAndNumberValuesWithStrictIdentity() {
        let boolBox = SwitchValueBox(false)
        let stringBox = SwitchValueBox("off")
        let numberBox = SwitchValueBox(0)
        var emitted: [UPSwitchValue] = []

        let booleanSwitch = UPSwitch(modelValue: boolBox.binding) { emitted.append($0) }
        booleanSwitch.triggerTap()
        XCTAssertTrue(boolBox.value)
        XCTAssertEqual(emitted, [true])

        let stringSwitch = UPSwitch(
            modelValue: stringBox.binding,
            activeValue: "on",
            inactiveValue: "off",
            onChange: { emitted.append($0) }
        )
        stringSwitch.triggerTap()
        XCTAssertEqual(stringBox.value, "on")
        XCTAssertEqual(emitted, [true, "on"])

        let numberSwitch = UPSwitch(
            modelValue: numberBox.binding,
            activeValue: 1,
            inactiveValue: 0,
            onChange: { emitted.append($0) }
        )
        numberSwitch.triggerTap()
        XCTAssertEqual(numberBox.value, 1)
        XCTAssertEqual(emitted, [true, "on", 1])

        XCTAssertFalse(UPSwitch.isActive(value: "1", activeValue: 1))
        XCTAssertFalse(UPSwitch.isActive(value: 1, activeValue: true))
    }

    func testAsyncChangeEmitsCandidateWithoutMutatingBoundValue() {
        let box = SwitchValueBox("off")
        var emitted: [UPSwitchValue] = []
        let toggle = UPSwitch(
            modelValue: box.binding,
            activeValue: "on",
            inactiveValue: "off",
            asyncChange: true,
            onChange: { emitted.append($0) }
        )

        toggle.triggerTap()

        XCTAssertEqual(box.value, "off")
        XCTAssertEqual(emitted, ["on"])
    }

    func testFluentOnChangeModifierUsesTheUviewPlusChangePayload() {
        let box = SwitchValueBox(false)
        var emitted: [UPSwitchValue] = []
        let toggle = UPSwitch(modelValue: box.binding)
            .onChange { emitted.append($0) }

        toggle.triggerTap()

        XCTAssertTrue(box.value)
        XCTAssertEqual(emitted, [true])
    }

    func testLoadingAndDisabledSuppressChangesAndCustomSizingHonorsSpace() {
        let box = SwitchValueBox(false)
        var emitted: [UPSwitchValue] = []
        let loading = UPSwitch(loading: true, modelValue: box.binding) { emitted.append($0) }
        let disabled = UPSwitch(disabled: true, modelValue: box.binding) { emitted.append($0) }
        let custom = UPSwitch(
            size: "30px",
            activeColor: "#00AA00",
            inactiveColor: "#EEEEEE",
            dotActiveColor: "#111111",
            dotInactiveColor: "#222222",
            value: "off",
            activeValue: "on",
            inactiveValue: "off",
            space: 3
        )

        loading.triggerTap()
        disabled.triggerTap()

        XCTAssertFalse(box.value)
        XCTAssertTrue(emitted.isEmpty)
        XCTAssertEqual(custom.resolvedSize, 30)
        XCTAssertEqual(custom.resolvedTrackWidth, 62)
        XCTAssertEqual(custom.resolvedTrackHeight, 32)
        XCTAssertEqual(custom.resolvedNodeSize, 27)
        XCTAssertEqual(custom.resolvedSpace, 3)
        XCTAssertFalse(custom.isActive)
    }
}

@MainActor
private final class SwitchValueBox<Value> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }

    var binding: Binding<Value> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
