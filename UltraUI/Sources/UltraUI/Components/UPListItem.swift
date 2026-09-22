import SwiftUI

/// Child item container corresponding to uview-plus `u-list-item`.
///
/// 上游只有一个 `anchor` prop（`String | Number`），用来配合 `u-list` 的
/// `scroll-into-view` 滚动到指定项；原生把它落成 `.id(_:)`。
/// 上游 `u-list-item` 内部还会量自身位置去驱动 `preLoadScreen` 的偏移复用，
/// 原生的 `LazyVStack` 自带复用，不需要这层测量。
public struct UPListItem<Content: View>: View {
    public var anchor: String
    public var customStyle: UPStyle
    private let content: Content

    public init(
        anchor: some UPCheckboxTextValue = UPConfig.listItem.anchor,
        customStyle: UPStyle = UPStyle(),
        @ViewBuilder content: () -> Content
    ) {
        self.anchor = anchor.upCheckboxTextValue
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
    init(anchor: some UPCheckboxTextValue = UPConfig.listItem.anchor,
         customStyle: UPStyle = UPStyle()) {
        self.init(anchor: anchor, customStyle: customStyle, content: EmptyView.init)
    }
}
