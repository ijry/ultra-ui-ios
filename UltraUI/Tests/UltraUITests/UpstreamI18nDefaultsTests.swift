import SwiftUI
import XCTest
@testable import UltraUI

/// 上游把一批 prop 默认值交给 i18n 表决定：`libs/config/props/*.js` 里写的是
/// `t("up.xxx")`，实际文案来自 `libs/i18n/locales/zh-Hans.js`。这些默认值属于
/// 组件契约的一部分，逐条钉住，避免再次抄成近义词（例如 `确定` 抄成 `确认`）。
@MainActor
final class UpstreamI18nDefaultsTests: XCTestCase {
    /// `up.common.confirm` 是「确定」而不是「确认」，上游 6 个组件共用这个 key。
    func testCommonConfirmAndCancelTextsMatchUpstreamLocale() {
        XCTAssertEqual(UPConfig.modal.confirmText, "确定")
        XCTAssertEqual(UPConfig.modal.cancelText, "取消")
        XCTAssertEqual(UPModal(show: .constant(false)).confirmText, "确定")
        XCTAssertEqual(UPToolbar().confirmText, "确定")
        XCTAssertEqual(UPToolbar().cancelText, "取消")
        XCTAssertEqual(UPPicker().confirmText, "确定")
        XCTAssertEqual(UPPicker().cancelText, "取消")
        XCTAssertEqual(UPDatetimePicker().confirmText, "确定")
        XCTAssertEqual(UPDatetimePicker().cancelText, "取消")
    }

    /// `up.common.pleaseChoose` = 请选择，两个 picker 的空值占位都走它。
    func testPickerPlaceholdersUseUpstreamPleaseChooseText() {
        XCTAssertEqual(UPPicker().placeholder, "请选择")
        XCTAssertEqual(UPDatetimePicker().placeholder, "请选择")
    }

    /// `u-read-more` 的 closeText / openText 分别是 `up.readMore.expand` 与
    /// `up.readMore.fold`，折叠态提示是「展开阅读全文」而不是「展开」。
    func testReadMoreToggleTextsMatchUpstreamDefaults() {
        let collapsed = UPReadMore(lines: 3, expanded: false)
        XCTAssertEqual(collapsed.closeText, "展开阅读全文")
        XCTAssertEqual(collapsed.openText, "收起")
        XCTAssertEqual(collapsed.toggleText, "展开阅读全文")

        let expanded = UPReadMore(lines: 3, expanded: true)
        XCTAssertEqual(expanded.toggleText, "收起")

        let custom = UPReadMore(lines: 3, closeText: "展开", openText: "折叠")
        XCTAssertEqual(custom.toggleText, "展开")
        custom.toggleReadMore()
        XCTAssertEqual(custom.toggleText, "折叠")
    }

    /// `u-no-network` 的 tips 默认取 `up.noNetwork.text`。
    func testNoNetworkTipsMatchUpstreamDefault() {
        XCTAssertEqual(UPNoNetwork().tips, "哎呀，网络信号丢失")
        XCTAssertEqual(UPNoNetwork(status: .offline, tips: "断网了").tips, "断网了")
    }

    /// `u-city-locate` 的定位入口文字是 `up.cityLocate.locateCity`；定位失败的描述
    /// 上游只有一条 `up.cityLocate.fail`，这里按失败原因分开写，但同样用中文。
    func testCityLocateTextsUseUpstreamChineseWording() {
        XCTAssertEqual(UPCityLocate().locateText, "定位城市")
        XCTAssertEqual(UPCityLocate(locateText: "重新定位").locateText, "重新定位")
        XCTAssertEqual(UPLocationError.denied.localizedDescription, "定位权限被拒绝")
        XCTAssertEqual(UPLocationError.unavailable.localizedDescription, "定位服务不可用")
        XCTAssertEqual(UPLocationError.failed("timeout").localizedDescription, "timeout")
    }

    /// 其余已经对齐的 i18n 默认值，一并钉住防回归。
    func testRemainingLocaleBackedDefaultsStayAligned() {
        XCTAssertEqual(UPConfig.code.startText, "获取验证码")
        XCTAssertEqual(UPConfig.code.changeText, "X秒重新获取")
        XCTAssertEqual(UPConfig.code.endText, "重新获取")
        XCTAssertEqual(UPConfig.link.mpTips, "链接已复制，请在浏览器打开")
        XCTAssertEqual(UPConfig.loadmore.loadmoreText, "加载更多")
        XCTAssertEqual(UPConfig.loadmore.loadingText, "正在加载...")
        XCTAssertEqual(UPConfig.loadmore.nomoreText, "没有更多了")
        XCTAssertEqual(UPConfig.modal.asyncCloseTip, "操作中...")
        XCTAssertEqual(UPConfig.search.placeholder, "请输入关键字")
        XCTAssertEqual(UPConfig.search.actionText, "搜索")
        XCTAssertEqual(UPLoadingPage().loadingText, "正在加载")
        XCTAssertEqual(UPSection().subTitle, "更多")
    }
}
