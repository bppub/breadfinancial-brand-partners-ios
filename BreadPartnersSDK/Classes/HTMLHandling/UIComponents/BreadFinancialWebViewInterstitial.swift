//------------------------------------------------------------------------------
//  File:          BreadFinancialWebViewInterstitial.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

@preconcurrency import WebKit

/// Manages WebView interactions and events within the SDK.
internal class BreadFinancialWebViewInterstitial: NSObject,
    WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate
{

    init(
        logger:Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) {
        self.logger = logger
        self.callback = callback
    }

    var onPageLoadCompleted: ((Result<URL, Error>) -> Void)?
    /// Stores a pending navigation URL that is waiting for the user to confirm
    /// they want to leave the current page (simulating a beforeunload dialog).
    var pendingNavigationURL: URL?

    let logger: Logger
    let callback: ((BreadPartnerEvents) -> Void)
    var appRestartListener: AppRestartListener?
    
    func createWebView(with url: URL) -> WKWebView {

        let contentController = WKUserContentController()
        contentController.add(self, name: "messageHandler")

        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        } else {
            UserDefaults.standard.set(true, forKey: "WebKitDeveloperExtras")
        }

        webView.navigationDelegate = self
        webView.uiDelegate = self

        Logger().logLoadingURL(url: url)
        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func loadPage(for webView: WKWebView) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            onPageLoadCompleted = { result in
                switch result {
                case .success(let url):
                    continuation.resume(returning: url)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Intercepts navigation actions. If a pending navigation URL is stored
    /// (i.e. the user already confirmed leaving via the beforeunload dialog),
    /// it is allowed through. All other navigations that change the page are
    /// cancelled and a native confirmation dialog is shown first.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let requestURL = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Allow the initial page load and same-page fragment navigation.
        let isLinkActivated = navigationAction.navigationType == .linkActivated
        let isFormSubmit = navigationAction.navigationType == .formSubmitted

        guard isLinkActivated || isFormSubmit else {
            decisionHandler(.allow)
            return
        }

        // If this URL was already confirmed by the user, allow it through.
        if let pending = pendingNavigationURL, pending == requestURL {
            pendingNavigationURL = nil
            decisionHandler(.allow)
            return
        }

        // Cancel the navigation and show a native "Leave page?" dialog.
        decisionHandler(.cancel)
        pendingNavigationURL = requestURL

        guard let rootVC = topViewController() else {
            // No view controller found — just proceed with navigation.
            pendingNavigationURL = nil
            webView.load(URLRequest(url: requestURL))
            return
        }

        let alert = UIAlertController(
            title: Constants.confirmNavigationTitle,
            message: Constants.confirmNavigationMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Constants.confirmNavigationStayButton, style: .cancel) { [weak self] _ in
            self?.pendingNavigationURL = nil
        })
        alert.addAction(UIAlertAction(title: Constants.confirmNavigationLeaveButton, style: .destructive) { [weak self] _ in
            self?.pendingNavigationURL = nil
            webView.load(URLRequest(url: requestURL))
        })
        rootVC.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView, didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        // Capture and nil out the handler before calling it to prevent the continuation
        // from being resumed more than once if didFail fires multiple times.
        let handler = onPageLoadCompleted
        onPageLoadCompleted = nil
        handler?(.failure(error))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject the anchor tag interception script on every page load
        injectAnchorInterceptorScript(view: webView)
        
        if let url = webView.url {
            // Capture and nil out the handler before calling it to prevent the continuation
            // from being resumed more than once. This can happen when messages like
            // LOG_OUT_OR_RESTART trigger a new page load, causing didFinish to fire again.
            let handler = onPageLoadCompleted
            onPageLoadCompleted = nil
            handler?(.success(url))
        }
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        if let parsedData = message.body as? [String: Any],
           let action = parsedData["action"] as? [String: Any],
           let type = action["type"] as? String {
            
            switch type {
            case "APP_RESTART":
                if let payload = action["payload"] as? String {
                    onAppRestartClicked(url: "\(payload)")
                }else {
                    logger.printLog("Issue in restarting application")
                }
            case "AnchorTags":
                if let payload = action["payload"] as? [String] {
//                    logger.printWebAnchorLogs(data:"\(payload.joined(separator: "\n"))")
                } else {
//                    logger.printWebAnchorLogs(data:"Anchor Tags: No anchors found")
                }

            case "OPEN_EXTERNAL":
                if let url = action["payload"] as? String {
                    if let externalURL = URL(string: url) {
                        UIApplication.shared.open(externalURL, options: [:], completionHandler: nil)
                    }
                }
            case "HEIGHT_CHANGED":
                break
                
            case "LOAD_ADOBE_TRACKING_ID":
                if let payload = action["payload"] as? [String: Any] {
                    if let adobeTrackingId = payload["adobeTrackingId"] {
                        if(logger.isLoggingEnabled){
                            logger.printLog("BreadPartnersSDK: AdobeTrackingID: \(adobeTrackingId)")
                        }
                    }
                }
                
            case "VIEW_PAGE":
                if let payload = action["payload"] as? [String: Any],
                   let pageName = payload["pageName"] as? String {
                    callback(.screenName(name: pageName))
                }
                
            case "CANCEL_APPLICATION":
                callback(.popupClosed)
                
            case "SUBMIT_APPLICATION":
                callback(.screenName(name: "submit-application"))
                
            case "RECEIVE_APPLICATION_RESULT":
                if let payload = action["payload"] as? [String: Any] {
                    logger.logApplicationResultDetails(payload)
                    callback(.webViewSuccess(result: payload))
                }
                
            case "RECEIVE_PRESCREEN_APPLICATION_RESULT":
                if let payload = action["payload"] as? [String: Any] {
                    logger.logApplicationResultDetails(payload)
                    callback(.webViewSuccess(result: payload))
                }
                
            case "UNIFIED_OFFERS_RECEIVED":
                if let payload = action["payload"] as? [String: Any] {
                    logger.logApplicationResultDetails(payload)
                    callback(.webViewSuccess(result: payload))
                    callback(.unifiedOffersReceived(result: payload))
                }
                
            case "RECEIVE_PREQUAL_APPLICATION_RESULT":
                if let payload = action["payload"] as? [String: Any] {
                    logger.logApplicationResultDetails(payload)
                    callback(.webViewSuccess(result: payload))
                    callback(.receivePrequalApplicationResult(result: payload))
                }
                
            case "RECEIVE_UNIFIED_CHECKOUT_APPLICATION_RESULT":
                if let payload = action["payload"] as? [String: Any] {
                    logger.logApplicationResultDetails(payload)
                    callback(.webViewSuccess(result: payload))
                    callback(.receiveUnifiedCheckoutApplicationResult(result: payload))
                    callback(.popupClosed)
                }
                
            case "SUBMIT_PREQUAL_APPLICATION":
                callback(.submitPrequalApplication)
                
            case "APPLICATION_COMPLETED":
                callback(.screenName(name: "application-completed"))
                callback(.applicationCompleted)
                callback(.popupClosed)
                
            case "OFFER_RESPONSE":
                if let payload = action["payload"] as? String,
                   let offerResponse = OfferResponse(rawValue: payload) {
                    callback(.offerResponse(response: offerResponse))
                    if offerResponse == .no || offerResponse == .notMe {
                        callback(.popupClosed)
                    }
                }
                
            case "RECEIVE_ACCOUNT_EXISTS":
                if let payload = action["payload"] as? [String: Any] {
                    logger.printLog("BreadPartnersSDK: RECEIVE_ACCOUNT_EXISTS: \(message.body)")
                    callback(.receiveAccountExist(result: payload))
                }
            
            default:
                logger.printLog("BreadPartnersSDK: WebViewMessage: \(message.body)")
            }
        }

    }
    
    func injectAnchorInterceptorScript(view: WKWebView?) {
        // CSS to remove the default blue tap-highlight and focus outline that
        // WebKit draws around the first focusable element after navigation.
        let cssScript = """
        (function() {
            var style = document.createElement('style');
            style.textContent = '* { -webkit-tap-highlight-color: transparent !important; outline: none !important; }';
            document.head.appendChild(style);
        })();
        """
        view?.evaluateJavaScript(cssScript, completionHandler: nil)

        // JavaScript code to intercept anchor tags and log them
        let script = """
        (function() {
            function isVisible(elem) {
                return !!(elem.offsetWidth || elem.offsetHeight || elem.getClientRects().length);
            }

            function handleAnchors() {
                const anchors = document.querySelectorAll('a[target="_blank"], a[data-open-externally="true"]');
                const anchorsHTML = Array.from(anchors).map(a => a.outerHTML);

                if (anchorsHTML.length > 0) {
                    window.webkit.messageHandlers.messageHandler.postMessage({
                        action: { type: 'AnchorTags', payload: anchorsHTML }
                    });
                } else {
                    window.webkit.messageHandlers.messageHandler.postMessage({
                        action: { type: 'AnchorTags', payload: 'No anchors found' }
                    });
                }

                anchors.forEach(a => {
                    if (!a.__handled__) {
                        a.__handled__ = true;
                        a.addEventListener('click', function(event) {
                            event.preventDefault();
                            window.webkit.messageHandlers.messageHandler.postMessage({
                                action: { type: 'OPEN_EXTERNAL', payload: a.href }
                            });
                        });
                    }
                });
            }

            function handleRestartButton() {
                const btn = document.querySelector('#appRestart');
                if (btn && isVisible(btn)) {
                    if (!btn.__handled__) {
                        btn.__handled__ = true;
                        btn.addEventListener('click', function(event) {
                            event.preventDefault();
                            if (btn.href) {
                                // Send the URL to the native iOS code to trigger the restart
                                window.webkit.messageHandlers.messageHandler.postMessage({
                                    action: { type: 'APP_RESTART', payload: btn.href }
                                });
                            }
                        });
                    }
                }
            }

            // Initial run
            handleAnchors();
            handleRestartButton();

            // MutationObserver to handle dynamically added elements like anchor tags and the restart button
            const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    if (mutation.addedNodes.length) {
                        handleAnchors();
                        handleRestartButton();
                    }
                });
            });

            observer.observe(document.body, { childList: true, subtree: true });
        })();
        """
        
        // Inject the script into the WebView
        view?.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func onAppRestartClicked(url: String) {
        appRestartListener?.onAppRestartClicked(url: url)
    }

    /// Returns the topmost active view controller in a backwards-compatible way.
    ///
    /// This is needed because `WKUIDelegate` methods for JavaScript dialogs
    /// (`alert`, `confirm`, `prompt`) and the "Leave this page?" beforeunload
    /// dialog all require presenting a `UIAlertController` from a live view
    /// controller. `WKWebView` itself is not a view controller, so we must
    /// locate one at runtime.
    ///
    /// - On iOS 15+, `keyWindow` is available directly on `UIWindowScene`.
    /// - On iOS 13–14, we fall back to iterating `UIApplication.shared.windows`.
    /// - The presentation chain is walked so the alert is never presented on a
    ///   controller that is already presenting another one.
    private func topViewController() -> UIViewController? {
        var root: UIViewController?
        if #available(iOS 15.0, *) {
            root = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                .first
        } else {
            root = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
        }
        // Walk up the presentation chain to get the topmost presented view controller,
        // so the alert is not presented on a controller that is already presenting another one.
        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

protocol AppRestartListener {
    func onAppRestartClicked(url: String)
}
