// MerchantConfigurationSpec.swift
// Tests for MerchantConfiguration, BreadPartnersBuyer, BreadPartnersAddress

import Quick
import Nimble
@testable import BreadPartnersSDK

class MerchantConfigurationSpec: QuickSpec {
    override func spec() {

        // MARK: - MerchantConfiguration

        describe("MerchantConfiguration") {

            context("default storeNumber fallback") {
                it("uses '8883' when storeNumber is nil") {
                    let config = MerchantConfiguration(storeNumber: nil)
                    expect(config.storeNumber) == "8883"
                }

                it("uses '8883' when storeNumber is empty string") {
                    let config = MerchantConfiguration(storeNumber: "")
                    expect(config.storeNumber) == "8883"
                }

                it("preserves a non-empty storeNumber") {
                    let config = MerchantConfiguration(storeNumber: "1234")
                    expect(config.storeNumber) == "1234"
                }
            }

            context("optional fields default to nil") {
                it("initialises with all nils when only storeNumber is provided") {
                    let config = MerchantConfiguration(storeNumber: "999")
                    expect(config.buyer).to(beNil())
                    expect(config.loyaltyID).to(beNil())
                    expect(config.campaignID).to(beNil())
                    expect(config.departmentId).to(beNil())
                    expect(config.existingCardHolder).to(beNil())
                    expect(config.cardholderTier).to(beNil())
                    expect(config.overrideKey).to(beNil())
                    expect(config.channel).to(beNil())
                    expect(config.subchannel).to(beNil())
                    expect(config.clerkId).to(beNil())
                }
            }

            context("paymentMode") {
                it("full rawValue is 'full'") {
                    expect(MerchantConfiguration.PaymentMode.full.rawValue) == "full"
                }

                it("split rawValue is 'split'") {
                    expect(MerchantConfiguration.PaymentMode.split.rawValue) == "split"
                }
            }

            context("full initialisation") {
                it("stores all provided values") {
                    let buyer = BreadPartnersBuyer(givenName: "Jane", familyName: "Doe")
                    let config = MerchantConfiguration(
                        buyer: buyer,
                        loyaltyID: "LY001",
                        campaignID: "CAMP01",
                        storeNumber: "5555",
                        existingCardHolder: true,
                        channel: "mobile",
                        subchannel: "app",
                        paymentMode: .split
                    )
                    expect(config.buyer?.givenName) == "Jane"
                    expect(config.loyaltyID) == "LY001"
                    expect(config.campaignID) == "CAMP01"
                    expect(config.storeNumber) == "5555"
                    expect(config.existingCardHolder) == true
                    expect(config.channel) == "mobile"
                    expect(config.subchannel) == "app"
                    expect(config.paymentMode) == .split
                }
            }
        }

        // MARK: - BreadPartnersBuyer

        describe("BreadPartnersBuyer") {
            it("stores buyer fields correctly") {
                let address = BreadPartnersAddress(
                    address1: "123 Main St",
                    locality: "Columbus",
                    region: "OH",
                    postalCode: "43215"
                )
                let buyer = BreadPartnersBuyer(
                    givenName: "John",
                    familyName: "Smith",
                    email: "john@example.com",
                    phone: "6145550100",
                    billingAddress: address
                )
                expect(buyer.givenName) == "John"
                expect(buyer.familyName) == "Smith"
                expect(buyer.email) == "john@example.com"
                expect(buyer.phone) == "6145550100"
                expect(buyer.billingAddress?.address1) == "123 Main St"
                expect(buyer.billingAddress?.locality) == "Columbus"
                expect(buyer.billingAddress?.region) == "OH"
                expect(buyer.billingAddress?.postalCode) == "43215"
            }

            it("defaults all fields to nil") {
                let buyer = BreadPartnersBuyer()
                expect(buyer.givenName).to(beNil())
                expect(buyer.familyName).to(beNil())
                expect(buyer.email).to(beNil())
                expect(buyer.billingAddress).to(beNil())
                expect(buyer.shippingAddress).to(beNil())
            }
        }

        // MARK: - BreadPartnersAddress

        describe("BreadPartnersAddress") {
            it("stores address1 as required field") {
                let address = BreadPartnersAddress(address1: "456 Oak Ave")
                expect(address.address1) == "456 Oak Ave"
                expect(address.address2).to(beNil())
                expect(address.country).to(beNil())
            }

            it("stores all optional fields") {
                let address = BreadPartnersAddress(
                    address1: "1 Infinite Loop",
                    address2: "Suite 200",
                    country: "US",
                    locality: "Cupertino",
                    region: "CA",
                    postalCode: "95014"
                )
                expect(address.address2) == "Suite 200"
                expect(address.country) == "US"
                expect(address.region) == "CA"
                expect(address.postalCode) == "95014"
            }
        }
    }
}
