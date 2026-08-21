import SwiftUI

public enum UPPaginationToken: Hashable, Sendable {
    case page(Int)
    case ellipsis
}

public struct UPPaginationPageSize: Equatable, Sendable, Identifiable {
    public let label: String
    public let value: Int
    public var id: Int { value }

    public init(label: String, value: Int) {
        self.label = label
        self.value = value
    }
}

/// Native counterpart of uview-plus `u-pagination`.
@MainActor
public struct UPPagination: View {
    public var currentPage: Int
    public var pageSize: Int
    public var total: Int
    public var prevText: String
    public var nextText: String
    public var buttonBgColor: String
    public var buttonBorderColor: String
    public var pageSizes: [Int]
    public var layout: String
    public var hideOnSinglePage: Bool

    private var currentPageBinding: Binding<Int>?
    private var pageSizeBinding: Binding<Int>?
    private var onCurrentChangeHandler: ((Int) -> Void)?
    private var onSizeChangeHandler: ((Int) -> Void)?

    public init(
        currentPage: Binding<Int>, pageSize: Binding<Int>,
        total: Int = 0, prevText: String = "", nextText: String = "",
        buttonBgColor: String = "#f5f7fa", buttonBorderColor: String = "#dcdfe6",
        pageSizes: [Int] = [10, 20, 30, 40, 50], layout: String = "prev, pager, next",
        hideOnSinglePage: Bool = false
    ) {
        self.currentPage = currentPage.wrappedValue
        self.pageSize = pageSize.wrappedValue
        self.total = total
        self.prevText = prevText
        self.nextText = nextText
        self.buttonBgColor = buttonBgColor
        self.buttonBorderColor = buttonBorderColor
        self.pageSizes = pageSizes
        self.layout = layout
        self.hideOnSinglePage = hideOnSinglePage
        self.currentPageBinding = currentPage
        self.pageSizeBinding = pageSize
    }

    public init(
        currentPage: Int = 1, pageSize: Int = 10, total: Int = 0,
        prevText: String = "", nextText: String = "",
        buttonBgColor: String = "#f5f7fa", buttonBorderColor: String = "#dcdfe6",
        pageSizes: [Int] = [10, 20, 30, 40, 50], layout: String = "prev, pager, next",
        hideOnSinglePage: Bool = false
    ) {
        self.currentPage = currentPage
        self.pageSize = pageSize
        self.total = total
        self.prevText = prevText
        self.nextText = nextText
        self.buttonBgColor = buttonBgColor
        self.buttonBorderColor = buttonBorderColor
        self.pageSizes = pageSizes
        self.layout = layout
        self.hideOnSinglePage = hideOnSinglePage
        self.currentPageBinding = nil
        self.pageSizeBinding = nil
    }

    public var body: some View {
        if !(hideOnSinglePage && totalPages <= 1) {
            HStack(spacing: 6) {
                if layoutParts.contains("prev") {
                    pageButton(label: prevText.isEmpty ? "‹" : prevText, page: selectedPage - 1,
                               disabled: selectedPage <= 1)
                }
                if layoutParts.contains("pager") {
                    ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                        switch token {
                        case .page(let page):
                            pageButton(label: String(page), page: page, disabled: false)
                                .fontWeight(page == selectedPage ? .bold : .regular)
                        case .ellipsis:
                            Text("…")
                        }
                    }
                }
                if layoutParts.contains("next") {
                    pageButton(label: nextText.isEmpty ? "›" : nextText, page: selectedPage + 1,
                               disabled: selectedPage >= totalPages)
                }
                if layoutParts.contains("sizes") {
                    Picker("", selection: Binding(get: { selectedPageSize }, set: { newValue in selectPageSize(newValue) })) {
                        ForEach(validPageSizes, id: \.self) { Text("\($0)/页").tag($0) }
                    }
                    .labelsHidden()
                }
            }
        }
    }

    public var totalPages: Int {
        Self.totalPages(total: total, pageSize: selectedPageSize)
    }

    public var tokens: [UPPaginationToken] {
        Self.tokens(current: selectedPage, total: totalPages)
    }

    public func onCurrentChange(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onCurrentChangeHandler = action
        return copy
    }

    public func onSizeChange(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onSizeChangeHandler = action
        return copy
    }

    public func selectPage(_ page: Int) {
        let normalized = Swift.min(Swift.max(page, 1), totalPages)
        guard normalized != selectedPage else { return }
        currentPageBinding?.wrappedValue = normalized
        onCurrentChangeHandler?(normalized)
    }

    public func selectPageSize(_ size: Int) {
        let normalizedSize = Swift.max(size, 1)
        guard normalizedSize != selectedPageSize else { return }
        pageSizeBinding?.wrappedValue = normalizedSize
        onSizeChangeHandler?(normalizedSize)
        let newTotal = Self.totalPages(total: total, pageSize: normalizedSize)
        let normalizedPage = Swift.min(Swift.max(selectedPage, 1), newTotal)
        if normalizedPage != selectedPage {
            currentPageBinding?.wrappedValue = normalizedPage
            onCurrentChangeHandler?(normalizedPage)
        }
    }

    public static func totalPages(total: Int, pageSize: Int) -> Int {
        let safeTotal = Swift.max(total, 0)
        let safeSize = Swift.max(pageSize, 1)
        return Swift.max(1, Int(ceil(Double(safeTotal) / Double(safeSize))))
    }

    public static func tokens(current: Int, total: Int) -> [UPPaginationToken] {
        let total = Swift.max(total, 1)
        let current = Swift.min(Swift.max(current, 1), total)
        if total <= 4 { return (1...total).map(UPPaginationToken.page) }

        var result: [UPPaginationToken]
        if current <= 2 {
            result = (1...4).map(UPPaginationToken.page) + [.ellipsis, .page(total)]
        } else if current >= total - 1 {
            result = [.page(1), .ellipsis] + ((total - 3)...total).map(UPPaginationToken.page)
        } else {
            result = [.page(1), .ellipsis, .page(current - 1), .page(current), .page(current + 1), .ellipsis, .page(total)]
        }
        return result.reduce(into: []) { output, token in
            if output.last != token { output.append(token) }
        }
    }

    private var selectedPage: Int { currentPageBinding?.wrappedValue ?? currentPage }
    private var selectedPageSize: Int { Swift.max(pageSizeBinding?.wrappedValue ?? pageSize, 1) }
    private var validPageSizes: [Int] { pageSizes.filter { $0 > 0 }.isEmpty ? [10] : pageSizes.filter { $0 > 0 } }
    private var layoutParts: Set<String> {
        Set(layout.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
    }

    private func pageButton(label: String, page: Int, disabled: Bool) -> some View {
        Button(action: { selectPage(page) }) {
            Text(label)
        }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(UPColor.parse(buttonBgColor))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(UPColor.parse(buttonBorderColor)))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .disabled(disabled)
    }
}
