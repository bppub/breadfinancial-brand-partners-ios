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
}