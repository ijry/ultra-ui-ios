import SwiftUI

public struct UPGap: View {
    var bgColor: String
    var height: Double
    var marginTop: Double
    var marginBottom: Double

    public init(bgColor: String = UPConfig.gap.bgColor,
                height: Double = UPConfig.gap.height,
                marginTop: Double = UPConfig.gap.marginTop,
                marginBottom: Double = UPConfig.gap.marginBottom) {
        self.bgColor = bgColor
        self.height = height
        self.marginTop = marginTop
        self.marginBottom = marginBottom
    }

    @Environment(\.upTheme) private var theme

    public var body: some View {
        Color.clear
            .frame(height: height)
            .background(bgColor == "transparent" ? Color.clear : UPColor.parse(bgColor, theme: theme))
            .padding(.top, marginTop)
            .padding(.bottom, marginBottom)
    }
}
