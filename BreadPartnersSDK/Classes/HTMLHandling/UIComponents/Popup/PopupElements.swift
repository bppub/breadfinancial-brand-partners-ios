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

    /// Scale factor applied to superscript text relative to its surrounding
    /// (base) font size. For example `0.6` renders superscripts at 60% of the
    /// body text size. Change this value to make superscripts larger/smaller.
    var superscriptFontScale: CGFloat = 0.6

    /// Vertical offset of superscript text expressed as a fraction of the base
    /// font's point size. Higher values raise the superscript further above the
    /// baseline. Adjust alongside `superscriptFontScale` if needed.
    var superscriptBaselineFactor: CGFloat = 0.35
    
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
    
    func createLabel(withText text: NSAttributedString,style:PopupTextStyle,align: NSTextAlignment = .center) -> UILabel {
        let label = UILabel()
        label.textAlignment = align
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        // Apply font while preserving bold/italic traits from HTML (e.g. <b> tags),
        // but also keeping the default font's own traits (e.g. bold) as a baseline.
        if let targetFont = style.font, text.length > 0 {
            let mutable = NSMutableAttributedString(attributedString: text)
            let fullRange = NSRange(location: 0, length: mutable.length)

            applyFont(targetFont, to: mutable, in: fullRange)

            // Re-shrink superscript runs (must run after applyFont, which
            // otherwise forces them back to the body point size).
            applySuperscriptStyling(to: mutable, baseFont: targetFont, in: fullRange)

            mutable.addAttribute(.foregroundColor, value: style.textColor, range: fullRange)

            // The HTML parser embeds .paragraphStyle with .left/.natural alignment,
            // which overrides label.textAlignment. Re-apply the requested alignment
            // to every paragraph style run (preserving other properties like line spacing).
            mutable.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, range, _ in
                let ps = ((value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle)
                    ?? NSMutableParagraphStyle()
                ps.alignment = align
                mutable.addAttribute(.paragraphStyle, value: ps, range: range)
            }

            label.attributedText = mutable
        } else {
            label.attributedText = text
            label.applyTextStyle(style: style)
        }

        return label
    }
    
    /// Enumerates every font run in `mutable` and replaces it with `targetFont`'s
    /// family/size while unioning the symbolic traits (bold, italic, etc.) so that:
    ///  - the default font's own traits (e.g. bold) are always preserved as a baseline, and
    ///  - traits embedded by the HTML parser (e.g. from <b> tags) are layered on top.
    private func applyFont(_ targetFont: UIFont,
                           to mutable: NSMutableAttributedString,
                           in fullRange: NSRange) {
        mutable.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            let newFont: UIFont
            if let existingFont = value as? UIFont {
                let combinedTraits = targetFont.fontDescriptor.symbolicTraits
                    .union(existingFont.fontDescriptor.symbolicTraits)
                if let descriptor = targetFont.fontDescriptor
                    .withFamily(targetFont.familyName)
                    .withSymbolicTraits(combinedTraits) {
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
    }

    /// Restyles superscript runs so their size can be controlled independently
    /// of the body text.
    ///
    /// Superscript is recognised either by a positive `.baselineOffset` (set by
    /// the HTML parser) or by the CoreText superscript key (`NSSuperScript`).
    /// Because `applyFont(_:to:in:)` forces every run back to the body point
    /// size, this method must be called *after* `applyFont` to re-shrink the
    /// superscript glyphs.
    ///
    /// - Parameters:
    ///   - mutable: The attributed string to mutate in place.
    ///   - baseFont: The surrounding body font superscript size is derived from.
    ///   - fullRange: The range to scan (usually the whole string).
    ///   - scale: Superscript size relative to `baseFont` (defaults to
    ///     `superscriptFontScale`).
    private func applySuperscriptStyling(to mutable: NSMutableAttributedString,
                                         baseFont: UIFont,
                                         in fullRange: NSRange,
                                         scale: CGFloat? = nil) {
        let effectiveScale = scale ?? superscriptFontScale
        let superscriptKey = NSAttributedString.Key(rawValue: "NSSuperScript")

        mutable.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            let baselineOffset = (attributes[.baselineOffset] as? NSNumber)?.doubleValue ?? 0
            let superscriptLevel = (attributes[superscriptKey] as? NSNumber)?.doubleValue ?? 0
            let isSuperscript = baselineOffset > 0 || superscriptLevel > 0
            guard isSuperscript else { return }

            let superSize = baseFont.pointSize * effectiveScale

            // Preserve any bold/italic traits the run already carries.
            let existingFont = (attributes[.font] as? UIFont) ?? baseFont
            let traits = baseFont.fontDescriptor.symbolicTraits
                .union(existingFont.fontDescriptor.symbolicTraits)
            let descriptor = (baseFont.fontDescriptor
                .withFamily(baseFont.familyName)
                .withSymbolicTraits(traits) ?? baseFont.fontDescriptor)
                .withSize(superSize)
            let superFont = UIFont(descriptor: descriptor, size: superSize)

            mutable.addAttribute(.font, value: superFont, range: range)
            mutable.addAttribute(.baselineOffset,
                                 value: baseFont.pointSize * superscriptBaselineFactor,
                                 range: range)
        }
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
            applyFont(font, to: mutable, in: fullRange)
            // Re-shrink superscript runs after font normalization.
            applySuperscriptStyling(to: mutable, baseFont: font, in: fullRange)
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
