import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

typealias UPClipboardWriter = (String) -> Bool

@MainActor
enum UPSystemClipboard {
    static func write(_ content: String) -> Bool {
        #if canImport(UIKit)
        UIPasteboard.general.string = content
        return true
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(content, forType: .string)
        #else
        return false
        #endif
    }
}

/// Native SwiftUI counterpart of uview-plus `u-copy`.
@MainActor
public struct UPCopy<Content: View>: View {
    var content: String
    var alertStyle: String
    var notice: String
    var contentView: Content
    var successAction: (() -> Void)?
    var clipboardWriter: UPClipboardWriter

    public init(
        content: String = "",
        alertStyle: String = "toast",
        notice: String = "复制成功"
    ) where Content == Text {
        self.init(
            content: content,
            alertStyle: alertStyle,
            notice: notice,
            clipboardWriter: UPSystemClipboard.write,
            contentView: { Text("复制") }
        )
    }

    public init(
        content: String = "",
        alertStyle: String = "toast",
        notice: String = "复制成功",
        @ViewBuilder contentView: () -> Content
    ) {
        self.init(
            content: content,
            alertStyle: alertStyle,
            notice: notice,
            clipboardWriter: UPSystemClipboard.write,
            contentView: contentView
        )
    }

    init(
        content: String = "",
        alertStyle: String = "toast",
        notice: String = "复制成功",
        clipboardWriter: @escaping UPClipboardWriter
    ) where Content == Text {
        self.init(
            content: content,
            alertStyle: alertStyle,
            notice: notice,
            clipboardWriter: clipboardWriter,
            contentView: { Text("复制") }
        )
    }

    init(
        content: String = "",
        alertStyle: String = "toast",
        notice: String = "复制成功",
        clipboardWriter: @escaping UPClipboardWriter,
        @ViewBuilder contentView: () -> Content
    ) {
        self.content = content
        self.alertStyle = alertStyle
        self.notice = notice
        self.contentView = contentView()
        self.successAction = nil
        self.clipboardWriter = clipboardWriter
    }

    public var body: some View {
        Button(action: { _ = performCopy() }) {
            contentView
        }
        .buttonStyle(.plain)
    }

    @discardableResult
    func performCopy() -> Bool {
        guard !content.isEmpty, clipboardWriter(content) else { return false }
        successAction?()
        return true
    }

    public func onSuccess(_ action: @escaping () -> Void) -> UPCopy {
        var copy = self
        copy.successAction = action
        return copy
    }
}
