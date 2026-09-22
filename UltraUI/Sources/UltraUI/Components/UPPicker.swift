import SwiftUI

public typealias UPPickerUnitValue = UPCheckboxUnitValue

/// Accepts the upstream `Boolean | String | Number` value used by `round`.
public protocol UPPickerRoundValue {
    var upPickerRoundValue: String { get }
}

extension Bool: UPPickerRoundValue {
    public var upPickerRoundValue: String { description }
}

extension String: UPPickerRoundValue { public var upPickerRoundValue: String { self } }
extension Int: UPPickerRoundValue { public var upPickerRoundValue: String { String(self) } }
extension Int8: UPPickerRoundValue { public var upPickerRoundValue: String { String(self) } }
extension Int16: UPPickerRoundValue { public var upPickerRoundValue: String { String(self) } }
extension Int32: UPPickerRoundValue { public var upPickerRoundValue: String { String(self) } }
extension Int64: UPPickerRoundValue { public var upPickerRoundValue: String { String(self) } }
extension UInt: UPPickerRoundValue { public var upPickerRoundValue: String { String(self) } }
extension UInt8: UPPickerRoundValue { public var upPickerRoundValue: String { String(self) } }
extension UInt16: UPPickerRoundValue { public var upPickerRoundValue: String { String(self) } }
extension UInt32: UPPickerRoundValue { public var upPickerRoundValue: String { String(self) } }
extension UInt64: UPPickerRoundValue { public var upPickerRoundValue: String { String(self) } }
extension Double: UPPickerRoundValue { public var upPickerRoundValue: String { upCheckboxTextValue } }
extension Float: UPPickerRoundValue { public var upPickerRoundValue: String { upCheckboxTextValue } }
extension CGFloat: UPPickerRoundValue { public var upPickerRoundValue: String { upCheckboxTextValue } }

/// Lets the Swift API preserve the upstream Boolean `show` prop while also
/// accepting a Binding for Vue-style `update:show` behavior.
public protocol UPPickerVisibilityValue {
    var upPickerInitialVisibility: Bool { get }
    var upPickerVisibilityBinding: Binding<Bool>? { get }
}

extension Bool: UPPickerVisibilityValue {
    public var upPickerInitialVisibility: Bool { self }
    public var upPickerVisibilityBinding: Binding<Bool>? { nil }
}

extension Binding: UPPickerVisibilityValue where Value == Bool {
    public var upPickerInitialVisibility: Bool { wrappedValue }
    public var upPickerVisibilityBinding: Binding<Bool>? { self }
}

public struct UPPickerData: Identifiable, Equatable, Sendable {
    public let id: String
    public var text: String
    public var value: String

    public init(id: String? = nil, text: String, value: String? = nil) {
        self.id = id ?? value ?? text
        self.text = text
        self.value = value ?? text
    }
}

public extension UPPickerData {
    /// 上游 `u-picker-data` 的 `valueKey` 默认值。
    static let defaultValueKey = "id"
    /// 上游 `u-picker-data` 的 `labelKey` 默认值。
    static let defaultLabelKey = "name"

    /// 对应上游 `options` 里的一个对象元素：`ele[valueKey]` 当值、`ele[labelKey]` 当显示文本。
    init?(object: [String: String],
          valueKey: String = UPPickerData.defaultValueKey,
          labelKey: String = UPPickerData.defaultLabelKey) {
        let value = object[valueKey]
        let label = object[labelKey]
        // 上游按 `ele[valueKey] == modelValue` 匹配、取 `ele[labelKey]` 显示，
        // 两个键都取不到就没法参与选择。
        guard value != nil || label != nil else { return nil }
        self.init(id: value, text: label ?? value ?? "", value: value)
    }

    /// 把上游 `options`（对象数组）整列转成 `UPPickerData`。
    static func options(_ objects: [[String: String]],
                        valueKey: String = UPPickerData.defaultValueKey,
                        labelKey: String = UPPickerData.defaultLabelKey) -> [UPPickerData] {
        objects.compactMap { UPPickerData(object: $0, valueKey: valueKey, labelKey: labelKey) }
    }

    /// 对应上游 `created` / `watch.modelValue` 里按 `modelValue` 找默认下标的逻辑。
    static func defaultIndex(for modelValue: String, in options: [UPPickerData]) -> [Int] {
        guard !modelValue.isEmpty, let index = options.firstIndex(where: { $0.value == modelValue }) else {
            return []
        }
        return [index]
    }
}

/// Event payload shared by `change` and `confirm`.
///
/// `values` and `indices` are retained for source compatibility with the
/// initial Swift implementation. `value`, `indexs`, and `allValues` expose the
/// corresponding uview-plus names without changing those existing meanings.
public struct UPPickerChange: Equatable, Sendable {
    public var values: [UPPickerData]
    public var indices: [Int]
    public var columnIndex: Int
    public var index: Int
    public var allValues: [[UPPickerData]]

    public var value: [UPPickerData] { values }
    public var indexs: [Int] { indices }

    public init(
        values: [UPPickerData],
        indices: [Int],
        columnIndex: Int,
        index: Int,
        allValues: [[UPPickerData]] = []
    ) {
        self.values = values
        self.indices = indices
        self.columnIndex = columnIndex
        self.index = index
        self.allValues = allValues
    }
}

@MainActor
private final class UPPickerSelection: ObservableObject {
    @Published var indices: [Int]
    var confirmedIndices: [Int]

    init(_ indices: [Int]) {
        self.indices = indices
        self.confirmedIndices = indices
    }
}

@MainActor
public struct UPPickerColumn: View {
    public var options: [UPPickerData]
    public var selectedIndex: Int
    public var itemHeight: CGFloat
    private var selectedIndexBinding: Binding<Int>?

    public init(
        options: [UPPickerData] = [],
        selectedIndex: Int = 0,
        itemHeight: some UPPickerUnitValue = 44
    ) {
        self.options = options
        self.selectedIndex = Self.normalized(selectedIndex, options: options)
        self.itemHeight = max(0, UPUnit.parse(itemHeight.upCheckboxUnitValue))
        self.selectedIndexBinding = nil
    }

    init(
        options: [UPPickerData],
        selectedIndex: Binding<Int>,
        itemHeight: CGFloat
    ) {
        self.options = options
        self.selectedIndex = Self.normalized(selectedIndex.wrappedValue, options: options)
        self.itemHeight = max(0, itemHeight)
        self.selectedIndexBinding = selectedIndex
    }

    public var body: some View {
        let selection = Binding<Int>(
            get: {
                Self.normalized(selectedIndexBinding?.wrappedValue ?? selectedIndex, options: options)
            },
            set: { selectedIndexBinding?.wrappedValue = Self.normalized($0, options: options) }
        )
        let picker = Picker("", selection: selection) {
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

    private static func normalized(_ index: Int, options: [UPPickerData]) -> Int {
        guard !options.isEmpty else { return 0 }
        return min(max(index, 0), options.count - 1)
    }
}

@MainActor
public struct UPPicker: View {
    public var columns: [[UPPickerData]]
    public var show: Bool
    public var popupMode: String
    public var showToolbar: Bool
    public var title: String
    public var loading: Bool
    public var itemHeight: CGFloat
    public var cancelText: String
    public var confirmText: String
    public var cancelColor: String
    public var confirmColor: String
    public var visibleItemCount: Int
    public var keyName: String
    public var valueName: String
    public var closeOnClickOverlay: Bool
    public var defaultIndex: [Int]
    public var immediateChange: Bool
    public var disabled: Bool
    public var placeholder: String
    public var zIndex: CGFloat
    public var bgColor: String
    public var round: String
    public var duration: Double
    public var overlayOpacity: Double
    public var hasInput: Bool
    public var inputProps: [String: String]
    public var inputBorder: String
    public var disabledColor: String
    public var toolbarRightSlot: Bool
    public var pageInline: Bool
    public var maskClass: String
    public var maskStyle: String

    private var modelValue: Binding<[String]>?
    private var showBinding: Binding<Bool>?

    /// 上游 `showByClickInput`：带输入框触发器时，点击输入框展开弹层。
    @State private var showByClickInput = false
    @ObservedObject private var selection: UPPickerSelection
    private var onChangeHandler: ((UPPickerChange) -> Void)?
    private var onConfirmHandler: ((UPPickerChange) -> Void)?
    private var onCancelHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?
    private var onClosedHandler: (() -> Void)?
    private var triggerContent: AnyView?
    private var toolbarRightContent: AnyView?
    private var toolbarBottomContent: AnyView?

    public var selectedIndices: [Int] { selection.indices }
    public var hasTriggerSlot: Bool { triggerContent != nil }
    public var hasToolbarRightSlot: Bool { toolbarRightContent != nil }
    public var hasToolbarBottomSlot: Bool { toolbarBottomContent != nil }

    public init(
        columns: [[String]] = [],
        modelValue: Binding<[String]>? = nil,
        show: some UPPickerVisibilityValue = false,
        popupMode: String = "bottom",
        showToolbar: Bool = true,
        title: String = "",
        loading: Bool = false,
        itemHeight: some UPPickerUnitValue = 44,
        cancelText: String = "取消",
        confirmText: String = "确定",
        cancelColor: String = "#909193",
        confirmColor: String = "",
        visibleItemCount: some UPPickerUnitValue = 5,
        keyName: String = "text",
        valueName: String = "value",
        closeOnClickOverlay: Bool = false,
        defaultIndex: [Int] = [],
        immediateChange: Bool = true,
        disabled: Bool = false,
        placeholder: String = "请选择",
        zIndex: some UPPickerUnitValue = 10076,
        bgColor: String = "",
        round: some UPPickerRoundValue = 0,
        duration: some UPPickerUnitValue = 300,
        overlayOpacity: some UPPickerUnitValue = 0.5,
        hasInput: Bool = false,
        inputProps: [String: String] = [:],
        inputBorder: String = "surround",
        disabledColor: String = "",
        toolbarRightSlot: Bool = false,
        pageInline: Bool = false,
        maskClass: String = "",
        maskStyle: String = ""
    ) {
        self.init(
            dataColumns: columns.map { $0.map { UPPickerData(text: $0) } },
            modelValue: modelValue,
            show: show,
            popupMode: popupMode,
            showToolbar: showToolbar,
            title: title,
            loading: loading,
            itemHeight: itemHeight,
            cancelText: cancelText,
            confirmText: confirmText,
            cancelColor: cancelColor,
            confirmColor: confirmColor,
            visibleItemCount: visibleItemCount,
            keyName: keyName,
            valueName: valueName,
            closeOnClickOverlay: closeOnClickOverlay,
            defaultIndex: defaultIndex,
            immediateChange: immediateChange,
            disabled: disabled,
            placeholder: placeholder,
            zIndex: zIndex,
            bgColor: bgColor,
            round: round,
            duration: duration,
            overlayOpacity: overlayOpacity,
            hasInput: hasInput,
            inputProps: inputProps,
            inputBorder: inputBorder,
            disabledColor: disabledColor,
            toolbarRightSlot: toolbarRightSlot,
            pageInline: pageInline,
            maskClass: maskClass,
            maskStyle: maskStyle
        )
    }

    public init(
        dataColumns: [[UPPickerData]],
        modelValue: Binding<[String]>? = nil,
        show: some UPPickerVisibilityValue = false,
        popupMode: String = "bottom",
        showToolbar: Bool = true,
        title: String = "",
        loading: Bool = false,
        itemHeight: some UPPickerUnitValue = 44,
        cancelText: String = "取消",
        confirmText: String = "确定",
        cancelColor: String = "#909193",
        confirmColor: String = "",
        visibleItemCount: some UPPickerUnitValue = 5,
        keyName: String = "text",
        valueName: String = "value",
        closeOnClickOverlay: Bool = false,
        defaultIndex: [Int] = [],
        immediateChange: Bool = true,
        disabled: Bool = false,
        placeholder: String = "请选择",
        zIndex: some UPPickerUnitValue = 10076,
        bgColor: String = "",
        round: some UPPickerRoundValue = 0,
        duration: some UPPickerUnitValue = 300,
        overlayOpacity: some UPPickerUnitValue = 0.5,
        hasInput: Bool = false,
        inputProps: [String: String] = [:],
        inputBorder: String = "surround",
        disabledColor: String = "",
        toolbarRightSlot: Bool = false,
        pageInline: Bool = false,
        maskClass: String = "",
        maskStyle: String = ""
    ) {
        self.columns = dataColumns
        self.modelValue = modelValue
        self.show = show.upPickerInitialVisibility
        self.showBinding = show.upPickerVisibilityBinding
        self.popupMode = popupMode
        self.showToolbar = showToolbar
        self.title = title
        self.loading = loading
        self.itemHeight = max(0, UPUnit.parse(itemHeight.upCheckboxUnitValue))
        self.cancelText = cancelText
        self.confirmText = confirmText
        self.cancelColor = cancelColor
        self.confirmColor = confirmColor
        self.visibleItemCount = max(0, Int(Double(visibleItemCount.upCheckboxUnitValue) ?? 0))
        self.keyName = keyName
        self.valueName = valueName
        self.closeOnClickOverlay = closeOnClickOverlay
        self.defaultIndex = defaultIndex
        self.immediateChange = immediateChange
        self.disabled = disabled
        self.placeholder = placeholder
        self.zIndex = UPUnit.parse(zIndex.upCheckboxUnitValue)
        self.bgColor = bgColor
        self.round = round.upPickerRoundValue
        self.duration = max(0, Double(duration.upCheckboxUnitValue) ?? 0)
        self.overlayOpacity = min(max(Double(overlayOpacity.upCheckboxUnitValue) ?? 0.5, 0), 1)
        self.hasInput = hasInput
        self.inputProps = inputProps
        self.inputBorder = inputBorder
        self.disabledColor = disabledColor
        self.toolbarRightSlot = toolbarRightSlot
        self.pageInline = pageInline
        self.maskClass = maskClass
        self.maskStyle = maskStyle
        self._selection = ObservedObject(
            wrappedValue: UPPickerSelection(Self.normalized(defaultIndex, columns: dataColumns))
        )
    }

    public var body: some View {
        // 上游把整个 picker 包在 u-popup 内，可见性由
        // `show || (hasInput && showByClickInput)` 决定；pageInline 时不走弹层。
        if Self.isContentVisible(
            show: showBinding?.wrappedValue ?? show,
            hasInput: hasInput,
            showByClickInput: showByClickInput,
            pageInline: pageInline
        ) {
            content
        }
    }

    /// 上游 `u-popup` 的 `:show="show || (hasInput && showByClickInput)"`。
    /// `pageInline` 是页面内嵌模式，此时内容常驻，不受 `show` 影响。
    public static func isContentVisible(show: Bool,
                                       hasInput: Bool,
                                       showByClickInput: Bool,
                                       pageInline: Bool = false) -> Bool {
        if pageInline { return true }
        return show || (hasInput && showByClickInput)
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
            HStack(spacing: 0) {
                ForEach(columns.indices, id: \.self) { column in
                    UPPickerColumn(
                        options: columns[column],
                        selectedIndex: Binding(
                            get: { selection.indices[column] },
                            set: { select(column: column, index: $0) }
                        ),
                        itemHeight: itemHeight
                    )
                }
            }
            .frame(height: itemHeight * CGFloat(visibleItemCount))
        }
        .disabled(disabled || loading)
    }

    public func select(column: Int, index: Int) {
        guard !disabled,
              columns.indices.contains(column),
              columns[column].indices.contains(index)
        else { return }
        selection.indices[column] = index
        onChangeHandler?(payload(column: column, index: index))
    }

    public func confirm() {
        guard !disabled else { return }
        let event = payload(
            column: max(selection.indices.count - 1, 0),
            index: selection.indices.last ?? 0
        )
        modelValue?.wrappedValue = event.value.map(\.value)
        selection.confirmedIndices = selection.indices
        closeVisibility()
        onConfirmHandler?(event)
        emitClosed()
    }

    public func cancel() {
        guard !disabled else { return }
        selection.indices = selection.confirmedIndices
        closeVisibility()
        onCancelHandler?()
        emitClosed()
    }

    public func overlayClick() {
        guard closeOnClickOverlay else { return }
        selection.indices = selection.confirmedIndices
        closeVisibility()
        onCloseHandler?()
        emitClosed()
    }

    public func onChange(_ action: @escaping (UPPickerChange) -> Void) -> Self {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    public func onConfirm(_ action: @escaping (UPPickerChange) -> Void) -> Self {
        var copy = self
        copy.onConfirmHandler = action
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

    private func closeVisibility() {
        showBinding?.wrappedValue = false
    }

    private func emitClosed() {
        guard let onClosedHandler else { return }
        if pageInline || duration == 0 {
            onClosedHandler()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 1_000) {
                onClosedHandler()
            }
        }
    }

    private func payload(column: Int, index: Int) -> UPPickerChange {
        let selected: [UPPickerData] = columns.enumerated().compactMap { column, values -> UPPickerData? in
            guard selection.indices.indices.contains(column),
                  values.indices.contains(selection.indices[column])
            else { return nil }
            return values[selection.indices[column]]
        }
        return UPPickerChange(
            values: selected,
            indices: selection.indices,
            columnIndex: column,
            index: index,
            allValues: columns
        )
    }

    private static func normalized(_ indices: [Int], columns: [[UPPickerData]]) -> [Int] {
        let candidates = indices.count == columns.count
            ? indices
            : Array(repeating: 0, count: columns.count)
        return columns.enumerated().map { column, values in
            guard !values.isEmpty else { return 0 }
            return min(max(candidates[column], 0), values.count - 1)
        }
    }
}
