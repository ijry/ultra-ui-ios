import SwiftUI

@MainActor
private final class UPTooltipState { var show: Bool; init(show: Bool) { self.show = show } }

/// Tooltip overlay corresponding to uview-plus `u-tooltip`.
@MainActor
public struct UPTooltip<Content: View>: View {
    public var text: String
    public var placement: String
    public var show: Bool { state.show }
    private let state: UPTooltipState
    private let content: Content

    public init(text: String = "", show: Bool = false, placement: String = "top", @ViewBuilder content: () -> Content) {
        self.text = text; self.placement = placement; self.state = UPTooltipState(show: show); self.content = content()
    }

    public var body: some View { content.overlay(alignment: .top) { if show { Text(text).padding(6).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 5)) } } }
    public func showTooltip() { state.show = true }
    public func hideTooltip() { state.show = false }
}

public extension UPTooltip where Content == EmptyView {
    init(text: String = "", show: Bool = false, placement: String = "top") {
        self.init(text: text, show: show, placement: placement, content: EmptyView.init)
    }
}
