import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class RadioTests: XCTestCase {
    func testRadioDefaultsAndStringNumberBooleanNameInputsMatchUviewPlus() {
        let radio = UPRadio()
        let stringName = UPRadio(name: "swift")
        let numberName = UPRadio(name: 42)
        let booleanName = UPRadio(name: true)

        XCTAssertEqual(radio.customClass, "")
        XCTAssertEqual(radio.name, "")
        XCTAssertEqual(radio.shape, "")
        XCTAssertEqual(radio.disabled, "")
        XCTAssertEqual(radio.labelDisabled, "")
        XCTAssertEqual(radio.activeColor, "")
        XCTAssertEqual(radio.inactiveColor, "")
        XCTAssertEqual(radio.iconSize, "")
        XCTAssertEqual(radio.labelSize, "")
        XCTAssertEqual(radio.label, "")
        XCTAssertEqual(radio.size, "")
        XCTAssertEqual(radio.color, "")
        XCTAssertEqual(radio.labelColor, "")
        XCTAssertEqual(radio.iconColor, "")
        XCTAssertEqual(radio.customStyle, UPStyle())
        XCTAssertEqual(radio.resolvedShape, "circle")
        XCTAssertEqual(radio.resolvedSize, 18)
        XCTAssertEqual(radio.resolvedIconSize, 12)
        XCTAssertEqual(radio.resolvedLabelFontSize, 15)

        XCTAssertEqual(stringName.name, "swift")
        XCTAssertEqual(numberName.name, 42)
        XCTAssertEqual(booleanName.name, true)
    }

    func testNamedIconAndLabelSlotsRemainOnCompatibilitySurface() {
        let radio = UPRadio(label: "Swift")
            .icon { context in
                Image(systemName: context.checked ? "record.circle.fill" : "circle")
            }
            .label { context in
                Text(context.label)
            }

        XCTAssertTrue(radio.hasIconSlot)
        XCTAssertTrue(radio.hasLabelSlot)
    }

    func testRadioGroupDefaultsBindingGapAndChangePayloadMatchUviewPlus() {
        let group = UPRadioGroup()
        let numericValue = 7
        let booleanValue = true
        let numericGroup = UPRadioGroup(value: numericValue)
        let booleanGroup = UPRadioGroup(value: booleanValue)
        _ = UPRadioGroup {
            UPRadio(name: "nested")
        }
        let selected = RadioValueBox("")
        var emitted: [UPRadioName] = []
        let boundGroup = UPRadioGroup(
            name: "language",
            modelValue: selected.binding,
            placement: "column",
            gap: 12,
            onChange: { emitted.append($0) }
        ) {
            UPRadio(name: "swift", label: "Swift")
        }

        XCTAssertEqual(group.customClass, "")
        XCTAssertEqual(group.value, "")
        XCTAssertEqual(numericGroup.value, 7)
        XCTAssertEqual(booleanGroup.value, true)
        XCTAssertFalse(group.disabled)
        XCTAssertEqual(group.shape, "circle")
        XCTAssertEqual(group.activeColor, "#2979ff")
        XCTAssertEqual(group.inactiveColor, "#c8c9cc")
        XCTAssertEqual(group.name, "")
        XCTAssertEqual(group.size, "18")
        XCTAssertEqual(group.placement, "row")
        XCTAssertEqual(group.label, "")
        XCTAssertEqual(group.labelColor, "#303133")
        XCTAssertEqual(group.labelSize, "14")
        XCTAssertFalse(group.labelDisabled)
        XCTAssertEqual(group.iconColor, "#ffffff")
        XCTAssertEqual(group.iconSize, "12")
        XCTAssertFalse(group.borderBottom)
        XCTAssertEqual(group.iconPlacement, "left")
        XCTAssertEqual(group.gap, "10px")
        XCTAssertEqual(group.customStyle, UPStyle())
        XCTAssertEqual(group.resolvedPlacement, .row)
        XCTAssertEqual(group.resolvedGap, 10)

        XCTAssertEqual(boundGroup.resolvedPlacement, .column)
        XCTAssertEqual(boundGroup.resolvedGap, 12)
        boundGroup.triggerRadioChange(name: "swift")
        XCTAssertEqual(selected.value, "swift")
        XCTAssertEqual(emitted, ["swift"])

        // u-radio only emits after changing from an unchecked state.
        boundGroup.triggerRadioChange(name: "swift")
        XCTAssertEqual(emitted, ["swift"])

        boundGroup.triggerRadioChange(name: 1)
        XCTAssertEqual(selected.value, 1)
        XCTAssertEqual(emitted, ["swift", 1])
    }

    func testRadioGroupSelectionKeepsStrictTypedNameIdentity() {
        XCTAssertEqual(
            UPRadioGroup<EmptyView>.updatedValue(current: "1", name: 1),
            1
        )
        XCTAssertNotEqual(UPRadioName("1"), UPRadioName(1))
        XCTAssertNotEqual(UPRadioName(1), UPRadioName(true))
    }
}

@MainActor
private final class RadioValueBox {
    var value: UPRadioName

    init(_ value: UPRadioName) {
        self.value = value
    }

    var binding: Binding<UPRadioName> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
