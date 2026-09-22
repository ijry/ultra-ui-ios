import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/novelReader/novelReader`。
@MainActor
struct NovelReaderDemoView: View {
    private static let chapters: [UPNovelReaderChapter] = [
        UPNovelReaderChapter(
            id: "chapter-1",
            index: 0,
            title: "第一章 远山来信",
            content: [
                "清晨的雾还没有散去。山城的邮差已经沿着石阶向上走 山城的邮差已经沿着石阶向上走",
                "他把一封没有署名的信放在门檐下，信纸上只有一句话：请在月亮升起以前，去旧车站等我。",
                "林砚读完信，抬头看见屋后的远山像一排沉默的屏风。这个季节少有人来，旧车站也早已停运多年。",
                "他收好信纸，带上手电和一件薄外套。院门外的风从峡谷里吹来，带着潮湿的草木气息。",
                "下山的路比记忆中更长，沿途的店铺都还关着门，只有河面上浮着一层微光，像有人提前点亮了夜色。"
            ].joined(separator: "\n")
        ),
        UPNovelReaderChapter(
            id: "chapter-2",
            index: 1,
            title: "第二章 旧车站",
            content: [
                "旧车站藏在杉树林后面，站牌上的字已经被雨水冲淡。林砚推开铁门时，门轴发出一声长久的叹息。",
                "候车室里没有灯，墙上的时钟停在十七点三十二分。长椅上积着灰尘，却留有一小块刚刚被擦拭过的地方。",
                "他按照信上的时间等候，远处的铁轨始终没有传来声响。直到月亮越过屋顶，一束车灯突然穿过树林。",
                "那不是普通的列车，车厢没有编号，窗户里也看不见乘客。车门打开后，里面传出熟悉的铃声。",
                "林砚想起许多年前失踪的父亲，也想起父亲离开那天说过的话：有些路只能走一遍。"
            ].joined(separator: "\n")
        ),
        UPNovelReaderChapter(
            id: "chapter-3",
            index: 2,
            title: "第三章 河谷回声",
            content: [
                "列车驶入河谷后，窗外的景色开始倒退。山壁上的树木像一排排翻动的书页，重复着从未改变的季节。",
                "林砚在车厢尽头找到一张木桌，桌上摆着一本旧笔记。第一页写着他的名字，日期却是二十年前。",
                "笔记记录了父亲寻找星门的过程，也记录了每次经过河谷时听见的回声。那些回声总会回答尚未问出口的问题。",
                "当列车停在无名隧道前，车厢里的铃声再次响起。林砚合上笔记，决定沿着铁轨走进黑暗。",
                "隧道深处传来水滴声，他打开手电，发现墙上刻着一串方向相反的箭头，尽头写着：不要相信回声。"
            ].joined(separator: "\n")
        ),
        UPNovelReaderChapter(
            id: "chapter-4",
            index: 3,
            title: "第四章 无字之页",
            content: [
                "隧道另一端是一间没有门窗的石室。石室中央放着一张桌子，桌上摊开的书册没有任何文字。",
                "林砚伸手触碰书页，空白上浮现出一行新的字迹。那是他刚才在车站没有说出口的疑问。",
                "每当他读完一页，下一页便会出现一段记忆。记忆中的父亲站在月台上，身旁还有一个年幼的林砚。",
                "原来那封信不是从远方寄来，而是从他一直不愿回想的那一天寄来。时间在石室里没有方向。",
                "他终于明白，所谓星门并不是通往别处的门，而是一条允许人重新面对选择的路。"
            ].joined(separator: "\n")
        ),
        UPNovelReaderChapter(id: "chapter-5", index: 4, title: "第五章 空白章节", content: ""),
        UPNovelReaderChapter(
            id: "chapter-6",
            index: 5,
            title: "第六章 尚未解锁",
            content: "这一章将在完成前置阅读后解锁。",
            isLocked: true
        )
    ]

    @State private var currentChapter = NovelReaderDemoView.chapters[0]
    @State private var loading = false
    @State private var error: UPNovelReaderError?
    @State private var mode = "scroll"
    @State private var progress = UPNovelReaderProgress(chapterId: "chapter-1")
    @State private var settings = UPNovelReaderSettingsPatch(
        theme: "day", fontSize: 18, lineHeight: 1.8, paragraphSpacing: 16,
        contentWidth: .text("92%"), fontFamily: "system", fontWeight: 400, animation: true
    )
    @State private var requestLog = "尚未切章"
    @State private var prefetchLog = "尚未预取"
    @State private var toolbarLog = "尚未开合工具栏"
    @State private var requestToken = 0
}

extension NovelReaderDemoView {
    var body: some View {
        DemoPage {
            DemoSection("默认") {
                reader
                    .frame(height: 460)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                tip("上游 book-id=\"demo-novel\"，6 章里 4 章有正文、1 章空白、1 章锁定。点正文中间开合工具栏。")
                tip("当前章节：\(currentChapter.title)｜章内进度 \(percentText)｜模式 \(mode == "page" ? "翻页" : "滚动")")
                tip("最近请求：\(requestLog)")
                tip("最近预取：\(prefetchLog)")
                tip("工具栏：\(toolbarLog)")
            }

            DemoSection("toolbar-extra 插槽") {
                UPButton(
                    type: "primary",
                    size: "mini",
                    text: mode == "page" ? "切回滚动模式" : "切到翻页模式"
                ) {
                    mode = mode == "scroll" ? "page" : "scroll"
                }

                tip("上游把 order 图标放进 toolbar-extra 插槽来切 mode，原生组件没有插槽，改由本页按钮驱动 mode。")
            }

            DemoSection("加载与失败态") {
                UPButton(size: "mini", text: "模拟加载失败") {
                    loading = false
                    requestToken += 1
                    error = UPNovelReaderError(message: "章节加载失败，请检查网络后重试。")
                }

                UPButton(size: "mini", text: "清除错误") { error = nil }

                tip("失败态下正文区显示 error.message 与「重试」，点重试派发 retry 事件，本页按上游语义重新请求当前章。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPNovelReader 复刻了上游 reader-core.js 的全部数据逻辑：正文归一化、翻页分页与锚点、滚动进度换算、章节请求去重与预取、书签增删、阅读时长累计、UserDefaults 持久化。视图层用 SwiftUI 重画了正文区、三段点击热区、顶/底工具栏，以及目录（左侧 UPPopup）与设置（底部 UPPopup）两个弹层。上游的 toolbar-extra / catalog-extra 等插槽、nvue 的 CSS 变量主题、翻页转场动画都没有对等实现：主题走内置 THEME_TOKENS 色板，翻页只做 easeInOut 淡入。字号会被上游同样的 clamp 收敛到 12…48，行高 1…3，段距 0…80。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var reader: UPNovelReader {
        UPNovelReader(
            chapters: Self.chapters,
            currentChapter: currentChapter,
            loading: loading,
            error: error,
            bookId: "demo-novel",
            progress: progress,
            settings: settings,
            mode: mode
        )
        .onChapterRequest { request in
            performChapterRequest(targetIndex: request.targetIndex, direction: request.direction)
        }
        .onChapterPrefetch { payload in
            prefetchLog = "chapter-prefetch：\(payload.targetId) · \(payload.direction)"
        }
        .onProgressChange { progress = $0 }
        .onSettingsChange { settings = Self.patch(from: $0.settings) }
        .onToolbarChange { change in
            toolbarLog = "toolbar-change：\(change.visible ? "展开" : "收起")（\(change.reason)）"
        }
        .onRetry { _ in
            error = nil
            performChapterRequest(targetIndex: Int(currentChapter.index), direction: "retry")
        }
    }

    private var percentText: String {
        "\(Int((progress.chapterProgress * 100).rounded()))%"
    }

    private func performChapterRequest(targetIndex: Int, direction: String) {
        guard !loading else { return }
        guard let target = Self.chapters.first(where: { Int($0.index) == targetIndex }), !target.isLocked else {
            requestLog = "chapter-request：\(direction) 被拒绝（越界或已锁定）"
            return
        }

        loading = true
        error = nil
        requestLog = "chapter-request：\(direction) → \(target.title)"
        requestToken += 1
        let token = requestToken

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 240_000_000)
            guard token == requestToken else { return }
            currentChapter = target
            progress = UPNovelReaderProgress(
                chapterId: target.id,
                chapterIndex: Int(target.index),
                totalProgress: progress.totalProgress,
                updatedAt: Date().timeIntervalSince1970 * 1000
            )
            loading = false
        }
    }

    private static func patch(from settings: UPNovelReaderSettings) -> UPNovelReaderSettingsPatch {
        UPNovelReaderSettingsPatch(
            theme: settings.theme,
            fontSize: settings.fontSize,
            lineHeight: settings.lineHeight,
            paragraphSpacing: settings.paragraphSpacing,
            contentWidth: settings.contentWidth,
            fontFamily: settings.fontFamily,
            fontWeight: settings.fontWeight,
            animation: settings.animation
        )
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
