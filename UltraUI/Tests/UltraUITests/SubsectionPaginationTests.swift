import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class SubsectionPaginationTests: XCTestCase {
    func testSubsectionDefaultsAndSelection() {
        let box = IntBox(0)
        var emitted: [Int] = []
        let subsection = UPSubsection(list: ["A", "B"], current: box.binding)
            .onChange { emitted.append($0) }

        subsection.select(1)

        XCTAssertEqual(box.value, 1)
        XCTAssertEqual(emitted, [1])
        XCTAssertEqual(subsection.mode, "button")
        XCTAssertEqual(subsection.fontSize, 12)
    }

    func testDisabledSubsectionDoesNotChange() {
        let box = IntBox(0)
        var emitted = 0
        UPSubsection(list: ["A", "B"], current: box.binding, disabled: true)
            .onChange { _ in emitted += 1 }
            .select(1)

        XCTAssertEqual(box.value, 0)
        XCTAssertEqual(emitted, 0)
    }

    func testSubsectionSelectedIndexTracksBindingAndEmitsPayload() {
        let box = IntBox(0)
        let items = [UPSubsectionItem(id: "first", name: "A"), UPSubsectionItem(id: "second", name: "B")]
        var change: UPSubsectionChange?
        let subsection = UPSubsection(list: items, current: box.binding)
            .onChangePayload { change = $0 }

        box.value = 1
        XCTAssertEqual(subsection.selectedIndex, 1)

        box.value = 0
        subsection.select(1)
        XCTAssertEqual(change, UPSubsectionChange(index: 1, item: items[1]))
    }

    func testSubsectionAcceptsUncontrolledCurrentProp() {
        let subsection = UPSubsection(list: ["A", "B"], current: 1)

        XCTAssertEqual(subsection.current, 1)
    }

    func testPaginationTokensAreOrderedAndUniqueAtEdges() {
        let pagination = UPPagination(currentPage: .constant(2), pageSize: .constant(10), total: 100)

        XCTAssertEqual(pagination.totalPages, 10)
        XCTAssertEqual(pagination.tokens, [.page(1), .page(2), .page(3), .page(4), .ellipsis, .page(10)])
        XCTAssertEqual(Set(pagination.tokens).count, pagination.tokens.count)
    }

    func testPaginationClampsAndEmitsChanges() {
        let page = IntBox(1)
        let size = IntBox(10)
        var events: [String] = []
        let pagination = UPPagination(currentPage: page.binding, pageSize: size.binding, total: 35)
            .onCurrentChange { events.append("page:\($0)") }
            .onSizeChange { events.append("size:\($0)") }

        pagination.selectPage(9)
        pagination.selectPageSize(20)

        XCTAssertEqual(page.value, 2)
        XCTAssertEqual(size.value, 20)
        XCTAssertEqual(events, ["page:4", "size:20", "page:2"])
    }

    func testPaginationAcceptsUncontrolledPageProps() {
        let pagination = UPPagination(currentPage: 2, pageSize: 20, total: 100)

        XCTAssertEqual(pagination.currentPage, 2)
        XCTAssertEqual(pagination.pageSize, 20)
        XCTAssertEqual(pagination.totalPages, 5)
    }

    /// 上游 props 内联在 `.vue` 里：`currentPage: 1`、`pageSize: 10`、`total: 0`、
    /// `prevText`/`nextText` 空串、`buttonBgColor: '#f5f7fa'`、
    /// `buttonBorderColor: '#dcdfe6'`、`pageSizes: [10,20,30,40,50]`、
    /// `layout: 'prev, pager, next'`、`hideOnSinglePage: false`。
    func testPaginationPropDefaultsMatchUpstream() {
        XCTAssertEqual(UPConfig.pagination.currentPage, 1)
        XCTAssertEqual(UPConfig.pagination.pageSize, 10)
        XCTAssertEqual(UPConfig.pagination.total, 0)
        XCTAssertEqual(UPConfig.pagination.buttonBgColor, "#f5f7fa")
        XCTAssertEqual(UPConfig.pagination.buttonBorderColor, "#dcdfe6")
        XCTAssertEqual(UPConfig.pagination.pageSizes, [10, 20, 30, 40, 50])
        XCTAssertEqual(UPConfig.pagination.layout, "prev, pager, next")
        XCTAssertFalse(UPConfig.pagination.hideOnSinglePage)
        XCTAssertEqual(UPConfig.pagination.activeColor, "#409eff")

        let pagination = UPPagination()
        XCTAssertEqual(pagination.currentPage, 1)
        XCTAssertEqual(pagination.pageSize, 10)
        XCTAssertEqual(pagination.total, 0)
        XCTAssertEqual(pagination.prevText, "")
        XCTAssertEqual(pagination.nextText, "")
        XCTAssertEqual(pagination.layout, "prev, pager, next")
        XCTAssertFalse(pagination.hideOnSinglePage)
        // total 为 0 时上游 totalPages 仍至少 1。
        XCTAssertEqual(pagination.totalPages, 1)
    }

    /// 上游 `normalizedPageSizes` / `pageSizeIndex` / `pageSizeLabel`。
    func testPaginationNormalizesPageSizes() {
        let pagination = UPPagination(currentPage: 1, pageSize: 20, total: 100, pageSizes: [10, 20, 30])
        XCTAssertEqual(pagination.normalizedPageSizes.map(\.value), [10, 20, 30])
        XCTAssertEqual(pagination.normalizedPageSizes.map(\.label), ["10条/页", "20条/页", "30条/页"])
        XCTAssertEqual(pagination.pageSizeIndex, 1)
        XCTAssertEqual(pagination.pageSizeLabel, "20条/页")

        // 上游 pageSizeIndex 找不到时回落 0，pageSizeLabel 直接显示数字。
        let mismatched = UPPagination(currentPage: 1, pageSize: 25, total: 100, pageSizes: [10, 20])
        XCTAssertEqual(mismatched.pageSizeIndex, 0)
        XCTAssertEqual(mismatched.pageSizeLabel, "25")
    }

    /// 上游模板 `v-if="total > 0 && layout.includes('total')"` 与 `共 N 条` 文案。
    func testPaginationTotalSectionFollowsLayout() {
        let hidden = UPPagination(currentPage: 1, pageSize: 10, total: 100)
        XCTAssertFalse(hidden.showsTotal)

        let shown = UPPagination(currentPage: 1, pageSize: 10, total: 100,
                                 layout: "total, prev, pager, next")
        XCTAssertTrue(shown.showsTotal)
        XCTAssertEqual(shown.totalText, "共 100 条")

        // total 为 0 时即便 layout 带 total 也不渲染。
        let empty = UPPagination(currentPage: 1, pageSize: 10, total: 0, layout: "total, prev")
        XCTAssertFalse(empty.showsTotal)
    }

    /// 上游 `hideOnSinglePage`：只有一页时整块不渲染。
    func testPaginationHidesOnSinglePage() {
        XCTAssertTrue(UPPagination(currentPage: 1, pageSize: 10, total: 8,
                                   hideOnSinglePage: true).isHidden)
        XCTAssertFalse(UPPagination(currentPage: 1, pageSize: 10, total: 80,
                                    hideOnSinglePage: true).isHidden)
        // hideOnSinglePage 为假时照旧渲染。
        XCTAssertFalse(UPPagination(currentPage: 1, pageSize: 10, total: 8).isHidden)
    }

    /// 上游 `displayedPages` 三分支：靠头、靠尾、居中。
    func testPaginationDisplayedPagesBranches() {
        // 总页数不超过 4 时全列。
        XCTAssertEqual(UPPagination.tokens(current: 1, total: 3),
                       [.page(1), .page(2), .page(3)])

        // 当前页靠头：1-4 + 省略号 + 尾页。
        XCTAssertEqual(UPPagination.tokens(current: 2, total: 10),
                       [.page(1), .page(2), .page(3), .page(4), .ellipsis, .page(10)])

        // 当前页靠尾：首页 + 省略号 + 末四页。
        XCTAssertEqual(UPPagination.tokens(current: 10, total: 10),
                       [.page(1), .ellipsis, .page(7), .page(8), .page(9), .page(10)])

        // 居中：首页 + 省略号 + 三页 + 省略号 + 尾页。
        XCTAssertEqual(UPPagination.tokens(current: 5, total: 10),
                       [.page(1), .ellipsis, .page(4), .page(5), .page(6), .ellipsis, .page(10)])
    }
}

@MainActor
private final class IntBox {
    var value: Int

    init(_ value: Int) { self.value = value }

    var binding: Binding<Int> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
