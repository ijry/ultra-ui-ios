import SwiftUI

/// Cross-platform glass options. iOS renders real Liquid Glass (iOS 26+) with a
/// Material fallback; the other platforms accept it as a no-op / approximation.
public struct UPFlexGlass: Sendable {
    public var enabled: Bool
    public var variant: String
    public var tint: String?
    public var interactive: Bool
    public var cornerRadius: Double?

    public init(
        enabled: Bool = false,
        variant: String = "regular",
        tint: String? = nil,
        interactive: Bool = false,
        cornerRadius: Double? = nil
    ) {
        self.enabled = enabled
        self.variant = variant
        self.tint = tint
        self.interactive = interactive
        self.cornerRadius = cornerRadius
    }
}

/// Single-line flex layout (wrap deferred), generalized from `UPRowLayout` to an
/// axis with intrinsic child sizing.
struct UPFlexLayout: Layout {
    let axis: Axis
    let reverse: Bool
    let justify: String
    let align: String
    let gap: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let totalGap = gap * CGFloat(max(subviews.count - 1, 0))
        if axis == .horizontal {
            let contentWidth = sizes.reduce(0) { $0 + $1.width } + totalGap
            let maxHeight = sizes.map(\.height).max() ?? 0
            return CGSize(width: proposal.width ?? contentWidth, height: proposal.height ?? maxHeight)
        } else {
            let contentHeight = sizes.reduce(0) { $0 + $1.height } + totalGap
            let maxWidth = sizes.map(\.width).max() ?? 0
            return CGSize(width: proposal.width ?? maxWidth, height: proposal.height ?? contentHeight)
        }
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let indices = Array(subviews.indices)
        let order: [Int] = reverse ? Array(subviews.indices.reversed()) : indices
        let mainTotal = indices.reduce(CGFloat.zero) { $0 + mainExtent(sizes[$1]) }
        let gapTotal = gap * CGFloat(max(order.count - 1, 0))
        let containerMain = axis == .horizontal ? bounds.width : bounds.height
        let remaining = max(containerMain - mainTotal - gapTotal, 0)
        let (leading, between) = distribution(remaining: remaining, count: order.count)
        var cursor = (axis == .horizontal ? bounds.minX : bounds.minY) + leading
        for (idx, i) in order.enumerated() {
            let size = sizes[i]
            let boundsCross = axis == .horizontal ? bounds.height : bounds.width
            let childCross = axis == .horizontal ? size.height : size.width
            let crossSize = align == "stretch" ? boundsCross : childCross
            let boundsCrossMin = axis == .horizontal ? bounds.minY : bounds.minX
            let crossPos = crossPosition(childCross: crossSize, boundsMin: boundsCrossMin, boundsExtent: boundsCross)
            if axis == .horizontal {
                subviews[i].place(at: CGPoint(x: cursor, y: crossPos), anchor: .topLeading, proposal: ProposedViewSize(width: size.width, height: crossSize))
                cursor += size.width
            } else {
                subviews[i].place(at: CGPoint(x: crossPos, y: cursor), anchor: .topLeading, proposal: ProposedViewSize(width: crossSize, height: size.height))
                cursor += size.height
            }
            if idx < order.count - 1 { cursor += gap + between }
        }
    }
    private func mainExtent(_ size: CGSize) -> CGFloat {
        axis == .horizontal ? size.width : size.height
    }

    private func crossPosition(childCross: CGFloat, boundsMin: CGFloat, boundsExtent: CGFloat) -> CGFloat {
        switch align {
        case "flex-end": return boundsMin + boundsExtent - childCross
        case "center": return boundsMin + (boundsExtent - childCross) / 2
        default: return boundsMin // flex-start, stretch (anchored at start), baseline (degraded)
        }
    }

    private func distribution(remaining: CGFloat, count: Int) -> (CGFloat, CGFloat) {
        guard count > 0 else { return (0, 0) }
        switch justify {
        case "flex-end": return (remaining, 0)
        case "center": return (remaining / 2, 0)
        case "space-between": return (0, count > 1 ? remaining / CGFloat(count - 1) : 0)
        case "space-around": let s = remaining / CGFloat(count); return (s / 2, s)
        case "space-evenly": let s = remaining / CGFloat(count + 1); return (s, s)
        default: return (0, 0) // flex-start
        }
    }
}
/// Native SwiftUI general flexbox container; distinct from the 12-col `UPRow`/`UPCol`.
public struct UPFlex<Content: View>: View {
    var direction: String
    var justify: String
    var align: String
    var wrap: Bool
    var gap: Double
    var glass: UPFlexGlass?
    var customStyle: UPStyle
    var onClick: (() -> Void)?
    private let content: Content

    public init(
        direction: String = "row",
        justify: String = "flex-start",
        align: String = "stretch",
        wrap: Bool = false,
        gap: Double = 0,
        glass: UPFlexGlass? = nil,
        customStyle: UPStyle = UPStyle(),
        onClick: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.direction = direction
        self.justify = justify
        self.align = align
        self.wrap = wrap
        self.gap = gap
        self.glass = glass
        self.customStyle = customStyle
        self.onClick = onClick
        self.content = content()
    }

    private var axis: Axis {
        (direction == "column" || direction == "column-reverse") ? .vertical : .horizontal
    }
    private var reverse: Bool {
        direction == "row-reverse" || direction == "column-reverse"
    }
    private var resolvedJustify: String {
        switch justify.lowercased() {
        case "flex-end", "end": return "flex-end"
        case "center": return "center"
        case "space-between", "between": return "space-between"
        case "space-around", "around": return "space-around"
        case "space-evenly": return "space-evenly"
        default: return "flex-start"
        }
    }
    private var resolvedAlign: String {
        switch align.lowercased() {
        case "flex-end", "end": return "flex-end"
        case "center": return "center"
        case "stretch": return "stretch"
        default: return "flex-start" // flex-start, baseline (degraded)
        }
    }
    public var body: some View {
        UPFlexLayout(
            axis: axis,
            reverse: reverse,
            justify: resolvedJustify,
            align: resolvedAlign,
            gap: max(UPUnit.parse(gap), 0)
        ) {
            content
        }
        .modifier(UPFlexGlassModifier(glass: glass))
        .contentShape(Rectangle())
        .onTapGesture { onClick?() }
        .upStyle(customStyle)
    }
}

/// Applies real Liquid Glass on iOS 26+, falling back to `.ultraThinMaterial`.
struct UPFlexGlassModifier: ViewModifier {
    let glass: UPFlexGlass?

    func body(content: Content) -> some View {
        guard let glass, glass.enabled else { return AnyView(content) }
        let shape = RoundedRectangle(cornerRadius: CGFloat(glass.cornerRadius ?? 0))
        if #available(iOS 26.0, *) {
            return AnyView(content.glassEffect(glassStyle(glass), in: shape))
        } else {
            let tintColor = glass.tint.map { UPColor.parse($0) } ?? Color.clear
            return AnyView(
                content
                    .background(.ultraThinMaterial, in: shape)
                    .overlay(shape.fill(tintColor.opacity(0.15)))
            )
        }
    }

    @available(iOS 26.0, *)
    private func glassStyle(_ g: UPFlexGlass) -> Glass {
        var style: Glass = (g.variant == "clear") ? .clear : .regular
        if let tint = g.tint { style = style.tint(UPColor.parse(tint)) }
        if g.interactive { style = style.interactive() }
        return style
    }
}
