import Foundation
import Testing
@testable import BreadPartnersSDK

@Suite(.serialized)
struct PlacementApiExtensionTests {

	private final class StubURLProtocol: URLProtocol {
		static var responseData = Data()
		static var responseStatusCode = 200
		static var responseContentType = "application/json"

		override class func canInit(with request: URLRequest) -> Bool {
			true
		}

		override class func canonicalRequest(for request: URLRequest) -> URLRequest {
			request
		}

		override func startLoading() {
			guard let url = request.url else {
				client?.urlProtocol(self, didFailWithError: URLError(.badURL))
				return
			}

			let response = HTTPURLResponse(
				url: url,
				statusCode: Self.responseStatusCode,
				httpVersion: nil,
				headerFields: ["Content-Type": Self.responseContentType]
			)!
			client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
			client?.urlProtocol(self, didLoad: Self.responseData)
			client?.urlProtocolDidFinishLoading(self)
		}

		override func stopLoading() {}
	}

	private final class EventBox: @unchecked Sendable {
		var event: BreadPartnerEvents?
	}

	@Test("fetchBrandConfig stores a valid brand configuration")
	@MainActor
	func fetchBrandConfigStoresConfiguration() async {
		await withStubbedResponse(data: Data("{\"config\":{}}".utf8)) {
			let sdk = BreadPartnersSDK()
			sdk.integrationKey = "brand-123"

			await sdk.fetchBrandConfig(logger: Logger())

			#expect(sdk.brandConfiguration != nil)
		}
	}

	@Test("fetchBrandConfig leaves configuration unset after an API failure")
	@MainActor
	func fetchBrandConfigHandlesAPIError() async {
		await withStubbedResponse(
			data: Data("{\"message\":\"unavailable\"}".utf8),
			statusCode: 500
		) {
			let sdk = BreadPartnersSDK()

			await sdk.fetchBrandConfig(logger: Logger())

			#expect(sdk.brandConfiguration == nil)
		}
	}

	@Test("fetchPlacementData forwards a successful response to the renderer")
	func fetchPlacementDataForwardsResponse() async {
		let eventBox = EventBox()

		await withStubbedResponse(data: Data("{}".utf8)) {
			await BreadPartnersSDK().fetchPlacementData(
				merchantConfiguration: MerchantConfiguration(),
				placementsConfiguration: PlacementConfiguration(),
				logger: Logger(),
				callback: { event in
					eventBox.event = event
				}
			)
		}

		expectSDKError(eventBox.event, message: Constants.noTextPlacementError)
	}

	@Test("fetchPlacementData reports generic API failures")
	func fetchPlacementDataReportsAPIError() async {
		let eventBox = EventBox()

		await withStubbedResponse(
			data: Data("{\"message\":\"service unavailable\"}".utf8),
			statusCode: 503
		) {
			await BreadPartnersSDK().fetchPlacementData(
				merchantConfiguration: MerchantConfiguration(),
				placementsConfiguration: PlacementConfiguration(),
				logger: Logger(),
				callback: { event in
					eventBox.event = event
				}
			)
		}

		expectSDKError(eventBox.event, message: "Error: service unavailable")
	}

	@Test("fetchPlacementData emits a challenge popup for Incapsula responses")
	@MainActor
	func fetchPlacementDataHandlesIncapsulaChallenge() async {
		let eventBox = EventBox()
		let challengeHTML = "<html>incap_ses challenge</html>"

		await withStubbedResponse(
			data: Data(challengeHTML.utf8),
			contentType: "text/html"
		) {
			await BreadPartnersSDK().fetchPlacementData(
				merchantConfiguration: MerchantConfiguration(),
				placementsConfiguration: PlacementConfiguration(),
				logger: Logger(),
				callback: { event in
					eventBox.event = event
				}
			)
		}

		guard case let .renderPopupView(view)? = eventBox.event else {
			Issue.record("Expected an Incapsula challenge popup")
			return
		}

		#expect(view is ChallengeController)
	}

	@Test("handlePlacementResponse reports missing text placement content")
	func handlePlacementResponseReportsMissingTextContent() async {
		let eventBox = EventBox()

		await BreadPartnersSDK().handlePlacementResponse(
			Data("{}".utf8),
			merchantConfiguration: MerchantConfiguration(),
			placementsConfiguration: PlacementConfiguration(),
			logger: Logger(),
			callback: { event in
				eventBox.event = event
			}
		)

		expectSDKError(eventBox.event, message: Constants.noTextPlacementError)
	}

	@Test("handlePlacementResponse reports missing popup content for open experience")
	func handlePlacementResponseReportsMissingPopupContent() async {
		let eventBox = EventBox()

		await BreadPartnersSDK().handlePlacementResponse(
			Data("{}".utf8),
			merchantConfiguration: MerchantConfiguration(),
			placementsConfiguration: PlacementConfiguration(),
			openPlacementExperience: true,
			logger: Logger(),
			callback: { event in
				eventBox.event = event
			}
		)

		expectSDKError(eventBox.event, message: Constants.popupPlacementParsingError)
	}

	@Test("handlePlacementResponse rejects a response without an overlay template")
	func handlePlacementResponseRejectsMissingOverlayTemplate() async {
		let response = """
		{
		  "placements": [{ "id": "placement-1" }],
		  "placementContent": [{
			"metadata": { "templateId": "text-placement" },
			"contentData": { "htmlContent": "<p>Text placement</p>" }
		  }]
		}
		"""
		let eventBox = EventBox()

		await BreadPartnersSDK().handlePlacementResponse(
			Data(response.utf8),
			merchantConfiguration: MerchantConfiguration(),
			placementsConfiguration: PlacementConfiguration(),
			openPlacementExperience: true,
			logger: Logger(),
			callback: { event in
				eventBox.event = event
			}
		)

		expectSDKError(eventBox.event, message: Constants.popupPlacementParsingError)
	}

	@Test("handlePlacementResponse reports malformed JSON")
	func handlePlacementResponseReportsMalformedJSON() async {
		let eventBox = EventBox()

		await BreadPartnersSDK().handlePlacementResponse(
			Data("not-json".utf8),
			merchantConfiguration: MerchantConfiguration(),
			placementsConfiguration: PlacementConfiguration(),
			logger: Logger(),
			callback: { event in
				eventBox.event = event
			}
		)

		guard case let .sdkError(error)? = eventBox.event else {
			Issue.record("Expected an SDK error for malformed placement JSON")
			return
		}

		#expect(error.localizedDescription.hasPrefix("Error:"))
	}

	private func expectSDKError(_ event: BreadPartnerEvents?, message: String) {
		guard case let .sdkError(error)? = event else {
			Issue.record("Expected an SDK error event")
			return
		}

		#expect(error.localizedDescription == message)
	}

	private func withStubbedResponse(
		data: Data,
		statusCode: Int = 200,
		contentType: String = "application/json",
		operation: () async -> Void
	) async {
		StubURLProtocol.responseData = data
		StubURLProtocol.responseStatusCode = statusCode
		StubURLProtocol.responseContentType = contentType
		URLProtocol.registerClass(StubURLProtocol.self)
		defer {
			URLProtocol.unregisterClass(StubURLProtocol.self)
		}
		await operation()
	}
}
