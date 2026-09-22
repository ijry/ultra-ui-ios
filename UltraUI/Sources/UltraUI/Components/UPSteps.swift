import SwiftUI

/// 仓库既有的三态枚举。
public enum UPStepState: Equatable, Sendable { case finished, current, pending }

/// 上游 `statusClass` 的四个取值。
public enum UPStepStatus: String, Equatable, Sendable {
    /// 当前步骤且未失败。
    case process
    /// 当前步骤失败，或非当前步骤但自身 `error` 为真。
    case error
    /// 已完成（`current > index`）。
    case finish
    /// 未到达。
    case wait
}

public protocol UPStepsValueInput {
    var upStepsValue: Int? { get }
}

extension Int: UPStepsValueInput {
    public var upStepsValue: Int? { self }
}

extension String: UPStepsValueInput {
    public var upStepsValue: Int? { Int(trimmingCharacters(in: .whitespacesAndNewlines)) }
}

/// 上游 `u-steps-item` 通过 `getParentData('u-steps')` 拿到的那份父级数据。
struct UPStepsParentData: Equatable, Sendable {
    var direction: String
    var current: Int
    var activeColor: String
    var inactiveColor: String
    var activeIcon: String
    var inactiveIcon: String
    var dot: Bool
    /// 上游 `childLength`：兄弟节点总数。
    var childLength: Int
    /// 上游 `lineStyle` 会看下一个兄弟的 `error`，因此父级要把这份表下发。
    var childErrors: [Bool]
    /// 子项登记顺序，子项据此反查自己的 `index`（上游是 `children.indexOf(this)`）。
    var childIDs: [UUID]

    static let placeholder = UPStepsParentData(direction: UPConfig.steps.direction,
                                               current: 0,
                                               activeColor: UPConfig.steps.activeColor,
                                               inactiveColor: UPConfig.steps.inactiveColor,
                                               activeIcon: UPConfig.steps.activeIcon,
                                               inactiveIcon: UPConfig.steps.inactiveIcon,
                                               dot: UPConfig.steps.dot,
                                               childLength: 0,
                                               childErrors: [],
                                               childIDs: [])
}

private struct UPStepsParentDataKey: EnvironmentKey {
    static let defaultValue: UPStepsParentData? = nil
}

extension EnvironmentValues {
    var upStepsParentData: UPStepsParentData? {
        get { self[UPStepsParentDataKey.self] }
        set { self[UPStepsParentDataKey.self] = newValue }
    }
}

/// 子项向父级登记自身，父级据此算出 `index` 与 `childLength`。
struct UPStepsItemRegistration: Equatable, Sendable {
    let id: UUID
    let error: Bool
}

struct UPStepsRegistrationKey: PreferenceKey {
    static let defaultValue: [UPStepsItemRegistration] = []

    static func reduce(value: inout [UPStepsItemRegistration],
                       nextValue: () -> [UPStepsItemRegistration]) {
        value.append(contentsOf: nextValue())
    }
}

/// Native SwiftUI counterpart of uview-plus `u-steps`.
///
/// 上游本身只是个 flex 容器，真正的排版与配色都在 `u-steps-item` 里，靠
/// `getParentData('u-steps')` 把 7 个 prop 下发给每个子项。原生用 Environment 下发
/// 同一份数据，子项则用 PreferenceKey 回报自身，从而拿到 `index` 与 `childLength`。
@MainActor
public struct UPSteps<Content: View>: View {
    /// 上游 `direction`：`row` / `column`。
    public var direction: String
    public var current: Int
    public var activeColor: String
    public var inactiveColor: String
    public var activeIcon: String
    public var inactiveIcon: String
    public var dot: Bool

    private let content: Content
    @State private var registrations: [UPStepsItemRegistration] = []

    public init(direction: String = UPConfig.steps.direction,
                current: Int = 0,
                activeColor: String = UPConfig.steps.activeColor,
                inactiveColor: String = UPConfig.steps.inactiveColor,
                activeIcon: String = UPConfig.steps.activeIcon,
                inactiveIcon: String = UPConfig.steps.inactiveIcon,
                dot: Bool = UPConfig.steps.dot,
                @ViewBuilder content: () -> Content) {
        self.direction = direction
        self.current = max(0, current)
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.activeIcon = activeIcon
        self.inactiveIcon = inactiveIcon
        self.dot = dot
        self.content = content()
    }

    /// 上游 `current` 是 `String | Number`。
    public init<Value: UPStepsValueInput>(direction: String = UPConfig.steps.direction,
                                          current: Value,
                                          activeColor: String = UPConfig.steps.activeColor,
                                          inactiveColor: String = UPConfig.steps.inactiveColor,
                                          activeIcon: String = UPConfig.steps.activeIcon,
                                          inactiveIcon: String = UPConfig.steps.inactiveIcon,
                                          dot: Bool = UPConfig.steps.dot,
                                          @ViewBuilder content: () -> Content) {
        self.init(direction: direction,
                  current: max(0, current.upStepsValue ?? 0),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  activeIcon: activeIcon,
                  inactiveIcon: inactiveIcon,
                  dot: dot,
                  content: content)
    }

    /// 仓库既有方法。
    public func state(for index: Int) -> UPStepState {
        index < current ? .finished : index == current ? .current : .pending
    }

    /// 上游 `statusClass`：当前项失败算 error，其余项自身 error 也算 error。
    public func status(for index: Int, error: Bool = false) -> UPStepStatus {
        Self.status(index: index, current: current, error: error)
    }

    nonisolated static func status(index: Int, current: Int, error: Bool) -> UPStepStatus {
        if current == index { return error ? .error : .process }
        if error { return .error }
        return current > index ? .finish : .wait
    }

    /// 上游 `statusColor`：finish 用 activeColor、error 用 `color.error`、
    /// process 在 dot 模式下用 activeColor（非 dot 时透明），其余用 inactiveColor。
    public func statusColor(for index: Int, error: Bool = false) -> String {
        Self.statusColor(status: status(for: index, error: error),
                         activeColor: activeColor,
                         inactiveColor: inactiveColor,
                         dot: dot)
    }

    nonisolated static func statusColor(status: UPStepStatus,
                                        activeColor: String,
                                        inactiveColor: String,
                                        dot: Bool) -> String {
        switch status {
        case .finish: return activeColor
        case .error: return UPConfig.stepsItem.errorColor
        case .process: return dot ? activeColor : "transparent"
        case .wait: return inactiveColor
        }
    }

    /// 上游 `lineStyle.backgroundColor`。
    ///
    /// 照抄上游这处反直觉：连线颜色看的是**下一个**兄弟节点的 `error`，
    /// 而不是自己的；下一个失败时整条线变红。
    public func lineColor(for index: Int, childErrors: [Bool] = []) -> String {
        Self.lineColor(index: index,
                       current: current,
                       childErrors: childErrors,
                       activeColor: activeColor,
                       inactiveColor: inactiveColor)
    }

    nonisolated static func lineColor(index: Int,
                                      current: Int,
                                      childErrors: [Bool],
                                      activeColor: String,
                                      inactiveColor: String) -> String {
        let nextIndex = index + 1
        if childErrors.indices.contains(nextIndex), childErrors[nextIndex] {
            return UPConfig.stepsItem.errorColor
        }
        return index < current ? activeColor : inactiveColor
    }

    // MARK: - 视图

    public var body: some View {
        Group {
            if direction == "column" {
                VStack(alignment: .leading, spacing: 0) { content }
            } else {
                HStack(alignment: .top, spacing: 0) { content }
            }
        }
        .environment(\.upStepsParentData, parentData)
        .onPreferenceChange(UPStepsRegistrationKey.self) { value in
            if registrations != value { registrations = value }
        }
    }

    private var parentData: UPStepsParentData {
        UPStepsParentData(direction: direction,
                          current: current,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          activeIcon: activeIcon,
                          inactiveIcon: inactiveIcon,
                          dot: dot,
                          childLength: registrations.count,
                          childErrors: registrations.map(\.error),
                          childIDs: registrations.map(\.id))
    }
}

public extension UPSteps where Content == EmptyView {
    init(direction: String = UPConfig.steps.direction,
         current: Int = 0,
         activeColor: String = UPConfig.steps.activeColor,
         inactiveColor: String = UPConfig.steps.inactiveColor,
         activeIcon: String = UPConfig.steps.activeIcon,
         inactiveIcon: String = UPConfig.steps.inactiveIcon,
         dot: Bool = UPConfig.steps.dot) {
        self.init(direction: direction,
                  current: current,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  activeIcon: activeIcon,
                  inactiveIcon: inactiveIcon,
                  dot: dot,
                  content: EmptyView.init)
    }
}
