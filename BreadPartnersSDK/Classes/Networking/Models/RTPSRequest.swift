// ------------------------------------------------------------------------------
//  File:          RTPSRequest.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
// ------------------------------------------------------------------------------

import Foundation

/// Represents a request model for an RTPS.
struct RTPSRequest: Codable {
    let urlPath: String?
    let firstName: String?
    let lastName: String?
    let address1: String?
    let city: String?
    let state: String?
    let zip: String?
    let storeNumber: String
    let location: String?
    let channel: String?
    let subchannel: String?
    var reCaptchaToken: String?
    let mockResponse: String?
    let overrideConfig: OverrideConfig?
    let prescreenId: String?
    let customerAcceptedOffer: Bool?
    let alternativePhone: String?
    let mobilePhone: String?
    let emailAddress: String?

    struct OverrideConfig: Codable {
        let enhancedPresentment: Bool?
    }

    init(
        urlPath: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        address1: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil,
        storeNumber: String? = nil,
        location: String? = nil,
        channel: String? = nil,
        subchannel: String? = nil,
        reCaptchaToken: String? = nil,
        mockResponse: String? = nil,
        overrideConfig: OverrideConfig? = nil,
        prescreenId: String? = nil,
        customerAcceptedOffer: Bool? = nil,
        mobilePhone: String? = nil,
        emailAddress: String? = nil,
        alternativePhone: String? = nil
    ) {
        self.urlPath = urlPath
        self.firstName = firstName
        self.lastName = lastName
        self.address1 = address1
        self.city = city
        self.state = state
        self.zip = zip
        self.storeNumber = storeNumber ?? "8883"
        self.location = location
        self.channel = channel
        self.subchannel = subchannel
        self.reCaptchaToken = reCaptchaToken
        self.mockResponse = mockResponse
        self.overrideConfig = overrideConfig
        self.prescreenId = prescreenId
        self.customerAcceptedOffer = customerAcceptedOffer
        self.emailAddress = emailAddress
        self.mobilePhone = mobilePhone
        self.alternativePhone = alternativePhone
    }
}
