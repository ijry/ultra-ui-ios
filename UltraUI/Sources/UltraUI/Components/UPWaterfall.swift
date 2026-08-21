import SwiftUI

/// A shortest-column layout corresponding to uview-plus `u-waterfall`.
public struct UPWaterfall<Content: View>: View {
    public var columnCount: Int
    public var columnGap: CGFloat
    public var rowGap: CGFloat
    private let content: Content

    public init(
        columnCount: Int = 2,
        columnGap: CGFloat = 10,
        rowGap: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.columnCount = max(columnCount, 1)
        self.columnGap = max(columnGap, 0)
        self.rowGap = max(rowGap ?? columnGap, 0)
        self.content = content()
    }

    public var body: some View {
        UPWaterfallLayout(
            columnCount: columnCount,
            columnGap: columnGap,
            rowGap: rowGap
        ) {
            content
        }
    }

    public func columnAssignments(heights: [CGFloat]) -> [Int] {
        var totals = Array(repeating: CGFloat.zero, count: columnCount)
        return heights.map { height in
            let column = shortestColumn(in: totals)
            if totals[column] > 0 { totals[column] += rowGap }
            totals[column] += max(height, 0)
            return column
        }
    }

    public func columnHeights(heights: [CGFloat]) -> [CGFloat] {
        var totals = Array(repeating: CGFloat.zero, count: columnCount)
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
}

public extension UPWaterfall where Content == EmptyView {
    init(columnCount: Int = 2, columnGap: CGFloat = 10, rowGap: CGFloat? = nil) {
        self.init(
            columnCount: columnCount,
            columnGap: columnGap,
            rowGap: rowGap,
            content: EmptyView.init
        )
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
