import Foundation
import XCTest
@testable import UltraUI

@MainActor
final class SystemCapabilityTests: XCTestCase {
    func testNoNetworkUsesInjectedStatusAndChangeEvent() {
        var changed: UPNetworkStatus?
        let network = UPNoNetwork(status: .offline)
            .onChange { changed = $0 }
        XCTAssertTrue(network.isOffline)
        network.update(.wifi)
        XCTAssertFalse(network.isOffline)
        XCTAssertEqual(changed, .wifi)
    }

    /// `u-no-network` 的 `image` 与 `zIndex` 默认值来自上游 `noNetwork.js`。
    func testNoNetworkImageAndZIndexMatchUpstreamProps() {
        let network = UPNoNetwork()
        XCTAssertEqual(network.tips, "哎呀，网络信号丢失")
        XCTAssertEqual(network.image, "")
        XCTAssertEqual(network.zIndex, "")
        // 上游把空 zIndex 原样交给 u-overlay，样式层最终回落到 overlay 自己的 10070。
        XCTAssertEqual(network.resolvedZIndex, UPConfig.overlay.zIndex)
        XCTAssertFalse(network.showsCustomImage)

        XCTAssertEqual(UPConfig.noNetwork.tips, "哎呀，网络信号丢失")
        XCTAssertEqual(UPConfig.noNetwork.image, "")
        XCTAssertEqual(UPConfig.noNetwork.zIndex, "")

        let custom = UPNoNetwork(status: .offline,
                                 tips: "断网了",
                                 image: "https://example.com/no-network.png",
                                 zIndex: 10_090)
        XCTAssertEqual(custom.image, "https://example.com/no-network.png")
        XCTAssertEqual(custom.zIndex, "10090")
        XCTAssertEqual(custom.resolvedZIndex, 10_090)
        XCTAssertTrue(custom.showsCustomImage)
        XCTAssertEqual(UPNoNetwork(zIndex: "10086").resolvedZIndex, 10_086)
    }

    /// 上游 `emitEvent(networkType)`：`'none'` 抛 `disconnected`，其余一律抛 `connected`。
    func testNoNetworkEmitsConnectedAndDisconnected() {
        var events: [String] = []
        let network = UPNoNetwork(status: .wifi)
            .onConnected { events.append("connected") }
            .onDisconnected { events.append("disconnected") }

        network.update(.offline)
        XCTAssertEqual(events, ["disconnected"])

        network.update(.cellular)
        XCTAssertEqual(events, ["disconnected", "connected"])

        // 照抄上游：unknown 不等于 'none'，因此也走 connected 分支。
        network.update(.unknown)
        XCTAssertEqual(events, ["disconnected", "connected", "connected"])
    }

    /// 上游 `retry()`：重新取网络类型 → emitEvent → toast → 抛 `retry`。
    func testNoNetworkRetryEmitsStatusThenRetry() {
        var order: [String] = []
        let network = UPNoNetwork(status: .offline)
            .onConnected { order.append("connected") }
            .onDisconnected { order.append("disconnected") }
            .onRetry { order.append("retry") }

        network.retry()
        XCTAssertEqual(order, ["disconnected", "retry"])

        network.retry(status: .wifi)
        XCTAssertEqual(order, ["disconnected", "retry", "connected", "retry"])
        XCTAssertFalse(network.isOffline)

        XCTAssertEqual(UPConfig.noNetwork.retryText, "重试")
        XCTAssertEqual(UPConfig.noNetwork.settingsText, "设置")
        XCTAssertEqual(UPConfig.noNetwork.pleaseCheckText, "请检查网络，或前往")
        XCTAssertEqual(UPConfig.noNetwork.connectToast, "网络已连接")
        XCTAssertEqual(UPConfig.noNetwork.disconnectToast, "无网络连接")
    }

    /// 上游 `openSettings()`：联网时直接 return，只有断网才跳设置页。
    func testNoNetworkOpenSettingsOnlyWhenOffline() {
        var opened = 0
        let network = UPNoNetwork(status: .wifi).onOpenSettings { opened += 1 }
        network.openSettings()
        XCTAssertEqual(opened, 0)

        network.update(.offline)
        network.openSettings()
        XCTAssertEqual(opened, 1)
    }

    func testCityLocateUsesInjectedProviderAndEmitsLocation() async {
        let location = UPLocationCoordinate(latitude: 31.2304, longitude: 121.4737)
        let city = UPCityLocate(provider: UPStaticLocationProvider(result: .success(location)))
        let result = await city.locate()
        XCTAssertEqual(result, location)
        XCTAssertEqual(city.lastLocation, location)
    }

    /// `u-city-locate.vue` 的内联 props：`indexList: ['🔥']`、`cityList` 五个热门城市、
    /// `locationType: 'wgs84'`、`currentCity: ''`、`nameKey: 'name'`。
    func testCityLocatePropDefaultsMatchUpstream() {
        let city = UPCityLocate()
        XCTAssertEqual(city.indexList, ["🔥"])
        XCTAssertEqual(city.cityList.count, 1)
        XCTAssertEqual(city.cityList[0].map(\.name), ["北京", "上海", "广州", "深圳", "杭州"])
        XCTAssertEqual(city.cityList[0].map(\.value), ["beijing", "shanghai", "guangzhou", "shenzhen", "hangzhou"])
        XCTAssertEqual(city.locationType, "wgs84")
        XCTAssertEqual(city.currentCity, "")
        XCTAssertEqual(city.nameKey, "name")
        // 上游 `data.locationCity` 初值是「定位中....」。
        XCTAssertEqual(city.locationCity, "定位中....")
    }

    /// 上游 `location-success` 会带上反查到的城市名；失败时把文案换成提示。
    func testCityLocateGeocodesCityAndReportsFailureText() async {
        let shanghai = UPLocationCoordinate(latitude: 31.2304, longitude: 121.4737)
        var results: [UPCityLocationResult] = []
        let city = UPCityLocate(provider: UPStaticLocationProvider(result: .success(shanghai)),
                                geocoder: UPStaticCityGeocoder(city: "上海市"))
            .onLocationSuccess { results.append($0) }
        _ = await city.locate()
        XCTAssertEqual(city.locationCity, "上海市")
        XCTAssertEqual(results.map(\.locationCity), ["上海市"])
        XCTAssertEqual(results.first?.coordinate, shanghai)

        let failed = UPCityLocate(provider: UPStaticLocationProvider(result: .failure(.denied)))
        _ = await failed.locate()
        XCTAssertEqual(failed.locationCity, "定位失败，请点击重试。")
    }

    /// 上游 `currentCity` 由外部指定时直接覆盖显示。
    func testCityLocateCurrentCityOverridesLocationCity() {
        XCTAssertEqual(UPCityLocate(currentCity: "南京").locationCity, "南京")
    }

    /// 上游 `selectedCity(city)`：写进当前城市并抛 `select-city`。
    func testCityLocateSelectEmitsSelection() {
        var selections: [UPCitySelection] = []
        let city = UPCityLocate().onSelectCity { selections.append($0) }
        city.select(UPCity(name: "苏州", value: "suzhou"))
        XCTAssertEqual(city.locationCity, "苏州")
        XCTAssertEqual(selections.map(\.locationCity), ["苏州"])
        XCTAssertEqual(selections.first?.city.value, "suzhou")
    }

    /// 上游 `cityList` 是对象数组，`nameKey` 指定显示字段。
    func testCityReadsNameKeyFromObjects() {
        let cities = UPCity.cities([["label": "北京", "value": "bj"], ["other": "x"]], nameKey: "label")
        XCTAssertEqual(cities.map(\.name), ["北京"])
        XCTAssertEqual(cities.map(\.value), ["bj"])
        // 只有名字时 value 回落成名字。
        XCTAssertEqual(UPCity(name: "厦门").value, "厦门")
    }

    func testCityLocateReportsProviderFailure() async {
        var message = ""
        let city = UPCityLocate(provider: UPStaticLocationProvider(result: .failure(UPLocationError.denied)))
            .onError { message = $0.localizedDescription }
        let result = await city.locate()
        XCTAssertNil(result)
        XCTAssertEqual(message, "定位权限被拒绝")
    }
}
