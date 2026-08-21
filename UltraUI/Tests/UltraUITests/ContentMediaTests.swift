import Foundation
import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class RichTextComponentTests: XCTestCase {
    func testMarkdownProducesAttributedContentAndRetainsSource() {
        let markdown = UPMarkdown(content: "# Title\n\n**Bold**")
        XCTAssertEqual(markdown.content, "# Title\n\n**Bold**")
        XCTAssertFalse(markdown.attributedContent.characters.isEmpty)
    }

    func testParseStripsSimpleHTMLAndEmitsErrorForInvalidInput() {
        var error = ""
        let parsed = UPParse(content: "<p>Hello <strong>world</strong></p>")
            .onError { error = $0 }
        XCTAssertTrue(parsed.plainText.contains("Hello"))
        XCTAssertTrue(parsed.plainText.contains("world"))
        XCTAssertTrue(error.isEmpty)
    }
}

@MainActor
final class DocumentMediaTests: XCTestCase {
    func testPDFReaderTracksPageAndEmitsPageChange() {
        var changed = -1
        let reader = UPPDFReader(documentData: Data([37, 80, 68, 70]))
            .onPageChange { changed = $0 }
        XCTAssertEqual(reader.currentPage, 0)
        reader.goToPage(2)
        XCTAssertEqual(reader.currentPage, 2)
        XCTAssertEqual(changed, 2)
    }

    func testShortVideoRetainsPlaybackStateAndEvents() {
        var played = 0
        let video = UPShortVideo(src: "https://example.com/video.mp4")
            .onPlay { played += 1 }
        XCTAssertFalse(video.isPlaying)
        video.play()
        XCTAssertTrue(video.isPlaying)
        XCTAssertEqual(played, 1)
        video.pause()
        XCTAssertFalse(video.isPlaying)
    }
}

@MainActor
final class UploadComponentTests: XCTestCase {
    func testUploadAddsFilesAndEmitsProgressAndSuccess() {
        var progress: Double = 0
        var uploaded = [UPUploadFile]()
        let upload = UPUpload(maxCount: 2)
            .onProgress { progress = $0 }
            .onSuccess { uploaded = $0 }
        let file = UPUploadFile(name: "a.txt", data: Data("A".utf8), mimeType: "text/plain")
        upload.add(file)
        XCTAssertEqual(upload.files.count, 1)
        upload.updateProgress(0.5)
        XCTAssertEqual(progress, 0.5)
        upload.complete()
        XCTAssertEqual(uploaded, [file])
    }
}
