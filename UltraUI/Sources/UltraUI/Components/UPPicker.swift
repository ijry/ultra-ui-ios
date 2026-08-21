import SwiftUI

public struct UPPickerData: Identifiable, Equatable, Sendable {
    public let id: String
    public var text: String
    public var value: String
    public init(id: String? = nil, text: String, value: String? = nil) { self.id = id ?? value ?? text; self.text = text; self.value = value ?? text }
}

public struct UPPickerChange: Equatable, Sendable {
    public var values: [UPPickerData]
    public var indices: [Int]
    public var columnIndex: Int
    public var index: Int
    public init(values: [UPPickerData], indices: [Int], columnIndex: Int, index: Int) { self.values = values; self.indices = indices; self.columnIndex = columnIndex; self.index = index }
}

@MainActor private final class UPPickerSelection { var indices: [Int]; init(_ indices: [Int]) { self.indices = indices } }

@MainActor
public struct UPPickerColumn: View {
    public var options: [UPPickerData]
    public var selectedIndex: Int
    public var itemHeight: CGFloat
    public init(options: [UPPickerData] = [], selectedIndex: Int = 0, itemHeight: some UPImageUnitValue = 44) { self.options = options; self.selectedIndex = selectedIndex; self.itemHeight = UPUnit.parse(itemHeight.upImageUnitValue) }
    public var body: some View {
        let picker = Picker("", selection: .constant(selectedIndex)) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                Text(option.text).tag(index)
            }
        }
#if os(iOS) || os(tvOS) || os(watchOS)
        picker.pickerStyle(.wheel).frame(height: itemHeight * 5)
#else
        picker.frame(height: itemHeight * 5)
#endif
    }
}

@MainActor
public struct UPPicker: View {
    public var columns: [[UPPickerData]]; public var show: Bool; public var popupMode: String; public var showToolbar: Bool
    public var title: String; public var loading: Bool; public var itemHeight: CGFloat; public var cancelText: String; public var confirmText: String
    public var cancelColor: String; public var confirmColor: String; public var visibleItemCount: Int; public var keyName: String; public var valueName: String
    public var closeOnClickOverlay: Bool; public var defaultIndex: [Int]; public var immediateChange: Bool; public var disabled: Bool
    public var placeholder: String; public var zIndex: CGFloat; public var bgColor: String; public var round: CGFloat; public var duration: Int
    private var modelValue: Binding<[String]>?; private let selection: UPPickerSelection
    private var onChangeHandler: ((UPPickerChange) -> Void)?; private var onConfirmHandler: ((UPPickerChange) -> Void)?; private var onCancelHandler: (() -> Void)?

    public init(columns: [[String]] = [], modelValue: Binding<[String]>? = nil, show: Bool = false, popupMode: String = "bottom",
                showToolbar: Bool = true, title: String = "", loading: Bool = false, itemHeight: some UPImageUnitValue = 44,
                cancelText: String = "取消", confirmText: String = "确认", cancelColor: String = "#909193", confirmColor: String = "",
                visibleItemCount: Int = 5, keyName: String = "text", valueName: String = "value", closeOnClickOverlay: Bool = false,
                defaultIndex: [Int] = [], immediateChange: Bool = true, disabled: Bool = false, placeholder: String = "请选择",
                zIndex: some UPImageUnitValue = 10076, bgColor: String = "", round: some UPImageUnitValue = 0, duration: Int = 300) {
        self.init(dataColumns: columns.map { $0.map { UPPickerData(text: $0) } }, modelValue: modelValue, show: show, popupMode: popupMode,
                  showToolbar: showToolbar, title: title, loading: loading, itemHeight: itemHeight, cancelText: cancelText, confirmText: confirmText,
                  cancelColor: cancelColor, confirmColor: confirmColor, visibleItemCount: visibleItemCount, keyName: keyName, valueName: valueName,
                  closeOnClickOverlay: closeOnClickOverlay, defaultIndex: defaultIndex, immediateChange: immediateChange, disabled: disabled,
                  placeholder: placeholder, zIndex: zIndex, bgColor: bgColor, round: round, duration: duration)
    }
    public init(dataColumns: [[UPPickerData]], modelValue: Binding<[String]>? = nil, show: Bool = false, popupMode: String = "bottom",
                showToolbar: Bool = true, title: String = "", loading: Bool = false, itemHeight: some UPImageUnitValue = 44,
                cancelText: String = "取消", confirmText: String = "确认", cancelColor: String = "#909193", confirmColor: String = "",
                visibleItemCount: Int = 5, keyName: String = "text", valueName: String = "value", closeOnClickOverlay: Bool = false,
                defaultIndex: [Int] = [], immediateChange: Bool = true, disabled: Bool = false, placeholder: String = "请选择",
                zIndex: some UPImageUnitValue = 10076, bgColor: String = "", round: some UPImageUnitValue = 0, duration: Int = 300) {
        self.columns = dataColumns; self.modelValue = modelValue; self.show = show; self.popupMode = popupMode; self.showToolbar = showToolbar
        self.title = title; self.loading = loading; self.itemHeight = UPUnit.parse(itemHeight.upImageUnitValue); self.cancelText = cancelText; self.confirmText = confirmText
        self.cancelColor = cancelColor; self.confirmColor = confirmColor; self.visibleItemCount = visibleItemCount; self.keyName = keyName; self.valueName = valueName
        self.closeOnClickOverlay = closeOnClickOverlay; self.defaultIndex = defaultIndex; self.immediateChange = immediateChange; self.disabled = disabled
        self.placeholder = placeholder; self.zIndex = UPUnit.parse(zIndex.upImageUnitValue); self.bgColor = bgColor; self.round = UPUnit.parse(round.upImageUnitValue); self.duration = duration
        self.selection = UPPickerSelection(Self.normalized(defaultIndex, columns: dataColumns))
    }
    public var body: some View { HStack { ForEach(columns.indices, id: \.self) { i in UPPickerColumn(options: columns[i], selectedIndex: selection.indices[i], itemHeight: itemHeight) } } }
    public func select(column: Int, index: Int) { guard !disabled, columns.indices.contains(column), columns[column].indices.contains(index) else { return }; selection.indices[column] = index; onChangeHandler?(payload(column: column, index: index)) }
    public func confirm() { let event = payload(column: max(selection.indices.count - 1, 0), index: selection.indices.last ?? 0); modelValue?.wrappedValue = event.values.map(\.value); onConfirmHandler?(event) }
    public func cancel() { onCancelHandler?() }
    public func onChange(_ action: @escaping (UPPickerChange) -> Void) -> Self { var c = self; c.onChangeHandler = action; return c }
    public func onConfirm(_ action: @escaping (UPPickerChange) -> Void) -> Self { var c = self; c.onConfirmHandler = action; return c }
    public func onCancel(_ action: @escaping () -> Void) -> Self { var c = self; c.onCancelHandler = action; return c }
    private func payload(column: Int, index: Int) -> UPPickerChange { UPPickerChange(values: columns.enumerated().compactMap { i, values in values.indices.contains(selection.indices[i]) ? values[selection.indices[i]] : nil }, indices: selection.indices, columnIndex: column, index: index) }
    private static func normalized(_ indices: [Int], columns: [[UPPickerData]]) -> [Int] { columns.enumerated().map { i, values in values.isEmpty ? 0 : min(max(indices.indices.contains(i) ? indices[i] : 0, 0), values.count - 1) } }
}
