import SwiftUI

/// Semantic alias for the `String | Number` duration prop accepted by
/// uview-plus `u-transition`.
public typealias UPTransitionUnitValue = UPCheckboxUnitValue

/// The edge used by a directional transition. This is intentionally kept
/// internal: the public API remains the upstream string-based `mode` prop,
/// while the descriptor gives tests and future native adapters a stable
/// translation of that prop.
enum UPTransitionEdge: String, Equatable, Sendable {
    case top
    case bottom
    case leading
    case trailing
}

/// A normalized description of one of uview-plus's built-in transition modes.
struct UPTransitionSpec: Equatable, Sendable {
    let opacity: Double?
    let scale: CGFloat?
    let edge: UPTransitionEdge?

    init(opacity: Double? = nil, scale: CGFloat? = nil, edge: UPTransitionEdge? = nil) {
        self.opacity = opacity
        self.scale = scale
        self.edge = edge
    }
}

/// Coordinates visibility and lifecycle callbacks independently from the
/// SwiftUI view value. Keeping this state in a reference object prevents a
/// delayed `afterEnter`/`afterLeave` callback from writing into a stale View
/// value when a binding changes during an animation.
@MainActor
final class UPTransitionCoordinator: ObservableObject {
    @Published private(set) var isRendered = false

    private var isMounted = false
    private var desiredShow = false
    private var generation = 0
    private var completionTask: Task<Void, Never>?

    private var mode = UPTransitionConfig.mode
    private var duration: Double = 300
    private var timingFunction = UPTransitionConfig.timingFunction

    private var onBeforeEnter: (() -> Void)?
    private var onEnter: (() -> Void)?
    private var onAfterEnter: (() -> Void)?
    private var onBeforeLeave: (() -> Void)?
    private var onLeave: (() -> Void)?
    private var onAfterLeave: (() -> Void)?

    func update(
        show: Bool,
        mode: String,
        duration: Double,
        timingFunction: String,
        onBeforeEnter: (() -> Void)?,
        onEnter: (() -> Void)?,
        onAfterEnter: (() -> Void)?,
        onBeforeLeave: (() -> Void)?,
        onLeave: (() -> Void)?,
        onAfterLeave: (() -> Void)?
    ) {
        self.mode = UPTransition.normalizedMode(mode)
        self.duration = max(0, duration.isFinite ? duration : 0)
        self.timingFunction = UPTransition.normalizedTimingFunction(timingFunction)
        self.onBeforeEnter = onBeforeEnter
        self.onEnter = onEnter
        self.onAfterEnter = onAfterEnter
        self.onBeforeLeave = onBeforeLeave
        self.onLeave = onLeave
        self.onAfterLeave = onAfterLeave

        guard isMounted else {
            desiredShow = show
            return
        }

        guard desiredShow != show else { return }
        desiredShow = show

        if show {
            beginEnter()
        } else {
            beginLeave()
        }
    }

    func mount(
        show: Bool,
        mode: String,
        duration: Double,
        timingFunction: String,
        onBeforeEnter: (() -> Void)?,
        onEnter: (() -> Void)?,
        onAfterEnter: (() -> Void)?,
        onBeforeLeave: (() -> Void)?,
        onLeave: (() -> Void)?,
        onAfterLeave: (() -> Void)?
    ) {
        isMounted = true
        update(
            show: show,
            mode: mode,
            duration: duration,
            timingFunction: timingFunction,
            onBeforeEnter: onBeforeEnter,
            onEnter: onEnter,
            onAfterEnter: onAfterEnter,
            onBeforeLeave: onBeforeLeave,
            onLeave: onLeave,
            onAfterLeave: onAfterLeave
        )

        // `update` intentionally treats the pre-mount value as the desired
        // value. A true initial value still needs an enter transition once the
        // view is mounted, so start it explicitly here.
        if show && !isRendered {
            desiredShow = true
            beginEnter()
        }
    }

    func cancel() {
        generation &+= 1
        completionTask?.cancel()
        completionTask = nil
        isMounted = false
    }

    private func beginEnter() {
        generation &+= 1
        let currentGeneration = generation
        completionTask?.cancel()

        onBeforeEnter?()
        withAnimation(UPTransition.animation(
            mode: mode,
            duration: duration,
            timingFunction: timingFunction
        )) {
            isRendered = true
        }
        onEnter?()
        scheduleCompletion(for: .enter, generation: currentGeneration)
    }

    private func beginLeave() {
        guard isRendered else { return }

        generation &+= 1
        let currentGeneration = generation
        completionTask?.cancel()

        onBeforeLeave?()
        onLeave?()
        withAnimation(UPTransition.animation(
            mode: mode,
            duration: duration,
            timingFunction: timingFunction
        )) {
            // SwiftUI retains the removed subtree for the duration of its
            // `AnyTransition`, matching uview-plus's `inited` leave behavior.
            isRendered = false
        }
        scheduleCompletion(for: .leave, generation: currentGeneration)
    }

    private enum CompletionPhase {
        case enter
        case leave
    }

    private func scheduleCompletion(for phase: CompletionPhase, generation: Int) {
        let nanoseconds = UPTransition.durationNanoseconds(
            mode: mode,
            duration: duration
        )

        completionTask = Task { @MainActor [weak self] in
            if nanoseconds > 0 {
                do {
                    try await Task.sleep(nanoseconds: nanoseconds)
                } catch {
                    return
                }
            } else {
                await Task.yield()
            }

            guard !Task.isCancelled,
                  let self,
                  self.generation == generation else { return }

            switch phase {
            case .enter:
                self.onAfterEnter?()
            case .leave:
                self.onAfterLeave?()
            }
        }
    }
}

/// Native SwiftUI counterpart of uview-plus `u-transition`.
///
/// The upstream prop names and lifecycle event names are retained. SwiftUI
/// callers may pass either a plain `Bool` for a static instance or a
/// `Binding<Bool>` for the normal two-way `show` usage:
///
///     UPTransition(show: $visible, mode: "fade-up") {
///         Text("内容")
///     }
@MainActor
public struct UPTransition: View {
    private let externalShow: Binding<Bool>?
    @State private var localShow: Bool
    @StateObject private var coordinator: UPTransitionCoordinator
    private let content: AnyView

    var mode: String
    var duration: Double
    var timingFunction: String
    var customStyle: UPStyle
    private let hasCustomContentValue: Bool

    var onClickHandler: (() -> Void)?
    var onBeforeEnterHandler: (() -> Void)?
    var onEnterHandler: (() -> Void)?
    var onAfterEnterHandler: (() -> Void)?
    var onBeforeLeaveHandler: (() -> Void)?
    var onLeaveHandler: (() -> Void)?
    var onAfterLeaveHandler: (() -> Void)?

    /// The current value of the upstream `show` prop.
    public var show: Bool {
        externalShow?.wrappedValue ?? localShow
    }

    /// The normalized mode used by the native renderer.
    public var resolvedMode: String {
        Self.normalizedMode(mode)
    }

    /// The normalized CSS timing-function token used by SwiftUI.
    public var resolvedTimingFunction: String {
        Self.normalizedTimingFunction(timingFunction)
    }

    /// Whether a trailing content slot was supplied.
    var hasCustomContent: Bool {
        hasCustomContentValue
    }

    /// Creates a transition with no content slot. The no-slot form is useful
    /// for composing an instance before attaching a future adapter-specific
    /// content view.
    public init(
        show: Bool = UPConfig.transition.show,
        mode: String = UPConfig.transition.mode,
        duration: some UPTransitionUnitValue = UPConfig.transition.duration,
        timingFunction: String = UPConfig.transition.timingFunction,
        customStyle: UPStyle = UPConfig.transition.customStyle,
        onClick: (() -> Void)? = nil,
        onBeforeEnter: (() -> Void)? = nil,
        onEnter: (() -> Void)? = nil,
        onAfterEnter: (() -> Void)? = nil,
        onBeforeLeave: (() -> Void)? = nil,
        onLeave: (() -> Void)? = nil,
        onAfterLeave: (() -> Void)? = nil
    ) {
        self.init(
            externalShow: nil,
            initialShow: show,
            mode: mode,
            duration: duration.upCheckboxUnitValue,
            timingFunction: timingFunction,
            customStyle: customStyle,
            content: AnyView(EmptyView()),
            hasCustomContent: false,
            onClick: onClick,
            onBeforeEnter: onBeforeEnter,
            onEnter: onEnter,
            onAfterEnter: onAfterEnter,
            onBeforeLeave: onBeforeLeave,
            onLeave: onLeave,
            onAfterLeave: onAfterLeave
        )
    }

    /// Creates a bound transition with no content slot.
    public init(
        show: Binding<Bool>,
        mode: String = UPConfig.transition.mode,
        duration: some UPTransitionUnitValue = UPConfig.transition.duration,
        timingFunction: String = UPConfig.transition.timingFunction,
        customStyle: UPStyle = UPConfig.transition.customStyle,
        onClick: (() -> Void)? = nil,
        onBeforeEnter: (() -> Void)? = nil,
        onEnter: (() -> Void)? = nil,
        onAfterEnter: (() -> Void)? = nil,
        onBeforeLeave: (() -> Void)? = nil,
        onLeave: (() -> Void)? = nil,
        onAfterLeave: (() -> Void)? = nil
    ) {
        self.init(
            externalShow: show,
            initialShow: show.wrappedValue,
            mode: mode,
            duration: duration.upCheckboxUnitValue,
            timingFunction: timingFunction,
            customStyle: customStyle,
            content: AnyView(EmptyView()),
            hasCustomContent: false,
            onClick: onClick,
            onBeforeEnter: onBeforeEnter,
            onEnter: onEnter,
            onAfterEnter: onAfterEnter,
            onBeforeLeave: onBeforeLeave,
            onLeave: onLeave,
            onAfterLeave: onAfterLeave
        )
    }

    /// Creates an unbound transition with a SwiftUI content slot.
    public init<Content: View>(
        show: Bool = UPConfig.transition.show,
        mode: String = UPConfig.transition.mode,
        duration: some UPTransitionUnitValue = UPConfig.transition.duration,
        timingFunction: String = UPConfig.transition.timingFunction,
        customStyle: UPStyle = UPConfig.transition.customStyle,
        onClick: (() -> Void)? = nil,
        onBeforeEnter: (() -> Void)? = nil,
        onEnter: (() -> Void)? = nil,
        onAfterEnter: (() -> Void)? = nil,
        onBeforeLeave: (() -> Void)? = nil,
        onLeave: (() -> Void)? = nil,
        onAfterLeave: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            externalShow: nil,
            initialShow: show,
            mode: mode,
            duration: duration.upCheckboxUnitValue,
            timingFunction: timingFunction,
            customStyle: customStyle,
            content: AnyView(content()),
            hasCustomContent: true,
            onClick: onClick,
            onBeforeEnter: onBeforeEnter,
            onEnter: onEnter,
            onAfterEnter: onAfterEnter,
            onBeforeLeave: onBeforeLeave,
            onLeave: onLeave,
            onAfterLeave: onAfterLeave
        )
    }

    /// Creates a bound transition with a SwiftUI content slot.
    public init<Content: View>(
        show: Binding<Bool>,
        mode: String = UPConfig.transition.mode,
        duration: some UPTransitionUnitValue = UPConfig.transition.duration,
        timingFunction: String = UPConfig.transition.timingFunction,
        customStyle: UPStyle = UPConfig.transition.customStyle,
        onClick: (() -> Void)? = nil,
        onBeforeEnter: (() -> Void)? = nil,
        onEnter: (() -> Void)? = nil,
        onAfterEnter: (() -> Void)? = nil,
        onBeforeLeave: (() -> Void)? = nil,
        onLeave: (() -> Void)? = nil,
        onAfterLeave: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            externalShow: show,
            initialShow: show.wrappedValue,
            mode: mode,
            duration: duration.upCheckboxUnitValue,
            timingFunction: timingFunction,
            customStyle: customStyle,
            content: AnyView(content()),
            hasCustomContent: true,
            onClick: onClick,
            onBeforeEnter: onBeforeEnter,
            onEnter: onEnter,
            onAfterEnter: onAfterEnter,
            onBeforeLeave: onBeforeLeave,
            onLeave: onLeave,
            onAfterLeave: onAfterLeave
        )
    }

    private init(
        externalShow: Binding<Bool>?,
        initialShow: Bool,
        mode: String,
        duration: String,
        timingFunction: String,
        customStyle: UPStyle,
        content: AnyView,
        hasCustomContent: Bool,
        onClick: (() -> Void)?,
        onBeforeEnter: (() -> Void)?,
        onEnter: (() -> Void)?,
        onAfterEnter: (() -> Void)?,
        onBeforeLeave: (() -> Void)?,
        onLeave: (() -> Void)?,
        onAfterLeave: (() -> Void)?
    ) {
        self.externalShow = externalShow
        self._localShow = State(initialValue: initialShow)
        self._coordinator = StateObject(wrappedValue: UPTransitionCoordinator())
        self.content = content
        self.mode = mode
        self.duration = Self.resolvedDuration(from: duration)
        self.timingFunction = timingFunction
        self.customStyle = customStyle
        self.hasCustomContentValue = hasCustomContent
        self.onClickHandler = onClick
        self.onBeforeEnterHandler = onBeforeEnter
        self.onEnterHandler = onEnter
        self.onAfterEnterHandler = onAfterEnter
        self.onBeforeLeaveHandler = onBeforeLeave
        self.onLeaveHandler = onLeave
        self.onAfterLeaveHandler = onAfterLeave
    }

    public var body: some View {
        Group {
            if coordinator.isRendered {
                content
                    .upStyle(customStyle)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Self.performClick(onClickHandler)
                    }
                    .transition(Self.swiftUITransition(for: resolvedMode))
            }
        }
        .animation(
            Self.animation(
                mode: resolvedMode,
                duration: duration,
                timingFunction: resolvedTimingFunction
            ),
            value: coordinator.isRendered
        )
        .onAppear {
            synchronize()
        }
        .onChange(of: show) { _, _ in
            synchronize()
        }
        .onDisappear {
            coordinator.cancel()
        }
    }

    private func synchronize() {
        coordinator.mount(
            show: show,
            mode: mode,
            duration: duration,
            timingFunction: timingFunction,
            onBeforeEnter: onBeforeEnterHandler,
            onEnter: onEnterHandler,
            onAfterEnter: onAfterEnterHandler,
            onBeforeLeave: onBeforeLeaveHandler,
            onLeave: onLeaveHandler,
            onAfterLeave: onAfterLeaveHandler
        )
    }
}

public extension UPTransition {
    /// Returns the supported uview-plus mode, preserving the upstream name
    /// while accepting a few historical native aliases.
    nonisolated static func normalizedMode(_ value: String) -> String {
        switch value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        {
        case "none", "fade", "zoom", "fade-zoom",
             "fade-up", "fade-down", "fade-left", "fade-right",
             "slide-up", "slide-down", "slide-left", "slide-right":
            return value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        case "slide-top":
            return "slide-down"
        case "slide-bottom":
            return "slide-up"
        case "zoom-in":
            return "zoom"
        case "zoom-out":
            return "fade-zoom"
        default:
            return UPTransitionConfig.mode
        }
    }

    nonisolated static func resolvedDuration(from value: String) -> Double {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return Double(UPTransitionConfig.duration) ?? 300 }

        let numericText: Substring
        if normalized.hasSuffix("ms") {
            numericText = normalized.dropLast(2)
        } else {
            numericText = Substring(normalized)
        }

        guard let number = Double(numericText), number.isFinite else {
            return Double(UPTransitionConfig.duration) ?? 300
        }
        return max(0, number)
    }

    nonisolated static func normalizedTimingFunction(_ value: String) -> String {
        switch value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        {
        case "linear", "ease-in", "ease-out", "ease-in-out":
            return value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        default:
            return UPTransitionConfig.timingFunction
        }
    }

    nonisolated internal static func animationSpec(for mode: String) -> UPTransitionSpec {
        switch normalizedMode(mode) {
        case "fade":
            return UPTransitionSpec(opacity: 0)
        case "zoom":
            return UPTransitionSpec(scale: 0.95)
        case "fade-zoom":
            return UPTransitionSpec(opacity: 0, scale: 0.95)
        case "fade-up":
            return UPTransitionSpec(opacity: 0, edge: .bottom)
        case "fade-down":
            return UPTransitionSpec(opacity: 0, edge: .top)
        case "fade-left":
            return UPTransitionSpec(opacity: 0, edge: .leading)
        case "fade-right":
            return UPTransitionSpec(opacity: 0, edge: .trailing)
        case "slide-up":
            return UPTransitionSpec(edge: .bottom)
        case "slide-down":
            return UPTransitionSpec(edge: .top)
        case "slide-left":
            return UPTransitionSpec(edge: .leading)
        case "slide-right":
            return UPTransitionSpec(edge: .trailing)
        case "none":
            return UPTransitionSpec()
        default:
            return UPTransitionSpec(opacity: 0)
        }
    }

    nonisolated static func durationNanoseconds(mode: String, duration: Double) -> UInt64 {
        guard normalizedMode(mode) != "none", duration.isFinite, duration > 0 else { return 0 }
        let raw = duration * 1_000_000
        guard raw.isFinite, raw > 0 else { return 0 }
        return UInt64(min(raw.rounded(), Double(UInt64.max)))
    }

    nonisolated static func animation(
        mode: String,
        duration: Double,
        timingFunction: String
    ) -> Animation? {
        guard normalizedMode(mode) != "none" else { return nil }
        let seconds = max(0, duration) / 1_000
        let timing = normalizedTimingFunction(timingFunction)
        switch timing {
        case "linear": return .linear(duration: seconds)
        case "ease-in": return .easeIn(duration: seconds)
        case "ease-in-out": return .easeInOut(duration: seconds)
        default: return .easeOut(duration: seconds)
        }
    }

    nonisolated static func performClick(_ action: (() -> Void)?) {
        action?()
    }

    func onClick(_ action: @escaping () -> Void) -> UPTransition {
        var copy = self
        copy.onClickHandler = action
        return copy
    }

    func onBeforeEnter(_ action: @escaping () -> Void) -> UPTransition {
        var copy = self
        copy.onBeforeEnterHandler = action
        return copy
    }

    func onEnter(_ action: @escaping () -> Void) -> UPTransition {
        var copy = self
        copy.onEnterHandler = action
        return copy
    }

    func onAfterEnter(_ action: @escaping () -> Void) -> UPTransition {
        var copy = self
        copy.onAfterEnterHandler = action
        return copy
    }

    func onBeforeLeave(_ action: @escaping () -> Void) -> UPTransition {
        var copy = self
        copy.onBeforeLeaveHandler = action
        return copy
    }

    func onLeave(_ action: @escaping () -> Void) -> UPTransition {
        var copy = self
        copy.onLeaveHandler = action
        return copy
    }

    func onAfterLeave(_ action: @escaping () -> Void) -> UPTransition {
        var copy = self
        copy.onAfterLeaveHandler = action
        return copy
    }

    private static func swiftUITransition(for mode: String) -> AnyTransition {
        let spec = animationSpec(for: mode)
        var transition: AnyTransition = .identity

        if let edge = spec.edge {
            let edgeTransition: AnyTransition
            switch edge {
            case .top: edgeTransition = .move(edge: .top)
            case .bottom: edgeTransition = .move(edge: .bottom)
            case .leading: edgeTransition = .move(edge: .leading)
            case .trailing: edgeTransition = .move(edge: .trailing)
            }
            transition = transition.combined(with: edgeTransition)
        }
        if let scale = spec.scale {
            transition = transition.combined(with: .scale(scale: scale))
        }
        if spec.opacity != nil {
            transition = transition.combined(with: .opacity)
        }
        return transition
    }
}
