import BreadPartnersSDK
import UIKit

class OpenExperienceController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        openExperienceFlow()
    }

    func openExperienceFlow() {
        let placementRequestType: [String: Any] = TestData.shared.placementConfigurations["ECO"]!
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
        
        let givenName = "John"
        let familyName = "Doe"
        let additionalName = "Smith"
        let email = "joncarlos.tavarez.1163@gmail.com"
        let phone = "3474351163"
        let postalCode = "11222"
        let region = "NY"
        let country = "US"
        let address1 = "123 Something Street"
        let address2 = "Apt. 2B"
        let locality = "Brooklyn"
        let birthDate = "1990-01-01"
        let subTotal: Int64 = 399999
        let totalTax: Int64 = 14999
        let totalShipping: Int64 = 0
        let totalDiscounts: Int64 = 0
        let totalPrice: Int64 = (subTotal + totalTax + totalShipping) - totalDiscounts

        let placementData = PlacementData(
            financingType: financingType,
            locationType: location,
            placementId: placementID,
            allowCheckout: allowCheckout,
            order: Order(
                subTotal: CurrencyValue(currency: "USD", value: subTotal),
                totalDiscounts: CurrencyValue(currency: "USD", value: totalDiscounts),
                totalPrice: CurrencyValue(currency: "USD", value: totalPrice),
                totalShipping: CurrencyValue(currency: "USD", value: totalShipping),
                totalTax: CurrencyValue(currency: "USD", value: totalTax),
                discountCode: "string",
                pickupInformation: PickupInformation(
                    name: Name(
                        givenName: givenName,
                        familyName: familyName
                    ),
                    phone: phone,
                    address: Address(
                        address1: address1,
                        address2: address2,
                        locality: locality,
                        postalCode: postalCode,
                        region: region,
                        country: country
                    ),
                    email: email
                ),
                fulfillmentType: "PICKUP",
                items: [
                    Item(
                        name: "Product 1",
                        category: "Electronics",
                        quantity: 1,
                        unitPrice: CurrencyValue(currency: "USD", value: 149999),
                        unitTax: CurrencyValue(currency: "USD", value: 7499),
                        sku: "SKU-001",
                        shippingCost: CurrencyValue(currency: "USD", value: 0),
                        fulfillmentType: "PICKUP"
                    ),
                    Item(
                        name: "Product 2",
                        category: "Accessories",
                        quantity: 1,
                        unitPrice: CurrencyValue(currency: "USD", value: 150000),
                        unitTax: CurrencyValue(currency: "USD", value: 7500),
                        sku: "SKU-002",
                        shippingCost: CurrencyValue(currency: "USD", value: 0),
                        fulfillmentType: "PICKUP"
                    )
                ]))

        let placementsConfiguration = PlacementConfiguration(
            placementData: placementData
        )

        let merchantConfiguration = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: givenName,
                familyName: familyName,
                additionalName: additionalName,
                birthDate: birthDate,
                email: email,
                phone: phone,
                billingAddress: BreadPartnersAddress(
                    address1: address1,
                    address2: address2,
                    country: country,
                    locality: locality,
                    region: region,
                    postalCode: postalCode
                ),
                shippingAddress: nil
            ),
            loyaltyID: loyaltyId,
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
                    print("SDK event: \(event)")
                }

            }
        }
    }
}
