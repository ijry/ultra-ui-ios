import Foundation
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
public final class UPCityLocate: View {
    public let provider: any UPLocationProvider
    public private(set) var lastLocation: UPLocationCoordinate?
    private var onSuccessHandler: ((UPLocationCoordinate) -> Void)?
    private var onErrorHandler: ((UPLocationError) -> Void)?

    public init(provider: any UPLocationProvider = UPStaticLocationProvider(result: .failure(.unavailable)),
                onSuccess: ((UPLocationCoordinate) -> Void)? = nil,
                onError: ((UPLocationError) -> Void)? = nil) {
        self.provider = provider
        self.onSuccessHandler = onSuccess
        self.onErrorHandler = onError
    }

    public func onSuccess(_ action: @escaping (UPLocationCoordinate) -> Void) -> UPCityLocate { onSuccessHandler = action; return self }
    public func onError(_ action: @escaping (UPLocationError) -> Void) -> UPCityLocate { onErrorHandler = action; return self }

    @discardableResult
    public func locate() async -> UPLocationCoordinate? {
        switch await provider.requestLocation() {
        case let .success(location):
            lastLocation = location
            onSuccessHandler?(location)
            return location
        case let .failure(error):
            onErrorHandler?(error)
            return nil
        }
    }

    public var body: some View {
        Button("Locate City") { Task { _ = await self.locate() } }
    }
}

public extension UPLocationError {
    var localizedDescription: String {
        switch self {
        case .denied: return "Location permission denied"
        case .unavailable: return "Location unavailable"
        case let .failed(message): return message
        }
    }
}
