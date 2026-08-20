import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CardTests: XCTestCase {
    func testDefaultsMatchUviewPlusCard() {
        let card = UPCard()

        XCTAssertFalse(card.full)
        XCTAssertEqual(card.title, "")
        XCTAssertEqual(card.titleColor, "#303133")
        XCTAssertEqual(card.titleSize, "15px")
        XCTAssertEqual(card.subTitle, "")
        XCTAssertEqual(card.subTitleColor, "#909399")
        XCTAssertEqual(card.subTitleSize, "13px")
        XCTAssertTrue(card.border)
        XCTAssertEqual(card.index, "")
        XCTAssertEqual(card.margin, "15px")
        XCTAssertEqual(card.borderRadius, "8px")
        XCTAssertEqual(card.headStyle, UPStyle())
        XCTAssertEqual(card.bodyStyle, UPStyle())
        XCTAssertEqual(card.footStyle, UPStyle())
        XCTAssertTrue(card.headBorderBottom)
        XCTAssertTrue(card.footBorderTop)
        XCTAssertEqual(card.thumb, "")
        XCTAssertEqual(card.thumbWidth, "30px")
        XCTAssertFalse(card.thumbCircle)
        XCTAssertEqual(card.padding, "15px")
        XCTAssertEqual(card.paddingHead, "")
        XCTAssertEqual(card.paddingBody, "")
        XCTAssertEqual(card.paddingFoot, "")
        XCTAssertTrue(card.showHead)
        XCTAssertTrue(card.showFoot)
        XCTAssertEqual(card.boxShadow, "none")
    }

    func testStringOrNumberPropsAndPaddingFallbackNormalizeForNativeRendering() {
        let card = UPCard(
            titleSize: 16,
            subTitleSize: "14px",
            borderRadius: 12,
            thumbWidth: 36,
            padding: "10px 20px",
            paddingHead: "8px",
            paddingBody: "12rpx"
        )

        XCTAssertEqual(card.titleSize, "16")
        XCTAssertEqual(card.subTitleSize, "14px")
        XCTAssertEqual(card.borderRadius, "12")
        XCTAssertEqual(card.thumbWidth, "36")
        XCTAssertEqual(card.resolvedBorderRadius, 12)
        XCTAssertEqual(card.resolvedThumbWidth, 36)
        XCTAssertEqual(card.resolvedHeadPadding, UPInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        XCTAssertEqual(card.resolvedBodyPadding, UPInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        XCTAssertEqual(card.resolvedFootPadding, UPInsets.zero)
    }

    func testNamedSlotsReplaceDefaultHeadAndControlFooterPadding() {
        let defaultHead = UPCard(title: "订单", subTitle: "待付款") { Text("内容") }
        let slotted = UPCard(
            padding: "15px",
            paddingFoot: "2px 15px",
            head: { Text("自定义头部") },
            body: { Text("内容") },
            foot: { Text("底部") }
        )

        XCTAssertTrue(defaultHead.hasDefaultHead)
        XCTAssertFalse(defaultHead.hasHeadSlot)
        XCTAssertFalse(defaultHead.hasFootSlot)
        XCTAssertEqual(defaultHead.resolvedFootPadding, UPInsets.zero)

        XCTAssertFalse(slotted.hasDefaultHead)
        XCTAssertTrue(slotted.hasHeadSlot)
        XCTAssertTrue(slotted.hasFootSlot)
        XCTAssertEqual(slotted.resolvedHeadPadding, UPInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
        XCTAssertEqual(slotted.resolvedBodyPadding, UPInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
        XCTAssertEqual(slotted.resolvedFootPadding, UPInsets(top: 2, leading: 15, bottom: 2, trailing: 15))
    }

    func testShowHeadAndShowFootRetainUpstreamVisibilityProps() {
        let card = UPCard(showHead: false, showFoot: false) { Text("内容") }

        XCTAssertFalse(card.showHead)
        XCTAssertFalse(card.showFoot)
        XCTAssertFalse(card.hasDefaultHead)
    }

    func testIndexAcceptsAllJsonLikeLiteralForms() {
        let stringCard = UPCard(index: "first")
        let numberCard = UPCard(index: 2)
        let boolCard = UPCard(index: true)
        let arrayCard = UPCard(index: [1, "orders", false])
        let objectIndex: UPCardIndex = ["id": 7, "visible": true]
        let objectCard = UPCard(index: objectIndex)

        XCTAssertEqual(stringCard.index, "first")
        XCTAssertEqual(numberCard.index, 2)
        XCTAssertEqual(boolCard.index, true)
        XCTAssertEqual(arrayCard.index, [1, "orders", false])
        XCTAssertEqual(objectCard.index, objectIndex)
    }

    func testFullCardSuppressesOuterBorderAndHorizontalMargin() {
        let card = UPCard(full: true, border: true, margin: "10px 20px 30px 40px")

        XCTAssertFalse(card.showsOuterBorder)
        XCTAssertEqual(card.resolvedMargin, UPInsets(top: 10, leading: 0, bottom: 30, trailing: 0))
    }

    func testClickEventModifiersReceiveTheSameIndexAsUviewPlusEmits() {
        let index: UPCardIndex = ["id": 7]
        var received: [UPCardIndex] = []
        let card = UPCard(index: index)
            .onClick { received.append($0) }
            .onHeadClick { received.append($0) }
            .onBodyClick { received.append($0) }
            .onFootClick { received.append($0) }

        card.onClickHandler?(card.index)
        card.onHeadClickHandler?(card.index)
        card.onBodyClickHandler?(card.index)
        card.onFootClickHandler?(card.index)

        XCTAssertEqual(received, [index, index, index, index])
    }
}
