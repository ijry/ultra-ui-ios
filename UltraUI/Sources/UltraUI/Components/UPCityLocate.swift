import Foundation
import Observation
import SwiftUI
#if canImport(CoreLocation)
import CoreLocation
#endif

public struct UPLocationCoordinate: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public init(latitude: Double, longitude: Double) {
        self.latitude = min(max(latitude, -90), 90)
        self.longitude = min(max(longitude, -180), 180)
    }
}

public enum UPLocationError: Error, Equatable, Sendable {
    case denied
    case unavailable
    case failed(String)
}

public protocol UPLocationProvider: Sendable {
    func requestLocation() async -> Result<UPLocationCoordinate, UPLocationError>
}

public struct UPStaticLocationProvider: UPLocationProvider {
    public let result: Result<UPLocationCoordinate, UPLocationError>
    public init(result: Result<UPLocationCoordinate, UPLocationError>) { self.result = result }
    public func requestLocation() async -> Result<UPLocationCoordinate, UPLocationError> { result }
}

#if canImport(CoreLocation)
public final class UPCoreLocationProvider: NSObject, UPLocationProvider, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Result<UPLocationCoordinate, UPLocationError>, Never>?

    public override init() {
        super.init()
        manager.delegate = self
    }

    public func requestLocation() async -> Result<UPLocationCoordinate, UPLocationError> {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        continuation?.resume(returning: .success(UPLocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)))
        continuation = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: .failure(.failed(error.localizedDescription)))
        continuation = nil
    }
}
#endif

@MainActor
@Observable
private final class UPCityLocateState {
    var lastLocation: UPLocationCoordinate?
    /// 对应上游 `data.locationCity`：初值是「定位中....」。
    var locationCity = "定位中...."
}

#if canImport(CoreLocation)
/// 默认的反地理编码实现，等价于上游 `getLocation({ geocode: true })` 里的
/// `res.address.city`。
public struct UPCoreLocationCityGeocoder: UPCityGeocoder {
    public init() {}

    public func city(at coordinate: UPLocationCoordinate) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else { return nil }
        return placemark.locality ?? placemark.administrativeArea
    }
}
#endif

/// Native SwiftUI counterpart of uview-plus `u-city-locate`.
///
/// 上游是「顶部当前城市 + 索引列表选城市」的一整页：挂载即调
/// `uni.getLocation({ geocode: true })` 反查城市名，成功抛 `location-success`、
/// 失败把当前城市文案换成「定位失败，请点击重试。」；点城市抛 `select-city`。
///
/// 原生把定位拆成两个可注入协议：`UPLocationProvider` 取坐标、
/// `UPCityGeocoder` 反查城市名（默认走 CoreLocation）。
@MainActor
public struct UPCityLocate: View {
    public let provider: any UPLocationProvider
    public let geocoder: any UPCityGeocoder
    /// 上游 `indexList`：索引条字母（默认只有一个 `🔥`）。
    public var indexList: [String]
    /// 上游 `cityList`：二维数组，第 0 组按热门城市横排。
    public var cityList: [[UPCity]]
    /// 上游 `locationType`。iOS 的 CoreLocation 固定 WGS-84，保留取值。
    public var locationType: String
    /// 上游 `currentCity`：外部指定当前城市，`watch` 会写进 `locationCity`。
    public var currentCity: String
    public var nameKey: String
    /// 定位入口文字，上游模板用 `up.cityLocate.locateCity`。
    public var locateText: String
    public var lastLocation: UPLocationCoordinate? { state.lastLocation }
    /// 对应上游 `data.locationCity`。
    public var locationCity: String { currentCity.isEmpty ? state.locationCity : currentCity }
    @State private var state: UPCityLocateState
    @Environment(\.upTheme) private var theme
    private var onSuccessHandler: ((UPLocationCoordinate) -> Void)?
    private var onErrorHandler: ((UPLocationError) -> Void)?
    private var onLocationSuccessHandler: ((UPCityLocationResult) -> Void)?
    private var onSelectCityHandler: ((UPCitySelection) -> Void)?

    public init(provider: any UPLocationProvider = UPStaticLocationProvider(result: .failure(.unavailable)),
                geocoder: any UPCityGeocoder = UPStaticCityGeocoder(city: nil),
                indexList: [String] = UPConfig.cityLocate.indexList,
                cityList: [[UPCity]] = UPConfig.cityLocate.cityList,
                locationType: String = UPConfig.cityLocate.locationType,
                currentCity: String = UPConfig.cityLocate.currentCity,
                nameKey: String = UPConfig.cityLocate.nameKey,
                locateText: String = "定位城市",
                onSuccess: ((UPLocationCoordinate) -> Void)? = nil,
                onError: ((UPLocationError) -> Void)? = nil) {
        self.provider = provider
        self.geocoder = geocoder
        self.indexList = indexList
        self.cityList = cityList
        self.locationType = locationType
        self.currentCity = currentCity
        self.nameKey = nameKey
        self.locateText = locateText
        self.onSuccessHandler = onSuccess
        self.onErrorHandler = onError
        self._state = State(initialValue: UPCityLocateState())
    }

    public func onSuccess(_ action: @escaping (UPLocationCoordinate) -> Void) -> UPCityLocate { var copy = self; copy.onSuccessHandler = action; return copy }
    public func onError(_ action: @escaping (UPLocationError) -> Void) -> UPCityLocate { var copy = self; copy.onErrorHandler = action; return copy }

    /// 对应上游 `location-success` 事件。
    public func onLocationSuccess(_ action: @escaping (UPCityLocationResult) -> Void) -> UPCityLocate {
        var copy = self
        copy.onLocationSuccessHandler = action
        return copy
    }

    /// 对应上游 `select-city` 事件。
    public func onSelectCity(_ action: @escaping (UPCitySelection) -> Void) -> UPCityLocate {
        var copy = self
        copy.onSelectCityHandler = action
        return copy
    }

    /// 对应上游 `selectedCity(city)`：写进当前城市并抛 `select-city`。
    public func select(_ city: UPCity) {
        state.locationCity = city.name
        onSelectCityHandler?(UPCitySelection(city: city))
    }

    @discardableResult
    public func locate() async -> UPLocationCoordinate? {
        switch await provider.requestLocation() {
        case let .success(location):
            state.lastLocation = location
            // 上游 `res.address.city` 反查不到时保持原文案。
            if let city = await geocoder.city(at: location) {
                state.locationCity = city
            }
            onSuccessHandler?(location)
            onLocationSuccessHandler?(UPCityLocationResult(coordinate: location,
                                                          locationCity: locationCity))
            return location
        case let .failure(error):
            // 上游 fail 分支把文案换成 `up.cityLocate.fail`。
            state.locationCity = "定位失败，请点击重试。"
            onErrorHandler?(error)
            return nil
        }
    }

    public var body: some View {
        UPIndexList(indexList: indexList) {
            header

            ForEach(Array(cityList.enumerated()), id: \.offset) { groupIndex, group in
                UPIndexItem(index: indexList.indices.contains(groupIndex) ? indexList[groupIndex] : "") {
                    // 上游第 0 组是横排的热门城市，其余是竖排列表。
                    if groupIndex == 0 {
                        hotCities(group)
                    } else {
                        cityRows(group)
                    }
                }
            }
        }
        // 上游 `mounted` 里立刻定位一次。
        .task { _ = await locate() }
    }

    /// 上游 `#header`：定位标题 + 当前城市，点一下重新定位。
    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(locateText)
                .font(.system(size: 13))
                .foregroundStyle(theme.tips)

            Text(locationCity)
                .font(.system(size: 15))
                .foregroundStyle(theme.main)
                .frame(height: 30, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { Task { _ = await locate() } }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }

    private func hotCities(_ group: [UPCity]) -> some View {
        UPAlbumWrapLayout(spacing: 10, lineSpacing: 10) {
            ForEach(group) { city in
                Text(city.name)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.main)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .overlay { Rectangle().strokeBorder(theme.border, lineWidth: 1) }
                    .contentShape(Rectangle())
                    .onTapGesture { select(city) }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }

    private func cityRows(_ group: [UPCity]) -> some View {
        VStack(spacing: 0) {
            ForEach(group) { city in
                VStack(spacing: 0) {
                    Text(city.name)
                        .font(.system(size: 15))
                        .foregroundStyle(theme.main)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture { select(city) }

                    UPLine()
                }
                .padding(.horizontal, 12)
            }
        }
    }
}

public extension UPLocationError {
    var localizedDescription: String {
        switch self {
        case .denied: return "定位权限被拒绝"
        case .unavailable: return "定位服务不可用"
        case let .failed(message): return message
        }
    }
}
