// ------------------------------------------------------------------------------
//  File:          Constants.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
// ------------------------------------------------------------------------------

class Constants {
    // API constants
    static let headerClientKey = "X-Client-Key"
    static let headerRequestedWithKey = "X-Requested-With"
    static let headerRequestedWithValue = "XMLHttpRequest"
    static let headerUserAgentKey = "User-Agent"
    static let headerContentType = "Content-Type"
    static let headerContentTypeValue = "application/json"
    static let headerOriginKey = "Origin"
    static let headerOriginValue = "https://brand-sdk.kmsmep.com"
    static let headerAuthorityKey = "authority"
    static let headerAuthorityValue = "metrics.kmsmep.com"
    static let headerAcceptKey = "Accept"
    static let headerAcceptValue = "*/*"
    static let headerAcceptEncodingKey = "Accept-Encoding"
    static let headerAcceptEncodingValue = "gzip, deflate, br, zstd"
    static let headerAcceptLanguageKey = "Accept-Language"
    static let headerAcceptLanguageValue = "en-GB,en-US;q=0.9,en;q=0.8"
    static let headerAccessControlRequestHeadersKey = "Access-Control-Request-Headers"
    static let headerAccessControlRequestHeadersValue = "content-type"
    static let headerAccessControlRequestMethodKey = "Access-Control-Request-Method"
    static let headerAccessControlRequestMethodValue = "POST"
    static let htmlContent = "htmlContent"
    static let url = "url"
    static func nativeSDKAlertTitle() -> String {
        return "Bread Partner"
    }
    
    static func catchError(message: String) -> String {
        return "\(error) \(message)"
    }
    
    static let securityCheckAlertTitle = "Re-CAPTCHA Verification"
    static let securityCheckFailureAlertTitle = "Unable to Verify. Please call us at 1-800-xxx-xxxx for assistance."
    static let securityCheckSuccessAlertTitle = "Congratulations!!"
    static let securityCheckSuccessAlertSubTitle = "You have been preapproved* for Credit Card!."
    static let okButton = "Ok"
    
    static let securityCheckAlertAcknolwedgeMessage = "Your web view will load once the captcha verification is successfully completed. This ensures that all transactions are secure."
    
    static func securityCheckAlertFailedMessage(error: String) -> String {
        return "Error: \(error)"
    }
    
    static let error = "Error:"
    
    static func apiError(message: String) -> String {
        return "\(error) \(message)"
    }

    static let consecutivePlacementRequestDataError = "Consecutive placement request data not found"
    
    static let apiResToJsonMapError = "Unable to convert response to map."
 
    static let textPlacementError = "\(error) Unable to handle text placement type."
    static let missingTextPlacementError = "Unhandled text placement type."
    static let noTextPlacementError = "No text placement type found."
    static let textPlacementParsingError = "Unable to parse text placement."
    
    static let popupPlacementParsingError = "\(error) Unable to parse popup placement."
    static let missingPopupPlacementError = "Unhandled popup placement type."
    static let somethingWentWrong = "Something went wrong. Please try again later."
    
    static let prescreenRequiredFieldsError = "Error: Prescreen requires customer information: firstname, lastname, and complete billing address must be provided in MerchantConfiguration."

    static func unableToLoadWebURL(message: String) -> String {
        return "\(error) Web Url Loading Issue: \(message)"
    }
    
    static let incapsulaChallenge = "IncapsulaChallenge"
    
    // Confirm Navigation dialog (mirrors Android WebView onJsBeforeUnload system dialog)
    static let confirmNavigationTitle = "Confirm Navigation"
    static let confirmNavigationMessage = "Changes you made may not be saved.\n\nAre you sure you want to navigate away from this page?"
    static let confirmNavigationStayButton = "Stay"
    static let confirmNavigationLeaveButton = "Leave"
}
