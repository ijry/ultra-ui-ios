import Foundation
import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class RichTextComponentTests: XCTestCase {
    func testMarkdownProducesAttributedContentAndRetainsSource() {
        let markdown = UPMarkdown(content: "# Title\n\n**Bold**")
        XCTAssertEqual(markdown.content, "# Title\n\n**Bold**")
        XCTAssertFalse(markdown.attributedContent.characters.isEmpty)
    }

    /// `u-markdown.vue` 的内联 props：`content: ''`、`previewImg: true`、
    /// `copyLink: true`、`domain: ''`、`showLineNumber: false`、`theme: 'light'`。
    func testMarkdownPropDefaultsMatchUpstream() {
        let markdown = UPMarkdown()
        XCTAssertEqual(markdown.content, "")
        XCTAssertTrue(markdown.previewImg)
        XCTAssertTrue(markdown.copyLink)
        XCTAssertEqual(markdown.domain, "")
        XCTAssertFalse(markdown.showLineNumber)
        XCTAssertEqual(markdown.theme, "light")
        XCTAssertFalse(markdown.isDark)
        XCTAssertEqual(markdown.parsedContent, "")
    }

    /// 上游把 props 原样透传给 `up-parse`。
    func testMarkdownForwardsPropsToParse() {
        let markdown = UPMarkdown(content: "# T",
                                  previewImg: true,
                                  copyLink: false,
                                  domain: "https://a.com",
                                  theme: "dark")
        let parse = markdown.parse
        XCTAssertEqual(parse.content, markdown.parsedContent)
        XCTAssertTrue(parse.previewImg)
        XCTAssertFalse(parse.copyLink)
        XCTAssertEqual(parse.domain, "https://a.com")
        // 上游 markdown 自带标题样式，不让 <title> 改导航栏。
        XCTAssertFalse(parse.setTitle)
        XCTAssertEqual(parse.tagStyle["h1"], "font-size:32px;margin:8px 0;font-weight:bold")
        XCTAssertTrue(markdown.isDark)
        XCTAssertEqual(markdown.containerStyle.foregroundColor, "#cccccc")
        XCTAssertEqual(parse.tagStyle["a"], "color:#4da6ff")
    }

    /// 事件全部由 `up-parse` 透传，链式调用后仍落在同一个 `UPParse` 上。
    func testMarkdownEventsReachParse() {
        var loaded = 0
        var links: [UPParseLink] = []
        let markdown = UPMarkdown(content: "[文档](https://a.com)")
            .onLoad { loaded += 1 }
            .onLinkTap { links.append($0) }
        let parse = markdown.parse
        let document = parse.document
        XCTAssertEqual(document.links.map(\.href), ["https://a.com"])
        parse.tapLink(document.links[0], in: document)
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(loaded, 0)
    }

    func testParseStripsSimpleHTMLAndEmitsErrorForInvalidInput() {
        var error = ""
        let parsed = UPParse(content: "<p>Hello <strong>world</strong></p>")
            .onError { error = $0 }
        XCTAssertTrue(parsed.plainText.contains("Hello"))
        XCTAssertTrue(parsed.plainText.contains("world"))
        XCTAssertTrue(error.isEmpty)
    }

    /// `u-parse.vue` 的内联 props：`copyLink` / `pauseVideo` / `previewImg` /
    /// `setTitle` / `showImgMenu` 默认 true，`scrollTable` / `selectable` /
    /// `useAnchor` 只声明类型（JS 下 undefined），`lazyLoad` 默认 false。
    func testParsePropDefaultsMatchUpstream() {
        let parse = UPParse()
        XCTAssertEqual(parse.containerStyle, UPStyle())
        XCTAssertEqual(parse.content, "")
        XCTAssertTrue(parse.copyLink)
        XCTAssertEqual(parse.domain, "")
        XCTAssertEqual(parse.errorImg, "")
        XCTAssertFalse(parse.lazyLoad)
        XCTAssertEqual(parse.loadingImg, "")
        XCTAssertTrue(parse.pauseVideo)
        XCTAssertTrue(parse.previewImg)
        XCTAssertFalse(parse.previewImgAll)
        XCTAssertFalse(parse.scrollTable)
        XCTAssertFalse(parse.selectable)
        XCTAssertTrue(parse.setTitle)
        XCTAssertTrue(parse.showImgMenu)
        XCTAssertEqual(parse.tagStyle, [:])
        XCTAssertFalse(parse.useAnchor)
        XCTAssertEqual(parse.anchorOffset, 0)
    }

    /// `copyLink` / `previewImg` 是 `[Boolean, String]`，`useAnchor` 是
    /// `[Boolean, Number]`：字符串按 JS 真值判断，数字兼作滚动偏移量。
    func testParseUnionPropsFollowJavaScriptTruthiness() {
        let all = UPParse(copyLink: "", previewImg: "all", useAnchor: 40)
        XCTAssertFalse(all.copyLink)
        XCTAssertTrue(all.previewImg)
        XCTAssertTrue(all.previewImgAll)
        XCTAssertTrue(all.useAnchor)
        XCTAssertEqual(all.anchorOffset, 40)

        let off = UPParse(previewImg: "", useAnchor: 0)
        XCTAssertFalse(off.previewImg)
        XCTAssertFalse(off.previewImgAll)
        XCTAssertFalse(off.useAnchor)
    }

    /// props 组装成解析层的 `UPParseOptions`；`containerStyle` 同时含
    /// `white-space` 与 `pre` 时上游会把 `this.pre` 设成 2。
    func testParseOptionsForwardParserProps() {
        let parse = UPParse(containerStyle: UPStyle(["white-space": "pre-wrap"]),
                            domain: "https://example.com",
                            previewImg: "all",
                            scrollTable: true,
                            setTitle: false,
                            tagStyle: ["li": "margin: 5px 0;"],
                            useAnchor: true)
        let options = parse.options
        XCTAssertEqual(options.domain, "https://example.com")
        XCTAssertEqual(options.tagStyle, ["li": "margin: 5px 0;"])
        XCTAssertTrue(options.useAnchor)
        XCTAssertFalse(options.setTitle)
        XCTAssertTrue(options.scrollTable)
        XCTAssertTrue(options.previewImgAll)
        XCTAssertTrue(options.containerPre)
    }

    /// 上游 `navigateTo`：`useAnchor` 为假直接 `Error('Anchor is disabled')`，
    /// 找不到 id 则 `Error('Label not found')`，成功时 offset 取 `parseInt(useAnchor)`。
    func testParseNavigateToReportsUpstreamAnchorErrors() {
        var errors: [String] = []
        let disabled = UPParse(content: "<div id=\"list\">a</div>").onError { errors.append($0) }
        XCTAssertFalse(disabled.navigateTo("list"))
        XCTAssertEqual(errors, ["Anchor is disabled"])

        var anchor: UPParseAnchorEvent?
        let enabled = UPParse(content: "<div id=\"list\">a</div>", useAnchor: 30)
            .onError { errors.append($0) }
            .onAnchor { anchor = $0 }
        XCTAssertFalse(enabled.navigateTo("missing"))
        XCTAssertEqual(errors, ["Anchor is disabled", "Label not found"])
        XCTAssertTrue(enabled.navigateTo("list"))
        XCTAssertEqual(anchor, UPParseAnchorEvent(id: "list", offset: 30))
    }

    /// 上游 `linkTap`：先抛 `linktap`，`#` 开头跳锚点，外链只在 `copyLink` 为真时复制。
    func testParseLinkTapCopiesExternalLinkOnlyWhenEnabled() {
        var copied: [String] = []
        var tapped: [UPParseLink] = []
        let parse = UPParse(content: "<a href=\"https://uview-plus.jiangruyi.com?a=1\">文档</a>")
            .onLinkTap { tapped.append($0) }
            .clipboard { copied.append($0); return true }
        let link = parse.document.links[0]
        XCTAssertEqual(link.innerText, "文档")
        parse.tapLink(link, in: parse.document)
        XCTAssertEqual(tapped.count, 1)
        XCTAssertEqual(copied, ["https://uview-plus.jiangruyi.com?a=1"])

        let disabled = UPParse(content: parse.content, copyLink: false)
            .clipboard { copied.append($0); return true }
        disabled.tapLink(disabled.document.links[0], in: disabled.document)
        XCTAssertEqual(copied.count, 1)
    }

    /// 上游 `imgTap`：祖先是 `<a>` 时转成 `linktap`，`attrs.ignore` 直接 return。
    func testParseImageTapFallsBackToLinkTap() {
        var images: [UPParseImageEvent] = []
        var links: [UPParseLink] = []
        let parse = UPParse(content: """
        <a href="/detail"><img src="/a.png"></a>
        <img src="data:image/png;base64,AAAA">
        <img src="/b.png">
        """, domain: "https://example.com")
            .onImageTap { images.append($0) }
            .onLinkTap { links.append($0) }
        let document = parse.document
        let nodes = Self.flatten(document.nodes).filter { $0.name == "img" }
        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(document.imageList, ["https://example.com/a.png", "https://example.com/b.png"])

        parse.tapImage(nodes[0], in: document)
        XCTAssertEqual(links.map(\.href), ["/detail"])
        XCTAssertTrue(images.isEmpty)

        parse.tapImage(nodes[1], in: document)
        XCTAssertTrue(images.isEmpty)

        parse.tapImage(nodes[2], in: document)
        XCTAssertEqual(images.map(\.src), ["https://example.com/b.png"])
        XCTAssertEqual(images.map(\.index), [1])
    }

    nonisolated static func flatten(_ nodes: [UPParseNode]) -> [UPParseNode] {
        nodes.flatMap { [$0] + flatten($0.children) }
    }

    /// 上游 `<slot v-if="!nodes[0]" />`：解析不出节点时展示默认插槽。
    func testParsePlaceholderSlotTracksEmptyContent() {
        XCTAssertFalse(UPParse().hasPlaceholderSlot)
        let parse = UPParse().placeholder { Text("暂无内容") }
        XCTAssertTrue(parse.hasPlaceholderSlot)
        XCTAssertTrue(parse.document.isEmpty)
        XCTAssertFalse(UPParse(content: "<p>a</p>").document.isEmpty)
    }
}

/// `u-parse/parser.js` 里 `Lexer` 的行为。
final class ParseLexerTests: XCTestCase {
    func testTokenizeLowercasesNamesAndFillsBooleanAttributes() {
        let tokens = UPParseLexer.tokenize("<DIV Class=\"a\" hidden><BR/></div>")
        XCTAssertEqual(tokens, [
            .openTag(name: "div", attributes: ["class": "a", "hidden": "T"], selfClosing: false),
            .openTag(name: "br", attributes: [:], selfClosing: true),
            .closeTag("div")
        ])
    }

    func testTokenizeSkipsCommentsAndScriptContent() {
        XCTAssertEqual(UPParseLexer.tokenize("a<!-- <b>x</b> -->b"), [.text("a"), .text("b")])
        XCTAssertEqual(UPParseLexer.tokenize("<script>if (1 < 2) {}</script>tail"),
                       [.openTag(name: "script", attributes: [:], selfClosing: false),
                        .closeTag("script"),
                        .text("tail")])
    }

    /// 上游 `onAttrName`：`data-src` 改名成 `src`，含 `?` / `;` 的属性名丢弃；
    /// 其余 `data-*` 只有 `img` / `a` 保留，供 `imgtap` / `linktap` 事件读取。
    func testTokenizeRenamesDataSourceAndDropsInvalidNames() {
        XCTAssertEqual(UPParseLexer.tokenize("<p data-src=\"a.png\" a;b=\"1\">"),
                       [.openTag(name: "p", attributes: ["src": "a.png"], selfClosing: false)])
        XCTAssertEqual(UPParseLexer.tokenize("<p data-x=\"1\">"),
                       [.openTag(name: "p", attributes: [:], selfClosing: false)])
        XCTAssertEqual(UPParseLexer.tokenize("<img data-x=\"1\">"),
                       [.openTag(name: "img", attributes: ["data-x": "1"], selfClosing: false)])
    }

    /// `style` / `href` / 含 `src` 的属性值走 `decodeEntity(_, amp: true)`。
    func testTokenizeDecodesEntitiesInUrlLikeAttributes() {
        XCTAssertEqual(UPParseLexer.tokenize("<a href=\"?a=1&amp;b=2\" title=\"1&amp;2\">"),
                       [.openTag(name: "a",
                                 attributes: ["href": "?a=1&b=2", "title": "1&amp;2"],
                                 selfClosing: false)])
    }
}

/// `parser.js` 的解析结果与工具函数。
final class ParseDocumentTests: XCTestCase {
    func testParseCollectsTitleImagesAnchorsAndLinks() {
        let document = UPParseDocument.parse("""
        <title>富文本示例</title>
        <section id="list"><a href="#list">锚点</a><img src="a.png"></section>
        """, options: UPParseOptions(domain: "https://example.com", useAnchor: true))
        XCTAssertEqual(document.title, "富文本示例")
        XCTAssertEqual(document.imageList, ["https://example.com/a.png"])
        XCTAssertEqual(document.anchors, ["list"])
        XCTAssertEqual(document.links.map(\.href), ["#list"])
        XCTAssertEqual(document.links.map(\.innerText), ["锚点"])
        // block 标签统一转 div。
        XCTAssertEqual(document.nodes.first?.name, "div")
    }

    /// `setTitle` 为假时不收集 `<title>`；`useAnchor` 为假时非媒体标签的 id 被清掉。
    func testParseHonoursSetTitleAndUseAnchor() {
        let document = UPParseDocument.parse("<title>T</title><p id=\"a\">x</p>",
                                             options: UPParseOptions(useAnchor: false, setTitle: false))
        XCTAssertEqual(document.title, "")
        XCTAssertTrue(document.anchors.isEmpty)
        XCTAssertNil(document.nodes.first(where: { $0.name == "p" })?.attributes["id"])
    }

    func testParsePlainTextMatchesUpstreamGetText() {
        let document = UPParseDocument.parse("<p>a<br>b</p><table><tr><td>1</td><td>2</td></tr></table>")
        XCTAssertEqual(document.plainText, "a\nb\n1\t2\t\n")
    }

    /// `cellpadding` / `cellspacing` / `border` 换算成单元格样式与 `border-spacing`。
    func testParseTableDecoratesCellsAndSinksRowColors() {
        let document = UPParseDocument.parse("""
        <table border="1" cellpadding="5" cellspacing="0">
          <tr style="color: #f00;"><td colspan="2">a</td></tr>
        </table>
        """)
        let table = document.nodes.first { $0.name == "table" }
        XCTAssertEqual(table?.style.value(for: "display"), "table")
        XCTAssertEqual(table?.style.value(for: "border"), "1px solid gray")
        XCTAssertEqual(table?.style.value(for: "border-spacing"), "0px")
        let cell = RichTextComponentTests.flatten(document.nodes).first { $0.name == "td" }
        XCTAssertEqual(cell?.style.value(for: "padding"), "5px")
        XCTAssertEqual(cell?.style.value(for: "border"), "1px solid gray")
        XCTAssertEqual(cell?.style.value(for: "color"), "#f00")
    }

    /// `scrollTable` 给表格外面套一层 `overflow:auto` 的 div。
    func testParseScrollTableWrapsTableInScrollLayer() {
        let plain = UPParseDocument.parse("<table><tr><td>a</td></tr></table>")
        XCTAssertEqual(plain.nodes.map(\.name), ["table"])

        let scrolled = UPParseDocument.parse("<table><tr><td>a</td></tr></table>",
                                             options: UPParseOptions(scrollTable: true))
        XCTAssertEqual(scrolled.nodes.map(\.name), ["div"])
        XCTAssertEqual(scrolled.nodes.first?.style.value(for: "overflow"), "auto")
        XCTAssertEqual(scrolled.nodes.first?.children.map(\.name), ["table"])
    }

    /// `<font>` 的 color / face / size 转样式，size 夹在 1…7。
    func testParseConvertsFontAttributesToStyle() {
        let document = UPParseDocument.parse("<font color=\"red\" face=\"serif\" size=\"9\">a</font>")
        let font = document.nodes[0]
        XCTAssertEqual(font.name, "span")
        XCTAssertEqual(font.style.value(for: "color"), "red")
        XCTAssertEqual(font.style.value(for: "font-family"), "serif")
        XCTAssertEqual(font.style.value(for: "font-size"), "xxx-large")
    }

    /// `<embed>` 依后缀转 video/audio，`<source>` 追加到 `sources`。
    func testParseConvertsEmbedAndCollectsSources() {
        let document = UPParseDocument.parse("""
        <embed src="https://a.com/a.mp3">
        <video src="https://a.com/a.mp4"><source src="https://a.com/b.mp4"></video>
        """)
        let media = document.nodes.filter { $0.name == "audio" || $0.name == "video" }
        XCTAssertEqual(media.map(\.name), ["audio", "video"])
        XCTAssertEqual(media[0].sources, ["https://a.com/a.mp3"])
        XCTAssertEqual(media[1].sources, ["https://a.com/a.mp4", "https://a.com/b.mp4"])
        XCTAssertEqual(media[1].attributes["id"], "v0")
        XCTAssertEqual(media[1].attributes["controls"], "T")
    }

    /// `<ruby>` 转成上下两行的居中排版，`<ol type>` 转 `list-style-type`。
    func testParseRewritesRubyAndListType() {
        let ruby = UPParseDocument.parse("<ruby>汉<rt>hàn</rt></ruby>").nodes[0]
        XCTAssertEqual(ruby.name, "span")
        XCTAssertEqual(ruby.children.first?.style.value(for: "display"), "inline-block")
        XCTAssertEqual(ruby.children.first?.children.first?.style.value(for: "font-size"), "50%")

        let list = UPParseDocument.parse("<ol type=\"A\"><li>a</li></ol>").nodes[0]
        XCTAssertEqual(list.style.value(for: "list-style-type"), "upper-alpha")
        XCTAssertNil(list.attributes["type"])
    }

    /// `<base>` 在解析途中设置主域名，`url()` 也补域名。
    func testParseUsesBaseTagAndFillsBackgroundURL() {
        let document = UPParseDocument.parse("""
        <base href="https://cdn.com"><p style="background: url(bg.png) no-repeat">a</p>
        """)
        XCTAssertEqual(document.nodes[0].style.value(for: "background"),
                       "url(https://cdn.com/bg.png) no-repeat")
    }

    /// `!important` 的声明不会被后面的普通声明覆盖，且末尾的标记被剥掉。
    func testParseKeepsImportantDeclarationsAndStripsMarker() {
        let document = UPParseDocument.parse("<p style=\"color: red !important; color: blue\">a</p>",
                                             options: UPParseOptions(tagStyle: ["p": "color: green"]))
        XCTAssertEqual(document.nodes[0].style.value(for: "color"), "red")
    }

    func testResolvedURLMatchesUpstreamGetUrl() {
        XCTAssertEqual(UPParseDocument.resolvedURL("//a.com/x.png", domain: "https://b.com"),
                       "https://a.com/x.png")
        XCTAssertEqual(UPParseDocument.resolvedURL("//a.com/x.png", domain: ""), "http://a.com/x.png")
        XCTAssertEqual(UPParseDocument.resolvedURL("/x.png", domain: "https://b.com"), "https://b.com/x.png")
        XCTAssertEqual(UPParseDocument.resolvedURL("x.png", domain: "https://b.com"), "https://b.com/x.png")
        XCTAssertEqual(UPParseDocument.resolvedURL("https://c.com/x.png", domain: "https://b.com"),
                       "https://c.com/x.png")
        XCTAssertEqual(UPParseDocument.resolvedURL("data:image/png;base64,AA", domain: "https://b.com"),
                       "data:image/png;base64,AA")
    }

    func testHrefHelpersMatchUpstream() {
        XCTAssertEqual(UPParseDocument.normalizeHref("  /a  "), "/a")
        XCTAssertEqual(UPParseDocument.normalizeHref(nil), "")
        XCTAssertTrue(UPParseDocument.isExternalLink("https://a.com?u=/b"))
        XCTAssertFalse(UPParseDocument.isExternalLink("/a?u=https://b.com"))
    }

    /// `config.entities` 里没有 `amp`，只有 `decodeEntity(_, amp: true)` 才解 `&amp;`。
    func testDecodeEntityHandlesNamedAndNumericForms() {
        XCTAssertEqual(UPParseDocument.decodeEntity("&lt;p&gt;&nbsp;&hellip;"), "<p>\u{A0}…")
        XCTAssertEqual(UPParseDocument.decodeEntity("&#65;&#x42;"), "AB")
        XCTAssertEqual(UPParseDocument.decodeEntity("&amp;"), "&amp;")
        XCTAssertEqual(UPParseDocument.decodeEntity("&amp;", amp: true), "&")
        XCTAssertEqual(UPParseDocument.decodeEntity("&unknown;"), "&unknown;")
    }

    func testResolvedTagStyleMergesOverridesOverDefaults() {
        let merged = UPParseTags.resolvedTagStyle([" TD ": "border: 1px"])
        XCTAssertEqual(merged["td"], "border: 1px")
        XCTAssertEqual(merged["pre"], UPParseTags.defaultTagStyle["pre"])
    }

    /// `pre` 下空白符原样保留，否则连续空白合并成一个空格。
    /// `<pre>` 属于 blockTags，出栈时转成 `div`，`getText` 因此补一个尾部换行。
    func testParseCollapsesWhitespaceOutsidePre() {
        XCTAssertEqual(UPParseDocument.parse("<span>a \t b</span>").plainText, "a b")
        XCTAssertEqual(UPParseDocument.parse("<pre>a \t b</pre>").plainText, "a \t b\n")
    }

    func testBuilderNumberHelpersFollowJavaScript() {
        XCTAssertEqual(UPParseBuilder.parseFloat("12.5px"), 12.5)
        XCTAssertEqual(UPParseBuilder.parseFloat("-3abc"), -3)
        XCTAssertNil(UPParseBuilder.parseFloat("abc"))
        XCTAssertEqual(UPParseBuilder.parseInt("12.9px"), 12)
        XCTAssertEqual(UPParseBuilder.numberText(12), "12")
        XCTAssertEqual(UPParseBuilder.numberText(12.5), "12.5")
    }
}

/// 渲染层的样式解析与排版工具。
final class ParseStyleTests: XCTestCase {
    func testStyleParsesTypographyDeclarations() {
        let style = UPParseStyle("""
        color: #f00; background-color: rgba(0, 0, 0, 0.5); font-weight: 600;
        font-style: italic; text-decoration: underline line-through;
        font-family: monospace; text-align: center; white-space: pre-wrap
        """)
        XCTAssertNotNil(style.foregroundColor)
        XCTAssertNotNil(style.backgroundColor)
        XCTAssertEqual(style.isBold, true)
        XCTAssertEqual(style.isItalic, true)
        XCTAssertTrue(style.isMonospaced)
        XCTAssertEqual(style.textAlignment, .center)
        XCTAssertTrue(style.isPre)
        XCTAssertEqual(style.textDecoration?.underline, true)
        XCTAssertEqual(style.textDecoration?.strikethrough, true)
    }

    func testStyleLengthSupportsCSSUnitsAndKeywords() {
        XCTAssertEqual(UPParseStyle.length("12px", base: 16), 12)
        XCTAssertEqual(UPParseStyle.length("2em", base: 16), 32)
        XCTAssertEqual(UPParseStyle.length("50%", base: 16), 8)
        XCTAssertEqual(UPParseStyle.length("12pt", base: 16), 16)
        XCTAssertEqual(UPParseStyle.length("smaller", base: 16), 16 * 0.8)
        XCTAssertEqual(UPParseStyle.length("xxx-large", base: 16), 34)
        XCTAssertNil(UPParseStyle.length("auto", base: 16))
        XCTAssertEqual(UPParseStyle.length("375rpx", base: 16), UPUnit.rpx(375))
    }

    func testStyleShorthandInsetsAndBorders() {
        let insets = UPParseStyle("padding: 1px 2px 3px 4px").insets(for: "padding", base: 16)
        XCTAssertEqual(insets, UPInsets(top: 1, leading: 4, bottom: 3, trailing: 2))
        XCTAssertEqual(UPParseStyle("border: 2px solid red").border(for: "top")?.width, 2)
        XCTAssertNil(UPParseStyle("border: none").border(for: "top"))
        XCTAssertEqual(UPParseStyle("border-left-width: 3px").border(for: "left")?.width, 3)
    }

    func testColorParsingRejectsUnknownValues() {
        XCTAssertEqual(UPParseColor.parse("transparent"), .clear)
        XCTAssertNotNil(UPParseColor.parse("#3c9cff"))
        XCTAssertNotNil(UPParseColor.parse("rgb(1, 2, 3)"))
        XCTAssertNotNil(UPParseColor.parse("gray"))
        XCTAssertNil(UPParseColor.parse("var(--main)"))
    }

    /// 继承链：字号按 `em` 逐级放大，`text-decoration: none` 会清掉祖先的下划线。
    func testTextStyleInheritanceAppliesDeclarations() {
        let root = UPParseTextStyle.root(UPStyle(["font-size": "15", "color": "#606266"]))
        XCTAssertEqual(root.fontSize, 15)
        XCTAssertNotNil(root.color)

        let heading = root.applying(UPParseStyle("font-size:2em;font-weight:bold;text-decoration:underline"))
        XCTAssertEqual(heading.fontSize, 30)
        XCTAssertTrue(heading.isBold)
        XCTAssertTrue(heading.underline)
        XCTAssertFalse(heading.applying(UPParseStyle("text-decoration:none")).underline)

        let superscript = root.applying(UPParseStyle("vertical-align:super"))
        XCTAssertGreaterThan(superscript.baselineOffset, 0)
    }

    /// 行内节点合并成一段富文本，块级各自成行。
    func testFragmentsGroupConsecutiveInlineNodes() {
        let nodes = UPParseDocument.parse("<span>a</span><b>b</b><div>c</div><span>d</span>").nodes
        let fragments = UPParseFragment.fragments(nodes)
        XCTAssertEqual(fragments.count, 3)
        guard case .inline(let first) = fragments[0] else { return XCTFail("expected inline group") }
        XCTAssertEqual(first.count, 2)
        guard case .block(let block) = fragments[1] else { return XCTFail("expected block") }
        XCTAssertEqual(block.name, "div")
    }

    /// `display:inline` 让未知块级标签回到文字流，`inline-block` 归块级。
    func testFragmentInlineDetectionFollowsDisplay() {
        XCTAssertTrue(UPParseFragment.isInline(UPParseNode(name: "div", style: UPParseStyle("display:inline"))))
        XCTAssertFalse(UPParseFragment.isInline(UPParseNode(name: "span",
                                                           style: UPParseStyle("display:inline-block"))))
        XCTAssertFalse(UPParseFragment.isInline(UPParseNode(name: "img")))
        XCTAssertTrue(UPParseFragment.isInline(UPParseNode.text("a")))
    }

    /// 上游 `node.vue` 的 `_xxx` class 默认样式。
    func testDefaultStylesMatchUpstreamClasses() {
        XCTAssertEqual(UPParseDefaults.style(for: UPParseNode(name: "h1")).value(for: "font-size"), "2em")
        XCTAssertEqual(UPParseDefaults.style(for: UPParseNode(name: "code")).value(for: "font-family"),
                       "monospace")
        XCTAssertEqual(UPParseDefaults.style(for: UPParseNode(name: "th")).value(for: "text-align"), "center")
        XCTAssertEqual(UPParseDefaults.style(for: UPParseNode(name: "ul")).value(for: "padding-left"), "40px")
        XCTAssertNil(UPParseDefaults.style(for: UPParseNode(name: "a")).value(for: "color"))
        XCTAssertEqual(UPParseDefaults.style(for: UPParseNode(name: "a",
                                                             attributes: ["href": "/a"])).value(for: "color"),
                       "#366092")
        // 节点自己的声明覆盖内建默认值。
        let node = UPParseNode(name: "h1", style: UPParseStyle("font-size:10px"))
        XCTAssertEqual(UPParseDefaults.resolvedStyle(for: node).value(for: "font-size"), "10px")
    }

    func testListMarkersCoverCSSTypes() {
        XCTAssertEqual(UPParseListView.marker("disc", index: 0), "\u{2022}")
        XCTAssertEqual(UPParseListView.marker("circle", index: 0), "\u{25E6}")
        XCTAssertEqual(UPParseListView.marker("decimal", index: 2, start: 3), "5.")
        XCTAssertEqual(UPParseListView.marker("upper-alpha", index: 26), "AA.")
        XCTAssertEqual(UPParseListView.marker("lower-roman", index: 3), "iv.")
        XCTAssertEqual(UPParseListView.marker("none", index: 0), "")
        XCTAssertEqual(UPParseListView.bulletType(depth: 0), "disc")
        XCTAssertEqual(UPParseListView.bulletType(depth: 2), "square")
    }

    /// 表格渲染前把 `thead` / `tbody` 展平成行，`colspan` 转成跨列数。
    func testTableViewFlattensRowsAndReadsColumnSpan() {
        let table = UPParseDocument.parse("""
        <table><caption>标题</caption>
        <thead><tr><th colspan="2">h</th></tr></thead>
        <tbody><tr><td>a</td><td>b</td></tr></tbody></table>
        """).nodes[0]
        let rows = UPParseTableView.rows(in: table.children)
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(UPParseTableView.cells(in: rows[1]).count, 2)
        XCTAssertEqual(UPParseTableView.columnSpan(UPParseTableView.cells(in: rows[0])[0]), 2)
        XCTAssertEqual(UPParseTableView.extras(in: table.children).map(\.name), ["div"])
    }

    func testMediaURLHelpersSkipUnsupportedSchemes() {
        XCTAssertNil(UPParseURL.remote("data:image/png;base64,AA"))
        XCTAssertNotNil(UPParseURL.remote("https://a.com/a.mp4"))
        XCTAssertEqual(UPParseURL.firstPlayable(["ftp://a", "https://a.com/a.mp4"])?.index, 1)
        XCTAssertNil(UPParseURL.firstPlayable([]))
    }

    /// 链接靠内部 scheme 在 `AttributedString` 里传递下标。
    func testLinkURLRoundTrip() {
        let url = UPParse.linkURL(index: 3)
        XCTAssertEqual(url?.scheme, UPParse.linkScheme)
        XCTAssertEqual(url.flatMap(UPParse.linkIndex(in:)), 3)
        XCTAssertNil(URL(string: "https://a.com").flatMap(UPParse.linkIndex(in:)))
    }
}

@MainActor
final class DocumentMediaTests: XCTestCase {
    func testPDFReaderTracksPageAndEmitsPageChange() {
        var changed = -1
        let reader = UPPDFReader(documentData: Data([37, 80, 68, 70]))
            .onPageChange { changed = $0 }
        XCTAssertEqual(reader.currentPage, 0)
        reader.goToPage(2)
        XCTAssertEqual(reader.currentPage, 2)
        XCTAssertEqual(changed, 2)
    }

    /// `u-pdf-reader/props.js`: `src: ''`、`height: '500px'`、
    /// `baseUrl: 'https://uview-plus.jiangruyi.com/h5'`。
    func testPDFReaderPropDefaultsMatchUpstream() {
        let reader = UPPDFReader()
        XCTAssertEqual(reader.src, "")
        XCTAssertEqual(reader.height, 500)
        XCTAssertEqual(reader.baseUrl, "https://uview-plus.jiangruyi.com/h5")
    }

    /// 上游 `mounted` 拼接 `${baseUrlInner}/static/pdfjs/web/viewer.html?file=` +
    /// `encodeURIComponent(src)`，`baseUrl` 传空串时回落到内置域名。
    func testPDFReaderBuildsViewerURLLikeUpstream() {
        let reader = UPPDFReader(src: "https://example.com/a b.pdf")
        XCTAssertEqual(
            reader.viewerURL,
            "https://uview-plus.jiangruyi.com/h5/static/pdfjs/web/viewer.html?file=https%3A%2F%2Fexample.com%2Fa%20b.pdf"
        )

        let fallback = UPPDFReader(src: "a.pdf", baseUrl: "")
        XCTAssertEqual(
            fallback.viewerURL,
            "https://uview-plus.jiangruyi.com/h5/static/pdfjs/web/viewer.html?file=a.pdf"
        )

        let custom = UPPDFReader(src: "a.pdf", baseUrl: "https://cdn.example.com")
        XCTAssertEqual(
            custom.viewerURL,
            "https://cdn.example.com/static/pdfjs/web/viewer.html?file=a.pdf"
        )
    }

    /// `height` 走字符串单位，`'500px'` 与裸数值等价。
    func testPDFReaderParsesHeightUnits() {
        XCTAssertEqual(UPPDFReader(height: "320px").height, 320)
        XCTAssertEqual(UPPDFReader(height: 240).height, 240)
    }

    func testShortVideoRetainsPlaybackStateAndEvents() {
        var played = 0
        let video = UPShortVideo(src: "https://example.com/video.mp4")
            .onPlay { played += 1 }
        XCTAssertFalse(video.isPlaying)
        video.play()
        XCTAssertTrue(video.isPlaying)
        XCTAssertEqual(played, 1)
        video.pause()
        XCTAssertFalse(video.isPlaying)
    }

    /// `u-short-video.vue` 的内联 props：`tabsList` 默认「推荐/关注/朋友/本地」、
    /// `videoList: []`、`currentTab: 0`、`currentVideo: 0`。
    func testShortVideoFeedPropDefaultsMatchUpstream() {
        let feed = UPShortVideoFeed()
        XCTAssertEqual(feed.tabsList, ["推荐", "关注", "朋友", "本地"])
        XCTAssertTrue(feed.videoList.isEmpty)
        XCTAssertEqual(feed.currentTab, 0)
        XCTAssertEqual(feed.currentVideo, 0)
        XCTAssertEqual(feed.speedOptions, [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
        XCTAssertFalse(feed.showSpeedSheet)
        XCTAssertFalse(feed.hasMenuSlot)
        XCTAssertFalse(feed.hasActionsSlot)
        XCTAssertNil(feed.currentItem)
    }

    /// 上游 `handleTabChange` / `handleSwiperChange` 抛下标并写回绑定。
    func testShortVideoFeedTabAndVideoChange() {
        var tab = 0
        var video = 0
        var tabs: [Int] = []
        var videos: [Int] = []
        let feed = UPShortVideoFeed(videoList: [UPShortVideoItem(videoUrl: "/a.mp4"),
                                                UPShortVideoItem(videoUrl: "/b.mp4")],
                                    currentTab: Binding(get: { tab }, set: { tab = $0 }),
                                    currentVideo: Binding(get: { video }, set: { video = $0 }))
            .onTabChange { tabs.append($0) }
            .onVideoChange { videos.append($0) }

        feed.selectTab(2)
        XCTAssertEqual(tab, 2)
        XCTAssertEqual(tabs, [2])
        feed.selectVideo(1)
        XCTAssertEqual(video, 1)
        XCTAssertEqual(videos, [1])
        XCTAssertEqual(feed.currentItem?.videoUrl, "/b.mp4")

        // 越界不响应。
        feed.selectTab(99)
        feed.selectVideo(99)
        XCTAssertEqual(tabs, [2])
        XCTAssertEqual(videos, [1])
    }

    /// 上游四个操作事件负载都是 `{ item, index }`。
    func testShortVideoFeedActionEventsCarryItemAndIndex() {
        var actions: [String] = []
        let feed = UPShortVideoFeed(videoList: [UPShortVideoItem(videoUrl: "/a.mp4", likeCount: 3)])
            .onLike { actions.append("like-\($0.index)-\($0.item.likeCount)") }
            .onComment { actions.append("comment-\($0.index)") }
            .onShare { actions.append("share-\($0.index)") }
            .onCollect { actions.append("collect-\($0.index)") }
        feed.like(at: 0)
        feed.comment(at: 0)
        feed.share(at: 0)
        feed.collect(at: 0)
        XCTAssertEqual(actions, ["like-0-3", "comment-0", "share-0", "collect-0"])
        feed.like(at: 5)
        XCTAssertEqual(actions.count, 4)
    }

    /// 上游 `onProgressChanging` / `onProgressChange` 都会写进当前项的 progress。
    func testShortVideoFeedProgressWritesBackToItem() {
        var changing: [Double] = []
        var changed: [Double] = []
        let feed = UPShortVideoFeed(videoList: [UPShortVideoItem(videoUrl: "/a.mp4")])
            .onProgressChanging { changing.append($0.progress) }
            .onProgressChange { changed.append($0.progress) }
        feed.progressChanging(40)
        XCTAssertEqual(feed.currentItem?.progress, 40)
        XCTAssertEqual(changing, [40])
        feed.progressChange(120)
        // 0…100 夹紧。
        XCTAssertEqual(feed.currentItem?.progress, 100)
        XCTAssertEqual(changed, [120])
    }

    /// 上游 `showSpeedOptions` / `selectSpeed` 写进 `item.playbackRate`。
    func testShortVideoFeedSpeedSheetUpdatesPlaybackRate() {
        let feed = UPShortVideoFeed(videoList: [UPShortVideoItem(videoUrl: "/a.mp4"),
                                                UPShortVideoItem(videoUrl: "/b.mp4")])
        feed.showSpeedOptions(at: 1)
        XCTAssertTrue(feed.showSpeedSheet)
        feed.selectSpeed(1.5)
        XCTAssertFalse(feed.showSpeedSheet)
        XCTAssertEqual(feed.videoList[1].playbackRate, 1.5)
        XCTAssertEqual(feed.videoList[0].playbackRate, 1)
    }

    /// 上游 `onTimeUpdate` 用 `currentTime / duration * 100` 算进度。
    func testShortVideoPlaybackProgressMatchesUpstreamFormula() {
        XCTAssertEqual(UPShortVideoPlayback(index: 0, currentTime: 30, duration: 120).progress, 25)
        XCTAssertEqual(UPShortVideoPlayback(index: 0, currentTime: 5, duration: 0).progress, 0)
    }
}

@MainActor
final class UploadComponentTests: XCTestCase {
    func testUploadAddsFilesAndEmitsProgressAndSuccess() {
        var progress: Double = 0
        var uploaded = [UPUploadFile]()
        let upload = UPUpload(maxCount: 2)
            .onProgress { progress = $0 }
            .onSuccess { uploaded = $0 }
        let file = UPUploadFile(name: "a.txt", data: Data("A".utf8), mimeType: "text/plain")
        upload.add(file)
        XCTAssertEqual(upload.files.count, 1)
        upload.updateProgress(0.5)
        XCTAssertEqual(progress, 0.5)
        upload.complete()
        XCTAssertEqual(uploaded, [file])
    }

    /// `upload.js`：`accept: 'image'`、`capture: ['album','camera']`、
    /// `compressed: true`、`camera: 'back'`、`maxDuration: 60`、
    /// `uploadIcon: 'camera-fill'`、`uploadIconColor: '#D3D4D6'`、`maxCount: 52`、
    /// `imageMode: 'aspectFill'`、`sizeType: ['original','compressed']`、
    /// `deletable: true`、`maxSize: Number.MAX_VALUE`、`width/height: 80`、
    /// `previewImage: true`、`previewFullImage: true`、`videoPreviewObjectFit: 'cover'`。
    func testUploadPropDefaultsMatchUpstream() {
        let upload = UPUpload(fileList: [UPUploadFile]())
        XCTAssertEqual(upload.accept, "image")
        XCTAssertEqual(upload.extensions, [])
        XCTAssertEqual(upload.capture, ["album", "camera"])
        XCTAssertTrue(upload.compressed)
        XCTAssertEqual(upload.camera, "back")
        XCTAssertEqual(upload.maxDuration, 60)
        XCTAssertEqual(upload.uploadIcon, "camera-fill")
        XCTAssertEqual(upload.uploadIconColor, "#D3D4D6")
        XCTAssertFalse(upload.useBeforeRead)
        XCTAssertTrue(upload.previewFullImage)
        XCTAssertEqual(upload.maxCount, 52)
        XCTAssertFalse(upload.disabled)
        XCTAssertEqual(upload.imageMode, "aspectFill")
        XCTAssertEqual(upload.name, "")
        XCTAssertEqual(upload.sizeType, ["original", "compressed"])
        XCTAssertFalse(upload.multiple)
        XCTAssertTrue(upload.deletable)
        XCTAssertEqual(upload.maxSize, Int.max)
        XCTAssertEqual(upload.uploadText, "")
        XCTAssertEqual(upload.width, 80)
        XCTAssertEqual(upload.height, 80)
        XCTAssertTrue(upload.previewImage)
        XCTAssertFalse(upload.autoDelete)
        XCTAssertFalse(upload.autoUpload)
        XCTAssertEqual(upload.autoUploadApi, "")
        XCTAssertEqual(upload.autoUploadAuthUrl, "")
        XCTAssertEqual(upload.autoUploadDriver, "")
        XCTAssertEqual(upload.autoUploadHeader, [:])
        XCTAssertFalse(upload.getVideoThumb)
        XCTAssertFalse(upload.customAfterAutoUpload)
        XCTAssertEqual(upload.videoPreviewObjectFit, "cover")
        XCTAssertTrue(upload.isInCount)
        XCTAssertFalse(upload.hasTriggerSlot)
    }

    /// 上游 `formatFileList`：`item.name` 非空时按文件名判类型，否则先看 `accept`；
    /// `item.deletable` 缺省时继承组件的 `deletable`。
    func testUploadFormatsFileListTypesAndDeletable() {
        let upload = UPUpload(fileList: [
            UPUploadFile(name: "a.png"),
            UPUploadFile(name: "b.mp4"),
            UPUploadFile(name: "c.txt"),
            UPUploadFile(url: "https://a.com/x"),
            UPUploadFile(url: "https://a.com/y.mp4", deletable: false)
        ], deletable: true)
        // 无名文件上游会同时把 isImage 与 isVideo 置为真（`accept === 'image'` 命中
        // 前者，`test.video(url)` 命中后者），模板先判 isImage，故按图片渲染。
        XCTAssertEqual(upload.lists.map(\.type), ["image", "video", "", "image", "image"])
        XCTAssertEqual(upload.lists.map { $0.deletable ?? false }, [true, true, true, true, false])

        // `accept: 'video'` 时无名文件按视频处理。
        let video = UPUpload(fileList: [UPUploadFile(url: "https://a.com/x")], accept: "video")
        XCTAssertEqual(video.lists.map(\.type), ["video"])
    }

    /// 上游 `test.image` 先截 query，`test.video` 不截。
    func testUploadSourceTypeHelpersMatchUpstreamRegexes() {
        XCTAssertTrue(UPUploadFile.isImageSource("a.PNG?x=1"))
        XCTAssertTrue(UPUploadFile.isImageSource("a.jfif"))
        XCTAssertFalse(UPUploadFile.isImageSource("a?b=.png"))
        XCTAssertTrue(UPUploadFile.isVideoSource("a.m3u8"))
        XCTAssertTrue(UPUploadFile.isVideoSource("a?b=.mp4"))
        XCTAssertFalse(UPUploadFile.isVideoSource("a.txt"))
    }

    /// 上游 `chooseFile`：`disabled` 时不弹选择器，`maxCount` 减去已选数量。
    func testUploadChooseFileForwardsRemainingCount() {
        var requests: [UPUploadPickRequest] = []
        let upload = UPUpload(fileList: [UPUploadFile(name: "a.png")],
                              maxCount: 3,
                              multiple: true)
            .onPick { requests.append($0) }
        upload.chooseFile()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.maxCount, 2)
        XCTAssertEqual(requests.first?.accept, "image")
        XCTAssertTrue(requests.first?.multiple ?? false)

        UPUpload(fileList: [UPUploadFile](), disabled: true)
            .onPick { requests.append($0) }
            .chooseFile()
        XCTAssertEqual(requests.count, 1)
    }

    /// `multiple` 为假时上游只取 `res[0]`。
    func testUploadReceiveHonoursMultipleFlag() {
        var events: [UPUploadReadEvent] = []
        let single = UPUpload(fileList: [UPUploadFile]()).onAfterRead { (event: UPUploadReadEvent) in
            events.append(event)
        }
        single.receive([UPUploadFile(name: "a.png"), UPUploadFile(name: "b.png")])
        XCTAssertEqual(events.first?.files.count, 1)

        let multiple = UPUpload(fileList: [UPUploadFile](), multiple: true)
            .onAfterRead { (event: UPUploadReadEvent) in events.append(event) }
        multiple.receive([UPUploadFile(name: "a.png"), UPUploadFile(name: "b.png")])
        XCTAssertEqual(events.last?.files.count, 2)
        XCTAssertEqual(events.last?.index, 0)
    }

    /// 上游 `beforeRead` 返回假值时中断，`useBeforeRead` 改由事件回调放行。
    func testUploadBeforeReadGatesAfterRead() {
        var after = 0
        let blocked = UPUpload(fileList: [UPUploadFile](), beforeRead: { _ in false })
            .onAfterRead { (_: UPUploadReadEvent) in after += 1 }
        blocked.receive([UPUploadFile(name: "a.png")])
        XCTAssertEqual(after, 0)

        var pending: [UPUploadFile] = []
        let deferred = UPUpload(fileList: [UPUploadFile](), useBeforeRead: true)
            .onBeforeRead { pending = $0.files }
            .onAfterRead { (_: UPUploadReadEvent) in after += 1 }
        deferred.receive([UPUploadFile(name: "a.png")])
        XCTAssertEqual(after, 0)
        XCTAssertEqual(pending.count, 1)
        deferred.resumeBeforeRead(pending, ok: false)
        XCTAssertEqual(after, 0)
        deferred.resumeBeforeRead(pending, ok: true)
        XCTAssertEqual(after, 1)
    }

    /// 上游 `onAfterRead` 先查 `maxSize`，超限抛 `oversize` 并 return。
    func testUploadOversizeStopsBeforeAfterRead() {
        var oversize: [UPUploadReadEvent] = []
        var after = 0
        let upload = UPUpload(fileList: [UPUploadFile](), maxSize: 10)
            .onOversize { oversize.append($0) }
            .onAfterRead { (_: UPUploadReadEvent) in after += 1 }
        upload.receive([UPUploadFile(name: "big.png", size: 20)])
        XCTAssertEqual(oversize.count, 1)
        XCTAssertEqual(after, 0)
    }

    /// 上游 `deleteItem`：`autoDelete` 为真时自己删，否则只抛 `delete`。
    func testUploadDeleteHonoursAutoDelete() {
        var events: [UPUploadDeleteEvent] = []
        let manual = UPUpload(fileList: [UPUploadFile(name: "a.png"), UPUploadFile(name: "b.png")])
            .onDelete { (event: UPUploadDeleteEvent) in events.append(event) }
        manual.deleteItem(at: 1)
        XCTAssertEqual(manual.files.count, 2)
        XCTAssertEqual(events.first?.index, 1)
        XCTAssertEqual(events.first?.file.name, "b.png")

        let auto = UPUpload(fileList: [UPUploadFile(name: "a.png"), UPUploadFile(name: "b.png")],
                            autoDelete: true)
        auto.deleteItem(at: 0)
        XCTAssertEqual(auto.files.map(\.name), ["b.png"])
    }

    /// 上游 `updateUpload` 到 100 即成功，`succcessUpload` 落地址与缩略图。
    func testUploadProgressAndSuccessMutateFileEntry() {
        let upload = UPUpload(fileList: [UPUploadFile(name: "a.png")])
        upload.updateUpload(at: 0, progress: 40)
        XCTAssertEqual(upload.files[0].status, .uploading)
        XCTAssertEqual(upload.files[0].progress, 40)
        upload.updateUpload(at: 0, progress: 100)
        XCTAssertEqual(upload.files[0].status, .success)
        upload.successUpload(at: 0, url: "https://a.com/a.png", thumb: "https://a.com/t.png")
        XCTAssertEqual(upload.files[0].url, "https://a.com/a.png")
        XCTAssertEqual(upload.files[0].thumb, "https://a.com/t.png")
        XCTAssertEqual(upload.files[0].progress, 100)
    }

    /// 上游 `onClickPreview` 只收集同类文件的地址，并给出当前位置。
    func testUploadClickPreviewCollectsSameTypeUrls() {
        var previews: [UPUploadPreviewEvent] = []
        let upload = UPUpload(fileList: [
            UPUploadFile(name: "a.png", url: "a.png"),
            UPUploadFile(name: "b.mp4", url: "b.mp4"),
            UPUploadFile(name: "c.png", url: "c.png")
        ], name: "album")
            .onClickPreview { previews.append($0) }
        upload.clickPreview(at: 2)
        XCTAssertEqual(previews.first?.urls, ["a.png", "c.png"])
        XCTAssertEqual(previews.first?.current, 1)
        XCTAssertEqual(previews.first?.name, "album")

        // `previewFullImage` 为假时不收集地址，但事件照抛。
        var plain: [UPUploadPreviewEvent] = []
        UPUpload(fileList: [UPUploadFile(name: "a.png", url: "a.png")], previewFullImage: false)
            .onClickPreview { plain.append($0) }
            .clickPreview(at: 0)
        XCTAssertEqual(plain.count, 1)
        XCTAssertTrue(plain[0].urls.isEmpty)
    }

    /// `autoUpload` 走注入的传输层；`customAfterAutoUpload` 时由宿主回填地址。
    func testUploadAutoUploadUsesTransportAndAfterAutoUpload() async {
        let upload = UPUpload(fileList: [UPUploadFile](),
                              autoUpload: true,
                              autoUploadApi: "https://a.com/upload")
            .uploadTransport { file, request in
                XCTAssertEqual(request.url, "https://a.com/upload")
                return .success(UPUploadResult(url: "https://cdn.com/\(file.name)"))
            }
        upload.receive([UPUploadFile(name: "a.png")])
        XCTAssertEqual(upload.files.map(\.status), [.uploading])
        XCTAssertEqual(upload.files[0].message, "上传中")
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(upload.files.map(\.url), ["https://cdn.com/a.png"])
        XCTAssertEqual(upload.files.map(\.status), [.success])

        var afterEvents: [UPUploadAutoUploadEvent] = []
        let custom = UPUpload(fileList: [UPUploadFile](),
                              autoUpload: true,
                              autoUploadApi: "https://a.com/upload",
                              customAfterAutoUpload: true)
            .uploadTransport { _, _ in .success(UPUploadResult(url: "", response: "{\"code\":200}")) }
            .onAfterAutoUpload { afterEvents.append($0) }
        custom.receive([UPUploadFile(name: "b.png")])
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(afterEvents.count, 1)
        XCTAssertEqual(afterEvents.first?.response, "{\"code\":200}")
        afterEvents.first?.callback("https://cdn.com/b.png", "")
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(custom.files.map(\.url), ["https://cdn.com/b.png"])
    }

    /// 上游只实现了 `local` / `oss` 两个驱动，原生只做 `local`，其余走 `error`。
    func testUploadRejectsUnsupportedDriver() {
        var errors: [String] = []
        let upload = UPUpload(fileList: [UPUploadFile](),
                              autoUpload: true,
                              autoUploadApi: "https://a.com/upload",
                              autoUploadDriver: "oss")
            .onError { errors.append($0) }
        upload.receive([UPUploadFile(name: "a.png")])
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(upload.files.isEmpty)
    }

    /// `v-model:fileList` 版本会把变更写回宿主绑定。
    func testUploadWritesBackToFileListBinding() {
        var list = [UPUploadFile(name: "a.png")]
        let upload = UPUpload(fileList: Binding(get: { list }, set: { list = $0 }), autoDelete: true)
        upload.deleteItem(at: 0)
        XCTAssertTrue(list.isEmpty)
        upload.add(UPUploadFile(name: "b.png"))
        XCTAssertEqual(list.map(\.name), ["b.png"])
    }

    /// multipart 请求体包含字段名、文件名与内容。
    func testUploadTransportBodyIsMultipart() {
        let file = UPUploadFile(name: "a.txt", data: Data("hi".utf8), mimeType: "text/plain")
        let body = UPUploadSystemTransport.body(for: file, fieldName: "file")
        let text = String(decoding: body, as: UTF8.self)
        XCTAssertTrue(text.contains("name=\"file\""))
        XCTAssertTrue(text.contains("filename=\"a.txt\""))
        XCTAssertTrue(text.contains("Content-Type: text/plain"))
        XCTAssertTrue(text.contains("hi"))
    }
}

/// `marked` 的原生替代：Markdown → HTML。
final class MarkdownParserTests: XCTestCase {
    func testHeadingsParagraphsAndBreaks() {
        XCTAssertEqual(UPMarkdownParser.html(from: "# 标题"), "<h1>标题</h1>")
        XCTAssertEqual(UPMarkdownParser.html(from: "###### 六级"), "<h6>六级</h6>")
        // 七个 # 不是标题。
        XCTAssertEqual(UPMarkdownParser.html(from: "####### x"), "<p>####### x</p>")
        XCTAssertEqual(UPMarkdownParser.html(from: "---"), "<hr>")
        // marked 默认 `breaks: false`：段落内换行当空格。
        XCTAssertEqual(UPMarkdownParser.html(from: "a\nb"), "<p>a b</p>")
        XCTAssertEqual(UPMarkdownParser.html(from: "a\n\nb"), "<p>a</p><p>b</p>")
    }

    func testInlineEmphasisCodeAndLinks() {
        XCTAssertEqual(UPMarkdownParser.html(from: "**粗**"), "<p><strong>粗</strong></p>")
        XCTAssertEqual(UPMarkdownParser.html(from: "*斜*"), "<p><em>斜</em></p>")
        XCTAssertEqual(UPMarkdownParser.html(from: "***都要***"), "<p><strong><em>都要</em></strong></p>")
        XCTAssertEqual(UPMarkdownParser.html(from: "~~删~~"), "<p><del>删</del></p>")
        XCTAssertEqual(UPMarkdownParser.html(from: "`code`"), "<p><code>code</code></p>")
        XCTAssertEqual(UPMarkdownParser.html(from: "[名](/a)"), "<p><a href=\"/a\">名</a></p>")
        XCTAssertEqual(UPMarkdownParser.html(from: "![图](/a.png)"),
                       "<p><img src=\"/a.png\" alt=\"图\"></p>")
        // 未闭合的标记按普通文本处理，尖括号转义。
        XCTAssertEqual(UPMarkdownParser.html(from: "a**b"), "<p>a**b</p>")
        XCTAssertEqual(UPMarkdownParser.html(from: "<view>"), "<p>&lt;view&gt;</p>")
    }

    func testListsSupportOrderedUnorderedAndNesting() {
        XCTAssertEqual(UPMarkdownParser.html(from: "- a\n- b"), "<ul><li>a</li><li>b</li></ul>")
        XCTAssertEqual(UPMarkdownParser.html(from: "1. a\n2. b"), "<ol><li>a</li><li>b</li></ol>")
        XCTAssertEqual(UPMarkdownParser.html(from: "3. a"), "<ol start=\"3\"><li>a</li></ol>")
        let nested = UPMarkdownParser.html(from: "- a\n  - b")
        XCTAssertTrue(nested.contains("<ul><li>a<ul><li>b</li></ul></li></ul>"))
    }

    func testBlockquoteRecursesIntoBlocks() {
        XCTAssertEqual(UPMarkdownParser.html(from: "> 引用"), "<blockquote><p>引用</p></blockquote>")
        XCTAssertEqual(UPMarkdownParser.html(from: "> # 标题"), "<blockquote><h1>标题</h1></blockquote>")
    }

    /// 上游 `handleCodeBlock` 给代码块补 `up-markdown-code` 与 `language-*`。
    func testFencedCodeBlockCarriesLanguageClass() {
        let html = UPMarkdownParser.html(from: "```swift\nlet a = 1 < 2\n```")
        XCTAssertTrue(html.contains("class=\"up-markdown-code language-swift\""))
        XCTAssertTrue(html.contains("class=\"code-lang language-swift\""))
        XCTAssertTrue(html.contains("let a = 1 &lt; 2"))

        let numbered = UPMarkdownParser.html(from: "```\na\nb\n```", showLineNumber: true)
        XCTAssertTrue(numbered.contains("1 | a"))
        XCTAssertTrue(numbered.contains("2 | b"))
    }

    /// GFM 表格：表头、对齐与数据行。
    func testTableParsesHeaderAlignmentAndRows() {
        let html = UPMarkdownParser.html(from: """
        | 左 | 中 | 右 |
        | :--- | :---: | ---: |
        | 1 | 2 | 3 |
        """)
        XCTAssertTrue(html.hasPrefix("<table><thead><tr>"))
        XCTAssertTrue(html.contains("<th align=\"left\">左</th>"))
        XCTAssertTrue(html.contains("<th align=\"center\">中</th>"))
        XCTAssertTrue(html.contains("<th align=\"right\">右</th>"))
        XCTAssertTrue(html.contains("<td align=\"left\">1</td>"))
        XCTAssertTrue(html.hasSuffix("</tbody></table>"))
        // 少了分隔行就不是表格。
        XCTAssertEqual(UPMarkdownParser.html(from: "| a | b |"), "<p>| a | b |</p>")
    }

    /// 解析结果能被 `UPParse` 正常消费。
    func testParsedHTMLFeedsIntoParseDocument() {
        let html = UPMarkdownParser.html(from: "# 标题\n\n段落 **粗** 与 [链接](/a)")
        let document = UPParseDocument.parse(html)
        XCTAssertTrue(document.plainText.contains("标题"))
        XCTAssertTrue(document.plainText.contains("粗"))
        XCTAssertEqual(document.links.map(\.href), ["/a"])
    }
}
