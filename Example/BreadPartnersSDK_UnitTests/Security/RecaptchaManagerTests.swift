import Testing
import RecaptchaEnterprise
@testable import BreadPartnersSDK

@Suite(.serialized)
struct RecaptchaManagerTests {

	@Test("RecaptchaManager exposes a shared singleton")
	func sharedInstanceIsStable() {
		#expect(RecaptchaManager.shared === RecaptchaManager.shared)
	}

	@Test("fetchRecaptchaClient propagates an invalid site-key failure")
	func fetchRecaptchaClientRejectsInvalidSiteKey() async {
		do {
			try await RecaptchaManager.shared.fetchRecaptchaClient(siteKey: "")
			Issue.record("Expected an invalid site-key error")
		} catch {
			#expect(error is RecaptchaError)
		}
	}

	@Test("executeReCaptcha propagates an invalid site-key failure")
	func executeReCaptchaRejectsInvalidSiteKey() async {
		do {
			_ = try await RecaptchaManager.shared.executeReCaptcha(
				siteKey: "",
				action: RecaptchaAction(customAction: "unit-test"),
				timeout: 1
			)
			Issue.record("Expected an invalid site-key error")
		} catch {
			#expect(error is RecaptchaError)
		}
	}
}
