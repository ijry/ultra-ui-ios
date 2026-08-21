import SwiftUI

@MainActor
public final class UPCalendar: View {
    public var selectedDate: Binding<Date?>?
    public let minDate: Date?
    public let maxDate: Date?
    public let multiple: Bool
    public private(set) var selectedDates: [Date]
    private var onChangeHandler: ((Date) -> Void)?

    public init(selectedDate: Binding<Date?>? = nil, minDate: Date? = nil, maxDate: Date? = nil,
                multiple: Bool = false, selectedDates: [Date] = [], onChange: ((Date) -> Void)? = nil) {
        self.selectedDate = selectedDate; self.minDate = minDate; self.maxDate = maxDate
        self.multiple = multiple; self.selectedDates = selectedDates; self.onChangeHandler = onChange
    }
    public func onChange(_ action: @escaping (Date) -> Void) -> UPCalendar { onChangeHandler = action; return self }
    public func select(_ date: Date) {
        if let minDate, date < minDate { return }; if let maxDate, date > maxDate { return }
        if multiple { if selectedDates.contains(date) { selectedDates.removeAll { $0 == date } } else { selectedDates.append(date) } }
        else { selectedDates = [date]; selectedDate?.wrappedValue = date }
        onChangeHandler?(date)
    }
    public var body: some View { DatePicker("", selection: Binding(get: { self.selectedDate?.wrappedValue ?? Date() }, set: { self.select($0) }), displayedComponents: .date).labelsHidden() }
}
