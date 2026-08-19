import Testing
@testable import BreadPartnersSDK

@Suite
@MainActor
struct BreadPartnersSDKTests {

    private final class EventBox: @unchecked Sendable {
        var event: BreadPartnerEvents?
    }

    private func makeConfigurations() -> (MerchantConfiguration, PlacementConfiguration) {
        (
            MerchantConfiguration(storeNumber: "store-123"),
            PlacementConfiguration()
        )
    }

    private func expectSDKNotInitialized(_ event: BreadPartnerEvents?) {
        guard case let .sdkError(error)? = event else {
            Issue.record("Expected an SDK initialization error")
            return
        }

        #expect(error.localizedDescription == "SDK not initialized. Call setup() first.")
    }

    @Test("SDK starts with its documented default configuration")
    func defaultConfiguration() {
        let sdk = BreadPartnersSDK()

        #expect(sdk.integrationKey == "")
        #expect(sdk.isLoggingEnabled == false)
        #expect(sdk.sdkEnvironment == .stage)
        #expect(sdk.brandConfiguration == nil)
    }

    @Test("registerPlacements reports an error before setup")
    func registerPlacementsRequiresSetup() async {
        let sdk = BreadPartnersSDK()
        let (merchantConfiguration, placementsConfiguration) = makeConfigurations()
        let eventBox = EventBox()

        await sdk.registerPlacements(
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: placementsConfiguration
        ) { event in
            eventBox.event = event
        }

        expectSDKNotInitialized(eventBox.event)
    }

    @Test("silentRTPSRequest reports an error before setup")
    func silentRTPSRequestRequiresSetup() async {
        let sdk = BreadPartnersSDK()
        let (merchantConfiguration, placementsConfiguration) = makeConfigurations()
        let eventBox = EventBox()

        await sdk.silentRTPSRequest(
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: placementsConfiguration
        ) { event in
            eventBox.event = event
        }

        expectSDKNotInitialized(eventBox.event)
    }

    @Test("openExperienceForPlacement reports an error before setup")
    func openExperienceForPlacementRequiresSetup() async {
        let sdk = BreadPartnersSDK()
        let (merchantConfiguration, placementsConfiguration) = makeConfigurations()
        let eventBox = EventBox()

        await sdk.openExperienceForPlacement(
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: placementsConfiguration
        ) { event in
            eventBox.event = event
        }

        expectSDKNotInitialized(eventBox.event)
    }
}