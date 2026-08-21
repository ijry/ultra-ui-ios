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

    func testCityLocateUsesInjectedProviderAndEmitsLocation() async {
        let location = UPLocationCoordinate(latitude: 31.2304, longitude: 121.4737)
        let city = UPCityLocate(provider: UPStaticLocationProvider(result: .success(location)))
        let result = await city.locate()
        XCTAssertEqual(result, location)
        XCTAssertEqual(city.lastLocation, location)
    }

    func testCityLocateReportsProviderFailure() async {
        var message = ""
        let city = UPCityLocate(provider: UPStaticLocationProvider(result: .failure(UPLocationError.denied)))
            .onError { message = $0.localizedDescription }
        let result = await city.locate()
        XCTAssertNil(result)
        XCTAssertEqual(message, "Location permission denied")
    }
}
