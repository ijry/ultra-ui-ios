import Foundation
import SwiftUI

/// Native SwiftUI counterpart of uview-plus `u-markdown`.
///
/// 上游是 `marked` + `up-parse` 的组合：先把 Markdown 转 HTML，再交给富文本组件
/// 渲染，六个事件全部由 `up-parse` 透传。原生沿用同一条链路——
/// `UPMarkdownParser` 负责 Markdown → HTML，`UPParse` 负责渲染与事件。
///
/// `theme` 上游是一套 scoped CSS（浅色 `#333` / 深色 `#ccc` 底 `#1e1e1e`），
/// 原生落成容器样式；`attributedContent` 保留了仓库既有的 API。
@MainActor
public struct UPMarkdown: View {
    public var content: String
    public var previewImg: Bool
    public var copyLink: Bool
    public var domain: String
    public var showLineNumber: Bool
    public var theme: String
    /// 原生扩展：仓库既有的长按复制开关，透传给 `UPParse.selectable`。
    public var selectable: Bool

    private var onLoadHandler: (() -> Void)?
    private var onReadyHandler: ((CGSize) -> Void)?
    private var onImageTapHandler: ((UPParseImageEvent) -> Void)?
    private var onLinkTapHandler: ((UPParseLink) -> Void)?
    private var onPlayHandler: ((UPParsePlayEvent) -> Void)?
    private var onErrorHandler: ((UPParseErrorEvent) -> Void)?

    /// 上游 `previewImg` 只声明 `Boolean`，`copyLink` 是 `[Boolean, String]`。
    public init(content: String = UPConfig.markdown.content,
                previewImg: Bool = UPConfig.markdown.previewImg,
                copyLink: some UPParseFlagValue = UPConfig.markdown.copyLink,
                domain: String = UPConfig.markdown.domain,
                showLineNumber: Bool = UPConfig.markdown.showLineNumber,
                theme: String = UPConfig.markdown.theme,
                selectable: Bool = true) {
        self.content = content
        self.previewImg = previewImg
        self.copyLink = copyLink.upParseFlagValue
        self.domain = domain
        self.showLineNumber = showLineNumber
        self.theme = theme
        self.selectable = selectable
    }

    /// 对应上游 `data.parsedContent`（`marked(content)` + `handleCodeBlock`）。
    public var parsedContent: String {
        UPMarkdownParser.html(from: content, showLineNumber: showLineNumber)
    }

    /// 仓库既有 API：Foundation 直接解析 Markdown 的结果，供只要纯文本的调用点使用。
    public var attributedContent: AttributedString {
        (try? AttributedString(markdown: content)) ?? AttributedString(content)
    }

    public var isDark: Bool { theme.lowercased() == "dark" }

    /// 上游 `.up-markdown` 的字号/行高/内边距与主题色，落成 `UPParse` 的容器样式。
    public var containerStyle: UPStyle {
        UPStyle([
            "font-size": "16",
            "color": isDark ? "#cccccc" : "#333333",
            "padding": "16"
        ])
    }

    /// 上游 scoped CSS 里的标签样式，交给 `UPParse` 的 `tagStyle` 承载。
    public var tagStyle: [String: String] {
        [
            "h1": "font-size:32px;margin:8px 0;font-weight:bold",
            "h2": "font-size:24px;margin:8px 0;font-weight:bold",
            "h3": "font-size:18px;margin:7px 0;font-weight:bold",
            "h4": "font-size:16px;margin:7px 0;font-weight:bold",
            "h5": "font-size:13px;margin:6px 0;font-weight:bold",
            "h6": "font-size:10px;margin:5px 0;font-weight:bold",
            "p": "margin:16px 0",
            "a": isDark ? "color:#4da6ff" : "color:#007aff",
            "ul": "margin:16px 0;padding-left:32px",
            "ol": "margin:16px 0;padding-left:32px",
            "li": "margin:8px 0",
            "blockquote": "margin:8px 0;padding:0 10px;border-left:4px solid #cccccc;color:"
                + (isDark ? "#bbbbbb" : "#666666"),
            "code": "font-family:monospace;font-size:14px;background-color:"
                + (isDark ? "#2d2d2d" : "#f6f8fa"),
            "pre": "font-family:monospace;font-size:14px;white-space:pre;padding:16px;"
                + "border-radius:6px;margin:16px 0;background-color:"
                + (isDark ? "#2d2d2d" : "#f6f8fa"),
            "th": "padding:6px 13px;border:1px solid #dfe2e5;font-weight:600",
            "td": "padding:6px 13px;border:1px solid #dfe2e5",
            "hr": "margin:24px 0"
        ]
    }

    public var body: some View {
        parse
            .background(isDark ? UPColor.parse("#1e1e1e") : Color.clear)
    }

    /// 组装出的 `UPParse`，同时供事件转发与单测断言使用。
    public var parse: UPParse {
        var view = UPParse(containerStyle: containerStyle,
                           content: parsedContent,
                           copyLink: copyLink,
                           domain: domain,
                           previewImg: previewImg,
                           scrollTable: true,
                           selectable: selectable,
                           setTitle: false,
                           tagStyle: tagStyle)
        if let onLoadHandler { view = view.onLoad(onLoadHandler) }
        if let onReadyHandler { view = view.onReady(onReadyHandler) }
        if let onImageTapHandler { view = view.onImageTap(onImageTapHandler) }
        if let onLinkTapHandler { view = view.onLinkTap(onLinkTapHandler) }
        if let onPlayHandler { view = view.onPlay(onPlayHandler) }
        if let onErrorHandler { view = view.onMediaError(onErrorHandler) }
        return view
    }
}

public extension UPMarkdown {
    /// 以下六个事件对应上游 `load` / `ready` / `imgtap` / `linktap` / `play` /
    /// `error` 的原样透传（上游方法名是 `emitLoad` 这一串）。
    func onLoad(_ action: @escaping () -> Void) -> UPMarkdown {
        var copy = self
        copy.onLoadHandler = action
        return copy
    }

    func onReady(_ action: @escaping (CGSize) -> Void) -> UPMarkdown {
        var copy = self
        copy.onReadyHandler = action
        return copy
    }

    func onImageTap(_ action: @escaping (UPParseImageEvent) -> Void) -> UPMarkdown {
        var copy = self
        copy.onImageTapHandler = action
        return copy
    }

    func onLinkTap(_ action: @escaping (UPParseLink) -> Void) -> UPMarkdown {
        var copy = self
        copy.onLinkTapHandler = action
        return copy
    }

    func onPlay(_ action: @escaping (UPParsePlayEvent) -> Void) -> UPMarkdown {
        var copy = self
        copy.onPlayHandler = action
        return copy
    }

    func onError(_ action: @escaping (UPParseErrorEvent) -> Void) -> UPMarkdown {
        var copy = self
        copy.onErrorHandler = action
        return copy
    }
}
