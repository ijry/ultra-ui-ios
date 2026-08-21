import Foundation
import SwiftUI
#if canImport(PDFKit)
import PDFKit
#endif

@MainActor
public final class UPPDFReader: View {
    public let documentData: Data
    public private(set) var currentPage: Int
    private var onPageChangeHandler: ((Int) -> Void)?

    public init(documentData: Data = Data(), currentPage: Int = 0,
                onPageChange: ((Int) -> Void)? = nil) {
        self.documentData = documentData
        self.currentPage = max(0, currentPage)
        self.onPageChangeHandler = onPageChange
    }

    public func onPageChange(_ action: @escaping (Int) -> Void) -> UPPDFReader {
        onPageChangeHandler = action
        return self
    }

    public func goToPage(_ page: Int) {
        currentPage = max(0, page)
        onPageChangeHandler?(currentPage)
    }

    public var pageCount: Int {
        #if canImport(PDFKit)
        return PDFDocument(data: documentData)?.pageCount ?? 0
        #else
        return 0
        #endif
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.richtext")
            Text(pageCount > 0 ? "\(currentPage + 1) / \(pageCount)" : "PDF")
        }
    }
}
