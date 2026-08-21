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
