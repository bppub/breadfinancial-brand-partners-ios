//------------------------------------------------------------------------------
//  File:          RTPSRequestBuilder.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

/// Builder class for constructing RTPS requests.
class RTPSRequestBuilder: @unchecked Sendable {

    private var merchantConfiguration: MerchantConfiguration
    private var rtpsData: RTPSData
    private var token: String?

    init(
        merchantConfiguration: MerchantConfiguration,
        rtpsData: RTPSData,
        reCaptchaToken: String?
    ) {
        self.merchantConfiguration = merchantConfiguration
        self.rtpsData = rtpsData
        self.token = reCaptchaToken
    }

    func build() -> RTPSRequest {
        let buyer = merchantConfiguration.buyer

        if rtpsData.prescreenId == nil {
            return RTPSRequest(
                urlPath: rtpsData.screenName.takeIfNotEmpty(),
                firstName: buyer?.givenName.takeIfNotEmpty(),
                lastName: buyer?.familyName.takeIfNotEmpty(),
                address1: buyer?.billingAddress?.address1,
                city: buyer?.billingAddress?.locality.takeIfNotEmpty(),
                state: buyer?.billingAddress?.region.takeIfNotEmpty(),
                zip: buyer?.billingAddress?.postalCode.takeIfNotEmpty(),
                storeNumber: merchantConfiguration.storeNumber.takeIfNotEmpty(),
                location: rtpsData.locationType?.rawValue,
                channel: merchantConfiguration.channel.takeIfNotEmpty(),
                subchannel: merchantConfiguration.subchannel.takeIfNotEmpty(),
                reCaptchaToken: token,
                mockResponse: rtpsData.mockResponse?.rawValue,
                overrideConfig: RTPSRequest.OverrideConfig(
                    enhancedPresentment: true),
                customerAcceptedOffer: rtpsData.customerAcceptedOffer,
                mobilePhone: merchantConfiguration.buyer?.phone.takeIfNotEmpty(),
                emailAddress: merchantConfiguration.buyer?.email.takeIfNotEmpty(),
                alternativePhone: merchantConfiguration.buyer?.alternativePhone.takeIfNotEmpty()
            )
        } else {
            return RTPSRequest(
                urlPath: rtpsData.screenName.takeIfNotEmpty(),
                location: rtpsData.locationType?.rawValue,
                channel: merchantConfiguration.channel.takeIfNotEmpty(),
                subchannel: merchantConfiguration.subchannel.takeIfNotEmpty(),
                mockResponse: rtpsData.mockResponse?.rawValue,
                overrideConfig: RTPSRequest.OverrideConfig(
                    enhancedPresentment: true),
                prescreenId: String(rtpsData.prescreenId!),
                customerAcceptedOffer: rtpsData.customerAcceptedOffer
            )
        }

    }
}
