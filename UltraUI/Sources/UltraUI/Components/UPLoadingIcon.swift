import SwiftUI

public struct UPLoadingIcon: View {
    var show: Bool
    var color: String
    var textColor: String
    var vertical: Bool
    var mode: String
    var size: Double
    var textSize: Double
    var text: String
    var duration: Double
    var inactiveColor: String

    public init(show: Bool = UPConfig.loadingIcon.show,
                color: String = UPConfig.loadingIcon.color,
                textColor: String = UPConfig.loadingIcon.textColor,
                vertical: Bool = UPConfig.loadingIcon.vertical,
                mode: String = UPConfig.loadingIcon.mode,
                size: Double = UPConfig.loadingIcon.size,
                textSize: Double = UPConfig.loadingIcon.textSize,
                text: String = UPConfig.loadingIcon.text,
                duration: Double = UPConfig.loadingIcon.duration,
                inactiveColor: String = UPConfig.loadingIcon.inactiveColor) {
        self.show = show
        self.color = color
        self.textColor = textColor
        self.vertical = vertical
        self.mode = mode
        self.size = size
        self.textSize = textSize
        self.text = text
        self.duration = duration
        self.inactiveColor = inactiveColor
    }

    @Environment(\.upTheme) private var theme
    @State private var rotation: Double = 0

    public var body: some View {
        if show {
            Group {
                if vertical {
                    VStack(spacing: 8) { spinner; textView }
                } else {
                    HStack(spacing: 8) { spinner; textView }
                }
            }
        }
    }

    private var spinner: some View {
        let c = UPColor.parse(color, theme: theme)
        return Group {
            if mode == "circle" {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(c, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: duration / 1000).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: c))
                    .scaleEffect(size / 20)
            }
        }
    }

    private var textView: some View {
        Text(text)
            .font(.system(size: textSize))
            .foregroundStyle(UPColor.parse(textColor, theme: theme))
    }
}
