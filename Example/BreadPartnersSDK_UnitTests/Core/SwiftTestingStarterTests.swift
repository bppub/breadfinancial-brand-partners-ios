import Testing
@testable import BreadPartnersSDK
import UIKit
import SwiftUI
import WebKit

@Suite
struct BreadPartnersSDKSwiftTestingCoverage {

    private final class ScriptMessageShim: NSObject {
        @objc let body: Any
        @objc let name: String

        init(body: Any, name: String = "messageHandler") {
            self.body = body
            self.name = name
        }
    }

    private func mirrorValue<T>(_ object: Any, key: String, as: T.Type) -> T? {
        var current: Mirror? = Mirror(reflecting: object)
        while let mirror = current {
            if let match = mirror.children.first(where: { $0.label == key })?.value as? T {
                return match
            }
            current = mirror.superclassMirror
        }
        return nil
    }

    private func makeScriptMessage(body: Any, name: String = "messageHandler") -> WKScriptMessage {
        let shim = ScriptMessageShim(body: body, name: name)
        return unsafeBitCast(shim, to: WKScriptMessage.self)
    }

    private func makeActionBody(type: String, payload: Any? = nil) -> [String: Any] {
        var action: [String: Any] = ["type": type]
        if let payload {
            action["payload"] = payload
        }
        return ["action": action]
    }

    // MARK: - Warm-up checks

    @Test
    func dummyAdditionWorks() {
        #expect(2 + 2 == 4)
    }

    @Test
    func dummyNameIsShown() {
        let name = "Manoj"
        #expect(name == "Manoj")
    }

    @Test
    func dummyUppercaseNameMatch() {
        let name = "bread"
        #expect(name.uppercased() == "BREAD")
    }

    // MARK: - Core configuration checks

    @Test
    func merchantConfigurationDefaultsStoreNumberWhenNil() {
        let config = MerchantConfiguration(storeNumber: nil)
        #expect(config.storeNumber == "8883")
    }

    @Test
    func merchantConfigurationDefaultsStoreNumberWhenEmpty() {
        let config = MerchantConfiguration(storeNumber: "")
        #expect(config.storeNumber == "8883")
    }

    @Test
    func merchantConfigurationUsesProvidedStoreNumber() {
        let config = MerchantConfiguration(storeNumber: "1234567")
        #expect(config.storeNumber == "1234567")
    }

    @Test
    func merchantConfigurationStoresOptionalFields() {
        let buyer = BreadPartnersBuyer(givenName: "Ava", familyName: "Miller")
        let config = MerchantConfiguration(
            buyer: buyer,
            loyaltyID: "LOYALTY-01",
            campaignID: "CAMPAIGN-22",
            storeNumber: "9001",
            paymentMode: .split,
            providerConfig: ["tier": "gold", "score": 10],
            skipVerification: true,
            custom: ["source": "ios-sdk"],
            cardChoiceCode: "CARD-A"
        )

        #expect(config.buyer?.givenName == "Ava")
        #expect(config.buyer?.familyName == "Miller")
        #expect(config.loyaltyID == "LOYALTY-01")
        #expect(config.campaignID == "CAMPAIGN-22")
        #expect(config.storeNumber == "9001")
        #expect(config.paymentMode == .split)
        #expect(config.providerConfig?["tier"] as? String == "gold")
        #expect(config.custom?["source"] as? String == "ios-sdk")
        #expect(config.skipVerification == true)
        #expect(config.cardChoiceCode == "CARD-A")
    }

    @Test
    func breadPartnersBuyerStoresAddresses() {
        let billingAddress = BreadPartnersAddress(
            address1: "100 Main St",
            country: "US",
            locality: "Columbus",
            region: "OH",
            postalCode: "43085"
        )
        let shippingAddress = BreadPartnersAddress(
            address1: "200 Lake Ave",
            country: "US",
            locality: "Dublin",
            region: "OH",
            postalCode: "43017"
        )
        let buyer = BreadPartnersBuyer(
            givenName: "Sam",
            familyName: "Lee",
            billingAddress: billingAddress,
            shippingAddress: shippingAddress
        )

        #expect(buyer.billingAddress?.address1 == "100 Main St")
        #expect(buyer.shippingAddress?.address1 == "200 Lake Ave")
    }

    @Test
    func placementConfigurationDefaultsToNilOptionals() {
        let config = PlacementConfiguration()
        #expect(config.placementData == nil)
        #expect(config.rtpsData == nil)
        #expect(config.popUpStyling == nil)
    }

    @Test
    func rtpsDataStoresProvidedValues() {
        let order = Order(totalPrice: CurrencyValue(currency: "USD", value: 1000))
        let rtpsData = RTPSData(
            financingType: .installments,
            order: order,
            locationType: .product,
            screenName: "PDP",
            cardType: "PLCC",
            country: "US",
            prescreenId: 42,
            correlationData: "corr-123",
            customerAcceptedOffer: true,
            mockResponse: .success
        )
        #expect(rtpsData.financingType == .installments)
        #expect(rtpsData.locationType == .product)
        #expect(rtpsData.prescreenId == 42)
        #expect(rtpsData.mockResponse == .success)
        #expect(rtpsData.order?.totalPrice?.value == 1000)
    }

    @Test
    func environmentRawValuesAreStable() {
        #expect(BreadPartnersEnvironment.stage.rawValue == "STAGE")
        #expect(BreadPartnersEnvironment.uat.rawValue == "UAT")
        #expect(BreadPartnersEnvironment.prod.rawValue == "PROD")
    }

    @Test
    func locationTypeChannelCodesForCommonPlacements() {
        #expect(BreadPartnersLocationType.homepage.channelCode == "H")
        #expect(BreadPartnersLocationType.product.channelCode == "P")
        #expect(BreadPartnersLocationType.checkout.channelCode == "O")
        #expect(BreadPartnersLocationType.cart.channelCode == "A")
    }

    @Test
    func allLocationTypesHaveChannelCodeMapping() {
        for location in BreadPartnersLocationType.allCases {
            #expect(location.channelCode != nil)
        }
    }

    @Test
    func mockOptionsAreUniqueAndIncludeNoMock() {
        let rawValues = BreadPartnersMockOptions.allCases.map(\.rawValue)
        #expect(Set(rawValues).count == rawValues.count)
        #expect(BreadPartnersMockOptions.noMock.rawValue == "")
        #expect(BreadPartnersMockOptions.allCases.contains(.success))
    }

    @Test
    func placementAndRtpsCanShareTheSameOrderReference() {
        let order = Order(totalPrice: CurrencyValue(currency: "USD", value: 1500))

        let placementData = PlacementData(
            financingType: .card,
            locationType: .checkout,
            placementId: "checkout-placement",
            order: order
        )

        let rtpsData = RTPSData(
            financingType: .card,
            order: order,
            locationType: .checkout
        )

        let config = PlacementConfiguration(placementData: placementData, rtpsData: rtpsData)
        config.placementData?.order?.totalPrice?.value = 1999

        #expect(config.rtpsData?.order?.totalPrice?.value == 1999)
    }

    @Test
    func updatingCurrencyValueReflectsThroughOrderReference() {
        let total = CurrencyValue(currency: "USD", value: 1200)
        let order = Order(totalPrice: total)

        total.value = 1300
        total.currency = "CAD"

        #expect(order.totalPrice?.value == 1300)
        #expect(order.totalPrice?.currency == "CAD")
    }

    @Test
    func merchantConfigurationPaymentModeRawValuesStayStable() {
        #expect(MerchantConfiguration.PaymentMode.full.rawValue == "full")
        #expect(MerchantConfiguration.PaymentMode.split.rawValue == "split")
    }

    @Test
    func offerResponseRawValuesAreStable() {
        #expect(OfferResponse.yes.rawValue == "YES")
        #expect(OfferResponse.no.rawValue == "NO")
        #expect(OfferResponse.notMe.rawValue == "NOT_ME")
        #expect(OfferResponse.abandoned.rawValue == "ABANDONED")
        #expect(OfferResponse.prescreenNo.rawValue == "PRESCREEN_NO")
    }

    @Test
    func uiColorHexInitializerParsesRGB() {
        let color = UIColor(hex: "#FF8040", alpha: 0.5)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        #expect(abs(r - 1.0) < 0.001)
        #expect(abs(g - 0.502) < 0.01)
        #expect(abs(b - 0.251) < 0.01)
        #expect(abs(a - 0.5) < 0.001)
    }

    @Test
    func apiUrlStageEnvironmentResolvesPrescreenAndLookup() async {
        await APIUrl.setEnvironment(.stage)

        #expect(APIUrl(urlType: .prescreen).url == "https://acquire1stage.comenity.net/api/prescreen")
        #expect(APIUrl(urlType: .virtualLookup).url == "https://acquire1stage.comenity.net/api/virtual_lookup")
    }

    @Test
    func apiUrlUatEnvironmentResolvesRtpsAndBps() async {
        await APIUrl.setEnvironment(.uat)

        #expect(APIUrl(urlType: .rtpsWebUrl(type: "offer")).url == "https://acquire1uat.comenity.net/prescreen/offer")
        #expect(APIUrl(urlType: .bpsWebUrl).url == "https://acquire1uat.comenity.net/batch-prescreen/start")
    }

    @Test
    func apiUrlBrandAndPlacementEndpointsAreStable() async {
        await APIUrl.setEnvironment(.prod)

        #expect(APIUrl(urlType: .brandStyle(brandId: "brand-1")).url == "https://brands.kmsmep.com/brands/brand-1/style")
        #expect(APIUrl(urlType: .brandConfig(brandId: "brand-1")).url == "https://brands.kmsmep.com/brands/brand-1/config")
        #expect(APIUrl(urlType: .generatePlacements).url == "https://brands.kmsmep.com/generatePlacements")
        #expect(APIUrl(urlType: .viewPlacement).url == "https://brands.kmsmep.com/ep/v1/view-placement")
        #expect(APIUrl(urlType: .clickPlacement).url == "https://brands.kmsmep.com/ep/v1/click-placement")
    }

    @Test
    func fromMoneyToDollarsConvertsExpectedValues() {
        #expect(fromMoneyToDollars(nil) == nil)
        #expect(fromMoneyToDollars(0) == 0)
        #expect(fromMoneyToDollars(12345) == 123.45)
    }

    @Test
    func takeIfNotEmptyFiltersNilAndWhitespace() {
        let nilValue: String? = nil
        let spaces: String? = "   \n  "
        let text: String? = "  abc  "

        #expect(nilValue.takeIfNotEmpty() == nil)
        #expect(spaces.takeIfNotEmpty() == nil)
        #expect(text.takeIfNotEmpty() == "  abc  ")
    }

    @Test
    func dictionaryAssignDefinedAndToQueryStringIncludeValidValues() {
        var base: [String: Any?] = [:]
        _ = base.assignDefined(["a": "x", "b": "", "c": nil, "d": 5, "e": true])

        #expect(base["a"] as? String == "x")
        #expect(base["b"] == nil)
        #expect(base["c"] == nil)
        #expect(base["d"] as? Int == 5)
        #expect(base["e"] as? Bool == true)

        let query = base.toQueryString()
        #expect(query.contains("a=x"))
        #expect(query.contains("d=5"))
        #expect(query.contains("e=true"))
    }

    @Test
    func rtpsRequestBuilderBuildsPrescreenBranchWithBuyerFields() {
        let merchant = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: "Ava",
                familyName: "Miller",
                email: "ava@example.com",
                phone: "+1234567890",
                alternativePhone: "+1987654321",
                billingAddress: BreadPartnersAddress(
                    address1: "123 Main",
                    country: "US",
                    locality: "Austin",
                    region: "TX",
                    postalCode: "78701"
                )
            ),
            storeNumber: "1234",
            channel: "APP",
            subchannel: "IOS"
        )

        let rtpsData = RTPSData(
            locationType: .checkout,
            screenName: "Checkout",
            prescreenId: nil,
            customerAcceptedOffer: true,
            mockResponse: .success
        )

        let request = RTPSRequestBuilder(
            merchantConfiguration: merchant,
            rtpsData: rtpsData,
            reCaptchaToken: "token-123"
        ).build()

        #expect(request.prescreenId == nil)
        #expect(request.firstName == "Ava")
        #expect(request.lastName == "Miller")
        #expect(request.address1 == "123 Main")
        #expect(request.city == "Austin")
        #expect(request.state == "TX")
        #expect(request.zip == "78701")
        #expect(request.storeNumber == "1234")
        #expect(request.channel == "APP")
        #expect(request.subchannel == "IOS")
        #expect(request.mobilePhone == "+1234567890")
        #expect(request.emailAddress == "ava@example.com")
        #expect(request.alternativePhone == "+1987654321")
        #expect(request.reCaptchaToken == "token-123")
        #expect(request.overrideConfig?.enhancedPresentment == true)
        #expect(request.customerAcceptedOffer == true)
        #expect(request.mockResponse == "success")
    }

    @Test
    func rtpsRequestBuilderBuildsLookupBranchWithPrescreenIdOnly() {
        let merchant = MerchantConfiguration(
            buyer: BreadPartnersBuyer(givenName: "Ava", familyName: "Miller"),
            channel: "APP",
            subchannel: "IOS"
        )

        let rtpsData = RTPSData(
            locationType: .checkout,
            screenName: "Checkout",
            prescreenId: 777,
            customerAcceptedOffer: false,
            mockResponse: .noHit
        )

        let request = RTPSRequestBuilder(
            merchantConfiguration: merchant,
            rtpsData: rtpsData,
            reCaptchaToken: "token-ignored"
        ).build()

        #expect(request.prescreenId == "777")
        #expect(request.firstName == nil)
        #expect(request.lastName == nil)
        #expect(request.address1 == nil)
        #expect(request.city == nil)
        #expect(request.state == nil)
        #expect(request.zip == nil)
        #expect(request.mobilePhone == nil)
        #expect(request.emailAddress == nil)
        #expect(request.alternativePhone == nil)
        #expect(request.reCaptchaToken == nil)
        #expect(request.channel == "APP")
        #expect(request.subchannel == "IOS")
        #expect(request.overrideConfig?.enhancedPresentment == true)
        #expect(request.customerAcceptedOffer == false)
        #expect(request.mockResponse == "noHit")
    }

    @Test
    func prescreenResultMappingHandlesKnownCodes() {
        #expect(getPrescreenResult(from: "0") == .accountFound)
        #expect(getPrescreenResult(from: "01") == .approved)
        #expect(getPrescreenResult(from: "10") == .noHit)
        #expect(getPrescreenResult(from: "11") == .makeOffer)
        #expect(getPrescreenResult(from: "12") == .acknowledge)
    }

    @Test
    func prescreenResultMappingFallsBackToNoHitForUnknownCode() {
        #expect(getPrescreenResult(from: "999") == .noHit)
        #expect(getPrescreenResult(from: "") == .noHit)
    }

    @Test
    func rtpsResponseDecodesReturnCodeFromIntAndString() throws {
        let intData = """
        {
          "returnCode": 0,
          "prescreenId": 123
        }
        """.data(using: .utf8)!

        let stringData = """
        {
          "returnCode": "01",
          "prescreenId": 456
        }
        """.data(using: .utf8)!

        let intDecoded = try JSONDecoder().decode(RTPSResponse.self, from: intData)
        let stringDecoded = try JSONDecoder().decode(RTPSResponse.self, from: stringData)

        #expect(intDecoded.returnCode == "0")
        #expect(intDecoded.prescreenId == 123)
        #expect(stringDecoded.returnCode == "01")
        #expect(stringDecoded.prescreenId == 456)
    }

    @Test
    func rtpsResponseUpdatesMerchantConfigurationWithBuyerAndAddress() throws {
        let data = """
        {
          "firstName": "Chris",
          "middleInitial": "A",
          "lastName": "Pine",
          "address1": "10 Street",
          "address2": "Unit 5",
          "city": "Dallas",
          "state": "TX",
          "zip": "75001"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(RTPSResponse.self, from: data)
        let updated = response.updateMerchantConfiguration(MerchantConfiguration())

        #expect(updated.buyer?.givenName == "Chris")
        #expect(updated.buyer?.additionalName == "A")
        #expect(updated.buyer?.familyName == "Pine")
        #expect(updated.buyer?.billingAddress?.address1 == "10 Street")
        #expect(updated.buyer?.billingAddress?.address2 == "Unit 5")
        #expect(updated.buyer?.billingAddress?.locality == "Dallas")
        #expect(updated.buyer?.billingAddress?.region == "TX")
        #expect(updated.buyer?.billingAddress?.postalCode == "75001")
    }

    @Test
    func rtpsResponseUpdatePreservesExistingValuesWhenResponseFieldsAreNil() throws {
        let data = "{}".data(using: .utf8)!
        let response = try JSONDecoder().decode(RTPSResponse.self, from: data)

        let existing = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: "Existing",
                familyName: "User",
                billingAddress: BreadPartnersAddress(
                    address1: "Original",
                    locality: "Austin",
                    region: "TX",
                    postalCode: "78701"
                )
            )
        )

        let updated = response.updateMerchantConfiguration(existing)
        #expect(updated.buyer?.givenName == "Existing")
        #expect(updated.buyer?.familyName == "User")
        #expect(updated.buyer?.billingAddress?.address1 == "Original")
        #expect(updated.buyer?.billingAddress?.locality == "Austin")
    }

    @Test
    func brandConfigDecodingDefaultsAndRecaptchaKeySelection() throws {
        let data = """
        {
          "config": {
            "rsk_UAT_NATIVE_IOS": "uat-key",
            "rsk_STAGE_NATIVE_IOS": "stage-key",
            "rsk_PROD_NATIVE_IOS": "prod-key"
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(BrandConfigResponse.self, from: data)
        #expect(decoded.config.AEMContent == "")
        #expect(decoded.config.clientName == "")
        #expect(decoded.config.getRecaptchaKey(for: .uat) == "uat-key")
        #expect(decoded.config.getRecaptchaKey(for: .stage) == "stage-key")
        #expect(decoded.config.getRecaptchaKey(for: .prod) == "prod-key")
    }

    @Test
    func placementRequestBuilderBuildsBrandIdAndPlacementId() {
        let placement = PlacementData(locationType: .product, placementId: "pid-1")
        let request = PlacementRequestBuilder(
            integrationKey: "brand-id",
            merchantConfiguration: MerchantConfiguration(),
            placementConfig: placement,
            environment: .stage
        ).build()

        #expect(request.brandId == "brand-id")
        #expect(request.placements?.count == 1)
        #expect(request.placements?.first?.id == "pid-1")
    }

    @Test
    func placementRequestBuilderNonCheckoutUsesUpqParamsOnly() {
        let merchant = MerchantConfiguration(channel: "APP", subchannel: "IOS")
        let placement = PlacementData(
            locationType: .product,
            placementId: "pid-2",
            allowCheckout: false,
            order: Order(totalPrice: CurrencyValue(currency: "USD", value: 5000))
        )

        let request = PlacementRequestBuilder(
            integrationKey: "brand-id",
            merchantConfiguration: merchant,
            placementConfig: placement,
            environment: .stage
        ).build()

        let context = request.placements?.first?.context
        #expect(context?.ALLOW_CHECKOUT == false)
        #expect(context?.UPQ_PARAMS != nil)
        #expect(context?.UPQ_CHECKOUT_PARAMS == nil)
        #expect(context?.UPQ_PARAMS?.contains("clientKey=brand-id") == true)
    }

    @Test
    func placementRequestBuilderCheckoutUsesUpqCheckoutParamsOnly() {
        let merchant = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                shippingAddress: BreadPartnersAddress(
                    address1: "10 Street",
                    locality: "Austin",
                    region: "TX",
                    postalCode: "78701"
                )
            )
        )
        let placement = PlacementData(
            locationType: .checkout,
            placementId: "pid-3",
            allowCheckout: true,
            order: Order(totalPrice: CurrencyValue(currency: "USD", value: 5000)),
            upqInSessionToken: "session-1",
            financingBuyerId: "buyer-1",
            prequalificationId: "prequal-1",
            prequalCreditLimit: "10000"
        )

        let request = PlacementRequestBuilder(
            integrationKey: "brand-id",
            merchantConfiguration: merchant,
            placementConfig: placement,
            environment: .stage
        ).build()

        let context = request.placements?.first?.context
        #expect(context?.ALLOW_CHECKOUT == true)
        #expect(context?.UPQ_CHECKOUT_PARAMS != nil)
        #expect(context?.UPQ_PARAMS == nil)
        #expect(context?.UPQ_CHECKOUT_PARAMS?.contains("clientKey=brand-id") == true)
        #expect(context?.UPQ_CHECKOUT_PARAMS?.contains("prequalificationId") == true)
    }

    @Test
    func placementRequestBuilderDefaultsChannelAndSubchannelWhenMerchantMissing() {
        let placement = PlacementData(locationType: .product, placementId: "pid-4")
        let request = PlacementRequestBuilder(
            integrationKey: "brand-id",
            merchantConfiguration: nil,
            placementConfig: placement,
            environment: .stage
        ).build()

        let context = request.placements?.first?.context
        #expect(context?.channel == BreadPartnersLocationType.product.channelCode)
        #expect(context?.subchannel == "X")
    }

    @Test
    func placementRequestBuilderPropagatesMerchantContextFields() {
        let merchant = MerchantConfiguration(
            loyaltyID: "LOY-1",
            campaignID: "CMP-1",
            storeNumber: "9999",
            departmentId: "D-1",
            cardholderTier: "gold",
            channel: "APP",
            subchannel: "IOS",
            overrideKey: "OVR-1",
            clientVariable1: "cv1",
            clientVariable2: "cv2",
            clientVariable3: "cv3",
            clientVariable4: "cv4"
        )
        let placement = PlacementData(locationType: .product, placementId: "pid-5")

        let request = PlacementRequestBuilder(
            integrationKey: "brand-id",
            merchantConfiguration: merchant,
            placementConfig: placement,
            environment: .stage
        ).build()

        let context = request.placements?.first?.context
        #expect(context?.LOYALTY_ID == "LOY-1")
        #expect(context?.CMP == "CMP-1")
        #expect(context?.STORE_NUMBER == "9999")
        #expect(context?.DEPARTMENT_ID == "D-1")
        #expect(context?.CARDHOLDER_TIER == "gold")
        #expect(context?.OVERRIDE_KEY == "OVR-1")
        #expect(context?.CLIENT_VAR_1 == "cv1")
        #expect(context?.CLIENT_VAR_2 == "cv2")
        #expect(context?.CLIENT_VAR_3 == "cv3")
        #expect(context?.CLIENT_VAR_4 == "cv4")
    }

    @Test
    func htmlParserActionAndOverlayMappingHandlesKnownAndUnknownValues() {
        let parser = HTMLContentParser()

        #expect(parser.handleActionType(from: "SHOW_OVERLAY") == .showOverlay)
        #expect(parser.handleActionType(from: "NO_ACTION") == .noAction)
        #expect(parser.handleActionType(from: "UNMAPPED") == nil)

        #expect(parser.handleOverlayType(from: "EMBEDDED_OVERLAY") == .embeddedOverlay)
        #expect(parser.handleOverlayType(from: "SINGLE_PRODUCT_OVERLAY") == .singleProductOverlay)
        #expect(parser.handleOverlayType(from: "UNMAPPED") == nil)
    }

    @Test
    func htmlParserExtractsTextPlacementModelCoreFields() async throws {
        let html = """
        <div class=\"ep-text-placement\" data-action-type=\"SHOW_OVERLAY\" data-action-target=\"primary\" data-action-content-id=\"cid-1\">
          <div class=\"epjs-body\">Pay over time <span class=\"epjs-body-action\"><a>Learn More</a></span></div>
        </div>
        """

        let model = try await HTMLContentParser().extractTextPlacementModel(htmlContent: html)
        #expect(model?.actionType == "SHOW_OVERLAY")
        #expect(model?.actionTarget == "primary")
        #expect(model?.actionContentId == "cid-1")
        #expect(model?.actionLink == "Learn More")
        #expect(model?.contentText?.contains("Pay over time") == true)
        #expect(model?.htmlContent?.contains("epjs-body") == true)
    }

    @Test
    func htmlParserTextPlacementReturnsNilLikeFieldsWhenAttributesMissing() async throws {
        let html = "<div class=\"ep-text-placement\"><div class=\"epjs-body\">Only content</div></div>"

        let model = try await HTMLContentParser().extractTextPlacementModel(htmlContent: html)
        #expect(model?.actionType == nil)
        #expect(model?.actionTarget == nil)
        #expect(model?.actionContentId == nil)
        #expect(model?.actionLink == nil)
        #expect(model?.contentText?.contains("Only content") == true)
    }

    @Test
    func htmlParserExtractsPopupPlacementCoreFields() async throws {
        let html = """
        <div data-overlay-metadata data-overlay-type=\"EMBEDDED_OVERLAY\"></div>
        <div class=\"brand logo\"><img src=\"https://img.example/logo.png\"/></div>
        <iframe src=\"https://example.com/embedded\"></iframe>
        <div class=\"epjs-css-overlay-title\"><b>Title</b></div>
        <div class=\"epjs-css-overlay-subtitle\">Subtitle</div>
        <div class=\"epjs-css-overlay-body-title-bar\">Heading</div>
        <div class=\"epjs-css-overlay-header\">Header</div>
        <div class=\"epjs-css-overlay-disclosures\"><i>Disclosure</i></div>
        <div class=\"epjs-css-modal-footer\" data-overlay-type=\"EMBEDDED_OVERLAY\"></div>
        <button class=\"action-button\" data-content-fetch=\"true\" data-action-target=\"modal\" data-action-type=\"SHOW_OVERLAY\" data-action-content-id=\"cta-1\" data-location=\"footer\"><span>Continue</span></button>
        <div class=\"epjs-css-overlay-body-content\"></div>
        """

        let model = try await HTMLContentParser().extractPopupPlacementModel(from: html)
        #expect(model?.overlayType == "EMBEDDED_OVERLAY")
        #expect(model?.brandLogoUrl == "https://img.example/logo.png")
        #expect(model?.webViewUrl == "https://example.com/embedded")
        #expect(model?.overlayTitle.string.contains("Title") == true)
        #expect(model?.disclosure.string.contains("Disclosure") == true)
        #expect(model?.disclosureHTML.contains("Disclosure") == true)
        #expect(model?.primaryActionButtonAttributes?.buttonText == "Continue")
        #expect(model?.primaryActionButtonAttributes?.dataActionType == "SHOW_OVERLAY")
    }

    @Test
    func htmlParserBuildsDynamicBodyContentSections() async throws {
        let html = """
        <div class=\"epjs-css-overlay-body-content\">
          <div>
            <div class=\"epjs-css-overlay-value-prop\"><h3>Value prop</h3><p>Details</p></div>
            <div class=\"epjs-css-overlay-value-prop-connector\">AND</div>
            <div class=\"epjs-css-overlay-body-footer\"><p>Footer text</p></div>
          </div>
        </div>
        """

        let model = try await HTMLContentParser().extractPopupPlacementModel(from: html)
        let body = model?.dynamicBodyModel.bodyDiv

        #expect(body?["div0"] != nil)
        #expect(body?["footer0"] != nil)
    }

    @MainActor
    @Test
    func htmlRendererCreateSpannableTextAppendsClickableLink() {
        let renderer = HTMLContentRenderer(
            integrationKey: "brand",
            merchantConfiguration: nil,
            placementsConfiguration: nil,
            brandConfiguration: nil,
            logger: Logger(),
            callback: { _ in }
        )

        let attributed = renderer.createSpannableText(text: "Pay over time ", linkText: "Learn More")
        let fullText = attributed.string
        #expect(fullText == "Pay over time Learn More")

        let range = (fullText as NSString).range(of: "Learn More")
        let linkValue = attributed.attribute(.link, at: range.location, effectiveRange: nil) as? String
        #expect(linkValue == "Learn More")
    }

    @MainActor
    @Test
    func htmlRendererCreatePlainTextViewUsesContentTextAndDefault() {
        let renderer = HTMLContentRenderer(
            integrationKey: "brand",
            merchantConfiguration: nil,
            placementsConfiguration: nil,
            brandConfiguration: nil,
            logger: Logger(),
            callback: { _ in }
        )

        renderer.textPlacementModel = TextPlacementModel(
            actionType: nil,
            actionTarget: nil,
            contentText: "Sample text",
            actionLink: nil,
            actionContentId: nil,
            htmlContent: nil
        )
        #expect(renderer.createPlainTextView().text == "Sample text")

        renderer.textPlacementModel = nil
        #expect(renderer.createPlainTextView().text == "N/A")
    }

    @MainActor
    @Test
    func htmlRendererCreateActionButtonFallsBackToContentText() {
        let renderer = HTMLContentRenderer(
            integrationKey: "brand",
            merchantConfiguration: nil,
            placementsConfiguration: nil,
            brandConfiguration: nil,
            logger: Logger(),
            callback: { _ in }
        )

        renderer.textPlacementModel = TextPlacementModel(
            actionType: nil,
            actionTarget: nil,
            contentText: "Apply Now",
            actionLink: nil,
            actionContentId: nil,
            htmlContent: nil
        )

        let button = renderer.createActionButton()
        #expect(button.title(for: .normal) == "Apply Now")
        #expect(button.accessibilityIdentifier == "Apply Now")
    }

    @MainActor
    @Test
    func htmlRendererRenderTextAndButtonEmitsUIKitEvent() {
        var renderedText: String?
        var renderedButtonTitle: String?

        let renderer = HTMLContentRenderer(
            integrationKey: "brand",
            merchantConfiguration: nil,
            placementsConfiguration: nil,
            brandConfiguration: nil,
            splitTextAndAction: true,
            forSwiftUI: false,
            logger: Logger(),
            callback: { event in
                if case .renderSeparateTextAndButton(let textView, let button) = event {
                    renderedText = textView.text
                    renderedButtonTitle = button.title(for: .normal)
                }
            }
        )

        renderer.textPlacementModel = TextPlacementModel(
            actionType: nil,
            actionTarget: nil,
            contentText: "Pay over time",
            actionLink: "Learn More",
            actionContentId: nil,
            htmlContent: nil
        )

        renderer.renderTextAndButton()

        #expect(renderedText == "Pay over time")
        #expect(renderedButtonTitle == "Learn More")
    }

    @MainActor
    @Test
    func htmlRendererHandleLinkInteractionNoActionAndInvalidActionEmitExpectedEvents() async {
        var textClickedCount = 0
        var sdkErrorMessages: [String] = []

        let renderer = HTMLContentRenderer(
            integrationKey: "brand",
            merchantConfiguration: nil,
            placementsConfiguration: nil,
            brandConfiguration: nil,
            logger: Logger(),
            callback: { event in
                switch event {
                case .textClicked:
                    textClickedCount += 1
                case .sdkError(let error):
                    sdkErrorMessages.append(error.localizedDescription)
                default:
                    break
                }
            }
        )

        renderer.responseModel = PlacementsResponse(placements: nil, placementContent: nil)

        renderer.textPlacementModel = TextPlacementModel(
            actionType: "NO_ACTION",
            actionTarget: nil,
            contentText: "Text",
            actionLink: nil,
            actionContentId: nil,
            htmlContent: nil
        )
        await renderer.handleLinkInteraction(link: "")

        renderer.textPlacementModel = TextPlacementModel(
            actionType: "NOT_A_REAL_ACTION",
            actionTarget: nil,
            contentText: "Text",
            actionLink: nil,
            actionContentId: nil,
            htmlContent: nil
        )
        await renderer.handleLinkInteraction(link: "")

        #expect(textClickedCount == 1)
        #expect(sdkErrorMessages.contains { $0.contains(Constants.noTextPlacementError) })
    }

        @Test
        func placementsResponseDecodesNestedPlacementAndContent() throws {
                let data = """
                {
                    "placements": [
                        {
                            "id": "p1",
                            "content": { "contentId": "c-ref-1" },
                            "renderContext": { "LOCATION": "checkout" }
                        }
                    ],
                    "placementContent": [
                        {
                            "id": "c1",
                            "contentType": "HTML",
                            "contentData": { "htmlContent": "<div>Hello</div>" },
                            "metadata": { "messageId": "m1", "templateId": "t1" }
                        }
                    ]
                }
                """.data(using: .utf8)!

                let decoded = try JSONDecoder().decode(PlacementsResponse.self, from: data)

                #expect(decoded.placements?.first?.id == "p1")
                #expect(decoded.placements?.first?.content?.contentId == "c-ref-1")
                #expect(decoded.placements?.first?.renderContext?.LOCATION == "checkout")
                #expect(decoded.placementContent?.first?.id == "c1")
                #expect(decoded.placementContent?.first?.contentData?.htmlContent == "<div>Hello</div>")
                #expect(decoded.placementContent?.first?.metadata?.messageId == "m1")
        }

        @Test
        func placementsResponseDecodesRenderContextFields() throws {
                let data = """
                {
                    "placements": [
                        {
                            "renderContext": {
                                "LOCATION": "product",
                                "subchannel": "IOS",
                                "RTPS_ID": "r1",
                                "PREQUAL_ID": "pq1",
                                "PRICE": 123,
                                "SDK_TID": "sdk-1",
                                "BUYER_ID": "b-1",
                                "channel": "APP",
                                "PREQUAL_CREDIT_LIMIT": "5000",
                                "ENV": "STAGE",
                                "ALLOW_CHECKOUT": true,
                                "embeddedUrl": "https://example.com/embed"
                            }
                        }
                    ]
                }
                """.data(using: .utf8)!

                let decoded = try JSONDecoder().decode(PlacementsResponse.self, from: data)
                let ctx = decoded.placements?.first?.renderContext

                #expect(ctx?.LOCATION == "product")
                #expect(ctx?.subchannel == "IOS")
                #expect(ctx?.RTPS_ID == "r1")
                #expect(ctx?.PREQUAL_ID == "pq1")
                #expect(ctx?.PRICE == 123)
                #expect(ctx?.SDK_TID == "sdk-1")
                #expect(ctx?.BUYER_ID == "b-1")
                #expect(ctx?.channel == "APP")
                #expect(ctx?.PREQUAL_CREDIT_LIMIT == "5000")
                #expect(ctx?.ENV == "STAGE")
                #expect(ctx?.ALLOW_CHECKOUT == true)
                #expect(ctx?.embeddedUrl == "https://example.com/embed")
        }

        @Test
        func placementsResponseHandlesMissingOptionalNodes() throws {
                let data = "{}".data(using: .utf8)!
                let decoded = try JSONDecoder().decode(PlacementsResponse.self, from: data)

                #expect(decoded.placements == nil)
                #expect(decoded.placementContent == nil)
        }

        @Test
        func contextRequestBodyCopySetsUpqValues() {
                let base = ContextRequestBody(
                        LOCATION: "checkout",
                        STORE_NUMBER: "9999",
                        channel: "APP",
                        subchannel: "IOS",
                        UPQ_PARAMS: "old-upq",
                        UPQ_CHECKOUT_PARAMS: "old-checkout"
                )

                let copied = base.copy(upqParams: "new-upq", upqCheckoutParams: "new-checkout")
                #expect(copied.UPQ_PARAMS == "new-upq")
                #expect(copied.UPQ_CHECKOUT_PARAMS == "new-checkout")
        }

        @Test
        func contextRequestBodyCopyProducesIndependentInstance() {
                let original = ContextRequestBody(UPQ_PARAMS: "a", UPQ_CHECKOUT_PARAMS: "b")
                let copied = original.copy(upqParams: "x", upqCheckoutParams: "y")

                #expect(original.UPQ_PARAMS == "a")
                #expect(original.UPQ_CHECKOUT_PARAMS == "b")
                #expect(copied.UPQ_PARAMS == "x")
                #expect(copied.UPQ_CHECKOUT_PARAMS == "y")
        }

        @Test
        func loggerDebugPrintDoesNotEmitWhenDisabled() {
            let logger = Logger()
            var events: [String] = []
            logger.setCallback { event in
                if case .onSDKEventLog(let logs) = event {
                    events.append(logs)
                }
            }

            logger.debugPrint("hello")
            #expect(events.isEmpty)
        }

        @Test
        func loggerDebugPrintEmitsWhenEnabled() {
            let logger = Logger()
            var events: [String] = []
            logger.setCallback { event in
                if case .onSDKEventLog(let logs) = event {
                    events.append(logs)
                }
            }

            logger.setLogging(enabled: true)
            logger.debugPrint("hello", "world")

            #expect(events.count == 1)
            #expect(events.first?.contains("hello world") == true)
        }

        @Test
        func loggerSetCallbackReplacesPreviousCallback() {
            let logger = Logger()
            var firstCount = 0
            var secondCount = 0

            logger.setLogging(enabled: true)
            logger.setCallback { event in
                if case .onSDKEventLog = event {
                    firstCount += 1
                }
            }
            logger.debugPrint("one")

            logger.setCallback { event in
                if case .onSDKEventLog = event {
                    secondCount += 1
                }
            }
            logger.debugPrint("two")

            #expect(firstCount == 1)
            #expect(secondCount == 1)
        }

        @Test
        func loggerPrintLogRespectsLoggingFlag() {
            let logger = Logger()
            var count = 0
            logger.setCallback { event in
                if case .onSDKEventLog = event {
                    count += 1
                }
            }

            logger.printLog("no-op")
            #expect(count == 0)

            logger.setLogging(enabled: true)
            logger.printLog("emit")
            #expect(count == 1)
        }

        @Test
        func loggerLogRequestDetailsIncludesMethodAndUrl() {
            let logger = Logger()
            var lastLog = ""
            logger.setLogging(enabled: true)
            logger.setCallback { event in
                if case .onSDKEventLog(let logs) = event {
                    lastLog = logs
                }
            }

            logger.logRequestDetails(
                url: URL(string: "https://example.com/path")!,
                method: "POST",
                headers: ["A": "B"],
                body: try? JSONSerialization.data(withJSONObject: ["k": "v"])
            )

            #expect(lastLog.contains("Request Details"))
            #expect(lastLog.contains("https://example.com/path"))
            #expect(lastLog.contains("Method  : POST"))
            #expect(lastLog.contains("A: B"))
        }

        @Test
        func loggerLogRequestDetailsHandlesNoBody() {
            let logger = Logger()
            var lastLog = ""
            logger.setLogging(enabled: true)
            logger.setCallback { event in
                if case .onSDKEventLog(let logs) = event {
                    lastLog = logs
                }
            }

            logger.logRequestDetails(
                url: URL(string: "https://example.com/no-body")!,
                method: "GET",
                headers: nil,
                body: nil
            )

            #expect(lastLog.contains("Method  : GET"))
            #expect(lastLog.contains("Body    : No Body"))
        }

        @Test
        func loggerLogResponseDetailsIncludesStatusAndBody() {
            let logger = Logger()
            var lastLog = ""
            logger.setLogging(enabled: true)
            logger.setCallback { event in
                if case .onSDKEventLog(let logs) = event {
                    lastLog = logs
                }
            }

            let data = "{\"ok\":true}".data(using: .utf8)
            logger.logResponseDetails(
                url: URL(string: "https://example.com/resp")!,
                statusCode: 201,
                headers: ["X": "Y"],
                body: data
            )

            #expect(lastLog.contains("Response Details"))
            #expect(lastLog.contains("Status Code : 201"))
            #expect(lastLog.contains("https://example.com/resp"))
            #expect(lastLog.contains("\"ok\""))
        }

        @Test
        func loggerLogTextPlacementModelDetailsIncludesModelFields() {
            let logger = Logger()
            var lastLog = ""
            logger.setLogging(enabled: true)
            logger.setCallback { event in
                if case .onSDKEventLog(let logs) = event {
                    lastLog = logs
                }
            }

            let model = TextPlacementModel(
                actionType: "SHOW_OVERLAY",
                actionTarget: "primary",
                contentText: "Pay over time",
                actionLink: "Learn More",
                actionContentId: "cid-1",
                htmlContent: "<div>content</div>"
            )
            logger.logTextPlacementModelDetails(model)

            #expect(lastLog.contains("Text Placement Model Details"))
            #expect(lastLog.contains("SHOW_OVERLAY"))
            #expect(lastLog.contains("Pay over time"))
            #expect(lastLog.contains("cid-1"))
        }

        @Test
        func loggerLogPopupPlacementModelDetailsIncludesPrimaryActionAndDynamicBody() {
            let logger = Logger()
            var lastLog = ""
            logger.setLogging(enabled: true)
            logger.setCallback { event in
                if case .onSDKEventLog(let logs) = event {
                    lastLog = logs
                }
            }

            let popup = PopupPlacementModel(
                overlayType: "EMBEDDED_OVERLAY",
                location: "checkout",
                brandLogoUrl: "https://img.example/logo.png",
                webViewUrl: "https://example.com/wv",
                overlayTitle: NSAttributedString(string: "Title"),
                overlaySubtitle: NSAttributedString(string: "Subtitle"),
                overlayContainerBarHeading: NSAttributedString(string: "Heading"),
                bodyHeader: NSAttributedString(string: "Body"),
                primaryActionButtonAttributes: PrimaryActionButtonModel(
                    dataOverlayType: "EMBEDDED_OVERLAY",
                    dataContentFetch: "true",
                    dataActionTarget: "modal",
                    dataActionType: "SHOW_OVERLAY",
                    dataActionContentId: "cta-1",
                    dataLocation: "footer",
                    buttonText: "Continue"
                ),
                dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(
                    bodyDiv: [
                        "div0": PopupPlacementModel.DynamicBodyContent(tagValuePairs: ["p": "Details"])
                    ]
                ),
                disclosure: NSAttributedString(string: "Disclosure"),
                disclosureHTML: "<i>Disclosure</i>"
            )

            logger.logPopupPlacementModelDetails(popup)

            #expect(lastLog.contains("Popup Placement Model Details"))
            #expect(lastLog.contains("Primary Action Button Details"))
            #expect(lastLog.contains("Continue"))
            #expect(lastLog.contains("Dynamic Body Model Details"))
        }

        @Test
        func loggerLogPopupPlacementModelDetailsHandlesEmptyDynamicBody() {
            let logger = Logger()
            var lastLog = ""
            logger.setLogging(enabled: true)
            logger.setCallback { event in
                if case .onSDKEventLog(let logs) = event {
                    lastLog = logs
                }
            }

            let popup = PopupPlacementModel(
                overlayType: "SINGLE_PRODUCT_OVERLAY",
                location: nil,
                brandLogoUrl: "",
                webViewUrl: "",
                overlayTitle: NSAttributedString(string: ""),
                overlaySubtitle: NSAttributedString(string: ""),
                overlayContainerBarHeading: NSAttributedString(string: ""),
                bodyHeader: NSAttributedString(string: ""),
                primaryActionButtonAttributes: nil,
                dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(bodyDiv: [:]),
                disclosure: NSAttributedString(string: ""),
                disclosureHTML: ""
            )

            logger.logPopupPlacementModelDetails(popup)
            #expect(lastLog.contains("Dynamic Body Model: N/A"))
        }

    @Test
    func apiClientRequestThrowsInvalidUrlError() async {
        let client = APIClient(logger: Logger())

        do {
            _ = try await client.request(urlString: "ht!tp://bad")
            Issue.record("Expected InvalidURL error")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "InvalidURL")
            #expect(nsError.code == 400)
            #expect(nsError.localizedDescription == "The URL provided is invalid.")
        }
    }

    @Test
    func apiClientRequestThrowsSerializationErrorForUnsupportedBody() async {
        final class NotEncodable {}
        let client = APIClient(logger: Logger())

        do {
            _ = try await client.request(
                urlString: "https://example.com",
                body: NotEncodable()
            )
            Issue.record("Expected SerializationError")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "SerializationError")
            #expect(nsError.code == 500)
        }
    }

    @Test
    func apiClientRequestThrowsSerializationErrorForUnsupportedAnySendableBody() async {
        final class NotEncodable {}
        let client = APIClient(logger: Logger())

        do {
            _ = try await client.request(
                urlString: "https://example.com",
                body: AnySendable(value: NotEncodable())
            )
            Issue.record("Expected SerializationError")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "SerializationError")
            #expect(nsError.code == 500)
        }
    }

    @Test
    func httpMethodRawValuesAreStable() {
        #expect(HTTPMethod.GET.rawValue == "GET")
        #expect(HTTPMethod.POST.rawValue == "POST")
        #expect(HTTPMethod.PUT.rawValue == "PUT")
        #expect(HTTPMethod.DELETE.rawValue == "DELETE")
        #expect(HTTPMethod.OPTIONS.rawValue == "OPTIONS")
    }

    @Test
    func anySendablePreservesWrappedValue() {
        let wrappedInt = AnySendable(value: 42)
        let wrappedDict = AnySendable(value: ["k": "v"])

        #expect((wrappedInt.value as? Int) == 42)
        #expect((wrappedDict.value as? [String: String])?["k"] == "v")
    }

    @Test
    func constantsStringHelpersReturnExpectedMessages() {
        #expect(Constants.nativeSDKAlertTitle() == "Bread Partner")
        #expect(Constants.catchError(message: "boom") == "Error: boom")
        #expect(Constants.apiError(message: "x") == "Error: x")
        #expect(Constants.securityCheckAlertFailedMessage(error: "oops") == "Error: oops")
        #expect(Constants.unableToLoadWebURL(message: "timeout") == "Error: Web Url Loading Issue: timeout")
    }

    @Test
    func analyticsPayloadEncodesAndDecodesRoundTrip() throws {
        let payload = Analytics.Payload(
            name: "view-placement",
            props: Analytics.Props(
                eventProperties: Analytics.EventProperties(
                    placement: Analytics.Placement(id: "p1", placementContentId: "c1", overlayContentId: "o1"),
                    placementContent: Analytics.PlacementContent(
                        id: "c1",
                        contentType: "HTML",
                        metadata: MetadataModel(placementId: "p1", productType: "CARD", messageId: "m1", templateId: "t1")
                    ),
                    metadata: ["location": "checkout"],
                    actionTarget: "modal"
                ),
                userProperties: ["user": "abc"]
            ),
            context: Analytics.Context(
                timestamp: "2026-08-10T10:00:00.000Z",
                apiKey: "api-key",
                browserCtx: Analytics.BrowserCtx(
                    library: Analytics.Library(name: "bread-partners-sdk-ios", version: "0.0.1"),
                    userAgent: "iPhone: iOS 18.3.1",
                    page: Analytics.Page(path: "ToDo", url: "https://example.com")
                ),
                trackingInfo: Analytics.TrackingInfo(userTrackingId: "u1", sessionTrackingId: "s1")
            )
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(Analytics.Payload.self, from: data)

        #expect(decoded.name == "view-placement")
        #expect(decoded.props?.eventProperties?.placement?.id == "p1")
        #expect(decoded.context?.apiKey == "api-key")
        #expect(decoded.context?.trackingInfo?.sessionTrackingId == "s1")
    }

    @Test
    func analyticsModelsSupportNilOptionalsOnDecode() throws {
        let data = """
        {
          "name": "click-placement",
          "props": {},
          "context": {}
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Analytics.Payload.self, from: data)
        #expect(decoded.name == "click-placement")
        #expect(decoded.props?.eventProperties == nil)
        #expect(decoded.context?.browserCtx == nil)
    }

    @Test
    func apiClientRequestWithInvalidUrlRetainsMessageContract() async {
        let client = APIClient(logger: Logger())
        do {
            _ = try await client.request(urlString: "ht!tp://bad")
            Issue.record("Expected InvalidURL error")
        } catch {
            #expect((error as NSError).localizedDescription.contains("invalid"))
        }
    }

    @Test
    func constantsApiHeaderValuesRemainStable() {
        #expect(Constants.headerContentTypeValue == "application/json")
        #expect(Constants.headerOriginValue == "https://brand-sdk.kmsmep.com")
        #expect(Constants.headerPlatformValue == "ios")
        #expect(Constants.headerAcceptValue == "*/*")
    }

    @Test
    func popupTextStyleDefaultUsesGrayColor() {
        let style = PopupTextStyle()
        #expect(style.font == nil)
        #expect(style.textColor.cgColor == BreadPartnerDefaults.GRAY_COLOR.cgColor)
    }

    @Test
    func popupTextStyleStoresCustomFontAndColor() {
        let font = UIFont.systemFont(ofSize: 15)
        let style = PopupTextStyle(font: font, textColor: .red)
        #expect(style.font?.pointSize == 15)
        #expect(style.textColor.cgColor == UIColor.red.cgColor)
    }

    @Test
    func popupActionButtonStyleStoresProvidedValues() {
        let style = PopupActionButtonStyle(
            font: UIFont.boldSystemFont(ofSize: 14),
            textColor: .white,
            backgroundColor: .black,
            cornerRadius: 9,
            padding: UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
        )
        #expect(style.font?.pointSize == 14)
        #expect(style.textColor.map { $0.cgColor == UIColor.white.cgColor } == true)
        #expect(style.backgroundColor.map { $0.cgColor == UIColor.black.cgColor } == true)
        #expect(style.cornerRadius == 9)
        #expect(style.padding?.left == 2)
    }

    @Test
    func popUpStylingDefaultValuesArePopulated() {
        let style = PopUpStyling()
        #expect(style.loaderColor.cgColor == UIColor.black.cgColor)
        #expect(style.crossColor.cgColor == UIColor.black.cgColor)
        #expect(style.backgroundColor.cgColor == UIColor.white.cgColor)
        #expect(style.actionButtonStyle == nil)
    }

    @Test
    func popUpStylingCustomActionButtonStyleIsRetained() {
        let actionStyle = PopupActionButtonStyle(cornerRadius: 12)
        let style = PopUpStyling(actionButtonStyle: actionStyle)
        #expect(style.actionButtonStyle?.cornerRadius == 12)
    }

    @Test
    func breadPartnerDefaultsPopupStyleContainsActionStyle() {
        #expect(BreadPartnerDefaults.popupStyle.actionButtonStyle != nil)
        #expect(BreadPartnerDefaults.popupStyle.actionButtonStyle?.cornerRadius == 8.0)
    }

    @Test
    func breadPartnerDefaultsSuperscriptScaleIsExpected() {
        #expect(BreadPartnerDefaults.SUPERSCRIPT_TEXT_SCALE == 0.75)
    }

    @Test
    func confirmNavigationConstantsAreStable() {
        #expect(Constants.confirmNavigationTitle == "Confirm Navigation")
        #expect(Constants.confirmNavigationStayButton == "Stay")
        #expect(Constants.confirmNavigationLeaveButton == "Leave")
        #expect(Constants.confirmNavigationMessage.contains("navigate away"))
    }

    @Test
    func offerResponseRawValueRoundTripWorks() {
        #expect(OfferResponse(rawValue: "YES") == .yes)
        #expect(OfferResponse(rawValue: "NO") == .no)
        #expect(OfferResponse(rawValue: "NOT_ME") == .notMe)
        #expect(OfferResponse(rawValue: "ABANDONED") == .abandoned)
        #expect(OfferResponse(rawValue: "PRESCREEN_NO") == .prescreenNo)
    }

    @Test
    func offerResponseUnknownRawValueReturnsNil() {
        #expect(OfferResponse(rawValue: "UNKNOWN") == nil)
    }

    @MainActor
    @Test
    func breadPartnerLinkTextDefaultsAfterInit() {
        let view = BreadPartnerLinkText()
        #expect(view.isEditable == false)
        #expect(view.isScrollEnabled == false)
        #expect(view.isSelectable == true)
        #expect(view.dataDetectorTypes.contains(.link))
    }

    @MainActor
    @Test
    func breadPartnerLinkTextConfigureWithLinkDisablesTapWithoutLink() {
        let view = BreadPartnerLinkText()
        let attributed = NSAttributedString(
            string: "Learn More",
            attributes: [.link: "https://example.com"]
        )
        view.configure(with: attributed)
        let flag = mirrorValue(view, key: "allowTapWithoutLink", as: Bool.self)
        #expect(flag == false)
    }

    @MainActor
    @Test
    func breadPartnerLinkTextConfigureWithoutLinkEnablesTapWithoutLink() {
        let view = BreadPartnerLinkText()
        view.configure(with: NSAttributedString(string: "No link"))
        let flag = mirrorValue(view, key: "allowTapWithoutLink", as: Bool.self)
        #expect(flag == true)
    }

    @MainActor
    @Test
    func breadPartnerLinkTextConfigureStoresTapHandler() {
        let view = BreadPartnerLinkText()
        view.configure(with: NSAttributedString(string: "x"), tapHandler: { _ in })
        let tapHandlerChild = Mirror(reflecting: view).children.first(where: { $0.label == "tapHandler" })
        let hasHandler = tapHandlerChild.map { !Mirror(reflecting: $0.value).children.isEmpty } ?? false
        #expect(hasHandler)
    }

    @Test
    func breadPartnerButtonViewDefaultStateIsStable() {
        let view = BreadPartnerButtonView("Continue") {}
        #expect(mirrorValue(view, key: "title", as: String.self) == "Continue")
        #expect(mirrorValue(view, key: "cornerRadius", as: CGFloat.self) == 8.0)
        #expect(mirrorValue(view, key: "padding", as: CGFloat.self) == 8.0)
    }

    @Test
    func breadPartnerButtonViewFluentModifiersUpdateCopy() {
        let updated = BreadPartnerButtonView("Continue") {}
            .cornerRadius(15)
            .padding(20)
            .alignment(.leading)

        #expect(mirrorValue(updated, key: "cornerRadius", as: CGFloat.self) == 15)
        #expect(mirrorValue(updated, key: "padding", as: CGFloat.self) == 20)
        #expect(mirrorValue(updated, key: "alignment", as: Alignment.self) != nil)
    }

    @Test
    func breadPartnerButtonViewFluentModifiersDoNotMutateOriginal() {
        let original = BreadPartnerButtonView("Continue") {}
        let _ = original.cornerRadius(99)
        #expect(mirrorValue(original, key: "cornerRadius", as: CGFloat.self) == 8.0)
    }

    @Test
    func breadPartnerTextViewDefaultStateIsStable() {
        let view = BreadPartnerTextView("Hello")
        #expect(mirrorValue(view, key: "text", as: String.self) == "Hello")
        #expect(mirrorValue(view, key: "padding", as: CGFloat.self) == 8.0)
    }

    @Test
    func breadPartnerTextViewFluentModifiersUpdateCopy() {
        let updated = BreadPartnerTextView("Hello")
            .padding(16)
            .alignment(.center)

        #expect(mirrorValue(updated, key: "padding", as: CGFloat.self) == 16)
        let alignmentDescription = String(describing: mirrorValue(updated, key: "alignment", as: TextAlignment.self) ?? .leading)
        #expect(alignmentDescription.contains("center"))
    }

    @Test
    func breadPartnerTextViewFluentModifiersDoNotMutateOriginal() {
        let original = BreadPartnerTextView("Hello")
        let _ = original.padding(100)
        #expect(mirrorValue(original, key: "padding", as: CGFloat.self) == 8.0)
    }

    @Test
    func breadPartnerLinkTextSwiftUiStoresAttributedInitData() {
        let attributed = NSAttributedString(string: "HTML")
        let view = BreadPartnerLinkTextSwitUI(attributedString: attributed)
        #expect(mirrorValue(view, key: "text", as: String.self) == "HTML")
        #expect(mirrorValue(view, key: "attributedText", as: NSAttributedString?.self)??.string == "HTML")
    }

    @Test
    func breadPartnerLinkTextSwiftUiModifierUpdates() {
        let view = BreadPartnerLinkTextSwitUI("Learn", links: ["Learn"])
            .linkColor(.red)
            .linkFont("HelveticaNeue", fontSize: 14)
        #expect(mirrorValue(view, key: "linkFontName", as: String.self) == "HelveticaNeue")
        #expect(mirrorValue(view, key: "linkFontSize", as: CGFloat.self) == 14)
    }

    @MainActor
    @Test
    func loaderIndicatorCreatesEightBallLayers() {
        let style = PopUpStyling(loaderColor: .green)
        let placementConfig = PlacementConfiguration(popUpStyling: style)
        let loader = LoaderIndicator(frame: CGRect(x: 0, y: 0, width: 200, height: 200), placementsConfiguration: placementConfig)
        let layers = mirrorValue(loader, key: "ballLayers", as: [CALayer].self) ?? []
        #expect(layers.count == 8)
    }

    @MainActor
    @Test
    func loaderIndicatorStopAnimatingHidesAllBalls() {
        let placementConfig = PlacementConfiguration(popUpStyling: PopUpStyling(loaderColor: .green))
        let loader = LoaderIndicator(frame: CGRect(x: 0, y: 0, width: 200, height: 200), placementsConfiguration: placementConfig)
        loader.stopAnimating()
        let layers = mirrorValue(loader, key: "ballLayers", as: [CALayer].self) ?? []
        #expect(layers.allSatisfy { $0.isHidden })
    }

    @MainActor
    @Test
    func loaderIndicatorStartAnimatingShowsAllBalls() {
        let placementConfig = PlacementConfiguration(popUpStyling: PopUpStyling(loaderColor: .green))
        let loader = LoaderIndicator(frame: CGRect(x: 0, y: 0, width: 200, height: 200), placementsConfiguration: placementConfig)
        loader.stopAnimating()
        loader.startAnimating()
        let layers = mirrorValue(loader, key: "ballLayers", as: [CALayer].self) ?? []
        #expect(layers.allSatisfy { !$0.isHidden })
    }

    @MainActor
    @Test
    func loaderIndicatorAddsRotationAnimationOnStart() {
        let placementConfig = PlacementConfiguration(popUpStyling: PopUpStyling(loaderColor: .green))
        let loader = LoaderIndicator(frame: CGRect(x: 0, y: 0, width: 200, height: 200), placementsConfiguration: placementConfig)
        loader.startAnimating()
        #expect(loader.layer.animation(forKey: "rotation") != nil)
    }

    @MainActor
    @Test
    func loaderIndicatorUsesConfiguredLoaderColor() {
        let placementConfig = PlacementConfiguration(popUpStyling: PopUpStyling(loaderColor: .magenta))
        let loader = LoaderIndicator(frame: CGRect(x: 0, y: 0, width: 200, height: 200), placementsConfiguration: placementConfig)
        let layers = mirrorValue(loader, key: "ballLayers", as: [CALayer].self) ?? []
        #expect(layers.first?.backgroundColor != nil)
        #expect(layers.first?.backgroundColor == UIColor.magenta.cgColor)
    }

    @MainActor
    @Test
    func loaderIndicatorStopAnimatingRemovesBallAnimations() {
        let placementConfig = PlacementConfiguration(popUpStyling: PopUpStyling(loaderColor: .green))
        let loader = LoaderIndicator(frame: CGRect(x: 0, y: 0, width: 200, height: 200), placementsConfiguration: placementConfig)
        loader.stopAnimating()
        let layers = mirrorValue(loader, key: "ballLayers", as: [CALayer].self) ?? []
        #expect(layers.allSatisfy { ($0.animationKeys() ?? []).isEmpty })
    }

    @MainActor
    @Test
    func loaderIndicatorStartStopStartCycleRemainsStable() {
        let placementConfig = PlacementConfiguration(popUpStyling: PopUpStyling(loaderColor: .green))
        let loader = LoaderIndicator(frame: CGRect(x: 0, y: 0, width: 200, height: 200), placementsConfiguration: placementConfig)
        loader.stopAnimating()
        loader.startAnimating()
        loader.stopAnimating()
        loader.startAnimating()
        let layers = mirrorValue(loader, key: "ballLayers", as: [CALayer].self) ?? []
        #expect(layers.count == 8)
    }

    @MainActor
    @Test
    func loaderIndicatorFrameIsRetained() {
        let frame = CGRect(x: 10, y: 20, width: 120, height: 140)
        let placementConfig = PlacementConfiguration(popUpStyling: PopUpStyling(loaderColor: .green))
        let loader = LoaderIndicator(frame: frame, placementsConfiguration: placementConfig)
        #expect(loader.frame == frame)
    }

    @MainActor
    @Test
    func loaderIndicatorStopAnimatingIsIdempotent() {
        let placementConfig = PlacementConfiguration(popUpStyling: PopUpStyling(loaderColor: .green))
        let loader = LoaderIndicator(frame: CGRect(x: 0, y: 0, width: 200, height: 200), placementsConfiguration: placementConfig)
        loader.stopAnimating()
        loader.stopAnimating()
        let layers = mirrorValue(loader, key: "ballLayers", as: [CALayer].self) ?? []
        #expect(layers.allSatisfy { $0.isHidden })
    }

    @MainActor
    @Test
    func loaderIndicatorStartAnimatingIsIdempotent() {
        let placementConfig = PlacementConfiguration(popUpStyling: PopUpStyling(loaderColor: .green))
        let loader = LoaderIndicator(frame: CGRect(x: 0, y: 0, width: 200, height: 200), placementsConfiguration: placementConfig)
        loader.startAnimating()
        loader.startAnimating()
        let layers = mirrorValue(loader, key: "ballLayers", as: [CALayer].self) ?? []
        #expect(layers.allSatisfy { !$0.isHidden })
    }

    @MainActor
    @Test
    func webViewInterstitialCreateWebViewSetsDelegates() {
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { _ in })
        let webView = interstitial.createWebView(with: URL(string: "https://example.com")!)
        #expect(webView.navigationDelegate != nil)
        #expect(webView.uiDelegate != nil)
    }

    @MainActor
    @Test
    func webViewInterstitialInjectAnchorScriptHandlesNilView() {
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { _ in })
        interstitial.injectAnchorInterceptorScript(view: nil)
        #expect(true)
    }

    @MainActor
    @Test
    func webViewInterstitialOnAppRestartClickedForwardsUrl() {
        final class Listener: AppRestartListener {
            var captured: String?
            func onAppRestartClicked(url: String) { captured = url }
        }
        let listener = Listener()
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { _ in })
        interstitial.appRestartListener = listener
        interstitial.onAppRestartClicked(url: "https://restart")
        #expect(listener.captured == "https://restart")
    }

    @MainActor
    @Test
    func webViewInterstitialDidFailInvokesCompletionOnce() {
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { _ in })
        var count = 0
        interstitial.onPageLoadCompleted = { _ in count += 1 }
        let webView = WKWebView(frame: .zero)
        interstitial.webView(webView, didFail: nil, withError: NSError(domain: "x", code: 1))
        interstitial.webView(webView, didFail: nil, withError: NSError(domain: "x", code: 2))
        #expect(count == 1)
    }

    @MainActor
    @Test
    func webViewInterstitialDidFinishWithoutUrlDoesNotInvokeCompletion() {
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { _ in })
        var count = 0
        interstitial.onPageLoadCompleted = { _ in count += 1 }
        let webView = WKWebView(frame: .zero)
        interstitial.webView(webView, didFinish: nil)
        #expect(count == 0)
    }

    @Test
    @MainActor
    func webViewInterstitialLoadPageResumesSuccess() async throws {
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { _ in })
        let webView = WKWebView(frame: .zero)

        let task = Task { try await interstitial.loadPage(for: webView) }
        for _ in 0..<50 {
            if interstitial.onPageLoadCompleted != nil { break }
            await Task.yield()
        }
        let expectedURL = URL(string: "https://example.com/success")!
        interstitial.onPageLoadCompleted?(.success(expectedURL))
        let result = try await task.value
        #expect(result == expectedURL)
    }

    @Test
    @MainActor
    func webViewInterstitialLoadPageResumesFailure() async {
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { _ in })
        let webView = WKWebView(frame: .zero)

        let task = Task { try await interstitial.loadPage(for: webView) }
        for _ in 0..<50 {
            if interstitial.onPageLoadCompleted != nil { break }
            await Task.yield()
        }
        interstitial.onPageLoadCompleted?(.failure(NSError(domain: "TestError", code: 9)))

        do {
            _ = try await task.value
            Issue.record("Expected loadPage to throw")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "TestError")
            #expect(nsError.code == 9)
        }
    }

    @MainActor
    @Test
    func webViewMessageLogOutOrRestartSetsPendingFlag() {
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { _ in })
        #expect(interstitial.pendingLogOutOrRestart == false)

        interstitial.userContentController(
            WKUserContentController(),
            didReceive: makeScriptMessage(body: makeActionBody(type: "LOG_OUT_OR_RESTART"))
        )

        #expect(interstitial.pendingLogOutOrRestart == true)
    }

    @MainActor
    @Test
    func webViewMessageAppRestartForwardsPayloadToListener() {
        final class Listener: AppRestartListener {
            var captured: String?
            func onAppRestartClicked(url: String) { captured = url }
        }

        let listener = Listener()
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { _ in })
        interstitial.appRestartListener = listener

        interstitial.userContentController(
            WKUserContentController(),
            didReceive: makeScriptMessage(body: makeActionBody(type: "APP_RESTART", payload: "https://restart.local"))
        )

        #expect(listener.captured == "https://restart.local")
    }

    @MainActor
    @Test
    func webViewMessageViewPageEmitsScreenName() {
        var captured: String?
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { event in
            if case .screenName(let name) = event {
                captured = name
            }
        })

        interstitial.userContentController(
            WKUserContentController(),
            didReceive: makeScriptMessage(
                body: makeActionBody(type: "VIEW_PAGE", payload: ["pageName": "approval-page"])
            )
        )

        #expect(captured == "approval-page")
    }

    @MainActor
    @Test
    func webViewMessageCancelApplicationEmitsPopupClosed() {
        var popupClosedCount = 0
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { event in
            if case .popupClosed = event {
                popupClosedCount += 1
            }
        })

        interstitial.userContentController(
            WKUserContentController(),
            didReceive: makeScriptMessage(body: makeActionBody(type: "CANCEL_APPLICATION"))
        )

        #expect(popupClosedCount == 1)
    }

    @MainActor
    @Test
    func webViewMessageSubmitPrequalApplicationEmitsEvent() {
        var submitCount = 0
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { event in
            if case .submitPrequalApplication = event {
                submitCount += 1
            }
        })

        interstitial.userContentController(
            WKUserContentController(),
            didReceive: makeScriptMessage(body: makeActionBody(type: "SUBMIT_PREQUAL_APPLICATION"))
        )

        #expect(submitCount == 1)
    }

    @MainActor
    @Test
    func webViewMessageApplicationCompletedEmitsExpectedSequence() {
        var screenName: String?
        var completedCount = 0
        var popupClosedCount = 0
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { event in
            switch event {
            case .screenName(let name):
                screenName = name
            case .applicationCompleted:
                completedCount += 1
            case .popupClosed:
                popupClosedCount += 1
            default:
                break
            }
        })

        interstitial.userContentController(
            WKUserContentController(),
            didReceive: makeScriptMessage(body: makeActionBody(type: "APPLICATION_COMPLETED"))
        )

        #expect(screenName == "application-completed")
        #expect(completedCount == 1)
        #expect(popupClosedCount == 1)
    }

    @MainActor
    @Test
    func webViewMessageOfferResponseNoEmitsClose() {
        var response: OfferResponse?
        var popupClosedCount = 0
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { event in
            switch event {
            case .offerResponse(let value):
                response = value
            case .popupClosed:
                popupClosedCount += 1
            default:
                break
            }
        })

        interstitial.userContentController(
            WKUserContentController(),
            didReceive: makeScriptMessage(body: makeActionBody(type: "OFFER_RESPONSE", payload: "NO"))
        )

        #expect(response == .no)
        #expect(popupClosedCount == 1)
    }

    @MainActor
    @Test
    func webViewMessageOfferResponseYesDoesNotEmitClose() {
        var response: OfferResponse?
        var popupClosedCount = 0
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { event in
            switch event {
            case .offerResponse(let value):
                response = value
            case .popupClosed:
                popupClosedCount += 1
            default:
                break
            }
        })

        interstitial.userContentController(
            WKUserContentController(),
            didReceive: makeScriptMessage(body: makeActionBody(type: "OFFER_RESPONSE", payload: "YES"))
        )

        #expect(response == .yes)
        #expect(popupClosedCount == 0)
    }

    @MainActor
    @Test
    func webViewMessageUnifiedOffersReceivedEmitsBothSuccessAndUnifiedEvents() {
        var successCount = 0
        var unifiedCount = 0
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { event in
            switch event {
            case .webViewSuccess:
                successCount += 1
            case .unifiedOffersReceived:
                unifiedCount += 1
            default:
                break
            }
        })

        interstitial.userContentController(
            WKUserContentController(),
            didReceive: makeScriptMessage(
                body: makeActionBody(type: "UNIFIED_OFFERS_RECEIVED", payload: ["applicationId": "upq-1"])
            )
        )

        #expect(successCount == 1)
        #expect(unifiedCount == 1)
    }

    @MainActor
    @Test
    func webViewMessageUnifiedCheckoutResultEmitsThreeCallbacks() {
        var successCount = 0
        var unifiedCheckoutCount = 0
        var popupClosedCount = 0
        let interstitial = BreadFinancialWebViewInterstitial(logger: Logger(), callback: { event in
            switch event {
            case .webViewSuccess:
                successCount += 1
            case .receiveUnifiedCheckoutApplicationResult:
                unifiedCheckoutCount += 1
            case .popupClosed:
                popupClosedCount += 1
            default:
                break
            }
        })

        interstitial.userContentController(
            WKUserContentController(),
            didReceive: makeScriptMessage(
                body: makeActionBody(type: "RECEIVE_UNIFIED_CHECKOUT_APPLICATION_RESULT", payload: ["decision": "approved"])
            )
        )

        #expect(successCount == 1)
        #expect(unifiedCheckoutCount == 1)
        #expect(popupClosedCount == 1)
    }

    @Test
    func locationChannelMapContainsExpectedSpecialCases() {
        #expect(BreadPartnersLocationType.bag.channelCode == "2")
        #expect(BreadPartnersLocationType.dashboard.channelCode == "5")
        #expect(BreadPartnersLocationType.myaccount.channelCode == "5")
    }

    @Test
    func financingTypeAllCasesAreStable() {
        let cases = BreadPartnersFinancingType.allCases
        #expect(cases.contains(.card))
        #expect(cases.contains(.installments))
        #expect(cases.contains(.versatile))
        #expect(cases.count == 3)
    }

    @Test
    func nameAndAddressModelsStoreCustomValues() {
        let name = Name(givenName: "A", familyName: "B", additionalName: "C")
        let address = Address(address1: "1", address2: "2", locality: "City", postalCode: "000", region: "ST", country: "US")
        #expect(name.givenName == "A")
        #expect(name.familyName == "B")
        #expect(name.additionalName == "C")
        #expect(address.address1 == "1")
        #expect(address.address2 == "2")
        #expect(address.locality == "City")
        #expect(address.postalCode == "000")
        #expect(address.region == "ST")
        #expect(address.country == "US")
    }

    @Test
    func pickupInformationStoresNestedNameAndAddress() {
        let pickup = PickupInformation(
            name: Name(givenName: "Sam", familyName: "Lee"),
            phone: "111",
            address: Address(address1: "Main"),
            email: "a@b.com"
        )
        #expect(pickup.name?.givenName == "Sam")
        #expect(pickup.name?.familyName == "Lee")
        #expect(pickup.phone == "111")
        #expect(pickup.address?.address1 == "Main")
        #expect(pickup.email == "a@b.com")
    }

    @Test
    func itemModelStoresShippingAndFulfillmentFields() {
        let item = Item(
            category: "furniture",
            sku: "sku-1",
            shippingProvider: "UPS",
            shippingDescription: "Ground",
            shippingTrackingNumber: "T1",
            shippingTrackingUrl: "https://carrier",
            fulfillmentType: .delivery
        )
        #expect(item.category == "furniture")
        #expect(item.sku == "sku-1")
        #expect(item.shippingProvider == "UPS")
        #expect(item.shippingDescription == "Ground")
        #expect(item.shippingTrackingNumber == "T1")
        #expect(item.shippingTrackingUrl == "https://carrier")
        #expect(item.fulfillmentType == .delivery)
    }

    @Test
    func orderModelStoresDiscountAndTotals() {
        let order = Order(
            subTotal: CurrencyValue(value: 100),
            totalDiscounts: CurrencyValue(value: 10),
            totalPrice: CurrencyValue(value: 90),
            totalShipping: CurrencyValue(value: 5),
            totalTax: CurrencyValue(value: 8),
            discountCode: "SAVE10",
            bnplEligible: true
        )
        #expect(order.subTotal?.value == 100)
        #expect(order.totalDiscounts?.value == 10)
        #expect(order.totalPrice?.value == 90)
        #expect(order.totalShipping?.value == 5)
        #expect(order.totalTax?.value == 8)
        #expect(order.discountCode == "SAVE10")
        #expect(order.bnplEligible == true)
    }
}
