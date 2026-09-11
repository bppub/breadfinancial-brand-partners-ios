import Foundation
import Testing
@testable import BreadPartnersSDK

@Suite(.serialized)
struct AnalyticsManagerTests {

	private func makePlacementResponse() throws -> PlacementsResponse {
		try JSONDecoder().decode(
			PlacementsResponse.self,
			from: Data("""
			{
			  "placements": [{
				"id": "placement-1",
				"renderContext": {
				  "LOCATION": "checkout",
				  "SDK_TID": "tracking-1"
				}
			  }],
			  "placementContent": [{
				"id": "content-1",
				"contentType": "HTML",
				"metadata": {
				  "placementId": "placement-1",
				  "productType": "CARD",
				  "messageId": "message-1",
				  "templateId": "template-1"
				}
			  }]
			}
			""".utf8)
		)
	}
    
    

    
    @Test("should store the logger instance passed to the initializer")
    func analyticsManagerInit() {
        let logger = Logger()
        let manager = AnalyticsManager(logger: logger)

        #expect(manager.logger === logger)
    }

	@Test("setApiKey stores the analytics API key")
	func setApiKeyStoresValue() {
		let manager = AnalyticsManager(logger: Logger())
		manager.setApiKey("analytics-key")

		#expect(mirrorValue(manager, key: "apiKey") == "analytics-key")
	}

	@Test("sendViewPlacement completes with placement context")
	func sendViewPlacementSendsPayload() async throws {
		let response = try makePlacementResponse()
		let manager = AnalyticsManager(logger: Logger())
		manager.setApiKey("analytics-key")

		let request = await TestNetworkCoordinator.shared.withRequest {
			await manager.sendViewPlacement(placementResponse: response)
		}

		expectAnalyticsRequest(
			request,
			path: "/ep/v1/view-placement"
		)
	}

	@Test("sendClickPlacement sends a click payload to the click endpoint")
	func sendClickPlacementSendsClickPayload() async throws {
		let response = try makePlacementResponse()
		let manager = AnalyticsManager(logger: Logger())

		let request = await TestNetworkCoordinator.shared.withRequest {
			await manager.sendClickPlacement(placementResponse: response)
		}

		expectAnalyticsRequest(
			request,
			path: "/ep/v1/click-placement"
		)
	}

	@Test("analytics methods tolerate an empty placement response")
	func analyticsMethodsHandleEmptyResponse() async {
		let emptyResponse = try! JSONDecoder().decode(
			PlacementsResponse.self,
			from: Data("{}".utf8)
		)
		let manager = AnalyticsManager(logger: Logger())
		manager.setApiKey("analytics-key")

		let request = await TestNetworkCoordinator.shared.withRequest {
			await manager.sendViewPlacement(placementResponse: emptyResponse)
		}

		expectAnalyticsRequest(
			request,
			path: "/ep/v1/view-placement"
		)
	}

	@Test("analytics requests ignore API failures")
	func analyticsRequestsIgnoreAPIFailures() async throws {
		let response = try makePlacementResponse()
		let manager = AnalyticsManager(logger: Logger())

		await TestNetworkCoordinator.shared.withResponse(
			data: Data("{\"message\":\"unavailable\"}".utf8),
			statusCode: 503
		) {
			await manager.sendViewPlacement(placementResponse: response)
		}
	}

	private func expectAnalyticsRequest(
		_ request: URLRequest?,
		path: String
	) {
		guard let request else {
			Issue.record("Expected an intercepted analytics request")
			return
		}

		#expect(request.httpMethod == "OPTIONS")
		#expect(request.url?.path == path)
		#expect(request.value(forHTTPHeaderField: Constants.headerAuthorityKey) == Constants.headerAuthorityValue)
		#expect(request.value(forHTTPHeaderField: Constants.headerAcceptKey) == Constants.headerAcceptValue)
		#expect(request.value(forHTTPHeaderField: Constants.headerAccessControlRequestMethodKey) == Constants.headerAccessControlRequestMethodValue)
	}

	private func mirrorValue<T>(_ object: Any, key: String) -> T? {
		var mirror: Mirror? = Mirror(reflecting: object)
		while let currentMirror = mirror {
			if let value = currentMirror.children.first(where: { $0.label == key })?.value as? T {
				return value
			}
			mirror = currentMirror.superclassMirror
		}
		return nil
	}
}
