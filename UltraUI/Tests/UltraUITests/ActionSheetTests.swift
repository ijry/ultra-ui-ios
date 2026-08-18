import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class ActionSheetTests: XCTestCase {
    func testDefaultsMatchUviewPlusActionSheet() {
        XCTAssertFalse(UPConfig.actionSheet.show)
        XCTAssertEqual(UPConfig.actionSheet.title, "")
        XCTAssertEqual(UPConfig.actionSheet.description, "")
        XCTAssertTrue(UPConfig.actionSheet.actions.isEmpty)
        XCTAssertEqual(UPConfig.actionSheet.nameKey, "name")
        XCTAssertEqual(UPConfig.actionSheet.subnameKey, "subnameKey")
        XCTAssertEqual(UPConfig.actionSheet.cancelText, "")
        XCTAssertTrue(UPConfig.actionSheet.closeOnClickAction)
        XCTAssertTrue(UPConfig.actionSheet.safeAreaInsetBottom)
        XCTAssertEqual(UPConfig.actionSheet.openType, "")
        XCTAssertTrue(UPConfig.actionSheet.closeOnClickOverlay)
        XCTAssertEqual(UPConfig.actionSheet.round, "0")
        XCTAssertEqual(UPConfig.actionSheet.wrapMaxHeight, "600px")
    }

    func testTypedActionPopulatesBothStandardSubnameKeys() {
        let action = UPActionSheetAction(
            id: "delete",
            name: "删除",
            subname: "删除后无法恢复",
            color: "#fa3534",
            fontSize: 16,
            disabled: true,
            loading: false
        )

        XCTAssertEqual(action.id, "delete")
        XCTAssertEqual(action.value(for: "name"), "删除")
        XCTAssertEqual(action.value(for: "subname"), "删除后无法恢复")
        XCTAssertEqual(action.value(for: "subnameKey"), "删除后无法恢复")
        XCTAssertEqual(action.color, "#fa3534")
        XCTAssertEqual(action.resolvedFontSize, 16)
        XCTAssertTrue(action.disabled)
        XCTAssertFalse(action.loading)
    }

    func testDynamicActionValuesHonorCustomKeys() {
        let action = UPActionSheetAction(
            id: "edit",
            values: [
                "label": "编辑",
                "detail": "修改当前内容"
            ]
        )

        XCTAssertEqual(action.value(for: "label"), "编辑")
        XCTAssertEqual(action.value(for: "detail"), "修改当前内容")
        XCTAssertEqual(action.value(for: "missing"), nil)
    }

    func testStringAndNumberDimensionsNormalizeSafely() {
        XCTAssertEqual(UPActionSheet.parseDimension("48px", fallback: 0), 48)
        XCTAssertEqual(UPActionSheet.parseDimension("24rpx", fallback: 0), 24)
        XCTAssertEqual(UPActionSheet.parseDimension("bad", fallback: 7), 7)
        XCTAssertEqual(UPActionSheet.parseDimension("-4", fallback: 7), 7)
        XCTAssertEqual(UPActionSheet.parseDimension("infinity", fallback: 7), 7)
    }
}

extension ActionSheetTests {
    func testSelectionEmitsSelectThenBindingChangeThenClose() {
        var shown = true
        var events: [String] = []
        let binding = Binding(
            get: { shown },
            set: { shown = $0; events.append("show:\($0)") }
        )
        let action = UPActionSheetAction(id: "edit", name: "编辑")

        UPActionSheet.performSelection(
            action,
            show: binding,
            closeOnClickAction: true,
            onSelect: { events.append("select:\($0.name)") },
            onClose: { events.append("close") }
        )

        XCTAssertEqual(events, ["select:编辑", "show:false", "close"])
        XCTAssertFalse(shown)
    }

    func testSelectionCanRemainOpenWhenCloseOnClickActionIsFalse() {
        var shown = true
        var events: [String] = []
        let binding = Binding(get: { shown }, set: { shown = $0 })
        let action = UPActionSheetAction(id: "edit", name: "编辑")

        UPActionSheet.performSelection(
            action,
            show: binding,
            closeOnClickAction: false,
            onSelect: { _ in events.append("select") },
            onClose: { events.append("close") }
        )

        XCTAssertEqual(events, ["select"])
        XCTAssertTrue(shown)
    }

    func testDisabledAndLoadingActionsDoNotSelectOrClose() {
        for action in [
            UPActionSheetAction(id: "disabled", name: "禁用", disabled: true),
            UPActionSheetAction(id: "loading", name: "加载", loading: true)
        ] {
            var shown = true
            var events: [String] = []
            let binding = Binding(get: { shown }, set: { shown = $0 })

            UPActionSheet.performSelection(
                action,
                show: binding,
                closeOnClickAction: true,
                onSelect: { _ in events.append("select") },
                onClose: { events.append("close") }
            )

            XCTAssertTrue(shown)
            XCTAssertTrue(events.isEmpty)
        }
    }

    func testCancelAndAllowedOverlayCloseUpdateBindingBeforeClose() {
        var shown = true
        var events: [String] = []
        let binding = Binding(
            get: { shown },
            set: { shown = $0; events.append("show:\($0)") }
        )

        UPActionSheet.performClose(show: binding) { events.append("close") }
        XCTAssertEqual(events, ["show:false", "close"])

        shown = true
        events.removeAll()
        UPActionSheet.performOverlayTap(
            show: binding,
            closeOnClickOverlay: true,
            onClose: { events.append("close") }
        )
        XCTAssertEqual(events, ["show:false", "close"])
    }

    func testDisallowedOverlayDoesNothing() {
        var shown = true
        var closed = false
        let binding = Binding(get: { shown }, set: { shown = $0 })

        UPActionSheet.performOverlayTap(
            show: binding,
            closeOnClickOverlay: false,
            onClose: { closed = true }
        )

        XCTAssertTrue(shown)
        XCTAssertFalse(closed)
    }
}

extension ActionSheetTests {
    func testDefaultActionSheetNormalizesPropsAndRendersDefaultActions() {
        let sheet = UPActionSheet(
            show: .constant(false),
            title: "操作",
            actions: [UPActionSheetAction(name: "编辑")],
            round: "12px",
            wrapMaxHeight: 420
        )

        XCTAssertEqual(sheet.title, "操作")
        XCTAssertEqual(sheet.resolvedRound, 12)
        XCTAssertEqual(sheet.resolvedWrapMaxHeight, 420)
        XCTAssertFalse(sheet.hasCustomContent)
        XCTAssertTrue(sheet.shouldRenderDefaultActions)
        XCTAssertEqual(sheet.displayName(for: sheet.actions[0]), "编辑")
    }

    func testCustomContentSuppressesDefaultActions() {
        let sheet = UPActionSheet(
            show: .constant(false),
            actions: [UPActionSheetAction(name: "不会显示")]
        ) {
            Text("自定义")
        }

        XCTAssertTrue(sheet.hasCustomContent)
        XCTAssertFalse(sheet.shouldRenderDefaultActions)
    }

    func testFluentEventModifiersReplaceHandlersWithoutMutatingOriginal() {
        let original = UPActionSheet(show: .constant(false))
        let selected = original.onSelect { _ in }
        let closed = selected.onClose {}

        XCTAssertNil(original.onSelectHandler)
        XCTAssertNil(original.onCloseHandler)
        XCTAssertNotNil(selected.onSelectHandler)
        XCTAssertNil(selected.onCloseHandler)
        XCTAssertNotNil(closed.onSelectHandler)
        XCTAssertNotNil(closed.onCloseHandler)
    }

    #if os(macOS)
    func testActionSheetCanRenderIntoAFixedNativeCanvas() {
        let renderer = ImageRenderer(
            content: UPActionSheet(
                show: .constant(true),
                title: "操作",
                description: "说明",
                actions: [
                    UPActionSheetAction(name: "编辑"),
                    UPActionSheetAction(name: "删除", disabled: true),
                    UPActionSheetAction(name: "加载", loading: true)
                ],
                cancelText: "取消"
            )
            .frame(width: 360, height: 560)
        )

        XCTAssertEqual(renderer.cgImage?.width, 360)
        XCTAssertEqual(renderer.cgImage?.height, 560)
    }
    #endif
}
