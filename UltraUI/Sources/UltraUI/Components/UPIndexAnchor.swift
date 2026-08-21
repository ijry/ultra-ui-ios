import SwiftUI

/// Sticky index header corresponding to uview-plus `u-index-anchor`.
public struct UPIndexAnchor<Content: View>: View {
    public var index: String
    public var useSlot: Bool
    public var customStyle: UPStyle
    public var displayIndex: String { index }
    private let content: Content

    public init(
        index: String,
        useSlot: Bool = false,
        customStyle: UPStyle = UPStyle(),
        @ViewBuilder content: () -> Content
    ) {
        self.index = index
        self.useSlot = useSlot
        self.customStyle = customStyle
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .upStyle(customStyle)
            .id(index)
    }
}

public extension UPIndexAnchor where Content == Text {
    init(index: String, useSlot: Bool = false, customStyle: UPStyle = UPStyle()) {
        self.init(index: index, useSlot: useSlot, customStyle: customStyle) {
            Text(index)
        }
    }
}
