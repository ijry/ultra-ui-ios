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
}

@MainActor
private final class IntBox {
    var value: Int

    init(_ value: Int) { self.value = value }

    var binding: Binding<Int> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
