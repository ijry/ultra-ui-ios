import Observation
import SwiftUI

/// A string-or-number value accepted by uview-plus `u-waterfall` unit props.
public typealias UPWaterfallUnitValue = UPImageUnitValue

/// 对应上游 `data`：`columnList`、量出来的列高、`distributionGeneration` 与 `windowWidth`。
@MainActor
@Observable
private final class UPWaterfallState<Item> {
    /// 上游 `columnList`，初始值同样是 `[[]]`，`created` 里再按列数重建。
    var columnList: [[Item]] = [[]]
    /// 上游 `getColumnHeights()` 用 `$uGetRect('#u-column-i')` 量到的列高。
    var measuredHeights: [CGFloat] = []
    /// 已分配数据的签名，对应上游 watcher 里的 `oVal`。
    var distributedSignature: [String] = []
    /// 上游 `distributionGeneration`：数据换代时让在跑的分配循环立即退出。
    var generation = 0
    /// 上游 `windowWidth`，原生量的是容器宽度。
    var containerWidth: CGFloat = UPConfig.waterfall.windowWidth
}

/// `.task(id:)` 的键：数据签名或列数变化都要重新分配。
private struct UPWaterfallTaskKey: Equatable {
    var signature: [String]
    var columnCount: Int
}

/// Native SwiftUI counterpart of uview-plus `u-waterfall`.
///
/// 上游是「按列存数据」的瀑布流：每来一条数据先量一遍所有列的真实高度，塞进最短列，
/// 等 `addTime` 毫秒后再量一次该列高度并抛 `after-add-one`，整批结束抛 `after-add-all`。
/// 原生保留同一套流程（列高用 `GeometryReader` 量、`addTime` 用 `Task.sleep`），
/// 同时保留仓库既有的「一次性 view 树 + 自定义 `Layout` 最短列」形态。
@MainActor
public struct UPWaterfall<Item, Content: View>: View {
    /// 上游 `columns`：数字，或 `'auto'` 按屏宽自适应。
    public var columns: String
    /// 上游 `columnsMin`：auto 模式下的最小列数。
    public var columnsMin: Int
    /// 上游 `minColumnWidth`：auto 模式下每列的最小宽度。
    public var minColumnWidth: CGFloat
    /// 上游 `addTime`：单条数据插入结构的时间间隔，单位 ms。
    public var addTime: Double
    /// 上游 `idKey`：`remove` / `modify` 靠它定位数据。
    public var idKey: String
    /// 上游 `.u-column:not(:first-child) { margin-left: 10rpx }`。
    public var columnGap: CGFloat
    /// 原生补充：列内相邻卡片的间距（上游列内无间距，由卡片自带 margin）。
    public var rowGap: CGFloat

    private var modelValue: Binding<[Item]>?
    private let itemContent: ((Item) -> Content)?
    private let staticContent: Content?
    private var keyProvider: ((Item) -> String)?
    private var columnSlot: ((Int, [Item]) -> AnyView)?
    private var leftSlot: ((Int, [Item]) -> AnyView)?
    private var onAfterAddOneHandler: ((Item, CGFloat) -> Void)?
    private var onAfterAddAllHandler: (([CGFloat], [Item]) -> Void)?

    @State private var state: UPWaterfallState<Item>

    fileprivate init(modelValue: Binding<[Item]>?,
                     addTime: Double,
                     idKey: String,
                     columns: String,
                     columnsMin: Int,
                     minColumnWidth: CGFloat,
                     columnGap: CGFloat,
                     rowGap: CGFloat,
                     keyProvider: ((Item) -> String)?,
                     itemContent: ((Item) -> Content)?,
                     staticContent: Content?) {
        self.modelValue = modelValue
        self.addTime = addTime
        self.idKey = idKey
        self.columns = columns
        self.columnsMin = columnsMin
        self.minColumnWidth = minColumnWidth
        self.columnGap = columnGap
        self.rowGap = rowGap
        self.keyProvider = keyProvider
        self.itemContent = itemContent
        self.staticContent = staticContent
        self._state = State(initialValue: UPWaterfallState<Item>())
    }

    /// 与上游 `props` 对齐的初始化器：`modelValue` 是必填数据源。
    public init(modelValue: Binding<[Item]>,
                addTime: any UPWaterfallUnitValue = UPConfig.waterfall.addTime,
                idKey: String = UPConfig.waterfall.idKey,
                columns: any UPWaterfallUnitValue = UPConfig.waterfall.columns,
                columnsMin: any UPWaterfallUnitValue = UPConfig.waterfall.columnsMin,
                minColumnWidth: any UPWaterfallUnitValue = UPConfig.waterfall.minColumnWidth,
                columnGap: CGFloat = UPConfig.waterfall.columnGap,
                rowGap: CGFloat = 0,
                key: ((Item) -> String)? = nil,
                @ViewBuilder content: @escaping (Item) -> Content) {
        self.init(modelValue: modelValue,
                  addTime: Self.parseAddTime(addTime.upImageUnitValue),
                  idKey: idKey,
                  columns: columns.upImageUnitValue,
                  columnsMin: Self.parseCount(columnsMin.upImageUnitValue),
                  minColumnWidth: Self.parseWidth(minColumnWidth.upImageUnitValue),
                  columnGap: max(columnGap, 0),
                  rowGap: max(rowGap, 0),
                  keyProvider: key,
                  itemContent: content,
                  staticContent: nil)
    }

    // MARK: - 解析后的呈现值

    /// 上游 `getColumnsCount()`：`'auto'` 按屏宽算，否则 `parseInt(columns) || 2`。
    /// 上游 `Array.from({ length: -1 })` 会得到 0 列，原生至少保留 1 列避免除零。
    public var columnCount: Int {
        guard columns == "auto" else { return max(Self.parseColumns(columns), 1) }
        let width = state.containerWidth > 0 ? state.containerWidth : UPConfig.waterfall.windowWidth
        return Self.autoColumnCount(windowWidth: width,
                                    minColumnWidth: minColumnWidth,
                                    columnsMin: columnsMin)
    }

    /// 上游 `columnList`：每列当前持有的数据。
    public var columnList: [[Item]] { state.columnList }

    /// 上游 `getColumnHeights()` 的结果。
    public var measuredColumnHeights: [CGFloat] { normalizedHeights() }

    /// 上游 `val[idKey] == id`。原生没有字符串下标读取，传了 `key` 用它，否则退回
    /// `String(describing:)`（与上游 `JSON.stringify` 比较同源）。
    public func itemKey(_ item: Item) -> String {
        keyProvider?(item) ?? String(describing: item)
    }

    // MARK: - 上游 methods

    /// 上游 `clear(bak = true)`：换代、清空列数据，并按需把空数组写回 `modelValue`。
    public func clear(bak: Bool = true) {
        state.generation += 1
        state.distributedSignature = []
        initColumnList()
        if bak { modelValue?.wrappedValue = [] }
    }

    /// 上游 `remove(id)`：先从列数据里删，再从 `modelValue` 里删。
    /// 写回后上游 watcher 判定「非纯追加」会整体重排，原生同样交给 `.task(id:)` 重排。
    public func remove(_ id: String) {
        for columnIndex in state.columnList.indices {
            if let index = state.columnList[columnIndex].firstIndex(where: { itemKey($0) == id }) {
                state.columnList[columnIndex].remove(at: index)
                break
            }
        }
        guard let modelValue else { return }
        var items = modelValue.wrappedValue
        guard let index = items.firstIndex(where: { itemKey($0) == id }) else { return }
        items.remove(at: index)
        modelValue.wrappedValue = items
    }

    /// 上游 `modify(id, key, value)`。Swift 侧没有字符串下标写入，
    /// 因此「改哪个字段」交给 `transform` 闭包；命中列数据后才会同步 `modelValue`。
    public func modify(_ id: String, _ transform: (inout Item) -> Void) {
        var found = false
        for columnIndex in state.columnList.indices {
            if let index = state.columnList[columnIndex].firstIndex(where: { itemKey($0) == id }) {
                transform(&state.columnList[columnIndex][index])
                found = true
                break
            }
        }
        guard found, let modelValue else { return }
        var items = modelValue.wrappedValue
        guard let index = items.firstIndex(where: { itemKey($0) == id }) else { return }
        transform(&items[index])
        modelValue.wrappedValue = items
    }

    // MARK: - 分配流程

    /// 上游 `initColumnList()`。
    private func initColumnList() {
        let count = max(columnCount, 1)
        state.columnList = Array(repeating: [], count: count)
        state.measuredHeights = Array(repeating: 0, count: count)
    }

    /// 对应上游 `copyFlowList` watcher：空数据 `clear(false)`，纯追加只排新增部分，
    /// 否则整体重排。
    private func synchronize() async {
        let items = modelValue?.wrappedValue ?? []
        guard !items.isEmpty else {
            clear(bak: false)
            return
        }
        let signature = Self.signature(of: items)
        guard state.columnList.count == max(columnCount, 1) else {
            await redistribute(items, signature: signature)
            return
        }
        if Self.isPureAppend(oldSignature: state.distributedSignature, newSignature: signature) {
            let startIndex = min(state.distributedSignature.count, items.count)
            state.distributedSignature = signature
            await distribute(Array(items.dropFirst(startIndex)))
        } else {
            await redistribute(items, signature: signature)
        }
    }

    /// 上游 `redistributeData()`。
    private func redistribute(_ items: [Item], signature: [String]) async {
        state.generation += 1
        state.distributedSignature = signature
        initColumnList()
        await distribute(items)
    }

    /// 上游 `distributeData(newData, generation)`。
    private func distribute(_ newData: [Item]) async {
        guard !newData.isEmpty else { return }
        let generation = state.generation
        var columnHeights = Array(repeating: CGFloat.zero, count: state.columnList.count)
        for item in newData {
            if generation != state.generation || Task.isCancelled { return }
            columnHeights = normalizedHeights()
            let index = Self.minHeightColumnIndex(columnHeights: columnHeights,
                                                  columnCounts: state.columnList.map(\.count))
            guard state.columnList.indices.contains(index) else { return }
            state.columnList[index].append(item)
            if addTime > 0 {
                try? await Task.sleep(for: .seconds(addTime / 1000))
            }
            await Task.yield()
            if generation != state.generation || Task.isCancelled { return }
            let height = normalizedHeights()[index]
            if height > 0 {
                columnHeights[index] = height
                onAfterAddOneHandler?(item, height)
            }
        }
        if generation != state.generation { return }
        onAfterAddAllHandler?(columnHeights, newData)
    }

    private func normalizedHeights() -> [CGFloat] {
        let count = state.columnList.count
        var heights = state.measuredHeights
        if heights.count < count {
            heights.append(contentsOf: Array(repeating: 0, count: count - heights.count))
        }
        if heights.count > count { heights = Array(heights.prefix(count)) }
        return heights
    }

    private func setMeasuredHeight(_ height: CGFloat, at index: Int) {
        var heights = normalizedHeights()
        guard heights.indices.contains(index), heights[index] != max(height, 0) else { return }
        heights[index] = max(height, 0)
        state.measuredHeights = heights
    }

    // MARK: - 可单测的纯函数

    /// 上游 `cloneData` + `JSON.stringify` 比较用的签名。
    nonisolated static func signature(of items: [Item]) -> [String] {
        items.map { String(describing: $0) }
    }

    /// 上游 `parseInt(this.columns) || 2`。
    nonisolated static func parseColumns(_ value: String) -> Int {
        let digits = value.prefix { $0.isNumber || $0 == "-" || $0 == "+" }
        let parsed = Int(digits) ?? 0
        return parsed != 0 ? parsed : 2
    }

    /// 上游 auto 模式：`max(1, floor(windowWidth / (minColumnWidth + 7)))`，再抬到 `columnsMin`。
    nonisolated static func autoColumnCount(windowWidth: CGFloat,
                                            minColumnWidth: CGFloat,
                                            columnsMin: Int) -> Int {
        let denominator = max(minColumnWidth + UPConfig.waterfall.autoColumnGap, 1)
        var count = max(1, Int((windowWidth / denominator).rounded(.down)))
        if count < columnsMin { count = columnsMin }
        return max(count, 1)
    }

    /// 上游 `isPureAppend`：旧数组为空算追加，新数组更短不算，否则逐项比较。
    nonisolated static func isPureAppend(oldSignature: [String], newSignature: [String]) -> Bool {
        guard !oldSignature.isEmpty else { return true }
        guard newSignature.count >= oldSignature.count else { return false }
        return zip(oldSignature, newSignature).allSatisfy { $0 == $1 }
    }

    /// 上游 `getMinHeightColumnIndex`：高度相同时按列数据量打散。
    nonisolated static func minHeightColumnIndex(columnHeights: [CGFloat], columnCounts: [Int]) -> Int {
        guard columnHeights.count > 1 else { return 0 }
        var minIndex = 0
        for index in 1..<columnHeights.count {
            let current = columnHeights[index]
            let minimum = columnHeights[minIndex]
            if current < minimum {
                minIndex = index
            } else if current == minimum {
                let currentCount = columnCounts.indices.contains(index) ? columnCounts[index] : 0
                let minCount = columnCounts.indices.contains(minIndex) ? columnCounts[minIndex] : 0
                if currentCount < minCount { minIndex = index }
            }
        }
        return minIndex
    }

    nonisolated static func parseAddTime(_ value: String) -> Double {
        let parsed = Double(UPUnit.parse(value))
        guard parsed.isFinite, parsed > 0 else { return 0 }
        return min(parsed, 60_000)
    }

    nonisolated static func parseCount(_ value: String) -> Int {
        let parsed = UPUnit.parse(value)
        guard parsed.isFinite else { return UPConfig.waterfall.columnsMin }
        return Int(min(max(parsed, 0), 999))
    }

    nonisolated static func parseWidth(_ value: String) -> CGFloat {
        let parsed = UPUnit.parse(value)
        guard parsed.isFinite else { return CGFloat(UPConfig.waterfall.minColumnWidth) }
        return max(parsed, 0)
    }

    /// 仓库既有方法：给定各卡片高度，算出它们落在哪一列。
    public func columnAssignments(heights: [CGFloat]) -> [Int] {
        var totals = Array(repeating: CGFloat.zero, count: max(columnCount, 1))
        return heights.map { height in
            let column = shortestColumn(in: totals)
            if totals[column] > 0 { totals[column] += rowGap }
            totals[column] += max(height, 0)
            return column
        }
    }

    /// 仓库既有方法：给定各卡片高度，算出各列总高。
    public func columnHeights(heights: [CGFloat]) -> [CGFloat] {
        var totals = Array(repeating: CGFloat.zero, count: max(columnCount, 1))
        for height in heights {
            let column = shortestColumn(in: totals)
            if totals[column] > 0 { totals[column] += rowGap }
            totals[column] += max(height, 0)
        }
        return totals
    }

    private func shortestColumn(in heights: [CGFloat]) -> Int {
        heights.indices.min { lhs, rhs in
            heights[lhs] == heights[rhs] ? lhs < rhs : heights[lhs] < heights[rhs]
        } ?? 0
    }

    // MARK: - 事件

    /// 对应上游 `after-add-one`，负载是 `{ ...item, height }`。
    public func onAfterAddOne(_ action: @escaping (Item, CGFloat) -> Void) -> UPWaterfall {
        var copy = self
        copy.onAfterAddOneHandler = action
        return copy
    }

    /// 对应上游 `after-add-all`，负载是 `{ columnHeights, newData }`。
    public func onAfterAddAll(_ action: @escaping ([CGFloat], [Item]) -> Void) -> UPWaterfall {
        var copy = self
        copy.onAfterAddAllHandler = action
        return copy
    }

    // MARK: - 插槽

    /// 对应上游作用域插槽 `column`，参数是 `colIndex` 与 `colList`。
    public func column<Slot: View>(@ViewBuilder _ builder: @escaping (Int, [Item]) -> Slot) -> UPWaterfall {
        var copy = self
        copy.columnSlot = { AnyView(builder($0, $1)) }
        return copy
    }

    /// 对应上游作用域插槽 `left`，参数是 `colIndex` 与 `leftList`。
    public func left<Slot: View>(@ViewBuilder _ builder: @escaping (Int, [Item]) -> Slot) -> UPWaterfall {
        var copy = self
        copy.leftSlot = { AnyView(builder($0, $1)) }
        return copy
    }

    public var hasColumnSlot: Bool { columnSlot != nil }
    public var hasLeftSlot: Bool { leftSlot != nil }

    // MARK: - 视图

    public var body: some View {
        Group {
            if let staticContent {
                UPWaterfallLayout(columnCount: columnCount, columnGap: columnGap, rowGap: rowGap) {
                    staticContent
                }
            } else {
                dataBody
            }
        }
        .background(widthProbe)
    }

    /// 上游模板：横排若干 `.u-column`，每列 `flex: 1`，列间 `margin-left: 10rpx`。
    private var dataBody: some View {
        HStack(alignment: .top, spacing: columnGap) {
            ForEach(Array(state.columnList.indices), id: \.self) { index in
                columnView(at: index)
            }
        }
        .task(id: taskKey) { await synchronize() }
    }

    private var taskKey: UPWaterfallTaskKey {
        UPWaterfallTaskKey(signature: Self.signature(of: modelValue?.wrappedValue ?? []),
                           columnCount: columnCount)
    }

    /// 照抄上游：`column` 与 `left` 两个插槽都会渲染，两者都没给时才渲染默认插槽。
    private func columnView(at index: Int) -> some View {
        let items = state.columnList.indices.contains(index) ? state.columnList[index] : []
        return VStack(spacing: rowGap) {
            if let columnSlot { columnSlot(index, items) }
            if let leftSlot { leftSlot(index, items) }
            if columnSlot == nil, leftSlot == nil, let itemContent {
                ForEach(Array(items.indices), id: \.self) { itemIndex in
                    itemContent(items[itemIndex])
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(heightProbe(index: index))
    }

    /// 上游 `getColumnHeights()` 用 selectorQuery 量 `#u-column-i`，原生用 GeometryReader。
    private func heightProbe(index: Int) -> some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { setMeasuredHeight(proxy.size.height, at: index) }
                .onChange(of: proxy.size.height) { _, value in setMeasuredHeight(value, at: index) }
        }
    }

    /// 上游 `windowWidth` 来自 `getSystemInfoSync()`，原生量容器宽度更贴近实际排布。
    private var widthProbe: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { state.containerWidth = proxy.size.width }
                .onChange(of: proxy.size.width) { _, value in state.containerWidth = value }
        }
    }
}

public extension UPWaterfall where Item == Never {
    /// 仓库既有签名：数据由调用方在 view 树里直接铺开，走自定义 `Layout` 的最短列分配。
    init(columnCount: Int = 2,
         columnGap: CGFloat = 10,
         rowGap: CGFloat? = nil,
         @ViewBuilder content: () -> Content) {
        self.init(modelValue: nil,
                  addTime: UPConfig.waterfall.addTime,
                  idKey: UPConfig.waterfall.idKey,
                  columns: String(max(columnCount, 1)),
                  columnsMin: UPConfig.waterfall.columnsMin,
                  minColumnWidth: CGFloat(UPConfig.waterfall.minColumnWidth),
                  columnGap: max(columnGap, 0),
                  rowGap: max(rowGap ?? columnGap, 0),
                  keyProvider: nil,
                  itemContent: nil,
                  staticContent: content())
    }
}

public extension UPWaterfall where Item == Never, Content == EmptyView {
    init(columnCount: Int = 2, columnGap: CGFloat = 10, rowGap: CGFloat? = nil) {
        self.init(columnCount: columnCount,
                  columnGap: columnGap,
                  rowGap: rowGap,
                  content: EmptyView.init)
    }
}

public extension UPWaterfall where Content == EmptyView {
    init(modelValue: Binding<[Item]>,
         addTime: any UPWaterfallUnitValue = UPConfig.waterfall.addTime,
         idKey: String = UPConfig.waterfall.idKey,
         columns: any UPWaterfallUnitValue = UPConfig.waterfall.columns,
         columnsMin: any UPWaterfallUnitValue = UPConfig.waterfall.columnsMin,
         minColumnWidth: any UPWaterfallUnitValue = UPConfig.waterfall.minColumnWidth,
         columnGap: CGFloat = UPConfig.waterfall.columnGap,
         rowGap: CGFloat = 0,
         key: ((Item) -> String)? = nil) {
        self.init(modelValue: modelValue,
                  addTime: addTime,
                  idKey: idKey,
                  columns: columns,
                  columnsMin: columnsMin,
                  minColumnWidth: minColumnWidth,
                  columnGap: columnGap,
                  rowGap: rowGap,
                  key: key,
                  content: { _ in EmptyView() })
    }
}

private struct UPWaterfallLayout: Layout {
    var columnCount: Int
    var columnGap: CGFloat
    var rowGap: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = max(proposal.width ?? 0, 0)
        let frames = frames(width: width, subviews: subviews)
        return CGSize(width: width, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let placements = frames(width: bounds.width, subviews: subviews)
        for (subview, frame) in zip(subviews, placements) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func frames(width: CGFloat, subviews: Subviews) -> [CGRect] {
        let columns = max(columnCount, 1)
        let itemWidth = max(
            (width - CGFloat(columns - 1) * columnGap) / CGFloat(columns),
            0
        )
        var heights = Array(repeating: CGFloat.zero, count: columns)

        return subviews.map { subview in
            let column = heights.indices.min { lhs, rhs in
                heights[lhs] == heights[rhs] ? lhs < rhs : heights[lhs] < heights[rhs]
            } ?? 0
            let size = subview.sizeThatFits(ProposedViewSize(width: itemWidth, height: nil))
            let y = heights[column] > 0 ? heights[column] + rowGap : 0
            let frame = CGRect(
                x: CGFloat(column) * (itemWidth + columnGap),
                y: y,
                width: itemWidth,
                height: size.height
            )
            heights[column] = frame.maxY
            return frame
        }
    }
}
