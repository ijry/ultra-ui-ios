import SwiftUI

/// The parent-table style that `u-th` and `u-td` copy onto themselves in their
/// upstream `mounted` hooks. SwiftUI has no `$parent` lookup, so `UPTable`
/// publishes this through the environment instead.
public struct UPTableStyleContext: Equatable, Sendable {
    public var borderColor: String
    public var align: String
    public var padding: String
    public var fontSize: String
    public var color: String
    public var thStyle: UPStyle

    public init(borderColor: String = UPConfig.table.borderColor,
                align: String = UPConfig.table.align,
                padding: String = UPConfig.table.padding,
                fontSize: String = UPConfig.table.fontSize,
                color: String = UPConfig.table.color,
                thStyle: UPStyle = UPConfig.table.thStyle) {
        self.borderColor = borderColor
        self.align = align
        self.padding = padding
        self.fontSize = fontSize
        self.color = color
        self.thStyle = thStyle
    }

    /// Splits the upstream CSS `padding` shorthand into the two insets SwiftUI
    /// needs. One value applies to all sides; two are vertical then horizontal.
    /// An empty string falls back to the upstream default.
    public static func insets(_ padding: String) -> (vertical: CGFloat, horizontal: CGFloat) {
        let parts = padding
            .split(separator: " ", omittingEmptySubsequences: true)
            .map(String.init)

        switch parts.count {
        case 0:
            return insets(UPConfig.table.padding)
        case 1:
            let value = UPUnit.parse(parts[0])
            return (value, value)
        default:
            return (UPUnit.parse(parts[0]), UPUnit.parse(parts[1]))
        }
    }
}

/// The style a single cell resolved from its own props plus the parent table.
public struct UPTableCellStyle: Equatable, Sendable {
    public var align: String
    public var padding: String
    public var fontSize: CGFloat
    public var color: String
    public var borderColor: String
    /// `nil` when the column stretches, matching the absence of upstream's
    /// `flex: 0 0 <width>`.
    public var fixedWidth: CGFloat?

    public var insets: (vertical: CGFloat, horizontal: CGFloat) {
        UPTableStyleContext.insets(padding)
    }

    public var textAlignment: TextAlignment {
        switch align {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }

    public var frameAlignment: Alignment {
        switch align {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }
}

private struct UPTableStyleContextKey: EnvironmentKey {
    static let defaultValue: UPTableStyleContext? = nil
}

extension EnvironmentValues {
    var upTableStyleContext: UPTableStyleContext? {
        get { self[UPTableStyleContextKey.self] }
        set { self[UPTableStyleContextKey.self] = newValue }
    }
}

/// Legacy uview-plus table primitives. The four Vue components are kept as
/// separate SwiftUI views so existing markup can be translated one element at a
/// time, and the table publishes its style so cells inherit it the way the
/// upstream `mounted` hooks do.
@MainActor
public struct UPTable<Content: View>: View {
    public var borderColor: String
    public var align: String
    public var padding: String
    public var fontSize: String
    public var color: String
    public var thStyle: UPStyle
    public var bgColor: String
    private let content: Content

    @Environment(\.upTheme) private var theme

    public init(borderColor: String = UPConfig.table.borderColor,
                align: String = UPConfig.table.align,
                padding: String = UPConfig.table.padding,
                fontSize: String = UPConfig.table.fontSize,
                color: String = UPConfig.table.color,
                thStyle: UPStyle = UPConfig.table.thStyle,
                bgColor: String = UPConfig.table.bgColor,
                @ViewBuilder content: () -> Content) {
        self.borderColor = borderColor
        self.align = align
        self.padding = padding
        self.fontSize = fontSize
        self.color = color
        self.thStyle = thStyle
        self.bgColor = bgColor
        self.content = content()
    }

    /// The style handed down to `UPTh` and `UPTd`.
    public var styleContext: UPTableStyleContext {
        UPTableStyleContext(
            borderColor: borderColor,
            align: align,
            padding: padding,
            fontSize: fontSize,
            color: color,
            thStyle: thStyle
        )
    }

    public var body: some View {
        VStack(spacing: 0) { content }
            .background(UPColor.parse(bgColor, theme: theme))
            .overlay(
                Rectangle()
                    .stroke(UPColor.parse(borderColor, theme: theme), lineWidth: 1)
            )
            .environment(\.upTableStyleContext, styleContext)
    }
}

public extension UPTable where Content == EmptyView {
    init(borderColor: String = UPConfig.table.borderColor,
         align: String = UPConfig.table.align,
         padding: String = UPConfig.table.padding,
         fontSize: String = UPConfig.table.fontSize,
         color: String = UPConfig.table.color,
         thStyle: UPStyle = UPConfig.table.thStyle,
         bgColor: String = UPConfig.table.bgColor) {
        self.init(borderColor: borderColor, align: align, padding: padding,
                  fontSize: fontSize, color: color, thStyle: thStyle,
                  bgColor: bgColor, content: EmptyView.init)
    }
}

@MainActor
public struct UPTr<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        HStack(spacing: 0) { content }
    }
}

public extension UPTr where Content == EmptyView {
    init() { self.init(content: EmptyView.init) }
}

@MainActor
public struct UPTh<Content: View>: View {
    public var width: String
    public var thStyle: UPStyle
    private let content: Content

    @Environment(\.upTableStyleContext) private var parent
    @Environment(\.upTheme) private var theme

    public init(width: String = UPConfig.table.thWidth,
                thStyle: UPStyle = UPConfig.table.thStyle,
                @ViewBuilder content: () -> Content) {
        self.width = width
        self.thStyle = thStyle
        self.content = content()
    }

    /// Mirrors the upstream `u-th` mounted hook: inherit the parent table's
    /// align, padding and border colour, and pin the column when `width` is set.
    public static func resolvedStyle(width: String,
                                     parent: UPTableStyleContext?) -> UPTableCellStyle {
        let parent = parent ?? UPTableStyleContext()
        return UPTableCellStyle(
            align: parent.align,
            padding: parent.padding,
            fontSize: UPUnit.parse(parent.fontSize),
            color: parent.color,
            borderColor: parent.borderColor,
            // Upstream sets `flex: 0 0 <width>` only for a nonempty width.
            fixedWidth: width.isEmpty ? nil : UPUnit.parse(width)
        )
    }

    public var body: some View {
        let style = Self.resolvedStyle(width: width, parent: parent)

        VStack { content }
            .frame(maxWidth: style.fixedWidth ?? .infinity, alignment: style.frameAlignment)
            .padding(.vertical, style.insets.vertical)
            .padding(.horizontal, style.insets.horizontal)
            .multilineTextAlignment(style.textAlignment)
            .fontWeight(.bold)
            .background(UPColor.parse(UPConfig.table.headerBgColor, theme: theme))
            .overlay(
                Rectangle()
                    .stroke(UPColor.parse(style.borderColor, theme: theme), lineWidth: 0.5)
            )
            // The parent's thStyle merges last upstream, then this cell's own.
            .upStyle(parent?.thStyle ?? UPStyle())
            .upStyle(thStyle)
    }
}

public extension UPTh where Content == EmptyView {
    init(width: String = UPConfig.table.thWidth, thStyle: UPStyle = UPConfig.table.thStyle) {
        self.init(width: width, thStyle: thStyle, content: EmptyView.init)
    }
}

@MainActor
public struct UPTd<Content: View>: View {
    public var width: String
    public var textAlign: String
    public var fontSize: String
    public var borderColor: String
    public var color: String
    private let content: Content

    @Environment(\.upTableStyleContext) private var parent
    @Environment(\.upTheme) private var theme

    public init(width: String = UPConfig.table.tdWidth,
                textAlign: String = "",
                fontSize: String = "",
                borderColor: String = "",
                color: String = "",
                @ViewBuilder content: () -> Content) {
        self.width = width
        self.textAlign = textAlign
        self.fontSize = fontSize
        self.borderColor = borderColor
        self.color = color
        self.content = content()
    }

    /// Mirrors the upstream `u-td` mounted hook: inherit the parent table's
    /// style first, then let each nonempty own prop override it.
    public static func resolvedStyle(width: String,
                                     textAlign: String,
                                     fontSize: String,
                                     borderColor: String,
                                     color: String,
                                     parent: UPTableStyleContext?) -> UPTableCellStyle {
        let parent = parent ?? UPTableStyleContext()
        return UPTableCellStyle(
            align: textAlign.isEmpty ? parent.align : textAlign,
            // Upstream has no per-cell padding prop, so it always inherits.
            padding: parent.padding,
            fontSize: UPUnit.parse(fontSize.isEmpty ? parent.fontSize : fontSize),
            color: color.isEmpty ? parent.color : color,
            borderColor: borderColor.isEmpty ? parent.borderColor : borderColor,
            // Upstream sets `flex: 0 0 <width>` for anything but `auto`.
            fixedWidth: width == UPConfig.table.tdWidth ? nil : UPUnit.parse(width)
        )
    }

    public var body: some View {
        let style = Self.resolvedStyle(
            width: width,
            textAlign: textAlign,
            fontSize: fontSize,
            borderColor: borderColor,
            color: color,
            parent: parent
        )

        HStack { content }
            .frame(maxWidth: style.fixedWidth ?? .infinity, alignment: style.frameAlignment)
            .frame(maxHeight: .infinity)
            .font(.system(size: style.fontSize))
            .foregroundStyle(UPColor.parse(style.color, theme: theme))
            .multilineTextAlignment(style.textAlignment)
            .padding(.vertical, style.insets.vertical)
            .padding(.horizontal, style.insets.horizontal)
            .overlay(
                Rectangle()
                    .stroke(UPColor.parse(style.borderColor, theme: theme), lineWidth: 0.5)
            )
    }
}

public extension UPTd where Content == EmptyView {
    init(width: String = UPConfig.table.tdWidth,
         textAlign: String = "",
         fontSize: String = "",
         borderColor: String = "",
         color: String = "") {
        self.init(width: width, textAlign: textAlign, fontSize: fontSize,
                  borderColor: borderColor, color: color, content: EmptyView.init)
    }
}
