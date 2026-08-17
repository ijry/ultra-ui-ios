import Foundation
import SwiftUI

/// Semantic alias for the `String | Number` props accepted by `u-avatar`.
public typealias UPAvatarUnitValue = UPCheckboxUnitValue

/// Native SwiftUI counterpart of uview-plus `u-avatar`.
///
/// Mini-program-only `mpAvatar` is retained for source compatibility; native
/// Apple platforms render the supplied text, icon, image, or a fallback avatar.
public struct UPAvatar: View {
    var src: String
    var shape: String
    var size: Double
    var mode: String
    var text: String
    var bgColor: String
    var color: String
    var fontSize: Double
    var icon: String
    var mpAvatar: Bool
    var randomBgColor: Bool
    var defaultUrl: String
    var colorIndex: String
    var name: String
    /// Retained for uview-plus source compatibility; SwiftUI has no CSS-class analogue.
    var customClass: String
    var customStyle: UPStyle
    var onTapHandler: (() -> Void)?
    var onClickHandler: ((String) -> Void)?

    @Environment(\.upTheme) private var theme

    /// Creates an avatar while accepting the upstream `String | Number` unit
    /// props independently. Values are normalized only for native layout;
    /// callers can therefore freely mix values such as `size: "48px"` and
    /// `fontSize: 18`.
    public init(src: String = UPConfig.avatar.src,
                shape: String = UPConfig.avatar.shape,
                size: some UPAvatarUnitValue = UPConfig.avatar.size,
                mode: String = UPConfig.avatar.mode,
                text: String = UPConfig.avatar.text,
                bgColor: String = UPConfig.avatar.bgColor,
                color: String = UPConfig.avatar.color,
                fontSize: some UPAvatarUnitValue = UPConfig.avatar.fontSize,
                icon: String = UPConfig.avatar.icon,
                mpAvatar: Bool = UPConfig.avatar.mpAvatar,
                randomBgColor: Bool = UPConfig.avatar.randomBgColor,
                defaultUrl: String = UPConfig.avatar.defaultUrl,
                colorIndex: some UPAvatarUnitValue = UPConfig.avatar.colorIndex,
                name: String = UPConfig.avatar.name,
                customClass: String = UPConfig.avatar.customClass,
                customStyle: UPStyle = UPConfig.avatar.customStyle,
                onTap: (() -> Void)? = nil,
                onClick: ((String) -> Void)? = nil) {
        self.src = src
        self.shape = shape
        self.size = Double(UPUnit.parse(size.upCheckboxUnitValue))
        self.mode = mode
        self.text = text
        self.bgColor = bgColor
        self.color = color
        self.fontSize = Double(UPUnit.parse(fontSize.upCheckboxUnitValue))
        self.icon = icon
        self.mpAvatar = mpAvatar
        self.randomBgColor = randomBgColor
        self.defaultUrl = defaultUrl
        self.colorIndex = colorIndex.upCheckboxUnitValue
        self.name = name
        self.customClass = customClass
        self.customStyle = customStyle
        self.onTapHandler = onTap
        self.onClickHandler = onClick
    }

    /// SwiftUI event modifier corresponding to uview-plus `@click`.
    public func onClick(_ action: @escaping (String) -> Void) -> UPAvatar {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    public var body: some View {
        avatarContent
            .frame(width: resolvedSize, height: resolvedSize)
            .background(contentBackground)
            .clipShape(RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .upStyle(customStyle)
            .onTapGesture {
                onTapHandler?()
                onClickHandler?(name)
            }
    }

    private var resolvedSize: CGFloat {
        max(CGFloat(size), 1)
    }

    private var resolvedCornerRadius: CGFloat {
        shape.lowercased() == "square" ? 4 : resolvedSize / 2
    }

    private var contentBackground: Color {
        guard !text.isEmpty || !icon.isEmpty else { return .clear }
        return UPColor.parse(resolvedBackgroundColorName, theme: theme)
    }

    private var resolvedBackgroundColorName: String {
        guard randomBgColor else { return bgColor }
        if let index = Int(colorIndex), Self.randomBackgroundColors.indices.contains(index) {
            return Self.randomBackgroundColors[index]
        }
        let stableSource = name.isEmpty ? (text.isEmpty ? icon : text) : name
        let index = abs(stableSource.hashValue) % Self.randomBackgroundColors.count
        return Self.randomBackgroundColors[index]
    }

    @ViewBuilder
    private var avatarContent: some View {
        if !icon.isEmpty {
            UPIcon(name: icon, color: color, size: "\(Int(fontSize))px")
        } else if !text.isEmpty {
            Text(text)
                .font(.system(size: max(CGFloat(fontSize), 1)))
                .foregroundStyle(UPColor.parse(color, theme: theme))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        } else {
            imageContent
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let url = remoteImageURL(src) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    renderedImage(image)
                default:
                    fallbackImage
                }
            }
        } else if !src.isEmpty {
            renderedImage(Image(src))
        } else {
            fallbackImage
        }
    }

    @ViewBuilder
    private var fallbackImage: some View {
        if let url = remoteImageURL(defaultUrl) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    renderedImage(image)
                } else {
                    placeholderImage
                }
            }
        } else if !defaultUrl.isEmpty {
            renderedImage(Image(defaultUrl))
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(UPColor.parse(bgColor, theme: theme).opacity(0.7))
            .padding(resolvedSize * 0.08)
    }

    @ViewBuilder
    private func renderedImage(_ image: Image) -> some View {
        if Self.usesAspectFill(for: mode) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: resolvedSize, height: resolvedSize)
                .clipped()
        } else {
            image
                .resizable()
                .scaledToFit()
                .frame(width: resolvedSize, height: resolvedSize)
        }
    }

    /// Maps uview-plus image modes to the native avatar content mode without
    /// depending on icon-specific implementation details.
    static func usesAspectFill(for mode: String) -> Bool {
        switch mode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "aspectfill", "scaletofill":
            true
        default:
            false
        }
    }

    private func remoteImageURL(_ source: String) -> URL? {
        guard let url = URL(string: source), let scheme = url.scheme?.lowercased() else {
            return nil
        }
        return ["http", "https", "file"].contains(scheme) ? url : nil
    }

    private static let randomBackgroundColors = [
        "#e45656", "#f9ae3d", "#f4c33d", "#5ac725", "#4fd3c4",
        "#4ca7f5", "#7385f5", "#9c6cf0", "#d45cec", "#eb67a6",
        "#d26060", "#e69850", "#d9b33b", "#76ad4a", "#56a99f",
        "#5d93c8", "#6e77ba", "#8a65bd", "#bd5da0", "#c76979"
    ]
}
