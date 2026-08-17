import SwiftUI

/// String-or-number value accepted by the uview-plus `u-row.gutter` prop.
public typealias UPRowUnitValue = UPCheckboxUnitValue

/// Internal layout metadata published by a direct `UPCol` child.
struct UPColLayoutValue: Equatable {
    var span: CGFloat = 12
    var offset: CGFloat = 0
}

struct UPColLayoutValueKey: LayoutValueKey {
    static let defaultValue = UPColLayoutValue()
}

private struct UPRowGutterKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private struct UPRowEventContextKey: EnvironmentKey {
    static let defaultValue = UPRowEventContext()
}

extension EnvironmentValues {
    var upRowGutter: CGFloat {
        get { self[UPRowGutterKey.self] }
        set { self[UPRowGutterKey.self] = newValue }
    }

    var upRowEventContext: UPRowEventContext {
        get { self[UPRowEventContextKey.self] }
        set { self[UPRowEventContextKey.self] = newValue }
    }
}

/// Coordinates the two SwiftUI gesture layers used by `UPRow` and `UPCol`.
///
/// uview-plus emits a column click and stops it from bubbling to its row. The
/// native implementation uses a high-priority column gesture plus this small
/// dispatcher so the same rule also remains directly testable.
@MainActor
final class UPRowEventContext {
    private var suppressNextRowClick = false

    func handleColumnClick(_ action: (() -> Void)?) {
        suppressNextRowClick = true
        action?()
    }

    func handleRowClick(_ action: (() -> Void)?) {
        if suppressNextRowClick {
            suppressNextRowClick = false
            return
        }
        action?()
    }
}

/// Metrics for one twelve-column grid item.
struct UPGridItemMetrics: Equatable {
    let spanWidth: CGFloat
    let offsetWidth: CGFloat
    let contentWidth: CGFloat
    let leadingPadding: CGFloat
    let trailingPadding: CGFloat

    init(containerWidth: CGFloat, span: CGFloat, offset: CGFloat, gutter: CGFloat) {
        let safeContainerWidth = max(containerWidth, 0)
        let safeSpan = max(span, 0)
        let safeOffset = max(offset, 0)
        let safeGutter = max(gutter, 0)
        spanWidth = safeContainerWidth * safeSpan / 12
        offsetWidth = safeContainerWidth * safeOffset / 12
        leadingPadding = safeGutter / 2
        trailingPadding = safeGutter / 2
        contentWidth = max(spanWidth - safeGutter, 0)
    }
}

/// Maps uview-plus's string flex aliases to native layout values.
enum UPFlexValue {
    static func justify(_ raw: String) -> String {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "start", "flex-start": return "flex-start"
        case "end", "flex-end": return "flex-end"
        case "center": return "center"
        case "around", "space-around": return "space-around"
        case "between", "space-between": return "space-between"
        default: return "flex-start"
        }
    }

    static func align(_ raw: String, allowsStretch: Bool) -> String {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "top", "flex-start": return "flex-start"
        case "bottom", "flex-end": return "flex-end"
        case "center": return "center"
        case "stretch" where allowsStretch: return "stretch"
        default: return allowsStretch ? "stretch" : "center"
        }
    }
}

/// Twelve-column custom layout used by `UPRow`.
struct UPRowLayout: Layout {
    let gutter: CGFloat
    let justify: String
    let align: String

    private struct MeasuredItem {
        let metrics: UPGridItemMetrics
        let size: CGSize
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let proposedWidth = proposal.width
        let fallbackWidth = subviews.reduce(CGFloat.zero) { partial, subview in
            partial + max(subview.sizeThatFits(.unspecified).width, 0)
        }
        let containerWidth = max(proposedWidth ?? fallbackWidth, 0)
        let measuredItems = measureItems(containerWidth: containerWidth, proposal: proposal, subviews: subviews)
        let measuredHeight = measuredItems.map(\.size.height).max() ?? 0
        let height = proposal.height ?? measuredHeight
        return CGSize(width: proposedWidth ?? fallbackWidth, height: max(height, 0))
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let measuredItems = measureItems(containerWidth: bounds.width, proposal: proposal, subviews: subviews)
        guard !measuredItems.isEmpty else { return }

        let occupiedWidth = measuredItems.reduce(CGFloat.zero) {
            $0 + $1.metrics.offsetWidth + $1.metrics.spanWidth
        }
        let remainingWidth = bounds.width - occupiedWidth
        let (leadingSpace, betweenSpace) = distribution(
            remainingWidth: remainingWidth,
            itemCount: measuredItems.count
        )
        let resolvedAlign = UPFlexValue.align(align, allowsStretch: false)
        var cursor = bounds.minX + leadingSpace

        for (index, item) in measuredItems.enumerated() {
            cursor += item.metrics.offsetWidth
            let centerX = cursor + item.metrics.spanWidth / 2
            let childHeight: CGFloat
            if resolvedAlign == "stretch" {
                childHeight = bounds.height
            } else {
                childHeight = item.size.height
            }
            let centerY: CGFloat
            switch resolvedAlign {
            case "flex-start":
                centerY = bounds.minY + childHeight / 2
            case "flex-end":
                centerY = bounds.maxY - childHeight / 2
            default:
                centerY = bounds.midY
            }

            subviews[index].place(
                at: CGPoint(x: centerX, y: centerY),
                anchor: .center,
                proposal: ProposedViewSize(width: item.metrics.spanWidth, height: childHeight)
            )
            cursor += item.metrics.spanWidth
            if index < measuredItems.count - 1 {
                cursor += betweenSpace
            }
        }
    }

    private func measureItems(
        containerWidth: CGFloat,
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> [MeasuredItem] {
        subviews.map { subview in
            let value = subview[UPColLayoutValueKey.self]
            let metrics = UPGridItemMetrics(
                containerWidth: containerWidth,
                span: value.span,
                offset: value.offset,
                gutter: gutter
            )
            let size = subview.sizeThatFits(
                ProposedViewSize(
                    width: metrics.spanWidth,
                    height: proposal.height
                )
            )
            return MeasuredItem(metrics: metrics, size: size)
        }
    }

    private func distribution(remainingWidth: CGFloat, itemCount: Int) -> (CGFloat, CGFloat) {
        guard itemCount > 0 else { return (0, 0) }
        switch UPFlexValue.justify(justify) {
        case "flex-end": return (remainingWidth, 0)
        case "center": return (remainingWidth / 2, 0)
        case "space-between":
            return (0, itemCount > 1 ? remainingWidth / CGFloat(itemCount - 1) : 0)
        case "space-around":
            let space = remainingWidth / CGFloat(itemCount)
            return (space / 2, space)
        default:
            return (0, 0)
        }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-row`.
public struct UPRow<Content: View>: View {
    var gutter: String
    var justify: String
    var align: String
    var customClass: String
    var customStyle: UPStyle
    var onTap: (() -> Void)?
    var onClick: (() -> Void)?
    private let content: Content
    private let eventContext: UPRowEventContext

    public init< Gutter: UPRowUnitValue >(
        gutter: Gutter = UPConfig.row.gutter,
        justify: String = UPConfig.row.justify,
        align: String = UPConfig.row.align,
        customClass: String = UPConfig.row.customClass,
        customStyle: UPStyle = UPConfig.row.customStyle,
        onTap: (() -> Void)? = nil,
        onClick: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.gutter = gutter.upCheckboxUnitValue
        self.justify = justify
        self.align = align
        self.customClass = customClass
        self.customStyle = customStyle
        self.onTap = onTap
        self.onClick = onClick
        self.content = content()
        self.eventContext = UPRowEventContext()
    }

    public var body: some View {
        UPRowLayout(
            gutter: resolvedGutter,
            justify: resolvedJustify,
            align: resolvedAlign
        ) {
            content
        }
        .environment(\.upRowGutter, resolvedGutter)
        .environment(\.upRowEventContext, eventContext)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, resolvedHorizontalMargin)
        .contentShape(Rectangle())
        .onTapGesture {
            eventContext.handleRowClick {
                onTap?()
                onClick?()
            }
        }
        .upStyle(customStyle)
    }

    var resolvedGutter: CGFloat {
        max(UPUnit.parse(gutter), 0)
    }

    var resolvedJustify: String {
        UPFlexValue.justify(justify)
    }

    var resolvedAlign: String {
        UPFlexValue.align(align, allowsStretch: false)
    }

    var resolvedHorizontalMargin: CGFloat {
        -resolvedGutter / 2
    }

    /// Executes the native equivalent of the row `click` event.
    func triggerClick() {
        eventContext.handleRowClick {
            onTap?()
            onClick?()
        }
    }
}

public extension UPRow where Content == EmptyView {
    init< Gutter: UPRowUnitValue >(
        gutter: Gutter = UPConfig.row.gutter,
        justify: String = UPConfig.row.justify,
        align: String = UPConfig.row.align,
        customClass: String = UPConfig.row.customClass,
        customStyle: UPStyle = UPConfig.row.customStyle,
        onTap: (() -> Void)? = nil,
        onClick: (() -> Void)? = nil
    ) {
        self.init(
            gutter: gutter,
            justify: justify,
            align: align,
            customClass: customClass,
            customStyle: customStyle,
            onTap: onTap,
            onClick: onClick
        ) {
            EmptyView()
        }
    }

    func onTap(_ action: @escaping () -> Void) -> UPRow {
        var copy = self
        copy.onTap = action
        return copy
    }

    func onClick(_ action: @escaping () -> Void) -> UPRow {
        var copy = self
        copy.onClick = action
        return copy
    }
}

public extension UPRow {
    func onTap(_ action: @escaping () -> Void) -> UPRow {
        var copy = self
        copy.onTap = action
        return copy
    }

    func onClick(_ action: @escaping () -> Void) -> UPRow {
        var copy = self
        copy.onClick = action
        return copy
    }
}
