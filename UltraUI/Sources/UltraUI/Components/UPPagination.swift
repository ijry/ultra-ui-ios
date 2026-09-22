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
///
/// 上游是「上一页 + 页码列表 + 总数 + 每页条数选择器 + 下一页」五段，
/// 由 `layout` 字符串里的关键字决定渲染哪几段。页码折叠规则见 `displayedPages`：
/// 总页数不超过 4 时全列，否则按当前页靠头/靠尾/居中三分支插省略号。
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
        total: Int = UPConfig.pagination.total,
        prevText: String = UPConfig.pagination.prevText,
        nextText: String = UPConfig.pagination.nextText,
        buttonBgColor: String = UPConfig.pagination.buttonBgColor,
        buttonBorderColor: String = UPConfig.pagination.buttonBorderColor,
        pageSizes: [Int] = UPConfig.pagination.pageSizes,
        layout: String = UPConfig.pagination.layout,
        hideOnSinglePage: Bool = UPConfig.pagination.hideOnSinglePage
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
        currentPage: Int = UPConfig.pagination.currentPage,
        pageSize: Int = UPConfig.pagination.pageSize,
        total: Int = UPConfig.pagination.total,
        prevText: String = UPConfig.pagination.prevText,
        nextText: String = UPConfig.pagination.nextText,
        buttonBgColor: String = UPConfig.pagination.buttonBgColor,
        buttonBorderColor: String = UPConfig.pagination.buttonBorderColor,
        pageSizes: [Int] = UPConfig.pagination.pageSizes,
        layout: String = UPConfig.pagination.layout,
        hideOnSinglePage: Bool = UPConfig.pagination.hideOnSinglePage
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

    /// 上游 `hideOnSinglePage`：只有一页时整块不渲染。
    public var isHidden: Bool { hideOnSinglePage && totalPages <= 1 }

    /// 上游 `normalizedPageSizes`：把数字数组转成 `{ label, value }`，
    /// 标签模板是 `${size}条/页`。
    public var normalizedPageSizes: [UPPaginationPageSize] {
        validPageSizes.map {
            UPPaginationPageSize(label: "\($0)\(UPConfig.pagination.pageSizeLabelSuffix)", value: $0)
        }
    }

    /// 上游 `pageSizeIndex`：找不到当前 `pageSize` 时回落 0。
    public var pageSizeIndex: Int {
        normalizedPageSizes.firstIndex { $0.value == selectedPageSize } ?? 0
    }

    /// 上游 `pageSizeLabel`：命中就用标签，否则直接显示数字。
    public var pageSizeLabel: String {
        normalizedPageSizes.first { $0.value == selectedPageSize }?.label ?? String(selectedPageSize)
    }

    /// 上游模板 `v-if="total > 0 && layout.includes('total')"`。
    public var showsTotal: Bool { total > 0 && layoutParts.contains("total") }

    /// 上游 `共 {{ total }} 条`。
    public var totalText: String {
        "\(UPConfig.pagination.totalPrefix)\(total)\(UPConfig.pagination.totalSuffix)"
    }

    public var body: some View {
        if !isHidden {
            HStack(spacing: 0) {
                if layoutParts.contains("prev") { prevButton }
                if layoutParts.contains("pager") { pager }

                if showsTotal {
                    Text(totalText)
                        .font(.system(size: UPConfig.pagination.fontSize))
                        .foregroundStyle(UPColor.parse(UPConfig.pagination.textColor))
                        .padding(.trailing, UPConfig.pagination.sectionSpacing)
                }

                if layoutParts.contains("sizes"), !normalizedPageSizes.isEmpty { sizePicker }
                if layoutParts.contains("next") { nextButton }
            }
            .font(.system(size: UPConfig.pagination.fontSize))
            .foregroundStyle(UPColor.parse(UPConfig.pagination.textColor))
        }
    }

    /// 上游 `prevText` 为空时渲染 `arrow-left` 图标。
    private var prevButton: some View {
        navigationButton(text: prevText,
                         icon: UPConfig.pagination.prevIcon,
                         page: selectedPage - 1,
                         disabled: selectedPage <= 1)
    }

    private var nextButton: some View {
        navigationButton(text: nextText,
                         icon: UPConfig.pagination.nextIcon,
                         page: selectedPage + 1,
                         disabled: selectedPage >= totalPages)
    }

    private func navigationButton(text: String,
                                  icon: String,
                                  page: Int,
                                  disabled: Bool) -> some View {
        Button { selectPage(page) } label: {
            Group {
                if text.isEmpty {
                    UPIcon(name: icon, color: UPConfig.pagination.textColor)
                } else {
                    Text(text)
                }
            }
            .padding(UPConfig.pagination.buttonPadding)
            .background(UPColor.parse(buttonBgColor))
            .overlay {
                RoundedRectangle(cornerRadius: UPConfig.pagination.cornerRadius)
                    .stroke(UPColor.parse(buttonBorderColor), lineWidth: UPUnit.rpx(CGFloat(1)))
            }
            .clipShape(RoundedRectangle(cornerRadius: UPConfig.pagination.cornerRadius))
            // 上游 `.disabled { opacity: 0.5 }` 只改透明度，点击仍走 goTo 的边界判定。
            .opacity(disabled ? UPConfig.pagination.disabledOpacity : 1)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, UPConfig.pagination.buttonSpacing)
    }

    /// 上游页码列表：激活项换 `#409eff` 底色 + 白字，省略号不可点。
    private var pager: some View {
        ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
            switch token {
            case let .page(page):
                Button { selectPage(page) } label: {
                    Text(String(page))
                        .foregroundStyle(page == selectedPage
                                         ? Color.white
                                         : UPColor.parse(UPConfig.pagination.textColor))
                        .padding(.horizontal, UPConfig.pagination.itemHorizontalPadding)
                        .padding(.vertical, UPConfig.pagination.buttonPadding)
                        .background(page == selectedPage
                                    ? UPColor.parse(UPConfig.pagination.activeColor)
                                    : Color.clear,
                                    in: RoundedRectangle(cornerRadius: UPConfig.pagination.cornerRadius))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, UPConfig.pagination.itemSpacing)
            case .ellipsis:
                Text("...")
                    .padding(.horizontal, UPConfig.pagination.itemHorizontalPadding)
                    .padding(.vertical, UPConfig.pagination.buttonPadding)
            }
        }
    }

    /// 上游 `<picker mode="selector">` 显示 `pageSizeLabel`，选中后抛 `size-change`。
    private var sizePicker: some View {
        Menu {
            ForEach(normalizedPageSizes) { size in
                Button(size.label) { selectPageSize(size.value) }
            }
        } label: {
            Text(pageSizeLabel)
                .padding(UPConfig.pagination.buttonPadding)
                .overlay {
                    RoundedRectangle(cornerRadius: UPConfig.pagination.cornerRadius)
                        .stroke(UPColor.parse(buttonBorderColor), lineWidth: UPUnit.rpx(CGFloat(1)))
                }
        }
        .padding(.trailing, UPConfig.pagination.sectionSpacing)
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

}
