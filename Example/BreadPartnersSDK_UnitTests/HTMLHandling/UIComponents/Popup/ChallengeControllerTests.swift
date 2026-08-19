import Foundation
import Testing
import UIKit
import WebKit
@testable import BreadPartnersSDK

@Suite(.serialized)
struct ChallengeControllerTests {

    private final class SelectorShim: NSObject {
        @objc func closeButtonTapped() {}
    }

    @MainActor
    private func makeController(
        callback: ((BreadPartnerEvents) -> Void)? = nil,
        onComplete: @escaping (String) -> Void = { _ in }
    ) -> ChallengeController {
        ChallengeController(
            htmlContent: "<html><body>Challenge</body></html>",
            originalURL: "https://example.com/challenge",
            callback: callback,
            onComplete: onComplete,
            logger: Logger()
        )
    }

    @Test("viewDidLoad creates the challenge web view and close button")
    @MainActor
    func viewDidLoadCreatesChallengeUI() {
        let controller = makeController()

        controller.loadViewIfNeeded()

        #expect(controller.isViewLoaded)
        #expect(controller.view.backgroundColor == .white)
        #expect(controller.view.subviews.contains { $0 is WKWebView })
        #expect(controller.view.subviews.contains { $0 is UIButton })
    }

    @Test("Close button emits popupClosed")
    @MainActor
    func closeButtonEmitsPopupClosed() {
        var receivedEvent: BreadPartnerEvents?
        let controller = makeController { event in
            receivedEvent = event
        }

        controller.loadViewIfNeeded()
        let closeButton = controller.view.subviews.compactMap { $0 as? UIButton }.first
        #expect(closeButton != nil)
        controller.perform(#selector(SelectorShim.closeButtonTapped))

        guard case .popupClosed? = receivedEvent else {
            Issue.record("Expected the close button to emit popupClosed")
            return
        }
    }

    @Test("viewDidLoad assigns the controller as the web view navigation delegate")
    @MainActor
    func viewDidLoadAssignsNavigationDelegate() {
        let controller = makeController()

        controller.loadViewIfNeeded()

        let webView = controller.view.subviews.compactMap { $0 as? WKWebView }.first
        #expect(webView?.navigationDelegate === controller)
    }

    @Test("Tracks provisional and initial navigation completion")
    @MainActor
    func navigationLifecycleUpdatesControllerState() {
        let controller = makeController()
        controller.loadViewIfNeeded()
        let webView = controller.view.subviews.compactMap { $0 as? WKWebView }.first!

        controller.webView(webView, didStartProvisionalNavigation: nil)
        controller.webView(webView, didFinish: nil)

        #expect(mirrorValue(controller, key: "hasFinisedLoading") == true)
        #expect(mirrorValue(controller, key: "hasInitialLoadCompleted") == true)
    }

    private func mirrorValue<T>(_ object: Any, key: String) -> T? {
        var mirror: Mirror? = Mirror(reflecting: object)
        while let currentMirror = mirror {
            if let value = currentMirror.children.first(where: { $0.label == key })?.value as? T {
                return value
            }
            mirror = currentMirror.superclassMirror
        }
        return nil
    }
}