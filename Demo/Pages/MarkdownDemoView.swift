import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/markdown/markdown`。
@MainActor
struct MarkdownDemoView: View {
    private static let basicContent = """
    # 标题1
    这是段落文本，包含**粗体**和*斜体*文本。

    ## 标题2
    这是一个链接：[uview-plus](https://ijry.github.io/uview-plus)

    ### 列表示例
    - 列表项1
    - 列表项2
    - 列表项3

    > 这是一个引用块

    ---

    段落中的行内代码： `console.log('Hello World')`
    """

    private static let codeContent = """
    # 代码示例

    以下是一个JavaScript函数：

    ```javascript
    function hello(name) {
        console.log('Hello, ' + name + '!');
    }

    hello('World');
    ```

    以下是一个Python示例：

    ```python
    def hello(name):
        print(f"Hello, {name}!")

    hello("World")
    ```
    """

    private static let fullAIContent = """
    # AI助手回答

    你好！我是AI助手，正在为你逐步生成回答内容...

    ## 问题分析

    让我来分析你提出的问题：

    1. 需要实现流式内容显示
    2. 模拟AI逐步输出文字的效果
    3. 使用定时器控制内容显示速度

    ## 解决方案

    我们可以使用以下方法实现：

    ## 总结

    通过定时器控制内容逐字显示，可以营造出AI正在思考和逐步输出的效果。

    ---

    *内容生成完毕*
    """

    @State private var streamingContent = ""
    @State private var isStreaming = false
    @State private var streamTask: Task<Void, Never>?
    @State private var eventLog = "尚未触发"

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPMarkdown(content: Self.basicContent)
                    .onLoad { eventLog = "load：dom 结构已就绪" }
                    .onLinkTap { link in eventLog = "linktap：\(link.innerText) → \(link.href)" }

                tip("最近事件：\(eventLog)")
            }

            DemoSection("带代码块行号") {
                UPMarkdown(content: Self.codeContent, showLineNumber: true)

                tip("showLineNumber 为真时上游把行号排成独立一列，原生前置到每行。")
            }

            DemoSection("深色主题") {
                UPMarkdown(content: Self.basicContent, theme: "dark")
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            DemoSection("AI流式内容显示") {
                UPMarkdown(content: streamingContent)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    UPButton(type: "primary", size: "mini", text: isStreaming ? "停止" : "开始") {
                        toggleStreaming()
                    }

                    UPButton(size: "mini", text: "重置") { resetStreaming() }
                }

                tip("已输出 \(streamingContent.count) / \(Self.fullAIContent.count) 个字符，间隔 50ms。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPMarkdown 已覆盖上游 6 个 prop：content / previewImg / copyLink / domain / showLineNumber / theme，事件为 onLoad / onReady / onImageTap / onLinkTap / onPlay / onError，与上游一样全部由 UPParse 透传。链路也和上游一致：UPMarkdownParser 顶替 marked 把 Markdown 转成 HTML（覆盖标题、段落、粗斜体、删除线、行内代码、链接、图片、有序无序列表与嵌套、引用块、分隔线、围栏代码块与 GFM 表格），再交给 UPParse 渲染，所以列表符号、引用竖线、代码块底色、表格线框都能出来。未覆盖 marked 的脚注、任务列表、定义列表、HTML 直通与引用式链接。theme 落成容器配色（深色 #1e1e1e 底 + #ccc 文字 + #4da6ff 链接）。仓库既有的 attributedContent 仍保留，供只要纯文本的调用点使用。流式一节保留了上游 50ms 逐字追加的行为，只是把 setInterval 换成可取消的 Task。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .onDisappear {
            streamTask?.cancel()
            streamTask = nil
            isStreaming = false
        }
    }

    private func toggleStreaming() {
        if isStreaming {
            stopStreaming()
        } else {
            startStreaming()
        }
    }

    private func startStreaming() {
        guard !isStreaming else { return }
        if streamingContent.count >= Self.fullAIContent.count { streamingContent = "" }
        isStreaming = true
        streamTask = Task { @MainActor in
            let characters = Array(Self.fullAIContent)
            while streamingContent.count < characters.count {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 50_000_000)
                if Task.isCancelled { return }
                streamingContent.append(characters[streamingContent.count])
            }
            stopStreaming()
        }
    }

    private func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    private func resetStreaming() {
        stopStreaming()
        streamingContent = ""
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
