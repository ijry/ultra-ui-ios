import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-view`.
///
/// CSS-only props are retained with their upstream names and mapped to the
/// closest deterministic SwiftUI layout behavior.
@MainActor
public struct UPView<Content: View>: View {
    var backgroundColor: String
    var color: String
    var flexDirection: String
    var justifyContent: String
    var alignItems: String
    var flex1: String
    var width: String
    var height: String
    var padding: String
    var margin: String
    var borderColor: String

    private let content: Content
    private var onClickHandler: (() -> Void)?

    public init(
        backgroundColor: String = "",
        color: String = "",
        flexDirection: String = "",
        justifyContent: String = "",
        alignItems: String = "",
        flex1: String = "",
        width: String = "",
        height: String = "",
        padding: String = "",
        margin: String = "",
        borderColor: String = "",
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.color = color
        self.flexDirection = flexDirection
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.flex1 = flex1
        self.width = width
        self.height = height
        self.padding = padding
        self.margin = margin
        self.borderColor = borderColor
        self.content = content()
    }

    public var body: some View {
        layout
            .frame(
                minWidth: flex1Value ? 0 : nil,
                maxWidth: flex1Value ? .infinity : nil,
                minHeight: flex1Value ? 0 : nil,
                maxHeight: flex1Value ? .infinity : nil,
                alignment: frameAlignment
            )
            .upStyle(resolvedStyle)
            .overlay {
                if !borderColor.isEmpty {
                    Rectangle().stroke(UPColor.parse(borderColor), lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { triggerClick() }
    }

    @ViewBuilder
    private var layout: some View {
        if flexDirection.lowercased().hasPrefix("row") {
            HStack(alignment: verticalAlignment, spacing: 0) { content }
        } else {
            VStack(alignment: horizontalAlignment, spacing: 0) { content }
        }
    }

    public func onClick(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    public func triggerClick() {
        onClickHandler?()
    }

    private var resolvedStyle: UPStyle {
        var properties: [String: String] = [:]
        if !backgroundColor.isEmpty { properties["background-color"] = backgroundColor }
        if !color.isEmpty { properties["color"] = color }
        if !width.isEmpty { properties["width"] = width }
        if !height.isEmpty { properties["height"] = height }
        if !padding.isEmpty { properties["padding"] = padding }
        if !margin.isEmpty { properties["margin"] = margin }
        return UPStyle(properties)
    }

    private var flex1Value: Bool {
        ["1", "true", "yes"].contains(flex1.lowercased())
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch alignItems.lowercased() {
        case "center": return .center
        case "flex-end", "end", "trailing": return .trailing
        default: return .leading
        }
    }

    private var verticalAlignment: VerticalAlignment {
        switch alignItems.lowercased() {
        case "center": return .center
        case "flex-end", "end", "bottom": return .bottom
        default: return .top
        }
    }

    private var frameAlignment: Alignment {
        switch justifyContent.lowercased() {
        case "center": return .center
        case "flex-end", "end": return flexDirection.lowercased().hasPrefix("row") ? .trailing : .bottom
        default: return flexDirection.lowercased().hasPrefix("row") ? .leading : .top
        }
    }
}

public extension UPView where Content == EmptyView {
    init(
        backgroundColor: String = "",
        color: String = "",
        flexDirection: String = "",
        justifyContent: String = "",
        alignItems: String = "",
        flex1: String = "",
        width: String = "",
        height: String = "",
        padding: String = "",
        margin: String = "",
        borderColor: String = ""
    ) {
        self.init(
            backgroundColor: backgroundColor,
            color: color,
            flexDirection: flexDirection,
            justifyContent: justifyContent,
            alignItems: alignItems,
            flex1: flex1,
            width: width,
            height: height,
            padding: padding,
            margin: margin,
            borderColor: borderColor,
            content: EmptyView.init
        )
    }
}
