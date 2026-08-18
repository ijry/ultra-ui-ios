import SwiftUI

/// String-or-number values accepted by uview-plus `u-grid` props.
public typealias UPGridUnitValue = UPCheckboxUnitValue

/// String-or-number values accepted by the `u-grid-item.name` prop.
public typealias UPGridName = UPCellName
public typealias UPGridNameValue = UPCellNameValue

/// The native alignment equivalent of uview-plus's `left`/`center`/`right`
/// grid prop values.
public enum UPGridAlignment: String, Equatable, Sendable {
    case leading
    case center
    case trailing

    var swiftUIAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

/// Deterministic geometry used by the grid layout and by native adapters that
/// need to calculate a cell's width before rendering it.
public struct UPGridLayoutMetrics: Equatable, Sendable {
    public let containerWidth: CGFloat
    public let columns: Int
    public let gap: CGFloat
    public let itemCount: Int
    public let itemWidth: CGFloat
    public let rowCount: Int
    public let lastRowItemCount: Int

    public init(containerWidth: CGFloat, columns: Int, gap: CGFloat, itemCount: Int) {
        let safeWidth = max(containerWidth, 0)
        let safeColumns = max(columns, 1)
        let safeGap = max(gap, 0)
        let safeItemCount = max(itemCount, 0)
        let horizontalGap = safeGap * CGFloat(max(safeColumns - 1, 0))

        self.containerWidth = safeWidth
        self.columns = safeColumns
        self.gap = safeGap
        self.itemCount = safeItemCount
        self.itemWidth = max((safeWidth - horizontalGap) / CGFloat(safeColumns), 0)
        self.rowCount = safeItemCount == 0
            ? 0
            : (safeItemCount + safeColumns - 1) / safeColumns
        self.lastRowItemCount = safeItemCount == 0
            ? 0
            : ((safeItemCount - 1) % safeColumns) + 1
    }

    public func lastRowLeadingOffset(for alignment: UPGridAlignment) -> CGFloat {
        guard lastRowItemCount > 0, lastRowItemCount < columns else { return 0 }

        let occupiedWidth = itemWidth * CGFloat(lastRowItemCount)
            + gap * CGFloat(max(lastRowItemCount - 1, 0))
        let remainingWidth = max(containerWidth - occupiedWidth, 0)

        switch alignment {
        case .leading: return 0
        case .center: return remainingWidth / 2
        case .trailing: return remainingWidth
        }
    }
}

/// Dispatches both the item-level and grid-level click events. Keeping this
/// rule in one place mirrors Vue's item event followed by the parent event and
/// makes it straightforward for future native adapters to reuse.
enum UPGridEventContext {
    static func performClick(
        name: UPGridName?,
        itemAction: ((UPGridName?) -> Void)?,
        gridAction: ((UPGridName?) -> Void)?
    ) {
        itemAction?(name)
        gridAction?(name)
    }
}

struct UPGridClickContext: @unchecked Sendable {
    let action: ((UPGridName?) -> Void)?
}

private struct UPGridClickContextKey: EnvironmentKey {
    static let defaultValue: UPGridClickContext? = nil
}

private struct UPGridBorderKey: EnvironmentKey {
    static let defaultValue = false
}

private struct UPGridBorderColorKey: EnvironmentKey {
    static let defaultValue = UPTheme.default.border
}

private extension EnvironmentValues {
    var upGridClickContext: UPGridClickContext? {
        get { self[UPGridClickContextKey.self] }
        set { self[UPGridClickContextKey.self] = newValue }
    }

    var upGridBorder: Bool {
        get { self[UPGridBorderKey.self] }
        set { self[UPGridBorderKey.self] = newValue }
    }

    var upGridBorderColor: Color {
        get { self[UPGridBorderColorKey.self] }
        set { self[UPGridBorderColorKey.self] = newValue }
    }
}

/// A SwiftUI `Layout` that reproduces uview-plus's fixed-column grid.
struct UPGridLayout: Layout {
    let columns: Int
    let gap: CGFloat
    let alignment: UPGridAlignment

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let containerWidth = resolvedContainerWidth(proposal: proposal, subviews: subviews)
        let metrics = UPGridLayoutMetrics(
            containerWidth: containerWidth,
            columns: columns,
            gap: gap,
            itemCount: subviews.count
        )
        let rowHeights = measuredRowHeights(
            metrics: metrics,
            subviews: subviews
        )
        let totalHeight = rowHeights.reduce(0, +)
            + CGFloat(max(rowHeights.count - 1, 0)) * metrics.gap

        return CGSize(
            width: proposal.width ?? containerWidth,
            height: proposal.height ?? totalHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard !subviews.isEmpty else { return }

        let metrics = UPGridLayoutMetrics(
            containerWidth: bounds.width,
            columns: columns,
            gap: gap,
            itemCount: subviews.count
        )
        let rowHeights = measuredRowHeights(metrics: metrics, subviews: subviews)
        var y = bounds.minY

        for row in 0..<metrics.rowCount {
            let start = row * metrics.columns
            let end = min(start + metrics.columns, subviews.count)
            let rowItemCount = end - start
            let rowHeight = rowHeights[row]
            let rowOffset: CGFloat = rowItemCount < metrics.columns
                ? metrics.lastRowLeadingOffset(for: alignment)
                : 0

            for index in start..<end {
                let column = index - start
                let x = bounds.minX
                    + rowOffset
                    + CGFloat(column) * (metrics.itemWidth + metrics.gap)
                    + metrics.itemWidth / 2
                let center = CGPoint(x: x, y: y + rowHeight / 2)
                subviews[index].place(
                    at: center,
                    anchor: .center,
                    proposal: ProposedViewSize(
                        width: metrics.itemWidth,
                        height: rowHeight
                    )
                )
            }

            y += rowHeight + metrics.gap
        }
    }

    private func resolvedContainerWidth(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> CGFloat {
        if let width = proposal.width {
            return max(width, 0)
        }

        let intrinsicItemWidth = subviews.map {
            max($0.sizeThatFits(.unspecified).width, 0)
        }.max() ?? 0
        let safeColumns = max(columns, 1)
        return intrinsicItemWidth * CGFloat(safeColumns)
            + gap * CGFloat(max(safeColumns - 1, 0))
    }

    private func measuredRowHeights(
        metrics: UPGridLayoutMetrics,
        subviews: Subviews
    ) -> [CGFloat] {
        guard !subviews.isEmpty else { return [] }

        return (0..<metrics.rowCount).map { row in
            let start = row * metrics.columns
            let end = min(start + metrics.columns, subviews.count)
            return (start..<end).map { index in
                max(
                    subviews[index].sizeThatFits(
                        ProposedViewSize(width: metrics.itemWidth, height: nil)
                    ).height,
                    0
                )
            }.max() ?? 0
        }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-grid`.
public struct UPGrid<Content: View>: View {
    public let col: String
    public let border: Bool
    public let align: String
    public let gap: String

    var onClickHandler: ((UPGridName?) -> Void)?
    private let content: Content

    public init<Col: UPGridUnitValue, Gap: UPGridUnitValue>(
        col: Col = UPConfig.grid.col,
        border: Bool = UPConfig.grid.border,
        align: String = UPConfig.grid.align,
        gap: Gap = UPConfig.grid.gap,
        onClick: ((UPGridName?) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.col = col.upCheckboxUnitValue
        self.border = border
        self.align = align
        self.gap = gap.upCheckboxUnitValue
        self.onClickHandler = onClick
        self.content = content()
    }

    public var body: some View {
        UPGridLayout(
            columns: resolvedColumnCount,
            gap: resolvedGap,
            alignment: resolvedAlignment
        ) {
            content
        }
        .environment(\.upGridClickContext, UPGridClickContext(action: onClickHandler))
        .environment(\.upGridBorder, border)
        .environment(\.upGridBorderColor, UPTheme.default.border)
        .frame(maxWidth: .infinity, alignment: resolvedAlignment.swiftUIAlignment)
    }

    /// Number of columns after applying uview-plus's string/number fallback.
    public var resolvedColumnCount: Int {
        Self.normalizedColumnCount(col)
    }

    /// Gap converted from px/rpx/string-number syntax to points.
    public var resolvedGap: CGFloat {
        Self.parseLength(gap)
    }

    /// Native alignment after applying the upstream fallback to `left`.
    public var resolvedAlignment: UPGridAlignment {
        Self.normalizedAlignment(align)
    }

    /// Triggers the parent-level click callback without synthesizing an item
    /// callback. This is useful for adapters that receive a native event.
    func triggerClick(name: UPGridName? = nil) {
        onClickHandler?(name)
    }
}

public extension UPGrid where Content == EmptyView {
    init<Col: UPGridUnitValue, Gap: UPGridUnitValue>(
        col: Col = UPConfig.grid.col,
        border: Bool = UPConfig.grid.border,
        align: String = UPConfig.grid.align,
        gap: Gap = UPConfig.grid.gap,
        onClick: ((UPGridName?) -> Void)? = nil
    ) {
        self.init(
            col: col,
            border: border,
            align: align,
            gap: gap,
            onClick: onClick
        ) {
            EmptyView()
        }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-grid-item`.
public struct UPGridItem<Content: View>: View {
    public let name: UPGridName?
    public let bgColor: String

    var onClickHandler: ((UPGridName?) -> Void)?
    private let content: Content
    @Environment(\.upGridClickContext) private var gridClickContext
    @Environment(\.upGridBorder) private var gridBorder
    @Environment(\.upGridBorderColor) private var gridBorderColor
    @Environment(\.upTheme) private var theme

    public init<Name: UPGridNameValue>(
        name: Name = UPConfig.gridItem.name,
        bgColor: String = UPConfig.gridItem.bgColor,
        onClick: ((UPGridName?) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        let resolvedName = name.upCellNameValue
        self.name = resolvedName.description
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ? nil : resolvedName
        self.bgColor = bgColor
        self.onClickHandler = onClick
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(resolvedBackgroundColor)
            .overlay {
                Rectangle()
                    .stroke(
                        gridBorder ? gridBorderColor : .clear,
                        lineWidth: gridBorder ? 0.5 : 0
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UPGridEventContext.performClick(
                    name: name,
                    itemAction: onClickHandler,
                    gridAction: gridClickContext?.action
                )
            }
            .layoutValue(key: UPGridItemNameKey.self, value: name)
    }

    private var resolvedBackgroundColor: Color {
        let normalized = bgColor
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty, normalized != "transparent" else {
            return .clear
        }
        return UPColor.parse(bgColor, theme: theme)
    }
}

public extension UPGridItem where Content == EmptyView {
    init<Name: UPGridNameValue>(
        name: Name = UPConfig.gridItem.name,
        bgColor: String = UPConfig.gridItem.bgColor,
        onClick: ((UPGridName?) -> Void)? = nil
    ) {
        self.init(
            name: name,
            bgColor: bgColor,
            onClick: onClick
        ) {
            EmptyView()
        }
    }
}

public extension UPGrid {
    nonisolated static func normalizedColumnCount(_ value: String) -> Int {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let parsed: Double?
        if normalized.hasSuffix("rpx") {
            parsed = Double(normalized.dropLast(3))
        } else if normalized.hasSuffix("px") {
            parsed = Double(normalized.dropLast(2))
        } else {
            parsed = Double(normalized)
        }

        guard let parsed, parsed.isFinite, parsed > 0 else {
            return Int(UPGridConfig.col) ?? 3
        }
        return max(Int(parsed.rounded(.down)), 1)
    }

    nonisolated static func parseLength(_ value: String) -> CGFloat {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else { return 0 }

        if normalized.hasSuffix("rpx") {
            return max(CGFloat(Double(normalized.dropLast(3)) ?? 0), 0)
        }
        if normalized.hasSuffix("px") {
            return max(CGFloat(Double(normalized.dropLast(2)) ?? 0), 0)
        }
        return max(CGFloat(Double(normalized) ?? 0), 0)
    }

    nonisolated static func normalizedAlignment(_ value: String) -> UPGridAlignment {
        switch value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        {
        case "center": return .center
        case "right", "trailing": return .trailing
        default: return .leading
        }
    }

    func onClick(_ action: @escaping (UPGridName?) -> Void) -> UPGrid {
        var copy = self
        copy.onClickHandler = action
        return copy
    }
}

public extension UPGridItem {
    func onClick(_ action: @escaping (UPGridName?) -> Void) -> UPGridItem {
        var copy = self
        copy.onClickHandler = action
        return copy
    }
}

private struct UPGridItemNameKey: LayoutValueKey {
    static let defaultValue: UPGridName? = nil
}
