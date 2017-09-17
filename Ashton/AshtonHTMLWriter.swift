//
//  AshtonHTMLWriter.swift
//  Ashton
//
//  Created by Michael Schwarz on 16.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation


final class AshtonHTMLWriter {

	public func encode(_ attributedString: NSAttributedString) -> Ashton.HTML {
		let string = attributedString.string
		let paragraphRanges = self.getParagraphRanges(from: string)

		var html = String()
		for paragraphRange in paragraphRanges {
			var paragraphContent = String()
			let nsParagraphRange = NSRange(paragraphRange, in: string)
			var paragraphTag = HTMLTag(name: "p", attributes: [:])
			attributedString.enumerateAttributes(in: nsParagraphRange,
			                                     options: .longestEffectiveRangeNotRequired, using: { attributes, nsrange, _ in
													if nsParagraphRange.length == nsrange.length {
														paragraphTag.addAttributes(attributes)
														paragraphContent += String(attributedString.string[paragraphRange])
													} else {
														guard let range = Range(nsrange, in: attributedString.string) else { return }

														let tag = HTMLTag(name: "span", attributes: attributes)
														paragraphContent += tag.makeOpenTag()
														paragraphContent += String(attributedString.string[range])
														paragraphContent += tag.makeCloseTag()
													}
			})

			html += paragraphTag.makeOpenTag() + paragraphContent + paragraphTag.makeCloseTag()
		}

		return html
	}
}

// MARK: - Private

private extension AshtonHTMLWriter {

	func getParagraphRanges(from string: String) -> [Range<String.Index>] {
		var (paragraphStart, paragraphEnd, contentsEnd) = (string.startIndex, string.startIndex, string.startIndex)
		var ranges = [Range<String.Index>]()
		let length = string.endIndex

		while paragraphEnd < length {
			string.getParagraphStart(&paragraphStart, end: &paragraphEnd, contentsEnd: &contentsEnd, for: paragraphEnd...paragraphEnd)
			ranges.append(paragraphStart..<contentsEnd)
		}
		return ranges
	}
}

struct HTMLTag {
	let name: String
	var attributes: [NSAttributedStringKey: Any]

	mutating func addAttributes(_ attributes: [NSAttributedStringKey: Any]?) {
		attributes?.forEach { (key, value) in
			self.attributes[key] = value
		}
	}

	func makeOpenTag() -> String {
		if attributes.isEmpty {
			return "<\(name)>"
		} else {
			var styles = ""
			self.attributes.forEach { key, value in
				switch key {
				case .backgroundColor:
					guard let color = value as? UIColor else { return }
					styles += "background-color: " + self.makeCSSrgba(for: color)
				default:
					assertionFailure("did not handle \(key)")
				}
				styles += "; "
			}
			return "<\(name) style='\(styles)'>"
		}
	}

	func makeCloseTag() -> String {
		return "</\(name)>"
	}

	// MARK: - Private

	private func makeCSSrgba(for color: UIColor) -> String {
		var red: CGFloat = 0.0
		var green: CGFloat = 0.0
		var blue: CGFloat = 0.0
		var alpha: CGFloat = 0.0
		color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

		return "rgba(\(Int(red * 255.0)), \(Int(green * 255.0)), \(Int(blue * 255.0)), \(String(format: "%.6f", alpha)))"
	}
}