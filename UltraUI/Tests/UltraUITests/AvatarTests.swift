import XCTest
@testable import UltraUI

@MainActor
final class AvatarTests: XCTestCase {
    func testDefaultsMatchUviewPlusAvatar() {
        let avatar = UPAvatar()

        XCTAssertEqual(avatar.src, "")
        XCTAssertEqual(avatar.shape, "circle")
        XCTAssertEqual(avatar.size, 40)
        XCTAssertEqual(avatar.mode, "scaleToFill")
        XCTAssertEqual(avatar.text, "")
        XCTAssertEqual(avatar.bgColor, "#c0c4cc")
        XCTAssertEqual(avatar.color, "#ffffff")
        XCTAssertEqual(avatar.fontSize, 18)
        XCTAssertEqual(avatar.icon, "")
        XCTAssertFalse(avatar.mpAvatar)
        XCTAssertFalse(avatar.randomBgColor)
        XCTAssertEqual(avatar.defaultUrl, "")
        XCTAssertEqual(avatar.colorIndex, "")
        XCTAssertEqual(avatar.name, "")
        XCTAssertEqual(avatar.customClass, "")
        XCTAssertEqual(avatar.customStyle, UPStyle())

        let customized = UPAvatar(customClass: "profile-avatar", customStyle: UPStyle())
        XCTAssertEqual(customized.customClass, "profile-avatar")
    }


    func testImageModeUsesAnAvatarLocalNativeMapping() {
        XCTAssertTrue(UPAvatar.usesAspectFill(for: "scaleToFill"))
        XCTAssertTrue(UPAvatar.usesAspectFill(for: "aspectFill"))
        XCTAssertFalse(UPAvatar.usesAspectFill(for: "aspectFit"))
    }

    func testStringOrNumberPropsAndClickModifierPreserveTheUpstreamSurface() {
        let stringAvatar = UPAvatar(size: "48px", fontSize: "19px", colorIndex: 3)
        XCTAssertEqual(stringAvatar.size, 48)
        XCTAssertEqual(stringAvatar.fontSize, 19)
        XCTAssertEqual(stringAvatar.colorIndex, "3")

        let numericAvatar = UPAvatar(size: 44, fontSize: 16.5, colorIndex: "17", name: "profile")
        XCTAssertEqual(numericAvatar.size, 44)
        XCTAssertEqual(numericAvatar.fontSize, 16.5)
        XCTAssertEqual(numericAvatar.colorIndex, "17")

        var clickedName = ""
        let eventAvatar = numericAvatar.onClick { clickedName = $0 }
        eventAvatar.onClickHandler?(eventAvatar.name)
        XCTAssertEqual(clickedName, "profile")
    }
}
