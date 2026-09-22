import SwiftUI
import XCTest
@testable import UltraUI

/// SwiftUI 要求 `View` 必须是值类型；用 class 声明的 View 一旦被渲染，
/// 运行时会直接 `Fatal error: views must be value types`。这类缺陷无法靠
/// 只测数据方法的单测发现——组件从不被渲染，测试便一直是绿的。
@MainActor
final class ViewValueTypeTests: XCTestCase {
    private func assertValueType<V: View>(_ view: V, _ name: String) {
        let displayStyle = Mirror(reflecting: view).displayStyle
        XCTAssertTrue(
            displayStyle == .struct || displayStyle == .enum,
            "\(name) 是引用类型；SwiftUI View 必须是 struct 或 enum"
        )
    }

    func testCalendarIsAValueTypeView() {
        assertValueType(UPCalendar(), "UPCalendar")
    }

    func testUploadIsAValueTypeView() {
        assertValueType(UPUpload(), "UPUpload")
    }

    func testAlbumIsAValueTypeView() {
        assertValueType(UPAlbum(images: []), "UPAlbum")
    }

    func testTreeIsAValueTypeView() {
        assertValueType(UPTree(), "UPTree")
    }

    func testRemainingClassBackedViewsAreValueTypes() {
        assertValueType(UPCoupon(), "UPCoupon")
        assertValueType(UPCalendarStrip(), "UPCalendarStrip")
        assertValueType(UPCateTab(), "UPCateTab")
        assertValueType(UPNoNetwork(), "UPNoNetwork")
        assertValueType(UPGoodsSku(), "UPGoodsSku")
        assertValueType(UPPDFReader(), "UPPDFReader")
        assertValueType(UPSignature(), "UPSignature")
        assertValueType(UPCityLocate(), "UPCityLocate")
        assertValueType(UPShortVideo(), "UPShortVideo")
        assertValueType(UPCropper(), "UPCropper")
    }
}
