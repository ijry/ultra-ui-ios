import Foundation

/// `cityList` 里的一项。上游是对象数组，`nameKey` 指定显示字段（默认 `name`），
/// 模板里还用到了 `value`。
public struct UPCity: Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var value: String

    public init(name: String, value: String = "") {
        self.name = name
        self.value = value.isEmpty ? name : value
        self.id = self.value
    }

    /// 对应上游 `item1[nameKey]`。
    public init?(object: [String: String], nameKey: String = UPConfig.cityLocate.nameKey) {
        guard let name = object[nameKey] else { return nil }
        self.init(name: name, value: object["value"] ?? name)
    }

    public static func cities(_ objects: [[String: String]],
                              nameKey: String = UPConfig.cityLocate.nameKey) -> [UPCity] {
        objects.compactMap { UPCity(object: $0, nameKey: nameKey) }
    }
}

/// `select-city` 的事件负载，对应上游 `{ locationCity }`。
public struct UPCitySelection: Equatable, Sendable {
    public let city: UPCity
    /// 上游把选中的名字同时写进 `locationCity`。
    public var locationCity: String { city.name }

    public init(city: UPCity) {
        self.city = city
    }
}

/// `location-success` 的事件负载。上游把 `uni.getLocation` 的整个结果连同
/// `locationCity` 一起抛出，原生给出坐标与反查到的城市名。
public struct UPCityLocationResult: Equatable, Sendable {
    public let coordinate: UPLocationCoordinate
    public let locationCity: String

    public init(coordinate: UPLocationCoordinate, locationCity: String) {
        self.coordinate = coordinate
        self.locationCity = locationCity
    }
}

/// 坐标 → 城市名。上游靠 `uni.getLocation({ geocode: true })` 里的
/// `res.address.city`，原生把这一步抽成协议，默认实现走 CoreLocation 的反地理编码。
public protocol UPCityGeocoder: Sendable {
    func city(at coordinate: UPLocationCoordinate) async -> String?
}

/// 固定返回值，供单测与预览使用。
public struct UPStaticCityGeocoder: UPCityGeocoder {
    public let city: String?

    public init(city: String?) {
        self.city = city
    }

    public func city(at coordinate: UPLocationCoordinate) async -> String? { city }
}
