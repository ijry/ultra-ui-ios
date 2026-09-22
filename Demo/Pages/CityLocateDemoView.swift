import SwiftUI
import UltraUI

/// 对应上游 `/pages/componentsD/cityLocate/cityLocate`。
@MainActor
struct CityLocateDemoView: View {
    /// 上游同页定位成功后把 currentCity 改成「南京」。
    private static let nanjing = UPLocationCoordinate(latitude: 32.0603, longitude: 118.7969)

    private static let hotCities = [
        UPCity(name: "北京", value: "beijing"),
        UPCity(name: "上海", value: "shanghai"),
        UPCity(name: "广州", value: "guangzhou"),
        UPCity(name: "深圳", value: "shenzhen"),
        UPCity(name: "杭州", value: "hangzhou")
    ]

    private static let allCities = [
        UPCity(name: "南京", value: "nanjing"),
        UPCity(name: "苏州", value: "suzhou"),
        UPCity(name: "无锡", value: "wuxi"),
        UPCity(name: "厦门", value: "xiamen"),
        UPCity(name: "成都", value: "chengdu")
    ]

    @State private var eventLog = "尚未定位"
    @State private var selectedCity = ""

    var body: some View {
        DemoPage {
            DemoSection("基础用法") {
                UPCityLocate(provider: UPStaticLocationProvider(result: .success(Self.nanjing)),
                             geocoder: UPStaticCityGeocoder(city: "南京市"),
                             indexList: ["🔥", "所有城市"],
                             cityList: [Self.hotCities, Self.allCities])
                    .onLocationSuccess { result in
                        eventLog = "location-success：\(result.locationCity)"
                            + "（\(String(format: "%.4f", result.coordinate.latitude)), "
                            + "\(String(format: "%.4f", result.coordinate.longitude))）"
                    }
                    .onSelectCity { selection in
                        selectedCity = selection.locationCity
                        eventLog = "select-city：\(selection.locationCity)"
                    }
                    .frame(height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                tip("最近事件：\(eventLog)")
                tip("已选城市：\(selectedCity.isEmpty ? "无" : selectedCity)")
                tip("第 0 组按热门城市横排，其余按索引分组竖排；点顶部当前城市可重新定位。")
            }

            DemoSection("定位失败") {
                UPCityLocate(provider: UPStaticLocationProvider(result: .failure(.denied)),
                             cityList: [Self.hotCities])
                    .onError { eventLog = "error：\($0.localizedDescription)" }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                tip("失败时当前城市文案换成「定位失败，请点击重试。」，与上游 up.cityLocate.fail 一致。")
            }

            DemoSection("外部指定当前城市") {
                UPCityLocate(cityList: [Self.hotCities], currentCity: "南京")
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                tip("currentCity 非空时直接覆盖显示，对应上游 watch.currentCity。")
            }

            DemoSection("当前原生范围") {
                Text("原生 UPCityLocate 已覆盖上游 5 个 prop：indexList / cityList / locationType / currentCity / nameKey，事件为 onLocationSuccess((UPCityLocationResult) -> Void) / onSelectCity((UPCitySelection) -> Void) 外加原生的 onSuccess / onError，方法 locate() / select(_:)，整页用 UPIndexList 承载（热门城市横排、其余分组竖排、顶部当前城市可点重定位）。定位拆成两个可注入协议：UPLocationProvider 取坐标（UPCoreLocationProvider 走 CoreLocation，UPStaticLocationProvider 用于测试与预览），UPCityGeocoder 反查城市名（UPCoreLocationCityGeocoder 走 CLGeocoder，对应上游 getLocation({ geocode: true }) 里的 res.address.city）。locationType 在 iOS 上无对应能力（CoreLocation 固定 WGS-84），只保留取值；定位权限需要宿主在 Info.plist 里声明。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
