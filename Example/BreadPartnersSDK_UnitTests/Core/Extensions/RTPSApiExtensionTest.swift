import Testing
import Foundation
@testable import BreadPartnersSDK

@Suite(.serialized)
@MainActor
struct RTPSApiExtensionTests {

	private final class EventBox: @unchecked Sendable {
		var event: BreadPartnerEvents?
	}

	@Test("rtpsCall reports missing prescreen customer data")
	func rtpsCallReportsMissingCustomerData() async {
		let sdk = BreadPartnersSDK()
		let eventBox = EventBox()

		await sdk.rtpsCall(
			merchantConfiguration: MerchantConfiguration(),
			placementsConfiguration: PlacementConfiguration(
				rtpsData: RTPSData(prescreenId: nil)
			),
			logger: Logger()
		) { event in
			eventBox.event = event
		}

		expectSDKError(
			eventBox.event,
			message: Constants.prescreenRequiredFieldsError
		)
	}

	@Test("rtpsCall validates every required prescreen field")
	func rtpsCallValidatesRequiredFields() async {
		let incompleteBuyer = BreadPartnersBuyer(
			givenName: "Ava",
			familyName: "Miller",
			billingAddress: BreadPartnersAddress(
				address1: "100 Main St",
				country: "US",
				locality: "Columbus",
				region: "OH",
				postalCode: nil
			)
		)
		let eventBox = EventBox()

		await BreadPartnersSDK().rtpsCall(
			merchantConfiguration: MerchantConfiguration(buyer: incompleteBuyer),
			placementsConfiguration: PlacementConfiguration(
				rtpsData: RTPSData(prescreenId: nil)
			),
			logger: Logger()
		) { event in
			eventBox.event = event
		}

		expectSDKError(
			eventBox.event,
			message: Constants.prescreenRequiredFieldsError
		)
	}

	@Test("rtpsCall performs virtual lookup without reCAPTCHA")
	func rtpsCallPerformsVirtualLookup() async {
		let data = RTPSData(prescreenId: 777)
		let configuration = PlacementConfiguration(rtpsData: data)
		let eventBox = EventBox()

		await TestNetworkCoordinator.shared.withResponse(
			data: Data("{\"returnCode\":\"10\",\"prescreenId\":777}".utf8)
		) {
			await BreadPartnersSDK().rtpsCall(
				merchantConfiguration: MerchantConfiguration(),
				placementsConfiguration: configuration,
				logger: Logger(),
				callback: { event in eventBox.event = event }
			)
		}

		#expect(data.prescreenId == 777)
		#expect(eventBox.event == nil)
	}

	@Test("rtpsCall reports virtual lookup API errors")
	func rtpsCallReportsVirtualLookupError() async {
		let eventBox = EventBox()

		await TestNetworkCoordinator.shared.withResponse(
			data: Data("{\"message\":\"lookup failed\"}".utf8),
			statusCode: 503
		) {
			await BreadPartnersSDK().rtpsCall(
				merchantConfiguration: MerchantConfiguration(),
				placementsConfiguration: PlacementConfiguration(
					rtpsData: RTPSData(prescreenId: 777)
				),
				logger: Logger(),
				callback: { event in eventBox.event = event }
			)
		}

		expectSDKError(eventBox.event, message: "Error: lookup failed")
	}

	@Test("rtpsCall reports reCAPTCHA failures for complete prescreen data")
	func rtpsCallReportsRecaptchaFailure() async {
		let buyer = BreadPartnersBuyer(
			givenName: "Ava",
			familyName: "Miller",
			billingAddress: BreadPartnersAddress(
				address1: "100 Main St",
				country: "US",
				locality: "Columbus",
				region: "OH",
				postalCode: "43085"
			)
		)
		let eventBox = EventBox()

		await BreadPartnersSDK().rtpsCall(
			merchantConfiguration: MerchantConfiguration(buyer: buyer),
			placementsConfiguration: PlacementConfiguration(
				rtpsData: RTPSData(prescreenId: nil)
			),
			logger: Logger(),
			callback: { event in eventBox.event = event }
		)

		guard case let .sdkError(error)? = eventBox.event else {
			Issue.record("Expected a reCAPTCHA failure")
			return
		}
		#expect(!error.localizedDescription.isEmpty)
	}

	@Test("rtpsCall batch flow forwards placement parsing errors")
	func rtpsCallBatchFlowForwardsPlacementError() async {
		let eventBox = EventBox()

		await TestNetworkCoordinator.shared.withResponse(data: Data("{}".utf8)) {
			await BreadPartnersSDK().rtpsCall(
				merchantConfiguration: MerchantConfiguration(),
				placementsConfiguration: PlacementConfiguration(
					rtpsData: RTPSData(customerAcceptedOffer: true)
				),
				logger: Logger(),
				callback: { event in eventBox.event = event }
			)
		}

		expectSDKError(eventBox.event, message: Constants.popupPlacementParsingError)
	}

	@Test("fetchRTPSData handles the batch URL branch")
	func fetchRTPSDataHandlesBatchBranch() async {
		let eventBox = EventBox()

		await TestNetworkCoordinator.shared.withResponse(data: Data("{}".utf8)) {
			await BreadPartnersSDK().fetchRTPSData(
				merchantConfiguration: MerchantConfiguration(),
				placementsConfiguration: PlacementConfiguration(
					rtpsData: RTPSData(customerAcceptedOffer: true)
				),
				logger: Logger(),
				callback: { event in eventBox.event = event }
			)
		}

		expectSDKError(eventBox.event, message: Constants.popupPlacementParsingError)
	}

	@Test("fetchRTPSData handles the regular RTPS URL branch")
	func fetchRTPSDataHandlesRegularBranch() async {
		let eventBox = EventBox()

		await TestNetworkCoordinator.shared.withResponse(data: Data("{}".utf8)) {
			await BreadPartnersSDK().fetchRTPSData(
				merchantConfiguration: MerchantConfiguration(),
				placementsConfiguration: PlacementConfiguration(
					rtpsData: RTPSData(prescreenId: 123)
				),
				logger: Logger(),
				callback: { event in eventBox.event = event }
			)
		}

		expectSDKError(eventBox.event, message: Constants.popupPlacementParsingError)
	}

	@Test("fetchRTPSData reports API failures")
	func fetchRTPSDataReportsAPIError() async {
		let eventBox = EventBox()

		await TestNetworkCoordinator.shared.withResponse(
			data: Data("{\"message\":\"placement service unavailable\"}".utf8),
			statusCode: 503
		) {
			await BreadPartnersSDK().fetchRTPSData(
				merchantConfiguration: MerchantConfiguration(),
				placementsConfiguration: PlacementConfiguration(
					rtpsData: RTPSData(prescreenId: 123)
				),
				logger: Logger(),
				callback: { event in eventBox.event = event }
			)
		}

		expectSDKError(eventBox.event, message: "Error: placement service unavailable")
	}

	@Test("rtpsCall renders a challenge popup for Incapsula responses")
	func rtpsCallHandlesIncapsulaChallenge() async {
		let eventBox = EventBox()

		await TestNetworkCoordinator.shared.withResponse(
			data: Data("<html>incap_ses challenge</html>".utf8),
			contentType: "text/html"
		) {
			await BreadPartnersSDK().rtpsCall(
				merchantConfiguration: MerchantConfiguration(),
				placementsConfiguration: PlacementConfiguration(
					rtpsData: RTPSData(prescreenId: 777)
				),
				logger: Logger(),
				callback: { event in eventBox.event = event }
			)
		}

		guard case let .renderPopupView(view)? = eventBox.event else {
			Issue.record("Expected an Incapsula challenge popup")
			return
		}
		#expect(view is ChallengeController)
	}

	@Test("handleRTPSPlacementResponse rejects an empty placement response")
	func handleRTPSPlacementResponseRejectsEmptyPlacements() async {
		let eventBox = EventBox()

		await BreadPartnersSDK().handleRTPSPlacementResponse(
			merchantConfiguration: MerchantConfiguration(),
			placementsConfiguration: PlacementConfiguration(),
			logger: Logger(),
			callback: { event in
				eventBox.event = event
			},
			AnySendable(value: Data("{}".utf8))
		)

		expectSDKError(
			eventBox.event,
			message: Constants.popupPlacementParsingError
		)
	}

	@Test("handleRTPSPlacementResponse reports malformed JSON")
	func handleRTPSPlacementResponseReportsMalformedJSON() async {
		let eventBox = EventBox()

		await BreadPartnersSDK().handleRTPSPlacementResponse(
			merchantConfiguration: MerchantConfiguration(),
			placementsConfiguration: PlacementConfiguration(),
			logger: Logger(),
			callback: { event in
				eventBox.event = event
			},
			AnySendable(value: "not-json")
		)

		guard case let .sdkError(error)? = eventBox.event else {
			Issue.record("Expected an SDK error for malformed placement JSON")
			return
		}

		#expect(error.localizedDescription.hasPrefix("Error:"))
	}

	@Test("handleRTPSPlacementResponse rejects missing overlay content")
	func handleRTPSPlacementResponseRejectsMissingOverlay() async {
		let eventBox = EventBox()
		let response = """
		{
		  "placements": [{"id":"placement-1"}],
		  "placementContent": [{"metadata":{"templateId":"text"}}]
		}
		"""

		await BreadPartnersSDK().handleRTPSPlacementResponse(
			merchantConfiguration: MerchantConfiguration(),
			placementsConfiguration: PlacementConfiguration(),
			logger: Logger(),
			callback: { event in eventBox.event = event },
			AnySendable(value: Data(response.utf8))
		)

		expectSDKError(eventBox.event, message: Constants.popupPlacementParsingError)
	}

	private func expectSDKError(_ event: BreadPartnerEvents?, message: String) {
		guard case let .sdkError(error)? = event else {
			Issue.record("Expected an SDK error event")
			return
		}

		#expect(error.localizedDescription == message)
	}
}

