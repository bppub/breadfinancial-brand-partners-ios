import Foundation
import Testing
import UIKit
@testable import BreadPartnersSDK

@Suite(.serialized)
struct PopupAPIExtensionTests {

	private final class EventBox: @unchecked Sendable {
		var event: BreadPartnerEvents?
	}

	@MainActor
	private func makeController(callback: @escaping (BreadPartnerEvents) -> Void = { _ in }) -> PopupController {
		let model = PopupPlacementModel(
			overlayType: PlacementOverlayType.singleProductOverlay.rawValue,
			location: "checkout",
			brandLogoUrl: "",
			webViewUrl: "",
			overlayTitle: NSAttributedString(string: "Title"),
			overlaySubtitle: NSAttributedString(string: "Subtitle"),
			overlayContainerBarHeading: NSAttributedString(string: "Heading"),
			bodyHeader: NSAttributedString(string: "Body"),
			primaryActionButtonAttributes: PrimaryActionButtonModel(
				dataOverlayType: PlacementOverlayType.singleProductOverlay.rawValue,
				dataContentFetch: "content-1",
				dataActionTarget: "primary",
				dataActionType: "SHOW_OVERLAY",
				dataActionContentId: "action-1",
				dataLocation: "footer",
				buttonText: "Continue"
			),
			dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(bodyDiv: [:]),
			disclosure: NSAttributedString(string: "Disclosure"),
			disclosureHTML: ""
		)
		let controller = PopupController(
			integrationKey: "brand-123",
			merchantConfiguration: MerchantConfiguration(storeNumber: "store-123"),
			placementConfiguration: PlacementConfiguration(),
			popupModel: model,
			overlayType: .singleProductOverlay,
			brandConfiguration: nil,
			logger: Logger(),
			callback: callback
		)
		controller.view = UIView()
		return controller
	}

	private var popupHTML: String {
		"""
		<div data-overlay-metadata data-overlay-type="EMBEDDED_OVERLAY"></div>
		<iframe src="https://example.com/embedded"></iframe>
		<div class="epjs-css-overlay-title">Title</div>
		<div class="epjs-css-overlay-subtitle">Subtitle</div>
		<div class="epjs-css-overlay-body-title-bar">Heading</div>
		<div class="epjs-css-overlay-header">Header</div>
		<div class="epjs-css-overlay-disclosures">Disclosure</div>
		<div class="epjs-css-modal-footer" data-overlay-type="EMBEDDED_OVERLAY"></div>
		<button class="action-button" data-content-fetch="true" data-action-target="modal" data-action-type="SHOW_OVERLAY" data-action-content-id="cta-1" data-location="footer"><span>Continue</span></button>
		<div class="epjs-css-overlay-body-content"></div>
		"""
	}

	@Test("fetchWebViewPlacement stores a decoded popup model")
	@MainActor
	func fetchWebViewPlacementStoresModel() async {
		let response = "{\"placementContent\":[{\"contentData\":{\"htmlContent\":\(jsonString(popupHTML))}}]}"

		await TestNetworkCoordinator.shared.withResponse(data: Data(response.utf8)) {
			let controller = makeController()
			await controller.fetchWebViewPlacement()

			guard let placementModel = controller.webViewPlacementModel else {
				Issue.record("Expected a decoded popup placement model")
				return
			}

			#expect(placementModel.webViewUrl == "https://example.com/embedded")
			#expect(placementModel.primaryActionButtonAttributes?.buttonText == "Continue")
		}
	}

	@Test("fetchWebViewPlacement reports missing popup content")
	@MainActor
	func fetchWebViewPlacementReportsMissingContent() async {
		let eventBox = EventBox()

		await TestNetworkCoordinator.shared.withResponse(data: Data("{}".utf8)) {
			let controller = makeController { event in eventBox.event = event }
			await controller.fetchWebViewPlacement()
		}

		expectSDKError(eventBox.event, message: Constants.popupPlacementParsingError)
	}

	@Test("fetchWebViewPlacement reports malformed response data")
	@MainActor
	func fetchWebViewPlacementReportsMalformedResponse() async {
		let eventBox = EventBox()

		await TestNetworkCoordinator.shared.withResponse(data: Data("not-json".utf8)) {
			let controller = makeController { event in eventBox.event = event }
			await controller.fetchWebViewPlacement()
		}

		expectSDKErrorPrefix(eventBox.event, prefix: "Error:")
	}

	@Test("fetchWebViewPlacement reports API failures")
	@MainActor
	func fetchWebViewPlacementReportsAPIError() async {
		let eventBox = EventBox()

		await TestNetworkCoordinator.shared.withResponse(
			data: Data("{\"message\":\"service unavailable\"}".utf8),
			statusCode: 503
		) {
			let controller = makeController { event in eventBox.event = event }
			await controller.fetchWebViewPlacement()
		}

		expectSDKError(eventBox.event, message: "Error: service unavailable")
	}

	private func jsonString(_ value: String) -> String {
		let data = try! JSONSerialization.data(withJSONObject: [value])
		let encoded = String(decoding: data, as: UTF8.self)
		return String(encoded.dropFirst().dropLast())
	}

	private func expectSDKError(_ event: BreadPartnerEvents?, message: String) {
		guard case let .sdkError(error)? = event else {
			Issue.record("Expected an SDK error event")
			return
		}
		#expect(error.localizedDescription == message)
	}

	private func expectSDKErrorPrefix(_ event: BreadPartnerEvents?, prefix: String) {
		guard case let .sdkError(error)? = event else {
			Issue.record("Expected an SDK error event")
			return
		}
		#expect(error.localizedDescription.hasPrefix(prefix))
	}
}
