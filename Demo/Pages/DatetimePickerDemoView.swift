import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsA/datetimePicker/datetimePicker`。
struct DatetimePickerDemoView: View {
    @State private var showDate = false
    @State private var showDatetime = false
    @State private var showTime = false
    @State private var dateValue: Int64 = 1_610_513_121_000
    @State private var datetimeValue: Int64 = 1_610_513_121_000
    @State private var timeValue = "09:30"

    var body: some View {
        ZStack {
            DemoPage {
                DemoSection("日期 date") {
                    UPButton(type: "primary", text: "选择日期") { showDate = true }
                }

                DemoSection("日期时间 datetime") {
                    UPButton(type: "primary", text: "选择日期时间") { showDatetime = true }
                }

                DemoSection("时间 time") {
                    UPButton(type: "primary", text: "选择时间") { showTime = true }
                    Text("当前：\(timeValue)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            UPDatetimePicker(modelValue: $dateValue, show: $showDate, title: "选择日期", mode: "date")

            UPDatetimePicker(
                modelValue: $datetimeValue,
                show: $showDatetime,
                title: "选择日期时间",
                mode: "datetime"
            )

            UPDatetimePicker(modelValue: $timeValue, show: $showTime, title: "选择时间", mode: "time")
        }
    }
}
