import Foundation
import SwiftUI

/// Semantic alias for the `String | Number` props accepted by uview-plus
/// `u-count-to`.
public typealias UPCountToValue = UPCheckboxUnitValue

/// Stateful controller corresponding to the uview-plus component instance
/// methods: `start`, `reStart`, `stop`, `resume`, and `reset`.
@MainActor
public final class UPCountToController: ObservableObject {
    /// The current animated numeric value before decimal/group formatting.
    @Published public private(set) var value: Double
    /// The value rendered by the native text view, equivalent to the upstream
    /// component's `displayValue` data field.
    @Published public private(set) var displayValue: String
    @Published public private(set) var isRunning = false
    @Published public private(set) var isPaused = false
    /// Remaining duration of the active or paused local animation, in
    /// milliseconds.
    @Published public private(set) var remainingTime: Double

    private var startValue: Double
    private var endValue: Double
    private var sourceDuration: Double
    private var autoplay: Bool
    private var decimalPlaces: Int
    private var useEasing: Bool
    private var decimalSeparator: String
    private var groupingSeparator: String

    private var localStartValue: Double
    private var localDuration: Double
    private var startedAt: Date?
    private var ticker: Task<Void, Never>?
    private var endDelivered = false
    private var initialActivationPending: Bool
    private var onEndHandler: (() -> Void)?

    public convenience init(
        startVal: some UPCountToValue = UPConfig.countTo.startVal,
        endVal: some UPCountToValue = UPConfig.countTo.endVal,
        duration: some UPCountToValue = UPConfig.countTo.duration,
        autoplay: Bool = UPConfig.countTo.autoplay,
        decimals: some UPCountToValue = UPConfig.countTo.decimals,
        useEasing: Bool = UPConfig.countTo.useEasing,
        decimal: some UPCountToValue = UPConfig.countTo.decimal,
        separator: String = UPConfig.countTo.separator,
        onEnd: (() -> Void)? = nil
    ) {
        self.init(
            startVal: startVal.upCheckboxUnitValue,
            endVal: endVal.upCheckboxUnitValue,
            duration: duration.upCheckboxUnitValue,
            autoplay: autoplay,
            decimals: decimals.upCheckboxUnitValue,
            useEasing: useEasing,
            decimal: decimal.upCheckboxUnitValue,
            separator: separator,
            onEnd: onEnd,
            deferredInitialActivation: false
        )
    }

    /// Creates the controller held by ``UPCountTo``. The automatic first run is
    /// deferred until the SwiftUI view appears, allowing `.onEnd` to register
    /// before an immediate zero-duration animation can finish.
    fileprivate init(
        startVal: String,
        endVal: String,
        duration: String,
        autoplay: Bool,
        decimals: String,
        useEasing: Bool,
        decimal: String,
        separator: String,
        onEnd: (() -> Void)? = nil,
        deferredInitialActivation: Bool
    ) {
        let initialStartValue = Self.parseNumber(startVal)
        let initialEndValue = Self.parseNumber(endVal)
        let initialDuration = Self.parseDuration(duration)
        let initialDecimalPlaces = Self.parseDecimalPlaces(decimals)

        self.startValue = initialStartValue
        self.endValue = initialEndValue
        self.sourceDuration = initialDuration
        self.autoplay = autoplay
        self.decimalPlaces = initialDecimalPlaces
        self.useEasing = useEasing
        self.decimalSeparator = decimal
        self.groupingSeparator = separator
        self.localStartValue = initialStartValue
        self.localDuration = initialDuration
        self.value = initialStartValue
        self.displayValue = UPCountTo.formattedValue(
            initialStartValue,
            decimals: initialDecimalPlaces,
            decimal: decimal,
            separator: separator
        )
        self.remainingTime = initialDuration
        self.initialActivationPending = true
        self.onEndHandler = onEnd

        if !deferredInitialActivation {
            activateIfNeeded()
        }
    }

    deinit {
        ticker?.cancel()
    }

    /// Starts a fresh animation from `startVal` to `endVal`.
    public func start() {
        start(at: Date())
    }

    /// Toggles between the upstream paused state and resuming the currently
    /// remaining animation.
    public func reStart() {
        reStart(at: Date())
    }

    /// Stops the current animation while preserving its latest value and
    /// remaining duration.
    public func stop() {
        isRunning = false
        startedAt = nil
        cancelTicker()
    }

    /// Resumes the remaining animation from its latest rendered value.
    public func resume() {
        resume(at: Date())
    }

    /// Cancels animation and restores the formatted `startVal`; as in
    /// uview-plus, `reset` does not automatically start a new run.
    public func reset() {
        initialActivationPending = false
        stop()
        isPaused = false
        endDelivered = false
        localStartValue = startValue
        localDuration = sourceDuration
        remainingTime = sourceDuration
        setValue(startValue)
    }

    /// Applies the latest SwiftUI props. This mirrors the upstream watchers:
    /// changing `startVal` or `endVal` restarts when `autoplay` is enabled;
    /// display-format changes reformat the current number immediately.
    func configure(
        startVal: String,
        endVal: String,
        duration: String,
        autoplay: Bool,
        decimals: String,
        useEasing: Bool,
        decimal: String,
        separator: String
    ) {
        let nextStartValue = Self.parseNumber(startVal)
        let nextEndValue = Self.parseNumber(endVal)
        let nextDuration = Self.parseDuration(duration)
        let nextDecimalPlaces = Self.parseDecimalPlaces(decimals)
        let rangeChanged = nextStartValue != self.startValue || nextEndValue != self.endValue
        let presentationChanged = nextDecimalPlaces != decimalPlaces
            || decimal != decimalSeparator
            || separator != groupingSeparator

        self.startValue = nextStartValue
        self.endValue = nextEndValue
        self.sourceDuration = nextDuration
        self.autoplay = autoplay
        self.decimalPlaces = nextDecimalPlaces
        self.useEasing = useEasing
        self.decimalSeparator = decimal
        self.groupingSeparator = separator

        if rangeChanged {
            endDelivered = false
            if autoplay {
                start()
            }
        } else if presentationChanged {
            setValue(value)
        }
    }

    /// Sets the SwiftUI counterpart of uview-plus' `end` event listener.
    func setOnEndHandler(_ handler: (() -> Void)?) {
        onEndHandler = handler
    }

    /// Runs the delayed mounted lifecycle once. It is internal because SwiftUI
    /// invokes it from ``UPCountTo``'s `onAppear`; application code uses the
    /// public instance methods instead.
    func activateIfNeeded() {
        guard initialActivationPending else { return }
        initialActivationPending = false
        guard autoplay else { return }
        start()
    }

    func start(at date: Date) {
        initialActivationPending = false
        endDelivered = false
        isPaused = false
        begin(
            from: startValue,
            duration: sourceDuration,
            at: date
        )
    }

    func reStart(at date: Date) {
        if isPaused {
            resume(at: date)
            isPaused = false
        } else {
            stop()
            isPaused = true
        }
    }

    func resume(at date: Date) {
        guard remainingTime > 0 else { return }
        begin(
            from: value,
            duration: remainingTime,
            at: date
        )
    }

    func tick(at date: Date) {
        guard isRunning, let startedAt else { return }

        let progress = min(
            max(date.timeIntervalSince(startedAt) * 1_000, 0),
            localDuration
        )
        let delta = endValue - localStartValue
        let nextValue: Double
        if useEasing {
            nextValue = Self.easingValue(
                time: progress,
                initialValue: localStartValue,
                change: delta,
                duration: localDuration
            )
        } else {
            let progressFraction = localDuration > 0 ? progress / localDuration : 1
            nextValue = localStartValue + delta * progressFraction
        }

        let boundedValue: Double
        if localStartValue > endValue {
            boundedValue = max(nextValue, endValue)
        } else {
            boundedValue = min(nextValue, endValue)
        }
        setValue(boundedValue)
        remainingTime = max(localDuration - progress, 0)

        if progress >= localDuration {
            isRunning = false
            isPaused = false
            self.startedAt = nil
            cancelTicker()
            setValue(endValue)
            deliverEndIfNeeded()
        } else {
            scheduleNextTick()
        }
    }

    /// The exact exponential easing formula used by uview-plus' `countTo`.
    nonisolated static func easingValue(
        time: Double,
        initialValue: Double,
        change: Double,
        duration: Double
    ) -> Double {
        guard duration > 0 else { return initialValue + change }
        return (change * (-pow(2, (-10 * time) / duration) + 1) * 1_024) / 1_023 + initialValue
    }

    private func begin(from initialValue: Double, duration: Double, at date: Date) {
        cancelTicker()
        localStartValue = initialValue
        localDuration = duration
        remainingTime = duration
        setValue(initialValue)

        guard duration > 0 else {
            isRunning = false
            isPaused = false
            startedAt = nil
            setValue(endValue)
            deliverEndIfNeeded()
            return
        }

        isRunning = true
        startedAt = date
        scheduleNextTick()
    }

    private func setValue(_ nextValue: Double) {
        value = nextValue.isFinite ? nextValue : 0
        displayValue = UPCountTo.formattedValue(
            value,
            decimals: decimalPlaces,
            decimal: decimalSeparator,
            separator: groupingSeparator
        )
    }

    private func deliverEndIfNeeded() {
        guard !endDelivered else { return }
        endDelivered = true
        onEndHandler?()
    }

    private func scheduleNextTick() {
        cancelTicker()
        ticker = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 16_000_000)
            guard !Task.isCancelled else { return }
            self?.tick(at: Date())
        }
    }

    private func cancelTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private nonisolated static func parseNumber(_ raw: String) -> Double {
        guard let value = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)), value.isFinite else {
            return 0
        }
        return value
    }

    private nonisolated static func parseDuration(_ raw: String) -> Double {
        max(parseNumber(raw), 0)
    }

    private nonisolated static func parseDecimalPlaces(_ raw: String) -> Int {
        let value = parseNumber(raw).rounded(.towardZero)
        guard value > 0 else { return 0 }
        // JavaScript `toFixed` allows at most 100 fraction digits. Clamping
        // before converting avoids an integer-overflow trap for huge inputs.
        return Int(min(value, 100))
    }
}

/// Native SwiftUI counterpart of uview-plus `u-count-to`.
///
/// The SwiftUI wrapper maps the upstream props and `end` event, while
/// ``UPCountToController`` exposes the ref-style animation methods.
@MainActor
public struct UPCountTo: View {
    public var startVal: String
    public var endVal: String
    public var duration: String
    public var autoplay: Bool
    public var decimals: String
    public var useEasing: Bool
    public var decimal: String
    public var color: String
    public var fontSize: String
    public var bold: Bool
    public var separator: String
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no
    /// direct CSS class equivalent.
    public var customClass: String
    public var customStyle: UPStyle

    private var onEndHandler: (() -> Void)?
    @StateObject private var stateController: UPCountToController

    /// The native instance-control object corresponding to a uview-plus
    /// component ref.
    public var controller: UPCountToController {
        stateController
    }

    /// The current text rendered by the component.
    public var displayValue: String {
        stateController.displayValue
    }

    /// Resolves the upstream string-or-number `fontSize` prop to native points.
    public var resolvedFontSize: CGFloat {
        UPUnit.parse(fontSize)
    }

    public init(
        startVal: some UPCountToValue = UPConfig.countTo.startVal,
        endVal: some UPCountToValue = UPConfig.countTo.endVal,
        duration: some UPCountToValue = UPConfig.countTo.duration,
        autoplay: Bool = UPConfig.countTo.autoplay,
        decimals: some UPCountToValue = UPConfig.countTo.decimals,
        useEasing: Bool = UPConfig.countTo.useEasing,
        decimal: some UPCountToValue = UPConfig.countTo.decimal,
        color: String = UPConfig.countTo.color,
        fontSize: some UPCountToValue = UPConfig.countTo.fontSize,
        bold: Bool = UPConfig.countTo.bold,
        separator: String = UPConfig.countTo.separator,
        customClass: String = UPConfig.countTo.customClass,
        customStyle: UPStyle = UPConfig.countTo.customStyle,
        controller: UPCountToController? = nil
    ) {
        let startVal = startVal.upCheckboxUnitValue
        let endVal = endVal.upCheckboxUnitValue
        let duration = duration.upCheckboxUnitValue
        let decimals = decimals.upCheckboxUnitValue
        let decimal = decimal.upCheckboxUnitValue
        let fontSize = fontSize.upCheckboxUnitValue

        self.startVal = startVal
        self.endVal = endVal
        self.duration = duration
        self.autoplay = autoplay
        self.decimals = decimals
        self.useEasing = useEasing
        self.decimal = decimal
        self.color = color
        self.fontSize = fontSize
        self.bold = bold
        self.separator = separator
        self.customClass = customClass
        self.customStyle = customStyle
        self.onEndHandler = nil

        let activeController = controller ?? UPCountToController(
            startVal: startVal,
            endVal: endVal,
            duration: duration,
            autoplay: autoplay,
            decimals: decimals,
            useEasing: useEasing,
            decimal: decimal,
            separator: separator,
            deferredInitialActivation: true
        )
        _stateController = StateObject(wrappedValue: activeController)
    }

    public var body: some View {
        Text(stateController.displayValue)
            .font(.system(size: resolvedFontSize, weight: bold ? .bold : .regular))
            .foregroundStyle(UPColor.parse(color))
            .multilineTextAlignment(.center)
            .upStyle(customStyle)
            .onAppear(perform: synchronizeController)
            .onChange(of: configurationSignature) { _, _ in
                synchronizeController()
            }
    }

    /// Formats a numeric value with the same fixed-decimal and optional
    /// thousands-separator rules as the upstream `formatNumber` method.
    public nonisolated static func formattedValue(
        _ value: Double,
        decimals: Int,
        decimal: String,
        separator: String
    ) -> String {
        guard value.isFinite else { return "0" }

        let safeDecimals = min(max(decimals, 0), 100)
        let fixed = String(
            format: "%.\(safeDecimals)f",
            locale: Locale(identifier: "en_US_POSIX"),
            value
        )
        let parts = fixed.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        var integerPart = parts.map(String.init).first ?? "0"
        let fractionPart = parts.count > 1 ? String(parts[1]) : ""

        if shouldApplyGrouping(separator) {
            let sign: String
            if integerPart.hasPrefix("-") {
                sign = "-"
                integerPart.removeFirst()
            } else {
                sign = ""
            }

            var grouped = ""
            for (offset, character) in integerPart.reversed().enumerated() {
                if offset > 0, offset.isMultiple(of: 3) {
                    grouped.insert(contentsOf: separator, at: grouped.startIndex)
                }
                grouped.insert(character, at: grouped.startIndex)
            }
            integerPart = sign + grouped
        }

        guard safeDecimals > 0 else { return integerPart }
        return integerPart + decimal + fractionPart
    }

    private var configurationSignature: String {
        [
            startVal,
            endVal,
            duration,
            autoplay ? "1" : "0",
            decimals,
            useEasing ? "1" : "0",
            decimal,
            separator
        ].joined(separator: "\u{1F}")
    }

    private func synchronizeController() {
        if let onEndHandler {
            stateController.setOnEndHandler(onEndHandler)
        }
        stateController.configure(
            startVal: startVal,
            endVal: endVal,
            duration: duration,
            autoplay: autoplay,
            decimals: decimals,
            useEasing: useEasing,
            decimal: decimal,
            separator: separator
        )
        stateController.activateIfNeeded()
    }

    private nonisolated static func shouldApplyGrouping(_ separator: String) -> Bool {
        guard !separator.isEmpty else { return false }
        return Double(separator.trimmingCharacters(in: .whitespacesAndNewlines)) == nil
    }
}

public extension UPCountTo {
    /// Registers the uview-plus `end` event callback.
    func onEnd(_ action: @escaping () -> Void) -> UPCountTo {
        var copy = self
        copy.onEndHandler = action
        copy.controller.setOnEndHandler(action)
        return copy
    }
}
