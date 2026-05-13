//------------------------------------------------------------------------------
//  File:          PlacementData.swift
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

/// Configuration for defining placement options in BreadPartners.
///
/// - `financingType`: Specifies the type of financing for the placement.
/// - `locationType`: Specifies the location type where the placement is rendered.
/// - `placementId`: A unique identifier for the placement.
/// - `domID`: A required identifier for the DOM element.
/// - `allowCheckout`: Specifies whether checkout is allowed for this placement.
/// - `order`: Represents the order configuration associated with the placement.
/// - `defaultSelectedCardKey`: Key for the default selected card, if any.
/// - `selectedCardKey`: Key for the currently selected card, if any.
public class PlacementData {
    public var financingType: BreadPartnersFinancingType?
    public var locationType: BreadPartnersLocationType?
    public var placementId: String?
    public var domID: String?
    public var allowCheckout: Bool?
    public var order: Order?
    public var defaultSelectedCardKey: String?
    public var selectedCardKey: String?
    public var upqInSessionToken: String?
    public var financingBuyerId: String?
    public var prequalificationId: String?
    public var prequalCreditLimit: String?
    
    public init(
        financingType: BreadPartnersFinancingType? = nil,
        locationType: BreadPartnersLocationType? = nil,
        placementId: String? = nil,
        domID: String? = nil,
        allowCheckout: Bool? = nil,
        order: Order? = nil,
        defaultSelectedCardKey: String? = nil,
        selectedCardKey: String? = nil
        
    ) {
        self.financingType = financingType
        self.locationType = locationType
        self.placementId = placementId
        self.domID = domID
        self.allowCheckout = allowCheckout
        self.order = order
        self.defaultSelectedCardKey = defaultSelectedCardKey
        self.selectedCardKey = selectedCardKey
    }
}

/// Specifies the location type where the placement is rendered.
public enum BreadPartnersLocationType: String, CaseIterable {
    case bag
    case banner
    case cart
    case category
    case checkout
    case dashboard
    case footer
    case homepage
    case landing
    case loyalty
    case mobile
    case product
    case header
    case search
    case myaccount
    
    /// Maps location types to their corresponding channel codes
    public static let locationChannelMap: [BreadPartnersLocationType: String] = [
        .homepage: "H",
        .landing: "L",
        .search: "S",
        .product: "P",
        .category: "C",
        .banner: "U",
        .checkout: "O",
        .cart: "A",
        .mobile: "E",
        .loyalty: "D",
        .footer: "F",
        .bag: "2",
        .dashboard: "5",
        .myaccount: "5",
        .header: "R"
    ]

    /// Returns the channel code for this location type
    public var channelCode: String? {
        return Self.locationChannelMap[self]
    }
}

/// Specifies the type of financing for the placement.
public enum BreadPartnersFinancingType: String, CaseIterable {
    case card, installments, versatile
}

/// Specifies the order configuration associated with the placement.
public class Order {
    public var subTotal: CurrencyValue?
    public var totalDiscounts: CurrencyValue?
    public var totalPrice: CurrencyValue?
    public var totalShipping: CurrencyValue?
    public var totalTax: CurrencyValue?
    public var discountCode: String?
    public var pickupInformation: PickupInformation?
    public var fulfillmentType: String?
    public var items: [Item]?
    public var bnplEligible: Bool?

    public init(
        subTotal: CurrencyValue? = nil,
        totalDiscounts: CurrencyValue? = nil,
        totalPrice: CurrencyValue? = nil,
        totalShipping: CurrencyValue? = nil,
        totalTax: CurrencyValue? = nil,
        discountCode: String? = nil,
        pickupInformation: PickupInformation? = nil,
        fulfillmentType: String? = nil,
        items: [Item]? = nil,
        bnplEligible: Bool? = nil
    ) {
        self.subTotal = subTotal
        self.totalDiscounts = totalDiscounts
        self.totalPrice = totalPrice
        self.totalShipping = totalShipping
        self.totalTax = totalTax
        self.discountCode = discountCode
        self.pickupInformation = pickupInformation
        self.fulfillmentType = fulfillmentType
        self.items = items
        self.bnplEligible = bnplEligible
    }
}

/// Specifies a currency value.
public class CurrencyValue {
    public var currency: String?
    public var value: Int?

    public init(currency: String? = nil, value: Int? = nil) {
        self.currency = currency
        self.value = value
    }
}

/// Specifies pickup information for an order.
public class PickupInformation {
    public var name: Name?
    public var phone: String?
    public var address: Address?
    public var email: String?

    public init(
        name: Name? = nil, phone: String? = nil, address: Address? = nil,
        email: String? = nil
    ) {
        self.name = name
        self.phone = phone
        self.address = address
        self.email = email
    }
}

/// Specifies a person's name.
public class Name {
    public var givenName: String?
    public var familyName: String?
    public var additionalName: String?

    public init(
        givenName: String? = nil, familyName: String? = nil,
        additionalName: String? = nil
    ) {
        self.givenName = givenName
        self.familyName = familyName
        self.additionalName = additionalName
    }
}

/// Specifies a person's address.
public class Address {
    public var address1: String?
    public var address2: String?
    public var locality: String?
    public var postalCode: String?
    public var region: String?
    public var country: String?

    public init(
        address1: String? = nil, address2: String? = nil,
        locality: String? = nil, postalCode: String? = nil,
        region: String? = nil, country: String? = nil
    ) {
        self.address1 = address1
        self.address2 = address2
        self.locality = locality
        self.postalCode = postalCode
        self.region = region
        self.country = country
    }
}

public class Item {
    public var name: String?
    public var category: String?
    public var quantity: Int?
    public var unitPrice: CurrencyValue?
    public var unitTax: CurrencyValue?
    public var sku: String?
    public var itemUrl: String?
    public var imageUrl: String?
    public var description: String?
    public var shippingCost: CurrencyValue?
    public var shippingProvider: String?
    public var shippingDescription: String?
    public var shippingTrackingNumber: String?
    public var shippingTrackingUrl: String?
    public var fulfillmentType: String?

    public init(
        name: String? = nil, category: String? = nil, quantity: Int? = nil,
        unitPrice: CurrencyValue? = nil,
        unitTax: CurrencyValue? = nil, sku: String? = nil,
        itemUrl: String? = nil, imageUrl: String? = nil,
        description: String? = nil, shippingCost: CurrencyValue? = nil,
        shippingProvider: String? = nil,
        shippingDescription: String? = nil,
        shippingTrackingNumber: String? = nil,
        shippingTrackingUrl: String? = nil, fulfillmentType: String? = nil
    ) {
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.unitTax = unitTax
        self.sku = sku
        self.itemUrl = itemUrl
        self.imageUrl = imageUrl
        self.description = description
        self.shippingCost = shippingCost
        self.shippingProvider = shippingProvider
        self.shippingDescription = shippingDescription
        self.shippingTrackingNumber = shippingTrackingNumber
        self.shippingTrackingUrl = shippingTrackingUrl
        self.fulfillmentType = fulfillmentType
    }
}
