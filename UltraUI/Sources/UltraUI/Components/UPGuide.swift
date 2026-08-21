import SwiftUI

public struct UPGuideStep: Identifiable, Equatable, Sendable {
    public let id: String
    public var title: String
    public var message: String
    public init(id: String, title: String = "", message: String = "") { self.id = id; self.title = title; self.message = message }
}

@MainActor
private final class UPGuideState { var current: Int; init(current: Int) { self.current = current } }

/// Step-based overlay guide corresponding to uview-plus `u-guide`.
@MainActor
public struct UPGuide: View {
    public var steps: [UPGuideStep]
    public var current: Int { state.current }
    public var show: Bool { state.current >= 0 && state.current < steps.count }
    private let state: UPGuideState
    private var onChangeHandler: ((Int) -> Void)?
    private var onFinishHandler: (() -> Void)?

    public init(steps: [UPGuideStep] = [], current: Int = 0) { self.steps = steps; self.state = UPGuideState(current: steps.isEmpty ? -1 : min(max(current, 0), steps.count - 1)) }
    public var body: some View { if show { Text(steps[current].title.isEmpty ? steps[current].message : steps[current].title).padding().background(.regularMaterial) } }
    @discardableResult public func next() -> Bool { guard current + 1 < steps.count else { onFinishHandler?(); return false }; state.current += 1; onChangeHandler?(current); return true }
    @discardableResult public func previous() -> Bool { guard current > 0 else { return false }; state.current -= 1; onChangeHandler?(current); return true }
    public func close() { state.current = -1; onFinishHandler?() }
    public func onChange(_ action: @escaping (Int) -> Void) -> Self { var copy = self; copy.onChangeHandler = action; return copy }
    public func onFinish(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onFinishHandler = action; return copy }
}
