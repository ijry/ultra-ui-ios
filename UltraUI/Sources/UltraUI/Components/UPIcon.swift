import SwiftUI

public struct UPIcon: View {
    var name: String
    var color: String
    var size: String
    var bold: Bool
    var label: String
    var labelPos: String
    var labelSize: String
    var labelColor: String
    var space: String
    var customPrefix: String
    var onTap: (() -> Void)?

    public init(name: String = UPConfig.icon.name,
                color: String = UPConfig.icon.color,
                size: String = UPConfig.icon.size,
                bold: Bool = UPConfig.icon.bold,
                label: String = UPConfig.icon.label,
                labelPos: String = UPConfig.icon.labelPos,
                labelSize: String = UPConfig.icon.labelSize,
                labelColor: String = UPConfig.icon.labelColor,
                space: String = UPConfig.icon.space,
                customPrefix: String = UPConfig.icon.customPrefix,
                onTap: (() -> Void)? = nil) {
        self.name = name
        self.color = color
        self.size = size
        self.bold = bold
        self.label = label
        self.labelPos = labelPos
        self.labelSize = labelSize
        self.labelColor = labelColor
        self.space = space
        self.customPrefix = customPrefix
        self.onTap = onTap
    }

    @Environment(\.upTheme) private var theme

    public var body: some View {
        let glyph = UPIconMap.glyph(for: customPrefix.isEmpty ? name : "\(customPrefix)-\(name)")
        let fontSize = UPUnit.parse(size)
        return HStack(spacing: UPUnit.parse(space)) {
            if labelPos == "left" { labelView }
            Text(glyph)
                .font(.custom("uview-icon", size: fontSize))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(UPColor.parse(color, theme: theme))
            if labelPos == "right" { labelView }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
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
}
