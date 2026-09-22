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
    /// 上游 mixin 提供的 `customStyle`，模板里 `addStyle(customStyle)` 叠在根节点上。
    var customStyle: UPStyle

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
                inactiveColor: String = UPConfig.loadingIcon.inactiveColor,
                customStyle: UPStyle = UPStyle()) {
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
        self.customStyle = customStyle
    }

    @Environment(\.upTheme) private var theme
    @State private var rotation: Double = 0

    public var body: some View {
        Group {
            if show {
                if vertical {
                    VStack(spacing: showsText ? UPConfig.loadingIcon.verticalTextSpacing : 0) {
                        spinner
                        textView
                    }
                } else {
                    HStack(spacing: showsText ? UPConfig.loadingIcon.textSpacing : 0) {
                        spinner
                        textView
                    }
                }
            }
        }
        .upStyle(customStyle)
    }

    /// 上游模板 `v-if="text"`：空串不渲染文字（另有 `&__text:empty { display: none }` 兜底）。
    public var showsText: Bool { !text.isEmpty }

    /// 上游 `otherBorderColor`：`circle` 模式下取 `inactiveColor`，
    /// 没给就用 `colorGradient(color, '#ffffff', 100)[80]`（往白色插值 80%）；
    /// 其余模式一律 `transparent`。
    public var otherBorderColor: String {
        guard Self.resolvedMode(mode) == "circle" else { return "transparent" }
        if !inactiveColor.isEmpty { return inactiveColor }
        return Self.lightened(color)
    }

    /// 上游 `colorGradient(startColor, '#ffffff', 100)[80]` 的等价实现。
    nonisolated static func lightened(_ hex: String, ratio: Double = UPConfig.loadingIcon.inactiveLightenRatio) -> String {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("#") else { return trimmed }
        var digits = String(trimmed.dropFirst())
        if digits.count == 3 {
            digits = digits.map { "\($0)\($0)" }.joined()
        }
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return trimmed }
        let channels = [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF]
        let lightened = channels.map { channel -> UInt32 in
            let raw = Double(channel)
            // 上游 colorGradient 每一档都走 Math.round，不是截断。
            return UInt32(((255 - raw) * ratio + raw).rounded())
        }
        return "#" + lightened.map { String(format: "%02x", $0) }.joined()
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
        let inactive = UPColor.parse(otherBorderColor, theme: theme)
        let resolvedMode = Self.resolvedMode(mode)

        return Group {
            switch resolvedMode {
            case "circle":
                // 上游 circle：四边都有边框，上边取 color、其余三边取 otherBorderColor。
                ZStack {
                    Circle()
                        .stroke(inactive, lineWidth: UPConfig.loadingIcon.borderWidth)
                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(activeColor,
                                style: StrokeStyle(lineWidth: UPConfig.loadingIcon.borderWidth, lineCap: .butt))
                }
            case "semicircle":
                // 上游 semicircle：`border-color: transparent` + 只有上边取 color，
                // 视觉上就是四分之一圈弧。
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(activeColor,
                            style: StrokeStyle(lineWidth: UPConfig.loadingIcon.borderWidth, lineCap: .butt))
            default:
                spinnerDots(activeColor)
            }
        }
        .frame(width: max(0, size), height: max(0, size))
        .rotationEffect(.degrees(rotation))
        .onAppear(perform: startRotation)
        .onChange(of: timingFunction) { _, _ in startRotation() }
        .onChange(of: duration) { _, _ in startRotation() }
        .onChange(of: mode) { _, _ in startRotation() }
    }

    /// 上游 spinner 模式：12 个绝对定位的 `__dot`，第 i 个转 `i * 30°`、
    /// 透明度 `1 - 0.0625 * (i - 1)`，每个点内是一根 2px 宽、25% 高的小竖条。
    private func spinnerDots(_ activeColor: Color) -> some View {
        ZStack {
            ForEach(Array(0..<UPConfig.loadingIcon.spinnerDotCount), id: \.self) { index in
                Capsule()
                    .fill(activeColor)
                    .frame(width: UPConfig.loadingIcon.spinnerDotWidth,
                           height: max(0, size) * UPConfig.loadingIcon.spinnerDotHeightRatio)
                    .opacity(Self.dotOpacity(at: index))
                    .offset(y: -max(0, size) / 2 + max(0, size) * UPConfig.loadingIcon.spinnerDotHeightRatio / 2)
                    .rotationEffect(.degrees(Double(index + 1) * UPConfig.loadingIcon.spinnerDotStep))
            }
        }
    }

    /// 上游 `opacity: 1 - 0.0625 * ($i - 1)`（`$i` 从 1 数到 12）。
    nonisolated static func dotOpacity(at index: Int) -> Double {
        max(0, 1 - UPConfig.loadingIcon.spinnerDotOpacityStep * Double(index))
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

    /// 上游 `.__spinner` 的 CSS 动画是固定 `1s linear infinite`，
    /// 只有 circle / semicircle 会通过内联 style 换成 `duration` + `timingFunction`
    /// （`animation-timing-function` 那行三元判定就是这么写的）。
    public var rotationAnimation: Animation {
        let mode = Self.resolvedMode(self.mode)
        guard mode == "circle" || mode == "semicircle" else {
            return .linear(duration: UPConfig.loadingIcon.spinnerRotationDuration / 1_000)
        }
        return Self.animation(for: timingFunction, duration: duration)
    }

    private func startRotation() {
        rotation = 0
        withAnimation(rotationAnimation.repeatForever(autoreverses: false)) {
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
