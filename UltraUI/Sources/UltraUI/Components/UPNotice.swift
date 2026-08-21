import SwiftUI

@MainActor
private final class UPNoticeState {
    var current: Int
    var closed = false

    init(current: Int) {
        self.current = current
    }
}

/// Shared notice item model for the row and column notice variants.
public struct UPNoticeItem: Identifiable, Equatable, Sendable {
    public let id: String
    public var text: String
    public var url: String

    public init(id: String? = nil, text: String, url: String = "") {
        self.id = id ?? text
        self.text = text
        self.url = url
    }
}

/// Vertical notice carousel corresponding to uview-plus `u-column-notice`.
@MainActor
public struct UPColumnNotice: View {
    public var notices: [String]
    public var interval: Int
    public var autoplay: Bool
    public var current: Int { state.current }
    private let state: UPNoticeState
    private var onClickHandler: ((String) -> Void)?
    private var onChangeHandler: ((Int) -> Void)?

    public init(notices: [String] = [], current: Int = 0, interval: Int = 3_000, autoplay: Bool = true) {
        self.notices = notices
        self.interval = max(interval, 0)
        self.autoplay = autoplay
        self.state = UPNoticeState(current: Self.clamp(current, count: notices.count))
    }

    public var body: some View {
        Text(notices.indices.contains(current) ? notices[current] : "")
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { click(notices.indices.contains(current) ? notices[current] : "") }
    }

    public func select(_ index: Int) {
        let next = Self.clamp(index, count: notices.count)
        guard next != current else { return }
        state.current = next
        onChangeHandler?(next)
    }

    public func click(_ text: String? = nil) {
        guard let text = text ?? notices[safe: current] else { return }
        onClickHandler?(text)
    }

    public func onClick(_ action: @escaping (String) -> Void) -> Self {
        var copy = self; copy.onClickHandler = action; return copy
    }

    public func onChange(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self; copy.onChangeHandler = action; return copy
    }

    private static func clamp(_ index: Int, count: Int) -> Int {
        count == 0 ? 0 : min(max(index, 0), count - 1)
    }
}

/// Horizontal notice carousel corresponding to uview-plus `u-row-notice`.
@MainActor
public struct UPRowNotice: View {
    public var notices: [String]
    public var interval: Int
    public var autoplay: Bool
    public var current: Int { state.current }
    private let state: UPNoticeState
    private var onClickHandler: ((Int) -> Void)?
    private var onChangeHandler: ((Int) -> Void)?

    public init(notices: [String] = [], current: Int = 0, interval: Int = 3_000, autoplay: Bool = true) {
        self.notices = notices
        self.interval = max(interval, 0)
        self.autoplay = autoplay
        self.state = UPNoticeState(current: notices.isEmpty ? 0 : min(max(current, 0), notices.count - 1))
    }

    public var body: some View {
        Text(notices.indices.contains(current) ? notices[current] : "")
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { click() }
    }

    public func select(_ index: Int) {
        let next = notices.isEmpty ? 0 : min(max(index, 0), notices.count - 1)
        guard next != current else { return }
        state.current = next
        onClickHandler?(next)
        onChangeHandler?(next)
    }

    public func click() { guard !notices.isEmpty else { return }; onClickHandler?(current) }

    public func onClick(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self; copy.onClickHandler = action; return copy
    }

    public func onChange(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self; copy.onChangeHandler = action; return copy
    }
}

/// Dismissible notice bar corresponding to uview-plus `u-notice-bar`.
@MainActor
public struct UPNoticeBar: View {
    public var text: String
    public var mode: String
    public var closable: Bool
    public var isClosed: Bool { state.closed }
    private let state = UPNoticeState(current: 0)
    private var onClickHandler: (() -> Void)?
    private var onCloseHandler: (() -> Void)?

    public init(text: String = "", mode: String = "", closable: Bool = false) {
        self.text = text; self.mode = mode; self.closable = closable
    }

    public var body: some View {
        HStack {
            Text(text).frame(maxWidth: .infinity, alignment: .leading)
            if closable { Button("×", action: close).buttonStyle(.plain) }
        }
        .opacity(isClosed ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { onClickHandler?() }
    }

    public func close() {
        guard closable, !isClosed else { return }
        state.closed = true
        onCloseHandler?()
    }

    public func onClick(_ action: @escaping () -> Void) -> Self {
        var copy = self; copy.onClickHandler = action; return copy
    }

    public func onClose(_ action: @escaping () -> Void) -> Self {
        var copy = self; copy.onCloseHandler = action; return copy
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
