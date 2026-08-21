import SwiftUI

struct UPIndexListContext: @unchecked Sendable {
    var activeIndex: String
    var select: (String) -> Void
}

private struct UPIndexListContextKey: EnvironmentKey {
    static let defaultValue: UPIndexListContext? = nil
}

extension EnvironmentValues {
    var upIndexListContext: UPIndexListContext? {
        get { self[UPIndexListContextKey.self] }
        set { self[UPIndexListContextKey.self] = newValue }
    }
}
