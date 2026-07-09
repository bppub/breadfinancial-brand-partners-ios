//------------------------------------------------------------------------------
//  File:          BreadPartnerDefaults.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import UIKit

/// `BreadPartnerDefaults` class provides default configurations/styles/properties used across the BreadPartner SDK.
public class BreadPartnerDefaults: NSObject {
    public static let GRAY_COLOR: UIColor = .init(hex: "#767676")
    public static let LIGHT_GRAY_COLOR: UIColor = .init(hex: "#ececec")
    public static let TITLE_POPUP_TEXT_STYLE: PopupTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT", size: 16.0),
        textColor: .black
    )
    public static let SUBTITLE_POPUP_TEXT_STYLE: PopupTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT",size: 12.0),
        textColor: GRAY_COLOR
    )
    public static let HEADER_POPUP_TEXT_STYLE: PopupTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT", size: 14.0),
        textColor: .black
    )
    public static let HEADING_THREE_POPUP_TEXT_STYLE: PopupTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT", size: 14.0),
        textColor: .black
    )
    public static let PARAGRAPH_POPUP_TEXT_STYLE: PopupTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT",size: 10.0),
        textColor: GRAY_COLOR
    )
    public static let CONNECTOR_POPUP_TEXT_STYLE: PopupTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT",size: 14.0),
        textColor: .black
    )
    public static let DISCLOSURE_POPUP_TEXT_STYLE: PopupTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT",size: 10.0),
        textColor: GRAY_COLOR
    )
  
        
        
    
    /// Default Popup Style
    static let popupStyle = PopUpStyling(
        loaderColor: UIColor(hex: "#0f2233"),
        crossColor: .black,
        dividerColor: LIGHT_GRAY_COLOR,
        borderColor: LIGHT_GRAY_COLOR.cgColor,
        backgroundColor: .white,
        titlePopupTextStyle: TITLE_POPUP_TEXT_STYLE,
        subTitlePopupTextStyle: SUBTITLE_POPUP_TEXT_STYLE,
        headerPopupTextStyle: HEADER_POPUP_TEXT_STYLE,
        headerBgColor: LIGHT_GRAY_COLOR,
        headingThreePopupTextStyle: HEADING_THREE_POPUP_TEXT_STYLE,
        paragraphPopupTextStyle: PARAGRAPH_POPUP_TEXT_STYLE,
        connectorPopupTextStyle: CONNECTOR_POPUP_TEXT_STYLE,
        disclosurePopupTextStyle: DISCLOSURE_POPUP_TEXT_STYLE,
        actionButtonStyle: PopupActionButtonStyle(
            font: UIFont.boldSystemFont(ofSize: 18),
            textColor: .white,
            backgroundColor: .black,
            cornerRadius: 8.0,
            padding: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        )
    )
}
