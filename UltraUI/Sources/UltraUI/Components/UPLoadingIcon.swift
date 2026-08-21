import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-loading-icon`.
public struct UPLoadingIcon: View {
    var show: Bool
    var color: String
    var textColor: String
    var vertical: Bool
    var mode: String
    var size: Double
    var textSize: Double
    var text: String
    var timingFunction: String
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
                timingFunction: String = UPConfig.loadingIcon.timingFunction,
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
        self.timingFunction = timingFunction
        self.duration = duration
        self.inactiveColor = inactiveColor
    }

    @Environment(\.upTheme) private var theme
    @State private var rotation: Double = 0

    public var body: some View {
        Group {
            if show {
                if vertical {
                    VStack(spacing: 8) { spinner; textView }
                } else {
                    HStack(spacing: 8) { spinner; textView }
                }
            }
        }
    }

    /// Normalizes the timing names accepted by uview-plus to a native animation.
    public static func animation(for timingFunction: String, duration: Double) -> Animation {
        let seconds = max(0.001, duration / 1_000)
        switch timingFunction.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "linear":
            return .linear(duration: seconds)
        case "ease-in", "easein":
            return .easeIn(duration: seconds)
        case "ease-out", "easeout":
            return .easeOut(duration: seconds)
        default:
            return .easeInOut(duration: seconds)
        }
    }

    private var spinner: some View {
        let activeColor = UPColor.parse(color, theme: theme)
        let inactive = inactiveColor.isEmpty
            ? activeColor.opacity(0.25)
            : UPColor.parse(inactiveColor, theme: theme)
        let resolvedMode = Self.resolvedMode(mode)

        return Group {
            switch resolvedMode {
            case "circle", "semicircle":
                ZStack {
                    Circle()
                        .trim(from: 0, to: resolvedMode == "semicircle" ? 0.5 : 1)
                        .stroke(inactive, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    Circle()
                        .trim(from: 0, to: resolvedMode == "semicircle" ? 0.38 : 0.7)
                        .stroke(activeColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                .frame(width: max(0, size), height: max(0, size))
                .rotationEffect(.degrees(rotation))
                .onAppear(perform: startRotation)
                .onChange(of: timingFunction) { _, _ in startRotation() }
                .onChange(of: duration) { _, _ in startRotation() }
            default:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: activeColor))
                    .scaleEffect(max(0, size) / 20)
            }
        }
    }

    private var textView: some View {
        Group {
            if !text.isEmpty {
                Text(text)
                    .font(.system(size: max(0, textSize)))
                    .foregroundStyle(UPColor.parse(textColor, theme: theme))
            }
        }
    }

    private func startRotation() {
        rotation = 0
        withAnimation(Self.animation(for: timingFunction, duration: duration).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }

    static func resolvedMode(_ mode: String) -> String {
        switch mode {
        case "circle", "semicircle", "spinner": return mode
        default: return "spinner"
        }
    }
}
