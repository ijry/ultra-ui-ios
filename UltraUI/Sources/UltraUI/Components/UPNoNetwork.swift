import SwiftUI

public enum UPNetworkStatus: Equatable, Sendable {
    case unknown
    case offline
    case wifi
    case cellular
    case wired
}

@MainActor
public final class UPNoNetwork: View {
    public private(set) var status: UPNetworkStatus
    private var onChangeHandler: ((UPNetworkStatus) -> Void)?

    public init(status: UPNetworkStatus = .unknown,
                onChange: ((UPNetworkStatus) -> Void)? = nil) {
        self.status = status
        self.onChangeHandler = onChange
    }

    public var isOffline: Bool { status == .offline }

    public func onChange(_ action: @escaping (UPNetworkStatus) -> Void) -> UPNoNetwork {
        onChangeHandler = action
        return self
    }

    public func update(_ newStatus: UPNetworkStatus) {
        status = newStatus
        onChangeHandler?(newStatus)
    }

    public var body: some View {
        Group {
            if isOffline { ContentUnavailableView("No Network", systemImage: "wifi.slash") }
            else { EmptyView() }
        }
    }
}
