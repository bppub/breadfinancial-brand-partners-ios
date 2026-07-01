//------------------------------------------------------------------------------
//  File:          PopupElements.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import UIKit
import SwiftSoup

internal class PopupElements: NSObject{
    
    static let shared = PopupElements()
    
    private override init() {
        super.init()
    }
    
    /// Returns a close button with a system "xmark" icon.
    func addCloseButton(target: Any,color:UIColor,action: Selector)->UIButton {
        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let closeIcon = UIImage(systemName: "xmark")
        closeButton.setImage(closeIcon, for: .normal)
        closeButton.tintColor = color
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.addTarget(target, action:action, for: .touchUpInside)
        return closeButton
    }
    
    /// Creates a simple horizontal divider view.
    func createHorizontalDivider(color:UIColor) -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = color
        return divider
    }
    
    func createContainerView(backgroundColor: UIColor, borderColor: CGColor? = nil, borderWidth: CGFloat = 0, cornerRadius: CGFloat = 12) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = backgroundColor
        containerView.layer.cornerRadius = cornerRadius
        containerView.layer.masksToBounds = true
        if let borderColor = borderColor {
            containerView.layer.borderColor = borderColor
            containerView.layer.borderWidth = borderWidth
        }
        
        return containerView
    }
    
    func createLabel(withText text: NSAttributedString, style: PopupTextStyle, align: NSTextAlignment = .center) -> UILabel {
        let label = UILabel()
        label.textAlignment = align
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        // Apply font while preserving bold/italic traits that the HTML parser embedded
        // in the attributed string. Simply setting label.font after label.attributedText
        // replaces every per-run font attribute and destroys bold/non-bold formatting.
        if let targetFont = style.font, text.length > 0 {
            let mutable = NSMutableAttributedString(attributedString: text)
            let fullRange = NSRange(location: 0, length: mutable.length)

            mutable.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
                let newFont: UIFont
                if let existingFont = value as? UIFont {
                    // Carry bold/italic traits from the HTML-parsed font into the target family.
                    let traits = existingFont.fontDescriptor.symbolicTraits
                    if let descriptor = targetFont.fontDescriptor
                        .withFamily(targetFont.familyName)
                        .withSymbolicTraits(traits) {
                        newFont = UIFont(descriptor: descriptor.withSize(targetFont.pointSize),
                                         size: targetFont.pointSize)
                    } else {
                        newFont = targetFont
                    }
                } else {
                    newFont = targetFont
                }
                mutable.addAttribute(.font, value: newFont, range: range)
            }

            mutable.addAttribute(.foregroundColor, value: style.textColor, range: fullRange)

            label.attributedText = mutable
        } else {
            label.attributedText = text
            label.applyTextStyle(style: style)
        }

        return label
    }
    
    /// Returns a UIStackView with specified axis and spacing.
    func createStackView(axis: NSLayoutConstraint.Axis, spacing: CGFloat) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = axis
        stackView.spacing = spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        return stackView
    }
    
    func createButton(target:Any,
                              title: String,
                              buttonStyle:PopupActionButtonStyle?,
                              action: Selector
                              ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = buttonStyle?.font
        button.setTitleColor(buttonStyle?.textColor ?? .white, for: .normal)
        button.backgroundColor = buttonStyle?.backgroundColor ?? UIColor(hex: "d50132")
        button.layer.cornerRadius = buttonStyle?.cornerRadius ?? 8.0
        button.layer.masksToBounds = true
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
    
    func createDisclosureTextView(
        withText text: NSAttributedString,
        rawHTML: String,
        style: PopupTextStyle,
        delegate: UITextViewDelegate
    ) -> UITextView {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = delegate

        // Apply attributed text, preserving any link attributes from HTML
        let mutable = NSMutableAttributedString(attributedString: text)
        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.addAttribute(.foregroundColor, value: style.textColor, range: fullRange)
        if let font = style.font {
            mutable.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
                let newFont: UIFont
                if let existingFont = value as? UIFont {
                    let traits = existingFont.fontDescriptor.symbolicTraits
                    if let descriptor = font.fontDescriptor.withFamily(font.familyName)
                        .withSymbolicTraits(traits) {
                        newFont = UIFont(descriptor: descriptor.withSize(font.pointSize), size: font.pointSize)
                    } else {
                        newFont = font
                    }
                } else {
                    newFont = font
                }
                mutable.addAttribute(.font, value: newFont, range: range)
            }
        }
        // Re-parse the raw HTML with SwiftSoup to find every <a href> and its
        // visible text, then inject the .link attribute at those ranges.
        if let doc = try? SwiftSoup.parse(rawHTML) {
            let anchors = (try? doc.select("a[href]").array()) ?? []
            let fullText = mutable.string as NSString
            for anchor in anchors {
                guard
                    let href = try? anchor.attr("href"), !href.isEmpty,
                    let linkURL = URL(string: href),
                    let linkText = try? anchor.text(), !linkText.isEmpty
                else { continue }

                // Find the first occurrence of the link text in the plain string
                let searchRange = NSRange(location: 0, length: fullText.length)
                let found = fullText.range(of: linkText, options: [], range: searchRange)
                mutable.addAttribute(.link, value: linkURL, range: found)
            }
        }

        textView.attributedText = mutable
        textView.linkTextAttributes = [
            .foregroundColor: style.textColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        return textView
    }

    func createLabelForTag(tag: String, value: String, popupStyle: PopUpStyling) -> UILabel? {
        switch tag.lowercased() {
        case "h3":
            return createLabel(withText: value.toAttributedString(),style: popupStyle.headingThreePopupTextStyle)
        case "p":
            return createLabel(withText: value.toAttributedString(),style: popupStyle.paragraphPopupTextStyle)
        case "connector":
            return createLabel(withText: value.toAttributedString(),style: popupStyle.connectorPopupTextStyle)
        case "footer":
            return createLabel(withText: value.toAttributedString(),style: popupStyle.paragraphPopupTextStyle)
        default:
            return nil
        }
    }
}
