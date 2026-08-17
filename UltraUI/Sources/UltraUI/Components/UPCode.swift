import Foundation
import SwiftUI

/// Semantic alias for the `String | Number` `seconds` prop accepted by
/// uview-plus `u-code`.
public typealias UPCodeSecondsValue = UPCheckboxUnitValue

/// Stateful native counterpart of a uview-plus `u-code` component instance.
///
/// The upstream component does not render the verification-code button itself;
/// it owns the countdown and emits the text that a surrounding button or label
/// should display. This controller keeps that same separation for SwiftUI.
@MainActor
public final class UPCodeController: ObservableObject {
    private static let storageSuffix = "_$uCountDownTimestamp"

    @Published public private(set) var secondsRemaining: Int
    @Published public private(set) var canGetCode: Bool
    @Published public private(set) var displayText: String
    @Published public private(set) var isRunning: Bool

    private var sourceSeconds: Int
    private var startText: String
    private var changeText: String
    private var endText: String
    private var keepRunning: Bool
    private var uniqueKey: String
    private let storage: UserDefaults
    private var endDate: Date?
    private var ticker: Task<Void, Never>?
    private var initialActivationPending: Bool

    private var onChangeHandler: ((String) -> Void)?
    private var onStartHandler: (() -> Void)?
    private var onEndHandler: (() -> Void)?

    /// Creates a controller for the upstream `u-code` props.
    public convenience init(
        seconds: some UPCodeSecondsValue = UPConfig.code.seconds,
        startText: String = UPConfig.code.startText,
        changeText: String = UPConfig.code.changeText,
        endText: String = UPConfig.code.endText,
        keepRunning: Bool = UPConfig.code.keepRunning,
        uniqueKey: String = UPConfig.code.uniqueKey,
        storage: UserDefaults = .standard,
        onChange: ((String) -> Void)? = nil,
        onStart: (() -> Void)? = nil,
        onEnd: (() -> Void)? = nil
    ) {
        self.init(
            seconds: seconds.upCheckboxUnitValue,
            startText: startText,
            changeText: changeText,
            endText: endText,
            keepRunning: keepRunning,
            uniqueKey: uniqueKey,
            storage: storage,
            onChange: onChange,
            onStart: onStart,
            onEnd: onEnd,
            deferredInitialActivation: false
        )
    }

    /// Creates the controller used by ``UPCode`` itself. Delaying mounted
    /// activation lets SwiftUI event modifiers install their callbacks first.
    init(
        seconds: some UPCodeSecondsValue = UPConfig.code.seconds,
        startText: String = UPConfig.code.startText,
        changeText: String = UPConfig.code.changeText,
        endText: String = UPConfig.code.endText,
        keepRunning: Bool = UPConfig.code.keepRunning,
        uniqueKey: String = UPConfig.code.uniqueKey,
        storage: UserDefaults = .standard,
        onChange: ((String) -> Void)? = nil,
        onStart: (() -> Void)? = nil,
        onEnd: (() -> Void)? = nil,
        deferredInitialActivation: Bool
    ) {
        let seconds = seconds.upCheckboxUnitValue
        sourceSeconds = Self.parseSeconds(seconds)
        self.startText = startText
        self.changeText = changeText
        self.endText = endText
        self.keepRunning = keepRunning
        self.uniqueKey = uniqueKey
        self.storage = storage
        self.endDate = nil
        self.ticker = nil
        self.initialActivationPending = true
        self.onChangeHandler = onChange
        self.onStartHandler = onStart
        self.onEndHandler = onEnd

        secondsRemaining = sourceSeconds
        canGetCode = true
        displayText = startText
        isRunning = false

        if !deferredInitialActivation {
            activateIfNeeded(at: Date(), schedule: true)
        }
    }

    deinit {
        ticker?.cancel()
    }

    /// Starts the countdown using the current wall-clock time.
    public func start() {
        start(at: Date(), schedule: true)
    }

    /// Resets the countdown and emits the upstream `endText` change event.
    public func reset() {
        resetState()
        emitChange(endText)
    }

    /// Runs the mounted lifecycle using the current wall-clock time.
    func activateIfNeeded() {
        activateIfNeeded(at: Date(), schedule: true)
    }

    /// Persists the expected Unix end timestamp when `keepRunning` is enabled.
    func persistRunningState() {
        persistRunningState(at: Date())
    }

    /// Mirrors the upstream unmount behavior: save the expected end time,
    /// cancel the active timer, and allow a later appearance to check storage
    /// again.
    func deactivate() {
        deactivate(at: Date())
    }

    /// Installs the SwiftUI counterpart of the upstream `change` event.
    func setOnChangeHandler(_ handler: ((String) -> Void)?) {
        onChangeHandler = handler
    }

    /// Installs the SwiftUI counterpart of the upstream `start` event.
    func setOnStartHandler(_ handler: (() -> Void)?) {
        onStartHandler = handler
    }

    /// Installs the SwiftUI counterpart of the upstream `end` event.
    func setOnEndHandler(_ handler: (() -> Void)?) {
        onEndHandler = handler
    }

    /// Applies the current SwiftUI props without starting a new countdown.
    /// Changing `seconds` follows the upstream watcher and resets the internal
    /// remaining count; text and persistence props are updated for subsequent
    /// events.
    func configure(
        seconds: String,
        startText: String,
        changeText: String,
        endText: String,
        keepRunning: Bool,
        uniqueKey: String
    ) {
        let nextSourceSeconds = Self.parseSeconds(seconds)
        if nextSourceSeconds != sourceSeconds {
            sourceSeconds = nextSourceSeconds
            secondsRemaining = nextSourceSeconds
        }

        self.startText = startText
        self.changeText = changeText
        self.endText = endText
        self.keepRunning = keepRunning
        self.uniqueKey = uniqueKey
    }

    /// Deterministic test/host entry point matching one elapsed wall-clock
    /// second. It intentionally does not create a native task; ``start()`` is
    /// the production entry point that schedules real ticks.
    func start(at date: Date) {
        start(at: date, schedule: false)
    }

    /// Deterministically runs the mounted lifecycle at a supplied timestamp.
    func activateIfNeeded(at date: Date) {
        activateIfNeeded(at: date, schedule: false)
    }

    /// Applies one deterministic timer tick at a supplied timestamp.
    func tick(at date: Date) {
        guard isRunning, let endDate else { return }

        let remaining = max(ceil(endDate.timeIntervalSince(date)), 0)
        if remaining != Double(secondsRemaining) {
            secondsRemaining = max(Self.safeInt(remaining), 0)
            emitChange(changeText.replacingFirstCodePlaceholder(with: secondsRemaining))
        }

        if secondsRemaining == 0 {
            finish()
        }
    }

    /// Deterministically writes the expected Unix end timestamp.
    func persistRunningState(at date: Date) {
        guard keepRunning,
              isRunning,
              secondsRemaining > 0,
              secondsRemaining <= sourceSeconds
        else {
            return
        }

        let nowTimestamp = Int(floor(date.timeIntervalSince1970))
        storage.set(nowTimestamp + secondsRemaining, forKey: storageKey)
    }

    /// Deterministically ends the current lifecycle and marks the controller as
    /// eligible for a subsequent mounted check.
    func deactivate(at date: Date) {
        persistRunningState(at: date)
        cancelTicker()
        endDate = nil
        isRunning = false
        canGetCode = true
        secondsRemaining = sourceSeconds
        displayText = startText
        initialActivationPending = true
    }

    private func activateIfNeeded(at date: Date, schedule: Bool) {
        guard initialActivationPending else { return }
        initialActivationPending = false

        let lastTimestamp = storedTimestamp()
        let nowTimestamp = Int(floor(date.timeIntervalSince1970))
        if keepRunning,
           let lastTimestamp,
           lastTimestamp > nowTimestamp {
            secondsRemaining = max(lastTimestamp - nowTimestamp, 0)
            storage.removeObject(forKey: storageKey)
            start(at: date, schedule: schedule)
        } else {
            emitChange(startText)
        }
    }

    private func start(at date: Date, schedule: Bool) {
        initialActivationPending = false
        cancelTicker()

        onStartHandler?()
        canGetCode = false
        emitChange(changeText.replacingFirstCodePlaceholder(with: secondsRemaining))

        guard secondsRemaining > 0 else {
            canGetCode = true
            return
        }

        isRunning = true
        endDate = date.addingTimeInterval(TimeInterval(secondsRemaining))
        persistRunningState(at: date)
        if schedule {
            scheduleTicker()
        }
    }

    private func resetState() {
        initialActivationPending = false
        cancelTicker()
        endDate = nil
        isRunning = false
        canGetCode = true
        secondsRemaining = sourceSeconds
    }

    private func finish() {
        guard isRunning else { return }

        cancelTicker()
        endDate = nil
        isRunning = false
        canGetCode = true
        emitChange(endText)
        secondsRemaining = sourceSeconds
        onEndHandler?()
    }

    private func emitChange(_ text: String) {
        displayText = text
        onChangeHandler?(text)
    }

    private func scheduleTicker() {
        cancelTicker()
        ticker = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
                guard let self, self.isRunning else { return }
                self.tick(at: Date())
            }
        }
    }

    private func cancelTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private var storageKey: String {
        uniqueKey + Self.storageSuffix
    }

    private func storedTimestamp() -> Int? {
        guard let raw = storage.object(forKey: storageKey) else { return nil }
        if let number = raw as? NSNumber {
            return Self.safeInt(number.doubleValue)
        }
        if let string = raw as? String, let value = Double(string) {
            return Self.safeInt(value)
        }
        return nil
    }

    private static func parseSeconds(_ raw: String) -> Int {
        guard let value = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)),
              value.isFinite,
              value > 0
        else {
            return 0
        }
        return safeInt(value.rounded(.towardZero))
    }

    private static func safeInt(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        if value <= Double(Int.min) { return Int.min }
        if value >= Double(Int.max) { return Int.max }
        return Int(value)
    }
}

/// Native SwiftUI counterpart of uview-plus `u-code`.
///
/// Like the upstream component, this view intentionally renders no visible UI;
/// it only owns the verification-code countdown state and event lifecycle.
@MainActor
public struct UPCode: View {
    public let seconds: String
    public let startText: String
    public let changeText: String
    public let endText: String
    public let keepRunning: Bool
    public let uniqueKey: String
    /// Retained for uview-plus shared-mixin compatibility; SwiftUI has no CSS-class analogue.
    public let customClass: String
    public let customStyle: UPStyle

    private var onChangeHandler: ((String) -> Void)?
    private var onStartHandler: (() -> Void)?
    private var onEndHandler: (() -> Void)?

    @StateObject private var stateController: UPCodeController

    /// The native instance-control object corresponding to a uview-plus
    /// component ref.
    public var controller: UPCodeController {
        stateController
    }

    /// The latest text delivered by the upstream-compatible `change` event.
    public var displayText: String {
        stateController.displayText
    }

    /// Whether callers may request another verification code.
    public var canGetCode: Bool {
        stateController.canGetCode
    }

    /// Whether the native countdown is currently active.
    public var isRunning: Bool {
        stateController.isRunning
    }

    public init(
        seconds: some UPCodeSecondsValue = UPConfig.code.seconds,
        startText: String = UPConfig.code.startText,
        changeText: String = UPConfig.code.changeText,
        endText: String = UPConfig.code.endText,
        keepRunning: Bool = UPConfig.code.keepRunning,
        uniqueKey: String = UPConfig.code.uniqueKey,
        customClass: String = UPConfig.code.customClass,
        customStyle: UPStyle = UPConfig.code.customStyle,
        storage: UserDefaults = .standard,
        controller: UPCodeController? = nil
    ) {
        let seconds = seconds.upCheckboxUnitValue
        self.seconds = seconds
        self.startText = startText
        self.changeText = changeText
        self.endText = endText
        self.keepRunning = keepRunning
        self.uniqueKey = uniqueKey
        self.customClass = customClass
        self.customStyle = customStyle
        self.onChangeHandler = nil
        self.onStartHandler = nil
        self.onEndHandler = nil

        let activeController = controller ?? UPCodeController(
            seconds: seconds,
            startText: startText,
            changeText: changeText,
            endText: endText,
            keepRunning: keepRunning,
            uniqueKey: uniqueKey,
            storage: storage,
            deferredInitialActivation: true
        )
        _stateController = StateObject(wrappedValue: activeController)
    }

    public var body: some View {
        EmptyView()
            .upStyle(customStyle)
            .onAppear(perform: synchronizeController)
            .onDisappear {
                stateController.deactivate()
            }
            .onChange(of: configurationSignature) { _, _ in
                synchronizeController()
            }
    }

    private var configurationSignature: String {
        [
            seconds,
            startText,
            changeText,
            endText,
            keepRunning ? "1" : "0",
            uniqueKey
        ].joined(separator: "\u{1F}")
    }

    private func synchronizeController() {
        stateController.setOnChangeHandler(onChangeHandler)
        stateController.setOnStartHandler(onStartHandler)
        stateController.setOnEndHandler(onEndHandler)
        stateController.configure(
            seconds: seconds,
            startText: startText,
            changeText: changeText,
            endText: endText,
            keepRunning: keepRunning,
            uniqueKey: uniqueKey
        )
        stateController.activateIfNeeded()
    }
}

public extension UPCode {
    /// Registers the upstream `change(text)` event callback.
    func onChange(_ action: @escaping (String) -> Void) -> UPCode {
        var copy = self
        copy.onChangeHandler = action
        copy.controller.setOnChangeHandler(action)
        return copy
    }

    /// Registers the upstream `start()` event callback.
    func onStart(_ action: @escaping () -> Void) -> UPCode {
        var copy = self
        copy.onStartHandler = action
        copy.controller.setOnStartHandler(action)
        return copy
    }

    /// Registers the upstream `end()` event callback.
    func onEnd(_ action: @escaping () -> Void) -> UPCode {
        var copy = self
        copy.onEndHandler = action
        copy.controller.setOnEndHandler(action)
        return copy
    }
}

private extension String {
    func replacingFirstCodePlaceholder(with value: Int) -> String {
        guard let range = range(of: "x", options: [.caseInsensitive]) else { return self }
        return replacingCharacters(in: range, with: String(value))
    }
}
