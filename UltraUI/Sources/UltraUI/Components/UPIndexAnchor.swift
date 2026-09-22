import SwiftUI

/// Sticky index header corresponding to uview-plus `u-index-anchor`.
public struct UPIndexAnchor<Content: View>: View {
    public var index: String
    public var text: String
    public var color: String
    public var size: CGFloat
    public var bgColor: String
    public var height: CGFloat
    public var useSlot: Bool
    public var customStyle: UPStyle
    /// Upstream renders `{{ text.name || text }}`; the anchor identifier is the
    /// fallback so existing `UPIndexList` call sites keep working.
    public var displayIndex: String { text.isEmpty ? index : text }
    private let content: Content

    public init(
        index: String,
        text: String = UPConfig.indexAnchor.text,
        color: String = UPConfig.indexAnchor.color,
        size: some UPImageUnitValue = UPConfig.indexAnchor.size,
        bgColor: String = UPConfig.indexAnchor.bgColor,
        height: some UPImageUnitValue = UPConfig.indexAnchor.height,
        useSlot: Bool = false,
        customStyle: UPStyle = UPStyle(),
        @ViewBuilder content: () -> Content
    ) {
        self.index = index
        self.text = text
        self.color = color
        self.size = UPUnit.parse(size.upImageUnitValue)
        self.bgColor = bgColor
        self.height = UPUnit.parse(height.upImageUnitValue)
        self.useSlot = useSlot
        self.customStyle = customStyle
        self.content = content()
    }

    public var body: some View {
        content
            .font(.system(size: size))
            .foregroundStyle(UPColor.parse(color))
            .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            .padding(.leading, 15)
            .background(UPColor.parse(bgColor))
            .upStyle(customStyle)
            .id(index)
    }
}

public extension UPIndexAnchor where Content == Text {
    init(
        index: String,
        text: String = UPConfig.indexAnchor.text,
        color: String = UPConfig.indexAnchor.color,
        size: some UPImageUnitValue = UPConfig.indexAnchor.size,
        bgColor: String = UPConfig.indexAnchor.bgColor,
        height: some UPImageUnitValue = UPConfig.indexAnchor.height,
        useSlot: Bool = false,
        customStyle: UPStyle = UPStyle()
    ) {
        let resolved = text.isEmpty ? index : text
        self.init(
            index: index, text: text, color: color, size: size,
            bgColor: bgColor, height: height, useSlot: useSlot, customStyle: customStyle
        ) {
            Text(resolved)
        }
    }
}
