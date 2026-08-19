import Testing
import UIKit
@testable import BreadPartnersSDK

@Suite(.serialized)
struct BreadPartnerLinkTextTests {

	private final class SelectorShim: NSObject {
		@objc func handleTap(_ gesture: UITapGestureRecognizer) {}
	}

	private final class FixedLocationTapGestureRecognizer: UITapGestureRecognizer {
		private let fixedLocation: CGPoint

		init(location: CGPoint) {
			fixedLocation = location
			super.init(target: nil, action: nil)
		}

		override func location(in view: UIView?) -> CGPoint {
			fixedLocation
		}
	}

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

	@MainActor
	@Test
	func defaultsAfterInit() {
		let view = BreadPartnerLinkText()

		#expect(view.isEditable == false)
		#expect(view.isScrollEnabled == false)
		#expect(view.isSelectable == true)
		#expect(view.dataDetectorTypes.contains(.link))
	}

	@MainActor
	@Test
	func configureWithLinkDisablesTapWithoutLink() {
		let view = BreadPartnerLinkText()
		let attributed = NSAttributedString(
			string: "Learn More",
			attributes: [.link: "https://example.com"]
		)

		view.configure(with: attributed)

		#expect(mirrorValue(view, key: "allowTapWithoutLink", as: Bool.self) == false)
	}

	@MainActor
	@Test
	func configureWithoutLinkEnablesTapWithoutLink() {
		let view = BreadPartnerLinkText()
		view.configure(with: NSAttributedString(string: "No link"))

		#expect(mirrorValue(view, key: "allowTapWithoutLink", as: Bool.self) == true)
	}

	@MainActor
	@Test
	func configureStoresTapHandler() {
		let view = BreadPartnerLinkText()
		view.configure(with: NSAttributedString(string: "x"), tapHandler: { _ in })
		let tapHandlerChild = Mirror(reflecting: view).children.first { $0.label == "tapHandler" }

		#expect(tapHandlerChild.map { !Mirror(reflecting: $0.value).children.isEmpty } ?? false)
	}

	@MainActor
	@Test
	func tappingLinkInvokesHandlerWithLink() async {
		let view = BreadPartnerLinkText(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
		let link = "https://example.com"
		let received = await receivedValue { continuation in
			view.configure(
				with: NSAttributedString(
					string: "Learn More",
					attributes: [.link: link]
				),
				tapHandler: { continuation($0) }
			)
			view.layoutIfNeeded()
			let gesture = FixedLocationTapGestureRecognizer(location: CGPoint(x: 10, y: 10))
			_ = view.perform(#selector(SelectorShim.handleTap(_:)), with: gesture)
		}

		#expect(received == link)
	}

	@MainActor
	@Test
	func tappingTextWithoutLinkInvokesHandlerWithEmptyLink() async {
		let view = BreadPartnerLinkText(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
		let received = await receivedValue { continuation in
			view.configure(
				with: NSAttributedString(string: "No link"),
				tapHandler: { continuation($0) }
			)
			view.layoutIfNeeded()
			let gesture = FixedLocationTapGestureRecognizer(location: CGPoint(x: 10, y: 10))
			_ = view.perform(#selector(SelectorShim.handleTap(_:)), with: gesture)
		}

		#expect(received.isEmpty)
	}

	@MainActor
	@Test
	func tappingOutsideTextWithoutLinkInvokesHandlerWithEmptyLink() async {
		let view = BreadPartnerLinkText(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
		let received = await receivedValue { continuation in
			view.configure(
				with: NSAttributedString(string: "No link"),
				tapHandler: { continuation($0) }
			)
			view.layoutIfNeeded()
			let gesture = FixedLocationTapGestureRecognizer(location: CGPoint(x: 199, y: 39))
			_ = view.perform(#selector(SelectorShim.handleTap(_:)), with: gesture)
		}

		#expect(received.isEmpty)
	}

	private func receivedValue(_ register: (@escaping (String) -> Void) -> Void) async -> String {
		await withCheckedContinuation { continuation in
			register { value in
				continuation.resume(returning: value)
			}
		}
	}
}
