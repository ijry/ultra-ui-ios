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

    /// 上游 props 内联在 `.vue` 里：`modelValue: ''`、`title: ''`、`description: ''`、
    /// `options: []`、`valueKey: 'value'`、`labelKey: 'name'`。
    func testActionSheetDataPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.actionSheetData.modelValue, "")
        XCTAssertEqual(UPConfig.actionSheetData.title, "")
        XCTAssertEqual(UPConfig.actionSheetData.description, "")
        // 上游 labelKey 默认是 name（不是 label），valueKey 默认是 value。
        XCTAssertEqual(UPConfig.actionSheetData.valueKey, "value")
        XCTAssertEqual(UPConfig.actionSheetData.labelKey, "name")

        let sheet = UPActionSheetData()
        XCTAssertEqual(sheet.title, "")
        XCTAssertEqual(sheet.description, "")
        XCTAssertTrue(sheet.options.isEmpty)
        XCTAssertEqual(sheet.valueKey, "value")
        XCTAssertEqual(sheet.labelKey, "name")
        XCTAssertEqual(sheet.current, "")
        XCTAssertFalse(sheet.show)
        XCTAssertFalse(sheet.hasTriggerSlot)
    }

    /// 上游 `created` 按 `valueKey` 匹配后取 `labelKey` 当回显文本。
    func testActionSheetDataSeedsCurrentLabelFromModelValue() {
        let options = [
            UPActionSheetAction(name: "北京", values: ["name": "北京", "value": "bj"]),
            UPActionSheetAction(name: "上海", values: ["name": "上海", "value": "sh"])
        ]
        XCTAssertEqual(
            UPActionSheetData.label(for: "sh", in: options, valueKey: "value", labelKey: "name"),
            "上海"
        )
        // 上游 modelValue 为空时 created 分支不跑，回显保持空串。
        XCTAssertEqual(
            UPActionSheetData.label(for: "", in: options, valueKey: "value", labelKey: "name"),
            ""
        )
        // 匹配不到时上游的 forEach 不赋值，这里同样返回空串。
        XCTAssertEqual(
            UPActionSheetData.label(for: "gz", in: options, valueKey: "value", labelKey: "name"),
            ""
        )

        var value = "bj"
        let sheet = UPActionSheetData(
            modelValue: Binding(get: { value }, set: { value = $0 }),
            title: "请选择城市",
            options: options
        )
        XCTAssertEqual(sheet.current, "北京")
    }

    /// 上游 `select(e)`：写回 `option[valueKey]`，回显换成 `option[labelKey]`。
    func testActionSheetDataSelectWritesBackValueAndLabel() {
        var value = ""
        var changes: [String] = []
        let options = [
            UPActionSheetAction(name: "北京", values: ["name": "北京", "value": "bj"]),
            UPActionSheetAction(name: "上海", values: ["name": "上海", "value": "sh"])
        ]
        let sheet = UPActionSheetData(
            modelValue: Binding(get: { value }, set: { value = $0 }),
            options: options
        ).onChange { changes.append($0) }

        sheet.open()
        XCTAssertTrue(sheet.show)

        sheet.select(options[1])
        XCTAssertEqual(value, "sh")
        XCTAssertEqual(sheet.current, "上海")
        XCTAssertEqual(changes, ["sh"])

        sheet.close()
        XCTAssertFalse(sheet.show)
    }

    func testActionSheetDataExposesTriggerSlot() {
        let plain = UPActionSheetData()
        XCTAssertFalse(plain.hasTriggerSlot)
        XCTAssertTrue(plain.trigger { Text("自定义触发器") }.hasTriggerSlot)
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
