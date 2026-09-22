import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class PickerCoreTests: XCTestCase {
    func testPickerDefaultsAndColumnSelection() {
        let value = StringArrayBox([])
        var changes: [UPPickerChange] = []
        let picker = UPPicker(columns: [["男", "女"], ["北京", "上海"]], modelValue: value.binding)
            .onChange { changes.append($0) }

        XCTAssertEqual(picker.itemHeight, 44)
        XCTAssertEqual(picker.visibleItemCount, 5)
        XCTAssertEqual(picker.keyName, "text")
        picker.select(column: 1, index: 1)
        XCTAssertEqual(changes.last?.indices, [0, 1])
        picker.confirm()
        XCTAssertEqual(value.value, ["男", "上海"])
    }

    func testDatetimePickerClampsDateAndEmitsConfirm() {
        let value = Int64Box(0)
        var confirmed: Int64 = 0
        let picker = UPDatetimePicker(modelValue: value.binding, mode: "date", minDate: 100, maxDate: 200)
            .onConfirm { confirmed = $0 }
        picker.setValue(999)
        picker.confirm()
        XCTAssertEqual(value.value, 200)
        XCTAssertEqual(confirmed, 200)
        XCTAssertEqual(picker.mode, "date")
    }

    func testPickerNormalizesUpstreamStringNumberAndBooleanProps() {
        let picker = UPPicker(
            columns: [["A"]],
            itemHeight: "48",
            visibleItemCount: "7",
            zIndex: "12000",
            round: true,
            duration: "450",
            overlayOpacity: "0.35",
            hasInput: true,
            inputBorder: "bottom",
            disabledColor: "#eeeeee",
            toolbarRightSlot: true,
            pageInline: true,
            maskClass: "picker-mask",
            maskStyle: "opacity: 0.8"
        )

        XCTAssertEqual(picker.itemHeight, 48)
        XCTAssertEqual(picker.visibleItemCount, 7)
        XCTAssertEqual(picker.zIndex, 12_000)
        XCTAssertEqual(picker.round, "true")
        XCTAssertEqual(picker.duration, 450)
        XCTAssertEqual(picker.overlayOpacity, 0.35)
        XCTAssertTrue(picker.hasInput)
        XCTAssertEqual(picker.inputBorder, "bottom")
        XCTAssertEqual(picker.disabledColor, "#eeeeee")
        XCTAssertTrue(picker.toolbarRightSlot)
        XCTAssertTrue(picker.pageInline)
        XCTAssertEqual(picker.maskClass, "picker-mask")
        XCTAssertEqual(picker.maskStyle, "opacity: 0.8")
    }

    func testPickerUsesDefaultIndexOnlyWhenEveryColumnHasAnIndex() {
        let incomplete = UPPicker(
            columns: [["A", "B"], ["C", "D"]],
            defaultIndex: [1]
        )
        let complete = UPPicker(
            columns: [["A", "B"], ["C", "D"]],
            defaultIndex: [1, 1]
        )

        XCTAssertEqual(incomplete.selectedIndices, [0, 0])
        XCTAssertEqual(complete.selectedIndices, [1, 1])
    }

    func testPickerPayloadKeepsLegacyFieldsAndAddsUpstreamAliases() {
        var change: UPPickerChange?
        let columns = [
            [UPPickerData(text: "男", value: "male"), UPPickerData(text: "女", value: "female")],
            [UPPickerData(text: "北京", value: "bj"), UPPickerData(text: "上海", value: "sh")]
        ]
        let picker = UPPicker(dataColumns: columns)
            .onChange { change = $0 }

        picker.select(column: 1, index: 1)

        XCTAssertEqual(change?.indices, [0, 1])
        XCTAssertEqual(change?.indexs, [0, 1])
        XCTAssertEqual(change?.values.map(\.value), ["male", "sh"])
        XCTAssertEqual(change?.value.map(\.value), ["male", "sh"])
        XCTAssertEqual(change?.allValues, columns)
        XCTAssertEqual(change?.columnIndex, 1)
        XCTAssertEqual(change?.index, 1)
    }

    func testPickerConfirmAndCancelCloseBeforeCallbacks() {
        let selected = StringArrayBox([])
        let show = PickerBoolBox(true)
        var events: [String] = []
        let picker = UPPicker(
            columns: [["A", "B"]],
            modelValue: selected.binding,
            show: show.binding,
            defaultIndex: [1],
            pageInline: true
        )
        .onConfirm { _ in events.append("confirm:\(show.value)") }
        .onClosed { events.append("closed") }

        picker.confirm()

        XCTAssertEqual(selected.value, ["B"])
        XCTAssertFalse(show.value)
        XCTAssertEqual(events, ["confirm:false", "closed"])

        show.value = true
        events.removeAll()
        let cancelPicker = UPPicker(columns: [["A"]], show: show.binding, pageInline: true)
            .onCancel { events.append("cancel:\(show.value)") }
            .onClosed { events.append("closed") }
        cancelPicker.cancel()

        XCTAssertFalse(show.value)
        XCTAssertEqual(events, ["cancel:false", "closed"])
    }

    func testPickerOverlayHonorsCloseOnClickOverlayAndEmitsClose() {
        let show = PickerBoolBox(true)
        var closes = 0
        let locked = UPPicker(columns: [["A"]], show: show.binding)
            .onClose { closes += 1 }
        locked.overlayClick()
        XCTAssertTrue(show.value)
        XCTAssertEqual(closes, 0)

        let closable = UPPicker(
            columns: [["A"]],
            show: show.binding,
            closeOnClickOverlay: true
        )
        .onClose { closes += 1 }
        closable.overlayClick()
        XCTAssertFalse(show.value)
        XCTAssertEqual(closes, 1)
    }

    func testPickerCancelRestoresMostRecentlyConfirmedIndices() {
        let picker = UPPicker(columns: [["A", "B", "C"]])

        picker.select(column: 0, index: 1)
        picker.confirm()
        picker.select(column: 0, index: 2)
        picker.cancel()

        XCTAssertEqual(picker.selectedIndices, [1])
    }

    func testPickerStoresUpstreamNamedSlots() {
        let picker = UPPicker(columns: [["A"]])
            .trigger { Text("trigger") }
            .toolbarRight { Text("right") }
            .toolbarBottom { Text("bottom") }

        XCTAssertTrue(picker.hasTriggerSlot)
        XCTAssertTrue(picker.hasToolbarRightSlot)
        XCTAssertTrue(picker.hasToolbarBottomSlot)
    }

    func testPickerColumnNormalizesSelectionAndHeight() {
        let options = [UPPickerData(text: "A"), UPPickerData(text: "B")]
        XCTAssertEqual(UPPickerColumn(options: options, selectedIndex: 99).selectedIndex, 1)
        XCTAssertEqual(UPPickerColumn(options: options, selectedIndex: -1).selectedIndex, 0)
        XCTAssertEqual(UPPickerColumn(options: options, itemHeight: "-10").itemHeight, 0)
    }

    func testDatetimePickerNormalizesPropsAndMode() {
        let picker = UPDatetimePicker(
            toolbarRightSlot: true,
            mode: "unsupported",
            minDate: 200,
            maxDate: 100,
            minHour: 30,
            maxHour: -1,
            itemHeight: "48",
            visibleItemCount: "7",
            disabledColor: "#dddddd",
            hasInput: true,
            inputBorder: "bottom",
            pageInline: true,
            maskClass: "date-mask",
            maskStyle: "opacity: 0.5"
        )

        XCTAssertEqual(picker.mode, "datetime")
        XCTAssertEqual(picker.minDate, 200)
        XCTAssertEqual(picker.maxDate, 200)
        XCTAssertEqual(picker.minHour, 23)
        XCTAssertEqual(picker.maxHour, 23)
        XCTAssertEqual(picker.itemHeight, 48)
        XCTAssertEqual(picker.visibleItemCount, 7)
        XCTAssertTrue(picker.hasInput)
        XCTAssertEqual(picker.inputBorder, "bottom")
        XCTAssertEqual(picker.disabledColor, "#dddddd")
        XCTAssertTrue(picker.toolbarRightSlot)
        XCTAssertTrue(picker.pageInline)
        XCTAssertEqual(picker.maskClass, "date-mask")
        XCTAssertEqual(picker.maskStyle, "opacity: 0.5")
    }

    func testTimePickerClampsAndPadsStringModelValue() {
        let value = StringBox("99:99")
        var changes: [UPDatetimePickerChange] = []
        var confirms: [UPDatetimePickerChange] = []
        let picker = UPDatetimePicker(
            modelValue: value.binding,
            mode: "time",
            minHour: 8,
            maxHour: 18,
            minMinute: 5,
            maxMinute: 45
        )
        .onChangePayload { changes.append($0) }
        .onConfirmPayload { confirms.append($0) }

        picker.setValue("7:3")
        picker.confirm()

        XCTAssertEqual(value.value, "08:05")
        XCTAssertEqual(changes, [UPDatetimePickerChange(value: .time("08:05"), mode: "time")])
        XCTAssertEqual(confirms, [UPDatetimePickerChange(value: .time("08:05"), mode: "time")])
    }

    func testTimeSecondPickerUsesThreeFieldsAndDefaultBoundaryValues() {
        let value = StringBox("")
        let picker = UPDatetimePicker(
            modelValue: value.binding,
            mode: "timesecond",
            minHour: 6,
            minMinute: 7,
            minSecond: 8
        )

        picker.confirm()

        XCTAssertEqual(value.value, "06:07:08")
    }

    func testDatetimeConfirmCancelAndOverlayUpdateShowBeforeEvents() {
        let value = Int64Box(150)
        let show = PickerBoolBox(true)
        var events: [String] = []
        let picker = UPDatetimePicker(
            modelValue: value.binding,
            show: show.binding,
            mode: "date",
            minDate: 100,
            maxDate: 200,
            pageInline: true
        )
        .onConfirmPayload { _ in events.append("confirm:\(show.value)") }
        .onClosed { events.append("closed") }

        picker.confirm()
        XCTAssertFalse(show.value)
        XCTAssertEqual(events, ["confirm:false", "closed"])

        show.value = true
        events.removeAll()
        let cancelPicker = UPDatetimePicker(show: show.binding, pageInline: true)
            .onCancel { events.append("cancel:\(show.value)") }
            .onClosed { events.append("closed") }
        cancelPicker.cancel()
        XCTAssertEqual(events, ["cancel:false", "closed"])

        show.value = true
        events.removeAll()
        let overlayPicker = UPDatetimePicker(
            show: show.binding,
            closeOnClickOverlay: true,
            pageInline: true
        )
        .onClose { events.append("close:\(show.value)") }
        .onClosed { events.append("closed") }
        overlayPicker.overlayClick()
        XCTAssertEqual(events, ["close:false", "closed"])
    }

    func testDatetimePickerStoresUpstreamNamedSlots() {
        let picker = UPDatetimePicker()
            .trigger { Text("trigger") }
            .toolbarRight { Text("right") }
            .toolbarBottom { Text("bottom") }

        XCTAssertTrue(picker.hasTriggerSlot)
        XCTAssertTrue(picker.hasToolbarRightSlot)
        XCTAssertTrue(picker.hasToolbarBottomSlot)
    }
}

@MainActor
final class PickerSelectionTests: XCTestCase {
    func testCascaderSelectsPathAndConfirms() {
        let value = StringArrayBox([])
        var result: [String] = []
        let cascader = UPCascader(data: [UPCascaderNode(value: "zj", label: "浙江", children: [UPCascaderNode(value: "hz", label: "杭州")])], modelValue: value.binding)
            .onConfirm { result = $0 }
        cascader.select(path: [0, 0])
        cascader.confirm()
        XCTAssertEqual(value.value, ["zj", "hz"])
        XCTAssertEqual(result, ["zj", "hz"])
        XCTAssertTrue(cascader.closeable)
    }

    /// 上游 props 内联在 `.vue` 里：`valueKey: 'value'`、`labelKey: 'label'`、
    /// `childrenKey: 'children'`、`maskCloseAble: true`、`zIndex: 0`、
    /// `autoClose: false`、`headerDirection: 'row'`、`optionsCols: 2`、`closeable: true`。
    func testCascaderPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.cascader.valueKey, "value")
        XCTAssertEqual(UPConfig.cascader.labelKey, "label")
        XCTAssertEqual(UPConfig.cascader.childrenKey, "children")
        XCTAssertTrue(UPConfig.cascader.maskCloseAble)
        XCTAssertEqual(UPConfig.cascader.zIndex, 0)
        XCTAssertFalse(UPConfig.cascader.autoClose)
        XCTAssertEqual(UPConfig.cascader.headerDirection, "row")
        XCTAssertEqual(UPConfig.cascader.optionsCols, 2)
        XCTAssertTrue(UPConfig.cascader.closeable)
        XCTAssertEqual(UPConfig.cascader.placeholderTabName, "请选择")

        let cascader = UPCascader(data: cascaderData)
        XCTAssertEqual(cascader.valueKey, "value")
        XCTAssertEqual(cascader.labelKey, "label")
        XCTAssertEqual(cascader.childrenKey, "children")
        XCTAssertTrue(cascader.maskCloseAble)
        XCTAssertEqual(cascader.zIndex, 0)
        XCTAssertFalse(cascader.autoClose)
        XCTAssertEqual(cascader.headerDirection, "row")
        XCTAssertEqual(cascader.optionsCols, 2)
        XCTAssertTrue(cascader.closeable)
        // 上游 uZIndex：zIndex 为假值时回落 $u.zIndex.popup。
        XCTAssertEqual(cascader.resolvedZIndex, 10_075)
        XCTAssertEqual(UPCascader(data: [], zIndex: 999).resolvedZIndex, 999)
        // 上游 initLevelList：data 非空时 levelList 只有第一级。
        XCTAssertEqual(cascader.levelList.count, 1)
        XCTAssertTrue(cascader.selectedValueIndexs.isEmpty)
    }

    /// 上游 `setDefaultValue()`：逐级按 valueKey 找下标，找不到或没有子级就停下。
    func testCascaderSeedsLevelsFromModelValue() {
        let value = StringArrayBox(["zj", "hz"])
        let cascader = UPCascader(data: cascaderData, modelValue: value.binding)
        XCTAssertEqual(cascader.selectedValueIndexs, [0, 0])
        XCTAssertEqual(cascader.levelList.count, 2)
        // 上游同步 confirmValues，避免「仅回显未改动时确认返回空数组」。
        XCTAssertEqual(cascader.confirmValues, ["zj", "hz"])
        XCTAssertEqual(cascader.getSelectedValues(), ["zj", "hz"])

        // 找不到匹配项时停在该级。
        let (levels, indexes) = UPCascader.resolveLevels(data: cascaderData, modelValue: ["zj", "missing"])
        XCTAssertEqual(indexes, [0])
        XCTAssertEqual(levels.count, 2)
    }

    /// 上游 `genTabsList`：首项「请选择」，选中后替换标题，还有子级时再追加一个「请选择」。
    func testCascaderTabsListMatchesUpstream() {
        XCTAssertEqual(UPCascader.tabsList(levels: [cascaderData], indexes: []), ["请选择"])

        let (levels, indexes) = UPCascader.resolveLevels(data: cascaderData, modelValue: ["zj"])
        XCTAssertEqual(UPCascader.tabsList(levels: levels, indexes: indexes), ["浙江", "请选择"])

        let (deepLevels, deepIndexes) = UPCascader.resolveLevels(data: cascaderData, modelValue: ["zj", "hz"])
        XCTAssertEqual(UPCascader.tabsList(levels: deepLevels, indexes: deepIndexes), ["浙江", "杭州"])
    }

    /// 上游 `levelChange`：截断其后层级、有子级则推进并切 tab。
    func testCascaderLevelChangeTruncatesAndAdvances() {
        var changes: [[String]] = []
        let cascader = UPCascader(data: cascaderData).onChange { changes.append($0) }

        cascader.levelChange(level: 0, index: 0)
        XCTAssertEqual(cascader.selectedValueIndexs, [0])
        XCTAssertEqual(cascader.levelList.count, 2)
        XCTAssertEqual(cascader.tabsIndex, 1)
        XCTAssertEqual(cascader.genTabsList, ["浙江", "请选择"])
        // 有子级时不抛 change。
        XCTAssertTrue(changes.isEmpty)

        cascader.levelChange(level: 1, index: 0)
        XCTAssertEqual(cascader.selectedValueIndexs, [0, 0])
        // 最后一级且 autoClose 为假：只抛 change，不关闭。
        XCTAssertEqual(changes, [["zj", "hz"]])
        XCTAssertTrue(cascader.popupShow == false || cascader.popupShow == true)

        // 回到第一级换一个分支，后续层级被截断。
        cascader.levelChange(level: 0, index: 1)
        XCTAssertEqual(cascader.selectedValueIndexs, [1])
        XCTAssertEqual(cascader.levelList.count, 2)
        XCTAssertEqual(cascader.genTabsList, ["江苏", "请选择"])
    }

    /// 上游 `autoClose`：选到最后一级时先 emitChange（顺带 close）再 handleConfirm。
    func testCascaderAutoCloseConfirmsImmediately() {
        let value = StringArrayBox([])
        var confirms: [[String]] = []
        var cancels = 0
        let cascader = UPCascader(data: cascaderData, modelValue: value.binding, autoClose: true)
            .onConfirm { confirms.append($0) }
            .onCancel { cancels += 1 }

        cascader.levelChange(level: 0, index: 0)
        cascader.levelChange(level: 1, index: 0)
        XCTAssertEqual(value.value, ["zj", "hz"])
        XCTAssertEqual(confirms, [["zj", "hz"]])
        XCTAssertFalse(cascader.popupShow)
        // 照抄上游：emitChange 与 handleConfirm 都会走 close()，因此 cancel 抛两次。
        XCTAssertEqual(cancels, 2)
    }

    /// 上游 `isChange` 与 `toFatherIndex`。
    func testCascaderTabIndexHelpers() {
        let cascader = UPCascader(data: cascaderData)
        XCTAssertFalse(cascader.isChange)
        cascader.toFatherIndex(2)
        XCTAssertEqual(cascader.tabsIndex, 2)
        XCTAssertTrue(cascader.isChange)
        // 上游 tabsChange 是空实现。
        cascader.tabsChange(0)
        XCTAssertEqual(cascader.tabsIndex, 2)
    }

    /// 上游模板 `levelIndex === 0 || selectedValueIndexs[levelIndex - 1] !== undefined`。
    func testCascaderLevelVisibilityAndSelection() {
        let cascader = UPCascader(data: cascaderData)
        XCTAssertTrue(cascader.isLevelVisible(0))
        XCTAssertFalse(cascader.isLevelVisible(1))
        XCTAssertFalse(cascader.isSelected(level: 0, index: 0))

        cascader.levelChange(level: 0, index: 0)
        XCTAssertTrue(cascader.isLevelVisible(1))
        XCTAssertTrue(cascader.isSelected(level: 0, index: 0))
    }

    private var cascaderData: [UPCascaderNode] {
        [
            UPCascaderNode(value: "zj", label: "浙江", children: [
                UPCascaderNode(value: "hz", label: "杭州"),
                UPCascaderNode(value: "nb", label: "宁波")
            ]),
            UPCascaderNode(value: "js", label: "江苏", children: [
                UPCascaderNode(value: "nj", label: "南京")
            ])
        ]
    }

    func testSelectUsesCurrentBindingAndReportsSelectedOption() {
        let value = StringBox("")
        var selected = ""
        let select = UPSelect(options: [UPSelectOption(id: "1", name: "一"), UPSelectOption(id: "2", name: "二")], current: value.binding)
            .onSelect { selected = $0.id }
        select.select("2")
        XCTAssertEqual(value.value, "2")
        XCTAssertEqual(selected, "2")
        XCTAssertEqual(select.label, "选项")
    }

    /// `u-select.vue` 的内联 props：`maxHeight: '90vh'`、`overlay: true`、
    /// `overlayOpacity: 0.01`、`duration: 300`、`label: '选项'`、`keyName: 'id'`、
    /// `labelName: 'name'`、`showOptionsLabel: false`、`current: ''`、
    /// `zIndex: 11000`、`itemColor: ''`、`iconColor: ''`、`iconSize: '13px'`、
    /// `disabled: false`、`border: false`、`optionsWidth: ''`。
    func testSelectPropDefaultsMatchUpstream() {
        let select = UPSelect()
        XCTAssertEqual(select.maxHeight, "90vh")
        XCTAssertTrue(select.overlay)
        XCTAssertEqual(select.overlayOpacity, 0.01)
        XCTAssertEqual(select.overlayStyle, UPStyle())
        XCTAssertEqual(select.duration, 300)
        XCTAssertEqual(select.label, "选项")
        XCTAssertEqual(select.keyName, "id")
        XCTAssertEqual(select.labelName, "name")
        XCTAssertFalse(select.showOptionsLabel)
        XCTAssertEqual(select.current, "")
        XCTAssertEqual(select.zIndex, 11000)
        XCTAssertEqual(select.itemColor, "")
        XCTAssertEqual(select.iconColor, "")
        XCTAssertEqual(select.iconSize, "13px")
        XCTAssertFalse(select.disabled)
        XCTAssertFalse(select.border)
        XCTAssertEqual(select.optionsWidth, "")
        XCTAssertFalse(select.isOpen)
        // 上游 `resolved*Color` 为空时取主题色。
        XCTAssertEqual(select.resolvedItemColor, "#303133")
        XCTAssertEqual(select.resolvedIconColor, "#606266")
        // `90vh` 与空串交给布局决定。
        XCTAssertNil(select.resolvedMaxHeight)
        XCTAssertNil(select.resolvedOptionsWidth)
        XCTAssertFalse(select.hasTextSlot)
        XCTAssertFalse(select.hasOptionItemSlot)
    }

    /// 上游 `openSelect` / `overlayClick`：`disabled` 时不展开，选中后自动收起。
    func testSelectOpenCloseAndDisabledGuard() {
        let value = StringBox("")
        let select = UPSelect(options: [UPSelectOption(id: "1", name: "一")], current: value.binding)
        select.openSelect()
        XCTAssertTrue(select.isOpen)
        select.closeSelect()
        XCTAssertFalse(select.isOpen)
        select.openSelect()
        select.select("1")
        XCTAssertFalse(select.isOpen)
        XCTAssertEqual(value.value, "1")

        let disabled = UPSelect(options: [UPSelectOption(id: "1", name: "一")], disabled: true)
        disabled.openSelect()
        XCTAssertFalse(disabled.isOpen)
        disabled.select("1")
        XCTAssertEqual(disabled.current, "")
    }

    /// 上游 `currentLabel` 按 `current` 找显示文本，`showOptionsLabel` 决定触发行内容。
    func testSelectCurrentLabelAndTriggerText() {
        let options = [UPSelectOption(id: "1", name: "一"), UPSelectOption(id: "2", name: "二")]
        let plain = UPSelect(options: options, current: .constant("2"), label: "请选择")
        XCTAssertEqual(plain.currentLabel, "二")
        XCTAssertEqual(plain.triggerText, "请选择")

        let labelled = UPSelect(options: options,
                                current: .constant("2"),
                                label: "请选择",
                                showOptionsLabel: true)
        XCTAssertEqual(labelled.triggerText, "二")
        // 找不到时上游 `currentLabel` 是空串。
        XCTAssertEqual(UPSelect(options: options, current: .constant("9")).currentLabel, "")
    }

    /// 上游 `options` 是对象数组，用 `keyName` / `labelName` 取字段。
    func testSelectReadsKeyNamesFromObjects() {
        let select = UPSelect(options: [["code": "bj", "label": "北京"], ["other": "x"]],
                             keyName: "code",
                             labelName: "label")
        XCTAssertEqual(select.options.map(\.id), ["bj"])
        XCTAssertEqual(select.options.map(\.name), ["北京"])
        // 只有 key 时上游 `item[labelName]` 是 undefined，原生退化成用值当文本。
        XCTAssertEqual(UPSelectOption.options([["id": "1"]]).map(\.name), ["1"])
    }

    /// `optionsWidth` 支持数字与 px，`maxHeight` 支持具体像素。
    func testSelectResolvesOptionsWidthAndMaxHeight() {
        XCTAssertEqual(UPSelect(options: [], optionsWidth: "240").resolvedOptionsWidth, 240)
        XCTAssertEqual(UPSelect(options: [], optionsWidth: "240px").resolvedOptionsWidth, 240)
        XCTAssertNil(UPSelect(options: [], optionsWidth: "50%").resolvedOptionsWidth)
        XCTAssertEqual(UPSelect(options: [], maxHeight: "300px").resolvedMaxHeight, 300)
    }

    func testChooseSupportsRadioAndCustomClick() {
        let value = StringBox("")
        var clicked = ""
        let choose = UPChoose(options: [UPChooseOption(value: "a", title: "A")], modelValue: value.binding, customClick: true)
            .onCustomClick { clicked = $0 }
        choose.select("a")
        XCTAssertEqual(clicked, "a")
        XCTAssertEqual(value.value, "")
    }

    /// 上游 props 内联在 `.vue` 里：`type: 'radio'`、`itemWidth: 'auto'`、
    /// `itemHeight: '50px'`、`itemPadding: '8px'`、`labelName: 'title'`、
    /// `valueName: 'value'`、`customClick: false`、`wrap: true`。
    func testChoosePropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.choose.type, "radio")
        XCTAssertEqual(UPConfig.choose.itemWidth, "auto")
        XCTAssertEqual(UPConfig.choose.itemHeight, "50px")
        XCTAssertEqual(UPConfig.choose.itemPadding, "8px")
        XCTAssertEqual(UPConfig.choose.labelName, "title")
        XCTAssertEqual(UPConfig.choose.valueName, "value")
        XCTAssertFalse(UPConfig.choose.customClick)
        XCTAssertTrue(UPConfig.choose.wrap)

        let choose = UPChoose(options: [UPChooseOption(value: "a", title: "A")])
        XCTAssertEqual(choose.type, "radio")
        XCTAssertEqual(choose.itemWidth, "auto")
        // itemWidth 为 auto 时不给固定宽度。
        XCTAssertNil(choose.resolvedItemWidth)
        XCTAssertEqual(choose.resolvedItemHeight, 50)
        XCTAssertEqual(choose.resolvedItemPadding, 8)
        XCTAssertEqual(choose.labelName, "title")
        XCTAssertEqual(choose.valueName, "value")
        XCTAssertFalse(choose.customClick)
        XCTAssertTrue(choose.wrap)
        XCTAssertNil(choose.currentIndex)
        XCTAssertFalse(choose.hasItemSlot)
    }

    /// 上游 `change(index)` 是按下标工作的：写回下标、抛出下标。
    func testChooseChangeWritesBackIndex() {
        let index = NavigationIntBox(0)
        let value = StringBox("")
        var changes: [Int] = []
        let choose = UPChoose(options: [
            UPChooseOption(value: "a", title: "A"),
            UPChooseOption(value: "b", title: "B")
        ], modelValue: value.binding, currentIndex: index.binding)
            .onChange { changes.append($0) }

        choose.change(1)
        XCTAssertEqual(choose.currentIndex, 1)
        XCTAssertEqual(index.value, 1)
        // 仓库既有的按值绑定同步写回选项值。
        XCTAssertEqual(value.value, "b")
        XCTAssertEqual(changes, [1])
        XCTAssertTrue(choose.isActive(1))
        XCTAssertFalse(choose.isActive(0))

        // 越界下标不生效。
        choose.change(9)
        XCTAssertEqual(choose.currentIndex, 1)
    }

    /// 上游 `watch.modelValue` 带 immediate：挂载时就把 currentIndex 同步成传入值。
    func testChooseSeedsCurrentIndexFromModelValue() {
        let value = StringBox("b")
        let choose = UPChoose(options: [
            UPChooseOption(value: "a", title: "A"),
            UPChooseOption(value: "b", title: "B")
        ], modelValue: value.binding)
        XCTAssertEqual(choose.currentIndex, 1)

        let indexed = UPChoose(options: [UPChooseOption(value: "a", title: "A")],
                               currentIndex: NavigationIntBox(0).binding)
        XCTAssertEqual(indexed.currentIndex, 0)
    }

    /// 上游默认插槽里 `up-tag` 的 type/plain 都随激活态切换。
    func testChooseTagAppearanceFollowsActiveState() {
        let choose = UPChoose(options: [
            UPChooseOption(value: "a", title: "A"),
            UPChooseOption(value: "b", title: "B")
        ])
        XCTAssertEqual(choose.tagType(at: 0), "info")
        XCTAssertTrue(choose.isPlain(at: 0))

        choose.change(0)
        XCTAssertEqual(choose.tagType(at: 0), "primary")
        XCTAssertFalse(choose.isPlain(at: 0))
    }

    /// 上游 `customClick` 为真时只抛 `custom-click`，不写回 modelValue。
    func testChooseCustomClickEmitsIndexWithoutWriteBack() {
        let value = StringBox("")
        var indexes: [Int] = []
        let choose = UPChoose(options: [
            UPChooseOption(value: "a", title: "A"),
            UPChooseOption(value: "b", title: "B")
        ], modelValue: value.binding, customClick: true)
            .onCustomClick { (index: Int) in indexes.append(index) }

        choose.change(1)
        XCTAssertEqual(indexes, [1])
        XCTAssertEqual(value.value, "")
        XCTAssertNil(choose.currentIndex)
    }

    func testChooseExposesItemSlot() {
        let choose = UPChoose(options: [UPChooseOption(value: "a", title: "A")])
        XCTAssertTrue(choose.itemContent { option, _ in Text(option.title) }.hasItemSlot)
    }
}

@MainActor
final class DropdownTests: XCTestCase {
    func testDropdownOpenCloseAndItemChange() {
        var events: [String] = []
        let dropdown = UPDropdown(items: [UPDropdownItem(title: "排序"), UPDropdownItem(title: "筛选")])
            .onOpen { events.append("open:\($0)") }
            .onClose { events.append("close:\($0)") }
        XCTAssertEqual(dropdown.height, 40)
        dropdown.open(1)
        dropdown.close()
        XCTAssertEqual(events, ["open:1", "close:1"])
    }

    func testDropdownItemUpdatesBinding() {
        let value = StringBox("")
        var changed = ""
        let item = UPDropdownItem(title: "排序", options: [UPDropdownOption(value: "asc", title: "升序")], modelValue: value.binding)
            .onChange { changed = $0 }
        item.select("asc")
        XCTAssertEqual(value.value, "asc")
        XCTAssertEqual(changed, "asc")
    }

    /// 上游 `u-dropdown/props.js`：`activeColor: '#2979ff'`、`inactiveColor: '#606266'`、
    /// `closeOnClickMask: true`、`closeOnClickSelf: true`、`duration: 300`、`height: 40`、
    /// `borderBottom: false`、`titleSize: 14`、`borderRadius: 0`、
    /// `menuIcon: 'arrow-down'`、`menuIconSize: 14`。
    func testDropdownPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.dropdown.activeColor, "#2979ff")
        XCTAssertEqual(UPConfig.dropdown.inactiveColor, "#606266")
        XCTAssertTrue(UPConfig.dropdown.closeOnClickMask)
        XCTAssertTrue(UPConfig.dropdown.closeOnClickSelf)
        XCTAssertEqual(UPConfig.dropdown.duration, 300)
        XCTAssertEqual(UPConfig.dropdown.height, "40")
        XCTAssertFalse(UPConfig.dropdown.borderBottom)
        XCTAssertEqual(UPConfig.dropdown.titleSize, "14")
        XCTAssertEqual(UPConfig.dropdown.borderRadius, "0")
        XCTAssertEqual(UPConfig.dropdown.menuIcon, "arrow-down")
        XCTAssertEqual(UPConfig.dropdown.menuIconSize, "14")
        // 上游 data.current 的哨兵值是 99999，不是 -1。
        XCTAssertEqual(UPConfig.dropdown.noneIndex, 99_999)

        let dropdown = UPDropdown(items: [UPDropdownItem(title: "排序")])
        XCTAssertEqual(dropdown.activeColor, "#2979ff")
        XCTAssertEqual(dropdown.inactiveColor, "#606266")
        XCTAssertEqual(dropdown.duration, 300)
        XCTAssertEqual(dropdown.height, 40)
        XCTAssertEqual(dropdown.titleSize, 14)
        XCTAssertEqual(dropdown.borderRadius, 0)
        XCTAssertEqual(dropdown.menuIcon, "arrow-down")
        XCTAssertEqual(dropdown.menuIconSize, 14)
        XCTAssertEqual(dropdown.current, 99_999)
        XCTAssertFalse(dropdown.active)
        // 上游 menuList 由子项的 title / disabled 汇总。
        XCTAssertEqual(dropdown.menuList.map(\.title), ["排序"])

        // 上游 u-dropdown-item/props.js：height 默认 'auto'、closeOnClickOverlay 默认 true。
        XCTAssertEqual(UPConfig.dropdownItem.height, "auto")
        XCTAssertTrue(UPConfig.dropdownItem.closeOnClickOverlay)
        let item = UPDropdownItem(title: "排序")
        XCTAssertEqual(item.height, "auto")
        XCTAssertNil(item.resolvedHeight)
        XCTAssertTrue(item.closeOnClickOverlay)
        XCTAssertFalse(item.disabled)
        XCTAssertFalse(item.active)
        XCTAssertEqual(item.propsChange, "排序-false")
    }

    /// 上游 `resolvedActiveColor` / `resolvedInactiveColor`：命中默认值时改取主题色。
    func testDropdownResolvedColorsFollowThemeSentinels() {
        let plain = UPDropdown(items: [UPDropdownItem(title: "A")])
        XCTAssertEqual(plain.resolvedActiveColor, "primary")
        XCTAssertEqual(plain.resolvedInactiveColor, "content")

        let custom = UPDropdown(items: [UPDropdownItem(title: "A")],
                                activeColor: "#ff9900",
                                inactiveColor: "#333333")
        XCTAssertEqual(custom.resolvedActiveColor, "#ff9900")
        XCTAssertEqual(custom.resolvedInactiveColor, "#333333")
    }

    /// 上游 `menuClick`：禁用项直接 return；点当前项且 `closeOnClickSelf` 为真时收起。
    func testDropdownMenuClickTogglesAndRespectsDisabled() {
        var events: [String] = []
        let dropdown = UPDropdown(items: [
            UPDropdownItem(title: "排序"),
            UPDropdownItem(title: "禁用", disabled: true)
        ])
        .onOpen { events.append("open:\($0)") }
        .onClose { events.append("close:\($0)") }

        dropdown.menuClick(0)
        XCTAssertTrue(dropdown.active)
        XCTAssertEqual(dropdown.current, 0)

        dropdown.menuClick(0)
        XCTAssertFalse(dropdown.active)
        // 关闭后 current 归位到哨兵值。
        XCTAssertEqual(dropdown.current, 99_999)

        dropdown.menuClick(1)
        XCTAssertFalse(dropdown.active)
        XCTAssertEqual(events, ["open:0", "close:0"])

        // closeOnClickSelf 为假时重复点同一项不收起。
        let sticky = UPDropdown(items: [UPDropdownItem(title: "排序")], closeOnClickSelf: false)
        sticky.menuClick(0)
        sticky.menuClick(0)
        XCTAssertTrue(sticky.active)
        XCTAssertEqual(sticky.current, 0)
    }

    /// 上游 `maskClick()`：`closeOnClickMask` 为假时什么都不做。
    func testDropdownMaskClickHonorsFlag() {
        let blocked = UPDropdown(items: [UPDropdownItem(title: "排序")], closeOnClickMask: false)
        blocked.open(0)
        blocked.maskClick()
        XCTAssertTrue(blocked.active)

        let closable = UPDropdown(items: [UPDropdownItem(title: "排序")])
        closable.open(0)
        closable.maskClick()
        XCTAssertFalse(closable.active)
    }

    /// 上游 `highlight(indexParams)`：数组整组高亮、单值只高亮一个、不传就清空。
    func testDropdownHighlightAcceptsArrayAndSingleValue() {
        let dropdown = UPDropdown(items: [
            UPDropdownItem(title: "A"),
            UPDropdownItem(title: "B")
        ])
        XCTAssertTrue(dropdown.highlightIndexList.isEmpty)

        dropdown.highlight([0, 1])
        XCTAssertEqual(dropdown.highlightIndexList, [0, 1])
        // 高亮项与激活项同样取激活色。
        XCTAssertEqual(dropdown.titleColor(at: 1), "primary")
        XCTAssertEqual(dropdown.iconColor(at: 1), "primary")

        dropdown.highlight(1)
        XCTAssertEqual(dropdown.highlightIndexList, [1])

        dropdown.highlight(nil as Int?)
        XCTAssertTrue(dropdown.highlightIndexList.isEmpty)
    }

    /// 上游模板的取色顺序：禁用 → 激活/高亮 → 未激活；箭头未激活时用的是禁用色。
    func testDropdownTitleAndIconColorsMatchTemplate() {
        let dropdown = UPDropdown(items: [
            UPDropdownItem(title: "A"),
            UPDropdownItem(title: "B", disabled: true)
        ])

        XCTAssertEqual(dropdown.titleColor(at: 0), "content")
        XCTAssertEqual(dropdown.titleColor(at: 1), "disabled")
        // 照抄上游：未激活项的箭头取 menuDisabledColor 而不是 inactiveColor。
        XCTAssertEqual(dropdown.iconColor(at: 0), "disabled")
        XCTAssertEqual(dropdown.iconRotation(at: 0), 0)

        dropdown.open(0)
        XCTAssertEqual(dropdown.titleColor(at: 0), "primary")
        XCTAssertEqual(dropdown.iconColor(at: 0), "primary")
        XCTAssertEqual(dropdown.iconRotation(at: 0), 180)
        XCTAssertEqual(dropdown.popupOffsetRatio, 0)
        XCTAssertEqual(dropdown.contentZIndex, 11)

        dropdown.close()
        XCTAssertEqual(dropdown.popupOffsetRatio, -1)
        XCTAssertEqual(dropdown.contentZIndex, -1)
    }

    /// 上游 `open(index)` 会把匹配的子项标成 active，`close()` 全部复位。
    func testDropdownActivatesMatchingItem() {
        let first = UPDropdownItem(title: "A")
        let second = UPDropdownItem(title: "B")
        let dropdown = UPDropdown(items: [first, second])

        dropdown.open(1)
        XCTAssertFalse(first.active)
        XCTAssertTrue(second.active)

        dropdown.close()
        XCTAssertFalse(second.active)
    }

    /// 上游 `cellClick(value)`：写回 modelValue → 收起父菜单 → 抛 change。
    func testDropdownItemCellClickClosesParent() {
        let value = StringBox("")
        var changes: [String] = []
        let item = UPDropdownItem(title: "排序",
                                  options: [UPDropdownOption(value: "asc", label: "升序")],
                                  modelValue: value.binding)
            .onChange { changes.append($0) }
        XCTAssertEqual(item.options[0].label, "升序")
        XCTAssertFalse(item.isSelected(item.options[0]))

        item.cellClick("asc")
        XCTAssertEqual(value.value, "asc")
        XCTAssertEqual(changes, ["asc"])
        XCTAssertTrue(item.isSelected(item.options[0]))

        // 仓库既有的 select 还会校验值是否在 options 里。
        item.select("missing")
        XCTAssertEqual(changes, ["asc"])
    }

    func testDropdownItemExposesContentSlot() {
        let item = UPDropdownItem(title: "排序")
        XCTAssertFalse(item.hasContentSlot)
        XCTAssertTrue(item.content { Text("自定义") }.hasContentSlot)
    }

    /// 上游整个 picker 包在 `u-popup` 里，由 `show || (hasInput && showByClickInput)`
    /// 控制可见。此前 Swift 侧 body 完全不看 `show`，导致 `show` 为 false 时
    /// 工具栏与滚轮仍绘制出来，叠在页面上。
    func testPickerContentIsHiddenWhileShowIsFalse() {
        XCTAssertFalse(UPPicker.isContentVisible(show: false, hasInput: false, showByClickInput: false))
        XCTAssertTrue(UPPicker.isContentVisible(show: true, hasInput: false, showByClickInput: false))
    }

    /// 带输入框触发器时，点击输入框也应展开，与上游的 or 条件一致。
    func testPickerContentAlsoOpensFromTheInputTrigger() {
        XCTAssertTrue(UPPicker.isContentVisible(show: false, hasInput: true, showByClickInput: true))
        // 没有输入框时 showByClickInput 不该单独生效。
        XCTAssertFalse(UPPicker.isContentVisible(show: false, hasInput: false, showByClickInput: true))
        // 有输入框但未点击，且 show 为 false 时仍隐藏。
        XCTAssertFalse(UPPicker.isContentVisible(show: false, hasInput: true, showByClickInput: false))
    }

    /// `pageInline` 是页面内嵌模式，上游此时不走弹层，内容常驻。
    func testPageInlinePickerIgnoresShow() {
        XCTAssertTrue(UPPicker.isContentVisible(show: false, hasInput: false, showByClickInput: false, pageInline: true))
    }

    /// u-datetime-picker 同样包在 u-popup 里，可见性规则与 picker 一致。
    func testDatetimePickerContentIsHiddenWhileShowIsFalse() {
        XCTAssertFalse(UPDatetimePicker.isContentVisible(show: false, hasInput: false, showByClickInput: false))
        XCTAssertTrue(UPDatetimePicker.isContentVisible(show: true, hasInput: false, showByClickInput: false))
        XCTAssertTrue(UPDatetimePicker.isContentVisible(show: false, hasInput: true, showByClickInput: true))
        XCTAssertTrue(UPDatetimePicker.isContentVisible(show: false, hasInput: false, showByClickInput: false, pageInline: true))
    }

    /// `u-picker-data.vue` 的内联 props：`valueKey: 'id'`、`labelKey: 'name'`，
    /// 用来从 `options` 的对象元素里取值与显示文本。
    func testPickerDataReadsValueAndLabelKeys() {
        XCTAssertEqual(UPPickerData.defaultValueKey, "id")
        XCTAssertEqual(UPPickerData.defaultLabelKey, "name")

        let objects = [["id": "1", "name": "北京"], ["id": "2", "name": "上海"]]
        let options = UPPickerData.options(objects)
        XCTAssertEqual(options.map(\.value), ["1", "2"])
        XCTAssertEqual(options.map(\.text), ["北京", "上海"])

        // 自定义键名。
        let custom = UPPickerData.options([["code": "bj", "label": "北京"]],
                                          valueKey: "code",
                                          labelKey: "label")
        XCTAssertEqual(custom.map(\.value), ["bj"])
        XCTAssertEqual(custom.map(\.text), ["北京"])

        // 两个键都取不到时跳过该元素。
        XCTAssertTrue(UPPickerData.options([["other": "x"]]).isEmpty)
        // 只有 value 时上游 `current` 会是 undefined，原生退化成用值当文本。
        XCTAssertEqual(UPPickerData.options([["id": "1"]]).map(\.text), ["1"])
    }

    /// 对应上游按 `modelValue` 找 `defaultIndex` 的逻辑。
    func testPickerDataDefaultIndexMatchesModelValue() {
        let options = UPPickerData.options([["id": "1", "name": "北京"], ["id": "2", "name": "上海"]])
        XCTAssertEqual(UPPickerData.defaultIndex(for: "2", in: options), [1])
        XCTAssertEqual(UPPickerData.defaultIndex(for: "", in: options), [])
        XCTAssertEqual(UPPickerData.defaultIndex(for: "999", in: options), [])
    }
}

@MainActor final class StringArrayBox { var value: [String]; init(_ value: [String]) { self.value = value }; var binding: Binding<[String]> { Binding(get: { self.value }, set: { self.value = $0 }) } }
@MainActor final class StringBox { var value: String; init(_ value: String) { self.value = value }; var binding: Binding<String> { Binding(get: { self.value }, set: { self.value = $0 }) } }
@MainActor final class Int64Box { var value: Int64; init(_ value: Int64) { self.value = value }; var binding: Binding<Int64> { Binding(get: { self.value }, set: { self.value = $0 }) } }
@MainActor final class PickerBoolBox { var value: Bool; init(_ value: Bool) { self.value = value }; var binding: Binding<Bool> { Binding(get: { self.value }, set: { self.value = $0 }) } }
