import Testing
import UIKit
@testable import BreadPartnersSDK

@Suite(.serialized)
struct PopupElementsTests {

	private let elements = PopupElements.shared

	private var style: PopupTextStyle {
		PopupTextStyle(font: UIFont.systemFont(ofSize: 16), textColor: .red)
	}

	@Test("addCloseButton creates a tinted system close button")
	@MainActor
	func addCloseButtonCreatesCloseButton() {
		let target = NSObject()
		let button = elements.addCloseButton(
			target: target,
			color: .blue,
			action: #selector(NSObject.description)
		)

		#expect(button.image(for: .normal) != nil)
		#expect(button.tintColor == .blue)
		#expect(button.translatesAutoresizingMaskIntoConstraints == false)
	}

	@Test("createHorizontalDivider applies its color")
	@MainActor
	func createHorizontalDividerAppliesColor() {
		let divider = elements.createHorizontalDivider(color: .green)

		#expect(divider.backgroundColor == .green)
		#expect(divider.translatesAutoresizingMaskIntoConstraints == false)
	}

	@Test("createContainerView applies background, corner, and border styling")
	@MainActor
	func createContainerViewAppliesStyling() {
		let container = elements.createContainerView(
			backgroundColor: .yellow,
			borderColor: UIColor.blue.cgColor,
			borderWidth: 2,
			cornerRadius: 6
		)

		#expect(container.backgroundColor == .yellow)
		#expect(container.layer.cornerRadius == 6)
		#expect(container.layer.borderWidth == 2)
		#expect(container.layer.borderColor == UIColor.blue.cgColor)
		#expect(container.layer.masksToBounds)
	}

	@Test("createLabel applies text alignment and style")
	@MainActor
	func createLabelAppliesStyle() {
		let label = elements.createLabel(
			withText: NSAttributedString(string: "Hello"),
			style: style,
			align: .left
		)

		#expect(label.textAlignment == .left)
		#expect(label.numberOfLines == 0)
		#expect(label.attributedText?.string == "Hello")
		#expect(label.attributedText?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor == .red)
		#expect((label.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)?.pointSize == 16)
	}

	@Test("createLabel preserves bold traits while applying a custom font")
	@MainActor
	func createLabelPreservesBoldTraits() {
		let boldText = NSAttributedString(
			string: "Bold",
			attributes: [.font: UIFont.boldSystemFont(ofSize: 12)]
		)
		let label = elements.createLabel(withText: boldText, style: style)
		let font = label.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont

		#expect(font?.pointSize == 16)
		#expect(font?.fontDescriptor.symbolicTraits.contains(.traitBold) == true)
	}

	@Test("createLabel rescales superscript runs")
	@MainActor
	func createLabelRescalesSuperscript() {
		let text = NSMutableAttributedString(string: "A2")
		text.addAttribute(.baselineOffset, value: 4, range: NSRange(location: 1, length: 1))
		text.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSMakeRange(0, 2))

		let label = elements.createLabel(withText: text, style: style)
		let superscriptFont = label.attributedText?.attribute(.font, at: 1, effectiveRange: nil) as? UIFont

		#expect(superscriptFont?.pointSize == 16 * BreadPartnerDefaults.SUPERSCRIPT_TEXT_SCALE)
	}

	@Test("createStackView applies axis, spacing, and layout configuration")
	@MainActor
	func createStackViewAppliesConfiguration() {
		let stack = elements.createStackView(axis: .vertical, spacing: 12)

		#expect(stack.axis == .vertical)
		#expect(stack.spacing == 12)
		#expect(stack.alignment == .fill)
		#expect(stack.translatesAutoresizingMaskIntoConstraints == false)
	}

	@Test("createButton applies title and default styling")
	@MainActor
	func createButtonAppliesDefaults() {
		let button = elements.createButton(
			target: NSObject(),
			title: "Continue",
			buttonStyle: nil,
			action: #selector(NSObject.description)
		)

		#expect(button.title(for: .normal) == "Continue")
		#expect(button.backgroundColor == UIColor(hex: "d50132"))
		#expect(button.layer.cornerRadius == 8)
		#expect(button.titleColor(for: .normal) == .white)
	}

	@Test("createButton applies custom action button styling")
	@MainActor
	func createButtonAppliesCustomStyle() {
		let customStyle = PopupActionButtonStyle(
			font: UIFont.italicSystemFont(ofSize: 18),
			textColor: UIColor.yellow,
			backgroundColor: UIColor.black,
			cornerRadius: 3
		)
		let button = elements.createButton(
			target: NSObject(),
			title: "Apply",
			buttonStyle: customStyle,
			action: #selector(NSObject.description)
		)

		#expect(button.backgroundColor == .black)
		#expect(button.titleColor(for: UIControl.State.normal) == UIColor.yellow)
		#expect(button.titleLabel?.font.pointSize == 18)
		#expect(button.layer.cornerRadius == 3)
	}

	@Test("createDisclosureTextView preserves links and delegate")
	@MainActor
	func createDisclosureTextViewPreservesLinks() {
		let delegate = DisclosureDelegate()
		let text = NSAttributedString(string: "Terms and conditions")
		let textView = elements.createDisclosureTextView(
			withText: text,
			rawHTML: "<a href=\"https://example.com/terms\">Terms and conditions</a>",
			style: style,
			delegate: delegate
		)

		#expect(textView.isEditable == false)
		#expect(textView.isScrollEnabled == false)
		#expect(textView.delegate === delegate)
		#expect(textView.attributedText?.attribute(.link, at: 0, effectiveRange: nil) as? URL == URL(string: "https://example.com/terms"))
		#expect(textView.linkTextAttributes[.underlineStyle] as? Int == NSUnderlineStyle.single.rawValue)
	}

	@Test("createLabelForTag creates labels for supported tags")
	@MainActor
	func createLabelForTagSupportsKnownTags() {
		for tag in ["h3", "p", "connector", "footer"] {
			#expect(elements.createLabelForTag(tag: tag, value: "Content", popupStyle: PopUpStyling()) != nil)
		}
	}

	@Test("createLabelForTag ignores unsupported tags")
	@MainActor
	func createLabelForTagIgnoresUnknownTags() {
		#expect(elements.createLabelForTag(tag: "unknown", value: "Content", popupStyle: PopUpStyling()) == nil)
	}

	private final class DisclosureDelegate: NSObject, UITextViewDelegate {}
}
