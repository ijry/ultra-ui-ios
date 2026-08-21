import SwiftUI

@MainActor private final class UPDateSelection { var value: Int64; init(_ value: Int64) { self.value = value } }
@MainActor
public struct UPDatetimePicker: View {
    public var show: Bool; public var popupMode: String; public var showToolbar: Bool; public var title: String; public var mode: String
    public var minDate: Int64; public var maxDate: Int64; public var minHour: Int; public var maxHour: Int; public var minMinute: Int; public var maxMinute: Int
    public var minSecond: Int; public var maxSecond: Int; public var loading: Bool; public var itemHeight: CGFloat; public var cancelText: String; public var confirmText: String
    public var closeOnClickOverlay: Bool; public var disabled: Bool
    private var modelValue: Binding<Int64>?; private let selection: UPDateSelection; private var onChangeHandler: ((Int64) -> Void)?; private var onConfirmHandler: ((Int64) -> Void)?; private var onCancelHandler: (() -> Void)?
    public init(modelValue: Binding<Int64>? = nil, show: Bool = false, popupMode: String = "bottom", showToolbar: Bool = true, title: String = "", mode: String = "datetime",
                minDate: Int64 = 0, maxDate: Int64 = Int64.max, minHour: Int = 0, maxHour: Int = 23, minMinute: Int = 0, maxMinute: Int = 59,
                minSecond: Int = 0, maxSecond: Int = 59, loading: Bool = false, itemHeight: some UPImageUnitValue = 44, cancelText: String = "取消",
                confirmText: String = "确认", closeOnClickOverlay: Bool = false, disabled: Bool = false) {
        self.modelValue = modelValue; self.show = show; self.popupMode = popupMode; self.showToolbar = showToolbar; self.title = title; self.mode = mode
        self.minDate = minDate; self.maxDate = max(maxDate, minDate); self.minHour = minHour; self.maxHour = maxHour; self.minMinute = minMinute; self.maxMinute = maxMinute
        self.minSecond = minSecond; self.maxSecond = maxSecond; self.loading = loading; self.itemHeight = UPUnit.parse(itemHeight.upImageUnitValue); self.cancelText = cancelText; self.confirmText = confirmText
        self.closeOnClickOverlay = closeOnClickOverlay; self.disabled = disabled; self.selection = UPDateSelection(min(max(modelValue?.wrappedValue ?? minDate, minDate), max(maxDate, minDate)))
    }
    public var body: some View { DatePicker(title, selection: .constant(Date(timeIntervalSince1970: Double(selection.value) / 1000))) }
    public func setValue(_ value: Int64) { guard !disabled else { return }; selection.value = min(max(value, minDate), maxDate); onChangeHandler?(selection.value) }
    public func confirm() { modelValue?.wrappedValue = selection.value; onConfirmHandler?(selection.value) }
    public func cancel() { onCancelHandler?() }
    public func onChange(_ action: @escaping (Int64) -> Void) -> Self { var c = self; c.onChangeHandler = action; return c }
    public func onConfirm(_ action: @escaping (Int64) -> Void) -> Self { var c = self; c.onConfirmHandler = action; return c }
    public func onCancel(_ action: @escaping () -> Void) -> Self { var c = self; c.onCancelHandler = action; return c }
}
