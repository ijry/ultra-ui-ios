import SwiftUI

public struct UPCalendarStripChange: Sendable {
    public let date: Date
    public let month: Date
    public let scene: String

    public init(date: Date, scene: String = "select", calendar: Calendar = .current) {
        self.date = date
        self.month = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        self.scene = scene
    }
}

@MainActor
public final class UPCalendarStrip: View {
    public var dates: [Date]
    public var current: Binding<Int>?
    public var modelValue: Binding<Date?>?
    public let minDate: Date?
    public let maxDate: Date?
    public let disabledDates: Set<Date>
    public let readonly: Bool
    private var onChangeHandler: ((Int, Date) -> Void)?
    private var onChangePayloadHandler: ((UPCalendarStripChange) -> Void)?

    public init(dates: [Date] = [], current: Binding<Int>? = nil, onChange: ((Int, Date) -> Void)? = nil) {
        self.dates = dates; self.current = current; self.modelValue = nil
        self.minDate = nil; self.maxDate = nil; self.disabledDates = []; self.readonly = false; self.onChangeHandler = onChange
    }

    public init(dates: [Date] = [], modelValue: Binding<Date?>? = nil, minDate: Date? = nil,
                maxDate: Date? = nil, disabledDates: [Date] = [], readonly: Bool = false,
                onChange: ((UPCalendarStripChange) -> Void)? = nil) {
        self.dates = dates
        self.current = nil
        self.modelValue = modelValue
        self.minDate = minDate
        self.maxDate = maxDate
        self.disabledDates = Set(disabledDates)
        self.readonly = readonly
        self.onChangePayloadHandler = onChange
    }

    public var selectedIndex: Int {
        if let value = modelValue?.wrappedValue, let index = dates.firstIndex(of: value) { return index }
        return min(max(current?.wrappedValue ?? 0, 0), max(dates.count - 1, 0))
    }
    public var selectedDate: Date? { dates.indices.contains(selectedIndex) ? dates[selectedIndex] : nil }
    public func select(_ index: Int) {
        guard !readonly, dates.indices.contains(index), isSelectable(dates[index]) else { return }
        let date = dates[index]
        current?.wrappedValue = index
        modelValue?.wrappedValue = date
        onChangeHandler?(index, date)
        onChangePayloadHandler?(UPCalendarStripChange(date: date))
    }
    public func onChange(_ action: @escaping (Int, Date) -> Void) -> UPCalendarStrip { onChangeHandler = action; return self }
    public func onChangePayload(_ action: @escaping (UPCalendarStripChange) -> Void) -> UPCalendarStrip { onChangePayloadHandler = action; return self }
    public func isSelectable(_ date: Date) -> Bool {
        if let minDate, date < minDate { return false }
        if let maxDate, date > maxDate { return false }
        return !disabledDates.contains(date)
    }
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(self.dates.enumerated()), id: \.offset) { index, date in
                    Button { self.select(index) } label: {
                        Text(date, format: .dateTime.month().day()).padding(8)
                            .background(index == self.selectedIndex ? Color.accentColor.opacity(0.15) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }.buttonStyle(.plain).disabled(self.readonly || !self.isSelectable(date))
                }
            }
        }
    }
}
