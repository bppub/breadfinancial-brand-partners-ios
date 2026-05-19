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
    WKNavigationDelegate, WKScriptMessageHandler
{

    init(
        logger:Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) {
        self.logger = logger
        self.callback = callback
    }

    var onPageLoadCompleted: ((Result<URL, Error>) -> Void)?

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

    func webView(
        _ webView: WKWebView, didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        onPageLoadCompleted?(.failure(error))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject the anchor tag interception script on every page load
        injectAnchorInterceptorScript(view: webView)
        
        if let url = webView.url {
            onPageLoadCompleted?(.success(url))
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
                
            case "APPLICATION_COMPLETED":
                callback(.screenName(name: "application-completed"))
                callback(.popupClosed)
                
            case "OFFER_RESPONSE":
                if let payload = action["payload"] as? String,
                   let offerResponse = OfferResponse(rawValue: payload) {
                    callback(.offerResponse(response: offerResponse))
                    if offerResponse == .no || offerResponse == .notMe {
                        callback(.popupClosed)
                    }
                }
                
            default:
                logger.printLog("BreadPartnersSDK: WebViewMessage: \(message.body)")
            }
        }

    }
    
    func injectAnchorInterceptorScript(view: WKWebView?) {
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
}

protocol AppRestartListener {
    func onAppRestartClicked(url: String)
}
