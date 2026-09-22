import Foundation
import SwiftUI

/// `imgtap` 事件负载，对应上游 `$emit('imgtap', node.attrs)`。
public struct UPParseImageEvent: Equatable, Sendable {
    public let src: String
    /// 上游 `attrs.i`，即该图片在 `imageList` 中的下标。
    public let index: Int?
    public let attributes: [String: String]

    public init(src: String, index: Int? = nil, attributes: [String: String] = [:]) {
        self.src = src
        self.index = index
        self.attributes = attributes
    }
}

/// `play` 事件负载，对应上游 `$emit('play', { source, attrs })`。
public struct UPParsePlayEvent: Equatable, Sendable {
    public let source: String
    public let src: String
    public let attributes: [String: String]

    public init(source: String, src: String, attributes: [String: String] = [:]) {
        self.source = source
        self.src = src
        self.attributes = attributes
    }
}

/// `error` 事件负载，对应上游 `$emit('error', { source, attrs, errMsg })`。
public struct UPParseErrorEvent: Equatable, Sendable {
    public let source: String
    public let src: String
    public let attributes: [String: String]
    public let message: String

    public init(source: String, src: String, attributes: [String: String] = [:], message: String) {
        self.source = source
        self.src = src
        self.attributes = attributes
        self.message = message
    }
}

/// 锚点跳转请求。上游 `navigateTo` 直接调 `uni.pageScrollTo` 滚动整页，
/// SwiftUI 的滚动容器归宿主所有，因此原生把校验通过的锚点回调出去，
/// 由宿主用 `ScrollViewReader` 滚动到同名 `.id(_:)`。
public struct UPParseAnchorEvent: Equatable, Sendable {
    public let id: String
    public let offset: CGFloat

    public init(id: String, offset: CGFloat = 0) {
        self.id = id
        self.offset = offset
    }
}

/// Native SwiftUI counterpart of uview-plus `u-parse`（上游即 mp-html v2.5.1）。
///
/// 解析走纯值类型的 `UPParseDocument`，渲染在 `UPParseRender.swift` /
/// `UPParseMedia.swift`。与上游的差异集中在三处平台能力：
/// - 仓库内没有图片预览层，`previewImg` 只决定是否把 base64 图片计入
///   `document.imageList`（上游 `previewImg === 'all'`），点击一律先抛 `imgtap`，
///   宿主可以自己拿 `document.imageList` 与事件里的 `index` 呈现预览。
/// - `useAnchor` 见 `UPParseAnchorEvent`。
/// - `showImgMenu` 换成长按菜单里的「复制图片链接」，上游的保存图片依赖相册权限。
@MainActor
public struct UPParse: View {
    public var containerStyle: UPStyle
    public var content: String
    public var copyLink: Bool
    public var domain: String
    public var errorImg: String
    public var lazyLoad: Bool
    public var loadingImg: String
    public var pauseVideo: Bool
    public var previewImg: Bool
    /// 上游 `previewImg === 'all'`：连 base64 图片也进 `imageList`。
    public var previewImgAll: Bool
    public var scrollTable: Bool
    public var selectable: Bool
    public var setTitle: Bool
    public var showImgMenu: Bool
    public var tagStyle: [String: String]
    public var useAnchor: Bool
    /// 上游 `offset = offset || parseInt(useAnchor) || 0`。
    public var anchorOffset: CGFloat

    private var onLoadHandler: (() -> Void)?
    private var onReadyHandler: ((CGSize) -> Void)?
    private var onImageTapHandler: ((UPParseImageEvent) -> Void)?
    private var onLinkTapHandler: ((UPParseLink) -> Void)?
    private var onPlayHandler: ((UPParsePlayEvent) -> Void)?
    private var onMediaErrorHandler: ((UPParseErrorEvent) -> Void)?
    private var onAnchorHandler: ((UPParseAnchorEvent) -> Void)?
    private var onErrorHandler: ((String) -> Void)?
    /// 对应上游 `<slot v-if="!nodes[0]" />`：没有解析出节点时的兜底内容。
    private var placeholderSlot: AnyView?
    /// 便于单测替换，语义与 `UPCopy` 一致。
    var clipboardWriter: UPClipboardWriter

    @Environment(\.openURL) private var openURL
    @State private var measuredSize: CGSize = .zero
    @State private var media: UPParseMediaCoordinator
    /// 上游只在 `watch.content` 里解析一次，SwiftUI 的 `body` 会被反复求值，
    /// 因此把解析结果按 content + options 缓存下来。
    @State private var cache = UPParseDocumentCache()

    public init(containerStyle: UPStyle = UPConfig.parse.containerStyle,
                content: String = UPConfig.parse.content,
                copyLink: some UPParseFlagValue = UPConfig.parse.copyLink,
                domain: String = UPConfig.parse.domain,
                errorImg: String = UPConfig.parse.errorImg,
                lazyLoad: some UPParseFlagValue = UPConfig.parse.lazyLoad,
                loadingImg: String = UPConfig.parse.loadingImg,
                pauseVideo: some UPParseFlagValue = UPConfig.parse.pauseVideo,
                previewImg: some UPParseFlagValue = UPConfig.parse.previewImg,
                scrollTable: some UPParseFlagValue = UPConfig.parse.scrollTable,
                selectable: some UPParseFlagValue = UPConfig.parse.selectable,
                setTitle: some UPParseFlagValue = UPConfig.parse.setTitle,
                showImgMenu: some UPParseFlagValue = UPConfig.parse.showImgMenu,
                tagStyle: [String: String] = UPConfig.parse.tagStyle,
                useAnchor: some UPParseAnchorValue = UPConfig.parse.useAnchor,
                onError: ((String) -> Void)? = nil) {
        self.containerStyle = containerStyle
        self.content = content
        self.copyLink = copyLink.upParseFlagValue
        self.domain = domain
        self.errorImg = errorImg
        self.lazyLoad = lazyLoad.upParseFlagValue
        self.loadingImg = loadingImg
        self.pauseVideo = pauseVideo.upParseFlagValue
        self.previewImg = previewImg.upParseFlagValue
        self.previewImgAll = previewImg.upParseFlagText.lowercased() == "all"
        self.scrollTable = scrollTable.upParseFlagValue
        self.selectable = selectable.upParseFlagValue
        self.setTitle = setTitle.upParseFlagValue
        self.showImgMenu = showImgMenu.upParseFlagValue
        self.tagStyle = tagStyle
        self.useAnchor = useAnchor.upParseAnchorEnabled
        self.anchorOffset = useAnchor.upParseAnchorOffset
        self.onErrorHandler = onError
        self.clipboardWriter = UPSystemClipboard.write
        self._media = State(initialValue: UPParseMediaCoordinator())
    }

    /// 解析期用到的 props 子集，对应上游 `new Parser(this)`。
    public var options: UPParseOptions {
        UPParseOptions(domain: domain,
                       tagStyle: tagStyle,
                       useAnchor: useAnchor,
                       setTitle: setTitle,
                       scrollTable: scrollTable,
                       previewImgAll: previewImgAll,
                       containerPre: containerStyle.value(for: "white-space")?.contains("pre") ?? false)
    }

    /// 对应上游 `setContent` 之后的 `nodes` / `imgList` / `title`。
    public var document: UPParseDocument {
        UPParseDocument.parse(content, options: options)
    }

    /// 对应上游 `getText()`。
    public var plainText: String { document.plainText }

    public func onLoad(_ action: @escaping () -> Void) -> UPParse {
        var copy = self
        copy.onLoadHandler = action
        return copy
    }

    public func onReady(_ action: @escaping (CGSize) -> Void) -> UPParse {
        var copy = self
        copy.onReadyHandler = action
        return copy
    }

    public func onImageTap(_ action: @escaping (UPParseImageEvent) -> Void) -> UPParse {
        var copy = self
        copy.onImageTapHandler = action
        return copy
    }

    public func onLinkTap(_ action: @escaping (UPParseLink) -> Void) -> UPParse {
        var copy = self
        copy.onLinkTapHandler = action
        return copy
    }

    public func onPlay(_ action: @escaping (UPParsePlayEvent) -> Void) -> UPParse {
        var copy = self
        copy.onPlayHandler = action
        return copy
    }

    /// 上游 `error` 事件的完整负载；`onError` 只拿 `errMsg`，保持既有签名。
    public func onMediaError(_ action: @escaping (UPParseErrorEvent) -> Void) -> UPParse {
        var copy = self
        copy.onMediaErrorHandler = action
        return copy
    }

    public func onAnchor(_ action: @escaping (UPParseAnchorEvent) -> Void) -> UPParse {
        var copy = self
        copy.onAnchorHandler = action
        return copy
    }

    public func onError(_ action: @escaping (String) -> Void) -> UPParse {
        var copy = self
        copy.onErrorHandler = action
        return copy
    }

    public func reportError(_ message: String) { onErrorHandler?(message) }

    /// 注入剪贴板实现，语义与 `UPCopy` 的 internal init 一致，仅供单测使用。
    func clipboard(_ writer: @escaping UPClipboardWriter) -> UPParse {
        var copy = self
        copy.clipboardWriter = writer
        return copy
    }

    /// 对应上游 `navigateTo(id, offset)`：`useAnchor` 为假或找不到锚点时走 `error`。
    @discardableResult
    public func navigateTo(_ id: String = "", offset: CGFloat? = nil) -> Bool {
        navigateTo(id, offset: offset, in: document)
    }

    @discardableResult
    private func navigateTo(_ id: String, offset: CGFloat? = nil, in document: UPParseDocument) -> Bool {
        guard useAnchor else {
            reportError("Anchor is disabled")
            return false
        }
        guard id.isEmpty || document.anchors.contains(id) else {
            reportError("Label not found")
            return false
        }
        onAnchorHandler?(UPParseAnchorEvent(id: id, offset: offset ?? anchorOffset))
        return true
    }

    public var body: some View {
        let document = cache.document(for: content, options: options)
        titled(selection(rootView(document)), title: document.title)
    }

    private func rootView(_ document: UPParseDocument) -> some View {
        nodesView(document)
            .frame(maxWidth: .infinity, alignment: .leading)
            // 上游 `._root { padding: 1px 0 }`。
            .padding(.vertical, 1)
            .upStyle(containerStyle)
            .background { sizeReader }
            .environment(\.openURL, OpenURLAction { open($0, in: document) })
            .task(id: content) { await reportLifecycle() }
    }

    @ViewBuilder
    private func nodesView(_ document: UPParseDocument) -> some View {
        if document.isEmpty, let placeholderSlot {
            placeholderSlot
        } else {
            UPParseNodesView(nodes: document.nodes,
                             context: context(for: document),
                             style: UPParseTextStyle.root(containerStyle),
                             lazy: lazyLoad)
        }
    }

    /// 上游 `selectable` 落在 `._select { user-select: text }`。
    @ViewBuilder
    private func selection(_ content: some View) -> some View {
        if selectable {
            content.textSelection(.enabled)
        } else {
            content.textSelection(.disabled)
        }
    }

    /// 上游 `setTitle` 调 `uni.setNavigationBarTitle`。
    @ViewBuilder
    private func titled(_ content: some View, title: String) -> some View {
        if setTitle, !title.isEmpty {
            content.navigationTitle(title)
        } else {
            content
        }
    }

    private var sizeReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { measuredSize = proxy.size }
                .onChange(of: proxy.size) { _, size in measuredSize = size }
        }
    }

    /// 上游在 `$nextTick` 里抛 `load`，再每 350ms 取一次高度，不变即 `ready`。
    private func reportLifecycle() async {
        onLoadHandler?()
        guard onReadyHandler != nil else { return }
        var height = -CGFloat.greatestFiniteMagnitude
        while !Task.isCancelled {
            let size = measuredSize
            if size.height == height {
                onReadyHandler?(size)
                return
            }
            height = size.height
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
            } catch {
                return
            }
        }
    }

    private func context(for document: UPParseDocument) -> UPParseContext {
        UPParseContext(loadingImg: loadingImg,
                       errorImg: errorImg,
                       lazyLoad: lazyLoad,
                       showImgMenu: showImgMenu,
                       pauseVideo: pauseVideo,
                       media: media,
                       onImageTap: { tapImage($0, in: document) },
                       onPlay: { onPlayHandler?($0) },
                       onMediaError: { event in
                           onMediaErrorHandler?(event)
                           onErrorHandler?(event.message)
                       },
                       copy: { text in
                           if clipboardWriter(text) { UPToast.show(message: "链接已复制") }
                       })
    }

    /// 对应上游 `node.vue` 的 `imgTap`。
    func tapImage(_ node: UPParseNode, in document: UPParseDocument) {
        if let index = node.linkIndex, document.links.indices.contains(index) {
            tapLink(document.links[index], in: document)
            return
        }
        guard node.attributes["ignore"] == nil else { return }
        onImageTapHandler?(UPParseImageEvent(src: node.attributes["src"] ?? "",
                                             index: node.imageIndex,
                                             attributes: node.attributes))
    }

    /// 对应上游 `node.vue` 的 `linkTap`。
    func tapLink(_ link: UPParseLink, in document: UPParseDocument) {
        onLinkTapHandler?(link)
        let href = link.href
        guard !href.isEmpty else { return }
        if href.hasPrefix("#") {
            navigateTo(String(href.dropFirst()), in: document)
            return
        }
        // 上游 APP-PLUS 用 `plus.runtime.openWeb` 打开外链，MP 分支是复制加提示；
        // `copyLink` 的文档语义是「自动复制」，原生取复制分支。
        if UPParseDocument.isExternalLink(href) {
            guard copyLink else { return }
            if clipboardWriter(href) { UPToast.show(message: "链接已复制") }
            return
        }
        // 上游此处 `uni.navigateTo` 走应用内路由，原生没有路由表，交给系统。
        if let url = URL(string: href) { openURL(url) }
    }

    /// `<a>` 在富文本里必须留在文字流中才能正确折行，因此渲染层把链接写成
    /// `AttributedString` 的 `link`，点击由这里拦截，不真的打开自定义 scheme。
    private func open(_ url: URL, in document: UPParseDocument) -> OpenURLAction.Result {
        guard let index = Self.linkIndex(in: url), document.links.indices.contains(index) else {
            return .systemAction
        }
        tapLink(document.links[index], in: document)
        return .handled
    }

    nonisolated static let linkScheme = "upparse"

    nonisolated static func linkURL(index: Int) -> URL? {
        URL(string: "\(linkScheme)://link/\(index)")
    }

    nonisolated static func linkIndex(in url: URL) -> Int? {
        guard url.scheme == linkScheme, url.host == "link" else { return nil }
        return Int(url.lastPathComponent)
    }
}

/// 一次解析结果的记忆体，避免每帧重新走一遍 `parser.js`。
public extension UPParse {
    /// 等价于上游默认插槽是否存在。
    var hasPlaceholderSlot: Bool { placeholderSlot != nil }

    /// 对应上游 `<slot v-if="!nodes[0]" />`：`content` 解析不出节点时展示。
    func placeholder<Slot: View>(@ViewBuilder _ builder: () -> Slot) -> UPParse {
        var copy = self
        copy.placeholderSlot = AnyView(builder())
        return copy
    }
}

/// 一次解析结果的记忆体，避免每帧重新走一遍 `parser.js`。
@MainActor
final class UPParseDocumentCache {
    private var key: (content: String, options: UPParseOptions)?
    private var cached = UPParseDocument.empty

    init() {}

    func document(for content: String, options: UPParseOptions) -> UPParseDocument {
        if let key, key.content == content, key.options == options { return cached }
        cached = UPParseDocument.parse(content, options: options)
        key = (content, options)
        return cached
    }
}
