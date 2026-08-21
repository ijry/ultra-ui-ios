import SwiftUI

@MainActor
public final class UPCalendarStrip: View {
    public var dates: [Date]; public var current: Binding<Int>?
    private var onChangeHandler: ((Int, Date) -> Void)?
    public init(dates: [Date] = [], current: Binding<Int>? = nil, onChange: ((Int, Date) -> Void)? = nil) { self.dates = dates; self.current = current; self.onChangeHandler = onChange }
    public var selectedIndex: Int { min(max(current?.wrappedValue ?? 0, 0), max(dates.count - 1, 0)) }
    public var selectedDate: Date? { dates.indices.contains(selectedIndex) ? dates[selectedIndex] : nil }
    public func select(_ index: Int) { guard dates.indices.contains(index) else { return }; current?.wrappedValue = index; onChangeHandler?(index, dates[index]) }
    public func onChange(_ action: @escaping (Int, Date) -> Void) -> UPCalendarStrip { onChangeHandler = action; return self }
    public var body: some View { ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(Array(self.dates.enumerated()), id: \.offset) { index, date in Button { self.select(index) } label: { Text(date, format: .dateTime.month().day()).padding(8).background(index == self.selectedIndex ? Color.accentColor.opacity(0.15) : .clear).clipShape(RoundedRectangle(cornerRadius: 6)) }.buttonStyle(.plain) } } } }
}
