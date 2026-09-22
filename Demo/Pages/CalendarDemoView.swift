import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsC/calendar/calendar`。
///
/// 上游把 12 个 `up-calendar` 一次性写在模板里，各自用 `showN` 控制；
/// 这里改为一个弹窗 + 一个场景枚举，避免同屏堆叠十多个隐藏弹层。
@MainActor
struct CalendarDemoView: View {
    private enum Scene: String, CaseIterable, Identifiable {
        case single = "单个日期"
        case multiple = "多个日期"
        case range = "日期范围"
        case theme = "自定义主题色"
        case customText = "自定义文案与格式化"
        case lunar = "显示农历"
        case monthSwitch = "单月切换模式"
        case time = "时分选择"

        var id: String { rawValue }
    }

    @State private var scene: Scene?
    @State private var inlineResult = "尚未选择"
    @State private var result = "尚未选择"

    private static func day(_ offset: Int) -> Date {
        let current = Calendar.current
        return current.date(byAdding: .day, value: offset, to: current.startOfDay(for: Date())) ?? Date()
    }

    var body: some View {
        DemoPage {
            inlineSection
            popupSection
            scopeSection
        }
        .overlay { popup }
    }

    private var inlineSection: some View {
        DemoSection("页面行内模式") {
            UPCalendar(showTitle: false,
                       defaultDate: [Self.day(0)],
                       show: true,
                       showConfirm: false,
                       pageInline: true)
                .onConfirm { selection in
                    inlineResult = "行内确认：" + selection.texts.joined(separator: " ~ ")
                }

            tip(inlineResult)
        }
    }

    private var popupSection: some View {
        DemoSection("弹窗模式") {
            ForEach(Scene.allCases) { item in
                UPButton(type: "primary", size: "small", text: item.rawValue) { scene = item }
            }

            tip(result)
        }
    }

    private var scopeSection: some View {
        DemoSection("当前原生范围") {
            Text("原生 UPCalendar 已覆盖上游 43 个 prop，事件为 onConfirm((UPCalendarSelection) -> Void) / onClose / onClosed 外加原生的 onChange((Date) -> Void) / onSelect，方法 confirm() / close() / select(_:) / jumpToToday() / prevMonth() / nextMonth() / prevYear() / nextYear() / openTimePicker(_:) / setTime(_:for:)，并提供 #footer 插槽。三处平台差异：showLunar 上游用内置 calendar.js 算农历，原生借 Foundation 的农历历法只取农历日名，闰月与节气不覆盖；enableTime 的时间选择上游是 picker-view，原生用 Picker 轮盘；上游会量每个月份高度让副标题跟随滚动（updateMonthTop + onScroll），原生副标题只跟随 monthIndex，非 monthSwitch 模式下滚动不改副标题。formatter 与 customList 都已支持，可按日期覆盖 bottomInfo / dot / disabled。上游同页把 12 个日历一次性写在模板里，这里改成一个弹窗加场景切换。")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var popup: some View {
        if let scene {
            calendarView(for: scene)
                .onConfirm { selection in
                    result = "\(scene.rawValue)：\(selection.texts.joined(separator: " ~ "))"
                    self.scene = nil
                }
                .onClose { self.scene = nil }
        }
    }

    private func calendarView(for scene: Scene) -> UPCalendar {
        switch scene {
        case .single:
            return UPCalendar(defaultDate: [Self.day(0)], show: true)
        case .multiple:
            return UPCalendar(mode: "multiple",
                              defaultDate: [Self.day(0), Self.day(1), Self.day(2)],
                              show: true)
        case .range:
            return UPCalendar(mode: "range", defaultDate: [], show: true)
        case .theme:
            return UPCalendar(mode: "range",
                              color: "#f56c6c",
                              defaultDate: [Self.day(0), Self.day(5)],
                              show: true)
        case .customText:
            return UPCalendar(mode: "range",
                              startText: "住店",
                              endText: "离店",
                              defaultDate: [Self.day(0)],
                              formatter: { day in
                                  var day = day
                                  if day.day == 1 { day.bottomInfo = "月初" }
                                  if day.week == 1 || day.week == 7 { day.dot = true }
                                  return day
                              },
                              confirmDisabledText: "请选择离店日期",
                              show: true)
        case .lunar:
            return UPCalendar(defaultDate: [Self.day(0)], showLunar: true, show: true)
        case .monthSwitch:
            return UPCalendar(minDate: Self.day(-365),
                              maxDate: Self.day(365),
                              defaultDate: [Self.day(0)],
                              show: true,
                              monthNum: 24,
                              monthSwitch: true)
        case .time:
            return UPCalendar(defaultDate: [Self.day(0)],
                              show: true,
                              enableTime: true,
                              defaultTime: "09:30")
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
