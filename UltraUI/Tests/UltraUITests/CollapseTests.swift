import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CollapseTests: XCTestCase {
    func testDefaultsMirrorUviewPlusCollapseAndCollapseItem() {
        let collapse = UPCollapse()
        XCTAssertEqual(collapse.value, .none)
        XCTAssertFalse(collapse.accordion)
        XCTAssertTrue(collapse.border)

        let item = UPCollapseItem()
        XCTAssertEqual(item.title, "")
        XCTAssertEqual(item.value, "")
        XCTAssertEqual(item.label, "")
        XCTAssertFalse(item.disabled)
        XCTAssertTrue(item.isLink)
        XCTAssertTrue(item.clickable)
        XCTAssertTrue(item.border)
        XCTAssertEqual(item.align, "left")
        XCTAssertNil(item.name)
        XCTAssertEqual(item.icon, "")
        XCTAssertEqual(item.duration, 300)
        XCTAssertTrue(item.showRight)
        XCTAssertEqual(item.titleStyle, UPStyle())
        XCTAssertEqual(item.iconStyle, UPStyle())
        XCTAssertEqual(item.rightIconStyle, UPStyle())
        XCTAssertEqual(item.cellCustomClass, "")
        XCTAssertEqual(item.cellCustomStyle, UPStyle())
    }

    func testValueAcceptsUpstreamScalarAndArrayForms() {
        let scalar = UPCollapse(value: "docs", accordion: true)
        XCTAssertEqual(scalar.value, .single("docs"))

        let names: [UPCollapseName] = ["docs", 2]
        let multiple = UPCollapse(value: names)
        XCTAssertEqual(multiple.value, .multiple(names))

        let empty = UPCollapse(value: UPCollapseValue.none)
        XCTAssertEqual(empty.value, .none)
    }

    func testToggleStateMirrorsAccordionAndDisabledRules() {
        let initial: [UPCollapseName] = ["one", "two"]

        XCTAssertEqual(
            UPCollapseState.nextNames(
                current: initial,
                target: "three",
                accordion: false
            ),
            ["one", "two", "three"]
        )
        XCTAssertEqual(
            UPCollapseState.nextNames(
                current: initial,
                target: "one",
                accordion: false
            ),
            ["two"]
        )
        XCTAssertEqual(
            UPCollapseState.nextNames(
                current: initial,
                target: "three",
                accordion: true
            ),
            ["three"]
        )
        XCTAssertEqual(
            UPCollapseState.nextNames(
                current: ["three"],
                target: "three",
                accordion: true
            ),
            []
        )
        XCTAssertEqual(
            UPCollapseState.nextNames(
                current: initial,
                target: "three",
                accordion: false,
                disabled: true
            ),
            initial
        )
    }

    func testChangePayloadContainsEveryItemStatusAndTypedNames() {
        let itemNames: [UPCollapseName] = ["one", 2, "three"]
        let payload = UPCollapseState.changePayload(
            activeNames: ["one", "three"],
            itemNames: itemNames
        )

        XCTAssertEqual(
            payload,
            [
                UPCollapseChange(name: "one", status: .open),
                UPCollapseChange(name: 2, status: .close),
                UPCollapseChange(name: "three", status: .open)
            ]
        )
    }

    func testItemPropsNormalizeNumbersStylesAlignmentAndNamedSlots() {
        let style = UPStyle(["color": "#2979ff"])
        let item = UPCollapseItem(
            title: 42,
            value: 7,
            label: 3.5,
            align: "center",
            name: 9,
            duration: 450,
            titleStyle: style,
            iconStyle: style,
            rightIconStyle: style,
            cellCustomClass: "custom-cell",
            cellCustomStyle: style
        ) {
            Text("Body")
        }
        .title { Text("Title") }
        .icon { Image(systemName: "star.fill") }
        .value { Text("Value") }
        .rightIcon { Image(systemName: "chevron.right") }

        XCTAssertEqual(item.title, "42")
        XCTAssertEqual(item.value, "7")
        XCTAssertEqual(item.label, "3.5")
        XCTAssertEqual(item.name, 9)
        XCTAssertEqual(item.align, "center")
        XCTAssertEqual(item.resolvedAlignment, UPCollapseAlignment.center)
        XCTAssertEqual(item.duration, 450)
        XCTAssertEqual(item.resolvedDuration, 0.45, accuracy: 0.001)
        XCTAssertEqual(item.titleStyle, style)
        XCTAssertEqual(item.iconStyle, style)
        XCTAssertEqual(item.rightIconStyle, style)
        XCTAssertEqual(item.cellCustomClass, "custom-cell")
        XCTAssertEqual(item.cellCustomStyle, style)
        XCTAssertTrue(item.hasContentSlot)
        XCTAssertTrue(item.hasTitleSlot)
        XCTAssertTrue(item.hasIconSlot)
        XCTAssertTrue(item.hasValueSlot)
        XCTAssertTrue(item.hasRightIconSlot)
    }

    func testBindingInitializerPreservesModelValueOnNativeSurface() {
        var model: [UPCollapseName] = ["initial"]
        let binding = Binding<[UPCollapseName]>(
            get: { model },
            set: { model = $0 }
        )

        let collapse = UPCollapse(modelValue: binding)
        XCTAssertEqual(collapse.value, .multiple(["initial"]))
    }

    #if os(macOS)
    func testCollapseCanRenderIntoAFixedNativeCanvas() {
        let renderer = ImageRenderer(
            content: UPCollapse(value: ["docs"]) {
                UPCollapseItem(title: "Docs", name: "docs") {
                    Text("Content")
                        .frame(height: 40)
                }
                UPCollapseItem(title: "Other", name: "other") {
                    Text("Other content")
                }
            }
            .frame(width: 260, height: 140)
        )

        XCTAssertEqual(renderer.cgImage?.width, 260)
        XCTAssertEqual(renderer.cgImage?.height, 140)
    }
    #endif
}
