// BreadPartnersSDKSpec.swift
// Tests for BreadPartnersSDK public API — initialization guard and setup behaviour.

import Quick
import Nimble
@testable import BreadPartnersSDK

class BreadPartnersSDKSpec: QuickSpec {
    override func spec() {

        // MARK: - Singleton

        describe("BreadPartnersSDK.shared") {
            it("returns the same instance on repeated access") {
                let first = BreadPartnersSDK.shared
                let second = BreadPartnersSDK.shared
                expect(first) === second
            }
        }

        // MARK: - Uninitialized guard

        describe("calling SDK methods before setup()") {
            // Each test creates a fresh BreadPartnersSDK() to exercise
            // the "not initialized" code path without affecting the shared instance.

            context("registerPlacements") {
                it("fires sdkError callback when SDK is not initialized") {
                    let sdk = BreadPartnersSDK()
                    let merchant = MerchantConfiguration(storeNumber: "1234")
                    let placement = PlacementConfiguration(
                        placementData: PlacementData(placementId: "p1")
                    )

                    waitUntil(timeout: .seconds(3)) { done in
                        Task {
                            await sdk.registerPlacements(
                                merchantConfiguration: merchant,
                                placementsConfiguration: placement
                            ) { event in
                                if case .sdkError(let error) = event {
                                    expect(error.localizedDescription).to(contain("setup()"))
                                    done()
                                }
                            }
                        }
                    }
                }
            }

            context("silentRTPSRequest") {
                it("fires sdkError callback when SDK is not initialized") {
                    let sdk = BreadPartnersSDK()
                    let merchant = MerchantConfiguration(storeNumber: "1234")
                    let placement = PlacementConfiguration(
                        rtpsData: RTPSData(cardType: "VISA")
                    )

                    waitUntil(timeout: .seconds(3)) { done in
                        Task {
                            await sdk.silentRTPSRequest(
                                merchantConfiguration: merchant,
                                placementsConfiguration: placement
                            ) { event in
                                if case .sdkError(let error) = event {
                                    expect(error.localizedDescription).to(contain("setup()"))
                                    done()
                                }
                            }
                        }
                    }
                }
            }

            context("openExperienceForPlacement") {
                it("fires sdkError callback when SDK is not initialized") {
                    let sdk = BreadPartnersSDK()
                    let merchant = MerchantConfiguration(storeNumber: "1234")
                    let placement = PlacementConfiguration(
                        placementData: PlacementData(placementId: "p2")
                    )

                    waitUntil(timeout: .seconds(3)) { done in
                        Task {
                            await sdk.openExperienceForPlacement(
                                merchantConfiguration: merchant,
                                placementsConfiguration: placement
                            ) { event in
                                if case .sdkError(let error) = event {
                                    expect(error.localizedDescription).to(contain("setup()"))
                                    done()
                                }
                            }
                        }
                    }
                }
            }
        }

        // MARK: - Default popup styling fallback

        describe("registerPlacements popUpStyling default") {
            it("PlacementConfiguration starts with nil popUpStyling") {
                let config = PlacementConfiguration(
                    placementData: PlacementData(placementId: "x")
                )
                expect(config.popUpStyling).to(beNil())
            }
        }
    }
}
