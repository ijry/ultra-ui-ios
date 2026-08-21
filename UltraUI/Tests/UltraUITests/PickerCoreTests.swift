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

    func testChooseSupportsRadioAndCustomClick() {
        let value = StringBox("")
        var clicked = ""
        let choose = UPChoose(options: [UPChooseOption(value: "a", title: "A")], modelValue: value.binding, customClick: true)
            .onCustomClick { clicked = $0 }
        choose.select("a")
        XCTAssertEqual(clicked, "a")
        XCTAssertEqual(value.value, "")
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
}

@MainActor final class StringArrayBox { var value: [String]; init(_ value: [String]) { self.value = value }; var binding: Binding<[String]> { Binding(get: { self.value }, set: { self.value = $0 }) } }
@MainActor final class StringBox { var value: String; init(_ value: String) { self.value = value }; var binding: Binding<String> { Binding(get: { self.value }, set: { self.value = $0 }) } }
@MainActor final class Int64Box { var value: Int64; init(_ value: Int64) { self.value = value }; var binding: Binding<Int64> { Binding(get: { self.value }, set: { self.value = $0 }) } }
@MainActor final class PickerBoolBox { var value: Bool; init(_ value: Bool) { self.value = value }; var binding: Binding<Bool> { Binding(get: { self.value }, set: { self.value = $0 }) } }
