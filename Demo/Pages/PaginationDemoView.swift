import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/pagination/pagination`。
@MainActor
struct PaginationDemoView: View {
    private static let pageSizes = [10, 20, 30]

    @State private var currentPage = 1
    @State private var pageSize = 10
    @State private var eventLog = "尚未翻页"

    private let total = 100

    var body: some View {
        DemoPage {
            DemoSection("基础") {
                UPPagination(
                    currentPage: $currentPage, pageSize: $pageSize, total: total,
                    pageSizes: Self.pageSizes, layout: "prev, next"
                )
                .onCurrentChange { page in eventLog = "当前页：\(page)" }
                .onSizeChange { size in eventLog = "每页条数：\(size)" }

                Text("共 \(total) 条，每页 \(pageSize) 条，当前第 \(currentPage) / \(UPPagination.totalPages(total: total, pageSize: pageSize)) 页")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("最近事件：\(eventLog)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("上一页下一页文案") {
                UPPagination(
                    currentPage: $currentPage, pageSize: $pageSize, total: total,
                    prevText: "上一页", nextText: "下一页",
                    pageSizes: Self.pageSizes, layout: "prev, next"
                )
                .onCurrentChange { page in eventLog = "当前页：\(page)" }
            }

            DemoSection("显示分页切换") {
                UPPagination(
                    currentPage: $currentPage, pageSize: $pageSize, total: total,
                    pageSizes: Self.pageSizes, layout: "prev, pager, next"
                )
                .onCurrentChange { page in eventLog = "当前页：\(page)" }
            }

            DemoSection("切换每页条数") {
                UPPagination(
                    currentPage: $currentPage, pageSize: $pageSize, total: total,
                    pageSizes: Self.pageSizes, layout: "prev, pager, next, sizes"
                )
                .onSizeChange { size in eventLog = "每页条数：\(size)" }
            }

            DemoSection("单页时隐藏") {
                UPPagination(
                    currentPage: 1, pageSize: 10, total: 8,
                    layout: "prev, pager, next", hideOnSinglePage: true
                )

                Text("total=8、pageSize=10 只有一页，hideOnSinglePage 生效后整个分页器不渲染。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("显示总条数") {
                UPPagination(
                    currentPage: $currentPage, pageSize: $pageSize, total: total,
                    pageSizes: Self.pageSizes, layout: "total, prev, pager, next"
                )

                Text("layout 带 total 且 total > 0 时渲染「共 N 条」。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("页码折叠规则") {
                ForEach([1, 2, 5, 9, 10], id: \.self) { page in
                    Text("current=\(page)：\(Self.describe(UPPagination.tokens(current: page, total: 10)))")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Text("总页数不超过 4 时全列，否则按当前页靠头 / 靠尾 / 居中三分支插省略号。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            DemoSection("当前原生范围") {
                Text("原生 UPPagination 覆盖上游全部 10 个 prop 与 update:currentPage / update:pageSize / current-change / size-change 四个事件，layout 的 total / prev / pager / next / sizes 五个关键字都已渲染。本轮补齐样式：按钮 4px 内边距 + 1rpx 边框 + 4px 圆角、底色取 buttonBgColor，页码激活项换 #409eff 底色白字，prevText / nextText 为空时渲染 arrow-left / arrow-right 图标，每页条数选择器显示 pageSizeLabel（模板 `${size}条/页`，找不到时直接显示数字）。displayedPages 的三分支折叠与 pageSizeIndex 的回落规则都可单测。上游 layout 里还留了一个 jumper 关键字，但那段模板整体被注释掉了，故不建模。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private nonisolated static func describe(_ tokens: [UPPaginationToken]) -> String {
        tokens.map { token in
            switch token {
            case let .page(page): return String(page)
            case .ellipsis: return "..."
            }
        }
        .joined(separator: " ")
    }
}
