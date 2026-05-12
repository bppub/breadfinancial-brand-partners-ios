// ------------------------------------------------------------------------------
//  File:          PlacementApiExtension.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
// ------------------------------------------------------------------------------

extension BreadPartnersSDK {
    /// Retrieve brand-specific configurations, such as the Recaptcha key.
    func fetchBrandConfig(logger: Logger) async {
        let apiUrl = APIUrl(urlType: .brandConfig(brandId: integrationKey)).url

        do {
            let response = try await APIClient(logger: logger).request(
                urlString: apiUrl, method: .GET, body: nil)
            brandConfiguration = try await CommonUtils().decodeJSON(
                from: response, to: BrandConfigResponse.self)
            return
        } catch {}
    }

    /// This method is called to fetch placement data,
    /// which will be displayed as a text view with a clickable button in the brand partner's UI.
    func fetchPlacementData(
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        splitTextAndAction: Bool = false,
        openPlacementExperience: Bool = false,
        forSwiftUI: Bool = false,
        logger: Logger,
        cookie: String? = nil,
        callback: @Sendable @escaping (
            BreadPartnerEvents
        ) -> Void
    ) async {
        do {
            let apiUrl = APIUrl(urlType: .generatePlacements).url
            var request: Any? = nil

            let builder = await PlacementRequestBuilder(
                integrationKey: integrationKey,
                merchantConfiguration: merchantConfiguration,
                placementConfig: placementsConfiguration.placementData,
                environment: APIUrl.currentEnvironment)
            request = builder.build()

            let response = try await APIClient(logger: logger).request(
                urlString: apiUrl,
                method: .POST,
                cookies: cookie,
                body: request)
            
            await handlePlacementResponse(
                response,
                merchantConfiguration: merchantConfiguration,
                placementsConfiguration: placementsConfiguration,
                splitTextAndAction: splitTextAndAction,
                openPlacementExperience: openPlacementExperience,
                forSwiftUI: forSwiftUI,
                logger: logger,
                callback: callback)
        } catch let error as NSError {
            if error.domain == Constants.incapsulaChallenge {
                guard let htmlContent = error.userInfo[Constants.htmlContent] as? String,
                      let url = error.userInfo[Constants.url] as? String else {
                    return callback(.sdkError(error: error))
                }

                let challengeController = ChallengeController(
                    htmlContent: htmlContent,
                    originalURL: url,
                    onComplete: { cookie in
                        Task {
                            await self.fetchPlacementData(
                                merchantConfiguration: merchantConfiguration,
                                placementsConfiguration: placementsConfiguration,
                                splitTextAndAction: splitTextAndAction,
                                openPlacementExperience: openPlacementExperience,
                                forSwiftUI: forSwiftUI,
                                logger: logger,
                                cookie: cookie,
                                callback: callback
                            )
                        }
                    },
                    logger: logger
                )


                return callback(.renderPopupView(view: challengeController))
            } else {
                return callback(
                    .sdkError(
                        error: NSError(
                            domain: "", code: 500,
                            userInfo: [
                                NSLocalizedDescriptionKey: Constants.apiError(
                                    message: error.localizedDescription)
                            ])))
            }
        }
    }

    internal func handlePlacementResponse(
        _ response: Any,
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        splitTextAndAction: Bool = false,
        openPlacementExperience: Bool = false,
        forSwiftUI: Bool = false,
        logger: Logger,
        callback: @Sendable @escaping (
            BreadPartnerEvents
        ) -> Void
    ) async {
        do {
            let responseModel: PlacementsResponse =
                try await CommonUtils().decodeJSON(
                    from: response,
                    to: PlacementsResponse.self)

            /// Opens the overlay automatically to simulate user behavior of manually tapping the placement.
            if openPlacementExperience {
                let responseModel: PlacementsResponse =
                    try await CommonUtils().decodeJSON(
                        from: response, to: PlacementsResponse.self)
                guard
                    let popupPlacementHTMLContent = responseModel
                        .placementContent?
                        .first(where: { $0.metadata?.templateId?.contains("overlay") == true }),

                    let popupPlacementModel = try await HTMLContentParser()
                        .extractPopupPlacementModel(
                            from: popupPlacementHTMLContent
                                .contentData?
                                .htmlContent
                                ?? ""
                    )
                else {
                    return callback(
                        .sdkError(
                            error: NSError(
                                domain: "", code: 500,
                                userInfo: [
                                    NSLocalizedDescriptionKey: Constants
                                        .popupPlacementParsingError
                                ])))
                }

                await HTMLContentRenderer(
                    integrationKey: integrationKey,
                    merchantConfiguration: merchantConfiguration,
                    placementsConfiguration: placementsConfiguration,
                    brandConfiguration: brandConfiguration,
                    splitTextAndAction: splitTextAndAction,
                    forSwiftUI: forSwiftUI,
                    logger: logger,
                    callback: callback
                ).createPopupOverlay(
                    popupPlacementModel: popupPlacementModel,
                    overlayType: PlacementOverlayType(rawValue: popupPlacementModel.overlayType) ?? .singleProductOverlay
                )

            } else {
                /// Handles the text placement UI that will be rendered on the brand partner's app screen
                /// for manual tap behavior.
                await HTMLContentRenderer(
                    integrationKey: integrationKey,
                    merchantConfiguration: merchantConfiguration,
                    placementsConfiguration: placementsConfiguration,
                    brandConfiguration: brandConfiguration,
                    splitTextAndAction: splitTextAndAction,
                    forSwiftUI: forSwiftUI,
                    logger: logger,
                    callback: callback
                ).handleTextPlacement(
                    responseModel: responseModel
                )
            }

        } catch {
            return callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.apiError(
                                message: error.localizedDescription)
                        ])))
        }
    }
}
