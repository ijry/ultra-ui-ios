import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/pdfReader/pdfReader`。
@MainActor
struct PdfReaderDemoView: View {
    private static let pdfFileUrl = "https://uview-plus.jiangruyi.com/big/plus.pdf"

    @State private var show = false
    @State private var localPDF = Data()
    @State private var remotePDF = Data()
    @State private var loadState = "尚未加载"
    @State private var eventLog = "尚未翻页"
    @State private var reader = UPPDFReader()
    @State private var tick = 0

    var body: some View {
        ZStack {
            DemoPage {
                DemoSection("默认") {
                    UPButton(text: "打开PDF预览") { show = true }

                    tip("本地生成的 3 页示例 PDF，pageCount = \(reader.pageCount)。")
                    tip("最近事件：\(eventLog)")
                }

                DemoSection("加载上游 PDF") {
                    UPButton(type: "primary", size: "mini", text: "下载 plus.pdf") {
                        loadRemotePDF()
                    }

                    tip("状态：\(loadState)")
                    tip("上游 src 是 \(Self.pdfFileUrl)，baseUrl 传空串。原生 UPPDFReader 渲染走 PDFKit + documentData，所以下载得由页面自己做。")

                    if !remotePDF.isEmpty {
                        UPPDFReader(documentData: remotePDF, src: Self.pdfFileUrl, baseUrl: "")
                            .frame(height: 80)
                    }
                }

                DemoSection("pdf.js viewer 地址") {
                    tip("baseUrl 为空串时回落到内置域名，与上游 mounted 的 baseUrlInner 一致：")
                    tip(UPPDFReader(src: Self.pdfFileUrl, baseUrl: "").viewerURL)

                    tip("自定义 baseUrl 时直接替换域名：")
                    tip(UPPDFReader(src: Self.pdfFileUrl, baseUrl: "https://cdn.example.com").viewerURL)
                }

                DemoSection("当前原生范围") {
                    Text("原生 UPPDFReader 接收 documentData: Data 与 currentPage，用 PDFKit 解析出 pageCount，提供 goToPage(_) 与 onPageChange((Int) -> Void)。上游三个 prop src / height / baseUrl 都已声明，viewerURL 按上游公式拼出 pdf.js 地址；但因为上游是 web-view 套 pdf.js、这里是原生渲染，src 与 viewerURL 只作元数据，实际内容仍来自 documentData。body 只画一个 doc.richtext 图标加「当前页 / 总页数」的文本，并不真正渲染 PDF 内容，也没有翻页手势与缩放。本页用 UIGraphicsPDFRenderer 先生成一份 3 页的示例 PDF，另给一个按钮用 URLSession 下载上游 plus.pdf 再交给组件。组件用私有 class 存当前页，外部读 currentPage 不会自动刷新，所以用 tick + .id(tick) 让 SwiftUI 重新求值。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            UPPopup(show: $show, closeable: true) {
                VStack(spacing: 14) {
                    reader
                        .id(tick)

                    HStack(spacing: 12) {
                        UPButton(size: "mini", disabled: reader.currentPage <= 0, text: "上一页") {
                            reader.goToPage(reader.currentPage - 1)
                            tick += 1
                        }

                        UPButton(
                            size: "mini",
                            disabled: reader.currentPage >= reader.pageCount - 1,
                            text: "下一页"
                        ) {
                            reader.goToPage(reader.currentPage + 1)
                            tick += 1
                        }
                    }

                    UPButton(type: "primary", size: "mini", text: "关闭") { show = false }
                }
                .padding(24)
            }
        }
        .onAppear(perform: prepare)
    }

    private func prepare() {
        if localPDF.isEmpty {
            localPDF = Self.makeSamplePDF(pages: 3)
        }

        reader = UPPDFReader(documentData: localPDF, src: Self.pdfFileUrl).onPageChange { page in
            eventLog = "page-change：第 \(page + 1) 页"
        }
    }

    private func loadRemotePDF() {
        loadState = "下载中…"
        Task { @MainActor in
            guard let url = URL(string: Self.pdfFileUrl) else {
                loadState = "地址无效"
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                remotePDF = data
                let pages = UPPDFReader(documentData: data).pageCount
                loadState = "已加载 \(data.count / 1024) KB · \(pages) 页"
            } catch {
                loadState = "下载失败：\(error.localizedDescription)"
            }
        }
    }

    private static func makeSamplePDF(pages: Int) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: 320, height: 420)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        return renderer.pdfData { context in
            for index in 1...max(1, pages) {
                context.beginPage()
                "uview-plus PDF · 第 \(index) 页".draw(
                    at: CGPoint(x: 24, y: 40),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                        .foregroundColor: UIColor.label
                    ]
                )
            }
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
