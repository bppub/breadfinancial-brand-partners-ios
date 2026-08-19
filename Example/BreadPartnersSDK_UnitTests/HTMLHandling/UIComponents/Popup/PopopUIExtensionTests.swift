import Testing
import UIKit
import WebKit
@testable import BreadPartnersSDK

@Suite(.serialized)
struct PopupUIExtensionTests {

	private final class EventBox: @unchecked Sendable {
		var event: BreadPartnerEvents?
	}

	@MainActor
	private func makeController(
		overlayType: PlacementOverlayType = .singleProductOverlay,
		styling: PopUpStyling? = PopUpStyling(),
		heading: String = "Heading",
		bodyDiv: [String: PopupPlacementModel.DynamicBodyContent] = [:],
		webViewURL: String = "",
		callback: @escaping (BreadPartnerEvents) -> Void = { _ in }
	) -> PopupController {
		let popupModel = PopupPlacementModel(
			overlayType: overlayType.rawValue,
			location: "checkout",
			brandLogoUrl: "",
			webViewUrl: webViewURL,
			overlayTitle: NSAttributedString(string: "Title"),
			overlaySubtitle: NSAttributedString(string: "Subtitle"),
			overlayContainerBarHeading: NSAttributedString(string: heading),
			bodyHeader: NSAttributedString(string: "Body"),
			primaryActionButtonAttributes: PrimaryActionButtonModel(
				dataOverlayType: overlayType.rawValue,
				dataContentFetch: "content-1",
				dataActionTarget: "primary",
				dataActionType: "SHOW_OVERLAY",
				dataActionContentId: "action-1",
				dataLocation: "footer",
				buttonText: "Continue"
			),
			dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(bodyDiv: bodyDiv),
			disclosure: NSAttributedString(string: "Disclosure"),
			disclosureHTML: "<p>Disclosure</p>"
		)

		let controller = PopupController(
			integrationKey: "integration-key",
			merchantConfiguration: MerchantConfiguration(storeNumber: "store-123"),
			placementConfiguration: PlacementConfiguration(popUpStyling: styling),
			popupModel: popupModel,
			overlayType: overlayType,
			brandConfiguration: nil,
			logger: Logger(),
			callback: callback
		)
		controller.view = UIView()
		return controller
	}

	@Test("setupPopupView creates the popup hierarchy and controls")
	@MainActor
	func setupPopupViewCreatesHierarchy() async {
		let controller = makeController()

		await controller.setupPopupView()

		#expect(controller.popupView != nil)
		#expect(controller.popupView.superview === controller.view)
		#expect(controller.topRowView.subviews.contains { $0 === controller.closeButton })
		#expect(controller.titleLabel.attributedText?.string == "Title")
		#expect(controller.subtitleLabel.attributedText?.string == "Subtitle")
		#expect(controller.actionButton.title(for: .normal) == "Continue")
		#expect(controller.disclosureTextView != nil)
	}

	@Test("setupPopupView hides an empty header")
	@MainActor
	func setupPopupViewHidesEmptyHeader() async {
		let controller = makeController(heading: "")

		await controller.setupPopupView()

		#expect(controller.headerView.isHidden)
	}

	@Test("setupPopupView keeps a populated header visible")
	@MainActor
	func setupPopupViewShowsPopulatedHeader() async {
		let controller = makeController(heading: "Important details")

		await controller.setupPopupView()

		#expect(!controller.headerView.isHidden)
		#expect(controller.headerLabel.attributedText?.string == "Important details")
	}

	@Test("addSectionsToStackView hides the dynamic container when empty")
	@MainActor
	func emptyDynamicBodyHidesContainer() async {
		let controller = makeController()
		await controller.setupPopupView()

		#expect(controller.dynamicParentProductView.isHidden)
		#expect(controller.dynamicChildProductView.arrangedSubviews.isEmpty)
	}

	@Test("addSectionsToStackView creates labels for supported body tags")
	@MainActor
	func dynamicBodyCreatesSupportedLabels() async {
		let body = [
			"div0": PopupPlacementModel.DynamicBodyContent(
				tagValuePairs: [
					"h3": "Heading",
					"p": "Paragraph",
					"connector": "Connector",
					"footer": "Footer"
				]
			)
		]
		let controller = makeController(bodyDiv: body)

		await controller.setupPopupView()

		#expect(!controller.dynamicParentProductView.isHidden)
		#expect(controller.dynamicChildProductView.arrangedSubviews.count == 3)
	}

	@Test("setupLoader adds a loader to the popup")
	@MainActor
	func setupLoaderAddsLoader() async {
		let controller = makeController()
		await controller.setupPopupView()
		controller.popupView.frame = CGRect(x: 0, y: 0, width: 320, height: 480)

		controller.setupLoader()
		await Task.yield()

		#expect(controller.loader != nil)
		#expect(controller.popupView.subviews.contains { $0 === controller.loader })
	}

	@Test("overlayProductConstraints creates layout constraints")
	@MainActor
	func overlayProductConstraintsCreatesConstraints() async {
		let controller = makeController()
		await controller.setupPopupView()

		controller.popupView.addSubview(controller.scrollView)
		controller.popupView.addSubview(controller.bottomRowView)
		controller.scrollView.addSubview(controller.overlayProductView)
		controller.overlayProductView.addSubview(controller.titleLabel)
		controller.overlayProductView.addSubview(controller.subtitleLabel)
		controller.overlayProductView.addSubview(controller.dynamicParentProductView)
		controller.overlayProductView.addSubview(controller.disclosureTextView)
		controller.dynamicParentProductView.addSubview(controller.headerView)
		controller.dynamicParentProductView.addSubview(controller.dynamicChildProductView)
		controller.headerView.addSubview(controller.headerLabel)
		controller.bottomRowView.addSubview(controller.dividerBottom)
		controller.bottomRowView.addSubview(controller.actionButton)

		controller.overlayProductConstraints()

		#expect(controller.popupView.constraints.isEmpty == false)
		#expect(controller.scrollView.constraints.isEmpty == false)
		#expect(controller.overlayProductView.constraints.isEmpty == false)
	}

	@Test("overlayEmbeddedConstraints creates layout constraints")
	@MainActor
	func overlayEmbeddedConstraintsCreatesConstraints() async {
		let controller = makeController(overlayType: .embeddedOverlay)
		await controller.setupPopupView()
		controller.webView = WKWebView()
		controller.popupView.addSubview(controller.overlayEmbeddedView)
		controller.overlayEmbeddedView.addSubview(controller.webView)

		controller.overlayEmbeddedConstraints()

		#expect(controller.popupView.constraints.isEmpty == false)
		#expect(controller.overlayEmbeddedView.constraints.isEmpty == false)
	}

	@Test("setupPopupView safely returns when popup styling is unavailable")
	@MainActor
	func setupPopupViewHandlesMissingStyling() async {
		let controller = makeController(styling: nil)

		await controller.setupPopupView()

		#expect(controller.popupView == nil)
		#expect(controller.closeButton == nil)
	}

}
