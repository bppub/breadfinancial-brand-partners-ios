//------------------------------------------------------------------------------
//  File:          BreadPartnerEvent.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import SwiftUI
import UIKit

/// Enum representing different events supported by BreadPartnerSDK.
public enum BreadPartnerEvents {

    /// Renders a text view containing a clickable hyperlink.
    /// - Parameter textView: BreadPartnerLinkTextSwitUI to display the linked text for SwiftUI based UI.
    case renderSwiftUITextViewWithLink(textView: BreadPartnerLinkTextSwitUI)

    /// Renders text and a button separately on the screen for SwiftUI based UI.
    /// - Parameters:
    ///   - textView: BreadPartnerTextView for displaying text.
    ///   - button: BreadPartnerButtonView for user interactions.
    case renderSwiftUISeparateTextAndButton(
        textView: BreadPartnerTextView, button: BreadPartnerButtonView)

    /// Renders a text view containing a clickable hyperlink.
    /// - Parameter textView: BreadPartnerLinkText to display the linked text for UIKit based UI.
    case renderTextViewWithLink(textView: BreadPartnerLinkText)

    /// Renders text and a button separately on the screen for UIKit based UI.
    /// - Parameters:
    ///   - textView: UITextView for displaying text.
    ///   - button: UIButton for user interactions.
    case renderSeparateTextAndButton(textView: UITextView, button: UIButton)

    /// Displays a popup interface on the screen.
    /// - Parameter view: UIViewController that presents the popup.
    case renderPopupView(view: UIViewController)

    /// Detects when a text element is clicked.
    /// This allows brand partners to trigger any specific action.
    case textClicked

    /// Detects when an action button inside a popup is tapped.
    /// This provides a callback for brand partners to handle the button tap.
    case actionButtonTapped

    /// Provides a callback for tracking screen names, typically for analytics.
    /// - Parameter name: name of the current screen.
    case screenName(name: String)

    /// Provides a success result from the web view, such as approval confirmation.
    /// - Parameter result: result object returned on success.
    case webViewSuccess(result: Any)

    /// Provides an error result from the web view, such as a failure response.
    /// - Parameter error: error object detailing the issue.
    case webViewFailure(error: Error)
    
    /// Provides a result with offers from the UPQ flow.
    /// - Parameter result: The result object returned.
    case unifiedOffersReceived(result: Any)
    
    /// Provides a result from the UPQ flow after applying for credit card.
    /// - Parameter result: The result object returned.
    case receivePrequalApplicationResult(result: Any)
    
    /// Provides a result from the UPQ flow after applying for installment product.
    /// - Parameter result: The result object returned.
    case receiveUnifiedCheckoutApplicationResult(result: Any)
    
    /// Detects when application for credit card was submitted from UPQ flow.
    case submitPrequalApplication

    /// Detects when the popup is closed at any point and provides a callback.
    case popupClosed

    /// Provides information about any SDK-related errors.
    /// - Parameter error: error object detailing the issue.
    case sdkError(error: Error)

    /// Provides information about any Card-related status.
    /// - Parameter status: object detailing the status.
    case cardApplicationStatus(status: Any)
    
    /// Logs requests, responses, errors, and successes.
    case onSDKEventLog(logs: String)
    
    /// Provides account information in account lookup call (ECO).
    case receiveAccountExist(result: Any)
    
    /// Fires when application have been submitted in different flows.
    case applicationCompleted

    /// Fires when the WebView sends an OFFER RESPONSE. The response parameter contains the OfferResponse value corresponding to the payload received from the WebView.
    case offerResponse(response: OfferResponse)

    /// Detects when the user interacts (taps) outside of the popup/web view content,
    /// i.e. on the dimmed background surrounding the popup.
    /// - Parameter location: The tap location in the popup's root view coordinate space.
    case outsideInteractionDetected(location: CGPoint)
}
