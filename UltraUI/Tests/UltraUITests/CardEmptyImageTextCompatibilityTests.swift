import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class CardEmptyImageTextCompatibilityTests: XCTestCase {
    func testCardAcceptsCamelCasePropsNumericValuesSlotsAndEvents() {
        let index: UPCardIndex = ["id": 7, "visible": true]
        var received: [UPCardIndex] = []
        let card = UPCard(
            full: true,
            title: "订单",
            titleColor: "#303133",
            titleSize: 16,
            subTitle: "待付款",
            subTitleColor: "#909399",
            subTitleSize: "14px",
            border: true,
            index: index,
            margin: "10px 20px",
            borderRadius: 12,
            headBorderBottom: false,
            footBorderTop: false,
            thumbWidth: 36,
            thumbCircle: true,
            padding: "10px 20px",
            paddingHead: 8,
            paddingBody: "12rpx",
            paddingFoot: 6,
            showHead: true,
            showFoot: true,
            head: { Text("自定义头部") },
            body: { Text("自定义主体") },
            foot: { Text("自定义底部") }
        )
        .onClick { received.append($0) }
        .onHeadClick { received.append($0) }
        .onBodyClick { received.append($0) }
        .onFootClick { received.append($0) }

        card.onClickHandler?(card.index)
        card.onHeadClickHandler?(card.index)
        card.onBodyClickHandler?(card.index)
        card.onFootClickHandler?(card.index)

        XCTAssertEqual(card.titleSize, "16")
        XCTAssertEqual(card.subTitleSize, "14px")
        XCTAssertEqual(card.resolvedHeadPadding, UPInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        XCTAssertTrue(card.hasHeadSlot)
        XCTAssertTrue(card.hasFootSlot)
        XCTAssertEqual(received, [index, index, index, index])
    }

    func testEmptyAcceptsMixedNumericPropsAndDefaultSlot() {
        let empty = UPEmpty(
            icon: "https://example.com/empty.png",
            text: "暂无内容",
            textColor: "#c0c4cc",
            textSize: 15,
            iconColor: "#909399",
            iconSize: "88px",
            mode: "data",
            width: 120,
            height: "90rpx",
            show: true,
            marginTop: 24
        ) { Text("重新加载") }

        XCTAssertTrue(empty.usesImageIcon)
        XCTAssertEqual(empty.displayText, "暂无内容")
        XCTAssertEqual(empty.resolvedTextSize, 15)
        XCTAssertEqual(empty.resolvedIconSize, 88)
        XCTAssertEqual(empty.resolvedWidth, 120)
        XCTAssertEqual(empty.resolvedHeight, 90)
        XCTAssertEqual(empty.resolvedMarginTop, 24)
    }

    func testImageAcceptsMixedNumericPropsNamedSlotsAndEvents() {
        var clickCount = 0
        var loadedSource = ""
        var failedSource = ""
        let image = UPImage(
            src: "https://example.com/avatar.png",
            mode: "aspectFill",
            width: 120,
            height: "60rpx",
            shape: "square",
            radius: 12,
            lazyLoad: true,
            showMenuByLongpress: true,
            loadingIcon: "photo",
            errorIcon: "error-circle",
            showLoading: true,
            showError: true,
            fade: true,
            webp: false,
            duration: "250",
            bgColor: "#f3f4f6",
            loading: { Text("加载中") },
            error: { Text("加载失败") }
        )
        .onClick { clickCount += 1 }
        .onLoad { loadedSource = $0.source }
        .onError { failedSource = $0.source }

        image.onClickHandler?()
        image.onLoadHandler?(UPImageLoadEvent(source: image.src))
        image.onErrorHandler?(UPImageErrorEvent(source: image.src, message: "offline"))

        XCTAssertEqual(image.width, "120")
        XCTAssertEqual(image.height, "60rpx")
        XCTAssertEqual(image.radius, "12")
        XCTAssertEqual(image.duration, 250)
        XCTAssertTrue(image.hasLoadingSlot)
        XCTAssertTrue(image.hasErrorSlot)
        XCTAssertEqual(clickCount, 1)
        XCTAssertEqual(loadedSource, image.src)
        XCTAssertEqual(failedSource, image.src)
    }

    func testTextAcceptsCamelCasePropsNumericValuesAndClickEvents() {
        var tapCount = 0
        var clickCount = 0
        let text = UPText(
            type: "primary",
            show: true,
            text: 1234,
            prefixIcon: "star",
            suffixIcon: "arrow-right",
            mode: "",
            href: "",
            format: "",
            call: false,
            openType: "",
            bold: true,
            block: true,
            lines: 2,
            color: "",
            size: "16px",
            decoration: "underline",
            margin: "4px 8px",
            lineHeight: 24,
            align: "center",
            wordWrap: "break-word",
            flex1: true,
            onTap: { tapCount += 1 },
            onClick: { clickCount += 1 }
        )

        text.onTap?()
        text.onClick?()

        XCTAssertEqual(text.text, "1234")
        XCTAssertEqual(text.lines, "2")
        XCTAssertEqual(text.resolvedSize, 16)
        XCTAssertEqual(text.resolvedLineLimit, 2)
        XCTAssertEqual(text.resolvedMargin, UPInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        XCTAssertEqual(tapCount, 1)
        XCTAssertEqual(clickCount, 1)
    }
}
