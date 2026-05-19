//------------------------------------------------------------------------------
//  File:          OfferResponse.swift
//  Author(s):     Bread Financial
//  Date:          19 May 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import Foundation

/// Represents the possible offer response values sent by the WebView.
public enum OfferResponse: String {
    /// The user accepted the offer.
    case yes = "YES"
    /// The user declined the offer.
    case no = "NO"
    /// The user indicated this offer is not for them.
    case notMe = "NOT_ME"
    /// The user abandoned the offer flow.
    case abandoned = "ABANDONED"
    /// The user was not eligible for the prescreen offer.
    case prescreenNo = "PRESCREEN_NO"
}
