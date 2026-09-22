import Foundation

/// `change` / `confirm` 的事件负载，对应上游 `{ date, month, scene }`。
/// 上游 `date` 是 `YYYY-MM-DD`、`month` 是 `YYYY-MM`，原生统一用 `Date`
/// （`month` 取该月 1 日 0 点）。`scene` 沿用上游字面量：
/// `sync` / `range` / `tap` / `switch` / `full`。
public struct UPCalendarStripChange: Equatable, Sendable {
    public let date: Date
    public let month: Date
    public let scene: String

    public init(date: Date, scene: String = "select", calendar: Calendar = .current) {
        self.date = date
        self.month = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        self.scene = scene
    }
}

/// `monthChange` 的事件负载，对应上游 `{ month, scene }`。
public struct UPCalendarStripMonthChange: Equatable, Sendable {
    public let month: Date
    public let scene: String

    public init(month: Date, scene: String) {
        self.month = month
        self.scene = scene
    }
}

/// `toggleFull` 的事件负载，对应上游 `{ show, source }`。
/// `source` 沿用上游字面量：`button` / `hint` / `pull-down` / `pull-up` / `auto`。
public struct UPCalendarStripToggle: Equatable, Sendable {
    public let show: Bool
    public let source: String

    public init(show: Bool, source: String) {
        self.show = show
        self.source = source
    }
}

/// 单行日历里的一格，对应上游 `monthDays` 的元素。
public struct UPCalendarStripDay: Equatable, Sendable {
    public let date: Date
    /// 该月中的第几天，对应上游 `item.day`。
    public let day: Int
    /// `Calendar` 语义的星期：1 是周日、7 是周六。
    public let weekday: Int
    public let disabled: Bool
    public let selected: Bool
    public let today: Bool

    public init(date: Date, day: Int, weekday: Int, disabled: Bool, selected: Bool, today: Bool) {
        self.date = date
        self.day = day
        self.weekday = weekday
        self.disabled = disabled
        self.selected = selected
        self.today = today
    }
}
