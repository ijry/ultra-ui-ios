import SwiftUI

/// Legacy uview-plus table primitives.  The four Vue components are kept as
/// separate SwiftUI views so existing markup can be translated one element at
/// a time while sharing the table's visual defaults.
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

    public init(borderColor: String = "#e4e7ed", align: String = "center",
                padding: String = "5px 3px", fontSize: String = "14px",
                color: String = "#606266", thStyle: UPStyle = UPStyle(),
                bgColor: String = "#ffffff", @ViewBuilder content: () -> Content) {
        self.borderColor = borderColor; self.align = align; self.padding = padding
        self.fontSize = fontSize; self.color = color; self.thStyle = thStyle
        self.bgColor = bgColor; self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) { content }
            .background(UPColor.parse(bgColor))
            .overlay(Rectangle().stroke(UPColor.parse(borderColor), lineWidth: 1))
    }
}

public extension UPTable where Content == EmptyView {
    init(borderColor: String = "#e4e7ed", align: String = "center",
         padding: String = "5px 3px", fontSize: String = "14px",
         color: String = "#606266", thStyle: UPStyle = UPStyle(),
         bgColor: String = "#ffffff") {
        self.init(borderColor: borderColor, align: align, padding: padding,
                  fontSize: fontSize, color: color, thStyle: thStyle,
                  bgColor: bgColor, content: EmptyView.init)
    }
}

@MainActor
public struct UPTr<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View { HStack(spacing: 0) { content } }
}

public extension UPTr where Content == EmptyView {
    init() { self.init(content: EmptyView.init) }
}

@MainActor
public struct UPTh<Content: View>: View {
    public var width: String
    public var thStyle: UPStyle
    private let content: Content
    public init(width: String = "", thStyle: UPStyle = UPStyle(), @ViewBuilder content: () -> Content) {
        self.width = width; self.thStyle = thStyle; self.content = content()
    }
    public var body: some View {
        VStack { content }.frame(maxWidth: width.isEmpty ? .infinity : UPUnit.parse(width))
            .fontWeight(.bold).background(UPColor.parse("#f5f6f8"))
            .overlay(Rectangle().stroke(UPColor.parse("#e4e7ed"), lineWidth: 0.5))
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
    public init(width: String = "auto", textAlign: String = "", fontSize: String = "",
                borderColor: String = "", color: String = "", @ViewBuilder content: () -> Content) {
        self.width = width; self.textAlign = textAlign; self.fontSize = fontSize
        self.borderColor = borderColor; self.color = color; self.content = content()
    }
    public var body: some View {
        HStack { content }.frame(maxWidth: width == "auto" ? .infinity : UPUnit.parse(width))
            .frame(maxHeight: .infinity).font(.system(size: UPUnit.parse(fontSize.isEmpty ? "14px" : fontSize)))
            .foregroundColor(UPColor.parse(color.isEmpty ? "#606266" : color))
            .multilineTextAlignment(textAlign == "right" ? .trailing : textAlign == "left" ? .leading : .center)
            .padding(.vertical, 5).padding(.horizontal, 3)
            .overlay(Rectangle().stroke(UPColor.parse(borderColor.isEmpty ? "#e4e7ed" : borderColor), lineWidth: 0.5))
    }
}

public extension UPTh where Content == EmptyView {
    init(width: String = "", thStyle: UPStyle = UPStyle()) {
        self.init(width: width, thStyle: thStyle, content: EmptyView.init)
    }
}

public extension UPTd where Content == EmptyView {
    init(width: String = "auto", textAlign: String = "", fontSize: String = "",
         borderColor: String = "", color: String = "") {
        self.init(width: width, textAlign: textAlign, fontSize: fontSize,
                  borderColor: borderColor, color: color, content: EmptyView.init)
    }
}
