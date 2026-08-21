import SwiftUI

public enum UPStepState: Equatable, Sendable { case finished, current, pending }

@MainActor
public struct UPSteps<Content: View>: View {
    public var direction: String; public var current: Int; public var activeColor: String
    public var inactiveColor: String; public var activeIcon: String; public var inactiveIcon: String; public var dot: Bool
    private let content: Content
    public init(direction: String = "row", current: Int = 0, activeColor: String = "#3c9cff",
                inactiveColor: String = "#969799", activeIcon: String = "", inactiveIcon: String = "",
                dot: Bool = false, @ViewBuilder content: () -> Content) {
        self.direction = direction; self.current = max(0, current); self.activeColor = activeColor
        self.inactiveColor = inactiveColor; self.activeIcon = activeIcon; self.inactiveIcon = inactiveIcon; self.dot = dot; self.content = content()
    }
    public var body: some View { Group { if direction == "column" { VStack { content } } else { HStack { content } } } }
    public func state(for index: Int) -> UPStepState { index < current ? .finished : index == current ? .current : .pending }
}
public extension UPSteps where Content == EmptyView {
    init(direction: String = "row", current: Int = 0, activeColor: String = "#3c9cff", inactiveColor: String = "#969799", activeIcon: String = "", inactiveIcon: String = "", dot: Bool = false) {
        self.init(direction: direction, current: current, activeColor: activeColor, inactiveColor: inactiveColor, activeIcon: activeIcon, inactiveIcon: inactiveIcon, dot: dot, content: EmptyView.init)
    }
}

@MainActor
public struct UPStepsItem<Content: View>: View {
    public var title: String; public var desc: String; public var iconSize: String; public var error: Bool; public var itemStyle: UPStyle
    private let content: Content; private var onClickHandler: (() -> Void)?
    public init(title: String = "", desc: String = "", iconSize: some UPImageUnitValue = "17", error: Bool = false, itemStyle: UPStyle = UPStyle(), @ViewBuilder content: () -> Content) {
        self.title = title; self.desc = desc; self.iconSize = iconSize.upImageUnitValue; self.error = error; self.itemStyle = itemStyle; self.content = content()
    }
    public var resolvedIconSize: CGFloat { UPUnit.parse(iconSize) }
    public var body: some View { Button(action: triggerClick) { VStack(spacing: 4) { content; Text(title); if !desc.isEmpty { Text(desc).font(.caption) } } }.buttonStyle(.plain) }
    public func onClick(_ action: @escaping () -> Void) -> Self { var copy = self; copy.onClickHandler = action; return copy }
    public func triggerClick() { onClickHandler?() }
}
public extension UPStepsItem where Content == EmptyView {
    init(title: String = "", desc: String = "", iconSize: some UPImageUnitValue = "17", error: Bool = false, itemStyle: UPStyle = UPStyle()) {
        self.init(title: title, desc: desc, iconSize: iconSize, error: error, itemStyle: itemStyle, content: EmptyView.init)
    }
}
