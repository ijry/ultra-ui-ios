import Foundation
import SwiftUI

public struct UPMarkdown: View {
    public var content: String
    public var selectable: Bool

    public init(content: String = "", selectable: Bool = true) {
        self.content = content
        self.selectable = selectable
    }

    public var attributedContent: AttributedString {
        (try? AttributedString(markdown: content)) ?? AttributedString(content)
    }

    @ViewBuilder public var body: some View {
        if selectable {
            Text(attributedContent).textSelection(.enabled)
        } else {
            Text(attributedContent).textSelection(.disabled)
        }
    }
}
