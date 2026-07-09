// PlacementDataSpec.swift
// Tests for PlacementData, PlacementConfiguration, BreadPartnersLocationType,
// BreadPartnersFinancingType, BreadPartnersEnvironment

import Quick
import Nimble
@testable import BreadPartnersSDK

class PlacementDataSpec: QuickSpec {
    override func spec() {

        // MARK: - BreadPartnersEnvironment

        describe("BreadPartnersEnvironment") {
            it("has three cases") {
                expect(BreadPartnersEnvironment.allCases.count) == 3
            }

            it("stage rawValue is 'STAGE'") {
                expect(BreadPartnersEnvironment.stage.rawValue) == "STAGE"
            }

            it("prod rawValue is 'PROD'") {
                expect(BreadPartnersEnvironment.prod.rawValue) == "PROD"
            }

            it("uat rawValue is 'UAT'") {
                expect(BreadPartnersEnvironment.uat.rawValue) == "UAT"
            }
        }

        // MARK: - BreadPartnersFinancingType

        describe("BreadPartnersFinancingType") {
            it("has three cases") {
                expect(BreadPartnersFinancingType.allCases.count) == 3
            }

            it("rawValues match case names") {
                expect(BreadPartnersFinancingType.card.rawValue) == "card"
                expect(BreadPartnersFinancingType.installments.rawValue) == "installments"
                expect(BreadPartnersFinancingType.versatile.rawValue) == "versatile"
            }
        }

        // MARK: - BreadPartnersLocationType

        describe("BreadPartnersLocationType") {
            it("has a non-empty channel code for all mapped locations") {
                let mapped: [BreadPartnersLocationType] = [
                    .homepage, .landing, .search, .product, .category,
                    .banner, .checkout, .cart, .mobile, .loyalty,
                    .footer, .bag, .dashboard, .myaccount, .header
                ]
                for location in mapped {
                    expect(location.channelCode).toNot(beNil(), description: "\(location) should have a channelCode")
                }
            }

            it("returns correct channel codes for key locations") {
                expect(BreadPartnersLocationType.homepage.channelCode) == "H"
                expect(BreadPartnersLocationType.product.channelCode) == "P"
                expect(BreadPartnersLocationType.checkout.channelCode) == "O"
                expect(BreadPartnersLocationType.cart.channelCode) == "A"
                expect(BreadPartnersLocationType.mobile.channelCode) == "E"
            }

            it("rawValues match location name strings") {
                expect(BreadPartnersLocationType.bag.rawValue) == "bag"
                expect(BreadPartnersLocationType.checkout.rawValue) == "checkout"
                expect(BreadPartnersLocationType.homepage.rawValue) == "homepage"
            }
        }

        // MARK: - PlacementData

        describe("PlacementData") {
            it("initialises with all nil defaults") {
                let data = PlacementData()
                expect(data.financingType).to(beNil())
                expect(data.locationType).to(beNil())
                expect(data.placementId).to(beNil())
                expect(data.domID).to(beNil())
                expect(data.allowCheckout).to(beNil())
                expect(data.order).to(beNil())
            }

            it("stores provided values") {
                let order = Order(subTotal: CurrencyValue(currency: "USD", value: 5000))
                let data = PlacementData(
                    financingType: .card,
                    locationType: .product,
                    placementId: "placement-abc",
                    domID: "dom-1",
                    allowCheckout: true,
                    order: order
                )
                expect(data.financingType) == .card
                expect(data.locationType) == .product
                expect(data.placementId) == "placement-abc"
                expect(data.domID) == "dom-1"
                expect(data.allowCheckout) == true
                expect(data.order?.subTotal?.value) == 5000
                expect(data.order?.subTotal?.currency) == "USD"
            }
        }

        // MARK: - PlacementConfiguration

        describe("PlacementConfiguration") {
            it("initialises with all nil defaults") {
                let config = PlacementConfiguration()
                expect(config.placementData).to(beNil())
                expect(config.rtpsData).to(beNil())
                expect(config.popUpStyling).to(beNil())
            }

            it("stores placementData") {
                let pd = PlacementData(placementId: "p1")
                let config = PlacementConfiguration(placementData: pd)
                expect(config.placementData?.placementId) == "p1"
                expect(config.rtpsData).to(beNil())
            }

            it("stores rtpsData") {
                let rtps = RTPSData(cardType: "VISA", channel: "web")
                let config = PlacementConfiguration(rtpsData: rtps)
                expect(config.rtpsData?.cardType) == "VISA"
                expect(config.rtpsData?.channel) == "web"
                expect(config.placementData).to(beNil())
            }
        }

        // MARK: - Order / CurrencyValue

        describe("Order") {
            it("converts subTotal cents to dollars via fromMoneyToDollars") {
                let order = Order(subTotal: CurrencyValue(currency: "USD", value: 9999))
                expect(fromMoneyToDollars(order.subTotal?.value)) == 99.99
            }

            it("returns nil from fromMoneyToDollars when value is nil") {
                expect(fromMoneyToDollars(nil)).to(beNil())
            }
        }

        // MARK: - BreadPartnersMockOptions

        describe("BreadPartnersMockOptions") {
            it("noMock rawValue is empty string") {
                expect(BreadPartnersMockOptions.noMock.rawValue) == ""
            }

            it("success rawValue is 'success'") {
                expect(BreadPartnersMockOptions.success.rawValue) == "success"
            }

            it("error rawValue is 'error'") {
                expect(BreadPartnersMockOptions.error.rawValue) == "error"
            }
        }
    }
}
