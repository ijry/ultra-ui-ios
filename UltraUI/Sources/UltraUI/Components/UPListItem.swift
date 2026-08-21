import SwiftUI

/// Child item container corresponding to uview-plus `u-list-item`.
public struct UPListItem<Content: View>: View {
    public var anchor: String
    public var customStyle: UPStyle
    private let content: Content

    public init(
        anchor: String = "",
        customStyle: UPStyle = UPStyle(),
        @ViewBuilder content: () -> Content
    ) {
        self.anchor = anchor
        self.customStyle = customStyle
        self.content = content()
    }

    public var body: some View {
        content
            .id(anchor.isEmpty ? nil : anchor)
            .upStyle(customStyle)
    }
}

public extension UPListItem where Content == EmptyView {
    init(anchor: String = "", customStyle: UPStyle = UPStyle()) {
        self.init(anchor: anchor, customStyle: customStyle, content: EmptyView.init)
    }
}
