import Foundation
import SwiftUI

public struct UPParse: View {
    public var content: String
    public var selectable: Bool
    private var onErrorHandler: ((String) -> Void)?

    public init(content: String = "", selectable: Bool = true,
                onError: ((String) -> Void)? = nil) {
        self.content = content
        self.selectable = selectable
        self.onErrorHandler = onError
    }

    public var plainText: String {
        content
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }

    public func onError(_ action: @escaping (String) -> Void) -> UPParse {
        var copy = self
        copy.onErrorHandler = action
        return copy
    }

    public func reportError(_ message: String) { onErrorHandler?(message) }

    @ViewBuilder public var body: some View {
        if selectable {
            Text(plainText).textSelection(.enabled)
        } else {
            Text(plainText).textSelection(.disabled)
        }
    }
}
