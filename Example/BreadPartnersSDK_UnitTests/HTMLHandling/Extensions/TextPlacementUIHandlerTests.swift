import Testing
import UIKit
import SwiftUI
@testable import BreadPartnersSDK

@Suite(.serialized)
struct TextPlacementUIHandlerTests {

	@MainActor
	private func makeRenderer(
		splitTextAndAction: Bool = false,
		forSwiftUI: Bool = false,
		callback: @escaping (BreadPartnerEvents) -> Void = { _ in }
	) -> HTMLContentRenderer {
		HTMLContentRenderer(
			integrationKey: "brand",
			merchantConfiguration: nil,
			placementsConfiguration: nil,
			brandConfiguration: nil,
			splitTextAndAction: splitTextAndAction,
			forSwiftUI: forSwiftUI,
			logger: Logger(),
			callback: callback
		)
	}

	@Test("createSpannableText marks the link range")
	@MainActor
	func createSpannableTextAppendsClickableLink() {
		let attributed = makeRenderer().createSpannableText(
			text: "Pay over time ", linkText: "Learn More")

		#expect(attributed.string == "Pay over time Learn More")
		let range = (attributed.string as NSString).range(of: "Learn More")
		#expect(attributed.attribute(.link, at: range.location, effectiveRange: nil) as? String == "Learn More")
	}

	@Test("createPlainTextView uses content text and its fallback")
	@MainActor
	func createPlainTextViewUsesContentTextAndDefault() {
		let renderer = makeRenderer()
		renderer.textPlacementModel = TextPlacementModel(
			actionType: nil, actionTarget: nil, contentText: "Sample text",
			actionLink: nil, actionContentId: nil, htmlContent: nil)

		#expect(renderer.createPlainTextView().text == "Sample text")
		renderer.textPlacementModel = nil
		#expect(renderer.createPlainTextView().text == "N/A")
	}

	@Test("createActionButton falls back to content text")
	@MainActor
	func createActionButtonFallsBackToContentText() {
		let renderer = makeRenderer()
		renderer.textPlacementModel = TextPlacementModel(
			actionType: nil, actionTarget: nil, contentText: "Apply Now",
			actionLink: nil, actionContentId: nil, htmlContent: nil)

		let button = renderer.createActionButton()
		#expect(button.title(for: .normal) == "Apply Now")
		#expect(button.accessibilityIdentifier == "Apply Now")
	}

	@Test("renderTextAndButton emits UIKit controls")
	@MainActor
	func renderTextAndButtonEmitsUIKitEvent() {
		var renderedText: String?
		var renderedButtonTitle: String?
		let renderer = makeRenderer(splitTextAndAction: true) { event in
			if case let .renderSeparateTextAndButton(textView, button) = event {
				renderedText = textView.text
				renderedButtonTitle = button.title(for: .normal)
			}
		}
		renderer.textPlacementModel = TextPlacementModel(
			actionType: nil, actionTarget: nil, contentText: "Pay over time",
			actionLink: "Learn More", actionContentId: nil, htmlContent: nil)

		renderer.renderTextAndButton()

		#expect(renderedText == "Pay over time")
		#expect(renderedButtonTitle == "Learn More")
	}

	@Test("renderTextAndButton emits SwiftUI controls")
	@MainActor
	func renderTextAndButtonEmitsSwiftUIEvent() {
		var didRender = false
		let renderer = makeRenderer(splitTextAndAction: true, forSwiftUI: true) { event in
			if case .renderSwiftUISeparateTextAndButton = event { didRender = true }
		}
		renderer.textPlacementModel = TextPlacementModel(
			actionType: nil, actionTarget: nil, contentText: "Pay over time",
			actionLink: "Learn More", actionContentId: nil, htmlContent: nil)

		renderer.renderTextAndButton()

		#expect(didRender)
	}

	@Test("renderTextViewWithLink emits UIKit link text")
	@MainActor
	func renderTextViewWithLinkEmitsUIKitEvent() {
		var linkText: String?
		let renderer = makeRenderer { event in
			if case let .renderTextViewWithLink(textView) = event {
				linkText = textView.attributedText?.string
			}
		}
		renderer.textPlacementModel = TextPlacementModel(
			actionType: nil, actionTarget: nil, contentText: "Pay over time",
			actionLink: "Learn More", actionContentId: nil, htmlContent: nil)

		renderer.renderTextViewWithLink()

		#expect(linkText == "Pay over timeLearn More")
	}

	@Test("renderTextViewWithLink emits SwiftUI link text")
	@MainActor
	func renderTextViewWithLinkEmitsSwiftUIEvent() {
		var didRender = false
		let renderer = makeRenderer(forSwiftUI: true) { event in
			if case .renderSwiftUITextViewWithLink = event { didRender = true }
		}
		renderer.textPlacementModel = TextPlacementModel(
			actionType: nil, actionTarget: nil, contentText: "Pay over time",
			actionLink: "Learn More", actionContentId: nil, htmlContent: nil)

		renderer.renderTextViewWithLink()

		#expect(didRender)
	}

	@Test("NO_ACTION HTML rendering emits UIKit link text")
	@MainActor
	func noActionHTMLRenderingEmitsLinkText() {
		var renderedText: String?
		let renderer = makeRenderer { event in
			if case let .renderTextViewWithLink(textView) = event {
				renderedText = textView.attributedText?.string
			}
		}
		renderer.textPlacementModel = TextPlacementModel(
			actionType: "NO_ACTION", actionTarget: nil, contentText: "Text",
			actionLink: nil, actionContentId: nil,
			htmlContent: "<div><b>Formatted text</b></div>")

		renderer.renderTextViewWithLink()

		#expect(renderedText?.contains("Formatted text") == true)
	}

	@Test("handleLinkInteraction emits textClicked for NO_ACTION")
	@MainActor
	func handleLinkInteractionNoAction() async {
		var count = 0
		let renderer = makeRenderer { event in
			if case .textClicked = event { count += 1 }
		}
		renderer.responseModel = PlacementsResponse(placements: nil, placementContent: nil)
		renderer.textPlacementModel = TextPlacementModel(
			actionType: "NO_ACTION", actionTarget: nil, contentText: "Text",
			actionLink: nil, actionContentId: nil, htmlContent: nil)

		await renderer.handleLinkInteraction(link: "")

		#expect(count == 1)
	}

	@Test("handleLinkInteraction reports missing action type")
	@MainActor
	func handleLinkInteractionReportsMissingAction() async {
		var message: String?
		let renderer = makeRenderer { event in
			if case let .sdkError(error) = event { message = error.localizedDescription }
		}
		renderer.responseModel = PlacementsResponse(placements: nil, placementContent: nil)
		renderer.textPlacementModel = TextPlacementModel(
			actionType: "UNKNOWN", actionTarget: nil, contentText: "Text",
			actionLink: nil, actionContentId: nil, htmlContent: nil)

		await renderer.handleLinkInteraction(link: "")

		#expect(message == Constants.noTextPlacementError)
	}

	@Test("handleLinkInteraction reports unsupported action types")
	@MainActor
	func handleLinkInteractionReportsUnsupportedAction() async {
		var message: String?
		let renderer = makeRenderer { event in
			if case let .sdkError(error) = event { message = error.localizedDescription }
		}
		renderer.responseModel = PlacementsResponse(placements: nil, placementContent: nil)
		renderer.textPlacementModel = TextPlacementModel(
			actionType: "REDIRECT", actionTarget: nil, contentText: "Text",
			actionLink: nil, actionContentId: nil, htmlContent: nil)

		await renderer.handleLinkInteraction(link: "")

		#expect(message == Constants.missingTextPlacementError)
	}

	@Test("handleLinkInteraction returns when required models are missing")
	@MainActor
	func handleLinkInteractionReturnsWithoutModels() async {
		var eventCount = 0
		let renderer = makeRenderer { _ in eventCount += 1 }

		await renderer.handleLinkInteraction(link: "anything")

		#expect(eventCount == 0)
	}

	@Test("handleButtonTap returns when the button has no link")
	@MainActor
	func handleButtonTapWithoutLinkDoesNothing() async {
		var eventCount = 0
		let renderer = makeRenderer { _ in eventCount += 1 }

		renderer.handleButtonTap(UIButton())
		await Task.yield()

		#expect(eventCount == 0)
	}

	@Test("handleButtonTap forwards the button link to interaction handling")
	@MainActor
	func handleButtonTapForwardsLink() async {
		var count = 0
		let renderer = makeRenderer { event in
			if case .textClicked = event { count += 1 }
		}
		renderer.responseModel = PlacementsResponse(placements: nil, placementContent: nil)
		renderer.textPlacementModel = TextPlacementModel(
			actionType: "NO_ACTION", actionTarget: nil, contentText: "Text",
			actionLink: nil, actionContentId: nil, htmlContent: nil)
		let button = UIButton()
		button.accessibilityIdentifier = "Learn More"

		renderer.handleButtonTap(button)
		await Task.yield()

		#expect(count == 1)
	}

	@Test("SHOW_OVERLAY reports missing popup placement content")
	@MainActor
	func showOverlayReportsMissingPopupContent() async {
		var message: String?
		let renderer = makeRenderer { event in
			if case let .sdkError(error) = event { message = error.localizedDescription }
		}
		renderer.responseModel = PlacementsResponse(placements: nil, placementContent: nil)
		renderer.textPlacementModel = TextPlacementModel(
			actionType: "SHOW_OVERLAY", actionTarget: nil, contentText: "Text",
			actionLink: "Learn", actionContentId: "missing", htmlContent: nil)

		await renderer.handleLinkInteraction(link: "Learn")

		#expect(message == Constants.popupPlacementParsingError)
	}
}
