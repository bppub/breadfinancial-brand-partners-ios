//------------------------------------------------------------------------------
//  File:          HTMLContentParser.swift
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
import SwiftSoup

/// Parses HTML content into a SwiftSoup Document.
internal class SwiftSoupParser {
    func parse(_ htmlContent: String) async throws -> Document {
        return try SwiftSoup.parse(htmlContent)
    }
}

/// Actor responsible for extracting structured data from HTML using SwiftSoup.
internal class HTMLContentParser {

    private let htmlParser: SwiftSoupParser

    init(htmlParser: SwiftSoupParser = SwiftSoupParser()) {
        self.htmlParser = htmlParser
    }

    func extractTextPlacementModel(htmlContent: String) async throws
        -> TextPlacementModel?
    {
        let document = try await htmlParser.parse(htmlContent)

        // Extract attributes
        let actionContentId = try document.select("[data-action-content-id]")
            .attr("data-action-content-id")
        let actionTarget = try document.select("[data-action-target]").attr(
            "data-action-target")
        let actionType = try document.select("[data-action-type]").attr(
            "data-action-type")
        
        // Extract HTML content (preserving formatting)
        let htmlContentWithFormatting = try document.select(".ep-text-placement").html()

        // Extract text content
        let actionLink = try document.select(".epjs-body-action a").text()
        let contentText =
            try document.select(".epjs-body").first()?.ownText()
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let paymentDetailsSup = try document.select("sup").text()

        // Extract Payment details
        var paymentDetails = try document.select(".ep-text-placement").text()
        paymentDetails =
            paymentDetails
            .replacingOccurrences(of: actionLink, with: "")
            .replacingOccurrences(of: paymentDetailsSup, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Combine contentText and paymentDetails into finalContentText
        let finalContentText: String = {
            switch (contentText.isEmpty, paymentDetails.isEmpty) {
            case (true, true): return ""
            case (true, false): return paymentDetails + " "
            case (false, true): return contentText + " "
            default:
                return contentText == paymentDetails
                    ? contentText + " "
                    : contentText + " " + paymentDetails + " "
            }
        }()

        return TextPlacementModel(
            actionType: actionType.isEmpty ? nil : actionType,
            actionTarget: actionTarget.isEmpty ? nil : actionTarget,
            contentText: finalContentText.isEmpty ? nil : finalContentText,
            actionLink: actionLink.isEmpty ? nil : actionLink,
            actionContentId: actionContentId.isEmpty ? nil : actionContentId,
            htmlContent: htmlContentWithFormatting.isEmpty ? nil : htmlContentWithFormatting
        )
    }

    func extractPopupPlacementModel(from htmlContent: String) async throws
        -> PopupPlacementModel?
    {
        let document = try SwiftSoup.parse(htmlContent)

        let overlayType =
            try document.select("[data-overlay-metadata]").first()?.attr(
                "data-overlay-type") ?? ""
        let brandLogoUrl =
            try document.select(".brand.logo img").first()?.attr("src") ?? ""
        let webViewUrl =
            try document.select("iframe").first()?.attr("src") ?? ""
        let overlayTitle =
            document.htmlFrom(".epjs-css-overlay-title")
        let overlaySubtitle =
            document.htmlFrom(".epjs-css-overlay-subtitle")
        let overlayContainerBarHeading =
            document.htmlFrom(".epjs-css-overlay-body-title-bar")
        let bodyHeader =
            document.htmlFrom(".epjs-css-overlay-header")
        let disclosure =
            document.htmlFrom(".epjs-css-overlay-disclosures")
        let disclosureHTML =
            (try? document.select(".epjs-css-overlay-disclosures").html()) ?? ""

        let primaryActionButtonAttributes =
            await extractPrimaryCTAButtonAttributes(
                from: document,
                selector: ".action-button"
            )

        let dynamicBodyModel = try await buildDynamicBodyModel(from: document)

        return PopupPlacementModel(
            overlayType: overlayType,
            brandLogoUrl: brandLogoUrl,
            webViewUrl: webViewUrl,
            overlayTitle: overlayTitle,
            overlaySubtitle: overlaySubtitle,
            overlayContainerBarHeading: overlayContainerBarHeading,
            bodyHeader: bodyHeader,
            primaryActionButtonAttributes: primaryActionButtonAttributes,
            dynamicBodyModel: dynamicBodyModel,
            disclosure: disclosure,
            disclosureHTML: disclosureHTML
        )
    }

    func extractPrimaryCTAButtonAttributes(
        from document: Document, selector: String
    ) async -> PrimaryActionButtonModel? {
        guard let button = try? document.select(selector).first() else {
            return nil
        }

        let dataContentFetch = try? button.attr("data-content-fetch")
        let dataActionTarget = try? button.attr("data-action-target")
        let dataActionType = try? button.attr("data-action-type")
        let dataActionContentId = try? button.attr("data-action-content-id")
        let dataLocation = try? button.attr("data-location")
        let buttonText = try? button.select("span").text()
        let overlayType = try? document.select(".epjs-css-modal-footer")
            .first()?.attr("data-overlay-type")

        return PrimaryActionButtonModel(
            dataOverlayType: overlayType,
            dataContentFetch: dataContentFetch,
            dataActionTarget: dataActionTarget,
            dataActionType: dataActionType,
            dataActionContentId: dataActionContentId,
            dataLocation: dataLocation,
            buttonText: buttonText
        )
    }

    func buildDynamicBodyModel(from document: Document) async throws
        -> PopupPlacementModel.DynamicBodyModel
    {
        var dynamicBodyModel = PopupPlacementModel.DynamicBodyModel(bodyDiv: [:]
        )
        guard
            let bodyContainer = try document.select(
                ".epjs-css-overlay-body-content"
            ).first()
        else {
            return dynamicBodyModel
        }

        do {

            var sequenceCounter = 0

            try bodyContainer.children().forEach { mainParent in

                let valueProps = try mainParent.select(
                    ".epjs-css-overlay-value-prop")

                for valueProp in valueProps.array() {
                    let bodyContent = PopupPlacementModel.DynamicBodyContent(
                        tagValuePairs: try valueProp.children()
                            .reduce(into: [:]) { dict, child in
                                dict[child.tagName()] = try child.html()
                            }
                    )
                    dynamicBodyModel.bodyDiv["div\(sequenceCounter)"] =
                        bodyContent
                }

                let connectors = try mainParent.select(
                    ".epjs-css-overlay-value-prop-connector")
                for connector in connectors.array() {
                    let connectorContent =
                        PopupPlacementModel.DynamicBodyContent(
                            tagValuePairs: ["connector": try connector.html()]
                        )
                    dynamicBodyModel.bodyDiv["div\(sequenceCounter)"] =
                        connectorContent
                }

                let footers = try mainParent.select(
                    ".epjs-css-overlay-body-footer")

                for footers in footers.array() {
                    let footers = PopupPlacementModel.DynamicBodyContent(
                        tagValuePairs: try footers.children()
                            .reduce(into: [:]) { dict, child in
                                dict[child.tagName()] = try child.html()
                            }
                    )
                    dynamicBodyModel.bodyDiv["footer\(sequenceCounter)"] =
                        footers
                }
                sequenceCounter += 1
            }
        } catch {
            throw error
        }
        return dynamicBodyModel
    }

    func handleActionType(from response: String) -> PlacementActionType? {
        return PlacementActionType(rawValue: response)
    }

    func handleOverlayType(from response: String) -> PlacementOverlayType? {
        return PlacementOverlayType(rawValue: response)
    }
}
