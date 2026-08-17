import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class SearchTests: XCTestCase {
    func testDefaultsMatchUviewPlusSearch() {
        XCTAssertEqual(UPConfig.search.shape, "round")
        XCTAssertEqual(UPConfig.search.bgColor, "")
        XCTAssertEqual(UPConfig.search.placeholder, "请输入关键字")
        XCTAssertTrue(UPConfig.search.clearabled)
        XCTAssertTrue(UPConfig.search.showAction)
        XCTAssertEqual(UPConfig.search.actionText, "搜索")
        XCTAssertEqual(UPConfig.search.iconPosition, "left")
        XCTAssertEqual(UPConfig.search.height, 32)
        XCTAssertEqual(UPConfig.search.maxlength, "-1")
        XCTAssertTrue(UPConfig.search.adjustPosition)
        XCTAssertTrue(UPConfig.search.autoBlur)
    }

    func testInvalidPropsUseSafeNativeFallbacks() {
        XCTAssertEqual(UPSearch.normalizedShape("unknown"), "square")
        XCTAssertEqual(UPSearch.normalizedShape("round"), "round")
        XCTAssertEqual(UPSearch.normalizedIconPosition("unknown"), "left")
        XCTAssertEqual(UPSearch.normalizedIconPosition("right"), "right")
        XCTAssertEqual(UPSearch.normalizedAlignment("unknown"), .leading)
        XCTAssertEqual(UPSearch.normalizedAlignment("center"), .center)
        XCTAssertEqual(UPSearch.normalizedAlignment("right"), .trailing)
        XCTAssertNil(UPSearch.parseMaxlength("-1"))
        XCTAssertNil(UPSearch.parseMaxlength("bad"))
        XCTAssertEqual(UPSearch.parseMaxlength("3"), 3)
        XCTAssertEqual(UPSearch.truncated("abcdef", maxlength: 3), "abc")
        XCTAssertEqual(UPSearch.truncated("abcdef", maxlength: nil), "abcdef")
    }

    func testStringAndNumberPropsNormalizeIndependently() {
        XCTAssertEqual(UPSearch.parseMaxlength(4), 4)
        XCTAssertEqual(UPSearch.parseMaxlength("4"), 4)
        let stringSearch = UPSearch(maxlength: "4", height: "36px", searchIconSize: "18px")
        XCTAssertEqual(stringSearch.resolvedMaxlength, 4)
        XCTAssertEqual(stringSearch.resolvedHeight, 36)
        XCTAssertEqual(stringSearch.resolvedSearchIconSize, 18)

        let numberSearch = UPSearch(maxlength: 5, height: 40, searchIconSize: 20)
        XCTAssertEqual(numberSearch.resolvedMaxlength, 5)
        XCTAssertEqual(numberSearch.resolvedHeight, 40)
        XCTAssertEqual(numberSearch.resolvedSearchIconSize, 20)
    }

    func testClearableAliasAndVisibilityRules() {
        let aliasSearch = UPSearch(clearabled: false, clearable: true)
        XCTAssertTrue(aliasSearch.resolvedClearable)
        XCTAssertFalse(UPSearch.shouldShowClear(value: "abc", clearabled: false, focused: true, onlyClearableOnFocused: false))
        XCTAssertTrue(UPSearch.shouldShowClear(value: "abc", clearabled: true, focused: true, onlyClearableOnFocused: true))
        XCTAssertFalse(UPSearch.shouldShowClear(value: "abc", clearabled: true, focused: false, onlyClearableOnFocused: true))
        XCTAssertFalse(UPSearch.shouldShowClear(value: "", clearabled: true, focused: true, onlyClearableOnFocused: false))
    }

    func testControllerQueuesActionsUntilTheViewRegistersHandlers() {
        let controller = UPSearchController()
        var actions: [String] = []

        controller.focus()
        controller.blur()
        controller.clear()
        controller.register(
            focus: { actions.append("focus") },
            blur: { actions.append("blur") },
            clear: { actions.append("clear") }
        )

        XCTAssertEqual(actions, ["focus", "blur", "clear"])
        controller.focus()
        XCTAssertEqual(actions, ["focus", "blur", "clear", "focus"])
    }

    func testControllerUnregistersHandlersAndQueuesNewActions() {
        let controller = UPSearchController()
        var actions: [String] = []
        controller.register(
            focus: { actions.append("focus") },
            blur: { actions.append("blur") },
            clear: { actions.append("clear") }
        )
        controller.unregister()
        controller.clear()
        XCTAssertEqual(actions, [])

        controller.register(
            focus: { actions.append("focus-2") },
            blur: { actions.append("blur-2") },
            clear: { actions.append("clear-2") }
        )
        XCTAssertEqual(actions, ["clear-2"])
    }

    func testCommitEmitsChangeBeforeBindingWriteAndTruncates() {
        let box = SearchTextBox("old")
        var order: [String] = []

        UPSearch.commit("abcdef", binding: box.binding, maxlength: 3) { value in
            order.append("event:\(value):\(box.value)")
        }

        XCTAssertEqual(order, ["event:abc:old"])
        XCTAssertEqual(box.value, "abc")
    }

    func testFocusBlurSearchClearAndIconCarryCurrentValue() {
        var events: [String] = []
        let search = UPSearch(
            onFocus: { events.append("focus:\($0)") },
            onBlur: { events.append("blur:\($0)") },
            onSearch: { events.append("search:\($0)") },
            onClear: { events.append("clear") },
            onClickIcon: { events.append("icon:\($0)") }
        )

        search.onFocusHandler?("abc")
        search.onBlurHandler?("abc")
        search.onSearchHandler?("abc")
        search.onClearHandler?()
        search.onClickIconHandler?("abc")

        XCTAssertEqual(events, ["focus:abc", "blur:abc", "search:abc", "clear", "icon:abc"])
    }

    func testEventModifiersPreserveUpstreamPayloadNames() {
        var events: [String] = []
        let search = UPSearch()
            .onChange { events.append("change:\($0)") }
            .onSearch { events.append("search:\($0)") }
            .onCustom { events.append("custom:\($0)") }
            .onClear { events.append("clear") }
            .onFocus { events.append("focus:\($0)") }
            .onBlur { events.append("blur:\($0)") }
            .onClick { events.append("click") }
            .onClickIcon { events.append("icon:\($0)") }

        search.onChangeHandler?("a")
        search.onSearchHandler?("a")
        search.onCustomHandler?("a")
        search.onClearHandler?()
        search.onFocusHandler?("a")
        search.onBlurHandler?("a")
        search.onClickHandler?()
        search.onClickIconHandler?("a")

        XCTAssertEqual(events, [
            "change:a", "search:a", "custom:a", "clear",
            "focus:a", "blur:a", "click", "icon:a"
        ])
    }

    func testDisabledSearchOnlyForwardsShellClick() {
        var clicked = false
        var custom = false
        var cleared = false
        let search = UPSearch(
            disabled: true,
            onClick: { clicked = true },
            onCustom: { _ in custom = true },
            onClear: { cleared = true }
        )

        search.onClickHandler?()
        search.onCustomHandler?("ignored")
        search.onClearHandler?()

        XCTAssertTrue(clicked)
        XCTAssertFalse(custom)
        XCTAssertFalse(cleared)
    }

#if os(macOS)
    func testSearchRendersIntoFixedNativeCanvas() {
        let renderer = ImageRenderer(
            content: UPSearch(value: .constant("keyword"), showAction: true)
                .frame(width: 360, height: 48)
        )
        XCTAssertEqual(renderer.cgImage?.width, 360)
        XCTAssertEqual(renderer.cgImage?.height, 48)
    }
#endif
}

@MainActor
private final class SearchTextBox {
    var value: String

    init(_ value: String) {
        self.value = value
    }

    var binding: Binding<String> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
