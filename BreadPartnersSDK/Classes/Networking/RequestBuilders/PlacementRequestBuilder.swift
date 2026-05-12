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
    private var integrationKey: String = ""
    private var placements: [PlacementRequestBody] = []
    private var brandId: String = ""

    init(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration?,
        placementConfig: PlacementData?,
        environment: BreadPartnersEnvironment?
    ) async {
        self.brandId = integrationKey
        await self.createPlacementRequestBody(
            merchantConfiguration: merchantConfiguration,
            placementData: placementConfig)
    }

    private func createPlacementRequestBody(
        merchantConfiguration: MerchantConfiguration?,
        placementData: PlacementData?
    ) async {
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
            var upqCheckoutData = mapUnifiedPlacementContextToUpqCheckout()
            
            var upqPathData = pathForUnifiedPrequalCheckout()
            
           
        } else {
            let upqData = await  mapUnifiedPlacementContextToUPQCommonData(
                placementData: placementData,
                merchantConfiguration: merchantConfiguration
            )
            
            var upqPathData = pathForUnifiedPrequal(
                initialData: upqData,
                clientKey: integrationKey
            ).queryString
            
            context = context.copy(upqParams: upqPathData)
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
    
    func mapUnifiedPlacementContextToUpqCheckout() {}
    
    func pathForUnifiedPrequalCheckout() {}
    
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
    ) async -> [String: Any?] {
        var commonData: [String: Any?] = [:]
        
        return await CommonUtils().assignDefined(
            target: &commonData,
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
        
        return commonData
    }
    
    
    /// Converts money (cents) to dollars
    /// - Parameter cents: Amount in cents
    /// - Returns: Amount in dollars
    private func fromMoneyToDollars(_ cents: Int64) -> Double {
        return Double(cents) / 100.0
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
            } else if let numVal = value as? NSNumber {
                stringValue = numVal.stringValue
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
}
