import Testing
import SwiftUI
import UIKit
@testable import BreadPartnersSDK

@Suite(.serialized)
struct BreadPartnerLinkTextSwitUITests {

	private func mirrorValue<T>(_ object: Any, key: String, as: T.Type) -> T? {
		var mirror: Mirror? = Mirror(reflecting: object)
		while let current = mirror {
			if let value = current.children.first(where: { $0.label == key })?.value as? T {
				return value
			}
			mirror = current.superclassMirror
		}
		return nil
	}

	@Test("plain initializer stores text and default link configuration")
	func plainInitializerStoresDefaults() {
		let view = BreadPartnerLinkTextSwitUI("Learn", links: ["Learn"])

		#expect(mirrorValue(view, key: "text", as: String.self) == "Learn")
		#expect(mirrorValue(view, key: "links", as: [String].self) == ["Learn"])
		#expect(mirrorValue(view, key: "linkFontName", as: String.self) == "System")
		#expect(mirrorValue(view, key: "linkFontSize", as: CGFloat.self) == 17)
	}

	@Test("attributed initializer stores attributed content")
	func attributedInitializerStoresContent() {
		let attributed = NSAttributedString(string: "HTML")
		let view = BreadPartnerLinkTextSwitUI(attributedString: attributed)

		#expect(mirrorValue(view, key: "text", as: String.self) == "HTML")
		#expect(mirrorValue(view, key: "attributedText", as: NSAttributedString?.self)??.string == "HTML")
		#expect(mirrorValue(view, key: "links", as: [String].self) == [])
	}

	@Test("link modifiers update a copy without mutating the original")
	func linkModifiersUpdateCopy() {
		let original = BreadPartnerLinkTextSwitUI("Learn", links: ["Learn"])
		let updated = original
			.linkColor(.red)
			.linkFont("HelveticaNeue", fontSize: 14)

		#expect(mirrorValue(updated, key: "linkFontName", as: String.self) == "HelveticaNeue")
		#expect(mirrorValue(updated, key: "linkFontSize", as: CGFloat.self) == 14)
		#expect(mirrorValue(original, key: "linkFontName", as: String.self) == "System")
		#expect(mirrorValue(original, key: "linkFontSize", as: CGFloat.self) == 17)
	}

	@Test("body builds for plain text with a custom link font")
	func bodyBuildsPlainTextBranch() {
		let view = BreadPartnerLinkTextSwitUI(
			"Learn more",
			links: ["Learn"],
			fontName: "Missing-Font",
			fontSize: 15
		)

		let body = view.body
		#expect(String(describing: body).isEmpty == false)
	}

	@Test("body builds for attributed text branch")
	func bodyBuildsAttributedTextBranch() {
		let view = BreadPartnerLinkTextSwitUI(
			attributedString: NSAttributedString(string: "Formatted")
		)

		let body = view.body
		#expect(String(describing: body).isEmpty == false)
	}
}
