import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-title`.
///
/// The upstream component has no props or emits. Its default slot maps to the
/// trailing SwiftUI builder, while the named `prefix` slot replaces the built-
/// in primary-color indicator entirely.
public struct UPTitle: View {
    private var prefixContent: AnyView?
    private var content: AnyView

    /// Whether the named uview-plus `prefix` slot was supplied.
    var hasCustomPrefix: Bool

    // These values are defined by `u-title.vue`'s final scoped CSS cascade.
    var defaultPrefixWidth: CGFloat { 4 }
    var defaultPrefixHeight: CGFloat { 18 }
    var defaultPrefixCornerRadius: CGFloat { 2 }
    var defaultPrefixTrailingMargin: CGFloat { 10 }

    @Environment(\.upTheme) private var theme

    /// Creates an empty title while retaining uview-plus's default prefix.
    public init() {
        self.prefixContent = nil
        self.content = AnyView(EmptyView())
        self.hasCustomPrefix = false
    }

    /// Creates a title whose trailing builder maps to uview-plus's default
    /// slot.
    public init<Content: View>(@ViewBuilder content: () -> Content) {
        self.prefixContent = nil
        self.content = AnyView(content())
        self.hasCustomPrefix = false
    }

    /// Creates a title with an explicit SwiftUI equivalent of the named
    /// uview-plus `prefix` slot.
    public init<Prefix: View, Content: View>(
        @ViewBuilder prefix: () -> Prefix,
        @ViewBuilder content: () -> Content
    ) {
        self.prefixContent = AnyView(prefix())
        self.content = AnyView(content())
        self.hasCustomPrefix = true
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if let prefixContent {
                prefixContent
            } else {
                RoundedRectangle(cornerRadius: defaultPrefixCornerRadius, style: .continuous)
                    .fill(theme.primary)
                    .frame(width: defaultPrefixWidth, height: defaultPrefixHeight)
                    .padding(.trailing, defaultPrefixTrailingMargin)
            }

            content
        }
        .foregroundStyle(theme.main)
    }
}
