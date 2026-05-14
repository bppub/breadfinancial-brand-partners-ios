//------------------------------------------------------------------------------
//  File:          PopupAPIExtension.swift
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

extension PopupController {

    /// Fetches the web view placement data asynchronously by constructing a placement request and calling the API.
    func fetchWebViewPlacement() async {
        let builder = PlacementRequestBuilder(
            integrationKey: integrationKey,
            merchantConfiguration: merchantConfiguration,
            placementConfig: placementsConfiguration?.placementData,
            environment: APIUrl.currentEnvironment)
        let placementRequest = builder.build()

        let request = PlacementRequest(
            placements: [
                PlacementRequestBody(
                    id: popupModel.primaryActionButtonAttributes?
                        .dataContentFetch,
                    context: placementRequest.placements?.first?.context
                )
            ],
            brandId: integrationKey
        )

        await fetchData(requestBody: request)
    }

    /// Fetches data asynchronously from the API using the given request body.
    private func fetchData(requestBody: Any) async {
        let apiUrl = APIUrl(urlType: .generatePlacements).url
        do {
            let response = try await APIClient(logger: logger).request(
                urlString: apiUrl, method: .POST, body: requestBody)
            await handleResponse(response)
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

    /// Handles the API response asynchronously by decoding the response data into a PlacementsResponse model.
    private func handleResponse(_ response: Any) async {
        do {
            let responseModel: PlacementsResponse =
                try await CommonUtils().decodeJSON(
                    from: response, to: PlacementsResponse.self)
            guard
                let popupPlacementHTMLContent = responseModel.placementContent?
                    .first,
                let popupPlacementModel = try await HTMLContentParser()
                    .extractPopupPlacementModel(
                        from: popupPlacementHTMLContent.contentData?.htmlContent
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
            self.webViewPlacementModel = popupPlacementModel
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
