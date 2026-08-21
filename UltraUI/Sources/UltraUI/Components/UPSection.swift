import SwiftUI

/// Native counterpart of uview-plus `u-section`.
@MainActor
public struct UPSection<Content: View>: View {
    public var title: String
    public var subTitle: String
    public var right: Bool
    public var fontSize: CGFloat
    public var bold: Bool
    public var color: String
    public var subColor: String
    public var showLine: Bool
    public var lineColor: String
    public var arrow: Bool

    private let content: Content
    private var onClickHandler: (() -> Void)?

    public init(
        title: String = "", subTitle: String = "更多", right: Bool = true,
        fontSize: CGFloat = 15, bold: Bool = true, color: String = "#303133",
        subColor: String = "#909399", showLine: Bool = true,
        lineColor: String = "", arrow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subTitle = subTitle
        self.right = right
        self.fontSize = fontSize
        self.bold = bold
        self.color = color
        self.subColor = subColor
        self.showLine = showLine
        self.lineColor = lineColor
        self.arrow = arrow
        self.content = content()
    }

    public var body: some View {
        Button(action: triggerClick) {
            HStack(spacing: 8) {
                if showLine {
                    Rectangle()
                        .fill(UPColor.parse(lineColor.isEmpty ? "#3c9cff" : lineColor))
                        .frame(width: 3, height: max(fontSize, 14))
                }
                Text(title)
                    .font(.system(size: fontSize, weight: bold ? .bold : .regular))
                    .foregroundColor(UPColor.parse(color))
                Spacer(minLength: 0)
                if right {
                    content
                    if !subTitle.isEmpty {
                        Text(subTitle).foregroundColor(UPColor.parse(subColor))
                    }
                    if arrow { Image(systemName: "chevron.right").font(.caption) }
                }
            }
        }
        .buttonStyle(.plain)
    }

    public func onClick(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    public func triggerClick() { onClickHandler?() }
}

public extension UPSection where Content == EmptyView {
    init(
        title: String = "", subTitle: String = "更多", right: Bool = true,
        fontSize: CGFloat = 15, bold: Bool = true, color: String = "#303133",
        subColor: String = "#909399", showLine: Bool = true,
        lineColor: String = "", arrow: Bool = true
    ) {
        self.init(title: title, subTitle: subTitle, right: right, fontSize: fontSize,
                  bold: bold, color: color, subColor: subColor, showLine: showLine,
                  lineColor: lineColor, arrow: arrow, content: EmptyView.init)
    }
}
