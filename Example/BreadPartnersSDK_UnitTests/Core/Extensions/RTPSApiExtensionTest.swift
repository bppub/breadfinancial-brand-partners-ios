import Testing
@testable import BreadPartnersSDK

@Suite(.serialized)
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

	private func expectSDKError(_ event: BreadPartnerEvents?, message: String) {
		guard case let .sdkError(error)? = event else {
			Issue.record("Expected an SDK error event")
			return
		}

		#expect(error.localizedDescription == message)
	}
}

