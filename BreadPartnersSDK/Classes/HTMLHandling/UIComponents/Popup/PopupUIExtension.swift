//------------------------------------------------------------------------------
//  File:          PopupUIExtension.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import UIKit

extension PopupController {

    /// Sets up the user interface for the popup.
    func setupUI() async {
        await setupPopupView()

        switch overlayType {
        case .embeddedOverlay:
            await setupEmbeddedOverlay()
        case .singleProductOverlay:
            await setupSingleProductOverlay()
        }

        if overlayType == .singleProductOverlay {
            await fetchWebViewPlacement()
        }
    }

    func setupPopupView() async {
        await MainActor.run {
            view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
          
            guard let popupStyle = placementsConfiguration?.popUpStyling else{
                return
            }

            popupView = PopupElements.shared.createContainerView(
                backgroundColor: .white)

            topRowView = UIView()
            topRowView.translatesAutoresizingMaskIntoConstraints = false

            bottomRowView = UIView()
            bottomRowView.translatesAutoresizingMaskIntoConstraints = false

            closeButton = PopupElements.shared.addCloseButton(
                target: self, color: popupStyle.crossColor,
                action: #selector(closeButtonTapped))
            dividerTop = PopupElements.shared.createHorizontalDivider(
                color: popupStyle.dividerColor)
            dividerBottom = PopupElements.shared.createHorizontalDivider(
                color: popupStyle.dividerColor)
            titleLabel = PopupElements.shared.createLabel(
                withText: popupModel.overlayTitle,
                style: popupStyle.titlePopupTextStyle)
            subtitleLabel = PopupElements.shared.createLabel(
                withText: popupModel.overlaySubtitle,
                style: popupStyle.subTitlePopupTextStyle)
            disclosureTextView = PopupElements.shared.createDisclosureTextView(
                withText: popupModel.disclosure,
                rawHTML: popupModel.disclosureHTML,
                style: popupStyle.disclosurePopupTextStyle,
                delegate: self)

            dynamicParentProductView = PopupElements.shared.createContainerView(
                backgroundColor: popupStyle.backgroundColor, borderColor: popupStyle.borderColor,
                borderWidth: 1.0, cornerRadius: 8.0)
            dynamicParentProductView.translatesAutoresizingMaskIntoConstraints =
                false

            headerLabel = PopupElements.shared.createLabel(
                withText: popupModel.overlayContainerBarHeading,
                style: popupStyle.headerPopupTextStyle)
            headerView = UIView()
            headerView.translatesAutoresizingMaskIntoConstraints = false
            headerView.backgroundColor = popupStyle.headerBgColor

            if headerLabel.text?.isEmpty ?? true {
                headerView.isHidden = true
            }
            dynamicChildProductView = PopupElements.shared.createStackView(
                axis: .vertical, spacing: 10)

            actionButton = PopupElements.shared.createButton(
                target: self,
                title: popupModel.primaryActionButtonAttributes?.buttonText
                    ?? "Action",
                buttonStyle: placementsConfiguration?.popUpStyling?.actionButtonStyle,
                action: #selector(actionButtonTapped))

            view.addSubview(popupView)

            brandLogo = UIImageView()
            brandLogo.translatesAutoresizingMaskIntoConstraints = false
            brandLogo.contentMode = .scaleAspectFit
            brandLogo.clipsToBounds = true
            brandLogo.setContentHuggingPriority(.defaultHigh, for: .vertical)
            brandLogo.setContentHuggingPriority(.defaultHigh, for: .horizontal)

            overlayProductView = UIView()
            overlayProductView.translatesAutoresizingMaskIntoConstraints = false

            overlayEmbeddedView = UIView()
            overlayEmbeddedView.translatesAutoresizingMaskIntoConstraints =
                false

            if let imageURL = URL(string: popupModel.brandLogoUrl) {
                brandLogo.loadImage(from: imageURL) { success in
                    if success {} else {}
                }
            }
            scrollView = UIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false

            topRowView.addSubview(closeButton)
            topRowView.addSubview(brandLogo)
            topRowView.addSubview(dividerTop)

            popupView.addSubview(topRowView)

            addSectionsToStackView(popupStyle: popupStyle)
        }
    }

    private func setupEmbeddedOverlay() async {
        guard let webViewURL = URL(string: popupModel.webViewUrl) else {
            return callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                Constants
                                .unableToLoadWebURL(
                                    message: popupModel.webViewUrl)
                        ])))
            return
        }

        await MainActor.run {
            popupView.addSubview(overlayEmbeddedView)
            webViewManager = BreadFinancialWebViewInterstitial(logger: logger) {
                [weak self] event in
                self?.handleWebViewEvent(event: event)
            }
            webViewManager.appRestartListener = self
            
            webView = webViewManager.createWebView(with: webViewURL)
            webView.translatesAutoresizingMaskIntoConstraints = false
            overlayEmbeddedView.addSubview(webView)

            applyConstraints()
            overlayEmbeddedConstraints()
        }

        do {
            await MainActor.run { loader?.startAnimating() }
            let loadedURL = try await webViewManager.loadPage(for: webView)
            logger.printLog("Loaded URL: \(loadedURL)")
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

        await MainActor.run { loader?.stopAnimating() }
    }

    private func setupSingleProductOverlay() async {
        await MainActor.run {

            popupView.addSubview(scrollView)
            popupView.addSubview(bottomRowView)

            scrollView.addSubview(overlayProductView)

            overlayProductView.addSubview(titleLabel)
            overlayProductView.addSubview(subtitleLabel)
            overlayProductView.addSubview(dynamicParentProductView)
            overlayProductView.addSubview(disclosureTextView)

            dynamicParentProductView.addSubview(headerView)
            dynamicParentProductView.addSubview(dynamicChildProductView)

            headerView.addSubview(headerLabel)

            bottomRowView.addSubview(dividerBottom)
            bottomRowView.addSubview(actionButton)

            applyConstraints()
            overlayProductConstraints()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let loader = self.loader {
                    loader.stopAnimating()
                }
            }
        }
    }

    func setupLoader() {
        DispatchQueue.main.async {
            self.loader = LoaderIndicator(
                frame: CGRect(
                    x: self.popupView.bounds.maxX * 0.45,
                    y: self.popupView.bounds.maxY * 0.45,
                    width: 50,
                    height: 50),
                placementsConfiguration: self.placementsConfiguration!
            )
            self.popupView.addSubview(self.loader)
        }
    }
    func applyConstraints() {
        NSLayoutConstraint.activate([

            popupView.centerXAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            popupView.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            popupView.widthAnchor.constraint(
                equalTo: view.widthAnchor, multiplier: popupWidth),
            popupView.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                constant: -UIScreen.main.bounds.size.height * popupHeight),

            topRowView.topAnchor.constraint(equalTo: popupView.topAnchor),
            topRowView.leadingAnchor.constraint(
                equalTo: popupView.leadingAnchor),
            topRowView.trailingAnchor.constraint(
                equalTo: popupView.trailingAnchor),

            closeButton.trailingAnchor.constraint(
                equalTo: topRowView.trailingAnchor,
                constant: -paddingHorizontalTen),
            closeButton.topAnchor.constraint(
                equalTo: topRowView.topAnchor, constant: 25),

            brandLogo.leadingAnchor.constraint(
                equalTo: topRowView.leadingAnchor,
                constant: paddingHorizontalTen),
            brandLogo.topAnchor.constraint(
                equalTo: topRowView.topAnchor, constant: paddingVerticalTen),
            brandLogo.heightAnchor.constraint(equalToConstant: brandLogoHeight),
            brandLogo.widthAnchor.constraint(lessThanOrEqualToConstant: 150),

            dividerTop.topAnchor.constraint(
                equalTo: brandLogo.bottomAnchor, constant: paddingVerticalTen),
            dividerTop.leadingAnchor.constraint(
                equalTo: topRowView.leadingAnchor),
            dividerTop.trailingAnchor.constraint(
                equalTo: topRowView.trailingAnchor),
            dividerTop.heightAnchor.constraint(equalToConstant: 1),
            dividerTop.bottomAnchor.constraint(
                equalTo: topRowView.bottomAnchor),

        ])
    }

    func overlayProductConstraints() {
        if !dynamicParentProductView.isHidden {

            NSLayoutConstraint.activate([
                dynamicParentProductView.topAnchor.constraint(
                    equalTo: subtitleLabel.bottomAnchor,
                    constant: paddingHorizontalTwenty),
                dynamicParentProductView.leadingAnchor.constraint(
                    equalTo: overlayProductView.leadingAnchor,
                    constant: paddingHorizontalTwenty),
                dynamicParentProductView.trailingAnchor.constraint(
                    equalTo: overlayProductView.trailingAnchor,
                    constant: -paddingHorizontalTwenty),
                dynamicParentProductView.bottomAnchor.constraint(
                    equalTo: dynamicChildProductView.bottomAnchor,
                    constant: paddingHorizontalTwenty),

                headerLabel.centerXAnchor.constraint(
                    equalTo: headerView.centerXAnchor),
                headerLabel.centerYAnchor.constraint(
                    equalTo: headerView.centerYAnchor),
                headerLabel.leadingAnchor.constraint(
                    equalTo: headerView.leadingAnchor, constant: 10),
                headerLabel.trailingAnchor.constraint(
                    equalTo: headerView.trailingAnchor, constant: -10),

                headerView.topAnchor.constraint(
                    equalTo: dynamicParentProductView.topAnchor),
                headerView.leadingAnchor.constraint(
                    equalTo: dynamicParentProductView.leadingAnchor),
                headerView.trailingAnchor.constraint(
                    equalTo: dynamicParentProductView.trailingAnchor),
                headerView.heightAnchor.constraint(
                    greaterThanOrEqualTo: headerLabel.heightAnchor, constant: 30
                ),

                dynamicChildProductView.topAnchor.constraint(
                    equalTo: headerView.bottomAnchor,
                    constant: paddingHorizontalTen
                ),
                dynamicChildProductView.leadingAnchor.constraint(
                    equalTo: dynamicParentProductView.leadingAnchor,
                    constant: paddingHorizontalTen),
                dynamicChildProductView.trailingAnchor.constraint(
                    equalTo: dynamicParentProductView.trailingAnchor,
                    constant: -paddingHorizontalTen),

                disclosureTextView.topAnchor.constraint(
                    equalTo: dynamicParentProductView.bottomAnchor,
                    constant: paddingVerticalFive),
            ])
        } else {
            NSLayoutConstraint.activate([
                disclosureTextView.topAnchor.constraint(
                    equalTo: subtitleLabel.bottomAnchor,
                    constant: paddingVerticalFive)
            ])
        }
        NSLayoutConstraint.activate([

            scrollView.topAnchor.constraint(equalTo: topRowView.bottomAnchor),
            scrollView.leadingAnchor.constraint(
                equalTo: popupView.leadingAnchor),
            scrollView.trailingAnchor.constraint(
                equalTo: popupView.trailingAnchor),
            scrollView.bottomAnchor.constraint(
                equalTo: dividerBottom.topAnchor),

            overlayProductView.topAnchor.constraint(
                equalTo: scrollView.topAnchor),
            overlayProductView.leadingAnchor.constraint(
                equalTo: scrollView.leadingAnchor),
            overlayProductView.trailingAnchor.constraint(
                equalTo: scrollView.trailingAnchor),
            overlayProductView.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor),
            overlayProductView.widthAnchor.constraint(
                equalTo: scrollView.widthAnchor),

            titleLabel.topAnchor.constraint(
                equalTo: overlayProductView.topAnchor,
                constant: paddingVerticalTen),
            titleLabel.leadingAnchor.constraint(
                equalTo: overlayProductView.leadingAnchor,
                constant: paddingHorizontalTwenty),
            titleLabel.trailingAnchor.constraint(
                equalTo: overlayProductView.trailingAnchor,
                constant: -paddingHorizontalTwenty),

            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: paddingVerticalTen),
            subtitleLabel.leadingAnchor.constraint(
                equalTo: overlayProductView.leadingAnchor,
                constant: paddingHorizontalTwenty),
            subtitleLabel.trailingAnchor.constraint(
                equalTo: overlayProductView.trailingAnchor,
                constant: -paddingHorizontalTwenty),

            disclosureTextView.trailingAnchor.constraint(
                equalTo: popupView.trailingAnchor,
                constant: -paddingHorizontalTwenty),
            disclosureTextView.leadingAnchor.constraint(
                equalTo: overlayProductView.leadingAnchor,
                constant: paddingHorizontalTwenty),
            disclosureTextView.bottomAnchor.constraint(
                equalTo: overlayProductView.bottomAnchor,
                constant: -paddingVerticalTen),

            bottomRowView.topAnchor.constraint(
                equalTo: scrollView.bottomAnchor),
            bottomRowView.leadingAnchor.constraint(
                equalTo: popupView.leadingAnchor),
            bottomRowView.trailingAnchor.constraint(
                equalTo: popupView.trailingAnchor),
            bottomRowView.bottomAnchor.constraint(
                equalTo: popupView.bottomAnchor),

            dividerBottom.topAnchor.constraint(
                equalTo: bottomRowView.topAnchor),
            dividerBottom.leadingAnchor.constraint(
                equalTo: bottomRowView.leadingAnchor),
            dividerBottom.trailingAnchor.constraint(
                equalTo: bottomRowView.trailingAnchor),
            dividerBottom.heightAnchor.constraint(equalToConstant: 1),

            actionButton.topAnchor.constraint(
                equalTo: dividerBottom.bottomAnchor,
                constant: paddingVerticalTen),
            actionButton.bottomAnchor.constraint(
                equalTo: bottomRowView.bottomAnchor,
                constant: -paddingVerticalTwenty),
            actionButton.widthAnchor.constraint(
                greaterThanOrEqualTo: actionButton.titleLabel!.widthAnchor,
                constant: 50),
            actionButton.heightAnchor.constraint(
                greaterThanOrEqualTo: actionButton.titleLabel!.heightAnchor,
                constant: 30),
            actionButton.trailingAnchor.constraint(
                equalTo: bottomRowView.trailingAnchor,
                constant: -paddingHorizontalTen),

        ])

    }

    func overlayEmbeddedConstraints() {
        NSLayoutConstraint.activate([

            overlayEmbeddedView.topAnchor.constraint(
                equalTo: topRowView.bottomAnchor),
            overlayEmbeddedView.leadingAnchor.constraint(
                equalTo: popupView.leadingAnchor),
            overlayEmbeddedView.trailingAnchor.constraint(
                equalTo: popupView.trailingAnchor),
            overlayEmbeddedView.bottomAnchor.constraint(
                equalTo: popupView.bottomAnchor),

            webView.topAnchor.constraint(equalTo: dividerTop.bottomAnchor),
            webView.leadingAnchor.constraint(
                equalTo: overlayEmbeddedView.leadingAnchor,
                constant: paddingHorizontalTen),
            webView.trailingAnchor.constraint(
                equalTo: overlayEmbeddedView.trailingAnchor,
                constant: -paddingHorizontalTen),
            webView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor),
        ])
    }

    func addSectionsToStackView(popupStyle: PopUpStyling) {
        let tagPriorityList = ["h3", "h2", "p", "connector"]
        let bodyDivModel = popupModel.dynamicBodyModel.bodyDiv

        let sortedDictList = bodyDivModel.sorted { (first, second) -> Bool in
            let firstKeyNumber =
                Int(first.key.replacingOccurrences(of: "div", with: "")) ?? 0
            let secondKeyNumber =
                Int(second.key.replacingOccurrences(of: "div", with: "")) ?? 0
            return firstKeyNumber < secondKeyNumber
        }

        for (_, value) in sortedDictList.enumerated() {
            let tagValuePairs = value.value.tagValuePairs

            for tag in tagPriorityList {
                if let content = tagValuePairs[tag],
                    let label = PopupElements.shared.createLabelForTag(
                        tag: tag, value: content, popupStyle: popupStyle)
                {
                    dynamicChildProductView.addArrangedSubview(label)
                }
            }
        }

        let containerFooter = bodyDivModel.first { key, value in
            return key.contains("footer")
        }

        if containerFooter != nil {
            if let label = PopupElements.shared.createLabelForTag(
                tag: "footer",
                value:
                    "\(containerFooter?.value.tagValuePairs.values.first ?? "")",
                popupStyle: popupStyle)
            {
                dynamicChildProductView.addArrangedSubview(label)
            }
        }

        if bodyDivModel.isEmpty {
            dynamicParentProductView.isHidden = true
        } else {
            dynamicParentProductView.isHidden = false
        }
    }

}
