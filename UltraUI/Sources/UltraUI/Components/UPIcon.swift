import Foundation
import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-icon`.
public struct UPIcon: View {
    public static let fontName = "iconfont"

    var name: String
    var color: String
    var size: String
    var bold: Bool
    var index: String
    var hoverClass: String
    var customPrefix: String
    var label: String
    var labelPos: String
    var labelSize: String
    var labelColor: String
    var space: String
    var imgMode: String
    var width: String
    var height: String
    var top: String
    var stop: Bool
    var onTap: (() -> Void)?
    var onClick: ((String) -> Void)?

    public init(name: String = UPConfig.icon.name,
                color: String = UPConfig.icon.color,
                size: String = UPConfig.icon.size,
                bold: Bool = UPConfig.icon.bold,
                index: String = UPConfig.icon.index,
                hoverClass: String = UPConfig.icon.hoverClass,
                customPrefix: String = UPConfig.icon.customPrefix,
                label: String = UPConfig.icon.label,
                labelPos: String = UPConfig.icon.labelPos,
                labelSize: String = UPConfig.icon.labelSize,
                labelColor: String = UPConfig.icon.labelColor,
                space: String = UPConfig.icon.space,
                imgMode: String = UPConfig.icon.imgMode,
                width: String = UPConfig.icon.width,
                height: String = UPConfig.icon.height,
                top: String = UPConfig.icon.top,
                stop: Bool = UPConfig.icon.stop,
                onTap: (() -> Void)? = nil,
                onClick: ((String) -> Void)? = nil) {
        self.name = name
        self.color = color
        self.size = size
        self.bold = bold
        self.index = index
        self.hoverClass = hoverClass
        self.customPrefix = customPrefix
        self.label = label
        self.labelPos = labelPos
        self.labelSize = labelSize
        self.labelColor = labelColor
        self.space = space
        self.imgMode = imgMode
        self.width = width
        self.height = height
        self.top = top
        self.stop = stop
        self.onTap = onTap
        self.onClick = onClick
    }

    @Environment(\.upTheme) private var theme

    public var body: some View {
        let position = Self.normalizedLabelPosition(labelPos)
        let spacing = UPUnit.parse(space)

        return Group {
            switch position {
            case "left":
                HStack(spacing: spacing) {
                    labelView
                    iconView
                }
            case "top":
                VStack(spacing: spacing) {
                    labelView
                    iconView
                }
            case "bottom":
                VStack(spacing: spacing) {
                    iconView
                    labelView
                }
            default:
                HStack(spacing: spacing) {
                    iconView
                    labelView
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
            onClick?(index)
        }
    }

    /// uview-plus treats a name containing `/` as an image source instead of a glyph name.
    public static func isImageName(_ name: String) -> Bool {
        name.contains("/")
    }

    /// Resolves unsupported positions to the upstream effective default (`right`).
    public static func normalizedLabelPosition(_ position: String) -> String {
        switch position {
        case "left", "right", "top", "bottom":
            return position
        default:
            return "right"
        }
    }

    /// SwiftUI's native analogue for uview-plus crop/fill image modes.
    public static func usesAspectFill(for imgMode: String) -> Bool {
        switch imgMode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "aspectfill", "scaletofill":
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if Self.isImageName(name) {
            imageView
        } else {
            glyphView
        }
    }

    private var glyphView: some View {
        let glyphKey: String
        if customPrefix.isEmpty || name.hasPrefix("\(customPrefix)-") {
            glyphKey = name
        } else {
            glyphKey = "\(customPrefix)-\(name)"
        }

        return Text(UPIconMap.glyph(for: glyphKey))
            .font(.custom(Self.fontName, size: UPUnit.parse(size)))
            .fontWeight(bold ? .bold : .regular)
            .foregroundStyle(UPColor.parse(color, theme: theme))
            .offset(y: UPUnit.parse(top))
    }

    @ViewBuilder
    private var imageView: some View {
        let imageWidth = resolvedImageDimension(width)
        let imageHeight = resolvedImageDimension(height)

        if let url = remoteImageURL(name) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    renderedImage(image, width: imageWidth, height: imageHeight)
                default:
                    Color.clear
                        .frame(width: imageWidth, height: imageHeight)
                }
            }
        } else {
            renderedImage(Image(name), width: imageWidth, height: imageHeight)
        }
    }

    @ViewBuilder
    private func renderedImage(_ image: Image, width: CGFloat, height: CGFloat) -> some View {
        if Self.usesAspectFill(for: imgMode) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
        } else {
            image
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
        }
    }

    private func remoteImageURL(_ source: String) -> URL? {
        guard let url = URL(string: source), let scheme = url.scheme?.lowercased() else {
            return nil
        }
        return ["http", "https", "file"].contains(scheme) ? url : nil
    }

    private func resolvedImageDimension(_ raw: String) -> CGFloat {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return UPUnit.parse(value.isEmpty ? size : value)
    }

    private var labelView: some View {
        Text(label)
            .font(.system(size: UPUnit.parse(labelSize)))
            .foregroundStyle(UPColor.parse(labelColor, theme: theme))
    }
}

public extension UPIcon {
    func onTap(_ action: @escaping () -> Void) -> UPIcon {
        var copy = self
        copy.onTap = action
        return copy
    }

    func onClick(_ action: @escaping (String) -> Void) -> UPIcon {
        var copy = self
        copy.onClick = action
        return copy
    }
}
