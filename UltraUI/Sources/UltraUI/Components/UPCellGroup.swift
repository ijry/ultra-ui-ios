import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-cell-group`.
///
/// The trailing SwiftUI builder is the upstream default slot. The named
/// `title` slot is exposed through ``UPCellGroup/title(_:)``. As in the
/// upstream template, a title slot is rendered only when the string `title`
/// prop is nonempty; the slot replaces the built-in title text rather than
/// adding a second title.
public struct UPCellGroup: View {
    /// Retained metadata equivalent to uview-plus's mixin-provided class prop.
    var customClass: String
    /// Group heading. An empty title hides both the heading wrapper and title slot.
    var title: String
    /// Whether the leading group separator is displayed.
    var border: Bool
    /// Native subset of uview-plus's mixin-provided `customStyle` prop.
    var customStyle: UPStyle

    private var content: AnyView
    private var titleContent: AnyView?

    /// Whether a native equivalent of the named uview-plus `title` slot was supplied.
    var hasTitleSlot: Bool

    @Environment(\.upTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    /// Creates an empty group, matching `<u-cell-group />`.
    public init(
        customClass: String = UPConfig.cellGroup.customClass,
        title: String = UPConfig.cellGroup.title,
        border: Bool = UPConfig.cellGroup.border,
        customStyle: UPStyle = UPConfig.cellGroup.customStyle
    ) {
        self.customClass = customClass
        self.title = title
        self.border = border
        self.customStyle = customStyle
        self.content = AnyView(EmptyView())
        self.titleContent = nil
        self.hasTitleSlot = false
    }

    /// Creates a group whose trailing builder maps to uview-plus's default slot.
    public init<Content: View>(
        customClass: String = UPConfig.cellGroup.customClass,
        title: String = UPConfig.cellGroup.title,
        border: Bool = UPConfig.cellGroup.border,
        customStyle: UPStyle = UPConfig.cellGroup.customStyle,
        @ViewBuilder content: () -> Content
    ) {
        self.customClass = customClass
        self.title = title
        self.border = border
        self.customStyle = customStyle
        self.content = AnyView(content())
        self.titleContent = nil
        self.hasTitleSlot = false
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsTitle {
                titleSection
            }

            VStack(spacing: 0) {
                if showsTopBorder {
                    UPLine()
                }
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(resolvedBackgroundColor)
        .upStyle(customStyle)
    }

    /// Mirrors `v-if="title"` around the upstream title wrapper.
    var showsTitle: Bool {
        !title.isEmpty
    }

    /// Mirrors the conditional leading `<u-line v-if="border" />`.
    var showsTopBorder: Bool {
        border
    }

    /// The final font size from `u-cell-group.vue`'s scoped CSS.
    var resolvedTitleFontSize: CGFloat {
        15
    }

    /// The final title wrapper padding from `u-cell-group.vue`'s scoped CSS.
    var resolvedTitlePadding: UPInsets {
        UPInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
    }

    private var resolvedBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: 0x1C1C1E) : .white
    }

    @ViewBuilder
    private var titleSection: some View {
        Group {
            if let titleContent {
                titleContent
            } else {
                Text(title)
                    .font(.system(size: resolvedTitleFontSize))
                    .foregroundStyle(theme.main)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, resolvedTitlePadding.top)
        .padding(.leading, resolvedTitlePadding.leading)
        .padding(.bottom, resolvedTitlePadding.bottom)
        .padding(.trailing, resolvedTitlePadding.trailing)
    }
}

public extension UPCellGroup {
    /// SwiftUI equivalent of uview-plus's named `title` slot.
    func title<Content: View>(@ViewBuilder _ content: () -> Content) -> UPCellGroup {
        var copy = self
        copy.titleContent = AnyView(content())
        copy.hasTitleSlot = true
        return copy
    }
}
