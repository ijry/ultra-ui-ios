import Foundation
import Observation
import SwiftUI

public typealias UPCalendarUnitValue = UPImageUnitValue

/// SwiftUI 的 View 必须是值类型，可变状态放在这个小引用盒里。
/// 字段与上游 `data()` 一一对应：`selected` / `monthIndex` / 三个时间值。
@MainActor
@Observable
final class UPCalendarState {
    var selectedDates: [Date]
    var monthIndex = 0
    var singleTime = ""
    var rangeStartTime = ""
    var rangeEndTime = ""
    var timePickerTarget = "single"
    var timePickerShow = false

    init(selectedDates: [Date]) {
        self.selectedDates = selectedDates
    }
}

/// Native SwiftUI counterpart of uview-plus `u-calendar`.
///
/// 上游是「底部弹窗 + 可滚动的多月网格」，原生沿用 `UPPopup` 承载弹窗，
/// 月份网格自己画。差异集中在三处：
/// - `showLunar` 上游用内置的 `calendar.js` 算农历，原生用 Foundation 的
///   `Calendar(identifier: .chinese)` 取农历日名，闰月与节气不覆盖。
/// - `enableTime` 的时间选择上游是 `picker-view`，原生用 `Picker` 轮盘。
/// - 上游要量每个月份的高度来同步副标题（`updateMonthTop` + `onScroll`），
///   原生滚动时用 `ScrollViewReader` 定位，副标题跟随 `monthIndex`，
///   非 `monthSwitch` 模式下滚动不会改副标题。
@MainActor
public struct UPCalendar: View {
    public var title: String
    public var showTitle: Bool
    public var showSubtitle: Bool
    public var mode: UPCalendarMode
    public var startText: String
    public var endText: String
    public var customList: [UPCalendarCustomDay]
    public var color: String
    public var minDate: Date?
    public var maxDate: Date?
    public var defaultDate: [Date]?
    public var maxCount: Int
    public var rowHeight: CGFloat
    public var formatter: UPCalendarFormatter?
    public var showLunar: Bool
    public var showMark: Bool
    public var confirmText: String
    public var confirmDisabledText: String
    public var closeOnClickOverlay: Bool
    public var readonly: Bool
    public var showConfirm: Bool
    public var maxRange: Int
    public var rangePrompt: String
    public var showRangePrompt: Bool
    public var allowSameDay: Bool
    public var rangeResultMode: String
    public var enableTime: Bool
    public var timePrecision: String
    public var defaultTime: String
    public var round: CGFloat
    public var overlay: Bool
    public var duration: Double
    public var overlayStyle: UPStyle
    public var overlayOpacity: Double
    public var zIndex: Double
    public var safeAreaInsetBottom: Bool
    public var safeAreaInsetTop: Bool
    public var bgColor: String
    public var monthNum: Int
    public var monthSwitch: Bool
    public var showToday: Bool
    public var todayColor: String
    public var weekText: [String]
    public var forbidDays: [Date]
    public var forbidDaysToast: String
    public var monthFormat: String
    public var pageInline: Bool

    /// 上游 `show` prop；`showBinding` 存在时由宿主双向控制。
    let showProp: Bool
    private var showBinding: Binding<Bool>?
    /// 原生扩展：与仓库既有 API 兼容的单选/多选绑定。
    private var selectedDateBinding: Binding<Date?>?
    private var selectedDatesBinding: Binding<[Date]>?

    @State private var state: UPCalendarState
    @Environment(\.upTheme) private var theme
    private var onChangeHandler: ((Date) -> Void)?
    private var onSelectHandler: ((UPCalendarSelection) -> Void)?
    private var onConfirmHandler: ((UPCalendarSelection) -> Void)?
    private var onCloseHandler: (() -> Void)?
    private var onClosedHandler: (() -> Void)?
    private var footerSlot: AnyView?

    let calendar = Calendar.current

    /// 仓库既有签名一。
    public init(selectedDate: Binding<Date?>? = nil,
                minDate: Date? = nil,
                maxDate: Date? = nil,
                multiple: Bool = false,
                selectedDates: [Date] = [],
                onChange: ((Date) -> Void)? = nil) {
        // 传非 nil 数组（可能为空）以保留仓库既有语义：没给日期时不预选今天，
        // 而上游 `setDefaultDate` 在 `defaultDate` 为空值时会选中今天。
        self.init(mode: multiple ? "multiple" : "single",
                  minDate: minDate,
                  maxDate: maxDate,
                  defaultDate: selectedDates.isEmpty
                      ? (selectedDate?.wrappedValue.map { [$0] } ?? [])
                      : selectedDates,
                  show: true,
                  pageInline: true)
        self.selectedDateBinding = selectedDate
        self.onChangeHandler = onChange
    }

    /// 仓库既有签名二。
    public init(mode: UPCalendarMode = .single,
                selectedDates: Binding<[Date]>? = nil,
                selectedDate: Binding<Date?>? = nil,
                minDate: Date? = nil,
                maxDate: Date? = nil,
                maxCount: Int = Int.max,
                readonly: Bool = false,
                onChange: ((Date) -> Void)? = nil) {
        self.init(mode: mode.rawValue,
                  minDate: minDate,
                  maxDate: maxDate,
                  defaultDate: selectedDates?.wrappedValue
                      ?? (selectedDate?.wrappedValue.map { [$0] } ?? []),
                  maxCount: maxCount,
                  show: true,
                  readonly: readonly,
                  pageInline: true)
        self.selectedDatesBinding = selectedDates
        self.selectedDateBinding = selectedDate
        self.onChangeHandler = onChange
    }

    /// 与上游 `props.js` 对齐的初始化器。
    public init(title: String = UPConfig.calendar.title,
                showTitle: Bool = UPConfig.calendar.showTitle,
                showSubtitle: Bool = UPConfig.calendar.showSubtitle,
                mode: String = UPConfig.calendar.mode,
                startText: String = UPConfig.calendar.startText,
                endText: String = UPConfig.calendar.endText,
                customList: [UPCalendarCustomDay] = UPConfig.calendar.customList,
                color: String = UPConfig.calendar.color,
                minDate: Date? = UPConfig.calendar.minDate,
                maxDate: Date? = UPConfig.calendar.maxDate,
                defaultDate: [Date]? = UPConfig.calendar.defaultDate,
                maxCount: any UPCalendarUnitValue = UPConfig.calendar.maxCount,
                rowHeight: any UPCalendarUnitValue = UPConfig.calendar.rowHeight,
                formatter: UPCalendarFormatter? = nil,
                showLunar: Bool = UPConfig.calendar.showLunar,
                showMark: Bool = UPConfig.calendar.showMark,
                confirmText: String = UPConfig.calendar.confirmText,
                confirmDisabledText: String = UPConfig.calendar.confirmDisabledText,
                show: Bool = UPConfig.calendar.show,
                closeOnClickOverlay: Bool = UPConfig.calendar.closeOnClickOverlay,
                readonly: Bool = UPConfig.calendar.readonly,
                showConfirm: Bool = UPConfig.calendar.showConfirm,
                maxRange: any UPCalendarUnitValue = UPConfig.calendar.maxRange,
                rangePrompt: String = UPConfig.calendar.rangePrompt,
                showRangePrompt: Bool = UPConfig.calendar.showRangePrompt,
                allowSameDay: Bool = UPConfig.calendar.allowSameDay,
                rangeResultMode: String = UPConfig.calendar.rangeResultMode,
                enableTime: Bool = UPConfig.calendar.enableTime,
                timePrecision: String = UPConfig.calendar.timePrecision,
                defaultTime: String = UPConfig.calendar.defaultTime,
                round: any UPCalendarUnitValue = UPConfig.calendar.round,
                overlay: Bool = UPConfig.calendar.overlay,
                duration: any UPCalendarUnitValue = UPConfig.calendar.duration,
                overlayStyle: UPStyle = UPConfig.calendar.overlayStyle,
                overlayOpacity: any UPCalendarUnitValue = UPConfig.calendar.overlayOpacity,
                zIndex: any UPCalendarUnitValue = UPConfig.calendar.zIndex,
                safeAreaInsetBottom: Bool = UPConfig.calendar.safeAreaInsetBottom,
                safeAreaInsetTop: Bool = UPConfig.calendar.safeAreaInsetTop,
                bgColor: String = UPConfig.calendar.bgColor,
                monthNum: any UPCalendarUnitValue = UPConfig.calendar.monthNum,
                monthSwitch: Bool = UPConfig.calendar.monthSwitch,
                showToday: Bool = UPConfig.calendar.showToday,
                todayColor: String = UPConfig.calendar.todayColor,
                weekText: [String] = UPConfig.calendar.weekText,
                forbidDays: [Date] = UPConfig.calendar.forbidDays,
                forbidDaysToast: String = UPConfig.calendar.forbidDaysToast,
                monthFormat: String = UPConfig.calendar.monthFormat,
                pageInline: Bool = UPConfig.calendar.pageInline,
                onConfirm: ((UPCalendarSelection) -> Void)? = nil,
                onClose: (() -> Void)? = nil) {
        let calendar = Calendar.current
        self.title = title
        self.showTitle = showTitle
        self.showSubtitle = showSubtitle
        self.mode = UPCalendarMode(rawValue: mode) ?? .single
        self.startText = startText
        self.endText = endText
        self.customList = customList
        self.color = color
        self.minDate = minDate.map { calendar.startOfDay(for: $0) }
        self.maxDate = maxDate.map { calendar.startOfDay(for: $0) }
        self.defaultDate = defaultDate.map { $0.map { calendar.startOfDay(for: $0) } }
        self.maxCount = Self.resolveCount(maxCount.upImageUnitValue, fallback: UPConfig.calendar.maxCount)
        self.rowHeight = max(UPUnit.parse(rowHeight.upImageUnitValue), 0)
        self.formatter = formatter
        self.showLunar = showLunar
        self.showMark = showMark
        self.confirmText = confirmText
        self.confirmDisabledText = confirmDisabledText
        self.closeOnClickOverlay = closeOnClickOverlay
        self.readonly = readonly
        self.showConfirm = showConfirm
        self.maxRange = Self.resolveCount(maxRange.upImageUnitValue, fallback: UPConfig.calendar.maxRange)
        self.rangePrompt = rangePrompt
        self.showRangePrompt = showRangePrompt
        self.allowSameDay = allowSameDay
        self.rangeResultMode = rangeResultMode
        self.enableTime = enableTime
        self.timePrecision = timePrecision
        self.defaultTime = defaultTime
        self.round = max(UPUnit.parse(round.upImageUnitValue), 0)
        self.overlay = overlay
        self.duration = Double(UPUnit.parse(duration.upImageUnitValue))
        self.overlayStyle = overlayStyle
        self.overlayOpacity = Double(UPUnit.parse(overlayOpacity.upImageUnitValue))
        self.zIndex = Double(UPUnit.parse(zIndex.upImageUnitValue))
        self.safeAreaInsetBottom = safeAreaInsetBottom
        self.safeAreaInsetTop = safeAreaInsetTop
        self.bgColor = bgColor
        self.monthNum = max(1, Int(UPUnit.parse(monthNum.upImageUnitValue)))
        self.monthSwitch = monthSwitch
        self.showToday = showToday
        self.todayColor = todayColor
        self.weekText = weekText
        self.forbidDays = forbidDays.map { calendar.startOfDay(for: $0) }
        self.forbidDaysToast = forbidDaysToast
        self.monthFormat = monthFormat
        self.pageInline = pageInline
        self.showProp = show
        self.showBinding = nil
        self.onConfirmHandler = onConfirm
        self.onCloseHandler = onClose
        let seeded = Self.seededSelection(mode: UPCalendarMode(rawValue: mode) ?? .single,
                                         defaultDate: defaultDate,
                                         minDate: minDate,
                                         maxDate: maxDate,
                                         monthNum: max(1, Int(UPUnit.parse(monthNum.upImageUnitValue))),
                                         calendar: calendar)
        self._state = State(initialValue: UPCalendarState(selectedDates: seeded))
    }

    /// `v-model:show` 版本。
    public init(show: Binding<Bool>,
                title: String = UPConfig.calendar.title,
                showTitle: Bool = UPConfig.calendar.showTitle,
                showSubtitle: Bool = UPConfig.calendar.showSubtitle,
                mode: String = UPConfig.calendar.mode,
                startText: String = UPConfig.calendar.startText,
                endText: String = UPConfig.calendar.endText,
                customList: [UPCalendarCustomDay] = UPConfig.calendar.customList,
                color: String = UPConfig.calendar.color,
                minDate: Date? = UPConfig.calendar.minDate,
                maxDate: Date? = UPConfig.calendar.maxDate,
                defaultDate: [Date]? = UPConfig.calendar.defaultDate,
                maxCount: any UPCalendarUnitValue = UPConfig.calendar.maxCount,
                rowHeight: any UPCalendarUnitValue = UPConfig.calendar.rowHeight,
                formatter: UPCalendarFormatter? = nil,
                showLunar: Bool = UPConfig.calendar.showLunar,
                showMark: Bool = UPConfig.calendar.showMark,
                confirmText: String = UPConfig.calendar.confirmText,
                confirmDisabledText: String = UPConfig.calendar.confirmDisabledText,
                closeOnClickOverlay: Bool = UPConfig.calendar.closeOnClickOverlay,
                readonly: Bool = UPConfig.calendar.readonly,
                showConfirm: Bool = UPConfig.calendar.showConfirm,
                maxRange: any UPCalendarUnitValue = UPConfig.calendar.maxRange,
                rangePrompt: String = UPConfig.calendar.rangePrompt,
                showRangePrompt: Bool = UPConfig.calendar.showRangePrompt,
                allowSameDay: Bool = UPConfig.calendar.allowSameDay,
                rangeResultMode: String = UPConfig.calendar.rangeResultMode,
                enableTime: Bool = UPConfig.calendar.enableTime,
                timePrecision: String = UPConfig.calendar.timePrecision,
                defaultTime: String = UPConfig.calendar.defaultTime,
                round: any UPCalendarUnitValue = UPConfig.calendar.round,
                overlay: Bool = UPConfig.calendar.overlay,
                duration: any UPCalendarUnitValue = UPConfig.calendar.duration,
                overlayStyle: UPStyle = UPConfig.calendar.overlayStyle,
                overlayOpacity: any UPCalendarUnitValue = UPConfig.calendar.overlayOpacity,
                zIndex: any UPCalendarUnitValue = UPConfig.calendar.zIndex,
                safeAreaInsetBottom: Bool = UPConfig.calendar.safeAreaInsetBottom,
                safeAreaInsetTop: Bool = UPConfig.calendar.safeAreaInsetTop,
                bgColor: String = UPConfig.calendar.bgColor,
                monthNum: any UPCalendarUnitValue = UPConfig.calendar.monthNum,
                monthSwitch: Bool = UPConfig.calendar.monthSwitch,
                showToday: Bool = UPConfig.calendar.showToday,
                todayColor: String = UPConfig.calendar.todayColor,
                weekText: [String] = UPConfig.calendar.weekText,
                forbidDays: [Date] = UPConfig.calendar.forbidDays,
                forbidDaysToast: String = UPConfig.calendar.forbidDaysToast,
                monthFormat: String = UPConfig.calendar.monthFormat,
                pageInline: Bool = UPConfig.calendar.pageInline,
                onConfirm: ((UPCalendarSelection) -> Void)? = nil,
                onClose: (() -> Void)? = nil) {
        self.init(title: title,
                  showTitle: showTitle,
                  showSubtitle: showSubtitle,
                  mode: mode,
                  startText: startText,
                  endText: endText,
                  customList: customList,
                  color: color,
                  minDate: minDate,
                  maxDate: maxDate,
                  defaultDate: defaultDate,
                  maxCount: maxCount,
                  rowHeight: rowHeight,
                  formatter: formatter,
                  showLunar: showLunar,
                  showMark: showMark,
                  confirmText: confirmText,
                  confirmDisabledText: confirmDisabledText,
                  show: show.wrappedValue,
                  closeOnClickOverlay: closeOnClickOverlay,
                  readonly: readonly,
                  showConfirm: showConfirm,
                  maxRange: maxRange,
                  rangePrompt: rangePrompt,
                  showRangePrompt: showRangePrompt,
                  allowSameDay: allowSameDay,
                  rangeResultMode: rangeResultMode,
                  enableTime: enableTime,
                  timePrecision: timePrecision,
                  defaultTime: defaultTime,
                  round: round,
                  overlay: overlay,
                  duration: duration,
                  overlayStyle: overlayStyle,
                  overlayOpacity: overlayOpacity,
                  zIndex: zIndex,
                  safeAreaInsetBottom: safeAreaInsetBottom,
                  safeAreaInsetTop: safeAreaInsetTop,
                  bgColor: bgColor,
                  monthNum: monthNum,
                  monthSwitch: monthSwitch,
                  showToday: showToday,
                  todayColor: todayColor,
                  weekText: weekText,
                  forbidDays: forbidDays,
                  forbidDaysToast: forbidDaysToast,
                  monthFormat: monthFormat,
                  pageInline: pageInline,
                  onConfirm: onConfirm,
                  onClose: onClose)
        self.showBinding = show
    }

    // MARK: - 状态

    public var show: Bool { showBinding?.wrappedValue ?? showProp }

    /// 上游 `data.selected`。
    public var selectedDates: [Date] { state.selectedDates }

    /// 仓库既有签名。
    public var multiple: Bool { mode == .multiple }

    /// 上游 `monthIndex`。
    public var monthIndex: Int { min(max(state.monthIndex, 0), max(months.count - 1, 0)) }

    public var singleTime: String { state.singleTime.isEmpty ? defaultTimeText : state.singleTime }
    public var rangeStartTime: String { state.rangeStartTime.isEmpty ? defaultTimeText : state.rangeStartTime }
    public var rangeEndTime: String { state.rangeEndTime.isEmpty ? defaultTimeText : state.rangeEndTime }

    /// 上游 `getDefaultTimeValue()`。
    public var defaultTimeText: String {
        let parsed = UPCalendarFormat.parseTime(defaultTime)
        return UPCalendarFormat.timeText(hour: parsed.hour,
                                        minute: parsed.minute,
                                        second: parsed.second,
                                        precision: timePrecision)
    }

    /// 上游 `setMonth()` 的结果。
    public var months: [UPCalendarMonth] {
        let start = calendar.startOfDay(for: minDate ?? Date())
        let end = maxDate ?? calendar.date(byAdding: .month, value: monthNum - 1, to: start) ?? start
        let span = (calendar.dateComponents([.month],
                                            from: UPCalendarStrip.startOfMonth(start, calendar: calendar),
                                            to: UPCalendarStrip.startOfMonth(end, calendar: calendar)).month ?? 0) + 1
        let count = min(max(span, 1), monthNum)
        return (0..<count).compactMap { offset in
            guard let anchor = calendar.date(byAdding: .month, value: offset, to: start) else { return nil }
            return month(for: anchor, minDate: start, maxDate: end)
        }
    }

    /// `monthSwitch` 模式下只渲染当前月。
    public var currentMonths: [UPCalendarMonth] {
        guard monthSwitch, months.indices.contains(monthIndex) else { return months }
        return [months[monthIndex]]
    }

    /// 上游 `subtitle`。
    public var subtitle: String {
        guard months.indices.contains(monthIndex) else { return "" }
        let item = months[monthIndex]
        return UPCalendarFormat.monthTitle(year: item.year, month: item.month, format: monthFormat)
    }

    /// 上游 `listHeight = rowHeight * (monthSwitch ? 6 : 5) + (pageInline ? 0 : 30)`。
    public var listHeight: CGFloat {
        rowHeight * (monthSwitch ? 6 : 5) + (pageInline ? 0 : 30)
    }

    public var switchPrevDisabled: Bool { monthIndex <= 0 }
    public var switchNextDisabled: Bool { monthIndex >= months.count - 1 }
    public var switchPrevYearDisabled: Bool { monthIndex - 12 < 0 }
    public var switchNextYearDisabled: Bool { monthIndex + 12 > months.count - 1 }

    /// 上游 `todayDisabled`：今天落在 min/max 之外时「今天」按钮禁用。
    public var todayDisabled: Bool {
        let today = calendar.startOfDay(for: Date())
        if let minDate, today < minDate { return true }
        if let maxDate, today > maxDate { return true }
        return false
    }

    /// 上游 `showTimePanel`。
    public var showTimePanel: Bool {
        guard enableTime else { return false }
        if mode == .single { return true }
        return mode == .range && rangeResultMode == "boundary"
    }

    /// 上游 `buttonDisabled`：range 模式下选不足 2 个时禁用确认按钮。
    public var buttonDisabled: Bool {
        mode == .range && selectedDates.count <= 1
    }

    /// 上游 `resolvedTodayColor`。
    public var resolvedTodayColor: String { todayColor.isEmpty ? color : todayColor }

    /// 上游 `getConfirmValue()`。
    public var selection: UPCalendarSelection {
        var dates = selectedDates
        if mode == .range, rangeResultMode == "boundary", dates.count >= 2, let first = dates.first, let last = dates.last {
            dates = [first, last]
        }
        var texts = dates.map { UPCalendarFormat.dateText($0, calendar: calendar) }
        if showTimePanel, enableTime {
            if mode == .single, let first = texts.first {
                texts = ["\(first) \(singleTime)"]
            } else if mode == .range, rangeResultMode == "boundary", texts.count >= 2 {
                texts = ["\(texts[0]) \(rangeStartTime)", "\(texts[1]) \(rangeEndTime)"]
            }
        }
        return UPCalendarSelection(mode: mode, dates: dates, texts: texts)
    }

    // MARK: - 上游方法

    /// 对应上游 `month.vue` 的 `clickHandler`。
    public func select(_ date: Date) {
        guard !readonly else { return }
        let day = calendar.startOfDay(for: date)
        guard isSelectable(day) else { return }
        if mode != .range, forbidDays.contains(day) {
            UPToast.show(message: forbidDaysToast)
            return
        }

        var selected = selectedDates
        switch mode {
        case .single:
            selected = [day]
        case .multiple:
            if let index = selected.firstIndex(of: day) {
                selected.remove(at: index)
            } else if selected.count < maxCount {
                selected.append(day)
            } else {
                return
            }
        case .range:
            if selected.isEmpty || selected.count >= 2 {
                selected = [day]
            } else if let start = selected.first {
                if day < start {
                    selected = [day]
                } else if day > start {
                    // 上游用 `date - maxRange` 与起始日比较来判定超限。
                    if let shifted = calendar.date(byAdding: .day, value: -maxRange, to: day),
                       shifted > start, showRangePrompt {
                        UPToast.show(message: rangePrompt.isEmpty ? "选择天数不能超过\(maxRange)天" : rangePrompt)
                        return
                    }
                    selected = Self.dates(from: start, to: day, calendar: calendar)
                } else {
                    // 起止同一天，需 `allowSameDay`。
                    guard allowSameDay else { return }
                    selected.append(day)
                }
            }
        }
        setSelected(selected, scene: "tap")
        onChangeHandler?(day)
    }

    /// 对应上游 `setSelected` + `monthSelected`。
    private func setSelected(_ selected: [Date], scene: String) {
        state.selectedDates = selected
        selectedDatesBinding?.wrappedValue = selected
        if mode == .single { selectedDateBinding?.wrappedValue = selected.first }
        onSelectHandler?(selection)
        // 上游 `showConfirm` 为假时点选即确认（range 需选满 2 个）。
        guard !showConfirm, scene == "tap" else { return }
        if mode == .range, selected.count < 2 { return }
        guard validateSameDayRangeTime() else { return }
        onConfirmHandler?(selection)
    }

    /// 对应上游 `confirm()`。
    @discardableResult
    public func confirm() -> UPCalendarSelection? {
        guard !buttonDisabled, !selectedDates.isEmpty else { return nil }
        guard validateSameDayRangeTime() else { return nil }
        let result = selection
        onConfirmHandler?(result)
        return result
    }

    /// 对应上游 `close()`。
    public func close() {
        showBinding?.wrappedValue = false
        onCloseHandler?()
    }

    /// 对应上游 `prevMonth` / `nextMonth` / `prevYear` / `nextYear`。
    public func prevMonth() { guard !switchPrevDisabled else { return }; state.monthIndex -= 1 }
    public func nextMonth() { guard !switchNextDisabled else { return }; state.monthIndex += 1 }
    public func prevYear() { guard !switchPrevYearDisabled else { return }; state.monthIndex -= 12 }
    public func nextYear() { guard !switchNextYearDisabled else { return }; state.monthIndex += 12 }

    /// 对应上游 `jumpToToday`：range 模式只跳月不选中。
    public func jumpToToday() {
        guard !todayDisabled else { return }
        let today = calendar.startOfDay(for: Date())
        if let index = months.firstIndex(where: {
            $0.year == calendar.component(.year, from: today) && $0.month == calendar.component(.month, from: today)
        }) {
            state.monthIndex = index
        }
        guard mode != .range else { return }
        select(today)
    }

    /// 对应上游 `validateSameDayRangeTime`。
    public func validateSameDayRangeTime() -> Bool {
        guard enableTime, mode == .range, rangeResultMode == "boundary", selectedDates.count >= 2 else { return true }
        guard let start = selectedDates.first, let end = selectedDates.last, start == end else { return true }
        guard UPCalendarFormat.seconds(of: rangeEndTime) < UPCalendarFormat.seconds(of: rangeStartTime) else { return true }
        UPToast.show(message: "结束时间不能早于开始时间")
        return false
    }

    /// 对应上游 `openTimePicker` / `confirmTimePicker`。
    public func openTimePicker(_ target: String) {
        state.timePickerTarget = target
        state.timePickerShow = true
    }

    public func setTime(_ value: String, for target: String) {
        switch target {
        case "start": state.rangeStartTime = value
        case "end": state.rangeEndTime = value
        default: state.singleTime = value
        }
    }

    var timePickerTarget: String { state.timePickerTarget }

    var timePickerShowBinding: Binding<Bool> {
        Binding(get: { state.timePickerShow }, set: { state.timePickerShow = $0 })
    }

    /// 上游 `disabled: date < minDate || date > maxDate`。
    public func isSelectable(_ date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        if let minDate, day < minDate { return false }
        if let maxDate, day > maxDate { return false }
        return true
    }

    /// 上游 `isForbid`：只在非 range 模式生效。
    public func isForbidden(_ date: Date) -> Bool {
        mode != .range && forbidDays.contains(calendar.startOfDay(for: date))
    }

    public func isSelected(_ date: Date) -> Bool {
        selectedDates.contains(calendar.startOfDay(for: date))
    }

    /// 上游 `getBottomInfo`：range 模式给首尾补「开始」/「结束」。
    public func bottomInfo(for day: UPCalendarDay) -> String {
        guard mode == .range, let first = selectedDates.first else { return day.bottomInfo }
        let date = calendar.startOfDay(for: day.date)
        guard selectedDates.count > 1, let last = selectedDates.last else {
            return date == first ? startText : day.bottomInfo
        }
        if date == first, date == last { return "\(startText)/\(endText)" }
        if date == first { return startText }
        if date == last { return endText }
        return day.bottomInfo
    }

    /// 一个月的格子，对应上游 `setMonth()` 里的 `date` 数组。
    func month(for anchor: Date, minDate: Date, maxDate: Date) -> UPCalendarMonth {
        let year = calendar.component(.year, from: anchor)
        let monthValue = calendar.component(.month, from: anchor)
        let days = UPCalendarStrip.days(inMonth: anchor, calendar: calendar).map { date -> UPCalendarDay in
            var day = UPCalendarDay(date: date,
                                    day: calendar.component(.day, from: date),
                                    week: calendar.component(.weekday, from: date),
                                    month: monthValue,
                                    disabled: date < minDate || date > maxDate,
                                    bottomInfo: showLunar ? Self.lunarDayText(date, calendar: calendar) : "",
                                    dot: false)
            if let custom = customList.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                if !custom.bottomInfo.isEmpty { day.bottomInfo = custom.bottomInfo }
                day.dot = custom.dot
                if let disabled = custom.disabled { day.disabled = disabled }
            }
            return formatter?(day) ?? day
        }
        return UPCalendarMonth(year: year, month: monthValue, days: days)
    }

    // MARK: - 纯函数工具

    /// 上游 `Number.MAX_SAFE_INTEGER` 语义：解析不出来或非正数时回落。
    /// 先按整数解析，避免 `Int.max` 经过 `Double` 往返时溢出。
    nonisolated static func resolveCount(_ raw: String, fallback: Int) -> Int {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        if let value = Int(trimmed) { return value > 0 ? value : fallback }
        let parsed = Double(UPUnit.parse(trimmed))
        guard parsed > 0, parsed < Double(Int.max) else { return fallback }
        return Int(parsed.rounded(.down))
    }

    /// 区间模式把起止之间的所有日期都塞进数组，对应上游的 do-while。
    nonisolated static func dates(from start: Date, to end: Date, calendar: Calendar = .current) -> [Date] {
        var result: [Date] = []
        var cursor = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        while cursor <= last {
            result.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    /// 上游 `setDefaultDate`：没给默认值时选中今天，否则过滤掉 min/max 之外的项。
    nonisolated static func seededSelection(mode: UPCalendarMode,
                                            defaultDate: [Date]?,
                                            minDate: Date?,
                                            maxDate: Date?,
                                            monthNum: Int,
                                            calendar: Calendar = .current) -> [Date] {
        let lower = minDate.map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: Date())
        let upper = maxDate.map { calendar.startOfDay(for: $0) }
            ?? calendar.date(byAdding: .month, value: monthNum - 1, to: lower)
            ?? lower
        guard let defaultDate else { return [calendar.startOfDay(for: Date())] }
        var candidates = defaultDate.map { calendar.startOfDay(for: $0) }
        // 上游单选模式只取第一个。
        if mode == .single, let first = candidates.first { candidates = [first] }
        return candidates.filter { $0 >= lower && $0 <= upper }
    }

    /// 上游用内置 `calendar.js` 算农历日名，原生借 Foundation 的农历历法。
    nonisolated static func lunarDayText(_ date: Date, calendar: Calendar = .current) -> String {
        var chinese = Calendar(identifier: .chinese)
        chinese.timeZone = calendar.timeZone
        let day = chinese.component(.day, from: date)
        guard day >= 1, day <= 30 else { return "" }
        let units = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        switch day {
        case 1...10: return "初" + units[day]
        case 11...19: return "十" + units[day - 10]
        case 20: return "二十"
        case 21...29: return "廿" + units[day - 20]
        default: return "三十"
        }
    }

    // MARK: - 事件

    public func onChange(_ action: @escaping (Date) -> Void) -> UPCalendar {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    public func onSelect(_ action: @escaping (UPCalendarSelection) -> Void) -> UPCalendar {
        var copy = self
        copy.onSelectHandler = action
        return copy
    }

    public func onConfirm(_ action: @escaping (UPCalendarSelection) -> Void) -> UPCalendar {
        var copy = self
        copy.onConfirmHandler = action
        return copy
    }

    public func onClose(_ action: @escaping () -> Void) -> UPCalendar {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }

    /// 对应上游 `closed` 事件（离场动画结束）。
    public func onClosed(_ action: @escaping () -> Void) -> UPCalendar {
        var copy = self
        copy.onClosedHandler = action
        return copy
    }

    /// 等价于上游 `$slots.footer` 是否存在。
    public var hasFooterSlot: Bool { footerSlot != nil }

    /// 对应上游 `#footer` 具名插槽（仅 `showConfirm` 为真时渲染）。
    public func footer<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPCalendar {
        var copy = self
        copy.footerSlot = AnyView(builder())
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        UPPopup(show: Binding(get: { show }, set: { if !$0 { close() } }),
                overlay: overlay,
                mode: "bottom",
                duration: duration,
                closeable: !pageInline,
                overlayStyle: overlayStyle,
                closeOnClickOverlay: closeOnClickOverlay,
                zIndex: zIndex,
                safeAreaInsetBottom: safeAreaInsetBottom,
                safeAreaInsetTop: safeAreaInsetTop,
                round: round,
                bgColor: bgColor,
                overlayOpacity: overlayOpacity,
                pageInline: pageInline,
                onClosed: { onClosedHandler?() }) {
            panel
        }
    }

    private var panel: some View {
        VStack(spacing: 0) {
            UPCalendarHeader(calendar: self)

            if showTimePanel { UPCalendarTimePanel(calendar: self) }

            UPCalendarMonthList(calendar: self)

            if showConfirm { footerView }
        }
        // 上游 `.u-calendar` 用 `--up-card-bg-color`，默认白底。
        .background(bgColor.isEmpty ? Color.white : UPColor.parse(bgColor, theme: theme))
    }

    @ViewBuilder
    private var footerView: some View {
        if let footerSlot {
            footerSlot
        } else {
            UPButton(type: "primary",
                     shape: "circle",
                     disabled: buttonDisabled,
                     text: buttonDisabled ? confirmDisabledText : confirmText,
                     color: color) {
                confirm()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}
