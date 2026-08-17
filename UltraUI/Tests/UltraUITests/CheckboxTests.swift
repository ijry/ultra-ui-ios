import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CheckboxTests: XCTestCase {
    func testCheckboxDefaultsAndStringNumberBooleanNameInputsMatchUviewPlus() {
        let checkbox = UPCheckbox()
        let stringName = UPCheckbox(name: "terms")
        let numberName = UPCheckbox(name: 42)
        let booleanName = UPCheckbox(name: true)

        XCTAssertEqual(checkbox.customClass, "")
        XCTAssertEqual(checkbox.name, "")
        XCTAssertEqual(checkbox.shape, "")
        XCTAssertEqual(checkbox.size, "")
        XCTAssertFalse(checkbox.checked)
        XCTAssertEqual(checkbox.disabled, "")
        XCTAssertEqual(checkbox.activeColor, "")
        XCTAssertEqual(checkbox.inactiveColor, "")
        XCTAssertEqual(checkbox.iconSize, "")
        XCTAssertEqual(checkbox.iconColor, "")
        XCTAssertEqual(checkbox.label, "")
        XCTAssertEqual(checkbox.labelSize, "")
        XCTAssertEqual(checkbox.labelColor, "")
        XCTAssertEqual(checkbox.labelDisabled, "")
        XCTAssertFalse(checkbox.usedAlone)
        XCTAssertEqual(checkbox.customStyle, UPStyle())
        XCTAssertEqual(checkbox.resolvedShape, "circle")
        XCTAssertEqual(checkbox.resolvedSize, 18)
        XCTAssertEqual(checkbox.resolvedIconSize, 12)
        XCTAssertEqual(checkbox.resolvedLabelFontSize, 15)

        XCTAssertEqual(stringName.name, "terms")
        XCTAssertEqual(numberName.name, 42)
        XCTAssertEqual(booleanName.name, true)
    }

    func testStandaloneCheckboxBindingClickRulesAndChangePayload() {
        let checked = CheckboxBoolBox(false)
        var events: [(Bool, UPCheckboxChange)] = []
        let checkbox = UPCheckbox(
            name: "terms",
            checked: checked.binding,
            labelDisabled: true,
            usedAlone: true,
            onChange: { isChecked, detail in
                events.append((isChecked, detail))
            }
        )

        checkbox.triggerLabelTap()
        XCTAssertFalse(checked.value)
        XCTAssertTrue(events.isEmpty)

        checkbox.triggerIconTap()
        XCTAssertTrue(checked.value)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.0, true)
        XCTAssertEqual(events.first?.1, UPCheckboxChange(name: "terms"))

        let disabled = UPCheckbox(
            name: "disabled",
            checked: checked.binding,
            disabled: true,
            usedAlone: true,
            onChange: { isChecked, detail in
                events.append((isChecked, detail))
            }
        )
        disabled.triggerIconTap()
        XCTAssertTrue(checked.value)
        XCTAssertEqual(events.count, 1)
    }

    func testNamedIconAndLabelSlotsRemainOnCompatibilitySurface() {
        let checkbox = UPCheckbox(label: "Accept", usedAlone: true)
            .icon { context in
                Image(systemName: context.checked ? "checkmark" : "square")
            }
            .label { context in
                Text(context.label)
            }

        XCTAssertTrue(checkbox.hasIconSlot)
        XCTAssertTrue(checkbox.hasLabelSlot)
    }

    func testGroupDefaultsAndBindingChangePayloadMatchUviewPlus() {
        let group = UPCheckboxGroup()
        _ = UPCheckboxGroup {
            UPCheckbox(name: "nested")
        }
        let selected = CheckboxValuesBox([])
        var emittedValues: [UPCheckboxName] = []
        var emittedDetail: UPCheckboxGroupChange?
        let boundGroup = UPCheckboxGroup(
            name: "interests",
            modelValue: selected.binding,
            placement: "column",
            onChange: { values, detail in
                emittedValues = values
                emittedDetail = detail
            }
        ) {
            EmptyView()
        }

        XCTAssertEqual(group.customClass, "")
        XCTAssertEqual(group.name, "")
        XCTAssertEqual(group.value, [])
        XCTAssertEqual(group.shape, "square")
        XCTAssertFalse(group.disabled)
        XCTAssertEqual(group.activeColor, "#2979ff")
        XCTAssertEqual(group.inactiveColor, "#c8c9cc")
        XCTAssertEqual(group.size, "18")
        XCTAssertEqual(group.placement, "row")
        XCTAssertEqual(group.labelSize, "14")
        XCTAssertEqual(group.labelColor, "#303133")
        XCTAssertFalse(group.labelDisabled)
        XCTAssertEqual(group.iconColor, "#ffffff")
        XCTAssertEqual(group.iconSize, "12")
        XCTAssertEqual(group.iconPlacement, "left")
        XCTAssertFalse(group.borderBottom)
        XCTAssertEqual(group.customStyle, UPStyle())
        XCTAssertEqual(group.resolvedPlacement, .row)

        boundGroup.triggerCheckboxChange(name: "swift", isChecked: true)
        XCTAssertEqual(selected.value, ["swift"])
        XCTAssertEqual(emittedValues, ["swift"])
        XCTAssertEqual(emittedDetail, UPCheckboxGroupChange(name: "swift", isChecked: true))

        boundGroup.triggerCheckboxChange(name: "swift", isChecked: false)
        XCTAssertTrue(selected.value.isEmpty)
        XCTAssertEqual(emittedValues, [])
        XCTAssertEqual(emittedDetail, UPCheckboxGroupChange(name: "swift", isChecked: false))
    }

    func testGroupSelectionPreservesStrictTypedNameIdentity() {
        XCTAssertEqual(
            UPCheckboxGroup<EmptyView>.updatedValues([], name: "1", isChecked: true),
            ["1"]
        )
        XCTAssertEqual(
            UPCheckboxGroup<EmptyView>.updatedValues(["1", 1, true], name: 1, isChecked: false),
            ["1", true]
        )
    }
}

@MainActor
private final class CheckboxBoolBox {
    var value: Bool

    init(_ value: Bool) {
        self.value = value
    }

    var binding: Binding<Bool> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}

@MainActor
private final class CheckboxValuesBox {
    var value: [UPCheckboxName]

    init(_ value: [UPCheckboxName]) {
        self.value = value
    }

    var binding: Binding<[UPCheckboxName]> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
