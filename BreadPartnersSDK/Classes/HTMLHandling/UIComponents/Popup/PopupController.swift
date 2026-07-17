//------------------------------------------------------------------------------
//  File:          PopupController.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import UIKit
import WebKit

internal class PopupController: UIViewController, AppRestartListener, UITextViewDelegate, UIGestureRecognizerDelegate {

    var integrationKey: String
    var popupModel: PopupPlacementModel
    var overlayType: PlacementOverlayType

    var popupView: UIView!
    var closeButton: UIButton!
    var dividerTop: UIView!
    var brandLogo: UIImageView!
    var topRowView: UIView!
    var bottomRowView: UIView!
    var dividerBottom: UIView!
    var scrollView: UIScrollView!
    var overlayProductView: UIView!
    var overlayEmbeddedView: UIView!
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var disclosureTextView: UITextView!
    var dynamicParentProductView: UIView!
    var headerLabel: UILabel!
    var headerView: UIView!
    var dynamicChildProductView: UIStackView!
    var actionButton: UIButton!
    var popupHeight: Double = 0.1
    var popupWidth: Double = 0.9
    var paddingHorizontalTen: Double = 10
    var paddingHorizontalTwenty: Double = 20
    var paddingVerticalFive: Double = 5
    var paddingVerticalTen: Double = 10
    var paddingVerticalTwenty: Double = 20
    var brandLogoHeight: Double = 50
    var webView: WKWebView!
    var webViewManager: BreadFinancialWebViewInterstitial!
    var webViewPlacementModel: PopupPlacementModel!

    var loader: LoaderIndicator!

    var merchantConfiguration: MerchantConfiguration?
    var placementsConfiguration: PlacementConfiguration?
    var brandConfiguration: BrandConfigResponse?

    var logger: Logger = Logger()
    let callback: ((BreadPartnerEvents) -> Void)

    init(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration,
        placementConfiguration: PlacementConfiguration,
        popupModel: PopupPlacementModel,
        overlayType: PlacementOverlayType,
        brandConfiguration: BrandConfigResponse?,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) {
        self.integrationKey = integrationKey
        self.merchantConfiguration = merchantConfiguration
        self.placementsConfiguration = placementConfiguration
        self.brandConfiguration = brandConfiguration
        self.popupModel = popupModel
        self.overlayType = overlayType
        self.logger = logger
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOutsideTapDetection()
        Task {
            await setupUI()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let popupView = popupView, popupView.bounds != .zero else {
            return
        }

        if overlayType == .embeddedOverlay, loader?.isHidden == nil {
            setupLoader()
        }

        closeButton.isHidden = (popupModel.location == "RTPS-Approval")
    }

    func displayEmbeddedOverlay(popupModel: PopupPlacementModel) {

        setupLoader()

        overlayProductView.isHidden = false
        overlayEmbeddedView.isHidden = false

        popupView.addSubview(overlayEmbeddedView)
        webViewManager = BreadFinancialWebViewInterstitial(
            logger: logger,
            callback: { event in
                self.handleWebViewEvent(event: event)
            })
        webViewManager.appRestartListener = self

        if let url = URL(string: popupModel.webViewUrl) {
            webView = webViewManager.createWebView(with: url)
            webViewManager.onPageLoadCompleted = { url in
                self.loader.stopAnimating()
            }

            webView.translatesAutoresizingMaskIntoConstraints = false
            self.overlayEmbeddedView.addSubview(webView)
        }

        if let imageURL = URL(string: popupModel.brandLogoUrl) {
            brandLogo.loadImage(from: imageURL) { success in
                if success {} else {}
            }
        }

        overlayEmbeddedConstraints()
    }

    func handleWebViewEvent(event: BreadPartnerEvents) {
        switch event {
        case .popupClosed:
            closeButtonTapped()
        default:
            callback(event)
        }
    }

    // MARK: - Outside Tap Detection

    /// Registers a tap gesture recognizer on the controller's root view so that
    /// taps landing on the dimmed background (i.e. outside the popup/web view)
    /// can be detected and reported back to the host app.
    ///
    /// The recognizer is configured with `cancelsTouchesInView = false` and a
    /// delegate that rejects touches inside `popupView`, so interactions with the
    /// popup content and the embedded web view continue to work normally.
    private func setupOutsideTapDetection() {
        let tapGesture = UITapGestureRecognizer(
            target: self, action: #selector(handleOutsideTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)

        // Ignore taps that fall inside the popup container (which hosts the web view).
        if let popupView = popupView,
            popupView.frame.contains(location) {
            return
        }

        callback(.popupClosed)
        dismiss(animated: true, completion: nil)
    }

    /// Ensures the outside-tap recognizer only receives touches that land outside
    /// the popup container, leaving popup/web view interactions untouched.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let popupView = popupView else { return true }
        let location = touch.location(in: view)
        return !popupView.frame.contains(location)
    }

    /// Allows the outside-tap recognizer to work alongside other gesture
    /// recognizers in the view hierarchy without blocking them.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    func onAppRestartClicked(url: String) {

        if let oldWebView = webView {
            oldWebView.removeFromSuperview()
            oldWebView.stopLoading()
        }

        webView = webViewManager.createWebView(with: URL(string: url)!)
        webViewManager.onPageLoadCompleted = { url in
            self.loader.stopAnimating()
        }

        webView.translatesAutoresizingMaskIntoConstraints = false
        self.overlayEmbeddedView.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: dividerTop.bottomAnchor),
            webView.leadingAnchor.constraint(
                equalTo: overlayEmbeddedView.leadingAnchor,
                constant: paddingHorizontalTen),
            webView.trailingAnchor.constraint(
                equalTo: overlayEmbeddedView.trailingAnchor,
                constant: -paddingHorizontalTen),
            webView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor),
        ])
    }
}
