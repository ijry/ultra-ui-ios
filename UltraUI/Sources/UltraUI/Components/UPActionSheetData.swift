import Observation
import SwiftUI

/// 对应上游 `data`：`show` 与回显文本 `current`。
@MainActor
@Observable
private final class UPActionSheetDataState {
    var show = false
    var current = ""
}

/// Native SwiftUI counterpart of uview-plus `u-action-sheet-data`.
///
/// 上游是「一个只读输入框 + 盖在上面的透明层」：点透明层打开 `u-action-sheet`，
/// 选中后把 `option[valueKey]` 写回 `modelValue`、把 `option[labelKey]` 显示在输入框里。
@MainActor
public struct UPActionSheetData: View {
    /// 上游 `title`：既是输入框 placeholder，也是面板标题。
    public var title: String
    /// 上游 `description`。
    public var description: String
    /// 上游 `options`：直接透传给 `u-action-sheet` 的 `actions`。
    public var options: [UPActionSheetAction]
    /// 上游 `valueKey`：写回 `modelValue` 时取的字段，默认 `value`。
    public var valueKey: String
    /// 上游 `labelKey`：回显文本取的字段，默认 `name`。
    public var labelKey: String

    private var modelValue: Binding<String>?
    @State private var state: UPActionSheetDataState
    private var onChangeHandler: ((String) -> Void)?
    private var triggerSlot: AnyView?

    /// 与上游 `props` 对齐的初始化器。
    public init(modelValue: Binding<String>? = nil,
                title: String = UPConfig.actionSheetData.title,
                description: String = UPConfig.actionSheetData.description,
                options: [UPActionSheetAction] = [],
                valueKey: String = UPConfig.actionSheetData.valueKey,
                labelKey: String = UPConfig.actionSheetData.labelKey) {
        self.modelValue = modelValue
        self.title = title
        self.description = description
        self.options = options
        self.valueKey = valueKey
        self.labelKey = labelKey
        let state = UPActionSheetDataState()
        // 上游 `created`：`modelValue` 非空时按 `valueKey` 找回显文本。
        state.current = Self.label(for: modelValue?.wrappedValue ?? UPConfig.actionSheetData.modelValue,
                                   in: options,
                                   valueKey: valueKey,
                                   labelKey: labelKey)
        self._state = State(initialValue: state)
    }

    // MARK: - 解析后的呈现值

    /// 上游 `current`：输入框里显示的文本。
    public var current: String { state.current }
    /// 上游 `show`。
    public var show: Bool { state.show }

    /// 上游 `created` / `watch.modelValue` 里那段 `forEach`：按 `valueKey` 匹配后取 `labelKey`。
    ///
    /// 照抄上游：`modelValue` 为空时 `created` 分支根本不跑，因此回显保持空串；
    /// 匹配不到时也不清空（上游 `forEach` 只在命中时赋值），这里同样返回空串表示未命中。
    nonisolated static func label(for value: String,
                                  in options: [UPActionSheetAction],
                                  valueKey: String,
                                  labelKey: String) -> String {
        guard !value.isEmpty else { return "" }
        for option in options where option.value(for: valueKey) == value {
            return option.value(for: labelKey) ?? ""
        }
        return ""
    }

    // MARK: - 上游 methods

    /// 上游 `select(e)`：写回 `update:modelValue` 并刷新回显文本。
    public func select(_ option: UPActionSheetAction) {
        let value = option.value(for: valueKey) ?? ""
        modelValue?.wrappedValue = value
        state.current = option.value(for: labelKey) ?? ""
        onChangeHandler?(value)
    }

    public func open() { state.show = true }

    /// 上游 `@close="show = false"`。
    public func close() { state.show = false }

    // MARK: - 事件

    /// 对应上游 `update:modelValue`，负载是 `option[valueKey]`。
    public func onChange(_ action: @escaping (String) -> Void) -> UPActionSheetData {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    // MARK: - 插槽

    /// 对应上游具名插槽 `trigger`：给了它就不再渲染内建的只读输入框。
    public func trigger<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPActionSheetData {
        var copy = self
        copy.triggerSlot = AnyView(builder())
        return copy
    }

    public var hasTriggerSlot: Bool { triggerSlot != nil }

    // MARK: - 视图

    public var body: some View {
        ZStack {
            triggerView

            // 上游 `__trigger__cover`：铺满触发区的透明层，点它才打开面板。
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { open() }
        }
        .overlay {
            UPActionSheet(show: Binding(get: { state.show }, set: { state.show = $0 }),
                          title: title,
                          description: description,
                          actions: options,
                          safeAreaInsetBottom: true,
                          onSelect: { select($0) },
                          onClose: { close() })
        }
    }

    @ViewBuilder
    private var triggerView: some View {
        if let triggerSlot {
            triggerSlot
        } else {
            UPInput(text: Binding(get: { state.current }, set: { _ in }),
                    placeholder: title,
                    border: UPConfig.actionSheetData.border,
                    disabled: true,
                    disabledColor: UPConfig.actionSheetData.disabledColor)
        }
    }
}
