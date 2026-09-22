import Foundation

/// `customList` 的一项，对应上游按 `date` 匹配后合并进日期格子的自定义信息。
public struct UPCalendarCustomDay: Equatable, Sendable {
    public let date: Date
    /// 覆盖格子底部文案。
    public let bottomInfo: String
    /// 是否画一个小圆点。
    public let dot: Bool
    /// 覆盖禁用态。
    public let disabled: Bool?

    public init(date: Date, bottomInfo: String = "", dot: Bool = false, disabled: Bool? = nil) {
        self.date = date
        self.bottomInfo = bottomInfo
        self.dot = dot
        self.disabled = disabled
    }
}

/// 日历里的一个格子，对应上游 `setMonth()` 生成的 `config` 对象。
/// `formatter` 拿到的就是这个值，可以改 `bottomInfo` / `dot` / `disabled`。
public struct UPCalendarDay: Equatable, Sendable {
    public var date: Date
    /// 1…31。
    public var day: Int
    /// `Calendar` 语义的星期：1 是周日、7 是周六。
    public var week: Int
    public var month: Int
    public var disabled: Bool
    public var bottomInfo: String
    public var dot: Bool

    public init(date: Date,
                day: Int,
                week: Int,
                month: Int,
                disabled: Bool = false,
                bottomInfo: String = "",
                dot: Bool = false) {
        self.date = date
        self.day = day
        self.week = week
        self.month = month
        self.disabled = disabled
        self.bottomInfo = bottomInfo
        self.dot = dot
    }
}

/// 一个月的数据，对应上游 `months` 数组的元素。
public struct UPCalendarMonth: Equatable, Sendable, Identifiable {
    public let year: Int
    public let month: Int
    public let days: [UPCalendarDay]

    public var id: String { "\(year)-\(month)" }

    public init(year: Int, month: Int, days: [UPCalendarDay]) {
        self.year = year
        self.month = month
        self.days = days
    }
}

/// 上游 `formatter(config)`：允许宿主改写单个格子。
public typealias UPCalendarFormatter = @Sendable (UPCalendarDay) -> UPCalendarDay

/// 上游 `mode` 的三个取值。
public enum UPCalendarMode: String, Sendable {
    case single
    case multiple
    case range
}

/// `confirm` 的事件负载。上游抛的是 `YYYY-MM-DD` 字符串数组（`enableTime` 时是
/// `YYYY-MM-DD HH:mm`），原生同时给出 `Date` 与格式化文本。
public struct UPCalendarSelection: Sendable {
    public let mode: UPCalendarMode
    public let dates: [Date]
    /// 对应上游 `getConfirmValue()` 的返回值。
    public let texts: [String]

    public init(mode: UPCalendarMode, dates: [Date], texts: [String] = []) {
        self.mode = mode
        self.dates = dates
        self.texts = texts
    }

    public var date: Date? { dates.first }

    public var range: ClosedRange<Date>? {
        guard dates.count >= 2, let first = dates.first, let last = dates.last else { return nil }
        return first <= last ? first...last : last...first
    }
}

/// 日期与时间的格式化工具，集中放这里方便单测。
public enum UPCalendarFormat {
    /// 上游统一用 `dayjs().format('YYYY-MM-DD')` 作为日期键。
    public static func dateText(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// 上游 `monthTitle` / `subtitle`：中文环境 `YYYY年MM月`，否则 `MM/YYYY`；
    /// `monthFormat` 非空时套 dayjs 格式串（只用到年月占位符）。
    public static func monthTitle(year: Int, month: Int, format: String) -> String {
        let padded = month < 10 ? "0\(month)" : String(month)
        guard !format.isEmpty else {
            let isChinese = (Locale.current.language.languageCode?.identifier ?? "").hasPrefix("zh")
            return isChinese ? "\(year)年\(padded)月" : "\(padded)/\(year)"
        }
        return format
            .replacingOccurrences(of: "YYYY", with: String(year))
            .replacingOccurrences(of: "YY", with: String(year % 100))
            .replacingOccurrences(of: "MM", with: padded)
            .replacingOccurrences(of: "M", with: String(month))
    }

    /// 对应上游 `padTime`。
    public static func padTime(_ value: Int) -> String {
        value < 10 ? "0\(value)" : String(value)
    }

    /// 对应上游 `parseTimeValue`：按 `:` 切分并夹到合法范围，缺省补 0。
    public static func parseTime(_ value: String) -> (hour: Int, minute: Int, second: Int) {
        let parts = value.trimmingCharacters(in: .whitespaces).split(separator: ":").map(String.init)
        func number(_ index: Int, max: Int) -> Int {
            guard index < parts.count, let value = Int(parts[index]) else { return 0 }
            return min(Swift.max(value, 0), max)
        }
        return (number(0, max: 23), number(1, max: 59), number(2, max: 59))
    }

    /// 对应上游 `pickerValueToTime` / `getDefaultTimeValue`。
    public static func timeText(hour: Int, minute: Int, second: Int, precision: String) -> String {
        switch precision {
        case "hour": return padTime(hour)
        case "second": return "\(padTime(hour)):\(padTime(minute)):\(padTime(second))"
        default: return "\(padTime(hour)):\(padTime(minute))"
        }
    }

    /// 对应上游 `timeToSecond`。
    public static func seconds(of time: String) -> Int {
        let parsed = parseTime(time)
        return parsed.hour * 3_600 + parsed.minute * 60 + parsed.second
    }
}
