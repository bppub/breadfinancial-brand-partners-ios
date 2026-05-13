//------------------------------------------------------------------------------
//  File:          PlacementRequest.swift
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

/// Represents the request for placements.
public struct PlacementRequest: Codable {
    let placements: [PlacementRequestBody]?
    let brandId: String?

    public init(placements: [PlacementRequestBody]? = nil, brandId: String? = nil) {
        self.placements = placements
        self.brandId = brandId
    }
}

/// Represents individual placement request body.
public struct PlacementRequestBody: Codable {
    let id: String?
    let context: ContextRequestBody?

    public init(id: String? = nil, context: ContextRequestBody? = nil) {
        self.id = id
        self.context = context
    }
}

/// Represents the context for a placement request.
public struct ContextRequestBody: Codable {
    let SDK_TID: String?
    let ENV: String?
    let RTPS_ID: String?
    let BUYER_ID: String?
    let PREQUAL_ID: String?
    let PREQUAL_CREDIT_LIMIT: String?
    let LOCATION: String?
    let PRICE: Int?
    let EXISTING_CH: Bool?
    let CARDHOLDER_TIER: String?
    let STORE_NUMBER: String?
    let LOYALTY_ID: String?
    let OVERRIDE_KEY: String?
    let CLIENT_VAR_1: String?
    let CLIENT_VAR_2: String?
    let CLIENT_VAR_3: String?
    let CLIENT_VAR_4: String?
    let DEPARTMENT_ID: String?
    let channel: String?
    let subchannel: String?
    let CMP: String?
    let ALLOW_CHECKOUT: Bool?
    let UPQ_PARAMS: String?
    let UPQ_CHECKOUT_PARAMS: String?
    let embeddedUrl: String?

    public init(
        SDK_TID: String? = nil,
        ENV: String? = nil,
        RTPS_ID: String? = nil,
        BUYER_ID: String? = nil,
        PREQUAL_ID: String? = nil,
        PREQUAL_CREDIT_LIMIT: String? = nil,
        LOCATION: String? = nil,
        PRICE: Int? = nil,
        EXISTING_CH: Bool? = nil,
        CARDHOLDER_TIER: String? = nil,
        STORE_NUMBER: String? = nil,
        LOYALTY_ID: String? = nil,
        OVERRIDE_KEY: String? = nil,
        CLIENT_VAR_1: String? = nil,
        CLIENT_VAR_2: String? = nil,
        CLIENT_VAR_3: String? = nil,
        CLIENT_VAR_4: String? = nil,
        DEPARTMENT_ID: String? = nil,
        channel: String? = nil,
        subchannel: String? = nil,
        CMP: String? = nil,
        ALLOW_CHECKOUT: Bool? = nil,
        UPQ_PARAMS: String? = nil,
        UPQ_CHECKOUT_PARAMS: String? = nil,
        embeddedUrl: String? = nil
    ) {
        self.SDK_TID = SDK_TID
        self.ENV = ENV
        self.RTPS_ID = RTPS_ID
        self.BUYER_ID = BUYER_ID
        self.PREQUAL_ID = PREQUAL_ID
        self.PREQUAL_CREDIT_LIMIT = PREQUAL_CREDIT_LIMIT
        self.LOCATION = LOCATION
        self.PRICE = PRICE
        self.EXISTING_CH = EXISTING_CH
        self.CARDHOLDER_TIER = CARDHOLDER_TIER
        self.STORE_NUMBER = STORE_NUMBER
        self.LOYALTY_ID = LOYALTY_ID
        self.OVERRIDE_KEY = OVERRIDE_KEY
        self.CLIENT_VAR_1 = CLIENT_VAR_1
        self.CLIENT_VAR_2 = CLIENT_VAR_2
        self.CLIENT_VAR_3 = CLIENT_VAR_3
        self.CLIENT_VAR_4 = CLIENT_VAR_4
        self.DEPARTMENT_ID = DEPARTMENT_ID
        self.channel = channel
        self.subchannel = subchannel
        self.CMP = CMP
        self.ALLOW_CHECKOUT = ALLOW_CHECKOUT
        self.UPQ_PARAMS = UPQ_PARAMS
        self.embeddedUrl = embeddedUrl
        self.UPQ_CHECKOUT_PARAMS = UPQ_CHECKOUT_PARAMS
    }
}

extension ContextRequestBody {
    func copy(upqParams: String? = nil, upqCheckoutParams: String? = nil) -> ContextRequestBody {
        return ContextRequestBody(
            UPQ_PARAMS: upqParams,
            UPQ_CHECKOUT_PARAMS: upqCheckoutParams,
        )
    }
}
