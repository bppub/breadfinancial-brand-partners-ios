import BreadPartnersSDK
import UIKit

class OpenExperienceController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        openExperienceFlow()
    }

    func openExperienceFlow() {
        let placementRequestType: [String: Any] = TestData.shared.placementConfigurations["textPlacementRequestType1"]!
//        let placementRequestType: [String: Any] = [:]
        let placementID = placementRequestType["placementID"] as? String
        let price = (placementRequestType["price"] as? Int)
        let loyaltyId = (placementRequestType["loyaltyId"] as? String)
        let brandId = placementRequestType["brandId"] as? String
        let channel = placementRequestType["channel"] as? String
        let subChannel = placementRequestType["subchannel"] as? String
        let env = placementRequestType["env"] as? BreadPartnersEnvironment
        let location = placementRequestType["location"] as? BreadPartnersLocationType
        let financingType = placementRequestType["financingType"] as? BreadPartnersFinancingType
        let allowCheckout = placementRequestType["allowCheckout"] as? Bool

        let placementData = PlacementData(
            financingType: financingType,
            locationType: location,
            placementId: placementID,
            allowCheckout: allowCheckout,
            order: Order(
                subTotal: CurrencyValue(currency: "USD", value: 150000),
                totalDiscounts: CurrencyValue(currency: "USD", value: 0),
                totalPrice: CurrencyValue(
                    currency: "USD", value: Int64(price ?? 0)),
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
                case .applicationCompleted:
                    print("Experience completed")
                case .onSDKEventLog(let log):
                    print("SDK Log: \(log)")
                default:
                    break
                }

            }
        }
    }
}
