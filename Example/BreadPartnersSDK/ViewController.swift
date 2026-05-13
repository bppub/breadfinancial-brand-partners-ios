import BreadPartnersSDK
import UIKit

class ViewController: UIViewController {


    func showYesNoAlert(
        from viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {

        let style: [String: Any] = ["": ""]

        // MARK: For development purposes
        let primaryColor = style["primaryColor"] as! String

        let alertController = UIAlertController(
            title: "Are you authenticated?",
            message: nil,
            preferredStyle: .alert
        )
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            completion(true)
        }
        let noAction = UIAlertAction(title: "No", style: .cancel) { _ in
            completion(false)
        }
        yesAction.setValue(UIColor(hex: primaryColor), forKey: "titleTextColor")
        noAction.setValue(UIColor(hex: primaryColor), forKey: "titleTextColor")

        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        viewController.present(alertController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        generatePlacement()
//        openExperienceFlow()
//        rtpsCall()
    }

    func generatePlacement(){
        // MARK: For development purposes
        // These configurations are used to test different types of placement requests.
        // Each placement type corresponds to a specific configuration that includes parameters
        // like placement ID, SDK transaction ID, environment, price, and brand ID.
        // This allows testing of various placement setups by fetching specific configurations
        // based on the placement type key.
        let placementRequestType: [String: Any] = TestData.shared.placementConfigurations["textPlacementRequestType1"]!
        let placementID = placementRequestType["placementID"] as? String
        let price = (placementRequestType["price"] as? Int)
        let loyaltyId = (placementRequestType["loyaltyId"] as? String)
        let brandId = placementRequestType["brandId"] as? String
        let channel = placementRequestType["channel"] as? String
        let subChannel = placementRequestType["subchannel"] as? String
        let env = placementRequestType["env"] as? BreadPartnersEnvironment
        let location =
            placementRequestType["location"] as? BreadPartnersLocationType
        let financingType =
            placementRequestType["financingType"]
            as? BreadPartnersFinancingType

        // MARK: For development purposes
        let style = TestData.shared.styleStruct["blue"]!
        let primaryColor = style["primaryColor"] as! String
        let lightColor = style["lightColor"] as! String
        let darkColor = style["darkColor"] as! String
        let boxColor = style["boxColor"] as! String
        let blackColor = "#000000"

        let fontFamily = style["fontFamily"] as! String

        let smallTextSize = style["smallTextSize"] as! Int
        let mediumTextSize = style["mediumTextSize"] as! Int
        let largeTextSize = style["largeTextSize"] as! Int
        let xlargeTextSize = style["xlargeTextSize"] as! Int

        let placementData = PlacementData(
            financingType: financingType,
            locationType: location,
            placementId: placementID,
            domID: "123",
            order: Order(
                subTotal: CurrencyValue(currency: "USD", value: 0),
                totalDiscounts: CurrencyValue(currency: "USD", value: 0),
                totalPrice: CurrencyValue(
                    currency: "USD", value: Int(price ?? 0)),
                totalShipping: CurrencyValue(currency: "USD", value: 0),
                totalTax: CurrencyValue(currency: "USD", value: 0),
                discountCode: "string",
                pickupInformation: PickupInformation(
                    name: Name(
                        givenName: "John",
                        familyName: "Doe"),
                    phone: "+14539842345",
                    address: Address(
                        address1: "156 5th Avenue",
                        locality: "New York",
                        postalCode: "10019",
                        region: "US-NY",
                        country: "US"),
                    email: "john.doe@gmail.com"),
                fulfillmentType: "type",
                items: []))

        
        /// Prepare popup styling configuration object for each style elemnt
        let popUpStyling = PopUpStyling(
            loaderColor: UIColor(hex: primaryColor),
            crossColor: UIColor(hex: primaryColor),
            dividerColor: UIColor(hex: boxColor),
            borderColor: UIColor(hex: boxColor).cgColor,
            titlePopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: fontFamily, size: Double(xlargeTextSize)),
                textColor: UIColor(hex: darkColor)
            ),
            subTitlePopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: fontFamily, size: Double(mediumTextSize)),
                textColor: UIColor(hex: lightColor)
            ),
            headerPopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: fontFamily, size: Double(mediumTextSize)),
                textColor: UIColor(hex: darkColor)
            ),
            headerBgColor: UIColor(hex: boxColor),
            headingThreePopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: fontFamily, size: Double(largeTextSize)),
                textColor: UIColor(hex: primaryColor)
            ),
            paragraphPopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: fontFamily, size: Double(smallTextSize)),
                textColor: UIColor(hex: lightColor)
            ),
            connectorPopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: fontFamily, size: Double(largeTextSize)),
                textColor: UIColor(hex: darkColor)
            ),
            disclosurePopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: fontFamily, size: Double(smallTextSize)),
                textColor: UIColor(hex: lightColor)
            ),
            actionButtonStyle: PopupActionButtonStyle(
                font: UIFont(
                    name: fontFamily, size: Double(mediumTextSize)),
                textColor: .white,
                backgroundColor: UIColor(hex: primaryColor),
                cornerRadius: 25.0,
                padding: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            )
        )
        
        let placementsConfiguration = PlacementConfiguration(
            placementData: placementData
        )

        let merchantConfiguration = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: "Jack",
                familyName: "Seamus",
                additionalName: "C.",
                birthDate: "1974-08-21",
                email: "johncseamus@gmail.com",
                phone: "+13235323423",
                billingAddress: BreadPartnersAddress(
                    address1: "323 something lane",
                    address2: "apt. B",
                    country: "USA",
                    locality: "NYC",
                    region: "NY",
                    postalCode: "11222"
                ),
                shippingAddress: nil
            ), loyaltyID: loyaltyId,
//            storeNumber: "1234567",
            channel: channel,
            subchannel: subChannel
        )

        Task {

            await BreadPartnersSDK.shared.setup(
                environment: env ?? BreadPartnersEnvironment.stage,
                integrationKey: brandId ?? "",
                enableLog: true)

            await BreadPartnersSDK.shared.registerPlacements(
                merchantConfiguration: merchantConfiguration,
                placementsConfiguration: placementsConfiguration,
                splitTextAndAction: false,
                forSwiftUI: false
            ) {
                event in
                switch event {
                case .renderTextViewWithLink(let textView):
                    /// Handles rendering of a text view with a clickable link.
                    /// - Modifies the font, text color, and link color for the text view.
                    /// - Adds the text view to the main view and sets up its layout constraints.
                    
                    self.view.addSubview(textView)

                    textView.translatesAutoresizingMaskIntoConstraints = false

                    // If you want to correctly style the text view with link functionality,
                    // you can call the actionPlacement function,
                    self.actionPlacement(
                        textView: textView,
                        fontFamily: fontFamily,
                        xlargeTextSize: xlargeTextSize,
                        primaryColor: primaryColor
                    )
                    
                    // If you want to correctly style the text view without link functionality,
                    // you can call the noActionPlacement function,
//                    self.noActionPlacement(textView: textView, fontSize: 15)
           

                case .renderSeparateTextAndButton(let textView, let button):

                    /// Handles rendering of a text view and a button, placed separately.
                    /// - Modifies the font, text color for the text view, and the button's title color, font, and background.
                    /// - Adds the text view and button to the main view and sets up their layout constraints.
                    textView.font = UIFont(
                        name: fontFamily, size: Double(mediumTextSize))
                    textView.textColor = UIColor(hex: blackColor)

                    button.setTitleColor(UIColor.white, for: .normal)
                    button.titleLabel?.font = UIFont(
                        name: fontFamily, size: Double(mediumTextSize))
                    button.backgroundColor =
                        UIColor(hex: primaryColor)
                    button.layer.cornerRadius = 25.0

                    DispatchQueue.main.async {

                        self.view.addSubview(textView)
                        self.view.addSubview(button)
                        textView.translatesAutoresizingMaskIntoConstraints =
                            false
                        button.translatesAutoresizingMaskIntoConstraints = false

                        NSLayoutConstraint.activate([
                            textView.centerXAnchor.constraint(
                                equalTo: self.view.centerXAnchor),
                            textView.topAnchor.constraint(
                                equalTo: self.view.topAnchor, constant: 100),
                            textView.leadingAnchor.constraint(
                                equalTo: self.view.leadingAnchor, constant: 20),
                            textView.trailingAnchor.constraint(
                                equalTo: self.view.trailingAnchor, constant: -20
                            ),

                            button.widthAnchor.constraint(equalToConstant: 150),
                            button.trailingAnchor.constraint(
                                equalTo: self.view.trailingAnchor, constant: -20
                            ),
                            button.heightAnchor.constraint(equalToConstant: 50),
                            button.topAnchor.constraint(
                                equalTo: textView.bottomAnchor, constant: 20),
                        ])
                    }
                case .onSDKEventLog(_):
                    print("")
                case .renderPopupView(let view):
                    self.present(view, animated: true)
                    print("BreadPartnerSDK::Successfully rendered PopupView.")
                default:
                    print("BreadPartnerSDK:: \(event)")
                    break
                }

            }
        }
    }
    
    func actionPlacement(textView: BreadPartnerLinkText, fontFamily: String, xlargeTextSize: Int, primaryColor: String) {
        textView.font = UIFont(
            name: fontFamily, size: Double(xlargeTextSize))
        textView.textColor = UIColor.black
        textView.linkTextAttributes = [
            .foregroundColor: UIColor(hex: primaryColor)
        ]

        NSLayoutConstraint.activate([
            textView.centerXAnchor.constraint(
                equalTo: self.view.centerXAnchor),
            textView.topAnchor.constraint(
                equalTo: self.view.topAnchor, constant: 100),
            textView.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor, constant: -20),
        ])
    }
    
 
    func noActionPlacement(textView: BreadPartnerLinkText, fontSize: Int) {
        // Apply font size to the attributed text while preserving HTML formatting
        if let attributedText = textView.attributedText {
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            let fullRange = NSRange(location: 0, length: mutableAttributedString.length)
            
            // Set base text color to black
            mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.black, range: fullRange)
            
            // Update font sizes while preserving traits (bold, italic, superscript, etc.)
            mutableAttributedString.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
                // Check if this is superscript by looking for baseline offset
                let baselineOffset = attributes[.baselineOffset] as? NSNumber
                let isSuperscript = (baselineOffset?.floatValue ?? 0) > 0
                
                if let currentFont = attributes[.font] as? UIFont {
                    // Use smaller size for superscript, regular size for normal text
                    let newSize = CGFloat(fontSize)

                    // Preserve font traits (bold, italic)
                    let fontDescriptor = currentFont.fontDescriptor
                    let newFontDescriptor = fontDescriptor.withSize(newSize)
                    let newFont = UIFont(descriptor: newFontDescriptor, size: newSize)
                    
                    mutableAttributedString.addAttribute(.font, value: newFont, range: range)
                } else {
                    // If no font attribute, add default font
                    let defaultSize = CGFloat(fontSize)
                    let defaultFont = UIFont.systemFont(ofSize: defaultSize)
                    mutableAttributedString.addAttribute(.font, value: defaultFont, range: range)
                }
            }
            
            textView.attributedText = mutableAttributedString
        }

        NSLayoutConstraint.activate([
            textView.centerXAnchor.constraint(
                equalTo: self.view.centerXAnchor),
            textView.topAnchor.constraint(
                equalTo: self.view.topAnchor, constant: 100),
            textView.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor, constant: -20),
        ])
    }
  

    
    func openExperienceFlow() {
        let placementRequestType: [String: Any] = TestData.shared.placementConfigurations["textPlacementRequestType1"]!
        let placementID = placementRequestType["placementID"] as? String
        let price = (placementRequestType["price"] as? Int)
        let loyaltyId = (placementRequestType["loyaltyId"] as? String)
        let brandId = placementRequestType["brandId"] as? String
        let channel = placementRequestType["channel"] as? String
        let subChannel = placementRequestType["subchannel"] as? String
        let env = placementRequestType["env"] as? BreadPartnersEnvironment
        let location = placementRequestType["location"] as? BreadPartnersLocationType
        let financingType = placementRequestType["financingType"] as? BreadPartnersFinancingType

        let placementData = PlacementData(
            financingType: financingType,
            locationType: location,
            placementId: placementID,
            domID: "123",
            order: Order(
                subTotal: CurrencyValue(currency: "USD", value: 0),
                totalDiscounts: CurrencyValue(currency: "USD", value: 0),
                totalPrice: CurrencyValue(
                    currency: "USD", value: Int(price ?? 0)),
                totalShipping: CurrencyValue(currency: "USD", value: 0),
                totalTax: CurrencyValue(currency: "USD", value: 0),
                discountCode: "string",
                pickupInformation: PickupInformation(
                    name: Name(
                        givenName: "John",
                        familyName: "Doe"),
                    phone: "+14539842345",
                    address: Address(
                        address1: "156 5th Avenue",
                        locality: "New York",
                        postalCode: "10019",
                        region: "US-NY",
                        country: "US"),
                    email: "john.doe@gmail.com"),
                fulfillmentType: "type",
                items: []))

        let placementsConfiguration = PlacementConfiguration(
            placementData: placementData
        )

        let merchantConfiguration = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: "Jack",
                familyName: "Seamus",
                additionalName: "C.",
                birthDate: "1974-08-21",
                email: "johncseamus@gmail.com",
                phone: "+13235323423",
                billingAddress: BreadPartnersAddress(
                    address1: "323 something lane",
                    address2: "apt. B",
                    country: "USA",
                    locality: "NYC",
                    region: "NY",
                    postalCode: "11222"
                ),
                shippingAddress: nil
            ), loyaltyID: loyaltyId,
            storeNumber: "1234567",
            env: env,
            channel: channel,
            subchannel: subChannel
        )

        Task {

            await BreadPartnersSDK.shared.setup(
                environment: env ?? BreadPartnersEnvironment.stage,
                integrationKey: brandId ?? "",
                enableLog: true)

            await BreadPartnersSDK.shared.openExperienceForPlacement(
                merchantConfiguration: merchantConfiguration,
                placementsConfiguration: placementsConfiguration,
                forSwiftUI: false
            ) {
                event in
                switch event {
                case .renderPopupView(let view):
                    DispatchQueue.main.async {
                        self.present(view, animated: true)
                    }
                case .onSDKEventLog(_):
                    print("")
                default:
                    break
                }

            }
        }
    }
    
    func rtpsCall() {

        let rtpsData = RTPSData(
            order: Order(
                totalPrice: CurrencyValue(
                    currency: "USD",
                    value: 50000)
            ), locationType: BreadPartnersLocationType.checkout,
            mockResponse: .success
        )

        let placementsConfiguration = PlacementConfiguration(
            rtpsData: rtpsData
        )

        let merchantConfiguration = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: "Carol",
                familyName: "Jones",
                additionalName: "C.",
                birthDate: "1974-08-21",
                billingAddress: BreadPartnersAddress(
                    address1: "3075 Loyalty Cir",
                    address2: "Columbus",
                    country: "USA",
                    locality: "Columbus",
                    region: "OH",
                    postalCode: "43219")
            ),
            storeNumber: "2009"
        )
        
        let placementRequestType: [String: Any] = [:]
        let brandId = placementRequestType["brandId"] as? String

        Task {
            await BreadPartnersSDK.shared.setup(
                environment: .stage,
                integrationKey: brandId ?? "",
                enableLog: true)

            await BreadPartnersSDK.shared.silentRTPSRequest(
                merchantConfiguration: merchantConfiguration,
                placementsConfiguration: placementsConfiguration
            ) {
                event in
                switch event {
                case .renderPopupView(let view):
                    self.present(view, animated: true)
                    print("BreadPartnerSDK::Successfully rendered PopupView.")
                default:
                    break
                }
            }
        }
    }
}
