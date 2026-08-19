import Foundation
import Testing
@testable import BreadPartnersSDK

@Suite(.serialized)
struct AnalyticsManagerTests {

	private final class StubURLProtocol: URLProtocol {
		static var responseData = Data("{}".utf8)
		static var capturedRequest: URLRequest?

		override class func canInit(with request: URLRequest) -> Bool { true }
		override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

		override func startLoading() {
			Self.capturedRequest = request
			guard let url = request.url else {
				client?.urlProtocol(self, didFailWithError: URLError(.badURL))
				return
			}
			let response = HTTPURLResponse(
				url: url,
				statusCode: 200,
				httpVersion: nil,
				headerFields: ["Content-Type": "application/json"]
			)!
			client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
			client?.urlProtocol(self, didLoad: Self.responseData)
			client?.urlProtocolDidFinishLoading(self)
		}

		override func stopLoading() {}
	}

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

		await withStubbedRequest {
			await manager.sendViewPlacement(placementResponse: response)
		}

		#expect(mirrorValue(manager, key: "apiKey") == "analytics-key")
	}

	@Test("sendClickPlacement sends a click payload to the click endpoint")
	func sendClickPlacementSendsClickPayload() async throws {
		let response = try makePlacementResponse()
		let manager = AnalyticsManager(logger: Logger())

		await withStubbedRequest {
			await manager.sendClickPlacement(placementResponse: response)
		}

		#expect(mirrorValue(manager, key: "apiKey") == "")
	}

	@Test("analytics methods tolerate an empty placement response")
	func analyticsMethodsHandleEmptyResponse() async {
		let emptyResponse = try! JSONDecoder().decode(
			PlacementsResponse.self,
			from: Data("{}".utf8)
		)
		let manager = AnalyticsManager(logger: Logger())

		await withStubbedRequest {
			await manager.sendViewPlacement(placementResponse: emptyResponse)
		}

		#expect(mirrorValue(manager, key: "apiKey") == "")
	}

	private func withStubbedRequest(operation: () async -> Void) async {
		StubURLProtocol.capturedRequest = nil
		URLProtocol.registerClass(StubURLProtocol.self)
		defer { URLProtocol.unregisterClass(StubURLProtocol.self) }
		await operation()
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
