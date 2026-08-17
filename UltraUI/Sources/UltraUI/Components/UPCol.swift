import SwiftUI

/// String-or-number values accepted by the uview-plus `u-col.span` and
/// `u-col.offset` props.
public typealias UPColUnitValue = UPCheckboxUnitValue

/// Layout used for the default slot inside a column.
struct UPColContentLayout: Layout {
    let justify: String
    let align: String

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(proposal) }
        let width = proposal.width ?? sizes.reduce(0) { $0 + $1.width }
        let height = proposal.height ?? (sizes.map(\.height).max() ?? 0)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard !subviews.isEmpty else { return }
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: nil, height: bounds.height)) }
        let occupiedWidth = sizes.reduce(0) { $0 + $1.width }
        let remainingWidth = bounds.width - occupiedWidth
        let (leadingSpace, betweenSpace) = distribution(
            remainingWidth: remainingWidth,
            itemCount: subviews.count
        )
        let resolvedAlign = UPFlexValue.align(align, allowsStretch: true)
        var cursor = bounds.minX + leadingSpace

        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            let childHeight = resolvedAlign == "stretch" ? bounds.height : size.height
            let centerY: CGFloat
            switch resolvedAlign {
            case "flex-start": centerY = bounds.minY + childHeight / 2
            case "flex-end": centerY = bounds.maxY - childHeight / 2
            default: centerY = bounds.midY
            }
            subview.place(
                at: CGPoint(x: cursor + size.width / 2, y: centerY),
                anchor: .center,
                proposal: ProposedViewSize(width: size.width, height: childHeight)
            )
            cursor += size.width
            if index < subviews.count - 1 {
                cursor += betweenSpace
            }
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
        default: return (0, 0)
        }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-col`.
public struct UPCol<Content: View>: View {
    var span: String
    var offset: String
    var justify: String
    var align: String
    var textAlign: String
    var customClass: String
    var customStyle: UPStyle
    var onTap: (() -> Void)?
    var onClick: (() -> Void)?
    private let content: Content

    @Environment(\.upRowGutter) private var rowGutter
    @Environment(\.upRowEventContext) private var rowEventContext

    public init<Span: UPColUnitValue, Offset: UPColUnitValue>(
        span: Span = UPConfig.col.span,
        offset: Offset = UPConfig.col.offset,
        justify: String = UPConfig.col.justify,
        align: String = UPConfig.col.align,
        textAlign: String = UPConfig.col.textAlign,
        customClass: String = UPConfig.col.customClass,
        customStyle: UPStyle = UPConfig.col.customStyle,
        onTap: (() -> Void)? = nil,
        onClick: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.span = span.upCheckboxUnitValue
        self.offset = offset.upCheckboxUnitValue
        self.justify = justify
        self.align = align
        self.textAlign = textAlign
        self.customClass = customClass
        self.customStyle = customStyle
        self.onTap = onTap
        self.onClick = onClick
        self.content = content()
    }

    public var body: some View {
        UPColContentLayout(justify: resolvedJustify, align: resolvedAlign) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: contentAlignment)
        .multilineTextAlignment(resolvedTextAlignment.swiftUIValue)
        .padding(.horizontal, rowGutter / 2)
        .contentShape(Rectangle())
        .highPriorityGesture(
            TapGesture().onEnded {
                rowEventContext.handleColumnClick {
                    onTap?()
                    onClick?()
                }
            }
        )
        .upStyle(customStyle)
        .layoutValue(
            key: UPColLayoutValueKey.self,
            value: UPColLayoutValue(span: resolvedSpan, offset: resolvedOffset)
        )
    }

    var resolvedSpan: CGFloat {
        min(max(UPUnit.parse(span), 0), 12)
    }

    var resolvedOffset: CGFloat {
        min(max(UPUnit.parse(offset), 0), 12)
    }

    var resolvedJustify: String {
        UPFlexValue.justify(justify)
    }

    var resolvedAlign: String {
        UPFlexValue.align(align, allowsStretch: true)
    }

    var resolvedTextAlignment: UPTextAlignment {
        switch textAlign.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "center": return .center
        case "right", "end", "trailing": return .trailing
        default: return .leading
        }
    }

    var contentAlignment: Alignment {
        let horizontal: HorizontalAlignment
        switch resolvedJustify {
        case "flex-end": horizontal = .trailing
        case "center": horizontal = .center
        default: horizontal = .leading
        }
        switch resolvedAlign {
        case "flex-start": return Alignment(horizontal: horizontal, vertical: .top)
        case "flex-end": return Alignment(horizontal: horizontal, vertical: .bottom)
        default: return Alignment(horizontal: horizontal, vertical: .center)
        }
    }

    /// Executes the native equivalent of the column `click` event.
    func triggerClick() {
        rowEventContext.handleColumnClick {
            onTap?()
            onClick?()
        }
    }
}

public extension UPCol where Content == EmptyView {
    init<Span: UPColUnitValue, Offset: UPColUnitValue>(
        span: Span = UPConfig.col.span,
        offset: Offset = UPConfig.col.offset,
        justify: String = UPConfig.col.justify,
        align: String = UPConfig.col.align,
        textAlign: String = UPConfig.col.textAlign,
        customClass: String = UPConfig.col.customClass,
        customStyle: UPStyle = UPConfig.col.customStyle,
        onTap: (() -> Void)? = nil,
        onClick: (() -> Void)? = nil
    ) {
        self.init(
            span: span,
            offset: offset,
            justify: justify,
            align: align,
            textAlign: textAlign,
            customClass: customClass,
            customStyle: customStyle,
            onTap: onTap,
            onClick: onClick
        ) {
            EmptyView()
        }
    }

    func onTap(_ action: @escaping () -> Void) -> UPCol {
        var copy = self
        copy.onTap = action
        return copy
    }

    func onClick(_ action: @escaping () -> Void) -> UPCol {
        var copy = self
        copy.onClick = action
        return copy
    }
}

public extension UPCol {
    func onTap(_ action: @escaping () -> Void) -> UPCol {
        var copy = self
        copy.onTap = action
        return copy
    }

    func onClick(_ action: @escaping () -> Void) -> UPCol {
        var copy = self
        copy.onClick = action
        return copy
    }
}
