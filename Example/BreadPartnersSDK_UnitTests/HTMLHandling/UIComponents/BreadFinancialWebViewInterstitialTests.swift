import Testing
@testable import BreadPartnersSDK
import UIKit
import WebKit

@Suite(.serialized)
struct BreadFinancialWebViewInterstitialTests {

	// Real WKScriptMessage/WKNavigationAction subclasses that override the get-only
	// properties, avoiding unsafeBitCast which relies on private WebKit object layout
	// and can break across OS/runtime versions.
	private final class MockScriptMessage: WKScriptMessage {
		private let _body: Any
		private let _name: String

		init(body: Any, name: String) {
			_body = body
			_name = name
			super.init()
		}

		override var body: Any { _body }
		override var name: String { _name }
	}

	private final class MockNavigationAction: WKNavigationAction {
		private let _request: URLRequest
		private let _navigationType: WKNavigationType

		init(request: URLRequest, navigationType: WKNavigationType) {
			_request = request
			_navigationType = navigationType
			super.init()
		}

		override var request: URLRequest { _request }
		override var navigationType: WKNavigationType { _navigationType }
	}

	private func makeScriptMessage(body: Any, name: String = "messageHandler") -> WKScriptMessage {
		MockScriptMessage(body: body, name: name)
	}

	private func makeNavigationAction(
		url: URL?,
		navigationType: WKNavigationType
	) -> WKNavigationAction {
		let request: URLRequest
		if let url {
			request = URLRequest(url: url)
		} else {
			let mutableRequest = NSMutableURLRequest(url: URL(string: "about:blank")!)
			mutableRequest.url = nil
			request = mutableRequest as URLRequest
		}
		return MockNavigationAction(request: request, navigationType: navigationType)
	}

	private func makeActionBody(type: String, payload: Any? = nil) -> [String: Any] {
		var action: [String: Any] = ["type": type]
		if let payload {
			action["payload"] = payload
		}
		return ["action": action]
	}

	private func makeInterstitial(callback: @escaping (BreadPartnerEvents) -> Void = { _ in })
		-> BreadFinancialWebViewInterstitial {
		BreadFinancialWebViewInterstitial(logger: Logger(), callback: callback)
	}

	@MainActor
	@Test
	func createWebViewSetsDelegates() {
		let interstitial = makeInterstitial()
		let webView = interstitial.createWebView(with: URL(string: "https://example.com")!)

		#expect(webView.navigationDelegate != nil)
		#expect(webView.uiDelegate != nil)
	}

	@MainActor
	@Test
	func injectAnchorScriptHandlesNilView() {
		makeInterstitial().injectAnchorInterceptorScript(view: nil)
		#expect(true)
	}

	@MainActor
	@Test
	func onAppRestartClickedForwardsUrl() {
		final class Listener: AppRestartListener {
			var captured: String?
			func onAppRestartClicked(url: String) { captured = url }
		}

		let listener = Listener()
		let interstitial = makeInterstitial()
		interstitial.appRestartListener = listener
		interstitial.onAppRestartClicked(url: "https://restart")

		#expect(listener.captured == "https://restart")
	}

	@MainActor
	@Test
	func onAppRestartClickedWithoutListenerDoesNothing() {
		makeInterstitial().onAppRestartClicked(url: "https://restart")
		#expect(true)
	}

	@MainActor
	@Test
	func didFailInvokesCompletionOnce() {
		let interstitial = makeInterstitial()
		var count = 0
		interstitial.onPageLoadCompleted = { _ in count += 1 }
		let webView = WKWebView(frame: .zero)

		interstitial.webView(webView, didFail: nil, withError: NSError(domain: "x", code: 1))
		interstitial.webView(webView, didFail: nil, withError: NSError(domain: "x", code: 2))

		#expect(count == 1)
		#expect(interstitial.onPageLoadCompleted == nil)
	}

	@MainActor
	@Test
	func didFinishWithoutUrlDoesNotInvokeCompletion() {
		let interstitial = makeInterstitial()
		var count = 0
		interstitial.onPageLoadCompleted = { _ in count += 1 }

		interstitial.webView(WKWebView(frame: .zero), didFinish: nil)

		#expect(count == 0)
	}

	@Test
	@MainActor
	func loadPageResumesSuccess() async throws {
		let interstitial = makeInterstitial()
		let task = Task { try await interstitial.loadPage(for: WKWebView(frame: .zero)) }
		for _ in 0..<50 {
			if interstitial.onPageLoadCompleted != nil { break }
			await Task.yield()
		}

		let expectedURL = URL(string: "https://example.com/success")!
		interstitial.onPageLoadCompleted?(.success(expectedURL))

		#expect(try await task.value == expectedURL)
	}

	@Test
	@MainActor
	func loadPageResumesFailure() async {
		let interstitial = makeInterstitial()
		let task = Task { try await interstitial.loadPage(for: WKWebView(frame: .zero)) }
		for _ in 0..<50 {
			if interstitial.onPageLoadCompleted != nil { break }
			await Task.yield()
		}

		interstitial.onPageLoadCompleted?(.failure(NSError(domain: "TestError", code: 9)))

		do {
			_ = try await task.value
			Issue.record("Expected loadPage to throw")
		} catch {
			let nsError = error as NSError
			#expect(nsError.domain == "TestError")
			#expect(nsError.code == 9)
		}
	}

	@MainActor
	@Test
	func navigationWithoutUrlIsAllowed() {
		let interstitial = makeInterstitial()
		var decision: WKNavigationActionPolicy?

		interstitial.webView(
			WKWebView(frame: .zero),
			decidePolicyFor: makeNavigationAction(url: nil, navigationType: .linkActivated),
			decisionHandler: { decision = $0 }
		)

		#expect(decision == .allow)
	}

	@MainActor
	@Test
	func navigationWithoutPendingRestartIsAllowed() {
		let interstitial = makeInterstitial()
		var decision: WKNavigationActionPolicy?

		interstitial.webView(
			WKWebView(frame: .zero),
			decidePolicyFor: makeNavigationAction(
				url: URL(string: "https://example.com/next"),
				navigationType: .linkActivated
			),
			decisionHandler: { decision = $0 }
		)

		#expect(decision == .allow)
	}

	@MainActor
	@Test
	func confirmedPendingNavigationIsAllowedAndCleared() {
		let interstitial = makeInterstitial()
		let url = URL(string: "https://example.com/confirmed")!
		interstitial.pendingLogOutOrRestart = true
		interstitial.pendingNavigationURL = url
		var decision: WKNavigationActionPolicy?

		interstitial.webView(
			WKWebView(frame: .zero),
			decidePolicyFor: makeNavigationAction(url: url, navigationType: .formSubmitted),
			decisionHandler: { decision = $0 }
		)

		#expect(decision == .allow)
		#expect(interstitial.pendingNavigationURL == nil)
	}

	@MainActor
	@Test
	func newWindowWithoutUrlCreatesDisclosureWebView() {
		let interstitial = makeInterstitial()
		let webView = WKWebView(frame: .zero)
		let popup = interstitial.webView(
			webView,
			createWebViewWith: WKWebViewConfiguration(),
			for: makeNavigationAction(url: nil, navigationType: .other),
			windowFeatures: WKWindowFeatures()
		)

		#expect(popup != nil)
		#expect(popup?.navigationDelegate != nil)
	}

	@MainActor
	@Test
	func newWindowWithUrlIsIgnored() {
		let interstitial = makeInterstitial()
		let popup = interstitial.webView(
			WKWebView(frame: .zero),
			createWebViewWith: WKWebViewConfiguration(),
			for: makeNavigationAction(
				url: URL(string: "https://example.com/external"),
				navigationType: .other
			),
			windowFeatures: WKWindowFeatures()
		)

		#expect(popup == nil)
	}

	@MainActor
	@Test
	func malformedScriptMessageIsIgnored() {
		let interstitial = makeInterstitial()
		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(body: "not-an-action")
		)

		#expect(interstitial.pendingLogOutOrRestart == false)
	}

	@MainActor
	@Test
	func logoutOrRestartMessageSetsPendingFlag() {
		let interstitial = makeInterstitial()
		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(body: makeActionBody(type: "LOG_OUT_OR_RESTART"))
		)

		#expect(interstitial.pendingLogOutOrRestart == true)
	}

	@MainActor
	@Test
	func appRestartMessageForwardsPayloadToListener() {
		final class Listener: AppRestartListener {
			var captured: String?
			func onAppRestartClicked(url: String) { captured = url }
		}

		let listener = Listener()
		let interstitial = makeInterstitial()
		interstitial.appRestartListener = listener
		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(
				body: makeActionBody(type: "APP_RESTART", payload: "https://restart.local")
			)
		)

		#expect(listener.captured == "https://restart.local")
	}

	@MainActor
	@Test
	func appRestartMessageWithoutPayloadDoesNotNotifyListener() {
		final class Listener: AppRestartListener {
			var callCount = 0
			func onAppRestartClicked(url: String) { callCount += 1 }
		}

		let listener = Listener()
		let interstitial = makeInterstitial()
		interstitial.appRestartListener = listener
		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(body: makeActionBody(type: "APP_RESTART"))
		)

		#expect(listener.callCount == 0)
	}

	@MainActor
	@Test
	func viewPageMessageEmitsScreenName() {
		var captured: String?
		let interstitial = makeInterstitial { event in
			if case .screenName(let name) = event { captured = name }
		}

		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(
				body: makeActionBody(type: "VIEW_PAGE", payload: ["pageName": "approval-page"])
			)
		)

		#expect(captured == "approval-page")
	}

	@MainActor
	@Test
	func viewPageMessageWithoutPageNameDoesNotEmitEvent() {
		var eventCount = 0
		let interstitial = makeInterstitial { _ in eventCount += 1 }

		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(body: makeActionBody(type: "VIEW_PAGE", payload: [:]))
		)

		#expect(eventCount == 0)
	}

	@MainActor
	@Test
	func simpleSubmissionMessagesEmitExpectedEvents() {
		var events: [BreadPartnerEvents] = []
		let interstitial = makeInterstitial { events.append($0) }
		let controller = WKUserContentController()

		interstitial.userContentController(controller, didReceive: makeScriptMessage(body: makeActionBody(type: "CANCEL_APPLICATION")))
		interstitial.userContentController(controller, didReceive: makeScriptMessage(body: makeActionBody(type: "SUBMIT_APPLICATION")))
		interstitial.userContentController(controller, didReceive: makeScriptMessage(body: makeActionBody(type: "SUBMIT_PREQUAL_APPLICATION")))

		#expect(events.count == 3)
		if case .popupClosed = events[0] {} else { Issue.record("Expected popupClosed") }
		if case .screenName(let name) = events[1] { #expect(name == "submit-application") } else { Issue.record("Expected submit screen event") }
		if case .submitPrequalApplication = events[2] {} else { Issue.record("Expected submit prequal event") }
	}

	@MainActor
	@Test
	func applicationResultMessagesEmitWebViewSuccess() {
		for type in ["RECEIVE_APPLICATION_RESULT", "RECEIVE_PRESCREEN_APPLICATION_RESULT"] {
			var result: [String: Any]?
			let interstitial = makeInterstitial { event in
				if case .webViewSuccess(let value) = event { result = value as? [String: Any] }
			}

			interstitial.userContentController(
				WKUserContentController(),
				didReceive: makeScriptMessage(
					body: makeActionBody(type: type, payload: ["status": "approved"])
				)
			)

			#expect(result?["status"] as? String == "approved")
		}
	}

	@MainActor
	@Test
	func prequalResultMessageEmitsSuccessAndPrequalEvents() {
		var success = 0
		var prequal = 0
		let interstitial = makeInterstitial { event in
			switch event {
			case .webViewSuccess: success += 1
			case .receivePrequalApplicationResult: prequal += 1
			default: break
			}
		}

		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(
				body: makeActionBody(type: "RECEIVE_PREQUAL_APPLICATION_RESULT", payload: ["id": "p1"])
			)
		)

		#expect(success == 1)
		#expect(prequal == 1)
	}

	@MainActor
	@Test
	func accountExistsMessageEmitsAccountEvent() {
		var captured: [String: Any]?
		let interstitial = makeInterstitial { event in
			if case .receiveAccountExist(let value) = event { captured = value as? [String: Any] }
		}

		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(
				body: makeActionBody(type: "RECEIVE_ACCOUNT_EXISTS", payload: ["exists": true])
			)
		)

		#expect(captured?["exists"] as? Bool == true)
	}

	@MainActor
	@Test
	func applicationCompletedEmitsExpectedSequence() {
		var events: [BreadPartnerEvents] = []
		let interstitial = makeInterstitial { events.append($0) }

		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(body: makeActionBody(type: "APPLICATION_COMPLETED"))
		)

		#expect(events.count == 3)
		if case .screenName(let name) = events[0] { #expect(name == "application-completed") } else { Issue.record("Expected completion screen event") }
		if case .applicationCompleted = events[1] {} else { Issue.record("Expected applicationCompleted") }
		if case .popupClosed = events[2] {} else { Issue.record("Expected popupClosed") }
	}

	@MainActor
	@Test
	func offerResponseNoAndNotMeClosePopup() {
		for response in ["NO", "NOT_ME"] {
			var popupClosedCount = 0
			let interstitial = makeInterstitial { event in
				if case .popupClosed = event { popupClosedCount += 1 }
			}

			interstitial.userContentController(
				WKUserContentController(),
				didReceive: makeScriptMessage(
					body: makeActionBody(type: "OFFER_RESPONSE", payload: response)
				)
			)

			#expect(popupClosedCount == 1)
		}
	}

	@MainActor
	@Test
	func offerResponseYesDoesNotClosePopup() {
		var responseValue: OfferResponse?
		var popupClosedCount = 0
		let interstitial = makeInterstitial { event in
			switch event {
			case .offerResponse(let response): responseValue = response
			case .popupClosed: popupClosedCount += 1
			default: break
			}
		}

		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(body: makeActionBody(type: "OFFER_RESPONSE", payload: "YES"))
		)

		#expect(responseValue == .yes)
		#expect(popupClosedCount == 0)
	}

	@MainActor
	@Test
	func offerResponseUnknownValueEmitsNothing() {
		var eventCount = 0
		let interstitial = makeInterstitial { _ in eventCount += 1 }

		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(body: makeActionBody(type: "OFFER_RESPONSE", payload: "UNKNOWN"))
		)

		#expect(eventCount == 0)
	}

	@MainActor
	@Test
	func unifiedOffersMessageEmitsSuccessAndUnifiedEvents() {
		var success = 0
		var unified = 0
		let interstitial = makeInterstitial { event in
			switch event {
			case .webViewSuccess: success += 1
			case .unifiedOffersReceived: unified += 1
			default: break
			}
		}

		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(
				body: makeActionBody(type: "UNIFIED_OFFERS_RECEIVED", payload: ["applicationId": "upq-1"])
			)
		)

		#expect(success == 1)
		#expect(unified == 1)
	}

	@MainActor
	@Test
	func unifiedCheckoutResultEmitsThreeCallbacks() {
		var success = 0
		var checkout = 0
		var popupClosed = 0
		let interstitial = makeInterstitial { event in
			switch event {
			case .webViewSuccess: success += 1
			case .receiveUnifiedCheckoutApplicationResult: checkout += 1
			case .popupClosed: popupClosed += 1
			default: break
			}
		}

		interstitial.userContentController(
			WKUserContentController(),
			didReceive: makeScriptMessage(
				body: makeActionBody(type: "RECEIVE_UNIFIED_CHECKOUT_APPLICATION_RESULT", payload: ["decision": "approved"])
			)
		)

		#expect(success == 1)
		#expect(checkout == 1)
		#expect(popupClosed == 1)
	}

	@MainActor
	@Test
	func payloadRequiredMessagesIgnoreMissingPayload() {
		let messageTypes = [
			"RECEIVE_APPLICATION_RESULT",
			"RECEIVE_PRESCREEN_APPLICATION_RESULT",
			"UNIFIED_OFFERS_RECEIVED",
			"RECEIVE_PREQUAL_APPLICATION_RESULT",
			"RECEIVE_UNIFIED_CHECKOUT_APPLICATION_RESULT",
			"RECEIVE_ACCOUNT_EXISTS"
		]
		var eventCount = 0
		let interstitial = makeInterstitial { _ in eventCount += 1 }
		let controller = WKUserContentController()

		for type in messageTypes {
			interstitial.userContentController(
				controller,
				didReceive: makeScriptMessage(body: makeActionBody(type: type))
			)
		}

		#expect(eventCount == 0)
	}
}
