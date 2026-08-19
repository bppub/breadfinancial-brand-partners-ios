import Testing
import UIKit
@testable import BreadPartnersSDK

struct PopupControllerTests {

    @Test("PopupController initializer stores all supplied configuration")
    @MainActor
    func initializerStoresConfiguration() {
        let merchantConfiguration = MerchantConfiguration(
            storeNumber: "store-123",
            env: .uat,
            channel: "channel-1",
            subchannel: "subchannel-1"
        )
        let placementConfiguration = PlacementConfiguration(
            popUpStyling: PopUpStyling()
        )
        let popupModel = PopupPlacementModel(
            overlayType: PlacementOverlayType.embeddedOverlay.rawValue,
            location: "checkout",
            brandLogoUrl: "https://example.com/logo.png",
            webViewUrl: "https://example.com/experience",
            overlayTitle: NSAttributedString(string: "Title"),
            overlaySubtitle: NSAttributedString(string: "Subtitle"),
            overlayContainerBarHeading: NSAttributedString(string: "Heading"),
            bodyHeader: NSAttributedString(string: "Body"),
            primaryActionButtonAttributes: PrimaryActionButtonModel(
                dataOverlayType: PlacementOverlayType.embeddedOverlay.rawValue,
                dataContentFetch: "content-123",
                dataActionTarget: "checkout",
                dataActionType: "SHOW_OVERLAY",
                dataActionContentId: "action-123",
                dataLocation: "footer",
                buttonText: "Continue"
            ),
            dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(
                bodyDiv: [
                    "div0": PopupPlacementModel.DynamicBodyContent(
                        tagValuePairs: ["p": "Details"]
                    )
                ]
            ),
            disclosure: NSAttributedString(string: "Disclosure"),
            disclosureHTML: "<p>Disclosure</p>"
        )
        let logger = Logger()
        var receivedEvent: BreadPartnerEvents?

        let controller = PopupController(
            integrationKey: "integration-key",
            merchantConfiguration: merchantConfiguration,
            placementConfiguration: placementConfiguration,
            popupModel: popupModel,
            overlayType: PlacementOverlayType.embeddedOverlay,
            brandConfiguration: nil,
            logger: logger,
            callback: { event in
                receivedEvent = event
            }
        )

        #expect(controller.integrationKey == "integration-key")
        #expect(controller.merchantConfiguration?.storeNumber == "store-123")
        #expect(controller.merchantConfiguration?.env == .uat)
        #expect(controller.placementsConfiguration?.popUpStyling != nil)
        #expect(controller.popupModel.overlayType == "EMBEDDED_OVERLAY")
        #expect(controller.popupModel.location == "checkout")
        #expect(controller.popupModel.webViewUrl == "https://example.com/experience")
        #expect(controller.popupModel.primaryActionButtonAttributes?.buttonText == "Continue")
        #expect(controller.popupModel.dynamicBodyModel.bodyDiv["div0"]?.tagValuePairs["p"] == "Details")
        #expect(controller.popupModel.disclosureHTML == "<p>Disclosure</p>")
        #expect(controller.overlayType == .embeddedOverlay)
        #expect(controller.brandConfiguration == nil)
        #expect(controller.logger === logger)

        controller.callback(BreadPartnerEvents.textClicked)
        if case BreadPartnerEvents.textClicked? = receivedEvent {
            // The stored callback received the event.
        } else {
            Issue.record("The initializer did not retain the callback")
        }
    }

    @Test("Forwards non-close web view events to the callback")
    @MainActor
    func handleWebViewEventForwardsNonCloseEvent() {
        var receivedEvent: BreadPartnerEvents?
        let controller = makeController { event in
            receivedEvent = event
        }

        controller.handleWebViewEvent(event: .textClicked)

        guard case .textClicked? = receivedEvent else {
            Issue.record("Expected textClicked to be forwarded")
            return
        }
    }

    @Test("Handles popupClosed through the dismissal path")
    @MainActor
    func handleWebViewEventHandlesPopupClosed() {
        var receivedEvent: BreadPartnerEvents?
        let controller = makeController { event in
            receivedEvent = event
        }

        controller.handleWebViewEvent(event: .popupClosed)

        guard case .popupClosed? = receivedEvent else {
            Issue.record("Expected popupClosed to be forwarded")
            return
        }
    }

    @Test("Hides close button for RTPS approval")
    @MainActor
    func viewDidLayoutSubviewsHidesCloseButtonForRTPSApproval() {
        let controller = makeController { _ in }
        controller.popupModel.location = "RTPS-Approval"
        controller.popupView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        controller.closeButton = UIButton(type: .system)

        controller.viewDidLayoutSubviews()

        #expect(controller.closeButton.isHidden)
    }

    @Test("Shows close button for a normal popup location")
    @MainActor
    func viewDidLayoutSubviewsShowsCloseButtonForNormalLocation() {
        let controller = makeController { _ in }
        controller.overlayType = .singleProductOverlay
        controller.popupModel.location = "checkout"
        controller.popupView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        controller.closeButton = UIButton(type: .system)

        controller.viewDidLayoutSubviews()

        #expect(!controller.closeButton.isHidden)
    }

    @Test("Returns safely when popup view is unavailable")
    @MainActor
    func viewDidLayoutSubviewsReturnsWhenPopupViewIsNil() {
        let controller = makeController { _ in }

        controller.viewDidLayoutSubviews()

        #expect(controller.popupView == nil)
    }

    @Test("Returns safely when popup view has zero bounds")
    @MainActor
    func viewDidLayoutSubviewsReturnsWhenPopupViewHasZeroBounds() {
        let controller = makeController { _ in }
        controller.popupView = UIView(frame: .zero)

        controller.viewDidLayoutSubviews()

        #expect(controller.loader == nil)
    }

    @Test("Creates a loader for an embedded overlay")
    @MainActor
    func viewDidLayoutSubviewsCreatesLoaderForEmbeddedOverlay() async {
        let controller = makeController { _ in }
        controller.popupView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        controller.closeButton = UIButton(type: .system)

        controller.viewDidLayoutSubviews()
        await Task.yield()

        #expect(controller.loader != nil)
        #expect(controller.popupView.subviews.contains { $0 === controller.loader })
    }

    @Test("viewDidLoad loads the controller view safely")
    @MainActor
    func viewDidLoadLoadsControllerViewSafely() {
        let controller = makeController { _ in }

        controller.loadViewIfNeeded()

        #expect(controller.isViewLoaded)
    }

    @Test("Creates and attaches a web view for an embedded overlay")
    @MainActor
    func displayEmbeddedOverlayCreatesWebView() {
        let controller = makeController { _ in }
        var popupModel = controller.popupModel
        popupModel.webViewUrl = "https://example.com/experience"
        prepareForEmbeddedOverlay(controller)

        controller.displayEmbeddedOverlay(popupModel)

        #expect(!controller.overlayProductView.isHidden)
        #expect(!controller.overlayEmbeddedView.isHidden)
        #expect(controller.webViewManager != nil)
        #expect(controller.webView != nil)
        #expect(controller.overlayEmbeddedView.subviews.contains { $0 === controller.webView })
    }

    @Test("Creates the embedded web view when the brand logo URL is invalid")
    @MainActor
    func displayEmbeddedOverlayContinuesWhenBrandLogoURLIsInvalid() {
        let controller = makeController { _ in }
        var popupModel = controller.popupModel
        popupModel.webViewUrl = "https://example.com/experience"
        popupModel.brandLogoUrl = "not a valid URL"
        prepareForEmbeddedOverlay(controller)

        controller.displayEmbeddedOverlay(popupModel: popupModel)

        #expect(controller.webView != nil)
        #expect(controller.brandLogo.image == nil)
    }

    @Test("Assigns the popup controller as the web view restart listener")
    @MainActor
    func displayEmbeddedOverlayAssignsRestartListener() {
        let controller = makeController { _ in }
        var popupModel = controller.popupModel
        popupModel.webViewUrl = "https://example.com/experience"
        prepareForEmbeddedOverlay(controller)

        controller.displayEmbeddedOverlay(popupModel: popupModel)

        #expect(controller.webViewManager.appRestartListener != nil)
    }

    @Test("Preserves an existing web view when the replacement URL is invalid")
    @MainActor
    func displayEmbeddedOverlayPreservesWebViewForInvalidURL() {
        let controller = makeController { _ in }
        var popupModel = controller.popupModel
        popupModel.webViewUrl = "not a valid URL"
        popupModel.brandLogoUrl = "not a valid URL"
        prepareForEmbeddedOverlay(controller)

        let existingWebView = WKWebView()
        controller.webView = existingWebView

        controller.displayEmbeddedOverlay(popupModel: popupModel)

        #expect(controller.webView === existingWebView)
    }

    @MainActor
    private func makeController(
        callback: @escaping (BreadPartnerEvents) -> Void
    ) -> PopupController {
        let popupModel = PopupPlacementModel(
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

        return PopupController(
            integrationKey: "integration-key",
            merchantConfiguration: MerchantConfiguration(storeNumber: "store-123"),
            placementConfiguration: PlacementConfiguration(),
            popupModel: popupModel,
            overlayType: .embeddedOverlay,
            brandConfiguration: nil,
            logger: Logger(),
            callback: callback
        )
    }

    @MainActor
    private func prepareForEmbeddedOverlay(_ controller: PopupController) {
        controller.popupView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        controller.overlayProductView = UIView()
        controller.overlayEmbeddedView = UIView()
        controller.topRowView = UIView()
        controller.dividerTop = UIView()
        controller.brandLogo = UIImageView()
        controller.popupView.addSubview(controller.topRowView)
        controller.topRowView.addSubview(controller.dividerTop)
        controller.popupView.addSubview(controller.overlayEmbeddedView)
    }
}