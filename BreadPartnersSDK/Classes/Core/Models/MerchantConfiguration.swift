//------------------------------------------------------------------------------
//  File:          MerchantConfiguration.swift
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

/// Represents configuration details for a merchant.
public struct MerchantConfiguration {
    public var buyer: BreadPartnersBuyer?
    public var loyaltyID: String?
    public var campaignID: String?
    public var storeNumber: String
    public var departmentId: String?
    public var existingCardHolder: Bool?
    public var cardholderTier: String?
    public var env: BreadPartnersEnvironment?
    public var cardEnv: String?
    public var cardChoiceCode: String? = nil

    public var channel: String?
    public var subchannel: String?
    public var clerkId: String?
    public var overrideKey: String?
    public var clientVariable1: String?
    public var clientVariable2: String?
    public var clientVariable3: String?
    public var clientVariable4: String?

    public var accountId: String?
    public var applicationId: String?
    public var invoiceNumber: String?
    public var paymentMode: PaymentMode?
    public var providerConfig: [String: Any]?
    public var skipVerification: Bool?
    public var custom: [String: Any]?

    public enum PaymentMode: String {
        case full
        case split
    }

    public init(
        buyer: BreadPartnersBuyer? = nil,
        loyaltyID: String? = nil,
        campaignID: String? = nil,
        storeNumber: String? = nil,
        departmentId: String? = nil,
        existingCardHolder: Bool? = nil,
        cardholderTier: String? = nil,
        env: BreadPartnersEnvironment? = nil,
        cardEnv: String? = nil,
        channel: String? = nil,
        subchannel: String? = nil,
        clerkId: String? = nil,
        overrideKey: String? = nil,
        clientVariable1: String? = nil,
        clientVariable2: String? = nil,
        clientVariable3: String? = nil,
        clientVariable4: String? = nil,
        accountId: String? = nil,
        applicationId: String? = nil,
        invoiceNumber: String? = nil,
        paymentMode: PaymentMode? = nil,
        providerConfig: [String: Any]? = nil,
        skipVerification: Bool? = nil,
        custom: [String: Any]? = nil,
        cardChoiceCode: String? = nil
    ) {
        self.buyer = buyer
        self.loyaltyID = loyaltyID
        self.campaignID = campaignID
        self.storeNumber = storeNumber ?? "8883"
        self.departmentId = departmentId
        self.existingCardHolder = existingCardHolder
        self.cardholderTier = cardholderTier
        self.env = env
        self.cardEnv = cardEnv
        self.channel = channel
        self.subchannel = subchannel
        self.clerkId = clerkId
        self.overrideKey = overrideKey
        self.clientVariable1 = clientVariable1
        self.clientVariable2 = clientVariable2
        self.clientVariable3 = clientVariable3
        self.clientVariable4 = clientVariable4
        self.accountId = accountId
        self.applicationId = applicationId
        self.invoiceNumber = invoiceNumber
        self.paymentMode = paymentMode
        self.providerConfig = providerConfig
        self.skipVerification = skipVerification
        self.custom = custom
        self.cardChoiceCode = cardChoiceCode
    }
}

public struct BreadPartnersBuyer {
    public var givenName: String?
    public var familyName: String?
    public var additionalName: String?
    public var birthDate: String?
    public var email: String?
    public var phone: String?
    public var alternativePhone: String?
    public var billingAddress: BreadPartnersAddress?
    public var shippingAddress: BreadPartnersAddress?

    public init(
        givenName: String? = nil,
        familyName: String? = nil,
        additionalName: String? = nil,
        birthDate: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        alternativePhone: String? = nil,
        billingAddress: BreadPartnersAddress? = nil,
        shippingAddress: BreadPartnersAddress? = nil
    ) {
        self.givenName = givenName
        self.familyName = familyName
        self.additionalName = additionalName
        self.birthDate = birthDate
        self.email = email
        self.phone = phone
        self.alternativePhone = alternativePhone
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
    }
}

public struct BreadPartnersAddress {
    public var address1: String
    public var address2: String?
    public var country: String?
    public var locality: String?
    public var region: String?
    public var postalCode: String?

    public init(
        address1: String,
        address2: String? = nil,
        country: String? = nil,
        locality: String? = nil,
        region: String? = nil,
        postalCode: String? = nil
    ) {
        self.address1 = address1
        self.address2 = address2
        self.country = country
        self.locality = locality
        self.region = region
        self.postalCode = postalCode
    }
}
