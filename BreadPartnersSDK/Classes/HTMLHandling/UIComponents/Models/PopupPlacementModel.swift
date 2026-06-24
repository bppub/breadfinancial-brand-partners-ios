//------------------------------------------------------------------------------
//  File:          PopupPlacementModel.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

/// A model representing the placement details for a popup overlay.
internal struct PopupPlacementModel {
    var overlayType: String
    var location: String?
    var brandLogoUrl: String
    var webViewUrl: String
    var overlayTitle: NSAttributedString
    var overlaySubtitle: NSAttributedString
    var overlayContainerBarHeading: NSAttributedString
    var bodyHeader: NSAttributedString
    var primaryActionButtonAttributes: PrimaryActionButtonModel?
    var dynamicBodyModel: DynamicBodyModel
    var disclosure: NSAttributedString
    var disclosureHTML: String
    
    struct DynamicBodyModel {
        var bodyDiv: [String: DynamicBodyContent]
    }
    
    struct DynamicBodyContent {
        var tagValuePairs: [String: String]
    }
}

/// A model representing the configuration of the primary action button.
internal struct PrimaryActionButtonModel {
    var dataOverlayType: String?
    var dataContentFetch: String?
    var dataActionTarget: String?
    var dataActionType: String?
    var dataActionContentId: String?
    var dataLocation: String?
    var buttonText: String?
    
    init(dataOverlayType: String? = nil,
         dataContentFetch: String? = nil,
         dataActionTarget: String? = nil,
         dataActionType: String? = nil,
         dataActionContentId: String? = nil,
         dataLocation: String? = nil,
         buttonText: String? = nil) {
        self.dataOverlayType = dataOverlayType
        self.dataContentFetch = dataContentFetch
        self.dataActionTarget = dataActionTarget
        self.dataActionType = dataActionType
        self.dataActionContentId = dataActionContentId
        self.dataLocation = dataLocation
        self.buttonText = buttonText
    }
}

/// Enum representing the different types of overlays that can be displayed for a placement.
internal enum PlacementOverlayType: String {
    case embeddedOverlay = "EMBEDDED_OVERLAY"
    case singleProductOverlay = "SINGLE_PRODUCT_OVERLAY"
}
