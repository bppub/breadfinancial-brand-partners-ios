//------------------------------------------------------------------------------
//  File:          PlacementRequestBuilder.swift
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

/// `PlacementRequestBuilder` helps create a request for placements by collecting
/// necessary details like pricing and settings. It uses given configurations to
/// build and organize placement data..
class PlacementRequestBuilder {
    private var placements: [PlacementRequestBody] = []
    private var brandId: String = ""

    init(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration?,
        placementConfig: PlacementData?,
        environment: BreadPartnersEnvironment?
    ) {
        self.brandId = integrationKey
        self.createPlacementRequestBody(
            merchantConfiguration: merchantConfiguration,
            placementData: placementConfig)
    }

    private func createPlacementRequestBody(
        merchantConfiguration: MerchantConfiguration?,
        placementData: PlacementData?
    ) {
        var context = ContextRequestBody(
            ENV: APIUrl.currentEnvironment.rawValue,
            LOCATION: placementData?.locationType?.rawValue,
            PRICE: placementData?.order?.totalPrice?.value,
            CARDHOLDER_TIER: merchantConfiguration?.cardholderTier
                .takeIfNotEmpty(),
            STORE_NUMBER: merchantConfiguration?.storeNumber,
            LOYALTY_ID: merchantConfiguration?.loyaltyID.takeIfNotEmpty(),
            OVERRIDE_KEY: merchantConfiguration?.overrideKey.takeIfNotEmpty(),
            CLIENT_VAR_1: merchantConfiguration?.clientVariable1
                .takeIfNotEmpty(),
            CLIENT_VAR_2: merchantConfiguration?.clientVariable2
                .takeIfNotEmpty(),
            CLIENT_VAR_3: merchantConfiguration?.clientVariable3
                .takeIfNotEmpty(),
            CLIENT_VAR_4: merchantConfiguration?.clientVariable4
                .takeIfNotEmpty(),
            DEPARTMENT_ID: merchantConfiguration?.departmentId.takeIfNotEmpty(),
            channel: merchantConfiguration?.channel ?? placementData?.locationType?.channelCode ?? "X",
            subchannel: merchantConfiguration?.subchannel ?? "X",
            CMP: merchantConfiguration?.campaignID.takeIfNotEmpty(),
            ALLOW_CHECKOUT: placementData?.allowCheckout ?? false
        )
        
        if(placementData?.allowCheckout == true){
            let upqCheckoutData = mapUnifiedPlacementContextToUpqCheckout(
                placementData: placementData,
                merchantConfiguration: merchantConfiguration,
                
            )
            
            let upqPathData = pathForUnifiedPrequalCheckout(
                initialData: upqCheckoutData,
                clientKey: brandId
            ).queryString
            
            context.UPQ_CHECKOUT_PARAMS = upqPathData
     
        } else {
            let upqData = mapUnifiedPlacementContextToUPQCommonData(
                placementData: placementData,
                merchantConfiguration: merchantConfiguration
            )
            
            let upqPathData = pathForUnifiedPrequal(
                initialData: upqData,
                clientKey: brandId
            ).queryString
            
            context.UPQ_PARAMS = upqPathData
        }
            
            
            
        let placement = PlacementRequestBody(
            id: placementData?.placementId,
            context: context
        )

        placements.append(placement)
    }

    func build() -> PlacementRequest {
        return PlacementRequest(
            placements: placements,
            brandId: brandId
        )
    }
    
    /// Maps placement and merchant data to UPQ checkout data.
    /// Combines buyer info, order details, and shipping address for checkout processing.
    ///
    /// - Parameters:
    ///   - placementData: Placement configuration with order information
    ///   - merchantConfiguration: Merchant and buyer configuration
    ///   - sessionTrackingId: Session tracking identifier
    ///   - userTrackingId: User tracking identifier
    ///   - financingLocationId: Financing location identifier
    ///   - callCenter: Call center identifier
    /// - Returns: Dictionary with all checkout data
    private func mapUnifiedPlacementContextToUpqCheckout(
        placementData: PlacementData? = nil,
        merchantConfiguration: MerchantConfiguration? = nil,
        sessionTrackingId: String? = nil,
        userTrackingId: String? = nil,
        financingLocationId: String? = nil,
        callCenter: String? = nil
    ) -> [String: Any?] {
        // Map common data from placement and merchant configs
        var commonData = mapUnifiedPlacementContextToUPQCommonData(
            placementData: placementData,
            merchantConfiguration: merchantConfiguration,
            sessionId: sessionTrackingId,
            userTrackingId: userTrackingId
        )
        
        // Map order and check BNPL eligibility
        let newOrder = mapUnifiedPlacementOrderToOrder(placementData?.order)
        checkBnplEligibility(newOrder)
        
        // Map shipping address
        let shippingAddress = mapUnifiedPlacementContextToUPQAddressRequest(
            buyer: merchantConfiguration?.buyer
        )
        
        return commonData.assignDefined(
            [
                "order": newOrder,
                "shippingAddress": shippingAddress,
                "prequalCreditLimit": placementData?.prequalCreditLimit,
                "prequalificationId": placementData?.prequalificationId,
                "financingBuyerId": placementData?.financingBuyerId,
                "financingLocationId": financingLocationId,
                "callCenter": callCenter,
                "inSessionToken": placementData?.upqInSessionToken
            ]
        )
    }
    
    private func checkBnplEligibility(_ order: [String: Any?]) {}
    
    /// Maps buyer shipping address to UPQ address.
    ///
    /// - Parameter buyer: Buyer object containing shipping address
    /// - Returns: UPQAddressRequest with mapped fields, or nil if address is not available
    private func mapUnifiedPlacementContextToUPQAddressRequest(
        buyer: BreadPartnersBuyer?
    ) -> UPQAddressRequest? {
        guard let shippingAddress = buyer?.shippingAddress else { return nil }
        
        return UPQAddressRequest(
            address1: shippingAddress.address1,
            address2: shippingAddress.address2,
            city: shippingAddress.locality,
            state: shippingAddress.region,
            zip: shippingAddress.postalCode
        )
    }

    
    /// Maps unified placement order to order.
    ///
    /// - Parameter order: Order object from placement config
    /// - Returns: Dictionary with mapped fields, or empty dictionary if order is nil
    private func mapUnifiedPlacementOrderToOrder(_ order: Order?) -> [String: Any?] {
        guard let order = order else { return [:] }
        
        var orderData: [String: Any?] = [:]

        // Map basic order fields
        let basicOrderData: [String: Any?] = [
            "bnplEligible": order.bnplEligible,
            "subTotalValue": fromMoneyToDollars(order.subTotal?.value),
            "totalDiscountsValue": fromMoneyToDollars(order.totalDiscounts?.value),
            "totalPriceValue": fromMoneyToDollars(order.totalPrice?.value),
            "totalShippingValue": fromMoneyToDollars(order.totalShipping?.value),
            "totalTaxValue": fromMoneyToDollars(order.totalTax?.value),
            "fulfillmentType": order.fulfillmentType
        ]
        
        orderData.assignDefined(
            basicOrderData
        )
       
        
        
         // Map items
         if let items = order.items {
             let mappedItems = items.compactMap { mapOrderItem($0) }
             if !mappedItems.isEmpty {
                 orderData["items"] = mappedItems
             }
         }
     
        // Map pickup information
        if let pickupInfo = order.pickupInformation {
            orderData["pickupInformation"] = mapPickupInformation(pickupInfo)
        }
        
        return orderData
    }
    
    /// Maps a single order item to a dictionary
    /// - Parameter item: The order item to map
    /// - Returns: Dictionary with mapped item fields
    private func mapOrderItem(_ item: Item) -> [String: Any?] {
        var itemData: [String: Any?] = [:]
        
        return itemData.assignDefined(
            [
                "name": item.name,
                "category": item.category,
                "quantity": item.quantity,
                "unitPriceValue": fromMoneyToDollars(item.unitPrice?.value),
                "unitTaxValue": fromMoneyToDollars(item.unitTax?.value),
                "sku": item.sku,
                "shippingCostValue": fromMoneyToDollars(item.shippingCost?.value),
                "fulfillmentType": item.fulfillmentType
            ]
        )
    }
    
    /// Maps pickup information from order
    /// - Parameter pickupInfo: The pickup information to map
    /// - Returns: Dictionary with mapped pickup information
    private func mapPickupInformation(_ pickupInfo: PickupInformation) -> [String: Any?] {
        var pickupData: [String: Any?] = [:]
        
        // Map name
        if let name = pickupInfo.name {
            var nameData: [String: Any?] = [:]
            nameData.assignDefined(
                [
                    "firstName": name.givenName,
                    "lastName": name.familyName,
                    "additionalName": name.additionalName
                ]
            )
            pickupData["name"] = nameData
        }
        
        // Map address
        if let address = pickupInfo.address {
            var addressData: [String: Any?] = [:]
            addressData.assignDefined(
                [
                    "address1": address.address1,
                    "address2": address.address2,
                    "city": address.locality,
                    "state": address.region,
                    "zip": address.postalCode
                ]
            )
            pickupData["address"] = addressData
        }
        
        // Map contact information
        return pickupData.assignDefined(
            [
                "mobilePhone": pickupInfo.phone,
                "emailAddress": pickupInfo.email
            ]
        )
    }

    /// Generates path and query string for unified prequalification checkout.
    /// Used for checkout flow with order information.
    ///
    /// - Parameters:
    ///   - initialData: Initial unified prequalification checkout data
    ///   - clientKey: Client key for the request
    /// - Returns: UnifiedPrequalPathResult containing path, query string, and parameters
    private func pathForUnifiedPrequalCheckout(
        initialData: [String: Any?],
        clientKey: String
    ) -> UnifiedPrequalPathResult {
        var queryParams: [String: Any?] = [
            "embedded": true,
            "clientKey": clientKey
        ]
        
        // Merge initial data
        queryParams.merge(initialData) { _, new in new }
        
        // Create final params with stringified order and shippingAddress
        var finalParams = queryParams
        
        // Stringify order object if present
        if let order = queryParams["order"] {
            finalParams["order"] = stringifyJSON(order)
        }
        
        // Stringify shippingAddress object if present
        if let shippingAddress = queryParams["shippingAddress"] {
            finalParams["shippingAddress"] = stringifyJSON(shippingAddress)
        }
        
        return UnifiedPrequalPathResult(
            path: "/unified/checkout",
            queryString: finalParams.toQueryString(),
            queryParams: queryParams
        )
    }
    
    /// Generates path and query string for unified prequalification.
    /// Used for standard prequalification flow (not checkout).
    ///
    /// - Parameters:
    ///   - initialData: Initial unified prequalification data
    ///   - clientKey: Client key for the request
    /// - Returns: UnifiedPrequalPathResult containing path, query string, and parameters
    private func pathForUnifiedPrequal(
        initialData: [String: Any?],
        clientKey: String
    ) -> UnifiedPrequalPathResult {
        var queryParams: [String: Any?] = [
            "embedded": true,
            "clientKey": clientKey
        ]
        
        // Merge initial data
        queryParams.merge(initialData) { _, new in new }
        
        return UnifiedPrequalPathResult(
            path: "/unified/offer-intro",
            queryString: queryParams.toQueryString(),
            queryParams: queryParams
        )
    }
    
    /// Maps unified placement context to UPQ common data.
    /// Transforms all fields from placementData and merchantConfiguration to CommonData format.
    ///
    /// - Parameters:
    ///   - placementData: Unified placement configuration (optional)
    ///   - merchantConfiguration: Unified setup configuration (optional)
    ///   - sessionId: Session tracking identifier (optional)
    ///   - userTrackingId: User tracking identifier (optional)
    /// - Returns: Dictionary with mapped fields from both configs
    private func mapUnifiedPlacementContextToUPQCommonData(
        placementData: PlacementData? = nil,
        merchantConfiguration: MerchantConfiguration? = nil,
        sessionId: String? = nil,
        userTrackingId: String? = nil
    ) -> [String: Any?] {
        var commonData: [String: Any?] = [:]
        
        return commonData.assignDefined(
            [
                "firstName": merchantConfiguration?.buyer?.givenName,
                "lastName": merchantConfiguration?.buyer?.familyName,
                "address1": merchantConfiguration?.buyer?.billingAddress?.address1,
                "address2": merchantConfiguration?.buyer?.billingAddress?.address2,
                "city": merchantConfiguration?.buyer?.billingAddress?.locality,
                "state": merchantConfiguration?.buyer?.billingAddress?.region,
                "zip": merchantConfiguration?.buyer?.billingAddress?.postalCode,
                "emailAddress": merchantConfiguration?.buyer?.email,
                "mobilePhone": merchantConfiguration?.buyer?.phone,
                "alternativePhone": merchantConfiguration?.buyer?.alternativePhone,
                "storeNumber": merchantConfiguration?.storeNumber,
                "loyaltyNumber": merchantConfiguration?.loyaltyID,
                "departmentId": merchantConfiguration?.departmentId,
                "checkoutAmount": placementData?.order?.totalPrice?.value.map { fromMoneyToDollars($0) },
                "location": placementData?.locationType?.rawValue,
                "epId": userTrackingId,
                "epPlacementId": placementData?.placementId,
                "epSessionId": sessionId,
                "channel": merchantConfiguration?.channel,
                "subchannel": merchantConfiguration?.subchannel,
                "clientVariable1": merchantConfiguration?.clientVariable1,
                "clientVariable2": merchantConfiguration?.clientVariable2,
                "clientVariable3": merchantConfiguration?.clientVariable3,
                "clientVariable4": merchantConfiguration?.clientVariable4,
                "selectedCardKey": placementData?.selectedCardKey,
                "defaultSelectedCardKey": placementData?.defaultSelectedCardKey,
                "overrideKey": merchantConfiguration?.overrideKey,
                "cardChoiceCode": merchantConfiguration?.cardChoiceCode,
                "associateId": merchantConfiguration?.clerkId,
                "splitPayment": merchantConfiguration?.paymentMode == .split ? true : nil
            ]
        )
    }
}


/// Represents the result of unified prequalification path generation
struct UnifiedPrequalPathResult {
    let path: String
    let queryString: String
    let queryParams: [String: Any?]
}

// MARK: - Dictionary Extension for Query String Conversion
extension Dictionary where Key == String, Value == Any? {
    /// Converts dictionary to URL query string format
    /// - Returns: Query string (e.g., "key1=value1&key2=value2")
    func toQueryString() -> String {
        let queryItems = self.compactMap { key, value -> String? in
            guard let value = value else { return nil }
            
            let stringValue: String
            if let stringVal = value as? String {
                stringValue = stringVal
            } else if let boolVal = value as? Bool {
                stringValue = boolVal ? "true" : "false"
            } else if let doubleVal = value as? Double {
                stringValue = String(format: "%.2f", doubleVal)
            } else if let numVal = value as? NSNumber {
                stringValue = numVal.stringValue
            } else if let dictVal = value as? [String: Any?],
                      let jsonData = try? JSONSerialization.data(withJSONObject: unwrapForJSON(dictVal)),
                      let jsonString = String(data: jsonData, encoding: .utf8) {
                stringValue = jsonString
            } else if let arrVal = value as? [Any],
                      let jsonData = try? JSONSerialization.data(withJSONObject: unwrapForJSON(arrVal)),
                      let jsonString = String(data: jsonData, encoding: .utf8) {
                stringValue = jsonString
            } else {
                stringValue = String(describing: value)
            }
            
            // URL encode the value
            guard let encodedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            
            return "\(key)=\(encodedValue)"
        }
        
        return queryItems.joined(separator: "&")
    }
    
    /// Merges source dictionaries into this dictionary, only including defined and non-empty values.
    ///
    /// - Parameter sources: One or more source dictionaries to merge from
    /// - Returns: Self with merged values
    @discardableResult
    mutating func assignDefined(_ sources: [String: Any?]...) -> [String: Any?] {
        for source in sources {
            if source.isEmpty { continue }
            
            for (key, value) in source {
                // Only add if value is not nil and not an empty string
                if let stringValue = value as? String {
                    if !stringValue.isEmpty {
                        self[key] = value
                    }
                } else if value != nil {
                    self[key] = value
                }
            }
        }
        return self
    }
}


struct UPQAddressRequest {
    let address1: String?
    let address2: String?
    let city: String?
    let state: String?
    let zip: String?
    
    public init(address1: String?,
                address2: String?,
                city: String?,
                state: String?,
                zip: String?) {
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.state = state
        self.zip = zip
    }
}

/// Converts Money value to dollars (divides by 100).
///
/// - Parameter moneyValue: Long value in cents
/// - Returns: Double value in dollars rounded to 2 decimal places, or nil if input is nil
private func fromMoneyToDollars(_ moneyValue: Int64?) -> Double? {
    guard let moneyValue = moneyValue else { return nil }

    return Double(moneyValue) / 100.0
}


/// Converts an object to JSON string, unwrapping Any? values before serialization
/// - Parameter object: The object to convert
/// - Returns: JSON string representation
private func stringifyJSON(_ object: Any) -> String {
    let unwrapped = unwrapForJSON(object)
    do {
        let jsonData = try JSONSerialization.data(
            withJSONObject: unwrapped,
            options: [.prettyPrinted, .sortedKeys]
        )
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
    } catch {
        print("Error converting object to JSON: \(error.localizedDescription)")
    }
    return ""
}

/// Recursively unwraps Any? values for JSON serialization
/// - Parameter value: The value to unwrap
/// - Returns: A JSON-safe representation of the value
private func unwrapForJSON(_ value: Any) -> Any {
    if let dict = value as? [String: Any?] {
        var result: [String: Any] = [:]
        for (k, v) in dict {
            if let v = v {
                let unwrapped = unwrapForJSON(v)
                if let doubleVal = unwrapped as? Double {
                    result[k] = Double(String(format: "%.2f", doubleVal)) ?? doubleVal
                } else {
                    result[k] = unwrapped
                }
            }
        }
        return result
    } else if let array = value as? [Any] {
        return array.map { unwrapForJSON($0) }
    } else if let array = value as? [[String: Any?]] {
        return array.map { unwrapForJSON($0) }
    } else if let double = value as? Double {
        return Double(String(format: "%.2f", double)) ?? double
    }
    return value
}


