// ------------------------------------------------------------------------------
//  File:          CommonUtils.swift
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
import UIKit

/// `CommonUtils` class provides utility methods for common operations across the BreadPartner SDK.
actor CommonUtils: NSObject {
    func getCurrentTimestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let currentDate = Date()
        let formattedTimestamp = dateFormatter.string(from: currentDate)
        return formattedTimestamp
    }

    func decodeJSON<T: Decodable>(from response: Any, to type: T.Type)
        async throws -> T
    {
        do {
            let jsonData: Data

            let unwrappedResponse =
                (response as? AnySendable)?.value ?? response

            if let responseData = unwrappedResponse as? Data {
                jsonData = responseData
            } else if let responseDictionary = unwrappedResponse
                as? [String: Any]
            {
                jsonData = try JSONSerialization.data(
                    withJSONObject: responseDictionary, options: [])
            } else if let responseArray = unwrappedResponse as? [[String: Any]] {
                jsonData = try JSONSerialization.data(
                    withJSONObject: responseArray, options: [])
            } else {
                throw NSError(
                    domain: "JSONDecodingError",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unsupported JSON structure"
                    ])
            }

            // Initialize JSON decoder
            let decoder = JSONDecoder()

            // Decode to the expected type
            let decodedObject = try decoder.decode(T.self, from: jsonData)

            return decodedObject
        } catch {
            throw error
        }
    }

    /// Builds a URL for RTPS Web based on the provided integration and configuration details.
    /// - Parameters:
    ///   - integrationKey: The unique integration key for the request.
    ///   - merchantConfiguration: Configuration details for the buyer and store.
    ///   - rtpsData: Configuration for RTPS settings, including mock responses and prescreen data.
    /// - Returns: A URL constructed with the given parameters, or nil if the URL could not be built.
    func buildRTPSWebURL(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration,
        rtpsData: RTPSData,
        prescreenId: Int64?
    ) async -> URL? {
        let mockResponseValue = rtpsData.mockResponse?.rawValue

        var queryParams: [String: String?] = [
            "mockMO": mockResponseValue.takeIfNotEmpty(),
            "mockPA": mockResponseValue.takeIfNotEmpty(),
            "mockVL": mockResponseValue.takeIfNotEmpty(),
            "embedded": "true",
            "clientKey": integrationKey,
            "cardType": rtpsData.cardType,
            "urlPath": "screen name",
            "firstName": merchantConfiguration.buyer?.givenName,
            "lastName": merchantConfiguration.buyer?.familyName,
            "address1": merchantConfiguration.buyer?.billingAddress?.address1,
            "city": merchantConfiguration.buyer?.billingAddress?.locality,
            "state": merchantConfiguration.buyer?.billingAddress?.region,
            "zip": merchantConfiguration.buyer?.billingAddress?.postalCode,
            "storeNumber": merchantConfiguration.storeNumber,
            "location": rtpsData.locationType?.rawValue,
            "channel": rtpsData.channel
        ]

        if prescreenId != nil {
            queryParams["prescreenId"] = "\(prescreenId ?? 0)"
        }

        guard
            var urlComponents = URLComponents(
                string: APIUrl(urlType: .rtpsWebUrl(type: "offer")).url)
        else {
            return nil
        }

        await Task {
            urlComponents.queryItems = queryParams.compactMap { key, value in
                guard let value = value, !value.isEmpty else { return nil }
                return URLQueryItem(name: key, value: value)
            }
        }.value

        return urlComponents.url
    }

    /// Builds a URL for BPS (Batch Prescreen) Web based on the provided integration and configuration details.
    /// - Parameters:
    ///   - integrationKey: The unique integration key for the request.
    ///   - merchantConfiguration: The merchant configuration containing buyer and merchant-specific data.
    ///   - placementConfiguration: The placement configuration containing placement or RTPS data.
    /// - Returns: A URL constructed with the given parameters, or nil if the URL could not be built.
    func buildBpsWebURL(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration,
        placementConfiguration: PlacementConfiguration
    ) async -> URL? {
        let mockResponseValue = placementConfiguration.rtpsData?.mockResponse?.rawValue

        // Extract buyer information
        let buyer = merchantConfiguration.buyer
        let billingAddress = buyer?.billingAddress

        // Extract order data from RTPS or placement data
        let order = placementConfiguration.rtpsData?.order ?? placementConfiguration.placementData?.order

        // Extract location - prioritize RTPS location over placement location
        let location = placementConfiguration.rtpsData?.locationType?.rawValue
            ?? placementConfiguration.placementData?.locationType?.rawValue

        // Extract channel - prioritize RTPS channel over merchant channel
        let channel = placementConfiguration.rtpsData?.channel ?? merchantConfiguration.channel
        let subchannel = placementConfiguration.rtpsData?.subChannel ?? merchantConfiguration.subchannel

        let queryParams: [String: String?] = [
            "mockMO": mockResponseValue.takeIfNotEmpty(),
            "mockPA": mockResponseValue.takeIfNotEmpty(),
            "mockVL": mockResponseValue.takeIfNotEmpty(),
            "embedded": "true",
            "clientKey": integrationKey,
            "prescreenId": placementConfiguration.rtpsData?.prescreenId.map { String($0) },
            "firstName": buyer?.givenName,
            "middleInitial": buyer?.additionalName,
            "lastName": buyer?.familyName,
            "address1": billingAddress?.address1,
            "address2": billingAddress?.address2,
            "city": billingAddress?.locality,
            "state": billingAddress?.region,
            "zip": billingAddress?.postalCode,
            "emailAddress": buyer?.email,
            "mobilePhone": buyer?.phone,
            "alternativePhone": buyer?.alternativePhone,
            "cardType": placementConfiguration.rtpsData?.cardType,
            "storeNumber": merchantConfiguration.storeNumber,
            "loyaltyNumber": merchantConfiguration.loyaltyID,
            "customerNumber": nil,
            "cartAmount": order?.subTotal?.value.map { String($0) },
            "productAmount": order?.items?.first?.unitPrice?.value.map { String($0) },
            "checkoutAmount": order?.totalPrice?.value.map { String($0) },
            "urlPath": nil,
            "location": location,
            "category": order?.items?.first?.category,
            "sku": order?.items?.first?.sku,
            "correlationData": placementConfiguration.rtpsData?.correlationData,
            "epId": nil,
            "epPlacementId": nil,
            "epSessionId": nil,
            "epMessageId": nil,
            "channel": channel,
            "subchannel": subchannel,
            "clientVariable1": merchantConfiguration.clientVariable1,
            "clientVariable2": merchantConfiguration.clientVariable2,
            "clientVariable3": merchantConfiguration.clientVariable3,
            "clientVariable4": merchantConfiguration.clientVariable4,
            "selectedCardKey": placementConfiguration.placementData?.selectedCardKey,
            "defaultSelectedCardKey": placementConfiguration.placementData?.defaultSelectedCardKey,
            "departmentId": merchantConfiguration.departmentId,
            "overrideKey": merchantConfiguration.overrideKey,
            "cardChoiceCode": nil,
            "associateId": merchantConfiguration.clerkId,
            "carrier": nil,
            "keyword": nil,
            "shortCode": nil,
            "channelId": nil,
            "applicationSubType": nil,
            "splitPayment": nil
        ]

        guard
            var urlComponents = URLComponents(
                string: APIUrl(urlType: .bpsWebUrl).url)
        else {
            return nil
        }

        await Task {
            urlComponents.queryItems = queryParams.compactMap { key, value in
                guard let value = value, !value.isEmpty else { return nil }
                return URLQueryItem(name: key, value: value)
            }
        }.value

        return urlComponents.url
    }

    @MainActor func getUserAgent() -> String {
        let systemName = UIDevice.current.systemName // e.g., "iOS"
        let systemVersion = UIDevice.current.systemVersion // e.g., "17.2"
        let deviceModel = UIDevice.current.model // e.g., "iPhone"

        return "\(deviceModel): \(systemName) \(systemVersion)" // iPhone; iOS 18.2
    }
}
