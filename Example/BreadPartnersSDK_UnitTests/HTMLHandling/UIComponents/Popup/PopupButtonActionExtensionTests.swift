import Foundation
import Testing
import UIKit
import WebKit
@testable import BreadPartnersSDK

@Suite(.serialized)
struct PopupButtonActionExtensionTests {

	private final class EventBox: @unchecked Sendable {
		var events: [BreadPartnerEvents] = []
	}

	@MainActor
	private func makeController(
		callback: @escaping (BreadPartnerEvents) -> Void = { _ in }
	) -> PopupController {
		let model = PopupPlacementModel(
			overlayType: PlacementOverlayType.embeddedOverlay.rawValue,
			location: "checkout",
			brandLogoUrl: "",
			webViewUrl: "",
			overlayTitle: NSAttributedString(string: "Title"),
			overlaySubtitle: NSAttributedString(string: "Subtitle"),
			overlayContainerBarHeading: NSAttributedString(string: "Heading"),
			bodyHeader: NSAttributedString(string: "Body"),
			primaryActionButtonAttributes: nil,
			dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(bodyDiv: [:]),
			disclosure: NSAttributedString(string: "Disclosure"),
			disclosureHTML: ""
		)
		let controller = PopupController(
			integrationKey: "integration-key",
			merchantConfiguration: MerchantConfiguration(storeNumber: "store-123"),
			placementConfiguration: PlacementConfiguration(popUpStyling: PopUpStyling()),
			popupModel: model,
			overlayType: .embeddedOverlay,
			brandConfiguration: nil,
			logger: Logger(),
			callback: callback
		)
		controller.view = UIView()
		return controller
	}

	@Test("dismissPopup emits popupClosed")
	@MainActor
	func dismissPopupEmitsPopupClosed() {
		let eventBox = EventBox()
		let controller = makeController { event in
			eventBox.events.append(event)
		}

		controller.dismissPopup()

		guard case .popupClosed? = eventBox.events.first else {
			Issue.record("Expected dismissPopup to emit popupClosed")
			return
		}
	}

	@Test("actionButtonTapped reports an error when placement data is unavailable")
	@MainActor
	func actionButtonTappedReportsMissingPlacement() {
		let eventBox = EventBox()
		let controller = makeController { event in
			eventBox.events.append(event)
		}

		controller.actionButtonTapped()

		guard case .actionButtonTapped? = eventBox.events.first else {
			Issue.record("Expected actionButtonTapped to emit its action event")
			return
		}
		guard case let .sdkError(error)? = eventBox.events.dropFirst().first else {
			Issue.record("Expected an SDK error when placement data is unavailable")
			return
		}

		#expect(error.localizedDescription == Constants.somethingWentWrong)
	}

	@Test("actionButtonTapped displays an available embedded placement")
	@MainActor
	func actionButtonTappedDisplaysPlacement() async {
		let eventBox = EventBox()
		let controller = makeController { event in
			eventBox.events.append(event)
		}
		controller.popupView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
		controller.overlayEmbeddedView = UIView()
		controller.overlayProductView = UIView()
		controller.topRowView = UIView()
		controller.dividerTop = UIView()
		controller.brandLogo = UIImageView()
		controller.loader = LoaderIndicator(
			frame: .zero,
			placementsConfiguration: controller.placementsConfiguration!
		)
		controller.popupView.addSubview(controller.topRowView)
		controller.topRowView.addSubview(controller.dividerTop)
		controller.popupView.addSubview(controller.overlayEmbeddedView)
		controller.popupModel.webViewUrl = "https://example.com/experience"
		controller.webViewPlacementModel = controller.popupModel

		controller.actionButtonTapped()
		await Task.yield()

		guard case .actionButtonTapped? = eventBox.events.first else {
			Issue.record("Expected actionButtonTapped to emit its action event")
			return
		}
		#expect(controller.webViewManager != nil)
		#expect(controller.webView != nil)
	}

	@Test("textView delegate scrolls to the top for the header anchor")
	@MainActor
	func textViewHeaderAnchorScrollsToTop() {
		let controller = makeController()
		let scrollView = UIScrollView()
		scrollView.contentOffset = CGPoint(x: 10, y: 100)
		controller.scrollView = scrollView

		let shouldInteract = controller.textView(
			UITextView(),
			shouldInteractWith: URL(string: "#epjs-css-overlay-header")!,
			in: NSRange(location: 0, length: 1),
			interaction: .invokeDefaultAction
		)

		#expect(!shouldInteract)
		#expect(scrollView.contentOffset == .zero)
	}

	@Test("textView delegate allows external links")
	@MainActor
	func textViewExternalLinkIsAllowed() {
		let controller = makeController()

		let shouldInteract = controller.textView(
			UITextView(),
			shouldInteractWith: URL(string: "https://example.com/terms")!,
			in: NSRange(location: 0, length: 1),
			interaction: .invokeDefaultAction
		)

		#expect(shouldInteract)
	}
}
