import XCTest
@testable import UltraUI

@MainActor
final class NovelReaderClockBox {
    var now: Double
    init(_ now: Double) { self.now = now }
    var clock: () -> Double { { self.now } }
}

@MainActor
enum NovelReaderFixture {
    static var chapters: [UPNovelReaderChapter] {
        [
            UPNovelReaderChapter(id: "c1", index: 0, title: "第一章", content: "第一章内容"),
            UPNovelReaderChapter(id: "c2", index: 1, title: "第二章", content: "第二章内容"),
            UPNovelReaderChapter(id: "c3", index: 2, title: "第三章", content: "第三章内容")
        ]
    }
}

final class NovelReaderModelTests: XCTestCase {
    func testNormalizeContentSplitsParagraphsAndTracksOffsets() {
        let content = UPNovelReaderContent.normalize("第一段\n第二段")

        XCTAssertEqual(content.paragraphs.count, 2)
        XCTAssertEqual(content.paragraphs[0].index, 0)
        XCTAssertEqual(content.paragraphs[0].text, "第一段")
        XCTAssertEqual(content.paragraphs[0].startOffset, 0)
        XCTAssertEqual(content.paragraphs[0].endOffset, 3)
        XCTAssertEqual(content.paragraphs[1].startOffset, 4)
        XCTAssertEqual(content.paragraphs[1].endOffset, 7)
        XCTAssertEqual(content.text, "第一段\n第二段")
        XCTAssertEqual(content.length, 7)
    }

    func testNormalizeContentAcceptsArrayAndCollapsesEmptyInput() {
        let content = UPNovelReaderContent.normalize(["第一段", "第二段\n第三段"])
        XCTAssertEqual(content.paragraphs.map(\.text), ["第一段", "第二段", "第三段"])
        XCTAssertEqual(content.length, 11)

        XCTAssertEqual(UPNovelReaderContent.normalize(""), .empty)
        XCTAssertEqual(UPNovelReaderContent.normalize("\n\n"), .empty)
        XCTAssertEqual(UPNovelReaderContent.normalize(["", ""]), .empty)
    }

    func testNormalizeProgressClampsOffsetAndDerivesChapterProgress() {
        let chapter = UPNovelReaderChapter(id: "c1", index: 2, title: "第三章", content: "第一章内容")
        let progress = UPNovelReaderProgress.normalize(
            UPNovelReaderProgress(chapterId: "stale", chapterIndex: 9, pageIndex: -3, pageCount: -1,
                                  charOffset: 10, chapterProgress: 0, totalProgress: 4, scrollTop: -8, updatedAt: 12),
            chapter: chapter
        )

        XCTAssertEqual(progress.chapterId, "stale")
        XCTAssertEqual(progress.chapterIndex, 2)
        XCTAssertEqual(progress.pageIndex, 0)
        XCTAssertEqual(progress.pageCount, 0)
        XCTAssertEqual(progress.charOffset, 5)
        XCTAssertEqual(progress.chapterProgress, 1, accuracy: 0.0001)
        XCTAssertEqual(progress.totalProgress, 1, accuracy: 0.0001)
        XCTAssertEqual(progress.scrollTop, 0, accuracy: 0.0001)
        XCTAssertEqual(progress.updatedAt, 12, accuracy: 0.0001)
    }

    func testNormalizeProgressFallsBackToChapterIdentity() {
        let chapter = UPNovelReaderChapter(id: "c9", index: 4, title: "第五章", content: "")
        let progress = UPNovelReaderProgress.normalize(nil, chapter: chapter)

        XCTAssertEqual(progress.chapterId, "c9")
        XCTAssertEqual(progress.chapterIndex, 4)
        XCTAssertEqual(progress.charOffset, 0)
        XCTAssertEqual(progress.chapterProgress, 0, accuracy: 0.0001)

        let orphan = UPNovelReaderProgress.normalize(nil, chapter: nil)
        XCTAssertEqual(orphan.chapterId, "")
        XCTAssertEqual(orphan.chapterIndex, 0)
    }

    func testDefaultSettingsMatchUpstream() {
        let settings = UPNovelReaderSettings.default

        XCTAssertEqual(settings.theme, "day")
        XCTAssertEqual(settings.fontSize, 18, accuracy: 0.0001)
        XCTAssertEqual(settings.lineHeight, 1.8, accuracy: 0.0001)
        XCTAssertEqual(settings.paragraphSpacing, 16, accuracy: 0.0001)
        XCTAssertEqual(settings.contentWidth, .text("92%"))
        XCTAssertEqual(settings.fontFamily, "system")
        XCTAssertEqual(settings.fontWeight, 400)
        XCTAssertTrue(settings.animation)

        XCTAssertEqual(UPNovelReaderSettings.merge([nil, nil]), .default)
    }

    func testMergeSettingsClampsEveryNumericField() {
        let merged = UPNovelReaderSettings.merge([
            UPNovelReaderSettingsPatch(theme: "night", fontSize: 999),
            UPNovelReaderSettingsPatch(lineHeight: 0.2, paragraphSpacing: -5,
                                       contentWidth: .text("   "), fontWeight: 700, animation: false)
        ])

        XCTAssertEqual(merged.theme, "night")
        XCTAssertEqual(merged.fontSize, 48, accuracy: 0.0001)
        XCTAssertEqual(merged.lineHeight, 1, accuracy: 0.0001)
        XCTAssertEqual(merged.paragraphSpacing, 0, accuracy: 0.0001)
        XCTAssertEqual(merged.contentWidth, .text("92%"))
        XCTAssertEqual(merged.fontWeight, 600)
        XCTAssertFalse(merged.animation)

        let lowered = UPNovelReaderSettings.merge([UPNovelReaderSettingsPatch(fontSize: 4, paragraphSpacing: 999)])
        XCTAssertEqual(lowered.fontSize, 12, accuracy: 0.0001)
        XCTAssertEqual(lowered.paragraphSpacing, 80, accuracy: 0.0001)
        XCTAssertEqual(lowered.fontWeight, 400)
    }

    func testContentWidthNormalizeAndResolve() {
        XCTAssertEqual(UPNovelReaderContentWidth.normalize(nil), .text("92%"))
        XCTAssertEqual(UPNovelReaderContentWidth.normalize(.number(10)), .number(40))
        XCTAssertEqual(UPNovelReaderContentWidth.normalize(.number(999)), .number(100))
        XCTAssertEqual(UPNovelReaderContentWidth.normalize(.number(.nan)), .number(92))
        XCTAssertEqual(UPNovelReaderContentWidth.normalize(.text("  80%  ")), .text("80%"))
        XCTAssertEqual(UPNovelReaderContentWidth.normalize(.text("   ")), .text("92%"))

        XCTAssertEqual(UPNovelReaderContentWidth.text("92%").resolve(containerWidth: 400), 368, accuracy: 0.0001)
        XCTAssertEqual(UPNovelReaderContentWidth.text("600px").resolve(containerWidth: 400), 400, accuracy: 0.0001)
        XCTAssertEqual(UPNovelReaderContentWidth.number(92).resolve(containerWidth: 400), 92, accuracy: 0.0001)
        XCTAssertEqual(UPNovelReaderContentWidth.text("bogus").resolve(containerWidth: 400), 400, accuracy: 0.0001)
    }

    func testModeNormalizeKeepsOnlyKnownValues() {
        XCTAssertEqual(UPNovelReaderMode.normalize("page"), .page)
        XCTAssertEqual(UPNovelReaderMode.normalize("scroll"), .scroll)
        XCTAssertEqual(UPNovelReaderMode.normalize("waterfall"), .scroll)
        XCTAssertEqual(UPNovelReaderMode.normalize(""), .scroll)
    }

    func testThemeTokensResolveFallsBackToDay() {
        let night = UPNovelReaderThemeTokens.resolve("night")
        XCTAssertEqual(night.theme, "night")
        XCTAssertEqual(night.background, "#202124")
        XCTAssertEqual(night.text, "#d6d7da")
        XCTAssertEqual(night.muted, "#9ca0a8")
        XCTAssertEqual(night.toolbar, "#292b30")
        XCTAssertEqual(night.border, "rgba(214,215,218,0.16)")
        XCTAssertEqual(night.active, "#7da7ff")
        XCTAssertEqual(night.disabled, "#62656d")

        let fallback = UPNovelReaderThemeTokens.resolve("sepia")
        XCTAssertEqual(fallback.theme, "day")
        XCTAssertEqual(fallback.background, "#f7f8fa")
        XCTAssertEqual(fallback.active, "#2979ff")

        XCTAssertEqual(UPNovelReaderThemeTokens.resolve("paper").background, "#f3ead7")
        XCTAssertEqual(UPNovelReaderThemeTokens.resolve("green").background, "#e7f1e4")
        XCTAssertEqual(UPNovelReaderThemeTokens.resolve("dark").background, "#111214")
    }

    func testBookmarkIdentityAndToggle() {
        let first = UPNovelReaderBookmark(chapterId: "c1", chapterIndex: 0, charOffset: 12, excerpt: "摘要")
        XCTAssertEqual(first.id, "c1:12")
        XCTAssertEqual(UPNovelReaderBookmark(chapterId: "c1", chapterIndex: 0, charOffset: -4).id, "c1:0")

        let added = UPNovelReaderBookmark.toggle([], bookmark: first)
        XCTAssertEqual(added.map(\.id), ["c1:12"])

        let removed = UPNovelReaderBookmark.toggle(added, bookmark: first)
        XCTAssertTrue(removed.isEmpty)

        let second = UPNovelReaderBookmark(chapterId: "c2", chapterIndex: 1, charOffset: 0)
        XCTAssertEqual(UPNovelReaderBookmark.toggle(added, bookmark: second).map(\.id), ["c1:12", "c2:0"])
    }

    func testTextMeasureUsesCJKWhitespaceAndLatinRatios() {
        XCTAssertEqual(UPNovelReaderTextMeasure.width("一二", fontSize: 10), 20, accuracy: 0.0001)
        XCTAssertEqual(UPNovelReaderTextMeasure.width("ab", fontSize: 10), 11.2, accuracy: 0.0001)
        XCTAssertEqual(UPNovelReaderTextMeasure.width(" ", fontSize: 10), 2.8, accuracy: 0.0001)
        XCTAssertEqual(UPNovelReaderTextMeasure.width("", fontSize: 10), 0, accuracy: 0.0001)
    }
}

final class NovelReaderLayoutTests: XCTestCase {
    private let measure: (String, Double) -> Double = { text, _ in Double(text.count) * 10 }

    func testWrapTextBreaksOversizedTokenIntoSingleCharacters() {
        let lines = UPNovelReaderLayout.wrapText("abcdef", width: 25, measure: { self.measure($0, 10) })

        XCTAssertEqual(lines.map(\.text), ["ab", "cd", "ef"])
        XCTAssertEqual(lines.map(\.startOffset), [0, 2, 4])
        XCTAssertEqual(lines.map(\.endOffset), [2, 4, 6])
    }

    func testWrapTextKeepsEmptyParagraphAsSingleEmptyLine() {
        let lines = UPNovelReaderLayout.wrapText("", width: 100, measure: { self.measure($0, 10) })

        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0].text, "")
        XCTAssertEqual(lines[0].startOffset, 0)
        XCTAssertEqual(lines[0].endOffset, 0)
    }

    func testPaginateSplitsParagraphsAcrossPagesWithGlobalOffsets() {
        let content = UPNovelReaderContent.normalize("一二三四\n五六")
        var settings = UPNovelReaderSettings.default
        settings.fontSize = 10
        settings.lineHeight = 2
        settings.paragraphSpacing = 0

        let layout = UPNovelReaderLayout.paginate(
            paragraphs: content.paragraphs, width: 20, height: 40,
            settings: settings, measure: { self.measure($0, settings.fontSize) }
        )

        XCTAssertEqual(layout.pageCount, 2)
        XCTAssertEqual(layout.pages[0].index, 0)
        XCTAssertEqual(layout.pages[0].text, "一二\n三四")
        XCTAssertEqual(layout.pages[0].startOffset, 0)
        XCTAssertEqual(layout.pages[0].endOffset, 4)
        XCTAssertEqual(layout.pages[0].lines.map(\.paragraphIndex), [0, 0])
        XCTAssertEqual(layout.pages[1].text, "五六")
        XCTAssertEqual(layout.pages[1].startOffset, 5)
        XCTAssertEqual(layout.pages[1].endOffset, 7)
        XCTAssertEqual(layout.pages[1].lines.map(\.paragraphIndex), [1])
    }

    func testPaginateEmptyParagraphsProducesEmptyLayout() {
        let layout = UPNovelReaderLayout.paginate(
            paragraphs: [], width: 100, height: 100,
            settings: .default, measure: { self.measure($0, 18) }
        )

        XCTAssertEqual(layout, .empty)
        XCTAssertEqual(layout.pageCount, 0)
    }

    func testAnchorResolvesPageAndLocalOffset() {
        let content = UPNovelReaderContent.normalize("一二三四\n五六")
        var settings = UPNovelReaderSettings.default
        settings.fontSize = 10
        settings.lineHeight = 2
        settings.paragraphSpacing = 0
        let layout = UPNovelReaderLayout.paginate(
            paragraphs: content.paragraphs, width: 20, height: 40,
            settings: settings, measure: { self.measure($0, settings.fontSize) }
        )

        XCTAssertEqual(layout.anchor(charOffset: 0), UPNovelReaderAnchor(pageIndex: 0, localOffset: 0))
        XCTAssertEqual(layout.anchor(charOffset: 6), UPNovelReaderAnchor(pageIndex: 1, localOffset: 1))
        XCTAssertEqual(layout.anchor(charOffset: 100), UPNovelReaderAnchor(pageIndex: 1, localOffset: 2))
        XCTAssertEqual(UPNovelReaderLayout.empty.anchor(charOffset: 5), UPNovelReaderAnchor(pageIndex: 0, localOffset: 0))
    }

    func testLayoutKeyChangesWithGeometryAndTypography() {
        var settings = UPNovelReaderSettings.default
        let base = UPNovelReaderLayout.layoutKey(chapterId: "c1", settings: settings, width: 300, height: 500)

        XCTAssertEqual(base, UPNovelReaderLayout.layoutKey(chapterId: "c1", settings: settings, width: 300, height: 500))
        XCTAssertNotEqual(base, UPNovelReaderLayout.layoutKey(chapterId: "c2", settings: settings, width: 300, height: 500))
        XCTAssertNotEqual(base, UPNovelReaderLayout.layoutKey(chapterId: "c1", settings: settings, width: 320, height: 500))
        XCTAssertNotEqual(base, UPNovelReaderLayout.layoutKey(chapterId: "c1", settings: settings, width: 300, height: 520))

        settings.fontSize = 22
        XCTAssertNotEqual(base, UPNovelReaderLayout.layoutKey(chapterId: "c1", settings: settings, width: 300, height: 500))
    }
}

@MainActor
final class NovelReaderStateTests: XCTestCase {
    func testDefaultsMirrorUpstreamProps() {
        let reader = UPNovelReader()

        XCTAssertTrue(reader.chapters.isEmpty)
        XCTAssertNil(reader.currentChapter)
        XCTAssertFalse(reader.loading)
        XCTAssertNil(reader.error)
        XCTAssertEqual(reader.bookId, "")
        XCTAssertEqual(reader.storageKey, "")
        XCTAssertTrue(reader.persist)
        XCTAssertEqual(reader.resolvedMode, .scroll)
        XCTAssertTrue(reader.showBack)
        XCTAssertFalse(reader.autoBack)
        XCTAssertEqual(reader.backIcon, "arrow-left")
        XCTAssertTrue(reader.safeAreaInsetTop)
        XCTAssertTrue(reader.safeAreaInsetBottom)
        XCTAssertEqual(reader.preloadThreshold, 2)
        XCTAssertTrue(reader.pageAnimation)
        XCTAssertEqual(reader.controlsAutoHide, 0)
        XCTAssertEqual(reader.resolvedSettings, .default)
        XCTAssertEqual(reader.themeTokens.theme, "day")
        XCTAssertTrue(reader.effectiveAnimation)
        XCTAssertFalse(reader.controlsVisible)
        XCTAssertEqual(reader.layout, .empty)
        XCTAssertEqual(reader.pageIndex, 0)
        XCTAssertEqual(reader.readingTime, 0, accuracy: 0.0001)
        XCTAssertNil(reader.pendingChapter)
        XCTAssertTrue(reader.resolvedBookmarks.isEmpty)
    }

    func testEffectiveAnimationRequiresBothFlags() {
        XCTAssertFalse(UPNovelReader(pageAnimation: false).effectiveAnimation)
        XCTAssertFalse(UPNovelReader(defaultSettings: UPNovelReaderSettingsPatch(animation: false)).effectiveAnimation)
    }

    func testChapterNavigationFlagsSkipLockedChapters() {
        let chapters = [
            UPNovelReaderChapter(id: "c1", index: 0, title: "第一章", content: "一"),
            UPNovelReaderChapter(id: "c2", index: 1, title: "第二章", content: "二"),
            UPNovelReaderChapter(id: "c3", index: 2, title: "第三章", content: "三", isLocked: true)
        ]
        let middle = UPNovelReader(chapters: chapters, currentChapter: chapters[1], persist: false)

        XCTAssertEqual(middle.currentChapterIndex, 1)
        XCTAssertTrue(middle.hasPreviousChapter)
        XCTAssertFalse(middle.hasNextChapter)

        let first = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false)
        XCTAssertFalse(first.hasPreviousChapter)
        XCTAssertTrue(first.hasNextChapter)
    }

    func testCurrentChapterIndexFallsBackToIdLookup() {
        let chapters = [
            UPNovelReaderChapter(id: "c1", index: .nan, title: "第一章", content: "一"),
            UPNovelReaderChapter(id: "c2", index: .nan, title: "第二章", content: "二")
        ]
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[1], persist: false)

        XCTAssertEqual(reader.currentChapterIndex, 1)
    }

    func testRequestChapterEmitsPayloadAndBlocksWhilePending() {
        let chapters = NovelReaderFixture.chapters
        var requests: [UPNovelReaderChapterRequest] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false)
            .onChapterRequest { requests.append($0) }

        XCTAssertTrue(reader.requestChapter(direction: "next"))
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].targetIndex, 1)
        XCTAssertEqual(requests[0].targetId, "c2")
        XCTAssertEqual(requests[0].direction, "next")
        XCTAssertFalse(requests[0].requestId.isEmpty)
        XCTAssertEqual(reader.pendingChapter?.targetId, "c2")

        XCTAssertFalse(reader.requestChapter(direction: "next"))
        XCTAssertEqual(requests.count, 1)
    }

    func testRequestChapterRejectsMissingLockedAndLoadingTargets() {
        var chapters = NovelReaderFixture.chapters
        chapters[2] = UPNovelReaderChapter(id: "c3", index: 2, title: "第三章", content: "三", isLocked: true)
        var requests: [UPNovelReaderChapterRequest] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[1], persist: false)
            .onChapterRequest { requests.append($0) }

        XCTAssertFalse(reader.requestChapter(direction: "next"))
        XCTAssertFalse(reader.requestChapter(direction: "catalog", targetIndex: 9))
        XCTAssertTrue(requests.isEmpty)

        let loading = UPNovelReader(chapters: chapters, currentChapter: chapters[0], loading: true, persist: false)
            .onChapterRequest { requests.append($0) }
        XCTAssertFalse(loading.requestChapter(direction: "next"))
        XCTAssertTrue(requests.isEmpty)
    }

    func testSelectChapterAndBookmarkRouteThroughCatalogRequests() {
        let chapters = NovelReaderFixture.chapters
        var requests: [UPNovelReaderChapterRequest] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false)
            .onChapterRequest { requests.append($0) }

        reader.selectChapter(chapters[2])
        XCTAssertEqual(requests.map(\.direction), ["catalog"])
        XCTAssertEqual(requests[0].targetIndex, 2)
    }

    func testSelectBookmarkWithinCurrentChapterEmitsProgress() {
        let chapters = NovelReaderFixture.chapters
        var progresses: [UPNovelReaderProgress] = []
        var requests: [UPNovelReaderChapterRequest] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false)
            .onProgressChange { progresses.append($0) }
            .onChapterRequest { requests.append($0) }

        reader.selectBookmark(UPNovelReaderBookmark(chapterId: "c1", chapterIndex: 0, charOffset: 3, pageIndex: 0, scrollTop: 42))

        XCTAssertTrue(requests.isEmpty)
        XCTAssertEqual(progresses.count, 1)
        XCTAssertEqual(progresses[0].charOffset, 3)
        XCTAssertEqual(progresses[0].scrollTop, 42, accuracy: 0.0001)

        reader.selectBookmark(UPNovelReaderBookmark(chapterId: "c3", chapterIndex: 2, charOffset: 0))
        XCTAssertEqual(requests.map(\.direction), ["catalog"])
        XCTAssertEqual(requests[0].targetIndex, 2)
    }

    func testRetryClearsPendingChapterAndEmitsPreviousRequest() {
        let chapters = NovelReaderFixture.chapters
        var retries: [UPNovelReaderChapterRequest?] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false)
            .onRetry { retries.append($0) }

        XCTAssertTrue(reader.requestChapter(direction: "next"))
        reader.handleRetry()

        XCTAssertNil(reader.pendingChapter)
        XCTAssertEqual(retries.count, 1)
        XCTAssertEqual(retries[0]?.targetId, "c2")
    }
}

@MainActor
final class NovelReaderInteractionTests: XCTestCase {
    private func pageReader(
        chapters: [UPNovelReaderChapter],
        currentIndex: Int,
        clock: NovelReaderClockBox = NovelReaderClockBox(0)
    ) -> UPNovelReader {
        UPNovelReader(
            chapters: chapters,
            currentChapter: chapters[currentIndex],
            persist: false,
            defaultSettings: UPNovelReaderSettingsPatch(
                fontSize: 12, lineHeight: 1, paragraphSpacing: 0, contentWidth: .text("100%")
            ),
            mode: "page",
            clock: clock.clock
        )
    }

    func testPageModeTapRightAdvancesPageThenRequestsNextChapter() {
        let chapters = [
            UPNovelReaderChapter(id: "c1", index: 0, title: "第一章", content: "一二三四五六"),
            UPNovelReaderChapter(id: "c2", index: 1, title: "第二章", content: "第二章内容")
        ]
        var progresses: [UPNovelReaderProgress] = []
        var requests: [UPNovelReaderChapterRequest] = []
        let reader = pageReader(chapters: chapters, currentIndex: 0)
            .onProgressChange { progresses.append($0) }
            .onChapterRequest { requests.append($0) }

        reader.refreshLayout(width: 24, height: 88)
        XCTAssertEqual(reader.layout.pageCount, 2)

        reader.handleTapZone(.right)
        XCTAssertEqual(reader.pageIndex, 1)
        XCTAssertEqual(progresses.count, 1)
        XCTAssertEqual(progresses[0].charOffset, 4)
        XCTAssertEqual(progresses[0].pageIndex, 1)
        XCTAssertEqual(progresses[0].pageCount, 2)
        XCTAssertEqual(progresses[0].chapterProgress, 1, accuracy: 0.0001)

        reader.handleTapZone(.right)
        XCTAssertEqual(requests.map(\.direction), ["next"])
        XCTAssertEqual(requests[0].targetId, "c2")
    }

    func testPageModeTapLeftFromFirstPageRequestsPreviousChapter() {
        let chapters = NovelReaderFixture.chapters
        var requests: [UPNovelReaderChapterRequest] = []
        let reader = pageReader(chapters: chapters, currentIndex: 1)
            .onChapterRequest { requests.append($0) }

        reader.refreshLayout(width: 200, height: 400)
        reader.handleTapZone(.left)

        XCTAssertEqual(requests.map(\.direction), ["previous"])
        XCTAssertEqual(requests[0].targetIndex, 0)
    }

    func testTapCenterTogglesControlsAndEmitsToolbarChange() {
        let chapters = NovelReaderFixture.chapters
        var toolbarChanges: [UPNovelReaderToolbarChange] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false)
            .onToolbarChange { toolbarChanges.append($0) }

        reader.handleTapZone(.center)
        XCTAssertTrue(reader.controlsVisible)
        XCTAssertEqual(toolbarChanges.count, 1)
        XCTAssertTrue(toolbarChanges[0].visible)
        XCTAssertEqual(toolbarChanges[0].reason, "tap-center")

        reader.hideControls()
        XCTAssertFalse(reader.controlsVisible)
        XCTAssertEqual(toolbarChanges.count, 2)
        XCTAssertFalse(toolbarChanges[1].visible)
        XCTAssertEqual(toolbarChanges[1].reason, "toolbar-action")

        reader.hideControls()
        XCTAssertEqual(toolbarChanges.count, 2)

        reader.handleTapZone(.center)
        reader.handleTapZone(.center)
        XCTAssertFalse(reader.controlsVisible)
        XCTAssertEqual(toolbarChanges.map(\.reason), ["tap-center", "toolbar-action", "tap-center", "tap-center"])
    }

    func testScrollModeLayoutReadyReportsZeroPages() {
        let chapters = NovelReaderFixture.chapters
        var layouts: [UPNovelReaderLayoutReady] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false)
            .onLayoutReady { layouts.append($0) }

        reader.refreshLayout(width: 320, height: 600)

        XCTAssertEqual(layouts.count, 1)
        XCTAssertEqual(layouts[0].mode, .scroll)
        XCTAssertEqual(layouts[0].width, 320, accuracy: 0.0001)
        XCTAssertEqual(layouts[0].height, 600, accuracy: 0.0001)
        XCTAssertEqual(layouts[0].pageCount, 0)
        XCTAssertEqual(reader.layout, .empty)
    }

    func testScrollProgressDerivesCharOffsetAndTotalProgress() {
        let chapters = NovelReaderFixture.chapters
        let clock = NovelReaderClockBox(777)
        var progresses: [UPNovelReaderProgress] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[1], persist: false, clock: clock.clock)
            .onProgressChange { progresses.append($0) }

        reader.refreshLayout(width: 300, height: 400)
        reader.handleScroll(scrollTop: 100, scrollHeight: 900)

        XCTAssertEqual(progresses.count, 1)
        XCTAssertEqual(progresses[0].chapterId, "c2")
        XCTAssertEqual(progresses[0].chapterProgress, 0.2, accuracy: 0.0001)
        XCTAssertEqual(progresses[0].totalProgress, 0.4, accuracy: 0.0001)
        XCTAssertEqual(progresses[0].charOffset, 1)
        XCTAssertEqual(progresses[0].scrollTop, 100, accuracy: 0.0001)
        XCTAssertEqual(progresses[0].updatedAt, 777, accuracy: 0.0001)
    }

    func testScrollProgressIsZeroWhenContentFitsViewport() {
        let chapters = NovelReaderFixture.chapters
        var progresses: [UPNovelReaderProgress] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false)
            .onProgressChange { progresses.append($0) }

        reader.refreshLayout(width: 300, height: 400)
        reader.handleScroll(scrollTop: 50, scrollHeight: 300)

        XCTAssertEqual(progresses[0].chapterProgress, 0, accuracy: 0.0001)
        XCTAssertEqual(progresses[0].charOffset, 0)
    }

    func testPrefetchIsEmittedOnceWhenNearingChapterEnd() {
        let chapters = [
            UPNovelReaderChapter(id: "c1", index: 0, title: "第一章", content: "一二三四五六"),
            UPNovelReaderChapter(id: "c2", index: 1, title: "第二章", content: "第二章内容")
        ]
        var prefetches: [UPNovelReaderChapterPrefetch] = []
        let reader = pageReader(chapters: chapters, currentIndex: 0)
            .onChapterPrefetch { prefetches.append($0) }

        reader.refreshLayout(width: 24, height: 88)
        reader.handleTapZone(.right)
        reader.handleTapZone(.left)

        XCTAssertEqual(prefetches.count, 1)
        XCTAssertEqual(prefetches[0].targetIndex, 1)
        XCTAssertEqual(prefetches[0].targetId, "c2")
        XCTAssertEqual(prefetches[0].direction, "next")
    }

    func testToggleBookmarkAddsExcerptThenRemovesIt() {
        let chapters = NovelReaderFixture.chapters
        var changes: [[UPNovelReaderBookmark]] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false)
            .onBookmarkChange { changes.append($0) }

        reader.toggleBookmark()
        XCTAssertEqual(reader.resolvedBookmarks.count, 1)
        XCTAssertEqual(reader.resolvedBookmarks[0].id, "c1:0")
        XCTAssertEqual(reader.resolvedBookmarks[0].excerpt, "第一章内容")
        XCTAssertTrue(reader.isCurrentBookmarked)
        XCTAssertEqual(changes.count, 1)

        reader.toggleBookmark()
        XCTAssertTrue(reader.resolvedBookmarks.isEmpty)
        XCTAssertFalse(reader.isCurrentBookmarked)
        XCTAssertEqual(changes.count, 2)
    }

    func testToggleBookmarkIsIgnoredWithoutCurrentChapter() {
        var changes: [[UPNovelReaderBookmark]] = []
        let reader = UPNovelReader(persist: false).onBookmarkChange { changes.append($0) }

        reader.toggleBookmark()

        XCTAssertTrue(changes.isEmpty)
        XCTAssertTrue(reader.resolvedBookmarks.isEmpty)
    }

    func testApplySettingsMergesAndEmitsSettingsChange() {
        let chapters = NovelReaderFixture.chapters
        var changes: [UPNovelReaderSettingsChange] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false, mode: "page")
            .onSettingsChange { changes.append($0) }

        reader.applySettings(UPNovelReaderSettingsPatch(theme: "night", fontSize: 99))

        XCTAssertEqual(reader.resolvedSettings.theme, "night")
        XCTAssertEqual(reader.resolvedSettings.fontSize, 48, accuracy: 0.0001)
        XCTAssertEqual(reader.themeTokens.theme, "night")
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes[0].mode, .page)
        XCTAssertEqual(changes[0].settings.theme, "night")
        XCTAssertEqual(changes[0].settings.fontSize, 48, accuracy: 0.0001)
    }

    func testControlledSettingsWinOverLocalChanges() {
        let chapters = NovelReaderFixture.chapters
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false,
                                   settings: UPNovelReaderSettingsPatch(theme: "paper", fontSize: 22))

        reader.applySettings(UPNovelReaderSettingsPatch(theme: "night"))

        XCTAssertEqual(reader.resolvedSettings.theme, "paper")
        XCTAssertEqual(reader.resolvedSettings.fontSize, 22, accuracy: 0.0001)
    }

    func testReadingTimeAccumulatesBetweenActivateAndPause() {
        let chapters = NovelReaderFixture.chapters
        let clock = NovelReaderClockBox(1000)
        var events: [UPNovelReaderReadingTime] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false, clock: clock.clock)
            .onReadingTimeChange { events.append($0) }

        reader.activateReading()
        clock.now = 3500
        reader.pauseReading()

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].delta, 2500, accuracy: 0.0001)
        XCTAssertEqual(events[0].readingTime, 2500, accuracy: 0.0001)
        XCTAssertEqual(events[0].updatedAt, 3500, accuracy: 0.0001)
        XCTAssertEqual(reader.readingTime, 2500, accuracy: 0.0001)

        reader.pauseReading()
        XCTAssertEqual(events.count, 1)
    }

    func testReadingDoesNotStartWhileLoadingOrErrored() {
        let chapters = NovelReaderFixture.chapters
        let clock = NovelReaderClockBox(1000)
        var events: [UPNovelReaderReadingTime] = []
        let loading = UPNovelReader(chapters: chapters, currentChapter: chapters[0], loading: true,
                                   persist: false, clock: clock.clock)
            .onReadingTimeChange { events.append($0) }

        loading.activateReading()
        clock.now = 5000
        loading.pauseReading()
        XCTAssertTrue(events.isEmpty)

        let errored = UPNovelReader(chapters: chapters, currentChapter: chapters[0],
                                    error: UPNovelReaderError(message: "网络异常"), persist: false, clock: clock.clock)
            .onReadingTimeChange { events.append($0) }
        errored.activateReading()
        errored.pauseReading()
        XCTAssertTrue(events.isEmpty)
    }

    func testBackEmitsEventAndModeSyncEmitsModeChange() {
        let chapters = NovelReaderFixture.chapters
        var backCount = 0
        var modes: [UPNovelReaderMode] = []
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], persist: false, mode: "page")
            .onBack { backCount += 1 }
            .onModeChange { modes.append($0) }

        reader.handleBack()
        XCTAssertEqual(backCount, 1)

        reader.syncMode()
        XCTAssertEqual(modes, [.page])
    }

    func testInitialProgressAndBookmarksSeedLocalState() {
        let chapters = NovelReaderFixture.chapters
        let reader = UPNovelReader(
            chapters: chapters,
            currentChapter: chapters[1],
            persist: false,
            initialProgress: UPNovelReaderProgress(chapterId: "c2", chapterIndex: 1, charOffset: 3, scrollTop: 24),
            initialBookmarks: [UPNovelReaderBookmark(chapterId: "c2", chapterIndex: 1, charOffset: 3)]
        )

        XCTAssertEqual(reader.currentProgress.charOffset, 3)
        XCTAssertEqual(reader.currentProgress.scrollTop, 24, accuracy: 0.0001)
        XCTAssertTrue(reader.isCurrentBookmarked)
        XCTAssertEqual(reader.resolvedBookmarks.map(\.id), ["c2:3"])
    }

    func testControlledBookmarksAndProgressStayExternal() {
        let chapters = NovelReaderFixture.chapters
        let reader = UPNovelReader(
            chapters: chapters,
            currentChapter: chapters[0],
            persist: false,
            progress: UPNovelReaderProgress(chapterId: "c1", chapterIndex: 0, charOffset: 2),
            bookmarks: []
        )

        reader.toggleBookmark()
        XCTAssertTrue(reader.resolvedBookmarks.isEmpty)
        XCTAssertEqual(reader.currentProgress.charOffset, 2)
    }

    func testPersistenceRoundTripThroughInjectedStorage() {
        let storage = UPNovelReaderMemoryStorage()
        let chapters = NovelReaderFixture.chapters
        let clock = NovelReaderClockBox(4242)
        let writer = UPNovelReader(chapters: chapters, currentChapter: chapters[0], bookId: "demo-novel",
                                   persist: true, storage: storage, clock: clock.clock)

        XCTAssertEqual(writer.resolvedStorageKey, "uview-plus:novel-reader:demo-novel")
        writer.toggleBookmark()
        writer.activateReading()
        clock.now = 6242
        writer.pauseReading()
        XCTAssertTrue(writer.flushPersistence())

        let reloaded = UPNovelReader(chapters: chapters, currentChapter: chapters[0], bookId: "demo-novel",
                                    persist: true, storage: storage, clock: clock.clock)
        XCTAssertEqual(reloaded.resolvedBookmarks.map(\.id), ["c1:0"])
        XCTAssertEqual(reloaded.readingTime, 2000, accuracy: 0.0001)
    }

    func testPersistDisabledSkipsStorageWrites() {
        let storage = UPNovelReaderMemoryStorage()
        let chapters = NovelReaderFixture.chapters
        let reader = UPNovelReader(chapters: chapters, currentChapter: chapters[0], bookId: "demo-novel",
                                   persist: false, storage: storage)

        reader.toggleBookmark()

        XCTAssertFalse(reader.flushPersistence())
        XCTAssertNil(storage.readData(forKey: "uview-plus:novel-reader:demo-novel"))
    }
}

final class NovelReaderPersistenceTests: XCTestCase {
    func testStorageKeyPrefersExplicitKeyThenBookId() {
        XCTAssertEqual(UPNovelReaderPersistedState.storageKey(storageKey: "", bookId: "book"), "uview-plus:novel-reader:book")
        XCTAssertEqual(UPNovelReaderPersistedState.storageKey(storageKey: "custom", bookId: "book"), "custom")
        XCTAssertEqual(UPNovelReaderPersistedState.storageKey(storageKey: "", bookId: ""), "")
    }

    func testWriteThenReadRoundTripsState() {
        let storage = UPNovelReaderMemoryStorage()
        let state = UPNovelReaderPersistedState(
            progress: UPNovelReaderProgress(chapterId: "c1", chapterIndex: 1, pageIndex: 2, pageCount: 5,
                                            charOffset: 30, chapterProgress: 0.6, totalProgress: 0.3, scrollTop: 80, updatedAt: 111),
            settings: UPNovelReaderSettingsPatch(theme: "night", fontSize: 20),
            bookmarks: [UPNovelReaderBookmark(chapterId: "c1", chapterIndex: 1, charOffset: 30, excerpt: "摘要")],
            readingTime: 4200,
            updatedAt: 0
        )

        XCTAssertTrue(UPNovelReaderPersistence.write(key: "novel", state: state, storage: storage, updatedAt: 999))

        let restored = UPNovelReaderPersistence.read(key: "novel", storage: storage)
        XCTAssertEqual(restored?.updatedAt, 999)
        XCTAssertEqual(restored?.readingTime, 4200)
        XCTAssertEqual(restored?.progress?.charOffset, 30)
        XCTAssertEqual(restored?.settings?.theme, "night")
        XCTAssertEqual(restored?.settings?.fontSize, 20)
        XCTAssertEqual(restored?.bookmarks.map(\.id), ["c1:30"])
    }

    func testWriteIsSkippedForEmptyKey() {
        let storage = UPNovelReaderMemoryStorage()
        XCTAssertFalse(UPNovelReaderPersistence.write(key: "", state: .empty, storage: storage, updatedAt: 1))
        XCTAssertNil(UPNovelReaderPersistence.read(key: "", storage: storage))
    }

    func testReadRejectsUnknownVersionAndClearsKey() {
        let storage = UPNovelReaderMemoryStorage()
        storage.writeRaw("{\"version\":2,\"readingTime\":0,\"updatedAt\":1}", forKey: "novel")

        XCTAssertNil(UPNovelReaderPersistence.read(key: "novel", storage: storage))
        XCTAssertNil(storage.readData(forKey: "novel"))
    }

    func testReadRejectsNegativeReadingTime() {
        let storage = UPNovelReaderMemoryStorage()
        storage.writeRaw("{\"version\":1,\"readingTime\":-1,\"updatedAt\":1}", forKey: "novel")

        XCTAssertNil(UPNovelReaderPersistence.read(key: "novel", storage: storage))
        XCTAssertNil(storage.readData(forKey: "novel"))
    }

    func testReadDropsInvalidProgressButKeepsRestOfState() {
        let storage = UPNovelReaderMemoryStorage()
        storage.writeRaw("""
        {"version":1,"readingTime":10,"updatedAt":5,
         "progress":{"chapterId":"c1","charOffset":-3},
         "settings":{"theme":"paper"},
         "bookmarks":[{"id":"c1:0","chapterId":"c1","chapterIndex":0,"charOffset":0},
                      {"id":"x","charOffset":0}]}
        """, forKey: "novel")

        let restored = UPNovelReaderPersistence.read(key: "novel", storage: storage)
        XCTAssertNotNil(restored)
        XCTAssertNil(restored?.progress)
        XCTAssertEqual(restored?.settings?.theme, "paper")
        XCTAssertEqual(restored?.bookmarks.map(\.id), ["c1:0"])
        XCTAssertEqual(restored?.readingTime, 10)
    }

    func testReadDropsProgressWithOutOfRangeRatios() {
        let storage = UPNovelReaderMemoryStorage()
        storage.writeRaw("""
        {"version":1,"readingTime":0,"updatedAt":1,
         "progress":{"chapterId":"c1","chapterProgress":1.5}}
        """, forKey: "novel")

        let restored = UPNovelReaderPersistence.read(key: "novel", storage: storage)
        XCTAssertNotNil(restored)
        XCTAssertNil(restored?.progress)
    }

    /// JSON `null` 反序列化成 `NSNull`，不是数字：显式出现的字段读不出数值时按无效
    /// 处理（丢 progress），而缺省字段仍走各自默认值。
    func testReadTreatsJSONNullNumbersAsInvalidRatherThanZero() {
        let storage = UPNovelReaderMemoryStorage()
        storage.writeRaw("""
        {"version":1,"readingTime":null,"updatedAt":null,
         "progress":{"chapterId":"c1","charOffset":null}}
        """, forKey: "novel")

        let restored = UPNovelReaderPersistence.read(key: "novel", storage: storage)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.readingTime, 0)
        XCTAssertEqual(restored?.updatedAt, 0)
        XCTAssertNil(restored?.progress)
    }

    /// `version` 是 `null` 时读不出版本号，等同版本不匹配：清 key 并返回 nil。
    func testReadRejectsNullVersionAndClearsKey() {
        let storage = UPNovelReaderMemoryStorage()
        storage.writeRaw("{\"version\":null,\"readingTime\":0,\"updatedAt\":1}", forKey: "novel")

        XCTAssertNil(UPNovelReaderPersistence.read(key: "novel", storage: storage))
        XCTAssertNil(storage.readData(forKey: "novel"))
    }
}
