import XCTest
@testable import UltraUI

@MainActor
final class AvatarGroupTests: XCTestCase {
    func testDefaultsMatchUviewPlusAvatarGroup() {
        let group = UPAvatarGroup()

        XCTAssertTrue(group.urls.isEmpty)
        XCTAssertEqual(group.maxCount, 5)
        XCTAssertEqual(group.shape, "circle")
        XCTAssertEqual(group.mode, "scaleToFill")
        XCTAssertTrue(group.showMore)
        XCTAssertEqual(group.size, 40)
        XCTAssertEqual(group.keyName, "")
        XCTAssertEqual(group.gap, 0.5)
        XCTAssertEqual(group.extraValue, 0)
        XCTAssertEqual(group.customClass, "")
        XCTAssertEqual(group.customStyle, UPStyle())

        let customized = UPAvatarGroup(customClass: "people")
        XCTAssertEqual(customized.customClass, "people")
    }

    func testVisibleURLsRespectMaxCountAndObjectKeyResolution() {
        let group = UPAvatarGroup(
            urls: [
                "first.png",
                .object(["avatar": "second.png", "url": "fallback.png"]),
                .object(["url": "third.png"])
            ],
            maxCount: 2,
            keyName: "avatar"
        )

        XCTAssertEqual(group.visibleURLs, ["first.png", "second.png"])
        XCTAssertEqual(group.hiddenCount, 1)
        XCTAssertTrue(group.showsMoreIndicator)
        XCTAssertEqual(group.moreText, "+1")
    }

    func testExtraValueOverridesHiddenCountForMoreIndicator() {
        let group = UPAvatarGroup(
            urls: ["one.png"],
            maxCount: 5,
            extraValue: 8
        )

        XCTAssertTrue(group.showsMoreIndicator)
        XCTAssertEqual(group.moreText, "+8")
    }

    func testObjectURLFallsBackToURLWhenConfiguredKeyIsMissing() {
        let group = UPAvatarGroup(
            urls: [.object(["url": "fallback.png"])],
            keyName: "avatar"
        )

        XCTAssertEqual(group.visibleURLs, ["fallback.png"])
    }

    func testOnShowMoreModifierRegistersCallback() {
        var didRequestMore = false
        let group = UPAvatarGroup(urls: ["one.png", "two.png"], maxCount: 1)
            .onShowMore { didRequestMore = true }

        group.showMoreHandler?()

        XCTAssertTrue(didRequestMore)
    }


    func testMixedStringAndNumberUnitPropsAreAcceptedIndependently() {
        let group = UPAvatarGroup(
            urls: ["one.png", "two.png"],
            maxCount: "1",
            size: 36,
            gap: "0.25",
            extraValue: 3
        )

        XCTAssertEqual(group.maxCount, 1)
        XCTAssertEqual(group.size, 36)
        XCTAssertEqual(group.gap, 0.25)
        XCTAssertEqual(group.extraValue, 3)
        XCTAssertEqual(group.visibleURLs, ["one.png"])
        XCTAssertEqual(group.moreText, "+3")
    }
}
