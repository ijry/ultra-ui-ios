import SwiftUI

/// Section container corresponding to uview-plus `u-index-item`.
public struct UPIndexItem<Header: View, Content: View>: View {
    public var index: String
    private let header: Header
    private let content: Content

    public init(
        index: String,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.index = index
        self.header = header()
        self.content = content()
    }

    public var body: some View {
        Section {
            content
        } header: {
            header.id(index)
        }
    }
}

public extension UPIndexItem where Header == UPIndexAnchor<Text> {
    init(index: String, @ViewBuilder content: () -> Content) {
        self.init(index: index, header: { UPIndexAnchor(index: index) }, content: content)
    }
}
