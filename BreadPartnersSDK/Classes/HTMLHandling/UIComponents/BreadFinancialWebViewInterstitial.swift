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
import QuickLook

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
    
    /// Called by WebKit when a page requests a new window (e.g. `window.open()`).
    ///
    /// When the requested URL is `nil` or empty (typical for `about:blank` popups
    /// where the web app writes disclosure HTML into a new window via `document.write()`),
    /// we return a real `WKWebView` so the content can be captured and displayed as a PDF.
    /// All other new-window requests are ignored by returning `nil`.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        let requestURL = navigationAction.request.url

        // about:blank is used when the page does window.open() and then writes
        // HTML into the new window (e.g. disclosure documents).
        // Return a hosted WKWebView so the content renders in a modal sheet.
        if requestURL == nil || (requestURL?.absoluteString ?? "").isEmpty {
            return presentedPopupWebView(with: configuration)
        }

        return nil
    }

    /// Creates a `WKWebView` using the provided configuration and returns it so
    /// WebKit can write the disclosure HTML into it.  Once the HTML has loaded,
    /// the content is rendered to a PDF via `WKWebView.createPDF()` (iOS 14+)
    /// and displayed with `QLPreviewController`.  On iOS 13 it falls back to
    /// displaying the `WKWebView` directly in a modal sheet.
    ///
    /// - Returns: The `WKWebView` instance so WebKit can route content into it.
    private func presentedPopupWebView(with configuration: WKWebViewConfiguration) -> WKWebView {
        // Use a large off-screen frame so the PDF page size is reasonable.
        let offscreenFrame = CGRect(x: 0, y: 0, width: 800, height: 1200)
        let popupWebView = WKWebView(frame: offscreenFrame, configuration: configuration)
        popupWebView.navigationDelegate = self

        // Hold a strong reference so the webView isn't deallocated before PDF is ready.
        objc_setAssociatedObject(self, &BreadFinancialWebViewInterstitial.popupWebViewKey, popupWebView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // didFinish fires on popupWebView too (same delegate). We capture it via
        // a one-shot navigation delegate wrapper below.
        let loader = DisclosurePDFLoader(owner: self, webView: popupWebView)
        objc_setAssociatedObject(popupWebView, &BreadFinancialWebViewInterstitial.loaderKey, loader, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        popupWebView.navigationDelegate = loader

        return popupWebView
    }

    private static var popupWebViewKey: UInt8 = 0
    private static var loaderKey: UInt8 = 0
    private static var dataSourceKey: UInt8 = 0
    private var isDisclosurePresenting = false

    /// Presents the disclosure content as a PDF using QLPreviewController.
    /// On iOS 14+ uses WKWebView.createPDF(); on iOS 13 falls back to
    /// UIPrintPageRenderer to generate the PDF from the webview's content.
    internal func presentDisclosureContent(from webView: WKWebView) {
        guard !isDisclosurePresenting else { return }
        isDisclosurePresenting = true
        if #available(iOS 14.0, *) {
            let config = WKPDFConfiguration()
            webView.createPDF(configuration: config) { [weak self] result in
                switch result {
                case .success(let data):
                    self?.presentPDF(data: data)
                case .failure(let error):
                    self?.presentWebViewModal(webView: webView)
                    self?.callback(.sdkError(error: error))
                }
            }
        } else {
            // iOS 13: render the WKWebView content to PDF using UIPrintPageRenderer.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let data = webView.exportAsPDF() {
                    self.presentPDF(data: data)
                } else {
                    self.presentWebViewModal(webView: webView)
                }
            }
        }
    }

    private func presentPDF(data: Data) {
        // Write to a temp file so QLPreviewController can read it.
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("disclosure.pdf")
        do {
            try data.write(to: tmpURL)
        } catch {
            callback(.sdkError(error: error))
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let topVC = self?.topViewController() else { return }
            let previewVC = QLPreviewController()
            let dataSource = DisclosurePDFPreviewDataSource(url: tmpURL)
            objc_setAssociatedObject(previewVC, &BreadFinancialWebViewInterstitial.dataSourceKey, dataSource, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            previewVC.dataSource = dataSource
            previewVC.modalPresentationStyle = .pageSheet
            topVC.present(previewVC, animated: true) {
                self?.isDisclosurePresenting = false
            }
        }
    }

    internal func presentWebViewModal(webView: WKWebView) {
        DispatchQueue.main.async { [weak self] in
            guard let topVC = self?.topViewController() else { return }

            let containerVC = UIViewController()
            containerVC.view.backgroundColor = .systemBackground
            containerVC.modalPresentationStyle = .pageSheet

            let closeButton = UIButton(type: .system)
            closeButton.setTitle("Close", for: .normal)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.addTarget(containerVC, action: #selector(UIViewController.dismissSelf), for: .touchUpInside)

            webView.translatesAutoresizingMaskIntoConstraints = false
            containerVC.view.addSubview(webView)
            containerVC.view.addSubview(closeButton)

            let safeArea = containerVC.view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
                closeButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
                webView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
                webView.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor),
            ])

            topVC.present(containerVC, animated: true)
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

private extension UIViewController {
    @objc func dismissSelf() {
        dismiss(animated: true)
    }
}

// MARK: - Disclosure PDF helpers

/// One-shot WKNavigationDelegate: waits for popup WKWebView to finish loading
/// disclosure HTML, then triggers PDF export via the owner.
private class DisclosurePDFLoader: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    weak var owner: BreadFinancialWebViewInterstitial?
    weak var webView: WKWebView?

    init(owner: BreadFinancialWebViewInterstitial, webView: WKWebView) {
        self.owner = owner
        self.webView = webView
    }

    /// Called when the initial about:blank navigation completes.
    /// We inject a MutationObserver that watches for document.write() content
    /// and posts a message back when the body has meaningful HTML.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Add ourselves as a script message handler so JS can notify us.
        webView.configuration.userContentController
            .removeScriptMessageHandler(forName: "disclosureReady")
        webView.configuration.userContentController
            .add(self, name: "disclosureReady")

        // Inject a MutationObserver that fires as soon as body has content.
        // document.write() populates the body synchronously, so this may
        // already have content by the time we run.
        let js = """
        (function() {
            function checkAndNotify() {
                if (document.body && document.body.innerHTML.trim().length > 0) {
                    window.webkit.messageHandlers.disclosureReady.postMessage("ready");
                    return true;
                }
                return false;
            }
            // Content may already be there (document.write is synchronous)
            if (!checkAndNotify()) {
                var observer = new MutationObserver(function() {
                    if (checkAndNotify()) { observer.disconnect(); }
                });
                observer.observe(document.documentElement, { childList: true, subtree: true });
            }
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    /// Called by JS MutationObserver when body content is ready.
    func userContentController(_ userContentController: WKUserContentController,
                                didReceive message: WKScriptMessage) {
        guard message.name == "disclosureReady", let wv = webView else { return }
        // Remove handler to prevent duplicate calls
        userContentController.removeScriptMessageHandler(forName: "disclosureReady")
        owner?.presentDisclosureContent(from: wv)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.configuration.userContentController
            .removeScriptMessageHandler(forName: "disclosureReady")
        owner?.presentWebViewModal(webView: webView)
    }
}

/// QLPreviewController data source that serves a single local PDF file.
private class DisclosurePDFPreviewDataSource: NSObject, QLPreviewControllerDataSource {
    let url: URL
    init(url: URL) { self.url = url }
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        url as QLPreviewItem
    }
}

// MARK: - iOS 13 PDF export

private extension WKWebView {
    /// Renders the webview's current content to a PDF `Data` blob using
    /// `UIPrintPageRenderer`. This is the iOS 13-compatible alternative to
    /// `WKWebView.createPDF()` which requires iOS 14+.
    ///
    /// - Returns: PDF data, or `nil` if rendering failed.
    func exportAsPDF() -> Data? {
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(viewPrintFormatter(), startingAtPageAt: 0)

        // A4 page size in points (72 pts/inch).
        let pageSize = CGSize(width: 595.2, height: 841.8)
        let printableRect = CGRect(origin: .zero, size: pageSize).insetBy(dx: 36, dy: 36)
        let paperRect = CGRect(origin: .zero, size: pageSize)

        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, paperRect, nil)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: renderer.numberOfPages))
        for page in 0 ..< renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: page, in: UIGraphicsGetCurrentContext()!.boundingBoxOfClipPath)
        }
        UIGraphicsEndPDFContext()
        return data.length > 0 ? data as Data : nil
    }
}
