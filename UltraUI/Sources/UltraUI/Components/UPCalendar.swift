import SwiftUI

public enum UPCalendarMode: String, Sendable {
    case single
    case multiple
    case range
}

public struct UPCalendarSelection: Sendable {
    public let mode: UPCalendarMode
    public let dates: [Date]

    public init(mode: UPCalendarMode, dates: [Date]) {
        self.mode = mode
        self.dates = dates
    }

    public var date: Date? { dates.first }
    public var range: ClosedRange<Date>? {
        guard dates.count == 2 else { return nil }
        return dates[0] <= dates[1] ? dates[0]...dates[1] : dates[1]...dates[0]
    }
}

@MainActor
public final class UPCalendar: View {
    public var selectedDate: Binding<Date?>?
    public let minDate: Date?
    public let maxDate: Date?
    public let mode: UPCalendarMode
    public let maxCount: Int
    public let readonly: Bool
    public private(set) var selectedDates: [Date]
    public var multiple: Bool { mode == .multiple }

    private var selectedDatesBinding: Binding<[Date]>?
    private var onChangeHandler: ((Date) -> Void)?
    private var onSelectHandler: ((UPCalendarSelection) -> Void)?
    private var onConfirmHandler: ((UPCalendarSelection) -> Void)?
    private var onCloseHandler: (() -> Void)?

    public init(selectedDate: Binding<Date?>? = nil, minDate: Date? = nil, maxDate: Date? = nil,
                multiple: Bool = false, selectedDates: [Date] = [], onChange: ((Date) -> Void)? = nil) {
        self.selectedDate = selectedDate
        self.minDate = minDate
        self.maxDate = maxDate
        self.mode = multiple ? .multiple : .single
        self.maxCount = Int.max
        self.readonly = false
        self.selectedDates = selectedDates
        self.selectedDatesBinding = nil
        self.onChangeHandler = onChange
    }

    public init(mode: UPCalendarMode = .single, selectedDates: Binding<[Date]>? = nil,
                selectedDate: Binding<Date?>? = nil, minDate: Date? = nil, maxDate: Date? = nil,
                maxCount: Int = Int.max, readonly: Bool = false,
                onChange: ((Date) -> Void)? = nil) {
        self.selectedDate = selectedDate
        self.minDate = minDate
        self.maxDate = maxDate
        self.mode = mode
        self.maxCount = max(0, maxCount)
        self.readonly = readonly
        self.selectedDatesBinding = selectedDates
        self.selectedDates = selectedDates?.wrappedValue ?? (selectedDate?.wrappedValue.map { [$0] } ?? [])
        self.onChangeHandler = onChange
    }

    public func onChange(_ action: @escaping (Date) -> Void) -> UPCalendar { onChangeHandler = action; return self }
    public func onSelect(_ action: @escaping (UPCalendarSelection) -> Void) -> UPCalendar { onSelectHandler = action; return self }
    public func onConfirm(_ action: @escaping (UPCalendarSelection) -> Void) -> UPCalendar { onConfirmHandler = action; return self }
    public func onClose(_ action: @escaping () -> Void) -> UPCalendar { onCloseHandler = action; return self }

    public func select(_ date: Date) {
        guard !readonly, isSelectable(date) else { return }
        switch mode {
        case .single:
            selectedDates = [date]
        case .multiple:
            if selectedDates.contains(date) {
                selectedDates.removeAll { $0 == date }
            } else if selectedDates.count < maxCount {
                selectedDates.append(date)
            } else {
                return
            }
        case .range:
            if selectedDates.count != 1 { selectedDates = [date] }
            else if selectedDates[0] == date { selectedDates = [date] }
            else {
                let range = selectedDates[0] <= date ? [selectedDates[0], date] : [date, selectedDates[0]]
                selectedDates = range
            }
        }
        selectedDatesBinding?.wrappedValue = selectedDates
        if mode == .single { selectedDate?.wrappedValue = date }
        onChangeHandler?(date)
        onSelectHandler?(selection)
    }

    public func confirm() -> UPCalendarSelection? {
        guard !selectedDates.isEmpty, mode != .range || selectedDates.count == 2 else { return nil }
        let result = selection
        onConfirmHandler?(result)
        return result
    }

    public func close() { onCloseHandler?() }

    public var selection: UPCalendarSelection { UPCalendarSelection(mode: mode, dates: selectedDates) }

    private func isSelectable(_ date: Date) -> Bool {
        if let minDate, date < minDate { return false }
        if let maxDate, date > maxDate { return false }
        return true
    }

    public var body: some View {
        DatePicker("", selection: Binding(get: { self.selectedDate?.wrappedValue ?? self.selectedDates.first ?? Date() }, set: { self.select($0) }), displayedComponents: .date)
            .labelsHidden()
            .disabled(readonly)
    }
}
