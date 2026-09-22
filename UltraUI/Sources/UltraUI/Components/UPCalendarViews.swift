import SwiftUI

/// 对应上游 `u-calendar/header.vue`：标题、带切换箭头的副标题、星期行。
@MainActor
struct UPCalendarHeader: View {
    let calendar: UPCalendar
    @Environment(\.upTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            if calendar.showTitle {
                Text(calendar.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.main)
                    .frame(height: 50)
            }

            if calendar.showSubtitle {
                HStack(spacing: 4) {
                    if calendar.monthSwitch {
                        switchButton("«", disabled: calendar.switchPrevYearDisabled) { calendar.prevYear() }
                        switchButton("‹", disabled: calendar.switchPrevDisabled) { calendar.prevMonth() }
                    }

                    Text(calendar.subtitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.main)

                    if calendar.monthSwitch {
                        switchButton("›", disabled: calendar.switchNextDisabled) { calendar.nextMonth() }
                        switchButton("»", disabled: calendar.switchNextYearDisabled) { calendar.nextYear() }
                    }

                    if calendar.showToday {
                        Text("今天")
                            .font(.system(size: 13))
                            .foregroundStyle(UPColor.parse(calendar.color, theme: theme))
                            .opacity(calendar.todayDisabled ? 0.35 : 1)
                            .contentShape(Rectangle())
                            .onTapGesture { calendar.jumpToToday() }
                    }
                }
                .frame(height: 30)
            }

            HStack(spacing: 0) {
                ForEach(Array(calendar.weekText.enumerated()), id: \.offset) { _, text in
                    Text(text)
                        .font(.system(size: 13))
                        .foregroundStyle(theme.main)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 30)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottom) { Rectangle().fill(theme.border).frame(height: 0.5) }
    }

    private func switchButton(_ label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Text(label)
            .font(.system(size: 18))
            .foregroundStyle(theme.main)
            .opacity(disabled ? 0.35 : 1)
            .frame(width: 28, height: 30)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }
}

/// 对应上游 `enableTime` 时的 `.u-calendar__time-panel`。
@MainActor
struct UPCalendarTimePanel: View {
    let calendar: UPCalendar
    @Environment(\.upTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            if calendar.mode == .single {
                row(label: calendar.selectedDates.first.map { UPCalendarFormat.dateText($0) } ?? "--",
                    time: calendar.singleTime,
                    target: "single")
            } else {
                row(label: calendar.selectedDates.first.map { UPCalendarFormat.dateText($0) } ?? "--",
                    time: calendar.rangeStartTime,
                    target: "start")
                row(label: calendar.selectedDates.count >= 2
                        ? UPCalendarFormat.dateText(calendar.selectedDates[calendar.selectedDates.count - 1])
                        : "--",
                    time: calendar.rangeEndTime,
                    target: "end")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .sheet(isPresented: calendar.timePickerShowBinding) { timePicker }
    }

    private func row(label: String, time: String, target: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(theme.content)
            Spacer(minLength: 0)
            Text(time)
                .font(.system(size: 14))
                .foregroundStyle(UPColor.parse(calendar.color, theme: theme))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(theme.bg)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .contentShape(Rectangle())
                .onTapGesture { calendar.openTimePicker(target) }
        }
        .frame(height: 36)
    }

    /// 上游用 `picker-view` 三列时分秒，原生用 `Picker` 轮盘。
    private var timePicker: some View {
        UPCalendarTimeSheet(calendar: calendar)
    }
}

/// 时间选择弹层。
@MainActor
struct UPCalendarTimeSheet: View {
    let calendar: UPCalendar
    @Environment(\.dismiss) private var dismiss
    @State private var hour = 0
    @State private var minute = 0
    @State private var second = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("取消").onTapGesture { dismiss() }
                Spacer()
                Text("选择时间").font(.system(size: 16, weight: .medium))
                Spacer()
                Text("确定").onTapGesture {
                    calendar.setTime(UPCalendarFormat.timeText(hour: hour,
                                                              minute: minute,
                                                              second: second,
                                                              precision: calendar.timePrecision),
                                     for: calendar.timePickerTarget)
                    dismiss()
                }
            }
            .font(.system(size: 14))
            .padding(16)

            HStack(spacing: 0) {
                column(range: 0..<24, selection: $hour)
                if calendar.timePrecision != "hour" { column(range: 0..<60, selection: $minute) }
                if calendar.timePrecision == "second" { column(range: 0..<60, selection: $second) }
            }
        }
        .onAppear(perform: seed)
        .presentationDetents([.height(300)])
    }

    private func column(range: Range<Int>, selection: Binding<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(Array(range), id: \.self) { value in
                Text(UPCalendarFormat.padTime(value)).tag(value)
            }
        }
        #if os(iOS)
        .pickerStyle(.wheel)
        #endif
        .frame(maxWidth: .infinity)
    }

    private func seed() {
        let current: String
        switch calendar.timePickerTarget {
        case "start": current = calendar.rangeStartTime
        case "end": current = calendar.rangeEndTime
        default: current = calendar.singleTime
        }
        let parsed = UPCalendarFormat.parseTime(current)
        hour = parsed.hour
        minute = parsed.minute
        second = parsed.second
    }
}

/// 对应上游 `u-calendar/month.vue`：多月网格，`monthSwitch` 时只渲染当前月。
@MainActor
struct UPCalendarMonthList: View {
    let calendar: UPCalendar
    @Environment(\.upTheme) private var theme

    var body: some View {
        Group {
            if calendar.monthSwitch {
                monthStack
            } else {
                ScrollView { monthStack }
            }
        }
        .frame(height: calendar.listHeight)
    }

    private var monthStack: some View {
        VStack(spacing: 0) {
            ForEach(Array(calendar.currentMonths.enumerated()), id: \.element.id) { index, month in
                // 上游第一个月不显示月份标题（副标题已经展示）。
                if index != 0 || calendar.monthSwitch {
                    Text(UPCalendarFormat.monthTitle(year: month.year,
                                                    month: month.month,
                                                    format: calendar.monthFormat))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.main)
                        .frame(height: 42)
                }
                UPCalendarMonthGrid(calendar: calendar, month: month)
            }
        }
    }
}

/// 单个月的 7 列网格。
@MainActor
struct UPCalendarMonthGrid: View {
    let calendar: UPCalendar
    let month: UPCalendarMonth
    @Environment(\.upTheme) private var theme

    /// 上游用 `marginLeft` 把每月第一天推到对应星期；周一是第一列。
    private var leadingBlanks: Int {
        guard let first = month.days.first else { return 0 }
        return (first.week == 1 ? 7 : first.week - 1) - 1
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
            ForEach(Array(0..<leadingBlanks), id: \.self) { _ in
                Color.clear.frame(height: calendar.rowHeight)
            }
            ForEach(Array(month.days.enumerated()), id: \.offset) { _, day in
                cell(day)
            }
        }
        // 上游 `showMark` 在月份区域中间放一个大号月份水印。
        .background(alignment: .center) {
            if calendar.showMark {
                Text(String(month.month))
                    .font(.system(size: 130))
                    .foregroundStyle(theme.border.opacity(0.3))
            }
        }
    }

    private func cell(_ day: UPCalendarDay) -> some View {
        let selected = calendar.isSelected(day.date)
        let forbidden = calendar.isForbidden(day.date)
        let isToday = Calendar.current.isDateInToday(day.date)
        let inRange = isBetweenRangeEnds(day.date)
        let themeColor = UPColor.parse(calendar.color, theme: theme)
        return VStack(spacing: 2) {
            Text(String(day.day))
                .font(.system(size: 16))
            let info = calendar.bottomInfo(for: day)
            if !info.isEmpty {
                Text(info).font(.system(size: 10))
            }
            if day.dot {
                Circle().fill(theme.error).frame(width: 5, height: 5)
            }
        }
        .foregroundStyle(textColor(selected: selected, inRange: inRange, isToday: isToday, themeColor: themeColor))
        .frame(maxWidth: .infinity)
        .frame(height: calendar.rowHeight)
        .background {
            if selected {
                RoundedRectangle(cornerRadius: 3).fill(themeColor)
            } else if inRange {
                // 上游把主题色与卡片底色做 100 等分后取第 90 档，再叠 0.7 透明度。
                RoundedRectangle(cornerRadius: 0).fill(themeColor.opacity(0.12))
            }
        }
        .overlay {
            if calendar.showToday, isToday, !selected {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(UPColor.parse(calendar.resolvedTodayColor, theme: theme), lineWidth: 1)
            }
        }
        .opacity(day.disabled || forbidden ? 0.4 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !day.disabled else { return }
            calendar.select(day.date)
        }
    }

    private func isBetweenRangeEnds(_ date: Date) -> Bool {
        guard calendar.mode == .range,
              calendar.selectedDates.count >= 2,
              let first = calendar.selectedDates.first,
              let last = calendar.selectedDates.last else { return false }
        let day = Calendar.current.startOfDay(for: date)
        return day > first && day < last
    }

    private func textColor(selected: Bool, inRange: Bool, isToday: Bool, themeColor: Color) -> Color {
        if selected { return .white }
        if inRange { return themeColor }
        if calendar.showToday, isToday {
            return UPColor.parse(calendar.resolvedTodayColor, theme: theme)
        }
        return theme.main
    }
}
