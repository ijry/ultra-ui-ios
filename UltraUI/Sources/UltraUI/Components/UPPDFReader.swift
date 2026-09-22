import Foundation
import Observation
import SwiftUI
#if canImport(PDFKit)
import PDFKit
#endif

/// SwiftUI requires views to be value types, so the mutable page index lives in
/// a small reference box rather than making the view itself a class.
@MainActor
@Observable
private final class UPPDFReaderState {
    var currentPage: Int

    init(currentPage: Int) {
        self.currentPage = currentPage
    }
}

@MainActor
public struct UPPDFReader: View {
    public let documentData: Data
    public var src: String
    public var height: CGFloat
    public var baseUrl: String
    public var currentPage: Int { state.currentPage }

    @State private var state: UPPDFReaderState
    private var onPageChangeHandler: ((Int) -> Void)?

    public init(documentData: Data = Data(), src: String = UPConfig.pdfReader.src,
                height: some UPImageUnitValue = UPConfig.pdfReader.height,
                baseUrl: String = UPConfig.pdfReader.baseUrl, currentPage: Int = 0,
                onPageChange: ((Int) -> Void)? = nil) {
        self.documentData = documentData
        self.src = src
        self.height = UPUnit.parse(height.upImageUnitValue)
        self.baseUrl = baseUrl
        self._state = State(initialValue: UPPDFReaderState(currentPage: max(0, currentPage)))
        self.onPageChangeHandler = onPageChange
    }

    /// Upstream builds `${baseUrlInner}/static/pdfjs/web/viewer.html?file=` +
    /// `encodeURIComponent(src)` and falls back to the bundled pdf.js domain
    /// whenever `baseUrl` is empty. Kept as metadata because the native reader
    /// renders through PDFKit instead of the H5 viewer.
    public var viewerURL: String {
        let domain = baseUrl.isEmpty ? UPConfig.pdfReader.baseUrl : baseUrl
        return "\(domain)/static/pdfjs/web/viewer.html?file=\(Self.encodeURIComponent(src))"
    }

    /// Mirrors JavaScript `encodeURIComponent`, which leaves
    /// `A-Z a-z 0-9 - _ . ! ~ * ' ( )` untouched.
    static func encodeURIComponent(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_.!~*'()")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    public func onPageChange(_ action: @escaping (Int) -> Void) -> UPPDFReader {
        var copy = self
        copy.onPageChangeHandler = action
        return copy
    }

    public func goToPage(_ page: Int) {
        state.currentPage = max(0, page)
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
