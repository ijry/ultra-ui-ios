import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class TagTests: XCTestCase {
    func testDefaultsMatchUviewPlusTag() {
        let tag = UPTag()

        XCTAssertEqual(tag.type, "primary")
        XCTAssertFalse(tag.disabled)
        XCTAssertEqual(tag.size, "medium")
        XCTAssertEqual(tag.shape, "square")
        XCTAssertEqual(tag.text, "")
        XCTAssertEqual(tag.closeColor, "#C6C7CB")
        XCTAssertFalse(tag.plainFill)
        XCTAssertFalse(tag.plain)
        XCTAssertFalse(tag.closable)
        XCTAssertTrue(tag.show)
        XCTAssertEqual(tag.autoBgColor, 0)
    }

    func testStringOrNumberPropsDisabledFlagAndSharedMixinRemainAvailable() {
        let style = UPStyle(["marginTop": "8px"])
        let enabled = UPTag(
            disabled: "",
            text: Int64(42),
            name: UInt16(7),
            customClass: "sale-tag",
            customStyle: style
        )
        let disabled = UPTag(disabled: "disabled")
        let opacity: UInt8 = 35
        let tinted = UPTag(autoBgColor: opacity)

        XCTAssertFalse(enabled.disabled)
        XCTAssertTrue(disabled.disabled)
        XCTAssertEqual(tinted.autoBgColor, 35)
        XCTAssertEqual(enabled.text, "42")
        XCTAssertEqual(enabled.name, .number(7))
        XCTAssertEqual(enabled.customClass, "sale-tag")
        XCTAssertEqual(enabled.customStyle, style)
    }

    func testSwiftUIMappingsExposeDefaultIconAndContentSlots() {
        let defaultSlot = UPTag {
            Text("默认内容")
        }
        let namedSlots = UPTag()
            .icon {
                Image(systemName: "star.fill")
            }
            .content {
                Text("具名内容")
            }

        XCTAssertTrue(defaultSlot.hasDefaultSlot)
        XCTAssertFalse(defaultSlot.hasIconSlot)
        XCTAssertFalse(defaultSlot.hasContentSlot)
        XCTAssertTrue(namedSlots.hasIconSlot)
        XCTAssertTrue(namedSlots.hasContentSlot)
    }
}

extension TagTests {
    func testClickAndCloseEventsPreserveTypedNamePayload() {
        var clicked: UPTagName?
        var closed: UPTagName?

        let tag = UPTag(name: Int16(3), closable: true)
            .onClick { clicked = $0 }
            .onClose { closed = $0 }

        tag.triggerClick()
        tag.triggerClose()

        XCTAssertEqual(clicked, .number(3))
        XCTAssertEqual(closed, .number(3))
    }
}

extension TagTests {
    func testNativeSizingAndImageIconRecognitionMirrorUviewPlusTag() {
        let mini = UPTag(size: "mini")
        let medium = UPTag(size: "medium")
        let large = UPTag(size: "large", shape: "circle")
        let customized = UPTag(
            size: "medium",
            textSize: "18px",
            height: "40px",
            padding: "1px 2px 3px 4px",
            borderRadius: "9px"
        )

        XCTAssertEqual(mini.resolvedTagHeight, 22)
        XCTAssertEqual(mini.resolvedTextSize, 12)
        XCTAssertEqual(mini.resolvedIconSize, 16)
        XCTAssertEqual(mini.resolvedImageIconSize, 13)
        XCTAssertEqual(mini.resolvedCloseButtonSize, 18)
        XCTAssertEqual(mini.resolvedCloseIconSize, 12)
        XCTAssertEqual(mini.resolvedContentInsets, UPInsets(top: 0, leading: 5, bottom: 0, trailing: 5))

        XCTAssertEqual(medium.resolvedTagHeight, 26)
        XCTAssertEqual(medium.resolvedTextSize, 13)
        XCTAssertEqual(medium.resolvedIconSize, 19)
        XCTAssertEqual(medium.resolvedImageIconSize, 15)
        XCTAssertEqual(medium.resolvedCloseButtonSize, 22)
        XCTAssertEqual(medium.resolvedCloseIconSize, 13)
        XCTAssertEqual(medium.resolvedContentInsets, UPInsets(top: 0, leading: 10, bottom: 0, trailing: 10))

        XCTAssertEqual(large.resolvedTagHeight, 32)
        XCTAssertEqual(large.resolvedTextSize, 15)
        XCTAssertEqual(large.resolvedIconSize, 21)
        XCTAssertEqual(large.resolvedImageIconSize, 17)
        XCTAssertEqual(large.resolvedCloseButtonSize, 25)
        XCTAssertEqual(large.resolvedCloseIconSize, 15)
        XCTAssertEqual(large.resolvedCornerRadius, 100)

        XCTAssertEqual(customized.resolvedTagHeight, 40)
        XCTAssertEqual(customized.resolvedTextSize, 18)
        XCTAssertEqual(customized.resolvedContentInsets, UPInsets(top: 1, leading: 4, bottom: 3, trailing: 2))
        XCTAssertEqual(customized.resolvedCornerRadius, 9)

        XCTAssertTrue(UPTag(icon: "https://example.com/tag.SVG?version=1").usesImageIcon)
        XCTAssertFalse(UPTag(icon: "tags-fill").usesImageIcon)
    }
}

extension TagTests {
    func testAutoBackgroundColorUsesUviewPlusHSLLightnessRules() {
        XCTAssertEqual(UPTag.autoBackgroundHex(for: "#2979ff", lightness: 80), "#99bfff")
        XCTAssertEqual(UPTag.autoBackgroundHex(for: "rgb(255, 0, 0)", lightness: 95), "#ffe5e5")
        XCTAssertEqual(UPTag.autoBackgroundHex(for: "#abcdef", lightness: 100), "#eaf2fb")
        XCTAssertEqual(UPTag.autoBackgroundHex(for: "#ff0000", lightness: 50), "#ff0000")
        XCTAssertNil(UPTag.autoBackgroundHex(for: "primary", lightness: 80))
    }
}
