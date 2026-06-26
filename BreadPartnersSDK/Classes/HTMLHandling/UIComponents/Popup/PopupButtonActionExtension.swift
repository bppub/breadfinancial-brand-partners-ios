//------------------------------------------------------------------------------
//  File:          PopupButtonActionExtension.swift
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

extension PopupController {
    
    /// Handles the close button tap event..
    @objc func closeButtonTapped() {
        callback(.popupClosed)
        dismiss(animated: true, completion: nil)
    }

    /// Handles the action button tap event. 
    @objc func actionButtonTapped() {
        callback(.actionButtonTapped)
        if let placementModel = webViewPlacementModel {
            displayEmbeddedOverlay(popupModel: placementModel)
        } else {
            callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                Constants.somethingWentWrong
                        ])))
        }
    }

    // MARK: - UITextViewDelegate

    /// Intercepts link taps in the disclosure text view.
    /// Anchor links beginning with `#` (e.g. `#epjs-css-overlay-header`) scroll
    /// the popup's scroll view back to the top instead of trying to open a URL.
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: Foundation.URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if URL.absoluteString == "#epjs-css-overlay-header" {
            scrollView?.setContentOffset(.zero, animated: true)
            return false
        }
        return true
    }
}
