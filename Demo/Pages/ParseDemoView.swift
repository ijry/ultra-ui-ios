import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsB/parse/parse`。
@MainActor
struct ParseDemoView: View {
    /// 与上游同目录 `content.js` 对齐的测试 HTML（保留标题、三个表格、四种列表、
    /// ruby / 上下标 / 划线、三类链接与图片段落）。
    private static let html = """
    <title>富文本示例</title>
    <div>
      <section style="text-align: center; margin: 0px auto;">
        <section style="border-radius: 4px; border: 1px solid #757576; display: inline-block; padding: 5px 20px;">
          <span style="font-size: 18px; color: #595959;">表格</span>
        </section>
      </section>
      <section style="margin-top: 1.5em;">
        <table width="100%" cellspacing="0" cellpadding="5">
          <thead><tr><th>标题 1</th><th>标题 2</th></tr></thead>
          <tbody>
            <tr><td align="center">内容 1</td><td align="center">内容 2</td></tr>
            <tr style="background-color: #f6f8fa;"><td align="center">内容 3</td><td align="center"><a>链接</a></td></tr>
            <tr><td align="center">内容 5</td><td align="center">内容 6</td></tr>
          </tbody>
        </table>
        <div style="font-size: 12px; color: gray; text-align: center; margin-top: 5px;">普通表格</div>
      </section>
      <section style="margin-top: 1.5em;">
        <table width="500px" cellspacing="0" cellpadding="5">
          <thead><tr><th>标题 1</th><th>标题 2</th><th>标题 3</th><th>标题 4</th><th>标题 5</th></tr></thead>
          <tbody>
            <tr><td align="center">内容 1</td><td align="center">内容 2</td><td align="center">内容 3</td><td align="center">内容 4</td><td align="center">内容 5</td></tr>
          </tbody>
        </table>
        <div style="font-size: 12px; color: gray; text-align: center; margin-top: 5px;">长表格，可以单独横向滚动</div>
      </section>
      <section style="margin-top: 1.5em;">
        <table width="100%" cellspacing="0" cellpadding="5">
          <thead><tr><th align="center">标题 1</th><th align="center">标题 2</th><th align="center">标题 3</th></tr></thead>
          <tbody>
            <tr><td align="center" colspan="2">内容 1</td><td align="center">内容 2</td></tr>
            <tr><td align="center">内容 3</td><td align="center">内容 4</td><td align="center">内容 5</td></tr>
          </tbody>
        </table>
        <div style="font-size: 12px; color: gray; text-align: center; margin-top: 5px;">合并单元格（原生只支持 colspan）</div>
      </section>
      <section id="list" style="text-align: center; margin: 0px auto; margin-top: 2em">
        <section style="border-radius: 4px; border: 1px solid #757576; display: inline-block; padding: 5px 20px;">
          <span style="font-size: 18px; color: #595959;">列表</span>
        </section>
      </section>
      <section style="margin-top: 1.5em;">
        <ol style="margin-bottom: 1.5em;">
          <li>这是第一条列表项</li>
          <li>这是第二条列表项</li>
          <li>这是第三条 <a>链接</a></li>
        </ol>
        <ol type="A" style="margin-bottom: 1.5em;">
          <li>这是第一条列表项</li>
          <li>这是第二条列表项</li>
        </ol>
        <ol type="I" style="margin-bottom: 1.5em;">
          <li>这是第一条列表项</li>
          <li>这是第二条列表项</li>
        </ol>
        <ul>
          <li>第一级无序列表</li>
          <li>第一级无序列表
            <ul>
              <li>第二级无序列表</li>
              <li>第二级无序列表
                <ul><li>第三级无序列表</li></ul>
              </li>
            </ul>
          </li>
        </ul>
      </section>
      <section style="text-align: center; margin: 0px auto; margin-top: 2em">
        <section style="border-radius: 4px; border: 1px solid #757576; display: inline-block; padding: 5px 20px;">
          <span style="font-size: 18px; color: #595959;">文本</span>
        </section>
      </section>
      <section style="margin-top: 1.5em;">
        <p style="margin-bottom: 1em;">
          <ruby>拼<rp>(</rp><rt>pin</rt><rp>)</rp>音<rp>(</rp><rt>yin</rt><rp>)</rp></ruby>
          &nbsp;&nbsp;<i>斜体</i>&nbsp;&nbsp;<b>粗体</b>&nbsp;&nbsp;上标<sup>1</sup>&nbsp;&nbsp;下标<sub>2</sub>
        </p>
        <p style="margin-bottom: 1em;">
          <s>中划线</s>&nbsp;&nbsp;<u>下划线</u>&nbsp;&nbsp;<code>等宽</code>
        </p>
        <p><big>大一号</big>&nbsp;&nbsp;<span>正常</span>&nbsp;&nbsp;<small>小一号</small></p>
        <h2 style="margin-top: 0.5em;">大标题</h2>
        <h3 style="margin-top: 0.5em;">中标题</h3>
        <h4 style="margin-top: 0.5em;">小标题</h4>
      </section>
      <section style="text-align: center; margin: 0px auto; margin-top: 2em">
        <section style="border-radius: 4px; border: 1px solid #757576; display: inline-block; padding: 5px 20px;">
          <span style="font-size: 18px; color: #595959;">链接</span>
        </section>
      </section>
      <section style="margin-top: 1.5em; text-align: center;">
        <a href="#list">跳转到列表</a>
        <div style="font-size: 12px; color: gray; margin-top: 5px;">锚点链接，将滚动到对应位置</div>
      </section>
      <section style="margin-top: 1.5em; text-align: center;">
        <a href="https://github.com/jin-yufeng/mp-html">外部链接</a>
        <div style="font-size: 12px; color: gray; margin-top: 5px;">外部链接，将复制链接</div>
      </section>
      <section style="margin-top: 1.5em; text-align: center;">
        <span>&nbsp;转义字符：&amp; &lt;view&gt;</span>
      </section>
    </div>
    """

    /// 上游同页的 tag-style，用来给表格补外框和给列表项加间距。
    private static let tagStyle = [
        "table": "box-sizing: border-box; border-top: 1px solid #dfe2e5; border-left: 1px solid #dfe2e5;",
        "th": "border-right: 1px solid #dfe2e5; border-bottom: 1px solid #dfe2e5;",
        "td": "border-right: 1px solid #dfe2e5; border-bottom: 1px solid #dfe2e5;",
        "li": "margin: 5px 0;"
    ]

    @State private var content = ""
    @State private var loadLog = "等待 200ms 后赋值"
    @State private var readyLog = "尚未触发"
    @State private var tapLog = "尚未点击"
    @State private var errorLog = "尚未触发"
    @State private var errorParse = UPParse(content: "<p>解析失败的内容</p>")
    @State private var tick = 0

    var body: some View {
        DemoPage {
            DemoSection("富文本示例") {
                ScrollViewReader { proxy in
                    UPParse(containerStyle: UPStyle(["padding": "10", "font-size": "16", "color": "#606266"]),
                            content: content,
                            domain: "https://6874-html-foe72-1259071903.tcb.qcloud.la/demo",
                            lazyLoad: true,
                            scrollTable: true,
                            selectable: true,
                            setTitle: false,
                            tagStyle: Self.tagStyle,
                            useAnchor: true)
                        .onLoad { loadLog = "load：dom 结构已就绪，共 \(Self.html.count) 个字符" }
                        .onReady { size in readyLog = "ready：高度稳定在 \(Int(size.height))pt" }
                        .onLinkTap { link in tapLog = "linktap：\(link.innerText.isEmpty ? "(无文本)" : link.innerText) → \(link.href.isEmpty ? "(无 href)" : link.href)" }
                        .onImageTap { event in tapLog = "imgtap：第 \(event.index.map(String.init) ?? "-") 张，\(event.src)" }
                        .onAnchor { anchor in
                            withAnimation { proxy.scrollTo(anchor.id, anchor: .top) }
                            tapLog = "锚点：滚动到 #\(anchor.id)，偏移 \(Int(anchor.offset))pt"
                        }
                        .placeholder { tip("content 为空时展示上游的默认插槽") }
                }

                tip(loadLog)
                tip(readyLog)
                tip("最近点击：\(tapLog)")
            }

            DemoSection("禁止选中文本") {
                UPParse(content: "<p>selectable 为 false（上游默认值）时长按不会弹出复制菜单。</p>")
            }

            DemoSection("解析失败回调") {
                errorParse
                    .id(tick)

                UPButton(type: "warning", size: "small", text: "模拟 error 事件") {
                    errorParse.reportError("html 解析失败")
                    tick += 1
                }

                tip("最近事件：\(errorLog)")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPParse 已覆盖上游 15 个 prop：containerStyle / content / copyLink / domain / errorImg / lazyLoad / loadingImg / pauseVideo / previewImg / scrollTable / selectable / setTitle / showImgMenu / tagStyle / useAnchor，事件为 onLoad / onReady / onImageTap / onLinkTap / onPlay / onMediaError 外加保留下来的 onError((String) -> Void)。解析层是 parser.js 的完整移植（词法分析、tagStyle 合并、align / dir / font 属性转样式、cellpadding / cellspacing 换算、tr 颜色下沉、ruby 重排、scrollTable 外套滚动层）。三处平台差异：没有 previewImage 图层，previewImg 只决定 base64 图片是否计入 imageList，点击一律抛 imgtap，预览界面由宿主自己实现；useAnchor 通过 onAnchor 把校验过的锚点交给宿主的 ScrollViewReader（本页即如此接线），错误仍按上游抛 Anchor is disabled / Label not found；showImgMenu 落成长按菜单里的「复制图片链接」，上游的保存到相册需要额外权限。表格用 Grid 对齐列宽，colspan 走 gridCellColumns，rowspan 没有对应能力（上游在小程序端也要改用 CSS grid 才支持）；svg 不渲染。上游 onMounted 里延迟 200ms 才赋值 content 用来模拟网络请求，这里用 Task.sleep 保留同样的时序。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: bindEvents)
        .task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            content = Self.html
        }
    }

    private func bindEvents() {
        errorParse = errorParse.onError { message in errorLog = message }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
