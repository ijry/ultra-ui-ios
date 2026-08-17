import Foundation
import SwiftUI

/// Semantic alias for the `String | Number` `time` prop accepted by
/// uview-plus `u-count-down`.
public typealias UPCountDownTimeValue = UPCheckboxUnitValue

/// The largest finite `Double` that can safely be converted to Swift `Int`.
/// `Double(Int.max)` rounds up to 2^63 on 64-bit platforms, which would trap
/// during `Int` conversion, so the preceding representable value is required.
private let upCountDownMaximumMilliseconds = Double(Int.max).nextDown

/// Remaining calendar-style units exposed by uview-plus `u-count-down` to its
/// default slot and `change` event.
public struct UPCountDownTimeData: Equatable, Sendable {
    public let days: Int
    public let hours: Int
    public let minutes: Int
    public let seconds: Int
    public let milliseconds: Int

    public static let zero = UPCountDownTimeData(
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
        milliseconds: 0
    )

    public init(
        days: Int,
        hours: Int,
        minutes: Int,
        seconds: Int,
        milliseconds: Int
    ) {
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.milliseconds = milliseconds
    }

    /// Mirrors uview-plus `parseTimeData`: negative and non-finite values are
    /// treated as zero, and every unit below days is kept within its natural
    /// range.
    public init(milliseconds totalMilliseconds: Double) {
        let safeMilliseconds: Double
        if totalMilliseconds.isFinite {
            safeMilliseconds = min(max(totalMilliseconds, 0).rounded(.down), upCountDownMaximumMilliseconds)
        } else {
            safeMilliseconds = 0
        }

        let total = Int(safeMilliseconds)
        let second = 1_000
        let minute = 60 * second
        let hour = 60 * minute
        let day = 24 * hour

        days = total / day
        hours = (total % day) / hour
        minutes = (total % hour) / minute
        seconds = (total % minute) / second
        milliseconds = total % second
    }
}

/// Stateful controller corresponding to the uview-plus component instance
/// methods: `start`, `pause`, and `reset`.
@MainActor
public final class UPCountDownController: ObservableObject {
    @Published public private(set) var timeData: UPCountDownTimeData
    @Published public private(set) var formattedTime: String
    @Published public private(set) var isRunning = false
    @Published public private(set) var remainingTime: Double

    private var sourceTime: Double
    private var format: String
    private var autoStart: Bool
    private var millisecond: Bool
    private var endTime: Date?
    private var ticker: Task<Void, Never>?
    private var finishDelivered = false
    private var initialActivationPending: Bool
    private var onChangeHandler: ((UPCountDownTimeData) -> Void)?
    private var onFinishHandler: (() -> Void)?

    public convenience init(
        time: some UPCountDownTimeValue = UPConfig.countDown.time,
        format: String = UPConfig.countDown.format,
        autoStart: Bool = UPConfig.countDown.autoStart,
        millisecond: Bool = UPConfig.countDown.millisecond,
        onChange: ((UPCountDownTimeData) -> Void)? = nil,
        onFinish: (() -> Void)? = nil
    ) {
        self.init(
            time: time.upCheckboxUnitValue,
            format: format,
            autoStart: autoStart,
            millisecond: millisecond,
            onChange: onChange,
            onFinish: onFinish,
            deferredInitialActivation: false
        )
    }

    /// Creates the controller used by ``UPCountDown`` itself. Its initial
    /// change/finish delivery is delayed until the SwiftUI view appears, so
    /// event modifiers can be installed before uview-plus' mounted lifecycle
    /// begins.
    fileprivate init(
        time: String,
        format: String,
        autoStart: Bool,
        millisecond: Bool,
        onChange: ((UPCountDownTimeData) -> Void)? = nil,
        onFinish: (() -> Void)? = nil,
        deferredInitialActivation: Bool
    ) {
        let milliseconds = Self.parseMilliseconds(time)
        self.sourceTime = milliseconds
        self.format = format
        self.autoStart = autoStart
        self.millisecond = millisecond
        let initialTimeData = UPCountDownTimeData(milliseconds: milliseconds)
        self.remainingTime = milliseconds
        self.timeData = initialTimeData
        self.formattedTime = UPCountDown.formattedTime(initialTimeData, format: format)
        self.initialActivationPending = true
        self.onChangeHandler = onChange
        self.onFinishHandler = onFinish

        if !deferredInitialActivation {
            activateIfNeeded()
        }
    }

    deinit {
        ticker?.cancel()
    }

    /// Starts the countdown from its current remaining duration.
    public func start() {
        start(at: Date())
    }

    /// Pauses the scheduled native tick without changing the current duration.
    public func pause() {
        initialActivationPending = false
        isRunning = false
        endTime = nil
        cancelTicker()
    }

    /// Restores the configured `time` prop and starts again when `autoStart` is true.
    public func reset() {
        reset(at: Date())
    }

    /// Applies the latest SwiftUI props. Changing `time` follows the upstream
    /// watcher and invokes `reset`; changing `format` only reformats the
    /// existing remaining duration.
    func configure(
        time: String,
        format: String,
        autoStart: Bool,
        millisecond: Bool
    ) {
        let nextSourceTime = Self.parseMilliseconds(time)
        let timeChanged = nextSourceTime != sourceTime
        let formatChanged = format != self.format
        let millisecondChanged = millisecond != self.millisecond

        self.format = format
        self.autoStart = autoStart
        self.millisecond = millisecond

        if timeChanged {
            sourceTime = nextSourceTime
            reset()
        } else if formatChanged {
            formattedTime = UPCountDown.formattedTime(timeData, format: format)
        }

        if millisecondChanged, isRunning {
            scheduleNextTick()
        }
    }

    /// Sets the SwiftUI counterpart of the uview-plus `change` event handler.
    func setOnChangeHandler(_ handler: ((UPCountDownTimeData) -> Void)?) {
        onChangeHandler = handler
    }

    /// Sets the SwiftUI counterpart of the uview-plus `finish` event handler.
    func setOnFinishHandler(_ handler: (() -> Void)?) {
        onFinishHandler = handler
    }

    /// Runs the initial mounted lifecycle once. It is intentionally internal:
    /// applications use the public instance methods, while ``UPCountDown``
    /// invokes this from `onAppear`.
    func activateIfNeeded() {
        guard initialActivationPending else { return }
        initialActivationPending = false
        notifyChange()

        if remainingTime == 0 {
            deliverFinishIfNeeded()
        } else if autoStart {
            begin(at: Date())
        }
    }

    func start(at date: Date) {
        if initialActivationPending {
            initialActivationPending = false
            notifyChange()
        }

        guard !isRunning, remainingTime > 0 else {
            if remainingTime == 0 {
                deliverFinishIfNeeded()
            }
            return
        }

        begin(at: date)
    }

    func reset(at date: Date) {
        pause()
        finishDelivered = false
        setRemainingTime(sourceTime)

        if remainingTime == 0 {
            deliverFinishIfNeeded()
        } else if autoStart {
            begin(at: date)
        }
    }

    func tick(at date: Date) {
        guard isRunning, let endTime else { return }
        let nextRemaining = max(endTime.timeIntervalSince(date) * 1_000, 0)

        if millisecond || !Self.isSameSecond(nextRemaining, remainingTime) || nextRemaining == 0 {
            setRemainingTime(nextRemaining)
        }

        if nextRemaining == 0 {
            pause()
            deliverFinishIfNeeded()
        } else {
            scheduleNextTick()
        }
    }

    private func begin(at date: Date) {
        isRunning = true
        endTime = date.addingTimeInterval(remainingTime / 1_000)
        scheduleNextTick()
    }

    private func tick() {
        tick(at: Date())
    }

    private func setRemainingTime(_ nextRemaining: Double) {
        remainingTime = Self.sanitizedMilliseconds(nextRemaining)
        timeData = UPCountDownTimeData(milliseconds: remainingTime)
        formattedTime = UPCountDown.formattedTime(timeData, format: format)
        notifyChange()
    }

    private func notifyChange() {
        onChangeHandler?(timeData)
    }

    private func deliverFinishIfNeeded() {
        guard !finishDelivered else { return }
        finishDelivered = true
        onFinishHandler?()
    }

    private func scheduleNextTick() {
        cancelTicker()
        let delay: UInt64 = millisecond ? 50_000_000 : 30_000_000
        ticker = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            self?.tick()
        }
    }

    private func cancelTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private static func parseMilliseconds(_ raw: String) -> Double {
        guard let value = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)) else { return 0 }
        return sanitizedMilliseconds(value)
    }

    private static func sanitizedMilliseconds(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), upCountDownMaximumMilliseconds)
    }

    private static func isSameSecond(_ lhs: Double, _ rhs: Double) -> Bool {
        Int(lhs / 1_000) == Int(rhs / 1_000)
    }
}

/// Native SwiftUI counterpart of uview-plus `u-count-down`.
///
/// The trailing SwiftUI builder is the upstream default slot. It receives the
/// same `days`, `hours`, `minutes`, `seconds`, and `milliseconds` values as the
/// uview-plus slot scope. Without a slot, the component renders its formatted
/// default text.
@MainActor
public struct UPCountDown: View {
    var time: String
    var format: String
    var autoStart: Bool
    var millisecond: Bool
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no CSS-class analogue.
    var customClass: String
    var customStyle: UPStyle
    private var defaultSlotContent: ((UPCountDownTimeData) -> AnyView)?
    private var onChangeHandler: ((UPCountDownTimeData) -> Void)?
    private var onFinishHandler: (() -> Void)?

    @StateObject private var stateController: UPCountDownController

    /// The native instance-control object that exposes `start`, `pause`, and
    /// `reset`, mirroring the methods available through a uview-plus component
    /// ref.
    public var controller: UPCountDownController {
        stateController
    }

    /// The current upstream-compatible formatted fallback text.
    public var displayText: String {
        stateController.formattedTime
    }

    public init(
        time: some UPCountDownTimeValue = UPConfig.countDown.time,
        format: String = UPConfig.countDown.format,
        autoStart: Bool = UPConfig.countDown.autoStart,
        millisecond: Bool = UPConfig.countDown.millisecond,
        customClass: String = UPConfig.countDown.customClass,
        customStyle: UPStyle = UPConfig.countDown.customStyle,
        controller: UPCountDownController? = nil
    ) {
        self.init(
            time: time.upCheckboxUnitValue,
            format: format,
            autoStart: autoStart,
            millisecond: millisecond,
            customClass: customClass,
            customStyle: customStyle,
            controller: controller,
            defaultSlotContent: nil
        )
    }

    /// Maps the uview-plus default slot to content that receives the latest
    /// countdown time data.
    public init<Content: View>(
        time: some UPCountDownTimeValue = UPConfig.countDown.time,
        format: String = UPConfig.countDown.format,
        autoStart: Bool = UPConfig.countDown.autoStart,
        millisecond: Bool = UPConfig.countDown.millisecond,
        customClass: String = UPConfig.countDown.customClass,
        customStyle: UPStyle = UPConfig.countDown.customStyle,
        controller: UPCountDownController? = nil,
        @ViewBuilder content: @escaping (UPCountDownTimeData) -> Content
    ) {
        self.init(
            time: time.upCheckboxUnitValue,
            format: format,
            autoStart: autoStart,
            millisecond: millisecond,
            customClass: customClass,
            customStyle: customStyle,
            controller: controller,
            defaultSlotContent: { AnyView(content($0)) }
        )
    }

    private init(
        time: String,
        format: String,
        autoStart: Bool,
        millisecond: Bool,
        customClass: String,
        customStyle: UPStyle,
        controller: UPCountDownController?,
        defaultSlotContent: ((UPCountDownTimeData) -> AnyView)?
    ) {
        self.time = time
        self.format = format
        self.autoStart = autoStart
        self.millisecond = millisecond
        self.customClass = customClass
        self.customStyle = customStyle
        self.defaultSlotContent = defaultSlotContent
        self.onChangeHandler = nil
        self.onFinishHandler = nil

        let activeController = controller ?? UPCountDownController(
            time: time,
            format: format,
            autoStart: autoStart,
            millisecond: millisecond,
            deferredInitialActivation: true
        )
        _stateController = StateObject(wrappedValue: activeController)
    }

    public var body: some View {
        Group {
            if let defaultSlotContent {
                defaultSlotContent(stateController.timeData)
            } else {
                Text(stateController.formattedTime)
                    .font(.system(size: 15))
                    .foregroundStyle(UPColor.parse("#606266"))
                    .frame(minHeight: 22)
            }
        }
        .upStyle(customStyle)
        .onAppear(perform: synchronizeController)
        .onChange(of: configurationSignature) { _, _ in
            synchronizeController()
        }
    }

    /// Formats countdown units with the same token roll-up rules as
    /// uview-plus `parseFormat` (`DD`, `HH`, `mm`, `ss`, and `SSS`).
    public nonisolated static func formattedTime(_ timeData: UPCountDownTimeData, format: String) -> String {
        var formatted = format
        let days = timeData.days
        var hours = timeData.hours
        var minutes = timeData.minutes
        var seconds = timeData.seconds
        var milliseconds = timeData.milliseconds

        if formatted.contains("DD") {
            formatted = replacingFirstOccurrence(in: formatted, of: "DD", with: padded(days))
        } else {
            hours += days * 24
        }

        if formatted.contains("HH") {
            formatted = replacingFirstOccurrence(in: formatted, of: "HH", with: padded(hours))
        } else {
            minutes += hours * 60
        }

        if formatted.contains("mm") {
            formatted = replacingFirstOccurrence(in: formatted, of: "mm", with: padded(minutes))
        } else {
            seconds += minutes * 60
        }

        if formatted.contains("ss") {
            formatted = replacingFirstOccurrence(in: formatted, of: "ss", with: padded(seconds))
        } else {
            milliseconds += seconds * 1_000
        }

        return replacingFirstOccurrence(in: formatted, of: "SSS", with: padded(milliseconds, length: 3))
    }

    private var configurationSignature: String {
        [
            time,
            format,
            autoStart ? "1" : "0",
            millisecond ? "1" : "0"
        ].joined(separator: "\u{1F}")
    }

    private func synchronizeController() {
        if let onChangeHandler {
            stateController.setOnChangeHandler(onChangeHandler)
        }
        if let onFinishHandler {
            stateController.setOnFinishHandler(onFinishHandler)
        }
        stateController.configure(
            time: time,
            format: format,
            autoStart: autoStart,
            millisecond: millisecond
        )
        stateController.activateIfNeeded()
    }

    private nonisolated static func padded(_ value: Int, length: Int = 2) -> String {
        let raw = String(value)
        guard raw.count < length else { return raw }
        return String(repeating: "0", count: length - raw.count) + raw
    }

    private nonisolated static func replacingFirstOccurrence(
        in source: String,
        of token: String,
        with replacement: String
    ) -> String {
        guard let range = source.range(of: token) else { return source }
        return source.replacingCharacters(in: range, with: replacement)
    }
}

public extension UPCountDown {
    /// Registers the uview-plus `change` event callback.
    func onChange(_ action: @escaping (UPCountDownTimeData) -> Void) -> UPCountDown {
        var copy = self
        copy.onChangeHandler = action
        copy.controller.setOnChangeHandler(action)
        return copy
    }

    /// Registers the uview-plus `finish` event callback.
    func onFinish(_ action: @escaping () -> Void) -> UPCountDown {
        var copy = self
        copy.onFinishHandler = action
        copy.controller.setOnFinishHandler(action)
        return copy
    }
}
