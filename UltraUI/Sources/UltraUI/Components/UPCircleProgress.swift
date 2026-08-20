import SwiftUI

/// Semantic alias for the String-or-Number `percentage` prop accepted by
/// uview-plus `u-circle-progress`.
public typealias UPCircleProgressValue = UPCheckboxUnitValue

/// Native SwiftUI counterpart of uview-plus `u-circle-progress`.
///
/// The upstream component currently exposes only `percentage`, plus the
/// shared `customClass` and `customStyle` props. SwiftUI's `Circle.trim`
/// provides the native progress-ring implementation while retaining that
/// compatibility surface.
@MainActor
public struct UPCircleProgress: View {
    public let percentage: String
    public let customClass: String
    public let customStyle: UPStyle

    /// Percentage normalized to the documented 0...100 range.
    public var resolvedPercentage: Double {
        Self.resolvePercentage(percentage)
    }

    /// SwiftUI trim fraction corresponding to ``resolvedPercentage``.
    public var progressFraction: Double {
        resolvedPercentage / 100
    }

    /// Native diameter. The upstream component is 100px square; an explicit
    /// customStyle width or height replaces that fixed dimension.
    public var resolvedDiameter: CGFloat {
        max(customStyle.width ?? customStyle.height ?? 100, 0)
    }

    /// Ring width mirrored from the upstream component's 5px borders.
    public var resolvedLineWidth: CGFloat { 5 }

    public init(
        percentage: some UPCircleProgressValue = UPConfig.circleProgress.percentage,
        customClass: String = UPConfig.circleProgress.customClass,
        customStyle: UPStyle = UPConfig.circleProgress.customStyle
    ) {
        self.percentage = percentage.upCheckboxUnitValue
        self.customClass = customClass
        self.customStyle = customStyle
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(red: 200 / 255, green: 200 / 255, blue: 200 / 255),
                    lineWidth: resolvedLineWidth
                )

            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(
                    Color(red: 66 / 255, green: 185 / 255, blue: 131 / 255),
                    style: StrokeStyle(lineWidth: resolvedLineWidth, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progressFraction)
        }
        .padding(resolvedLineWidth / 2)
        .frame(width: resolvedDiameter, height: resolvedDiameter)
        .upStyle(customStyle)
    }

    nonisolated static func resolvePercentage(_ raw: String) -> Double {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(normalized), value.isFinite else {
            return Double(UPCircleProgressConfig.percentage)
        }
        return min(max(value, 0), 100)
    }
}
