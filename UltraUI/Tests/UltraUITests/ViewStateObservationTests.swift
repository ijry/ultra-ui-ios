import Foundation
import Observation
import XCTest
@testable import UltraUI

@MainActor
final class ViewStateObservationTests: XCTestCase {
    private func assertMutationInvalidates<Value>(
        _ name: String,
        read: () -> Value,
        mutate: () -> Void
    ) {
        let invalidated = expectation(description: "\(name) state invalidated")

        withObservationTracking {
            _ = read()
        } onChange: {
            invalidated.fulfill()
        }

        mutate()

        XCTAssertEqual(XCTWaiter.wait(for: [invalidated], timeout: 0.1), .completed)
    }

    func testAlbumSelectionInvalidatesObservers() {
        let view = UPAlbum(images: ["first", "second"])
        assertMutationInvalidates("UPAlbum", read: { view.current }) {
            view.select(1)
        }
    }

    func testCalendarSelectionInvalidatesObservers() {
        let view = UPCalendar()
        let selectedDate = Date(timeIntervalSince1970: 1_000)
        assertMutationInvalidates("UPCalendar", read: { view.selectedDates }) {
            view.select(selectedDate)
        }
    }

    func testCateTabSelectionInvalidatesObservers() {
        let view = UPCateTab(items: ["First", "Second"])
        assertMutationInvalidates("UPCateTab", read: { view.current }) {
            view.select(1)
        }
    }

    func testCouponClaimInvalidatesObservers() {
        let view = UPCoupon(title: "Coupon")
        assertMutationInvalidates("UPCoupon", read: { view.isClaimed }) {
            view.claim()
        }
    }

    func testCropperRectChangeInvalidatesObservers() {
        let view = UPCropper(sourceSize: CGSize(width: 100, height: 100))
        assertMutationInvalidates("UPCropper", read: { view.cropRect }) {
            view.setCropRect(CGRect(x: 10, y: 10, width: 50, height: 50))
        }
    }

    func testGoodsSkuSelectionInvalidatesObservers() {
        let view = UPGoodsSku(options: [UPGoodsSkuOption(name: "Color", values: ["Red"])])
        assertMutationInvalidates("UPGoodsSku", read: { view.selections }) {
            view.select("Color", value: "Red")
        }
    }

    func testNoNetworkStatusChangeInvalidatesObservers() {
        let view = UPNoNetwork(status: .wifi)
        assertMutationInvalidates("UPNoNetwork", read: { view.status }) {
            view.update(.offline)
        }
    }

    func testPDFPageChangeInvalidatesObservers() {
        let view = UPPDFReader()
        assertMutationInvalidates("UPPDFReader", read: { view.currentPage }) {
            view.goToPage(2)
        }
    }

    func testShortVideoPlaybackChangeInvalidatesObservers() {
        let view = UPShortVideo()
        assertMutationInvalidates("UPShortVideo", read: { view.isPlaying }) {
            view.play()
        }
    }

    func testSignatureStrokeChangeInvalidatesObservers() {
        let view = UPSignature()
        assertMutationInvalidates("UPSignature", read: { view.strokes }) {
            view.addStroke([.zero, CGPoint(x: 10, y: 10)])
        }
    }

    func testTreeExpansionInvalidatesObservers() {
        let view = UPTree(nodes: [
            UPTreeNode(
                id: "root",
                title: "Root",
                children: [UPTreeNode(id: "child", title: "Child")]
            )
        ])
        assertMutationInvalidates("UPTree", read: { view.expandedIDs }) {
            view.toggle("root")
        }
    }

    func testUploadFileChangeInvalidatesObservers() {
        let view = UPUpload()
        let file = UPUploadFile(name: "demo.txt", data: Data())
        assertMutationInvalidates("UPUpload", read: { view.files }) {
            view.add(file)
        }
    }

    func testCityLocationChangeInvalidatesObservers() async {
        let location = UPLocationCoordinate(latitude: 31.2304, longitude: 121.4737)
        let view = UPCityLocate(provider: UPStaticLocationProvider(result: .success(location)))
        let invalidated = expectation(description: "UPCityLocate state invalidated")

        withObservationTracking {
            _ = view.lastLocation
        } onChange: {
            invalidated.fulfill()
        }

        _ = await view.locate()

        await fulfillment(of: [invalidated], timeout: 0.1)
    }
}
