import SwiftUI

public typealias UPDatetimePickerUnitValue = UPCheckboxUnitValue
public typealias UPDatetimePickerFilter = (_ type: String, _ values: [String]) -> [String]
public typealias UPDatetimePickerFormatter = (_ type: String, _ value: String) -> String

public enum UPDatetimePickerValue: Equatable, Sendable {
    case timestamp(Int64)
    case time(String)

    public var timestamp: Int64? {
        guard case .timestamp(let value) = self else { return nil }
        return value
    }

    public var time: String? {
        guard case .time(let value) = self else { return nil }
        return value
    }
}

public struct UPDatetimePickerChange: Equatable, Sendable {
    public var value: UPDatetimePickerValue
    public var mode: String

    public init(value: UPDatetimePickerValue, mode: String) {
        self.value = value
        self.mode = mode
    }
}

@MainActor
private final class UPDatetimePickerSelection: ObservableObject {
    @Published var value: UPDatetimePickerValue

    init(_ value: UPDatetimePickerValue) {
        self.value = value
    }
}

@MainActor
public struct UPDatetimePicker: View {
    public var show: Bool
    public var popupMode: String
    public var showToolbar: Bool
    public var toolbarRightSlot: Bool
    public var title: String
    public var mode: String
    public var minDate: Int64
    public var maxDate: Int64
    public var minHour: Int
    public var maxHour: Int
    public var minMinute: Int
    public var maxMinute: Int
    public var minSecond: Int
    public var maxSecond: Int
    public var loading: Bool
    public var itemHeight: CGFloat
    public var cancelText: String
    public var confirmText: String
    public var cancelColor: String
    public var confirmColor: String
    public var visibleItemCount: Int
    public var closeOnClickOverlay: Bool
    public var defaultIndex: [Int]
    public var disabled: Bool
    public var disabledColor: String
    public var hasInput: Bool
    public var inputProps: [String: String]
    public var inputBorder: String
    public var placeholder: String
    public var format: String
    public var pageInline: Bool
    public var maskClass: String
    public var maskStyle: String
    public var filter: UPDatetimePickerFilter?
    public var formatter: UPDatetimePickerFormatter?

    private var timestampModelValue: Binding<Int64>?
    private var timeModelValue: Binding<String>?
    private var showBinding: Binding<Bool>?

    /// 与 picker 一致：带输入框触发器时点击输入框展开。
    @State private var showByClickInput = false
    @ObservedObject private var selection: UPDatetimePickerSelection
    private var onChangeHandler: ((Int64) -> Void)?
    private var onChangeStringHandler: ((String) -> Void)?
    private var onChangePayloadHandler: ((UPDatetimePickerChange) -> Void)?
    private var onConfirmHandler: ((Int64) -> Void)?
    private var onConfirmStringHandler: ((String) -> Void)?
    private var onConfirmPayloadHandler: ((UPDatetimePickerChange) -> Void)?
    private var onCancelHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?
    private var onClosedHandler: (() -> Void)?
    private var triggerContent: AnyView?
    private var toolbarRightContent: AnyView?
    private var toolbarBottomContent: AnyView?

    public var selectedValue: UPDatetimePickerValue { selection.value }
    public var hasTriggerSlot: Bool { triggerContent != nil }
    public var hasToolbarRightSlot: Bool { toolbarRightContent != nil }
    public var hasToolbarBottomSlot: Bool { toolbarBottomContent != nil }

    public init(
        modelValue: Binding<Int64>? = nil,
        show: some UPPickerVisibilityValue = false,
        popupMode: String = "bottom",
        showToolbar: Bool = true,
        toolbarRightSlot: Bool = false,
        title: String = "",
        mode: String = "datetime",
        minDate: Int64 = 0,
        maxDate: Int64 = Int64.max,
        minHour: Int = 0,
        maxHour: Int = 23,
        minMinute: Int = 0,
        maxMinute: Int = 59,
        minSecond: Int = 0,
        maxSecond: Int = 59,
        filter: UPDatetimePickerFilter? = nil,
        formatter: UPDatetimePickerFormatter? = nil,
        loading: Bool = false,
        itemHeight: some UPDatetimePickerUnitValue = 44,
        cancelText: String = "取消",
        confirmText: String = "确定",
        cancelColor: String = "#909193",
        confirmColor: String = "#3c9cff",
        visibleItemCount: some UPDatetimePickerUnitValue = 5,
        closeOnClickOverlay: Bool = false,
        defaultIndex: [Int] = [],
        disabled: Bool = false,
        disabledColor: String = "",
        hasInput: Bool = false,
        inputProps: [String: String] = [:],
        inputBorder: String = "surround",
        placeholder: String = "请选择",
        format: String = "",
        pageInline: Bool = false,
        maskClass: String = "",
        maskStyle: String = ""
    ) {
        let resolvedMode = Self.normalizedMode(mode)
        let lowerDate = minDate
        let upperDate = max(maxDate, lowerDate)
        let hourBounds = Self.normalizedBounds(min: minHour, max: maxHour, allowed: 0...23)
        let minuteBounds = Self.normalizedBounds(min: minMinute, max: maxMinute, allowed: 0...59)
        let secondBounds = Self.normalizedBounds(min: minSecond, max: maxSecond, allowed: 0...59)
        let initial = Self.correctedTimestamp(
            modelValue?.wrappedValue ?? lowerDate,
            minDate: lowerDate,
            maxDate: upperDate
        )
        self.init(
            timestampModelValue: modelValue,
            timeModelValue: nil,
            show: show,
            popupMode: popupMode,
            showToolbar: showToolbar,
            toolbarRightSlot: toolbarRightSlot,
            title: title,
            mode: resolvedMode,
            minDate: lowerDate,
            maxDate: upperDate,
            hourBounds: hourBounds,
            minuteBounds: minuteBounds,
            secondBounds: secondBounds,
            filter: filter,
            formatter: formatter,
            loading: loading,
            itemHeight: itemHeight.upCheckboxUnitValue,
            cancelText: cancelText,
            confirmText: confirmText,
            cancelColor: cancelColor,
            confirmColor: confirmColor,
            visibleItemCount: visibleItemCount.upCheckboxUnitValue,
            closeOnClickOverlay: closeOnClickOverlay,
            defaultIndex: defaultIndex,
            disabled: disabled,
            disabledColor: disabledColor,
            hasInput: hasInput,
            inputProps: inputProps,
            inputBorder: inputBorder,
            placeholder: placeholder,
            format: format,
            pageInline: pageInline,
            maskClass: maskClass,
            maskStyle: maskStyle,
            initialValue: .timestamp(initial)
        )
    }

    public init(
        modelValue: Binding<String>,
        show: some UPPickerVisibilityValue = false,
        popupMode: String = "bottom",
        showToolbar: Bool = true,
        toolbarRightSlot: Bool = false,
        title: String = "",
        mode: String = "time",
        minDate: Int64 = 0,
        maxDate: Int64 = Int64.max,
        minHour: Int = 0,
        maxHour: Int = 23,
        minMinute: Int = 0,
        maxMinute: Int = 59,
        minSecond: Int = 0,
        maxSecond: Int = 59,
        filter: UPDatetimePickerFilter? = nil,
        formatter: UPDatetimePickerFormatter? = nil,
        loading: Bool = false,
        itemHeight: some UPDatetimePickerUnitValue = 44,
        cancelText: String = "取消",
        confirmText: String = "确定",
        cancelColor: String = "#909193",
        confirmColor: String = "#3c9cff",
        visibleItemCount: some UPDatetimePickerUnitValue = 5,
        closeOnClickOverlay: Bool = false,
        defaultIndex: [Int] = [],
        disabled: Bool = false,
        disabledColor: String = "",
        hasInput: Bool = false,
        inputProps: [String: String] = [:],
        inputBorder: String = "surround",
        placeholder: String = "请选择",
        format: String = "",
        pageInline: Bool = false,
        maskClass: String = "",
        maskStyle: String = ""
    ) {
        let requestedMode = Self.normalizedMode(mode)
        let resolvedMode = requestedMode == "timesecond" ? "timesecond" : "time"
        let lowerDate = minDate
        let upperDate = max(maxDate, lowerDate)
        let hourBounds = Self.normalizedBounds(min: minHour, max: maxHour, allowed: 0...23)
        let minuteBounds = Self.normalizedBounds(min: minMinute, max: maxMinute, allowed: 0...59)
        let secondBounds = Self.normalizedBounds(min: minSecond, max: maxSecond, allowed: 0...59)
        let initial = Self.correctedTime(
            modelValue.wrappedValue,
            mode: resolvedMode,
            hourBounds: hourBounds,
            minuteBounds: minuteBounds,
            secondBounds: secondBounds
        )
        self.init(
            timestampModelValue: nil,
            timeModelValue: modelValue,
            show: show,
            popupMode: popupMode,
            showToolbar: showToolbar,
            toolbarRightSlot: toolbarRightSlot,
            title: title,
            mode: resolvedMode,
            minDate: lowerDate,
            maxDate: upperDate,
            hourBounds: hourBounds,
            minuteBounds: minuteBounds,
            secondBounds: secondBounds,
            filter: filter,
            formatter: formatter,
            loading: loading,
            itemHeight: itemHeight.upCheckboxUnitValue,
            cancelText: cancelText,
            confirmText: confirmText,
            cancelColor: cancelColor,
            confirmColor: confirmColor,
            visibleItemCount: visibleItemCount.upCheckboxUnitValue,
            closeOnClickOverlay: closeOnClickOverlay,
            defaultIndex: defaultIndex,
            disabled: disabled,
            disabledColor: disabledColor,
            hasInput: hasInput,
            inputProps: inputProps,
            inputBorder: inputBorder,
            placeholder: placeholder,
            format: format,
            pageInline: pageInline,
            maskClass: maskClass,
            maskStyle: maskStyle,
            initialValue: .time(initial)
        )
    }

    private init(
        timestampModelValue: Binding<Int64>?,
        timeModelValue: Binding<String>?,
        show: some UPPickerVisibilityValue,
        popupMode: String,
        showToolbar: Bool,
        toolbarRightSlot: Bool,
        title: String,
        mode: String,
        minDate: Int64,
        maxDate: Int64,
        hourBounds: ClosedRange<Int>,
        minuteBounds: ClosedRange<Int>,
        secondBounds: ClosedRange<Int>,
        filter: UPDatetimePickerFilter?,
        formatter: UPDatetimePickerFormatter?,
        loading: Bool,
        itemHeight: String,
        cancelText: String,
        confirmText: String,
        cancelColor: String,
        confirmColor: String,
        visibleItemCount: String,
        closeOnClickOverlay: Bool,
        defaultIndex: [Int],
        disabled: Bool,
        disabledColor: String,
        hasInput: Bool,
        inputProps: [String: String],
        inputBorder: String,
        placeholder: String,
        format: String,
        pageInline: Bool,
        maskClass: String,
        maskStyle: String,
        initialValue: UPDatetimePickerValue
    ) {
        self.timestampModelValue = timestampModelValue
        self.timeModelValue = timeModelValue
        self.show = show.upPickerInitialVisibility
        self.showBinding = show.upPickerVisibilityBinding
        self.popupMode = popupMode
        self.showToolbar = showToolbar
        self.toolbarRightSlot = toolbarRightSlot
        self.title = title
        self.mode = mode
        self.minDate = minDate
        self.maxDate = maxDate
        self.minHour = hourBounds.lowerBound
        self.maxHour = hourBounds.upperBound
        self.minMinute = minuteBounds.lowerBound
        self.maxMinute = minuteBounds.upperBound
        self.minSecond = secondBounds.lowerBound
        self.maxSecond = secondBounds.upperBound
        self.filter = filter
        self.formatter = formatter
        self.loading = loading
        self.itemHeight = max(0, UPUnit.parse(itemHeight))
        self.cancelText = cancelText
        self.confirmText = confirmText
        self.cancelColor = cancelColor
        self.confirmColor = confirmColor
        self.visibleItemCount = max(0, Int(Double(visibleItemCount) ?? 0))
        self.closeOnClickOverlay = closeOnClickOverlay
        self.defaultIndex = defaultIndex
        self.disabled = disabled
        self.disabledColor = disabledColor
        self.hasInput = hasInput
        self.inputProps = inputProps
        self.inputBorder = inputBorder
        self.placeholder = placeholder
        self.format = format
        self.pageInline = pageInline
        self.maskClass = maskClass
        self.maskStyle = maskStyle
        self._selection = ObservedObject(wrappedValue: UPDatetimePickerSelection(initialValue))
    }

    public var body: some View {
        // 与 u-picker 一致：整个组件由 u-popup 承载，可见性同一套规则。
        if Self.isContentVisible(
            show: showBinding?.wrappedValue ?? show,
            hasInput: hasInput,
            showByClickInput: showByClickInput,
            pageInline: pageInline
        ) {
            content
        }
    }

    /// 复用 picker 的可见性规则，保持两个组件行为一致。
    public static func isContentVisible(show: Bool,
                                       hasInput: Bool,
                                       showByClickInput: Bool,
                                       pageInline: Bool = false) -> Bool {
        UPPicker.isContentVisible(
            show: show,
            hasInput: hasInput,
            showByClickInput: showByClickInput,
            pageInline: pageInline
        )
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            if hasInput, let triggerContent {
                triggerContent
            }
            if showToolbar {
                UPToolbar(
                    cancelText: cancelText,
                    confirmText: confirmText,
                    cancelColor: cancelColor,
                    confirmColor: confirmColor,
                    title: title,
                    rightSlot: toolbarRightSlot || toolbarRightContent != nil
                ) {
                    toolbarRightContent
                }
                .onCancel(cancel)
                .onConfirm(confirm)
            }
            toolbarBottomContent
            DatePicker(
                title,
                selection: nativeDateBinding,
                displayedComponents: displayedComponents
            )
        }
        .disabled(disabled || loading)
    }

    public func setValue(_ value: Int64) {
        guard !disabled else { return }
        let corrected = Self.correctedTimestamp(value, minDate: minDate, maxDate: maxDate)
        selection.value = .timestamp(corrected)
        onChangeHandler?(corrected)
        onChangePayloadHandler?(eventPayload)
    }

    public func setValue(_ value: String) {
        guard !disabled else { return }
        let corrected = Self.correctedTime(
            value,
            mode: mode,
            hourBounds: minHour...maxHour,
            minuteBounds: minMinute...maxMinute,
            secondBounds: minSecond...maxSecond
        )
        selection.value = .time(corrected)
        onChangeStringHandler?(corrected)
        onChangePayloadHandler?(eventPayload)
    }

    public func confirm() {
        guard !disabled else { return }
        switch selection.value {
        case .timestamp(let value):
            timestampModelValue?.wrappedValue = value
            closeVisibility()
            onConfirmHandler?(value)
        case .time(let value):
            timeModelValue?.wrappedValue = value
            closeVisibility()
            onConfirmStringHandler?(value)
        }
        onConfirmPayloadHandler?(eventPayload)
        emitClosed()
    }

    public func cancel() {
        guard !disabled else { return }
        closeVisibility()
        onCancelHandler?()
        emitClosed()
    }

    public func overlayClick() {
        guard closeOnClickOverlay else { return }
        closeVisibility()
        onCloseHandler?()
        emitClosed()
    }

    public func onChange(_ action: @escaping (Int64) -> Void) -> Self {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    public func onChangeString(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onChangeStringHandler = action
        return copy
    }

    public func onChangePayload(_ action: @escaping (UPDatetimePickerChange) -> Void) -> Self {
        var copy = self
        copy.onChangePayloadHandler = action
        return copy
    }

    public func onConfirm(_ action: @escaping (Int64) -> Void) -> Self {
        var copy = self
        copy.onConfirmHandler = action
        return copy
    }

    public func onConfirmString(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onConfirmStringHandler = action
        return copy
    }

    public func onConfirmPayload(_ action: @escaping (UPDatetimePickerChange) -> Void) -> Self {
        var copy = self
        copy.onConfirmPayloadHandler = action
        return copy
    }

    public func onCancel(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onCancelHandler = action
        return copy
    }

    public func onClose(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onCloseHandler = action
        return copy
    }

    public func onClosed(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onClosedHandler = action
        return copy
    }

    public func trigger<Slot: View>(@ViewBuilder _ content: () -> Slot) -> Self {
        var copy = self
        copy.triggerContent = AnyView(content())
        return copy
    }

    public func toolbarRight<Slot: View>(@ViewBuilder _ content: () -> Slot) -> Self {
        var copy = self
        copy.toolbarRightContent = AnyView(content())
        copy.toolbarRightSlot = true
        return copy
    }

    public func toolbarBottom<Slot: View>(@ViewBuilder _ content: () -> Slot) -> Self {
        var copy = self
        copy.toolbarBottomContent = AnyView(content())
        return copy
    }

    private var eventPayload: UPDatetimePickerChange {
        UPDatetimePickerChange(value: selection.value, mode: mode)
    }

    private var nativeDateBinding: Binding<Date> {
        Binding(
            get: {
                switch selection.value {
                case .timestamp(let value):
                    return Date(timeIntervalSince1970: Double(value) / 1_000)
                case .time(let value):
                    let parts = Self.timeParts(value)
                    return Calendar.current.date(
                        bySettingHour: parts.hour,
                        minute: parts.minute,
                        second: parts.second,
                        of: Date()
                    ) ?? Date()
                }
            },
            set: { date in
                if mode == "time" || mode == "timesecond" {
                    let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
                    let raw = mode == "timesecond"
                        ? String(format: "%02d:%02d:%02d", parts.hour ?? 0, parts.minute ?? 0, parts.second ?? 0)
                        : String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
                    setValue(raw)
                } else {
                    setValue(Int64((date.timeIntervalSince1970 * 1_000).rounded()))
                }
            }
        )
    }

    private var displayedComponents: DatePicker.Components {
        switch mode {
        case "time", "timesecond": return [.hourAndMinute]
        case "date", "year-month": return [.date]
        default: return [.date, .hourAndMinute]
        }
    }

    private func closeVisibility() {
        showBinding?.wrappedValue = false
    }

    private func emitClosed() {
        guard let onClosedHandler else { return }
        if pageInline {
            onClosedHandler()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onClosedHandler()
            }
        }
    }

    private static func normalizedMode(_ mode: String) -> String {
        let supported = [
            "date", "time", "year-month", "datetime", "datehour",
            "timesecond", "datetimesecond"
        ]
        return supported.contains(mode) ? mode : "datetime"
    }

    private static func normalizedBounds(
        min lower: Int,
        max upper: Int,
        allowed: ClosedRange<Int>
    ) -> ClosedRange<Int> {
        let normalizedLower = Swift.min(Swift.max(lower, allowed.lowerBound), allowed.upperBound)
        let normalizedUpper = Swift.min(Swift.max(upper, allowed.lowerBound), allowed.upperBound)
        return normalizedLower...Swift.max(normalizedLower, normalizedUpper)
    }

    private static func correctedTimestamp(_ value: Int64, minDate: Int64, maxDate: Int64) -> Int64 {
        Swift.min(Swift.max(value, minDate), maxDate)
    }

    private static func correctedTime(
        _ value: String,
        mode: String,
        hourBounds: ClosedRange<Int>,
        minuteBounds: ClosedRange<Int>,
        secondBounds: ClosedRange<Int>
    ) -> String {
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        let hour = clamp(Int(parts.first ?? "") ?? hourBounds.lowerBound, to: hourBounds)
        let minute = clamp(
            parts.indices.contains(1) ? Int(parts[1]) ?? minuteBounds.lowerBound : minuteBounds.lowerBound,
            to: minuteBounds
        )
        if mode == "timesecond" {
            let second = clamp(
                parts.indices.contains(2) ? Int(parts[2]) ?? secondBounds.lowerBound : secondBounds.lowerBound,
                to: secondBounds
            )
            return String(format: "%02d:%02d:%02d", hour, minute, second)
        }
        return String(format: "%02d:%02d", hour, minute)
    }

    private static func clamp(_ value: Int, to bounds: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(value, bounds.lowerBound), bounds.upperBound)
    }

    private static func timeParts(_ value: String) -> (hour: Int, minute: Int, second: Int) {
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        return (
            Int(parts.first ?? "") ?? 0,
            parts.indices.contains(1) ? Int(parts[1]) ?? 0 : 0,
            parts.indices.contains(2) ? Int(parts[2]) ?? 0 : 0
        )
    }
}
