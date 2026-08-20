import SwiftUI

/// A string-or-number value accepted by the uview-plus `u-card` dimension
/// props. Values are stored as their original uview-compatible string form.
public protocol UPCardUnitValue {
    var upCardUnitValue: String { get }
}

extension String: UPCardUnitValue {
    public var upCardUnitValue: String { self }
}

extension Int: UPCardUnitValue {
    public var upCardUnitValue: String { String(self) }
}

extension Double: UPCardUnitValue {
    public var upCardUnitValue: String { Self.upCardFormatted(self) }
}

extension Float: UPCardUnitValue {
    public var upCardUnitValue: String { Double(self).upCardUnitValue }
}

extension CGFloat: UPCardUnitValue {
    public var upCardUnitValue: String { Double(self).upCardUnitValue }
}

private extension Double {
    static func upCardFormatted(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        return value.rounded() == value ? String(Int(value)) : String(value)
    }
}

/// Swift's typed analogue of uview-plus `u-card`'s `String | Number | Object`
/// `index` prop. JSON-like object values preserve the event payload without
/// exposing an untyped `Any` value to SwiftUI callers.
public indirect enum UPCardIndex: Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([UPCardIndex])
    case object([String: UPCardIndex])
    case null

    public init(_ value: String) {
        self = .string(value)
    }

    public init(_ value: Int) {
        self = .number(Double(value))
    }

    public init(_ value: Double) {
        self = .number(value)
    }
}

extension UPCardIndex: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension UPCardIndex: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension UPCardIndex: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension UPCardIndex: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension UPCardIndex: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: UPCardIndex...) {
        self = .array(elements)
    }
}

extension UPCardIndex: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, UPCardIndex)...) {
        var object: [String: UPCardIndex] = [:]
        for (key, value) in elements {
            object[key] = value
        }
        self = .object(object)
    }
}

extension UPCardIndex: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

/// Native SwiftUI counterpart of uview-plus `u-card`.
///
/// The public props, camel-case names, defaults, named `head` / `body` /
/// `foot` slots, and `click` / `head-click` / `body-click` / `foot-click`
/// events follow the checked-in uview-plus implementation. SwiftUI's trailing
/// `body` builder is an ergonomic equivalent of uview-plus's named `body`
/// slot; there is intentionally no synthetic default Vue slot.
///
/// CSS `boxShadow` syntax cannot be represented losslessly by SwiftUI. The
/// raw prop is retained and non-`none` values receive a conservative native
/// shadow approximation.
public struct UPCard: View {
    var full: Bool
    var title: String
    var titleColor: String
    var titleSize: String
    var subTitle: String
    var subTitleColor: String
    var subTitleSize: String
    var border: Bool
    var index: UPCardIndex
    var margin: String
    var borderRadius: String
    var headStyle: UPStyle
    var bodyStyle: UPStyle
    var footStyle: UPStyle
    var headBorderBottom: Bool
    var footBorderTop: Bool
    var thumb: String
    var thumbWidth: String
    var thumbCircle: Bool
    var padding: String
    var paddingHead: String
    var paddingBody: String
    var paddingFoot: String
    var showHead: Bool
    var showFoot: Bool
    var boxShadow: String
    var onClickHandler: ((UPCardIndex) -> Void)?
    var onHeadClickHandler: ((UPCardIndex) -> Void)?
    var onBodyClickHandler: ((UPCardIndex) -> Void)?
    var onFootClickHandler: ((UPCardIndex) -> Void)?

    private var headContent: AnyView
    private var bodyContent: AnyView
    private var footContent: AnyView
    var hasHeadSlot: Bool
    var hasFootSlot: Bool

    @Environment(\.upTheme) private var theme

    /// Creates a card with empty named slots, matching an empty `<u-card />`.
    public init(
        full: Bool = UPConfig.card.full,
        title: String = UPConfig.card.title,
        titleColor: String = UPConfig.card.titleColor,
        titleSize: some UPCardUnitValue = UPConfig.card.titleSize,
        subTitle: String = UPConfig.card.subTitle,
        subTitleColor: String = UPConfig.card.subTitleColor,
        subTitleSize: some UPCardUnitValue = UPConfig.card.subTitleSize,
        border: Bool = UPConfig.card.border,
        index: UPCardIndex = UPConfig.card.index,
        margin: String = UPConfig.card.margin,
        borderRadius: some UPCardUnitValue = UPConfig.card.borderRadius,
        headStyle: UPStyle = UPConfig.card.headStyle,
        bodyStyle: UPStyle = UPConfig.card.bodyStyle,
        footStyle: UPStyle = UPConfig.card.footStyle,
        headBorderBottom: Bool = UPConfig.card.headBorderBottom,
        footBorderTop: Bool = UPConfig.card.footBorderTop,
        thumb: String = UPConfig.card.thumb,
        thumbWidth: some UPCardUnitValue = UPConfig.card.thumbWidth,
        thumbCircle: Bool = UPConfig.card.thumbCircle,
        padding: some UPCardUnitValue = UPConfig.card.padding,
        paddingHead: some UPCardUnitValue = UPConfig.card.paddingHead,
        paddingBody: some UPCardUnitValue = UPConfig.card.paddingBody,
        paddingFoot: some UPCardUnitValue = UPConfig.card.paddingFoot,
        showHead: Bool = UPConfig.card.showHead,
        showFoot: Bool = UPConfig.card.showFoot,
        boxShadow: String = UPConfig.card.boxShadow,
        onClick: ((UPCardIndex) -> Void)? = nil,
        onHeadClick: ((UPCardIndex) -> Void)? = nil,
        onBodyClick: ((UPCardIndex) -> Void)? = nil,
        onFootClick: ((UPCardIndex) -> Void)? = nil
    ) {
        self.init(
            full: full,
            title: title,
            titleColor: titleColor,
            titleSize: titleSize.upCardUnitValue,
            subTitle: subTitle,
            subTitleColor: subTitleColor,
            subTitleSize: subTitleSize.upCardUnitValue,
            border: border,
            index: index,
            margin: margin,
            borderRadius: borderRadius.upCardUnitValue,
            headStyle: headStyle,
            bodyStyle: bodyStyle,
            footStyle: footStyle,
            headBorderBottom: headBorderBottom,
            footBorderTop: footBorderTop,
            thumb: thumb,
            thumbWidth: thumbWidth.upCardUnitValue,
            thumbCircle: thumbCircle,
            padding: padding.upCardUnitValue,
            paddingHead: paddingHead.upCardUnitValue,
            paddingBody: paddingBody.upCardUnitValue,
            paddingFoot: paddingFoot.upCardUnitValue,
            showHead: showHead,
            showFoot: showFoot,
            boxShadow: boxShadow,
            onClick: onClick,
            onHeadClick: onHeadClick,
            onBodyClick: onBodyClick,
            onFootClick: onFootClick,
            headContent: AnyView(EmptyView()),
            bodyContent: AnyView(EmptyView()),
            footContent: AnyView(EmptyView()),
            hasHeadSlot: false,
            hasFootSlot: false
        )
    }

    /// Creates a card whose trailing builder maps to uview-plus's named
    /// `body` slot.
    public init<BodyContent: View>(
        full: Bool = UPConfig.card.full,
        title: String = UPConfig.card.title,
        titleColor: String = UPConfig.card.titleColor,
        titleSize: some UPCardUnitValue = UPConfig.card.titleSize,
        subTitle: String = UPConfig.card.subTitle,
        subTitleColor: String = UPConfig.card.subTitleColor,
        subTitleSize: some UPCardUnitValue = UPConfig.card.subTitleSize,
        border: Bool = UPConfig.card.border,
        index: UPCardIndex = UPConfig.card.index,
        margin: String = UPConfig.card.margin,
        borderRadius: some UPCardUnitValue = UPConfig.card.borderRadius,
        headStyle: UPStyle = UPConfig.card.headStyle,
        bodyStyle: UPStyle = UPConfig.card.bodyStyle,
        footStyle: UPStyle = UPConfig.card.footStyle,
        headBorderBottom: Bool = UPConfig.card.headBorderBottom,
        footBorderTop: Bool = UPConfig.card.footBorderTop,
        thumb: String = UPConfig.card.thumb,
        thumbWidth: some UPCardUnitValue = UPConfig.card.thumbWidth,
        thumbCircle: Bool = UPConfig.card.thumbCircle,
        padding: some UPCardUnitValue = UPConfig.card.padding,
        paddingHead: some UPCardUnitValue = UPConfig.card.paddingHead,
        paddingBody: some UPCardUnitValue = UPConfig.card.paddingBody,
        paddingFoot: some UPCardUnitValue = UPConfig.card.paddingFoot,
        showHead: Bool = UPConfig.card.showHead,
        showFoot: Bool = UPConfig.card.showFoot,
        boxShadow: String = UPConfig.card.boxShadow,
        onClick: ((UPCardIndex) -> Void)? = nil,
        onHeadClick: ((UPCardIndex) -> Void)? = nil,
        onBodyClick: ((UPCardIndex) -> Void)? = nil,
        onFootClick: ((UPCardIndex) -> Void)? = nil,
        @ViewBuilder body: () -> BodyContent
    ) {
        self.init(
            full: full,
            title: title,
            titleColor: titleColor,
            titleSize: titleSize.upCardUnitValue,
            subTitle: subTitle,
            subTitleColor: subTitleColor,
            subTitleSize: subTitleSize.upCardUnitValue,
            border: border,
            index: index,
            margin: margin,
            borderRadius: borderRadius.upCardUnitValue,
            headStyle: headStyle,
            bodyStyle: bodyStyle,
            footStyle: footStyle,
            headBorderBottom: headBorderBottom,
            footBorderTop: footBorderTop,
            thumb: thumb,
            thumbWidth: thumbWidth.upCardUnitValue,
            thumbCircle: thumbCircle,
            padding: padding.upCardUnitValue,
            paddingHead: paddingHead.upCardUnitValue,
            paddingBody: paddingBody.upCardUnitValue,
            paddingFoot: paddingFoot.upCardUnitValue,
            showHead: showHead,
            showFoot: showFoot,
            boxShadow: boxShadow,
            onClick: onClick,
            onHeadClick: onHeadClick,
            onBodyClick: onBodyClick,
            onFootClick: onFootClick,
            headContent: AnyView(EmptyView()),
            bodyContent: AnyView(body()),
            footContent: AnyView(EmptyView()),
            hasHeadSlot: false,
            hasFootSlot: false
        )
    }

    /// Creates a card with SwiftUI counterparts of the three named slots from
    /// uview-plus: `head`, `body`, and `foot`.
    public init<HeadContent: View, BodyContent: View, FootContent: View>(
        full: Bool = UPConfig.card.full,
        title: String = UPConfig.card.title,
        titleColor: String = UPConfig.card.titleColor,
        titleSize: some UPCardUnitValue = UPConfig.card.titleSize,
        subTitle: String = UPConfig.card.subTitle,
        subTitleColor: String = UPConfig.card.subTitleColor,
        subTitleSize: some UPCardUnitValue = UPConfig.card.subTitleSize,
        border: Bool = UPConfig.card.border,
        index: UPCardIndex = UPConfig.card.index,
        margin: String = UPConfig.card.margin,
        borderRadius: some UPCardUnitValue = UPConfig.card.borderRadius,
        headStyle: UPStyle = UPConfig.card.headStyle,
        bodyStyle: UPStyle = UPConfig.card.bodyStyle,
        footStyle: UPStyle = UPConfig.card.footStyle,
        headBorderBottom: Bool = UPConfig.card.headBorderBottom,
        footBorderTop: Bool = UPConfig.card.footBorderTop,
        thumb: String = UPConfig.card.thumb,
        thumbWidth: some UPCardUnitValue = UPConfig.card.thumbWidth,
        thumbCircle: Bool = UPConfig.card.thumbCircle,
        padding: some UPCardUnitValue = UPConfig.card.padding,
        paddingHead: some UPCardUnitValue = UPConfig.card.paddingHead,
        paddingBody: some UPCardUnitValue = UPConfig.card.paddingBody,
        paddingFoot: some UPCardUnitValue = UPConfig.card.paddingFoot,
        showHead: Bool = UPConfig.card.showHead,
        showFoot: Bool = UPConfig.card.showFoot,
        boxShadow: String = UPConfig.card.boxShadow,
        onClick: ((UPCardIndex) -> Void)? = nil,
        onHeadClick: ((UPCardIndex) -> Void)? = nil,
        onBodyClick: ((UPCardIndex) -> Void)? = nil,
        onFootClick: ((UPCardIndex) -> Void)? = nil,
        @ViewBuilder head: () -> HeadContent,
        @ViewBuilder body: () -> BodyContent,
        @ViewBuilder foot: () -> FootContent
    ) {
        self.init(
            full: full,
            title: title,
            titleColor: titleColor,
            titleSize: titleSize.upCardUnitValue,
            subTitle: subTitle,
            subTitleColor: subTitleColor,
            subTitleSize: subTitleSize.upCardUnitValue,
            border: border,
            index: index,
            margin: margin,
            borderRadius: borderRadius.upCardUnitValue,
            headStyle: headStyle,
            bodyStyle: bodyStyle,
            footStyle: footStyle,
            headBorderBottom: headBorderBottom,
            footBorderTop: footBorderTop,
            thumb: thumb,
            thumbWidth: thumbWidth.upCardUnitValue,
            thumbCircle: thumbCircle,
            padding: padding.upCardUnitValue,
            paddingHead: paddingHead.upCardUnitValue,
            paddingBody: paddingBody.upCardUnitValue,
            paddingFoot: paddingFoot.upCardUnitValue,
            showHead: showHead,
            showFoot: showFoot,
            boxShadow: boxShadow,
            onClick: onClick,
            onHeadClick: onHeadClick,
            onBodyClick: onBodyClick,
            onFootClick: onFootClick,
            headContent: AnyView(head()),
            bodyContent: AnyView(body()),
            footContent: AnyView(foot()),
            hasHeadSlot: true,
            hasFootSlot: true
        )
    }

    var resolvedTitleSize: CGFloat { UPUnit.parse(titleSize) }
    var resolvedSubTitleSize: CGFloat { UPUnit.parse(subTitleSize) }
    var resolvedBorderRadius: CGFloat { max(UPUnit.parse(borderRadius), 0) }
    var resolvedThumbWidth: CGFloat { max(UPUnit.parse(thumbWidth), 0) }
    var resolvedThumbCornerRadius: CGFloat { thumbCircle ? 50 : 4 }
    var resolvedHeadPadding: UPInsets { Self.insets(for: paddingHead.isEmpty ? padding : paddingHead) }
    var resolvedBodyPadding: UPInsets { Self.insets(for: paddingBody.isEmpty ? padding : paddingBody) }
    var resolvedFootPadding: UPInsets {
        hasFootSlot ? Self.insets(for: paddingFoot.isEmpty ? padding : paddingFoot) : .zero
    }
    var resolvedMargin: UPInsets {
        var result = Self.insets(for: margin)
        if full {
            result.leading = 0
            result.trailing = 0
        }
        return result
    }
    var hasDefaultHead: Bool { showHead && !hasHeadSlot }
    var showsOuterBorder: Bool { border && !full }

    public func onClick(_ action: @escaping (UPCardIndex) -> Void) -> UPCard {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    public func onHeadClick(_ action: @escaping (UPCardIndex) -> Void) -> UPCard {
        var copy = self
        copy.onHeadClickHandler = action
        return copy
    }

    public func onBodyClick(_ action: @escaping (UPCardIndex) -> Void) -> UPCard {
        var copy = self
        copy.onBodyClickHandler = action
        return copy
    }

    public func onFootClick(_ action: @escaping (UPCardIndex) -> Void) -> UPCard {
        var copy = self
        copy.onFootClickHandler = action
        return copy
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerSection
            bodySection
            footerSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: resolvedBorderRadius, style: .continuous))
        .overlay {
            if showsOuterBorder {
                RoundedRectangle(cornerRadius: resolvedBorderRadius, style: .continuous)
                    .stroke(theme.border, lineWidth: 1)
            }
        }
        .shadow(
            color: hasNativeShadow ? Color.black.opacity(0.12) : .clear,
            radius: hasNativeShadow ? 4 : 0,
            x: 0,
            y: hasNativeShadow ? 2 : 0
        )
        .padding(Self.edgeInsets(resolvedMargin))
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { onClickHandler?(index) })
    }

    @ViewBuilder
    private var headerSection: some View {
        if showHead {
            styledSection(padding: resolvedHeadPadding, style: headStyle) {
                if hasHeadSlot {
                    headContent
                } else {
                    defaultHeader
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { onHeadClickHandler?(index) })

            if headBorderBottom {
                separator
            }
        }
    }

    private var bodySection: some View {
        styledSection(padding: resolvedBodyPadding, style: bodyStyle) {
            bodyContent
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { onBodyClickHandler?(index) })
    }

    @ViewBuilder
    private var footerSection: some View {
        if showFoot {
            if footBorderTop {
                separator
            }

            styledSection(padding: resolvedFootPadding, style: footStyle) {
                footContent
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { onFootClickHandler?(index) })
        }
    }

    private var defaultHeader: some View {
        HStack(spacing: 6) {
            if !title.isEmpty {
                HStack(spacing: 8) {
                    if !thumb.isEmpty {
                        UPImage(
                            src: thumb,
                            mode: "aspectFill",
                            width: thumbWidth,
                            height: thumbWidth,
                            radius: thumbCircle ? "50px" : "4px"
                        )
                    }

                    Text(title)
                        .font(.system(size: max(resolvedTitleSize, 1)))
                        .foregroundStyle(UPColor.parse(titleColor, theme: theme))
                        .lineLimit(1)
                        .frame(maxWidth: 400, alignment: .leading)
                }
            }

            if !title.isEmpty && !subTitle.isEmpty {
                Spacer(minLength: 6)
            }

            if !subTitle.isEmpty {
                Text(subTitle)
                    .font(.system(size: max(resolvedSubTitleSize, 1)))
                    .foregroundStyle(UPColor.parse(subTitleColor, theme: theme))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var separator: some View {
        Rectangle()
            .fill(theme.border)
            .frame(height: 1)
    }

    private var hasNativeShadow: Bool {
        let normalized = boxShadow.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !normalized.isEmpty && normalized != "none"
    }

    private func styledSection<Content: View>(
        padding: UPInsets,
        style: UPStyle,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let effectivePadding = mergedPadding(base: padding, style: style)
        return ZStack(alignment: .leading) {
            // This baseline retains a padded uview `<view>` even when its
            // corresponding SwiftUI slot is empty.
            Color.clear.frame(height: 0)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(width: style.width, height: style.height, alignment: .leading)
        .padding(Self.edgeInsets(effectivePadding))
        .foregroundColor(style.foregroundColor.map { UPColor.parse($0, theme: theme) })
        .background {
            if let backgroundColor = style.backgroundColor {
                UPColor.parse(backgroundColor, theme: theme)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius ?? 0, style: .continuous))
        .opacity(style.opacity ?? 1)
        .padding(Self.edgeInsets(style.margin))
    }

    private func mergedPadding(base: UPInsets, style: UPStyle) -> UPInsets {
        var result = base
        if let shorthand = style.value(for: "padding"), !shorthand.isEmpty {
            result = Self.insets(for: shorthand)
        }
        if let top = style.length(for: "padding-top") { result.top = top }
        if let leading = style.length(for: "padding-left") { result.leading = leading }
        if let bottom = style.length(for: "padding-bottom") { result.bottom = bottom }
        if let trailing = style.length(for: "padding-right") { result.trailing = trailing }
        return result
    }

    private init(
        full: Bool,
        title: String,
        titleColor: String,
        titleSize: String,
        subTitle: String,
        subTitleColor: String,
        subTitleSize: String,
        border: Bool,
        index: UPCardIndex,
        margin: String,
        borderRadius: String,
        headStyle: UPStyle,
        bodyStyle: UPStyle,
        footStyle: UPStyle,
        headBorderBottom: Bool,
        footBorderTop: Bool,
        thumb: String,
        thumbWidth: String,
        thumbCircle: Bool,
        padding: String,
        paddingHead: String,
        paddingBody: String,
        paddingFoot: String,
        showHead: Bool,
        showFoot: Bool,
        boxShadow: String,
        onClick: ((UPCardIndex) -> Void)?,
        onHeadClick: ((UPCardIndex) -> Void)?,
        onBodyClick: ((UPCardIndex) -> Void)?,
        onFootClick: ((UPCardIndex) -> Void)?,
        headContent: AnyView,
        bodyContent: AnyView,
        footContent: AnyView,
        hasHeadSlot: Bool,
        hasFootSlot: Bool
    ) {
        self.full = full
        self.title = title
        self.titleColor = titleColor
        self.titleSize = titleSize
        self.subTitle = subTitle
        self.subTitleColor = subTitleColor
        self.subTitleSize = subTitleSize
        self.border = border
        self.index = index
        self.margin = margin
        self.borderRadius = borderRadius
        self.headStyle = headStyle
        self.bodyStyle = bodyStyle
        self.footStyle = footStyle
        self.headBorderBottom = headBorderBottom
        self.footBorderTop = footBorderTop
        self.thumb = thumb
        self.thumbWidth = thumbWidth
        self.thumbCircle = thumbCircle
        self.padding = padding
        self.paddingHead = paddingHead
        self.paddingBody = paddingBody
        self.paddingFoot = paddingFoot
        self.showHead = showHead
        self.showFoot = showFoot
        self.boxShadow = boxShadow
        self.onClickHandler = onClick
        self.onHeadClickHandler = onHeadClick
        self.onBodyClickHandler = onBodyClick
        self.onFootClickHandler = onFootClick
        self.headContent = headContent
        self.bodyContent = bodyContent
        self.footContent = footContent
        self.hasHeadSlot = hasHeadSlot
        self.hasFootSlot = hasFootSlot
    }

    private static func insets(for raw: String) -> UPInsets {
        UPStyle(["padding": raw]).padding
    }

    private static func edgeInsets(_ insets: UPInsets) -> EdgeInsets {
        EdgeInsets(
            top: insets.top,
            leading: insets.leading,
            bottom: insets.bottom,
            trailing: insets.trailing
        )
    }
}
