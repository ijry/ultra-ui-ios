import Foundation
import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CalendarComponentTests: XCTestCase {
    func testBusinessComponentsKeepLegacyEmptyInitializers() {
        _ = UPCalendar()
        _ = UPCalendarStrip()
        _ = UPGoodsSku()
        _ = UPTree()
    }

    /// 上游以 `YYYY-MM-DD` 为粒度工作（`dayjs(...).format('YYYY-MM-DD')`），
    /// 因此选中值统一规整到当天 0 点。
    func testCalendarSelectsDateWithinRangeAndEmitsChange() {
        var selected: Date?
        var changed: Date?
        let calendar = UPCalendar(selectedDate: Binding(get: { selected }, set: { selected = $0 }),
                                  minDate: Self.day(2026, 3, 10),
                                  maxDate: Self.day(2026, 3, 20))
            .onChange { changed = $0 }
        calendar.select(Self.day(2026, 3, 15))
        XCTAssertEqual(selected, Self.day(2026, 3, 15))
        XCTAssertEqual(changed, selected)
        calendar.select(Self.day(2026, 3, 25))
        XCTAssertEqual(selected, Self.day(2026, 3, 15))
    }

    func testCalendarStripExposesVisibleDatesAndSelection() {
        var index = 0
        let strip = UPCalendarStrip(dates: [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 2)],
                                    current: Binding(get: { index }, set: { index = $0 }))
        strip.select(1)
        XCTAssertEqual(index, 1)
        XCTAssertEqual(strip.selectedDate, Date(timeIntervalSince1970: 2))
    }

    /// 上游 range 模式会把起止之间的每一天都放进数组。
    func testCalendarSupportsRangeSelectionAndConfirmPayload() {
        var dates: [Date] = []
        var confirmed: UPCalendarSelection?
        let calendar = UPCalendar(mode: .range, selectedDates: Binding(get: { dates }, set: { dates = $0 }))
            .onConfirm { confirmed = $0 }

        calendar.select(Self.day(2026, 3, 10))
        calendar.select(Self.day(2026, 3, 12))
        XCTAssertEqual(dates, [Self.day(2026, 3, 10), Self.day(2026, 3, 11), Self.day(2026, 3, 12)])
        XCTAssertEqual(calendar.confirm()?.dates, dates)
        XCTAssertEqual(confirmed?.range?.lowerBound, Self.day(2026, 3, 10))
        XCTAssertEqual(confirmed?.range?.upperBound, Self.day(2026, 3, 12))
    }

    func testCalendarEnforcesReadonlyAndMultipleMaximum() {
        let readonly = UPCalendar(mode: .single, readonly: true)
        readonly.select(Self.day(2026, 3, 10))
        XCTAssertTrue(readonly.selectedDates.isEmpty)

        let multiple = UPCalendar(mode: .multiple, maxCount: 1)
        multiple.select(Self.day(2026, 3, 10))
        multiple.select(Self.day(2026, 3, 11))
        XCTAssertEqual(multiple.selectedDates, [Self.day(2026, 3, 10)])
        XCTAssertTrue(multiple.multiple)
    }

    static func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    /// `calendar.js`：`title` / `startText` / `endText` / `confirmText` 走 i18n，
    /// `mode: 'single'`、`color: '#3c9cff'`、`maxCount/maxRange: MAX_SAFE_INTEGER`、
    /// `rowHeight: 56`、`showMark: true`、`showConfirm: true`、`monthNum: 3`、
    /// `zIndex: 10075`、`overlayOpacity: 0.5`、`duration: 300`、`timePrecision: 'minute'`。
    func testCalendarPropDefaultsMatchUpstream() {
        let calendar = UPCalendar(title: UPConfig.calendar.title)
        XCTAssertEqual(calendar.title, "日期选择")
        XCTAssertTrue(calendar.showTitle)
        XCTAssertTrue(calendar.showSubtitle)
        XCTAssertEqual(calendar.mode, .single)
        XCTAssertEqual(calendar.startText, "开始")
        XCTAssertEqual(calendar.endText, "结束")
        XCTAssertTrue(calendar.customList.isEmpty)
        XCTAssertEqual(calendar.color, "#3c9cff")
        XCTAssertNil(calendar.minDate)
        XCTAssertNil(calendar.maxDate)
        XCTAssertNil(calendar.defaultDate)
        XCTAssertEqual(calendar.maxCount, Int.max)
        XCTAssertEqual(calendar.rowHeight, 56)
        XCTAssertFalse(calendar.showLunar)
        XCTAssertTrue(calendar.showMark)
        XCTAssertEqual(calendar.confirmText, "确定")
        XCTAssertEqual(calendar.confirmDisabledText, "确定")
        XCTAssertFalse(calendar.show)
        XCTAssertFalse(calendar.closeOnClickOverlay)
        XCTAssertFalse(calendar.readonly)
        XCTAssertTrue(calendar.showConfirm)
        XCTAssertEqual(calendar.maxRange, Int.max)
        XCTAssertEqual(calendar.rangePrompt, "")
        XCTAssertTrue(calendar.showRangePrompt)
        XCTAssertFalse(calendar.allowSameDay)
        XCTAssertEqual(calendar.rangeResultMode, "all")
        XCTAssertFalse(calendar.enableTime)
        XCTAssertEqual(calendar.timePrecision, "minute")
        XCTAssertEqual(calendar.defaultTime, "")
        XCTAssertEqual(calendar.round, 0)
        XCTAssertTrue(calendar.overlay)
        XCTAssertEqual(calendar.duration, 300)
        XCTAssertEqual(calendar.overlayOpacity, 0.5)
        XCTAssertEqual(calendar.zIndex, 10075)
        XCTAssertTrue(calendar.safeAreaInsetBottom)
        XCTAssertFalse(calendar.safeAreaInsetTop)
        XCTAssertEqual(calendar.bgColor, "")
        XCTAssertEqual(calendar.monthNum, 3)
        XCTAssertFalse(calendar.monthSwitch)
        XCTAssertTrue(calendar.showToday)
        XCTAssertEqual(calendar.todayColor, "")
        XCTAssertEqual(calendar.weekText, ["一", "二", "三", "四", "五", "六", "日"])
        XCTAssertTrue(calendar.forbidDays.isEmpty)
        XCTAssertEqual(calendar.forbidDaysToast, "该日期已禁用")
        XCTAssertEqual(calendar.monthFormat, "")
        XCTAssertFalse(calendar.pageInline)
        XCTAssertFalse(calendar.hasFooterSlot)
        // 上游 `todayColor` 为空时跟随主题色。
        XCTAssertEqual(calendar.resolvedTodayColor, "#3c9cff")
        // 上游 `setDefaultDate`：没给 defaultDate 时选中今天。
        XCTAssertEqual(calendar.selectedDates, [Calendar.current.startOfDay(for: Date())])
    }

    /// 上游 `setMonth()`：从 `minDate` 起最多铺 `monthNum` 个月，每月按实际天数生成格子。
    func testCalendarBuildsMonthsFromMinDate() {
        let calendar = UPCalendar(minDate: Self.day(2026, 1, 15),
                                  maxDate: Self.day(2026, 4, 20),
                                  monthNum: 3)
        XCTAssertEqual(calendar.months.count, 3)
        XCTAssertEqual(calendar.months.map(\.month), [1, 2, 3])
        XCTAssertEqual(calendar.months[0].days.count, 31)
        XCTAssertEqual(calendar.months[1].days.count, 28)
        // 小于 minDate 的日子被禁用。
        XCTAssertTrue(calendar.months[0].days[0].disabled)
        XCTAssertFalse(calendar.months[0].days[14].disabled)
        // 上游 listHeight = rowHeight * 5 + 30（非 pageInline）。
        XCTAssertEqual(calendar.listHeight, 56 * 5 + 30)
        XCTAssertEqual(UPCalendar(monthSwitch: true, pageInline: true).listHeight, 56 * 6)
    }

    /// 上游 `customList` 按 `date` 合并进格子，`formatter` 最后再加工一次。
    func testCalendarMergesCustomListAndFormatter() {
        let target = Self.day(2026, 5, 3)
        let calendar = UPCalendar(customList: [UPCalendarCustomDay(date: target, bottomInfo: "休", dot: true)],
                                  minDate: Self.day(2026, 5, 1),
                                  maxDate: Self.day(2026, 5, 31),
                                  formatter: { day in
                                      var day = day
                                      if day.day == 4 { day.bottomInfo = "班" }
                                      return day
                                  })
        let days = calendar.months[0].days
        XCTAssertEqual(days[2].bottomInfo, "休")
        XCTAssertTrue(days[2].dot)
        XCTAssertEqual(days[3].bottomInfo, "班")
    }

    /// 上游 `maxRange` 超限时提示并放弃本次选择；`allowSameDay` 决定能否起止同天。
    func testCalendarRangeRespectsMaxRangeAndAllowSameDay() {
        let calendar = UPCalendar(mode: "range",
                                  minDate: Self.day(2026, 6, 1),
                                  maxDate: Self.day(2026, 6, 30),
                                  maxRange: 3)
        calendar.select(Self.day(2026, 6, 10))
        calendar.select(Self.day(2026, 6, 20))
        XCTAssertEqual(calendar.selectedDates, [Self.day(2026, 6, 10)])
        calendar.select(Self.day(2026, 6, 12))
        XCTAssertEqual(calendar.selectedDates.count, 3)

        let sameDay = UPCalendar(mode: "range", minDate: Self.day(2026, 6, 1))
        sameDay.select(Self.day(2026, 6, 10))
        sameDay.select(Self.day(2026, 6, 10))
        XCTAssertEqual(sameDay.selectedDates.count, 1)

        let allowed = UPCalendar(mode: "range", minDate: Self.day(2026, 6, 1), allowSameDay: true)
        allowed.select(Self.day(2026, 6, 10))
        allowed.select(Self.day(2026, 6, 10))
        XCTAssertEqual(allowed.selectedDates.count, 2)
    }

    /// 上游 `rangeResultMode: 'boundary'` 只返回起止两天。
    func testCalendarRangeResultModeBoundaryTrimsSelection() {
        let calendar = UPCalendar(mode: "range",
                                  minDate: Self.day(2026, 7, 1),
                                  rangeResultMode: "boundary")
        calendar.select(Self.day(2026, 7, 5))
        calendar.select(Self.day(2026, 7, 8))
        XCTAssertEqual(calendar.selectedDates.count, 4)
        XCTAssertEqual(calendar.selection.dates, [Self.day(2026, 7, 5), Self.day(2026, 7, 8)])
        XCTAssertEqual(calendar.selection.texts, ["2026-07-05", "2026-07-08"])
    }

    /// 上游 `buttonDisabled`：range 模式选不足 2 个时确认按钮禁用且 `confirm()` 无效。
    func testCalendarConfirmRequiresCompleteRange() {
        var confirmed: [UPCalendarSelection] = []
        let calendar = UPCalendar(mode: "range", minDate: Self.day(2026, 8, 1))
            .onConfirm { confirmed.append($0) }
        calendar.select(Self.day(2026, 8, 5))
        XCTAssertTrue(calendar.buttonDisabled)
        XCTAssertNil(calendar.confirm())
        calendar.select(Self.day(2026, 8, 6))
        XCTAssertFalse(calendar.buttonDisabled)
        XCTAssertNotNil(calendar.confirm())
        XCTAssertEqual(confirmed.count, 1)
    }

    /// 上游 `showConfirm` 为假时点选即确认（range 需选满两端）。
    func testCalendarWithoutConfirmEmitsOnTap() {
        var confirmed: [UPCalendarSelection] = []
        let single = UPCalendar(minDate: Self.day(2026, 9, 1), showConfirm: false)
            .onConfirm { confirmed.append($0) }
        single.select(Self.day(2026, 9, 3))
        XCTAssertEqual(confirmed.count, 1)

        let range = UPCalendar(mode: "range", minDate: Self.day(2026, 9, 1), showConfirm: false)
            .onConfirm { confirmed.append($0) }
        range.select(Self.day(2026, 9, 3))
        XCTAssertEqual(confirmed.count, 1)
        range.select(Self.day(2026, 9, 5))
        XCTAssertEqual(confirmed.count, 2)
    }

    /// 上游 `isForbid` 只在非 range 模式生效。
    func testCalendarForbidDaysOnlyApplyOutsideRangeMode() {
        let forbidden = Self.day(2026, 10, 5)
        let single = UPCalendar(minDate: Self.day(2026, 10, 1), forbidDays: [forbidden])
        XCTAssertTrue(single.isForbidden(forbidden))
        single.select(forbidden)
        XCTAssertFalse(single.isSelected(forbidden))

        let range = UPCalendar(mode: "range", minDate: Self.day(2026, 10, 1), forbidDays: [forbidden])
        XCTAssertFalse(range.isForbidden(forbidden))
        range.select(forbidden)
        XCTAssertTrue(range.isSelected(forbidden))
    }

    /// 上游 `getBottomInfo`：range 模式给首尾补「开始」/「结束」，同天时合成一格。
    /// 传 `defaultDate: []` 才是空选中态：上游 `setDefaultDate` 在 `defaultDate`
    /// 为空值时会无条件选中今天（range 模式也一样）。
    func testCalendarBottomInfoMarksRangeEnds() {
        let calendar = UPCalendar(mode: "range", minDate: Self.day(2026, 11, 1), defaultDate: [])
        calendar.select(Self.day(2026, 11, 3))
        let start = calendar.months[0].days[2]
        XCTAssertEqual(calendar.bottomInfo(for: start), "开始")
        calendar.select(Self.day(2026, 11, 5))
        XCTAssertEqual(calendar.bottomInfo(for: calendar.months[0].days[2]), "开始")
        XCTAssertEqual(calendar.bottomInfo(for: calendar.months[0].days[4]), "结束")
        XCTAssertEqual(calendar.bottomInfo(for: calendar.months[0].days[3]), "")

        let sameDay = UPCalendar(mode: "range",
                                 minDate: Self.day(2026, 11, 1),
                                 defaultDate: [],
                                 allowSameDay: true)
        sameDay.select(Self.day(2026, 11, 3))
        sameDay.select(Self.day(2026, 11, 3))
        XCTAssertEqual(sameDay.bottomInfo(for: sameDay.months[0].days[2]), "开始/结束")
    }

    /// 上游 `monthSwitch` 下的月/年切换与「今天」跳转。
    func testCalendarMonthSwitchNavigation() {
        let calendar = UPCalendar(minDate: Self.day(2026, 1, 1),
                                  maxDate: Self.day(2027, 12, 31),
                                  monthNum: 24,
                                  monthSwitch: true)
        XCTAssertEqual(calendar.months.count, 24)
        XCTAssertTrue(calendar.switchPrevDisabled)
        XCTAssertFalse(calendar.switchNextDisabled)
        calendar.nextMonth()
        XCTAssertEqual(calendar.monthIndex, 1)
        calendar.nextYear()
        XCTAssertEqual(calendar.monthIndex, 13)
        calendar.prevYear()
        XCTAssertEqual(calendar.monthIndex, 1)
        calendar.prevMonth()
        XCTAssertEqual(calendar.monthIndex, 0)
        XCTAssertEqual(calendar.currentMonths.count, 1)
        // 上游 `subtitle` 跟随 monthIndex。
        XCTAssertFalse(calendar.subtitle.isEmpty)
    }

    /// 上游 `todayDisabled` / `jumpToToday`：range 模式只跳月不选中。
    func testCalendarJumpToTodayHonoursModeAndBounds() {
        let today = Calendar.current.startOfDay(for: Date())
        let single = UPCalendar(minDate: today, monthNum: 3)
        XCTAssertFalse(single.todayDisabled)
        single.jumpToToday()
        XCTAssertTrue(single.isSelected(today))

        let range = UPCalendar(mode: "range", minDate: today, defaultDate: [], monthNum: 3)
        range.jumpToToday()
        XCTAssertTrue(range.selectedDates.isEmpty)

        let futureOnly = UPCalendar(minDate: Calendar.current.date(byAdding: .day, value: 5, to: today))
        XCTAssertTrue(futureOnly.todayDisabled)
    }

    /// 上游 `enableTime`：`showTimePanel` 的条件与确认值拼接时间。
    func testCalendarTimePanelAppendsTimeToConfirmValue() {
        let single = UPCalendar(minDate: Self.day(2026, 2, 1),
                                enableTime: true,
                                timePrecision: "second",
                                defaultTime: "08:30:15")
        XCTAssertTrue(single.showTimePanel)
        XCTAssertEqual(single.defaultTimeText, "08:30:15")
        single.select(Self.day(2026, 2, 3))
        XCTAssertEqual(single.selection.texts, ["2026-02-03 08:30:15"])
        single.setTime("09:00:00", for: "single")
        XCTAssertEqual(single.selection.texts, ["2026-02-03 09:00:00"])

        // range + all 模式下上游不显示时间面板。
        XCTAssertFalse(UPCalendar(mode: "range", enableTime: true).showTimePanel)
        XCTAssertTrue(UPCalendar(mode: "range", rangeResultMode: "boundary", enableTime: true).showTimePanel)
    }

    /// 上游 `validateSameDayRangeTime`：同一天时结束时间不能早于开始时间。
    func testCalendarRejectsInvertedTimeOnSameDay() {
        let calendar = UPCalendar(mode: "range",
                                  minDate: Self.day(2026, 2, 1),
                                  allowSameDay: true,
                                  rangeResultMode: "boundary",
                                  enableTime: true)
        calendar.select(Self.day(2026, 2, 5))
        calendar.select(Self.day(2026, 2, 5))
        calendar.setTime("10:00", for: "start")
        calendar.setTime("09:00", for: "end")
        XCTAssertFalse(calendar.validateSameDayRangeTime())
        XCTAssertNil(calendar.confirm())
        calendar.setTime("11:00", for: "end")
        XCTAssertTrue(calendar.validateSameDayRangeTime())
        XCTAssertNotNil(calendar.confirm())
    }

    /// `showLunar` 用 Foundation 的农历历法给底部补农历日名。
    func testCalendarLunarBottomInfoIsFilled() {
        let calendar = UPCalendar(minDate: Self.day(2026, 3, 1), showLunar: true)
        XCTAssertFalse(calendar.months[0].days[0].bottomInfo.isEmpty)
        XCTAssertTrue(UPCalendar(minDate: Self.day(2026, 3, 1)).months[0].days[0].bottomInfo.isEmpty)
    }

    /// 时间与月份的格式化工具。
    func testCalendarFormatHelpers() {
        XCTAssertEqual(UPCalendarFormat.dateText(Self.day(2026, 4, 5)), "2026-04-05")
        XCTAssertEqual(UPCalendarFormat.monthTitle(year: 2026, month: 4, format: "YYYY/MM"), "2026/04")
        XCTAssertEqual(UPCalendarFormat.padTime(7), "07")
        XCTAssertEqual(UPCalendarFormat.parseTime("25:70:99").hour, 23)
        XCTAssertEqual(UPCalendarFormat.parseTime("").minute, 0)
        XCTAssertEqual(UPCalendarFormat.timeText(hour: 1, minute: 2, second: 3, precision: "hour"), "01")
        XCTAssertEqual(UPCalendarFormat.timeText(hour: 1, minute: 2, second: 3, precision: "minute"), "01:02")
        XCTAssertEqual(UPCalendarFormat.seconds(of: "01:02:03"), 3_723)
        XCTAssertEqual(UPCalendar.dates(from: Self.day(2026, 4, 1), to: Self.day(2026, 4, 3)).count, 3)
        // `Number.MAX_SAFE_INTEGER` 语义：非正数回落到默认值。
        XCTAssertEqual(UPCalendar.resolveCount("0", fallback: 9), 9)
        XCTAssertEqual(UPCalendar.resolveCount("5", fallback: 9), 5)
        XCTAssertEqual(UPCalendar.resolveCount(String(Int.max), fallback: 9), Int.max)
    }

    /// `v-model:show` 版本关闭时会写回绑定并抛 `close`。
    func testCalendarCloseWritesBackShowBinding() {
        var visible = true
        var closed = 0
        let calendar = UPCalendar(show: Binding(get: { visible }, set: { visible = $0 }))
            .onClose { closed += 1 }
        XCTAssertTrue(calendar.show)
        calendar.close()
        XCTAssertFalse(visible)
        XCTAssertEqual(closed, 1)
    }

    func testCalendarStripSupportsDateBindingAndDisabledDates() {
        var selected: Date? = nil
        var changed: UPCalendarStripChange?
        let disabled = Date(timeIntervalSince1970: 2)
        let strip = UPCalendarStrip(
            dates: [Date(timeIntervalSince1970: 1), disabled, Date(timeIntervalSince1970: 3)],
            modelValue: Binding(get: { selected }, set: { selected = $0 }),
            disabledDates: [disabled]
        ).onChangePayload { changed = $0 }

        strip.select(1)
        XCTAssertNil(selected)
        strip.select(2)
        XCTAssertEqual(selected, Date(timeIntervalSince1970: 3))
        XCTAssertEqual(changed?.date, selected)
    }

    func testCalendarStripRejectsDatesOutsideBounds() {
        var selected: Date?
        let strip = UPCalendarStrip(
            dates: [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 2), Date(timeIntervalSince1970: 3)],
            modelValue: Binding(get: { selected }, set: { selected = $0 }),
            minDate: Date(timeIntervalSince1970: 2),
            maxDate: Date(timeIntervalSince1970: 2)
        )

        strip.select(0)
        XCTAssertNil(selected)
        strip.select(1)
        XCTAssertEqual(selected, Date(timeIntervalSince1970: 2))
        strip.select(2)
        XCTAssertEqual(selected, Date(timeIntervalSince1970: 2))
    }

    /// `calendarStrip.js`：`color: '#3c9cff'`、`weekText` 走 `t('up.week.*')`、
    /// `fullCalendar: true`、`fullMonthNum: 24`、`pullDownThreshold: 40`、
    /// `collapseAfterSelect: true`、`readonly: false`、`showToday: true`、
    /// `monthFormat: ''`、`expandHint: '下拉展开月历'`、`collapseHint: '上拉收起月历'`。
    func testCalendarStripPropDefaultsMatchUpstream() {
        let strip = UPCalendarStrip(modelValue: nil)
        XCTAssertNil(strip.minDate)
        XCTAssertNil(strip.maxDate)
        XCTAssertEqual(strip.color, "#3c9cff")
        XCTAssertEqual(strip.weekText, ["一", "二", "三", "四", "五", "六", "日"])
        XCTAssertTrue(strip.fullCalendar)
        XCTAssertEqual(strip.fullCalendarProps, [:])
        XCTAssertEqual(strip.fullMonthNum, 24)
        XCTAssertEqual(strip.pullDownThreshold, 40)
        XCTAssertTrue(strip.collapseAfterSelect)
        XCTAssertFalse(strip.readonly)
        XCTAssertTrue(strip.showToday)
        XCTAssertEqual(strip.monthFormat, "")
        XCTAssertEqual(strip.expandHint, "下拉展开月历")
        XCTAssertEqual(strip.collapseHint, "上拉收起月历")
        // 上游 `watch.modelValue` 是 immediate 的：没给值时落到今天。
        XCTAssertFalse(strip.isListMode)
        XCTAssertNotNil(strip.selectedDate)
        XCTAssertEqual(strip.currentMonth, UPCalendarStrip.startOfMonth(Date()))
    }

    /// `fullMonthNum` / `pullDownThreshold` 是 `String | Number`，走 `UPUnit` 解析。
    func testCalendarStripAcceptsStringUnitProps() {
        let strip = UPCalendarStrip(fullMonthNum: "6", pullDownThreshold: "60")
        XCTAssertEqual(strip.fullMonthNum, 6)
        XCTAssertEqual(strip.pullDownThreshold, 60)
        // 上游 `Math.max(1, Number(...) || 24)`：解析不出来时兜到有效值。
        XCTAssertEqual(UPCalendarStrip(fullMonthNum: 0).fullMonthNum, 1)
        XCTAssertEqual(UPCalendarStrip(pullDownThreshold: 0).pullDownThreshold, 40)
    }

    /// 上游 `monthDays`：按当前月生成，`disabled` 由 min/max 决定，`today` 标记今天。
    func testCalendarStripBuildsMonthDaysForCurrentMonth() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 2, day: 10))!
        let strip = UPCalendarStrip(modelValue: .constant(start),
                                    minDate: calendar.date(from: DateComponents(year: 2026, month: 2, day: 5)),
                                    maxDate: calendar.date(from: DateComponents(year: 2026, month: 2, day: 20)))
        let days = strip.monthDays
        XCTAssertEqual(days.count, 28)
        XCTAssertEqual(days.first?.day, 1)
        XCTAssertTrue(days[0].disabled)
        XCTAssertFalse(days[9].disabled)
        XCTAssertTrue(days[9].selected)
        XCTAssertTrue(days[20].disabled)
        XCTAssertFalse(days.contains { $0.today })
    }

    /// 上游 `getWeekLabel(week)`：`week === 0`（周日）取末位。
    func testCalendarStripWeekLabelStartsOnMonday() {
        let strip = UPCalendarStrip(modelValue: nil)
        XCTAssertEqual(strip.weekLabel(for: 2), "一")
        XCTAssertEqual(strip.weekLabel(for: 7), "六")
        XCTAssertEqual(strip.weekLabel(for: 1), "日")
        XCTAssertEqual(UPCalendarStrip(weekText: ["Mon"]).weekLabel(for: 7), "")
    }

    /// 上游 `monthLabel`：`monthFormat` 为空时按语言取默认串，否则套 dayjs 格式。
    func testCalendarStripMonthLabelFollowsFormat() {
        let month = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        XCTAssertEqual(UPCalendarStrip.monthLabel(for: month, format: "YYYY/MM"), "2026/03")
        XCTAssertEqual(UPCalendarStrip.monthLabel(for: month, format: "YY年M月"), "26年3月")
        let auto = UPCalendarStrip.monthLabel(for: month, format: "")
        XCTAssertTrue(auto == "2026年03月" || auto == "03/2026")
    }

    /// 上游 `switchMonth`：切月后保留「几号」，越界则退到目标月第一个可选日期，
    /// 并抛出 `change` + `monthChange`（scene 为 `switch`）。
    func testCalendarStripSwitchMonthKeepsDayAndEmitsMonthChange() {
        let calendar = Calendar.current
        var selected: Date? = calendar.date(from: DateComponents(year: 2026, month: 3, day: 31))
        var changes: [UPCalendarStripChange] = []
        var months: [UPCalendarStripMonthChange] = []
        let strip = UPCalendarStrip(modelValue: Binding(get: { selected }, set: { selected = $0 }))
            .onChangePayload { changes.append($0) }
            .onMonthChange { months.append($0) }

        strip.prevMonth()
        XCTAssertEqual(calendar.component(.month, from: selected!), 2)
        // 2026-02 只有 28 天，上游用 `Math.min(selectedDay, daysInMonth)`。
        XCTAssertEqual(calendar.component(.day, from: selected!), 28)
        XCTAssertEqual(changes.map(\.scene), ["switch"])
        XCTAssertEqual(months.map(\.scene), ["switch"])
        XCTAssertEqual(months.first?.month, UPCalendarStrip.startOfMonth(selected!))
    }

    /// 上游 `switchPrevDisabled` / `switchNextDisabled` 只看月份粒度。
    func testCalendarStripDisablesMonthSwitchAtBounds() {
        let calendar = Calendar.current
        let day = calendar.date(from: DateComponents(year: 2026, month: 4, day: 15))!
        let strip = UPCalendarStrip(modelValue: .constant(day),
                                    minDate: calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)),
                                    maxDate: calendar.date(from: DateComponents(year: 2026, month: 4, day: 30)))
        XCTAssertTrue(strip.switchPrevDisabled)
        XCTAssertTrue(strip.switchNextDisabled)
        XCTAssertFalse(UPCalendarStrip(modelValue: .constant(day)).switchPrevDisabled)
    }

    /// 上游 `panelMinDate` / `panelMaxDate` / `panelMonthNum`：没有 min/max 时
    /// 以当前月为轴向两侧各推 `fullMonthNum - 1` 个月。
    func testCalendarStripFullCalendarRangeFollowsFullMonthNum() {
        let calendar = Calendar.current
        let day = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10))!
        let strip = UPCalendarStrip(modelValue: .constant(day), fullMonthNum: 3)
        XCTAssertEqual(strip.panelMinDate, calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        XCTAssertEqual(strip.panelMaxDate, calendar.date(from: DateComponents(year: 2026, month: 8, day: 31)))
        XCTAssertEqual(strip.panelMonthNum, 5)
    }

    /// 上游 `toggleFull` / `setFullVisible`：`fullCalendar` 为假时不响应，
    /// 状态没变化也不重复抛事件。
    func testCalendarStripToggleFullEmitsSourceAndHonoursFlag() {
        var toggles: [UPCalendarStripToggle] = []
        let strip = UPCalendarStrip(modelValue: nil).onToggleFull { toggles.append($0) }
        strip.toggleFull()
        XCTAssertTrue(strip.showsFullCalendar)
        XCTAssertEqual(strip.pullHintText, "上拉收起月历")
        strip.setFullVisible(true)
        XCTAssertEqual(toggles.count, 1)
        strip.toggleFull(source: "hint")
        XCTAssertFalse(strip.showsFullCalendar)
        XCTAssertEqual(toggles.map(\.source), ["button", "hint"])
        XCTAssertEqual(toggles.map(\.show), [true, false])
        XCTAssertEqual(strip.pullHintText, "下拉展开月历")

        var disabledToggles: [UPCalendarStripToggle] = []
        let disabled = UPCalendarStrip(modelValue: nil, fullCalendar: false)
            .onToggleFull { disabledToggles.append($0) }
        disabled.toggleFull()
        XCTAssertFalse(disabled.showsFullCalendar)
        XCTAssertTrue(disabledToggles.isEmpty)
    }

    /// 上游 `onPanelConfirm`：选中后按 `collapseAfterSelect` 决定是否自动收起，
    /// 收起时 `source` 是 `auto`，`change` 的 scene 是 `full`。
    func testCalendarStripFullCalendarConfirmCollapsesWhenEnabled() {
        let day = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 6))!
        var scenes: [String] = []
        var toggles: [UPCalendarStripToggle] = []
        let strip = UPCalendarStrip(modelValue: nil)
            .onChangePayload { scenes.append($0.scene) }
            .onToggleFull { toggles.append($0) }
        strip.toggleFull()
        strip.confirmFromFullCalendar(day)
        XCTAssertEqual(scenes, ["full"])
        XCTAssertFalse(strip.showsFullCalendar)
        XCTAssertEqual(toggles.last?.source, "auto")

        let kept = UPCalendarStrip(modelValue: nil, collapseAfterSelect: false)
        kept.toggleFull()
        kept.confirmFromFullCalendar(day)
        XCTAssertTrue(kept.showsFullCalendar)
    }

    /// 上游 `change` 与 `confirm` 同时抛出、负载一致；`readonly` 时不响应点击。
    func testCalendarStripEmitsConfirmAlongsideChangeAndHonoursReadonly() {
        let day = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 8))!
        var changes: [UPCalendarStripChange] = []
        var confirms: [UPCalendarStripChange] = []
        let strip = UPCalendarStrip(modelValue: nil)
            .onChangePayload { changes.append($0) }
            .onConfirm { confirms.append($0) }
        strip.select(day)
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(confirms.first?.date, changes.first?.date)
        XCTAssertEqual(changes.first?.scene, "tap")

        // 上游 `readonly` 只挡 `onDayTap`：`switchMonth` / `prevMonth` 与 header 的
        // 切月按钮都没有这层判断，照抄该行为。
        var readonlyChanges: [UPCalendarStripChange] = []
        let readonly = UPCalendarStrip(modelValue: nil, readonly: true)
            .onChangePayload { readonlyChanges.append($0) }
        readonly.select(day)
        XCTAssertTrue(readonlyChanges.isEmpty)
        readonly.prevMonth()
        XCTAssertEqual(readonlyChanges.map(\.scene), ["switch"])
    }

    /// 上游 `clampDate`：越界的值被夹到边界，而不是被丢弃。
    func testCalendarStripClampsDatesIntoBounds() {
        let calendar = Calendar.current
        let min = calendar.date(from: DateComponents(year: 2026, month: 8, day: 10))!
        let max = calendar.date(from: DateComponents(year: 2026, month: 8, day: 20))!
        let strip = UPCalendarStrip(modelValue: .constant(min), minDate: min, maxDate: max)
        XCTAssertEqual(strip.clamped(calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!), min)
        XCTAssertEqual(strip.clamped(calendar.date(from: DateComponents(year: 2026, month: 8, day: 25))!), max)
        XCTAssertEqual(strip.firstEnabledDate(inMonth: min), min)
    }
}

@MainActor
final class CommerceComponentTests: XCTestCase {
    func testCouponClaimUpdatesStateAndEmitsEvent() {
        var claimed = ""
        let coupon = UPCoupon(id: "c1", title: "10 off", value: 10).onClaim { claimed = $0.id }
        XCTAssertFalse(coupon.isClaimed)
        coupon.claim()
        XCTAssertTrue(coupon.isClaimed)
        XCTAssertEqual(claimed, "c1")
    }

    func testCouponMapsDisplayPropsAndSuppressesDisabledClick() {
        var clicks = 0
        let coupon = UPCoupon(amount: "20", unit: "¥", limit: "满100可用", title: "满减券",
                              desc: "全场通用", time: "2026-08-31", actionText: "使用", disabled: true)
            .onClick { clicks += 1 }

        coupon.click()
        XCTAssertEqual(clicks, 0)
        XCTAssertEqual(coupon.amount, "20")
        XCTAssertEqual(coupon.limit, "满100可用")
        _ = UPCoupon()
    }

    /// 上游 props 内联在 `.vue` 里：`amount: ''`、`unit: '￥'`、`unitPosition: 'left'`、
    /// `limit: ''`、`title: '优惠券'`、`desc: ''`、`time: ''`、`actionText: '使用'`、
    /// `shape: 'coupon'`、`size: 'medium'`、`circle: false`、`disabled: false`、
    /// `bgColor: ''`、`color: ''`、`type: ''`。
    func testCouponPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.coupon.unit, "￥")
        XCTAssertEqual(UPConfig.coupon.unitPosition, "left")
        XCTAssertEqual(UPConfig.coupon.title, "优惠券")
        XCTAssertEqual(UPConfig.coupon.actionText, "使用")
        XCTAssertEqual(UPConfig.coupon.shape, "coupon")
        XCTAssertEqual(UPConfig.coupon.size, "medium")
        XCTAssertFalse(UPConfig.coupon.circle)
        XCTAssertFalse(UPConfig.coupon.disabled)
        XCTAssertEqual(UPConfig.coupon.type, "")

        let coupon = UPCoupon(amount: 100)
        XCTAssertEqual(coupon.amount, "100")
        XCTAssertEqual(coupon.value, 100)
        XCTAssertEqual(coupon.unit, "￥")
        XCTAssertEqual(coupon.unitPosition, "left")
        XCTAssertEqual(coupon.title, "优惠券")
        XCTAssertEqual(coupon.actionText, "使用")
        XCTAssertEqual(coupon.shape, "coupon")
        XCTAssertEqual(coupon.size, "medium")
        XCTAssertTrue(coupon.showsUnitBeforeAmount)
        XCTAssertEqual(coupon.displayAmount, "￥100")

        let suffixed = UPCoupon(amount: "88", unit: "折", unitPosition: "right")
        XCTAssertFalse(suffixed.showsUnitBeforeAmount)
        XCTAssertEqual(suffixed.displayAmount, "88折")
    }

    /// 上游 `dotCount` 与三档 `size` 的高度：160 / 180 / 220 rpx。
    func testCouponSizeMapsHeightAndDotCount() {
        XCTAssertEqual(UPCoupon(amount: "1", size: "small").dotCount, 8)
        XCTAssertEqual(UPCoupon(amount: "1", size: "medium").dotCount, 10)
        XCTAssertEqual(UPCoupon(amount: "1", size: "large").dotCount, 12)
        // 上游 `map[this.size] || 10`：未命中回落 10。
        XCTAssertEqual(UPCoupon(amount: "1", size: "huge").dotCount, 10)

        XCTAssertEqual(UPCoupon(amount: "1", size: "small").resolvedHeight, UPUnit.rpx(CGFloat(160)))
        XCTAssertEqual(UPCoupon(amount: "1", size: "medium").resolvedHeight, UPUnit.rpx(CGFloat(180)))
        XCTAssertEqual(UPCoupon(amount: "1", size: "large").resolvedHeight, UPUnit.rpx(CGFloat(220)))
    }

    /// 上游四个内置主题类会把底色换成渐变、文字与金额刷白，虚线换成 #eee。
    func testCouponTypeSwitchesToGradientTheme() {
        let plain = UPCoupon(amount: "10")
        XCTAssertNil(plain.gradientColors)
        XCTAssertEqual(plain.resolvedTextColor, "main")
        // 无 type 时上游把金额写死成红色。
        XCTAssertEqual(plain.resolvedAmountColor, "#ff0000")
        XCTAssertEqual(plain.resolvedDashColor, "#cccccc")
        // 默认 action 标签是实心红底。
        XCTAssertEqual(plain.actionTagBackgroundColor, "#eb433d")
        XCTAssertEqual(plain.actionTagBorderColor, "#eb433d")

        let themed = UPCoupon(amount: "10", type: "success")
        XCTAssertEqual(themed.gradientColors, ["#67dda9", "#19be6b"])
        XCTAssertEqual(themed.resolvedTextColor, "#ffffff")
        XCTAssertEqual(themed.resolvedAmountColor, "#ffffff")
        XCTAssertEqual(themed.resolvedDashColor, "#eeeeee")
        // type 非空时标签换成透明底 + #eee 边框。
        XCTAssertEqual(themed.actionTagBackgroundColor, "transparent")
        XCTAssertEqual(themed.actionTagBorderColor, "#eeeeee")

        // couponStyle.color 优先级最高。
        let colored = UPCoupon(amount: "10", color: "#333333", type: "primary")
        XCTAssertEqual(colored.resolvedTextColor, "#333333")
        XCTAssertEqual(colored.resolvedAmountColor, "#333333")

        // 未命中的 type 不换主题。
        XCTAssertNil(UPCoupon(amount: "10", type: "info").gradientColors)
    }

    func testCouponExposesAllUpstreamSlots() {
        let plain = UPCoupon(amount: "10")
        XCTAssertFalse(plain.hasAmountSlot)
        XCTAssertFalse(plain.hasUnitSlot)
        XCTAssertFalse(plain.hasLimitSlot)
        XCTAssertFalse(plain.hasTitleSlot)
        XCTAssertFalse(plain.hasDescSlot)
        XCTAssertFalse(plain.hasTimeSlot)
        XCTAssertFalse(plain.hasActionSlot)
        XCTAssertFalse(plain.hasContentSlot)

        let slotted = plain
            .amountContent { Text($0) }
            .unitContent { unit, position in Text("\(unit)-\(position)") }
            .limitContent { Text($0) }
            .titleContent { Text($0) }
            .descContent { Text($0) }
            .timeContent { Text($0) }
            .actionContent { text, circle in Text("\(text)-\(circle)") }
            .content { Text("extra") }
        XCTAssertTrue(slotted.hasAmountSlot)
        XCTAssertTrue(slotted.hasUnitSlot)
        XCTAssertTrue(slotted.hasLimitSlot)
        XCTAssertTrue(slotted.hasTitleSlot)
        XCTAssertTrue(slotted.hasDescSlot)
        XCTAssertTrue(slotted.hasTimeSlot)
        XCTAssertTrue(slotted.hasActionSlot)
        XCTAssertTrue(slotted.hasContentSlot)
    }

    func testGoodsSkuOnlyConfirmsCompleteSelection() {
        var confirmed: [String: String] = [:]
        let sku = UPGoodsSku(options: [
            UPGoodsSkuOption(name: "Color", values: ["Red", "Blue"]),
            UPGoodsSkuOption(name: "Size", values: ["S", "M"])
        ]).onConfirm { confirmed = $0 }
        sku.select("Color", value: "Red")
        XCTAssertFalse(sku.confirm())
        sku.select("Size", value: "M")
        XCTAssertTrue(sku.confirm())
        XCTAssertEqual(confirmed["Color"], "Red")
    }

    func testGoodsSkuRejectsUnavailableCombinationAndBindsQuantity() {
        var quantity = 1
        let sku = UPGoodsSku(
            options: [
                UPGoodsSkuOption(name: "Color", values: ["Red", "Blue"]),
                UPGoodsSkuOption(name: "Size", values: ["S", "M"])
            ],
            combinations: [
                UPGoodsSkuCombination(selections: ["Color": "Red", "Size": "S"], stock: 2)
            ],
            quantity: Binding(get: { quantity }, set: { quantity = $0 }),
            maxBuy: 5
        )

        XCTAssertTrue(sku.isDisabled("Color", value: "Blue"))
        sku.select("Color", value: "Red")
        sku.select("Size", value: "S")
        XCTAssertTrue(sku.setQuantity(3) == false)
        XCTAssertEqual(quantity, 1)
        XCTAssertTrue(sku.setQuantity(2))
        XCTAssertEqual(quantity, 2)
    }

    /// `u-goods-sku.vue` 的内联 props：`goodsInfo: {}`、`skuTree: []`、
    /// `skuList: []`、`maxBuy: 999`、`confirmText: '确定'`、`closeable: true`、
    /// `pageInline: false`。
    func testGoodsSkuPropDefaultsMatchUpstream() {
        let sku = UPGoodsSku(goodsInfo: UPGoodsInfo())
        XCTAssertEqual(sku.maxBuy, 999)
        XCTAssertEqual(sku.confirmText, "确定")
        XCTAssertTrue(sku.closeable)
        XCTAssertFalse(sku.pageInline)
        XCTAssertTrue(sku.skuTree.isEmpty)
        XCTAssertTrue(sku.skuList.isEmpty)
        XCTAssertFalse(sku.show)
        XCTAssertFalse(sku.hasTriggerSlot)
        XCTAssertFalse(sku.hasHeaderSlot)
        // 上游 `created`：pageInline 为真时直接展开。
        XCTAssertTrue(UPGoodsSku(pageInline: true).show)
    }

    /// 上游 `price` / `stock` / `maxBuyNum` / `canBuy` / `selectedSkuText`。
    func testGoodsSkuDerivesPriceStockAndSelectedText() {
        let tree = [
            UPGoodsSkuTreeItem(name: "color", label: "颜色", children: [
                UPGoodsSkuLeaf(id: "1", name: "红色"),
                UPGoodsSkuLeaf(id: "2", name: "蓝色")
            ]),
            UPGoodsSkuTreeItem(name: "size", label: "尺码", children: [
                UPGoodsSkuLeaf(id: "s", name: "S"),
                UPGoodsSkuLeaf(id: "m", name: "M")
            ])
        ]
        let list = [
            UPGoodsSkuItem(selections: ["color": "1", "size": "s"], stock: 3, price: 88),
            UPGoodsSkuItem(selections: ["color": "1", "size": "m"], stock: 0, price: 99)
        ]
        let sku = UPGoodsSku(goodsInfo: UPGoodsInfo(image: "/a.png", price: 100, stock: 20),
                             skuTree: tree,
                             skuList: list,
                             maxBuy: 2)

        // 未选满时用商品自身的价与库存。
        XCTAssertEqual(sku.price, 100)
        XCTAssertEqual(sku.stock, 20)
        XCTAssertEqual(sku.maxBuyNum, 2)
        XCTAssertFalse(sku.canBuy)
        XCTAssertEqual(sku.selectedSkuText, "")

        sku.select("color", value: "1")
        sku.select("size", value: "s")
        XCTAssertEqual(sku.price, 88)
        XCTAssertEqual(sku.stock, 3)
        XCTAssertEqual(sku.maxBuyNum, 2)
        XCTAssertTrue(sku.canBuy)
        XCTAssertEqual(sku.selectedSkuText, "红色, S")

        // 库存为 0 的组合被置灰。
        XCTAssertTrue(sku.isDisabled("size", value: "m"))
    }

    /// 上游 `confirm` 负载是 `{ sku, goodsInfo, num, selectedText }`。
    func testGoodsSkuConfirmEventCarriesUpstreamPayload() {
        var events: [UPGoodsSkuConfirmEvent] = []
        let sku = UPGoodsSku(goodsInfo: UPGoodsInfo(price: 100, stock: 10),
                             skuTree: [UPGoodsSkuTreeItem(name: "color", label: "颜色",
                                                          children: [UPGoodsSkuLeaf(id: "1", name: "红色")])],
                             skuList: [UPGoodsSkuItem(selections: ["color": "1"], stock: 5, price: 66)])
            .onConfirmEvent { events.append($0) }

        XCTAssertFalse(sku.confirm())
        sku.select("color", value: "1")
        XCTAssertTrue(sku.confirm())
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.num, 1)
        XCTAssertEqual(events.first?.selectedText, "红色")
        XCTAssertEqual(events.first?.sku?.price, 66)
        XCTAssertEqual(events.first?.goodsInfo.price, 100)
    }

    /// 上游 `open()` / `close()` / `reset()`。
    func testGoodsSkuOpenCloseAndReset() {
        var opened = 0
        var closed = 0
        let sku = UPGoodsSku(skuTree: [UPGoodsSkuTreeItem(name: "color",
                                                          children: [UPGoodsSkuLeaf(id: "1", name: "红")])])
            .onOpen { opened += 1 }
            .onClose { closed += 1 }
        sku.open()
        XCTAssertTrue(sku.show)
        XCTAssertEqual(opened, 1)
        sku.select("color", value: "1")
        XCTAssertEqual(sku.selections["color"], "1")
        sku.reset()
        XCTAssertTrue(sku.selections.isEmpty)
        XCTAssertEqual(sku.quantity, 1)
        sku.close()
        XCTAssertFalse(sku.show)
        XCTAssertEqual(closed, 1)
    }
}

@MainActor
final class NavigationBusinessTests: XCTestCase {
    func testCateTabSelectionEmitsIndexAndValue() {
        var selected = ""
        let tabs = UPCateTab(items: ["全部", "数码"]).onChange { selected = $0.value }
        tabs.select(1)
        XCTAssertEqual(tabs.current, 1)
        XCTAssertEqual(selected, "数码")
    }

    func testCateTabBindsCurrentAndEmitsStructuredChange() {
        var current = 0
        var change: UPCateTabChange?
        let tabs = UPCateTab(items: ["全部", "数码"], current: Binding(get: { current }, set: { current = $0 }))
            .onChangePayload { change = $0 }

        tabs.select(1)
        XCTAssertEqual(current, 1)
        XCTAssertEqual(change?.index, 1)
        XCTAssertEqual(change?.item.value, "数码")
    }

    /// `u-cate-tab.vue` 的内联 props：`mode: 'follow'`、`height: '100%'`、
    /// `tabList: []`、`tabKeyName: 'name'`、`itemKeyName: 'name'`、`current: 0`。
    func testCateTabPropDefaultsMatchUpstream() {
        let tabs = UPCateTab()
        XCTAssertEqual(tabs.mode, "follow")
        XCTAssertEqual(tabs.height, "100%")
        XCTAssertEqual(tabs.tabKeyName, "name")
        XCTAssertEqual(tabs.itemKeyName, "name")
        XCTAssertEqual(tabs.current, 0)
        XCTAssertTrue(tabs.items.isEmpty)
        XCTAssertTrue(tabs.isFollowMode)
        // `100%` 交给父级决定高度。
        XCTAssertNil(tabs.resolvedHeight)
        XCTAssertEqual(UPCateTab(height: "400").resolvedHeight, 400)
        XCTAssertFalse(tabs.hasTabItemSlot)
        XCTAssertFalse(tabs.hasPageItemSlot)
    }

    /// 上游 `tabList` 是对象数组，用 `tabKeyName` / `itemKeyName` 取字段。
    func testCateTabReadsKeyNamesFromObjects() {
        let tabs = UPCateTab(tabList: [["label": "热菜"], ["label": "凉菜"], ["other": "x"]],
                             children: [[["dish": "水煮肉片", "icon": "/a.png"]], []],
                             tabKeyName: "label",
                             itemKeyName: "dish")
        XCTAssertEqual(tabs.items.map(\.title), ["热菜", "凉菜"])
        XCTAssertEqual(tabs.items[0].children.map(\.name), ["水煮肉片"])
        XCTAssertEqual(tabs.items[0].children.first?.icon, "/a.png")
        XCTAssertTrue(tabs.items[1].children.isEmpty)
    }

    /// `mode: 'tab'` 时右侧只铺当前分组，`follow` 铺全部。
    func testCateTabModeControlsVisibleGroups() {
        let items = ["A", "B", "C"].map { UPCateTabItem(title: $0) }
        let follow = UPCateTab(tabList: items)
        XCTAssertEqual(follow.visibleItems.count, 3)

        let single = UPCateTab(tabList: items, mode: "tab", current: 1)
        XCTAssertFalse(single.isFollowMode)
        XCTAssertEqual(single.visibleItems.map(\.title), ["B"])
    }

    /// 上游 `rightScroll` 按每组 `top` 区间反查高亮；`tab` 模式不联动。
    /// 偏移全是 0（尚未量到）时上游 `!height2` 命中第一组，原生照抄。
    func testCateTabSyncCurrentFollowsScrollOffsets() {
        var changes: [Int] = []
        let tabs = UPCateTab(tabList: ["A", "B", "C"].map { UPCateTabItem(title: $0) })
            .onChangePayload { changes.append($0.index) }
        tabs.syncCurrent(scrollTop: 0)
        XCTAssertEqual(tabs.current, 0)
        XCTAssertEqual(changes, [0])

        // `tab` 模式下上游 `rightScroll` 直接 return，不改高亮。
        var singleChanges: [Int] = []
        let single = UPCateTab(tabList: ["A", "B"].map { UPCateTabItem(title: $0) }, mode: "tab")
            .onChangePayload { singleChanges.append($0.index) }
        single.syncCurrent(scrollTop: 500)
        XCTAssertEqual(single.current, 0)
        XCTAssertTrue(singleChanges.isEmpty)
    }

    func testTreeExpandsAndSelectsRecursiveNode() {
        let tree = UPTree(nodes: [UPTreeNode(id: "root", title: "Root", children: [UPTreeNode(id: "child", title: "Child")])])
        tree.toggle("root")
        XCTAssertTrue(tree.isExpanded("root"))
        tree.select("child")
        XCTAssertEqual(tree.selectedIDs, ["child"])
    }

    func testTreeSupportsDisabledMultipleSelectionAndCheckEvents() {
        var selected: [String] = []
        var checkedIDs: Set<String> = []
        var checked: (String, Bool)?
        var expansionEvents: [String] = []
        let tree = UPTree(
            nodes: [
                UPTreeNode(id: "root", title: "Root", children: [
                    UPTreeNode(id: "a", title: "A"),
                    UPTreeNode(id: "b", title: "B", disabled: true)
                ])
            ],
            multiple: true,
            selectedIDs: Binding(get: { selected }, set: { selected = $0 }),
            checkedIDs: Binding(get: { checkedIDs }, set: { checkedIDs = $0 }),
            showCheckbox: true
        ).onCheckChange { node, value in checked = (node.id, value) }
            .onExpand { expansionEvents.append("expand:\($0.id)") }
            .onCollapse { expansionEvents.append("collapse:\($0.id)") }

        tree.select("a")
        tree.select("root")
        XCTAssertEqual(selected, ["a", "root"])
        tree.select("b")
        XCTAssertEqual(selected, ["a", "root"])
        tree.check("a", checked: true)
        XCTAssertEqual(checked?.0, "a")
        XCTAssertEqual(checked?.1, true)
        // 照抄上游 `updateParentChecked`：判定只看未禁用的子节点，b 被禁用后
        // root 的唯一可选子节点 a 一勾选，root 就算全选。
        XCTAssertEqual(checkedIDs, ["a", "root"])
        tree.toggle("root")
        tree.toggle("root")
        XCTAssertEqual(expansionEvents, ["expand:root", "collapse:root"])
    }

    /// 上游 props 内联在 `.vue` 里：`nodeKey: ''`、`showCheckbox: false`、
    /// `defaultExpandAll: false`、`expandOnClickNode: true`、`checkOnClickNode: false`、
    /// `checkStrictly: false`、`accordion: false`、`highlightCurrent: false`、
    /// `currentNodeKey: ''`、`indent: 32`、`iconSize: 14`、`checkboxSize: 16`、
    /// `expandIcon: 'play-right-fill'`、`collapseIcon: 'arrow-down-fill'`。
    func testTreePropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.tree.nodeKey, "")
        XCTAssertFalse(UPConfig.tree.showCheckbox)
        XCTAssertFalse(UPConfig.tree.defaultExpandAll)
        XCTAssertTrue(UPConfig.tree.expandOnClickNode)
        XCTAssertFalse(UPConfig.tree.checkOnClickNode)
        XCTAssertFalse(UPConfig.tree.checkStrictly)
        XCTAssertFalse(UPConfig.tree.accordion)
        XCTAssertFalse(UPConfig.tree.highlightCurrent)
        XCTAssertEqual(UPConfig.tree.currentNodeKey, "")
        XCTAssertEqual(UPConfig.tree.indent, "32")
        XCTAssertEqual(UPConfig.tree.iconSize, "14")
        XCTAssertEqual(UPConfig.tree.checkboxSize, "16")
        XCTAssertEqual(UPConfig.tree.expandIcon, "play-right-fill")
        XCTAssertEqual(UPConfig.tree.collapseIcon, "arrow-down-fill")

        let tree = UPTree(data: [UPTreeNode(id: "a", title: "A")])
        XCTAssertEqual(tree.nodeKey, "")
        // 上游 keyField = nodeKey || props.nodeKey || 'id'。
        XCTAssertEqual(tree.keyField, "id")
        XCTAssertEqual(tree.props.label, "label")
        XCTAssertEqual(tree.props.children, "children")
        XCTAssertEqual(tree.props.disabled, "disabled")
        XCTAssertTrue(tree.expandOnClickNode)
        XCTAssertFalse(tree.checkOnClickNode)
        XCTAssertFalse(tree.checkStrictly)
        XCTAssertFalse(tree.accordion)
        XCTAssertFalse(tree.highlightCurrent)
        XCTAssertEqual(tree.indent, "32")
        XCTAssertEqual(tree.expandIcon, "play-right-fill")
        XCTAssertEqual(tree.collapseIcon, "arrow-down-fill")
        XCTAssertEqual(UPTree(data: [], nodeKey: "code").keyField, "code")
    }

    /// 上游 `getIndentValue(level)`：数字前缀乘层级再拼单位，没写单位补 rpx。
    func testTreeIndentValueMatchesUpstream() {
        XCTAssertEqual(UPTree.indentValue("32", level: 0), "0rpx")
        XCTAssertEqual(UPTree.indentValue("32", level: 2), "64rpx")
        XCTAssertEqual(UPTree.indentValue("16px", level: 3), "48px")
        // 纯非数字原样返回。
        XCTAssertEqual(UPTree.indentValue("auto", level: 2), "auto")
    }

    /// 上游 `visibleNodes` 只铺开已展开的分支，`defaultExpandAll` 会全铺开。
    func testTreeVisibleNodesFollowExpansion() {
        let data = [
            UPTreeNode(id: "root", title: "Root", children: [
                UPTreeNode(id: "a", title: "A", children: [UPTreeNode(id: "a-1", title: "A1")])
            ])
        ]
        let collapsed = UPTree(data: data)
        XCTAssertEqual(collapsed.visibleNodes.map(\.key), ["root"])
        XCTAssertTrue(collapsed.visibleNodes[0].hasChildren)
        XCTAssertEqual(collapsed.visibleNodes[0].level, 0)

        let expandedAll = UPTree(data: data, defaultExpandAll: true)
        XCTAssertEqual(expandedAll.visibleNodes.map(\.key), ["root", "a", "a-1"])
        XCTAssertEqual(expandedAll.visibleNodes.map(\.level), [0, 1, 2])

        // 节点自带 expanded 也算展开。
        let seeded = UPTree(data: [UPTreeNode(id: "root", title: "Root",
                                             children: [UPTreeNode(id: "a", title: "A")],
                                             expanded: true)])
        XCTAssertEqual(seeded.visibleNodes.map(\.key), ["root", "a"])
    }

    /// 上游 `handleNodeClick`：`expandOnClickNode` 默认真，点整行就切换展开；
    /// current 变化时补一发 `current-change`。
    func testTreeNodeClickTogglesExpandAndEmitsCurrentChange() {
        var clicks: [String] = []
        var currentChanges: [String] = []
        let tree = UPTree(data: [
            UPTreeNode(id: "root", title: "Root", children: [UPTreeNode(id: "a", title: "A")])
        ], highlightCurrent: true)
            .onNodeClick { clicks.append($0.id) }
            .onCurrentChange { node, old in currentChanges.append("\(old?.id ?? "nil")->\(node.id)") }

        tree.handleNodeClick("root")
        XCTAssertTrue(tree.isExpanded("root"))
        XCTAssertEqual(tree.currentKey, "root")
        XCTAssertEqual(clicks, ["root"])
        XCTAssertEqual(currentChanges, ["nil->root"])

        // 再点一次收起，current 没变所以不再抛 current-change。
        tree.handleNodeClick("root")
        XCTAssertFalse(tree.isExpanded("root"))
        XCTAssertEqual(currentChanges.count, 1)

        // expandOnClickNode 为假时点整行不再展开。
        let noExpand = UPTree(data: [
            UPTreeNode(id: "root", title: "Root", children: [UPTreeNode(id: "a", title: "A")])
        ], expandOnClickNode: false)
        noExpand.handleNodeClick("root")
        XCTAssertFalse(noExpand.isExpanded("root"))
        // 但点箭头仍然能展开。
        noExpand.handleExpandClick("root")
        XCTAssertTrue(noExpand.isExpanded("root"))
        // 上游 handleExpandClick 对无子节点直接 return。
        noExpand.handleExpandClick("a")
        XCTAssertFalse(noExpand.isExpanded("a"))
    }

    /// 上游 `checkOnClickNode`：为真且 `showCheckbox` 也为真时，点整行连带勾选。
    func testTreeCheckOnClickNodeRequiresCheckbox() {
        let data = [UPTreeNode(id: "a", title: "A")]
        let withoutCheckbox = UPTree(data: data, checkOnClickNode: true)
        withoutCheckbox.handleNodeClick("a")
        XCTAssertTrue(withoutCheckbox.checkedIDs.isEmpty)

        var checkInfos: [UPTreeCheckInfo] = []
        let withCheckbox = UPTree(data: data, showCheckbox: true, checkOnClickNode: true)
            .onCheck { _, info in checkInfos.append(info) }
        withCheckbox.handleNodeClick("a")
        XCTAssertEqual(withCheckbox.checkedIDs, ["a"])
        XCTAssertEqual(checkInfos.count, 1)
        XCTAssertEqual(checkInfos[0].checkedKeys, ["a"])
    }

    /// 上游 `accordion`：展开某节点前先收起同级。
    func testTreeAccordionCollapsesSiblings() {
        let tree = UPTree(data: [
            UPTreeNode(id: "a", title: "A", children: [UPTreeNode(id: "a-1", title: "A1")]),
            UPTreeNode(id: "b", title: "B", children: [UPTreeNode(id: "b-1", title: "B1")])
        ], accordion: true)

        tree.toggleExpand("a")
        tree.toggleExpand("b")
        XCTAssertFalse(tree.isExpanded("a"))
        XCTAssertTrue(tree.isExpanded("b"))
    }

    /// 上游 `setNodeChecked` + `updateParentChecked`：非严格模式下向下铺开、向上推导，
    /// disabled 子节点被跳过且不参与父节点判定。
    func testTreeCascadesCheckedStateAndHalfChecked() {
        let tree = UPTree(data: [
            UPTreeNode(id: "root", title: "Root", children: [
                UPTreeNode(id: "a", title: "A"),
                UPTreeNode(id: "b", title: "B"),
                UPTreeNode(id: "c", title: "C", disabled: true)
            ])
        ], showCheckbox: true)

        tree.handleCheckboxChange("a", checked: true)
        XCTAssertEqual(tree.checkedIDs, ["a"])
        XCTAssertEqual(tree.halfCheckedKeys(), ["root"])
        XCTAssertTrue(tree.indeterminateIDs.contains("root"))

        tree.handleCheckboxChange("b", checked: true)
        // 只看未禁用子节点，a + b 全勾选后 root 即全选，c 仍未被写入。
        XCTAssertEqual(tree.checkedIDs, ["a", "b", "root"])
        XCTAssertTrue(tree.halfCheckedKeys().isEmpty)

        tree.handleCheckboxChange("root", checked: false)
        XCTAssertTrue(tree.checkedIDs.isEmpty)

        // disabled 节点上的勾选被直接忽略。
        tree.handleCheckboxChange("c", checked: true)
        XCTAssertTrue(tree.checkedIDs.isEmpty)
    }

    /// 上游 `checkStrictly`：父子不再联动。
    func testTreeCheckStrictlyKeepsNodesIndependent() {
        let tree = UPTree(data: [
            UPTreeNode(id: "root", title: "Root", children: [UPTreeNode(id: "a", title: "A")])
        ], showCheckbox: true, checkStrictly: true)

        tree.handleCheckboxChange("root", checked: true)
        XCTAssertEqual(tree.checkedIDs, ["root"])
        XCTAssertTrue(tree.halfCheckedKeys().isEmpty)
    }

    /// 上游 `defaultCheckedKeys` 在初始化时就向下铺开并推导父节点。
    func testTreeSeedsDefaultCheckedKeys() {
        let tree = UPTree(data: [
            UPTreeNode(id: "root", title: "Root", children: [
                UPTreeNode(id: "a", title: "A", children: [UPTreeNode(id: "a-1", title: "A1")]),
                UPTreeNode(id: "b", title: "B")
            ])
        ], defaultCheckedKeys: ["a"])

        XCTAssertEqual(tree.checkedIDs, ["a", "a-1"])
        XCTAssertEqual(tree.halfCheckedKeys(), ["root"])
        XCTAssertEqual(tree.checkedKeys(leafOnly: true), ["a-1"])
    }

    /// 上游 `setCheckedKeys(keys, leafOnly)` 先全清再写入。
    func testTreeSetCheckedKeysReplacesSelection() {
        let tree = UPTree(data: [
            UPTreeNode(id: "root", title: "Root", children: [
                UPTreeNode(id: "a", title: "A"),
                UPTreeNode(id: "b", title: "B")
            ])
        ], defaultCheckedKeys: ["a"])

        tree.setCheckedKeys(["b"])
        XCTAssertEqual(tree.checkedIDs, ["b"])
        XCTAssertEqual(tree.halfCheckedKeys(), ["root"])

        // leafOnly 为真时非叶子键被跳过。
        tree.setCheckedKeys(["root"], leafOnly: true)
        XCTAssertTrue(tree.checkedIDs.isEmpty)
    }

    /// 上游 `setCurrentKey` / `getCurrentKey` / `getCurrentNode`。
    func testTreeCurrentKeyAccessors() {
        let tree = UPTree(data: [UPTreeNode(id: "a", title: "A")], currentNodeKey: "a")
        XCTAssertEqual(tree.getCurrentKey(), "a")
        XCTAssertEqual(tree.currentNode?.title, "A")

        tree.setCurrentKey("missing")
        XCTAssertNil(tree.currentNode)
    }

    /// 上游 `props` 的字段名映射：从字典构造节点时生效，缺 key 时按父键 + 下标兜底。
    func testTreeNodesFromDictionariesRespectPropsMapping() {
        let raw: [[String: Any]] = [
            ["name": "父", "kids": [["name": "子"]], "locked": true]
        ]
        let props = UPTreeProps(label: "name", children: "kids", nodeKey: "code", disabled: "locked")
        let nodes = UPTreeNode.nodes(from: raw, props: props)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].title, "父")
        XCTAssertEqual(nodes[0].id, "root-0")
        XCTAssertTrue(nodes[0].disabled)
        XCTAssertEqual(nodes[0].children.map(\.title), ["子"])
        XCTAssertEqual(nodes[0].children[0].id, "root-0-0")
    }

    func testTreeExposesNodeSlot() {
        let tree = UPTree(data: [UPTreeNode(id: "a", title: "A")])
        XCTAssertFalse(tree.hasNodeSlot)
        XCTAssertTrue(tree.nodeContent { item in Text(item.node.title) }.hasNodeSlot)
    }
}
