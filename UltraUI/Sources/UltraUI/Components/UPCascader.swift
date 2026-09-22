import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-cascader` unit props.
public typealias UPCascaderUnitValue = UPImageUnitValue

/// 上游 `data` 里的一个节点：`item[valueKey]` / `item[labelKey]` / `item[childrenKey]`。
public struct UPCascaderNode: Identifiable, Equatable, Sendable {
    public let id: String
    public var value: String
    public var label: String
    public var children: [Self]

    public init(id: String? = nil, value: String, label: String, children: [Self] = []) {
        self.id = id ?? value
        self.value = value
        self.label = label
        self.children = children
    }
}

/// 对应上游 `data`：`levelList` / `selectedValueIndexs` / `tabsIndex` / `confirmValues`。
@MainActor
@Observable
private final class UPCascaderState {
    /// 上游 `levelList`：每一级要展示的数据。
    var levelList: [[UPCascaderNode]] = []
    /// 上游 `selectedValueIndexs`：每一级选中的下标。
    var selectedValueIndexs: [Int] = []
    var tabsIndex = 0
    var popupShow = false
    /// 上游 `confirmValues`：确认时真正抛出去的值。
    var confirmValues: [String] = []
}

/// Native SwiftUI counterpart of uview-plus `u-cascader`.
///
/// 上游是「底部弹层 + 顶部层级导航（tabs 或竖向 steps）+ 选项列 + 取消/确定」：
/// 点某项后截断其后所有层级，有子级就把子级推进 `levelList` 并切到下一个 tab，
/// 没有子级就按 `autoClose` 决定是否直接确认。
/// 原生保留同一套层级推进/截断算法（`levelList`、`selectedValueIndexs`、`genTabsList` 都可单测）。
@MainActor
public struct UPCascader: View {
    public var data: [UPCascaderNode]
    /// 上游 `show`。
    public var show: Bool
    public var valueKey: String
    public var labelKey: String
    public var childrenKey: String
    public var maskCloseAble: Bool
    public var zIndex: CGFloat
    /// 上游 `autoClose`：选到最后一级时自动确认并关闭。
    public var autoClose: Bool
    /// 上游 `headerDirection`：`row` 用 tabs，`column` 用竖向 steps。
    public var headerDirection: String
    /// 上游 `optionsCols`：1 列时只显示当前级，2 列时并排显示。
    public var optionsCols: Int
    public var closeable: Bool

    private var modelValue: Binding<[String]>?
    private var showBinding: Binding<Bool>?
    @State private var state: UPCascaderState
    private var onChangeHandler: (([String]) -> Void)?
    private var onConfirmHandler: (([String]) -> Void)?
    private var onCancelHandler: (() -> Void)?

    @Environment(\.upTheme) private var theme

    /// 与上游 `props` 对齐的初始化器。
    public init(data: [UPCascaderNode] = [],
                modelValue: Binding<[String]>? = nil,
                show: Bool = false,
                showBinding: Binding<Bool>? = nil,
                valueKey: String = UPConfig.cascader.valueKey,
                labelKey: String = UPConfig.cascader.labelKey,
                childrenKey: String = UPConfig.cascader.childrenKey,
                maskCloseAble: Bool = UPConfig.cascader.maskCloseAble,
                zIndex: any UPCascaderUnitValue = UPConfig.cascader.zIndex,
                autoClose: Bool = UPConfig.cascader.autoClose,
                headerDirection: String = UPConfig.cascader.headerDirection,
                optionsCols: Int = UPConfig.cascader.optionsCols,
                closeable: Bool = UPConfig.cascader.closeable) {
        self.data = data
        self.modelValue = modelValue
        self.show = showBinding?.wrappedValue ?? show
        self.showBinding = showBinding
        self.valueKey = valueKey
        self.labelKey = labelKey
        self.childrenKey = childrenKey
        self.maskCloseAble = maskCloseAble
        self.zIndex = UPUnit.parse(zIndex.upImageUnitValue)
        self.autoClose = autoClose
        self.headerDirection = headerDirection
        self.optionsCols = optionsCols
        self.closeable = closeable
        self._state = State(initialValue: UPCascader.seededState(
            data: data,
            modelValue: modelValue?.wrappedValue ?? [],
            popupShow: showBinding?.wrappedValue ?? show
        ))
    }

    // MARK: - 初始状态

    /// 上游 `initLevelList()` + `setDefaultValue()`。
    private static func seededState(data: [UPCascaderNode],
                                    modelValue: [String],
                                    popupShow: Bool) -> UPCascaderState {
        let state = UPCascaderState()
        state.popupShow = popupShow
        // 上游 `initLevelList`：data 非空才写 levelList。
        if !data.isEmpty { state.levelList = [data] }
        guard !data.isEmpty else { return state }
        guard !modelValue.isEmpty else {
            state.confirmValues = []
            return state
        }

        let (levels, indexes) = resolveLevels(data: data, modelValue: modelValue)
        state.levelList = levels
        state.selectedValueIndexs = indexes
        state.confirmValues = selectedValues(levels: levels, indexes: indexes)
        return state
    }

    /// 上游 `setDefaultValue()` 里那段循环：逐级按 `valueKey` 找下标，
    /// 找不到或没有子级就停下。
    nonisolated static func resolveLevels(data: [UPCascaderNode],
                                         modelValue: [String]) -> ([[UPCascaderNode]], [Int]) {
        var levels: [[UPCascaderNode]] = []
        var indexes: [Int] = []
        var currentLevel = data

        for value in modelValue {
            levels.append(currentLevel)
            guard let index = currentLevel.firstIndex(where: { $0.value == value }) else { break }
            indexes.append(index)
            let children = currentLevel[index].children
            if children.isEmpty { break }
            currentLevel = children
        }
        return (levels, indexes)
    }

    /// 上游 `getSelectedValues()`：逐级取 `levelList[i][index][valueKey]`。
    nonisolated static func selectedValues(levels: [[UPCascaderNode]], indexes: [Int]) -> [String] {
        var result: [String] = []
        for (level, index) in indexes.enumerated() {
            guard levels.indices.contains(level), levels[level].indices.contains(index) else { continue }
            result.append(levels[level][index].value)
        }
        return result
    }

    /// 上游 `genTabsList`：首项是「请选择」，每选一级就把该级标题替换进去，
    /// 若最后一级还有子级则再追加一个「请选择」。
    nonisolated static func tabsList(levels: [[UPCascaderNode]],
                                     indexes: [Int],
                                     placeholder: String = UPConfig.cascader.placeholderTabName) -> [String] {
        var list = [placeholder]
        for (level, index) in indexes.enumerated() {
            guard levels.indices.contains(level), levels[level].indices.contains(index) else { continue }
            let item = levels[level][index]
            if list.indices.contains(level) {
                list[level] = item.label
            } else {
                list.append(item.label)
            }
            if level == indexes.count - 1, !item.children.isEmpty {
                list.append(placeholder)
            }
        }
        return list
    }

    // MARK: - 解析后的呈现值

    public var levelList: [[UPCascaderNode]] { state.levelList }
    public var selectedValueIndexs: [Int] { state.selectedValueIndexs }
    public var tabsIndex: Int { state.tabsIndex }
    public var popupShow: Bool { state.popupShow }
    public var confirmValues: [String] { state.confirmValues }

    /// 上游 `genTabsList`。
    public var genTabsList: [String] {
        Self.tabsList(levels: state.levelList, indexes: state.selectedValueIndexs)
    }

    /// 上游 `isChange`：`tabsIndex > 1` 时选项区整体左移。
    public var isChange: Bool { state.tabsIndex > 1 }

    /// 上游 `uZIndex`：`zIndex` 为 0（假值）时回落 `$u.zIndex.popup`。
    public var resolvedZIndex: Double {
        zIndex > 0 ? Double(zIndex) : UPConfig.cascader.popupZIndex
    }

    /// 上游 `getSelectedValues()`。
    public func getSelectedValues() -> [String] {
        Self.selectedValues(levels: state.levelList, indexes: state.selectedValueIndexs)
    }

    /// 上游模板 `levelIndex === 0 || selectedValueIndexs[levelIndex - 1] !== undefined`。
    public func isLevelVisible(_ level: Int) -> Bool {
        level == 0 || state.selectedValueIndexs.count > level - 1
    }

    /// 上游模板 `selectedValueIndexs[levelIndex] === index`。
    public func isSelected(level: Int, index: Int) -> Bool {
        state.selectedValueIndexs.indices.contains(level) && state.selectedValueIndexs[level] == index
    }

    // MARK: - 上游 methods

    /// 上游 `levelChange(levelIndex, index)`。
    public func levelChange(level: Int, index: Int) {
        guard state.levelList.indices.contains(level), state.levelList[level].indices.contains(index) else { return }

        if state.selectedValueIndexs.count > level {
            state.selectedValueIndexs[level] = index
            // 上游 `splice(levelIndex + 1)`：截断其后所有选中项。
            state.selectedValueIndexs = Array(state.selectedValueIndexs.prefix(level + 1))
        } else {
            // 上游 `$set` 在下标越界时也会补齐，这里按层级顺序追加。
            state.selectedValueIndexs = Array(state.selectedValueIndexs.prefix(level)) + [index]
        }
        state.tabsIndex = min(state.tabsIndex, level)
        state.levelList = Array(state.levelList.prefix(level + 1))

        let currentItem = state.levelList[level][index]
        if !currentItem.children.isEmpty {
            state.levelList.append(currentItem.children)
            state.tabsIndex = level + 1
        } else if autoClose {
            // 上游先 emitChange()（会顺带 close）再 handleConfirm()。
            emitChange()
            handleConfirm()
        } else {
            emitChange(closePopup: false)
        }
    }

    /// 仓库既有方法：按下标路径一次性选到底。
    public func select(path: [Int]) {
        for (level, index) in path.enumerated() {
            levelChange(level: level, index: index)
        }
        if !autoClose { state.confirmValues = getSelectedValues() }
    }

    /// 上游 `emitChange(closePopup = true)`：先同步 `confirmValues` 再抛 `change`。
    public func emitChange(closePopup: Bool = true) {
        let result = getSelectedValues()
        state.confirmValues = result
        onChangeHandler?(result)
        if closePopup { close() }
    }

    /// 上游 `handleConfirm()`：`confirmValues` 为空时兜底重算，然后写回并抛 `confirm`。
    public func handleConfirm() {
        let values = state.confirmValues.isEmpty ? getSelectedValues() : state.confirmValues
        state.confirmValues = values
        modelValue?.wrappedValue = values
        onConfirmHandler?(values)
        close()
    }

    /// 仓库既有名。
    public func confirm() { handleConfirm() }

    /// 上游 `close()`：抛 `cancel` 并把 `show` 置假。
    ///
    /// 照抄上游这处反直觉：确认路径最后也会走 `close()`，因此 `confirm` 之后
    /// 紧跟着还会抛一次 `cancel`。
    public func close() {
        onCancelHandler?()
        state.popupShow = false
        showBinding?.wrappedValue = false
    }

    /// 上游 `handleCancel()`。
    public func handleCancel() { close() }

    /// 仓库既有名。
    public func cancel() { close() }

    /// 上游 `toFatherIndex(index)`：竖向导航点某级时跳回该级。
    public func toFatherIndex(_ index: Int) { state.tabsIndex = index }

    /// 上游 `tabsChange(item)` 是空实现，原生保留同名入口。
    public func tabsChange(_ index: Int) {}

    public func open() {
        state.popupShow = true
        showBinding?.wrappedValue = true
    }

    // MARK: - 事件

    /// 对应上游 `change` 事件，负载是值数组。
    public func onChange(_ action: @escaping ([String]) -> Void) -> Self {
        var copy = self
        copy.onChangeHandler = action
        return copy
    }

    /// 对应上游 `confirm` 事件（同时写回 `update:modelValue`）。
    public func onConfirm(_ action: @escaping ([String]) -> Void) -> Self {
        var copy = self
        copy.onConfirmHandler = action
        return copy
    }

    /// 对应上游 `cancel` 事件（同时写回 `update:show`）。
    public func onCancel(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onCancelHandler = action
        return copy
    }

    // MARK: - 视图

    public var body: some View {
        UPPopup(show: Binding(get: { state.popupShow }, set: { state.popupShow = $0 }),
                mode: "bottom",
                closeable: closeable,
                closeOnClickOverlay: maskCloseAble,
                zIndex: resolvedZIndex,
                safeAreaInsetBottom: true,
                onClose: { close() }) {
            VStack(spacing: 0) {
                header
                optionPanes
                actionBar
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if headerDirection == "column" {
            // 上游竖向用 `up-steps direction="column" dot`，点某级跳回该级。
            UPSteps(direction: "column", current: state.tabsIndex, dot: true) {
                ForEach(Array(genTabsList.enumerated()), id: \.offset) { index, name in
                    UPStepsItem(title: name)
                        .onTapGesture { toFatherIndex(index) }
                }
            }
            .padding(.top, UPUnit.rpx(CGFloat(30)))
            .padding(.leading, UPUnit.rpx(CGFloat(20)))
            .padding(.bottom, UPUnit.rpx(CGFloat(10)))
        } else {
            UPTabs(list: genTabsList.map { UPTabsItem(name: $0) },
                   current: Binding(get: { state.tabsIndex }, set: { state.tabsIndex = $0 }),
                   scrollable: true)
                .padding(.top, UPUnit.rpx(CGFloat(20)))
                .padding(.bottom, UPUnit.rpx(CGFloat(10)))
        }
    }

    /// 上游 `.area-box`：固定 800rpx 高，两列模式下并排铺开、`tabsIndex > 1` 时整体左移。
    private var optionPanes: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(Array(state.levelList.enumerated()), id: \.offset) { level, nodes in
                    if optionsCols == 2 || level == state.tabsIndex {
                        levelPane(level: level, nodes: nodes)
                            .frame(width: optionsCols == 2
                                   ? proxy.size.width * UPConfig.cascader.twoColumnRatio * 1.5
                                   : proxy.size.width)
                    }
                }
            }
            .offset(x: optionsCols == 2 && isChange
                    ? -proxy.size.width * UPConfig.cascader.twoColumnRatio
                    : 0)
            .animation(.easeInOut(duration: 0.3), value: state.tabsIndex)
        }
        .frame(height: UPConfig.cascader.paneHeight)
        .clipped()
    }

    private func levelPane(level: Int, nodes: [UPCascaderNode]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                if isLevelVisible(level) {
                    ForEach(Array(nodes.enumerated()), id: \.offset) { index, node in
                        UPCell(title: node.label,
                               onTap: { levelChange(level: level, index: index) })
                            .overlay(alignment: .trailing) {
                                if isSelected(level: level, index: index) {
                                    UPIcon(name: UPConfig.cascader.checkedIcon,
                                           size: UPConfig.cascader.checkedIconSize)
                                        .padding(.trailing, 15)
                                }
                            }
                    }
                }
            }
        }
        .padding(UPUnit.rpx(CGFloat(10)))
        .frame(maxHeight: .infinity)
        .background(UPColor.parse(UPConfig.cascader.paneBackgroundColor, theme: theme))
    }

    /// 上游 `.u-cascader-action`：顶部一条边框、左右两个按钮。
    private var actionBar: some View {
        HStack(spacing: 0) {
            UPButton(type: "default", text: UPConfig.cascader.cancelText, block: true) {
                handleCancel()
            }
            .padding(UPUnit.rpx(CGFloat(20)))

            UPButton(type: "primary", text: UPConfig.cascader.confirmText, block: true) {
                handleConfirm()
            }
            .padding(UPUnit.rpx(CGFloat(20)))
        }
        .overlay(alignment: .top) { UPLine() }
    }
}
