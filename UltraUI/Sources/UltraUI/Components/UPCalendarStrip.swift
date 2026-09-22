import Foundation
import Observation
import SwiftUI

/// SwiftUI 的 `View` 必须是值类型，可变的选中态与展开态放在这个小引用盒里。
@MainActor
@Observable
private final class UPCalendarStripState {
    var selectedDate: Date?
    /// 对应上游 `currentMonth`（`YYYY-MM`），原生存该月 1 日 0 点。
    var month: Date
    /// 对应上游 `innerShowFull`。
    var showsFullCalendar: Bool

    init(selectedDate: Date?, month: Date, showsFullCalendar: Bool) {
        self.selectedDate = selectedDate
        self.month = month
        self.showsFullCalendar = showsFullCalendar
    }
}

/// Native SwiftUI counterpart of uview-plus `u-calendar-strip`.
///
/// 上游只渲染「当前月」的日期，日期列表由 `currentMonth` 推导；本组件保留了
/// 仓库既有的 `dates` + `current` 显式列表模式（下称列表模式），两者共存：
/// `dates` 非空时按列表渲染，为空时按上游的月份模式渲染。
@MainActor
public struct UPCalendarStrip: View {
    /// 上游 `modelValue`，`String | Number | Date | null`，原生只收 `Date`。
    public var modelValue: Binding<Date?>?
    /// 上游用 `0` 表示不限制，原生用 `nil`。月份模式下按天比较，因此构造时
    /// 会把边界规整到当天 0 点；列表模式保留调用方给的精确时间点。
    public let minDate: Date?
    public let maxDate: Date?
    public let color: String
    /// 上游 `weekText`，从周一开始，对应 `t('up.week.one')`…`t('up.week.seven')`。
    public let weekText: [String]
    public let fullCalendar: Bool
    /// 上游 `v-bind="fullCalendarProps"` 把整个对象透传给 `u-calendar`，
    /// 原生没有属性展开，保留为兼容元数据（与 `UPImage.webp` 同样处理）。
    public let fullCalendarProps: [String: String]
    public let fullMonthNum: Int
    public let pullDownThreshold: CGFloat
    public let collapseAfterSelect: Bool
    public let readonly: Bool
    public let showToday: Bool
    /// dayjs 格式串；为空时中文环境取 `YYYY年MM月`，其他取 `MM/YYYY`。
    public let monthFormat: String
    public let expandHint: String
    public let collapseHint: String

    /// 原生扩展：显式日期列表与下标绑定。
    public var dates: [Date]
    public var current: Binding<Int>?
    /// 原生扩展：按精确时间点禁用，上游只有 `minDate` / `maxDate`。
    public let disabledDates: Set<Date>

    @State private var state: UPCalendarStripState
    @Environment(\.upTheme) private var theme
    private var onChangeHandler: ((Int, Date) -> Void)?
    private var onChangePayloadHandler: ((UPCalendarStripChange) -> Void)?
    private var onConfirmHandler: ((UPCalendarStripChange) -> Void)?
    private var onMonthChangeHandler: ((UPCalendarStripMonthChange) -> Void)?
    private var onToggleFullHandler: ((UPCalendarStripToggle) -> Void)?

    private let calendar = Calendar.current

    /// 仓库既有的列表模式初始化器。
    public init(dates: [Date] = [], current: Binding<Int>? = nil, onChange: ((Int, Date) -> Void)? = nil) {
        self.init(dates: dates,
                  current: current,
                  modelValue: nil,
                  minDate: nil,
                  maxDate: nil,
                  readonly: UPConfig.calendarStrip.readonly,
                  disabledDates: [],
                  clampsBoundsToDay: false)
        self.onChangeHandler = onChange
    }

    /// 仓库既有的日期绑定模式初始化器。
    public init(dates: [Date] = [], modelValue: Binding<Date?>? = nil, minDate: Date? = nil,
                maxDate: Date? = nil, disabledDates: [Date] = [], readonly: Bool = false,
                onChange: ((UPCalendarStripChange) -> Void)? = nil) {
        self.init(dates: dates,
                  current: nil,
                  modelValue: modelValue,
                  minDate: minDate,
                  maxDate: maxDate,
                  readonly: readonly,
                  disabledDates: Set(disabledDates),
                  clampsBoundsToDay: false)
        self.onChangePayloadHandler = onChange
    }

    /// 与上游 `props.js` 对齐的初始化器。
    public init(modelValue: Binding<Date?>? = nil,
                minDate: Date? = UPConfig.calendarStrip.minDate,
                maxDate: Date? = UPConfig.calendarStrip.maxDate,
                color: String = UPConfig.calendarStrip.color,
                weekText: [String] = UPConfig.calendarStrip.weekText,
                fullCalendar: Bool = UPConfig.calendarStrip.fullCalendar,
                fullCalendarProps: [String: String] = UPConfig.calendarStrip.fullCalendarProps,
                fullMonthNum: some UPImageUnitValue = UPConfig.calendarStrip.fullMonthNum,
                pullDownThreshold: some UPImageUnitValue = UPConfig.calendarStrip.pullDownThreshold,
                collapseAfterSelect: Bool = UPConfig.calendarStrip.collapseAfterSelect,
                readonly: Bool = UPConfig.calendarStrip.readonly,
                showToday: Bool = UPConfig.calendarStrip.showToday,
                monthFormat: String = UPConfig.calendarStrip.monthFormat,
                expandHint: String = UPConfig.calendarStrip.expandHint,
                collapseHint: String = UPConfig.calendarStrip.collapseHint,
                disabledDates: [Date] = [],
                onChange: ((UPCalendarStripChange) -> Void)? = nil) {
        self.init(dates: [],
                  current: nil,
                  modelValue: modelValue,
                  minDate: minDate,
                  maxDate: maxDate,
                  color: color,
                  weekText: weekText,
                  fullCalendar: fullCalendar,
                  fullCalendarProps: fullCalendarProps,
                  fullMonthNum: max(1, Int(UPUnit.parse(fullMonthNum.upImageUnitValue))),
                  pullDownThreshold: UPUnit.parse(pullDownThreshold.upImageUnitValue),
                  collapseAfterSelect: collapseAfterSelect,
                  readonly: readonly,
                  showToday: showToday,
                  monthFormat: monthFormat,
                  expandHint: expandHint,
                  collapseHint: collapseHint,
                  disabledDates: Set(disabledDates),
                  clampsBoundsToDay: true)
        self.onChangePayloadHandler = onChange
    }

    private init(dates: [Date],
                 current: Binding<Int>?,
                 modelValue: Binding<Date?>?,
                 minDate: Date?,
                 maxDate: Date?,
                 color: String = UPConfig.calendarStrip.color,
                 weekText: [String] = UPConfig.calendarStrip.weekText,
                 fullCalendar: Bool = UPConfig.calendarStrip.fullCalendar,
                 fullCalendarProps: [String: String] = UPConfig.calendarStrip.fullCalendarProps,
                 fullMonthNum: Int = UPConfig.calendarStrip.fullMonthNum,
                 pullDownThreshold: CGFloat = UPConfig.calendarStrip.pullDownThreshold,
                 collapseAfterSelect: Bool = UPConfig.calendarStrip.collapseAfterSelect,
                 readonly: Bool,
                 showToday: Bool = UPConfig.calendarStrip.showToday,
                 monthFormat: String = UPConfig.calendarStrip.monthFormat,
                 expandHint: String = UPConfig.calendarStrip.expandHint,
                 collapseHint: String = UPConfig.calendarStrip.collapseHint,
                 disabledDates: Set<Date>,
                 clampsBoundsToDay: Bool) {
        let calendar = Calendar.current
        self.dates = dates
        self.current = current
        self.modelValue = modelValue
        self.minDate = clampsBoundsToDay ? minDate.map { calendar.startOfDay(for: $0) } : minDate
        self.maxDate = clampsBoundsToDay ? maxDate.map { calendar.startOfDay(for: $0) } : maxDate
        self.color = color
        self.weekText = weekText
        self.fullCalendar = fullCalendar
        self.fullCalendarProps = fullCalendarProps
        self.fullMonthNum = max(1, fullMonthNum)
        self.pullDownThreshold = pullDownThreshold > 0 ? pullDownThreshold : 40
        self.collapseAfterSelect = collapseAfterSelect
        self.readonly = readonly
        self.showToday = showToday
        self.monthFormat = monthFormat
        self.expandHint = expandHint
        self.collapseHint = collapseHint
        self.disabledDates = disabledDates
        // 上游 `watch.modelValue` 是 immediate 的：没给值时落到今天，且不回写 modelValue。
        let seed: Date? = dates.isEmpty
            ? Self.clamped(modelValue?.wrappedValue ?? Date(),
                           minDate: self.minDate,
                           maxDate: self.maxDate,
                           calendar: calendar)
            : modelValue?.wrappedValue
        let anchor = seed ?? modelValue?.wrappedValue ?? dates.first ?? Date()
        self._state = State(initialValue: UPCalendarStripState(
            selectedDate: seed,
            month: Self.startOfMonth(anchor, calendar: calendar),
            showsFullCalendar: false
        ))
    }

    // MARK: - 状态

    /// 列表模式：`dates` 非空。
    public var isListMode: Bool { !dates.isEmpty }

    public var selectedIndex: Int {
        if let value = modelValue?.wrappedValue, let index = dates.firstIndex(of: value) { return index }
        return min(max(current?.wrappedValue ?? 0, 0), max(dates.count - 1, 0))
    }

    public var selectedDate: Date? {
        if isListMode { return dates.indices.contains(selectedIndex) ? dates[selectedIndex] : nil }
        return modelValue?.wrappedValue ?? state.selectedDate
    }

    /// 对应上游 `currentMonth`。
    public var currentMonth: Date { state.month }

    /// 对应上游 `innerShowFull`。
    public var showsFullCalendar: Bool { state.showsFullCalendar }

    /// 对应上游 `monthLabel`。
    public var monthLabel: String {
        Self.monthLabel(for: currentMonth, format: monthFormat, calendar: calendar)
    }

    /// 对应上游 `pullHintText`。上游模板只用到了 `collapseHint`，
    /// `expandHint` 仅在这个计算属性里出现，故一并暴露给宿主使用。
    public var pullHintText: String { showsFullCalendar ? collapseHint : expandHint }

    /// 对应上游 `monthDays`：列表模式直接用 `dates`。
    public var monthDays: [UPCalendarStripDay] {
        let today = Date()
        let selected = selectedDate
        let source: [Date] = isListMode ? dates : Self.days(inMonth: currentMonth, calendar: calendar)
        return source.map { date in
            UPCalendarStripDay(date: date,
                               day: calendar.component(.day, from: date),
                               weekday: calendar.component(.weekday, from: date),
                               disabled: !isSelectable(date),
                               // 列表模式的日期可以是同一天里的多个时间点，只能按精确值比较。
                               selected: selected.map {
                                   isListMode ? $0 == date : calendar.isDate($0, inSameDayAs: date)
                               } ?? false,
                               today: calendar.isDate(date, inSameDayAs: today))
        }
    }

    /// 对应上游 `switchPrevDisabled`。
    public var switchPrevDisabled: Bool {
        guard let minDate else { return false }
        return currentMonth <= Self.startOfMonth(minDate, calendar: calendar)
    }

    /// 对应上游 `switchNextDisabled`。
    public var switchNextDisabled: Bool {
        guard let maxDate else { return false }
        return currentMonth >= Self.startOfMonth(maxDate, calendar: calendar)
    }

    /// 对应上游 `panelMinDate`：没有 `minDate` 时以当前月为轴向前推 `fullMonthNum - 1` 个月。
    public var panelMinDate: Date {
        if let minDate { return minDate }
        return calendar.date(byAdding: .month, value: -(fullMonthNum - 1), to: currentMonth) ?? currentMonth
    }

    /// 对应上游 `panelMaxDate`。
    public var panelMaxDate: Date {
        if let maxDate { return maxDate }
        let start = calendar.date(byAdding: .month, value: fullMonthNum - 1, to: currentMonth) ?? currentMonth
        return Self.endOfMonth(start, calendar: calendar)
    }

    /// 对应上游 `panelMonthNum`。
    public var panelMonthNum: Int {
        let components = calendar.dateComponents([.month], from: Self.startOfMonth(panelMinDate, calendar: calendar),
                                                to: Self.startOfMonth(panelMaxDate, calendar: calendar))
        return max(1, (components.month ?? 0) + 1)
    }

    /// 对应上游 `isDateDisabled` 的反面；`disabledDates` 是原生扩展，按精确时间点比较。
    public func isSelectable(_ date: Date) -> Bool {
        if let minDate, date < minDate { return false }
        if let maxDate, date > maxDate { return false }
        return !disabledDates.contains(date)
    }

    /// 对应上游 `getWeekLabel`：`weekText` 从周一开始，周日排在末位。
    public func weekLabel(for weekday: Int) -> String {
        let index = weekday == 1 ? 6 : weekday - 2
        return weekText.indices.contains(index) ? weekText[index] : ""
    }

    // MARK: - 事件

    public func onChange(_ action: @escaping (Int, Date) -> Void) -> UPCalendarStrip {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    public func onChangePayload(_ action: @escaping (UPCalendarStripChange) -> Void) -> UPCalendarStrip {
        var copy = self
        copy.onChangePayloadHandler = action
        return copy
    }

    /// 上游 `confirm` 与 `change` 同时抛出、负载一致。
    public func onConfirm(_ action: @escaping (UPCalendarStripChange) -> Void) -> UPCalendarStrip {
        var copy = self
        copy.onConfirmHandler = action
        return copy
    }

    public func onMonthChange(_ action: @escaping (UPCalendarStripMonthChange) -> Void) -> UPCalendarStrip {
        var copy = self
        copy.onMonthChangeHandler = action
        return copy
    }

    public func onToggleFull(_ action: @escaping (UPCalendarStripToggle) -> Void) -> UPCalendarStrip {
        var copy = self
        copy.onToggleFullHandler = action
        return copy
    }

    // MARK: - 行为

    /// 列表模式的按下标选择。
    public func select(_ index: Int) {
        guard !readonly, dates.indices.contains(index), isSelectable(dates[index]) else { return }
        let date = dates[index]
        current?.wrappedValue = index
        apply(date, scene: "tap")
        onChangeHandler?(index, date)
    }

    /// 对应上游 `setSelectedDate(date, 'tap')`。
    public func select(_ date: Date) {
        guard !readonly else { return }
        if isListMode, let index = dates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
            select(index)
            return
        }
        apply(date, scene: "tap")
    }

    /// 对应上游 `switchMonth`。
    public func switchMonth(_ step: Int) {
        guard step != 0 else { return }
        if step < 0, switchPrevDisabled { return }
        if step > 0, switchNextDisabled { return }
        guard let target = calendar.date(byAdding: .month, value: step, to: currentMonth) else { return }
        let days = calendar.range(of: .day, in: .month, for: target)?.count ?? 28
        let day = min(calendar.component(.day, from: selectedDate ?? Date()), days)
        var components = calendar.dateComponents([.year, .month], from: target)
        components.day = day
        let candidate = calendar.date(from: components).flatMap { clamped($0) }
        if let candidate,
           calendar.isDate(candidate, equalTo: target, toGranularity: .month),
           isSelectable(candidate) {
            apply(candidate, scene: "switch")
        } else if let fallback = firstEnabledDate(inMonth: target) {
            apply(fallback, scene: "switch")
        }
    }

    public func prevMonth() { switchMonth(-1) }

    public func nextMonth() { switchMonth(1) }

    /// 对应上游 `toggleFull(source)`。
    public func toggleFull(source: String = "button") {
        setFullVisible(!showsFullCalendar, source: source)
    }

    /// 对应上游 `setFullVisible(show, source)`：`fullCalendar` 为假时不响应。
    public func setFullVisible(_ show: Bool, source: String = "button") {
        guard fullCalendar, showsFullCalendar != show else { return }
        state.showsFullCalendar = show
        onToggleFullHandler?(UPCalendarStripToggle(show: show, source: source))
    }

    /// 对应上游 `onPanelConfirm`：月历里确认后按 `collapseAfterSelect` 自动收起。
    public func confirmFromFullCalendar(_ date: Date) {
        apply(date, scene: "full")
        if collapseAfterSelect { setFullVisible(false, source: "auto") }
    }

    /// 对应上游 `clampDate`。
    public func clamped(_ date: Date) -> Date? {
        Self.clamped(date, minDate: minDate, maxDate: maxDate, calendar: calendar)
    }

    /// 对应上游 `findFirstEnabledDate`。
    public func firstEnabledDate(inMonth month: Date) -> Date? {
        Self.days(inMonth: month, calendar: calendar).first { isSelectable($0) }
    }

    /// 对应上游 `setSelectedDate` 的主体。
    private func apply(_ date: Date, scene: String) {
        guard let next = clamped(date), isSelectable(next) else { return }
        let previousDate = selectedDate
        let previousMonth = currentMonth
        state.selectedDate = next
        state.month = Self.startOfMonth(next, calendar: calendar)
        // 上游只在日期真的变了才 `$emit('update:modelValue')`；它按天比较（值是
        // `YYYY-MM-DD` 字符串），原生按精确时间点比较，列表模式下同一天里的多个
        // 时间点才能正确回写。
        if previousDate != next { modelValue?.wrappedValue = next }
        let payload = UPCalendarStripChange(date: next, scene: scene, calendar: calendar)
        onChangePayloadHandler?(payload)
        onConfirmHandler?(payload)
        if Self.startOfMonth(previousMonth, calendar: calendar) != payload.month {
            onMonthChangeHandler?(UPCalendarStripMonthChange(month: payload.month, scene: scene))
        }
    }

    // MARK: - 纯函数工具

    nonisolated static func startOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    nonisolated static func endOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        let start = startOfMonth(date, calendar: calendar)
        let days = calendar.range(of: .day, in: .month, for: start)?.count ?? 28
        return calendar.date(byAdding: .day, value: days - 1, to: start) ?? start
    }

    nonisolated static func days(inMonth month: Date, calendar: Calendar = .current) -> [Date] {
        let start = startOfMonth(month, calendar: calendar)
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 0
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    nonisolated static func clamped(_ date: Date, minDate: Date?, maxDate: Date?, calendar: Calendar = .current) -> Date? {
        var result = date
        if let minDate, result < minDate { result = minDate }
        if let maxDate, result > maxDate { result = maxDate }
        if let minDate, let maxDate, minDate > maxDate { return nil }
        return result
    }

    /// 上游用 dayjs 的格式串，原生只支持其中的年月占位符（`YYYY` / `YY` / `MM` / `M`），
    /// 这也是 `monthFormat` 唯一会用到的部分。
    nonisolated static func monthLabel(for month: Date, format: String, calendar: Calendar = .current) -> String {
        let year = calendar.component(.year, from: month)
        let value = calendar.component(.month, from: month)
        let padded = value < 10 ? "0\(value)" : String(value)
        guard !format.isEmpty else {
            let isChinese = (Locale.current.language.languageCode?.identifier ?? "").hasPrefix("zh")
            return isChinese ? "\(year)年\(padded)月" : "\(padded)/\(year)"
        }
        return format
            .replacingOccurrences(of: "YYYY", with: String(year))
            .replacingOccurrences(of: "YY", with: String(year % 100))
            .replacingOccurrences(of: "MM", with: padded)
            .replacingOccurrences(of: "M", with: String(value))
    }

    // MARK: - 渲染

    public var body: some View {
        VStack(spacing: 0) {
            if !fullCalendar || !showsFullCalendar {
                header
                strip
            } else {
                fullCalendarPanel
                // 上游模板只在展开态显示 `collapseHint`。
                Text(collapseHint)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.tips)
                    .padding(.bottom, 8)
                    .onTapGesture { toggleFull(source: "hint") }
            }
        }
        // 上游 `--up-card-bg-color` 默认白底。
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .gesture(pullGesture)
    }

    private var header: some View {
        HStack(spacing: 0) {
            switchButton("‹", disabled: switchPrevDisabled) { prevMonth() }

            Text(monthLabel)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.main)
                .frame(maxWidth: .infinity)

            switchButton("›", disabled: switchNextDisabled) { nextMonth() }

            if fullCalendar {
                Text("▾")
                    .font(.system(size: 18))
                    .foregroundStyle(theme.content)
                    .frame(width: 40)
                    .contentShape(Rectangle())
                    .onTapGesture { toggleFull(source: "button") }
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 4)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.border).frame(height: 0.5)
        }
    }

    private func switchButton(_ label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Text(label)
            .font(.system(size: 20))
            .foregroundStyle(theme.main)
            .opacity(disabled ? 0.35 : 1)
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }

    private var strip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                        dayCell(day)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.top, 10)
            .padding(.bottom, 6)
            // 对应上游 `scrollToDate` 的 `scroll-into-view`。
            .onChange(of: selectedDate) { _, date in
                guard let date else { return }
                withAnimation { proxy.scrollTo(date, anchor: .center) }
            }
        }
    }

    private func dayCell(_ day: UPCalendarStripDay) -> some View {
        let selectedColor = UPColor.parse(color, theme: theme)
        let highlightsToday = day.today && showToday && !day.selected
        return VStack(spacing: 4) {
            Text(String(day.day))
                .font(.system(size: 18))
                .foregroundStyle(day.selected ? Color.white : theme.main)
            Text(weekLabel(for: day.weekday))
                .font(.system(size: 12))
                .foregroundStyle(day.selected ? Color.white : theme.content)
        }
        .frame(width: 54, height: 62)
        .background(day.selected ? selectedColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(highlightsToday ? selectedColor : Color.clear, lineWidth: 1)
        }
        .opacity(day.disabled ? 0.4 : 1)
        .contentShape(Rectangle())
        .id(day.date)
        .onTapGesture {
            guard !readonly, !day.disabled else { return }
            select(day.date)
        }
    }

    /// 上游展开态嵌的是 `u-calendar`（`pageInline`），原生沿用 `UPCalendar`。
    private var fullCalendarPanel: some View {
        UPCalendar(mode: .single,
                   selectedDate: Binding(get: { selectedDate },
                                         set: { if let date = $0 { confirmFromFullCalendar(date) } }),
                   minDate: panelMinDate,
                   maxDate: panelMaxDate,
                   readonly: readonly)
            .datePickerStyle(.graphical)
            .tint(UPColor.parse(color, theme: theme))
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .padding(.top, 4)
    }

    /// 对应上游 `onTouchStart` / `onTouchEnd` 的下拉展开、上拉收起。
    private var pullGesture: some Gesture {
        DragGesture(minimumDistance: 10).onEnded { value in
            guard fullCalendar else { return }
            let deltaX = value.translation.width
            let deltaY = value.translation.height
            guard abs(deltaY) >= pullDownThreshold, abs(deltaY) > abs(deltaX) else { return }
            if deltaY > 0 { setFullVisible(true, source: "pull-down") }
            if deltaY < 0 { setFullVisible(false, source: "pull-up") }
        }
    }
}
