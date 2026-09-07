//
//  NoteHTML.swift
//  Focus Bear
//
//  Converts note bodies between the HTML the web dashboard stores (CKEditor output: <p>, <strong>,
//  <em>, <u>, <s>, <a>, <ul>/<ol>/<li>, <h1>–<h6>, <br>, <code>) and the NSAttributedString the native
//  editor edits. Hand-rolled rather than NSAttributedString(html:) because that goes through WebKit
//  (slow, main-thread only) and exports bloated styled markup the web wouldn't render consistently.
//
//  Lists are represented in the attributed string as plain marker prefixes ("• " / "1. ") with a
//  hanging indent, so the editor stays a simple NSTextView and export just pattern-matches the marker.
//

import AppKit

enum NoteHTML {

    /// Paragraph attribute carrying the heading level (1–6) of an imported <hN> so it exports back as one.
    static let headingLevelKey = NSAttributedString.Key("focusBearNoteHeadingLevel")

    static let bulletMarker = "• "
    static let indentUnit: CGFloat = 18
    static let markerWidth: CGFloat = 18
    /// Blank paragraphs round-trip as CKEditor's own representation.
    private static let emptyParagraphHTML = "<p>&nbsp;</p>"
    private static let lineSeparator = "\u{2028}"

    private static let headingSizeMultipliers: [Int: CGFloat] = [1: 1.6, 2: 1.35, 3: 1.15]
    private static let blockTags: Set<String> = ["p", "div", "h1", "h2", "h3", "h4", "h5", "h6", "li", "blockquote", "pre", "ul", "ol", "hr", "tr", "table", "section", "article", "header", "footer"]
    private static let orderedMarkerPattern = try! NSRegularExpression(pattern: "^(\\d+)\\. ")

    struct ListMarker {
        let ordered: Bool
        let number: Int
        let length: Int

        static func detect(in paragraphText: String) -> ListMarker? {
            if paragraphText.hasPrefix(bulletMarker) {
                return ListMarker(ordered: false, number: 0, length: bulletMarker.utf16.count)
            }
            let range = NSRange(location: 0, length: paragraphText.utf16.count)
            guard let match = orderedMarkerPattern.firstMatch(in: paragraphText, range: range),
                  let numberRange = Range(match.range(at: 1), in: paragraphText),
                  let number = Int(paragraphText[numberRange]) else { return nil }
            return ListMarker(ordered: true, number: number, length: match.range.length)
        }

        static func text(ordered: Bool, number: Int) -> String {
            ordered ? "\(number). " : bulletMarker
        }
    }

    static func listParagraphStyle(depth: Int) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        let base = CGFloat(max(depth - 1, 0)) * indentUnit
        style.firstLineHeadIndent = base
        style.headIndent = base + markerWidth
        return style
    }

    static func listDepth(of paragraphStyle: NSParagraphStyle?) -> Int {
        guard let style = paragraphStyle else { return 1 }
        return Int((style.firstLineHeadIndent / indentUnit).rounded()) + 1
    }

    // MARK: - Import (HTML → NSAttributedString)

    static func attributedString(fromHTML html: String, baseFont: NSFont, textColor: NSColor) -> NSAttributedString {
        let builder = Builder(baseFont: baseFont, textColor: textColor)
        for token in tokenize(html) {
            builder.consume(token)
        }
        return builder.finish()
    }

    /// Plain text for list previews and comparisons; paragraphs become newlines.
    static func plainText(fromHTML html: String) -> String {
        guard html.contains("<") else { return decodeEntities(html).trimmingCharacters(in: .whitespacesAndNewlines) }
        let attributed = attributedString(fromHTML: html, baseFont: NSFont.systemFont(ofSize: 12), textColor: .textColor)
        return attributed.string
            .replacingOccurrences(of: lineSeparator, with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Export (NSAttributedString → HTML)

    static func html(from attributed: NSAttributedString) -> String {
        let nsString = attributed.string as NSString
        var paragraphRanges: [NSRange] = []
        var location = 0
        while location <= nsString.length {
            let range = nsString.paragraphRange(for: NSRange(location: location, length: 0))
            paragraphRanges.append(range)
            if range.length == 0 { break }
            location = NSMaxRange(range)
            if location >= nsString.length {
                // A trailing "\n" leaves one empty final paragraph; paragraphRange handles it above.
                break
            }
        }
        // Drop trailing empty paragraphs (an NSTextView ending in "\n" would otherwise add a blank <p>).
        var paragraphs = paragraphRanges.map { range -> (NSRange, String) in
            let text = nsString.substring(with: range).trimmingCharacters(in: CharacterSet(charactersIn: "\n\r"))
            return (range, text)
        }
        while let last = paragraphs.last, last.1.trimmingCharacters(in: .whitespaces).isEmpty {
            paragraphs.removeLast()
        }

        var output = ""
        var openLists: [Bool] = []   // true = ordered

        func closeLists(downTo depth: Int) {
            while openLists.count > depth {
                output += openLists.removeLast() ? "</ol>" : "</ul>"
            }
        }

        for (range, text) in paragraphs {
            let contentStart = range.location
            if let marker = ListMarker.detect(in: text) {
                let style = attributed.length > contentStart
                    ? attributed.attribute(.paragraphStyle, at: contentStart, effectiveRange: nil) as? NSParagraphStyle
                    : nil
                let depth = listDepth(of: style)
                closeLists(downTo: depth)
                if openLists.count == depth, openLists.last != marker.ordered {
                    closeLists(downTo: depth - 1)
                }
                while openLists.count < depth {
                    openLists.append(marker.ordered)
                    output += marker.ordered ? "<ol>" : "<ul>"
                }
                let contentRange = NSRange(location: contentStart + marker.length, length: text.utf16.count - marker.length)
                output += "<li>" + inlineHTML(attributed, range: contentRange, inHeading: false) + "</li>"
                continue
            }
            closeLists(downTo: 0)
            if text.trimmingCharacters(in: .whitespaces).isEmpty {
                output += emptyParagraphHTML
                continue
            }
            let contentRange = NSRange(location: contentStart, length: text.utf16.count)
            let headingLevel = attributed.attribute(headingLevelKey, at: contentStart, effectiveRange: nil) as? Int
            if let level = headingLevel, (1...6).contains(level) {
                output += "<h\(level)>" + inlineHTML(attributed, range: contentRange, inHeading: true) + "</h\(level)>"
            } else {
                output += "<p>" + inlineHTML(attributed, range: contentRange, inHeading: false) + "</p>"
            }
        }
        closeLists(downTo: 0)
        return output
    }

    private static func inlineHTML(_ attributed: NSAttributedString, range: NSRange, inHeading: Bool) -> String {
        var output = ""
        guard range.length > 0 else { return output }
        attributed.enumerateAttributes(in: range, options: []) { attributes, runRange, _ in
            let text = (attributed.string as NSString).substring(with: runRange)
            var fragment = escape(text).replacingOccurrences(of: lineSeparator, with: "<br>")
            let font = attributes[.font] as? NSFont
            let traits = font?.fontDescriptor.symbolicTraits ?? []
            if traits.contains(.monoSpace) { fragment = "<code>\(fragment)</code>" }
            if let strike = attributes[.strikethroughStyle] as? Int, strike != 0 { fragment = "<s>\(fragment)</s>" }
            if let underline = attributes[.underlineStyle] as? Int, underline != 0 { fragment = "<u>\(fragment)</u>" }
            if traits.contains(.italic) { fragment = "<em>\(fragment)</em>" }
            if traits.contains(.bold), !inHeading { fragment = "<strong>\(fragment)</strong>" }
            if let link = attributes[.link] {
                let href = (link as? URL)?.absoluteString ?? (link as? String) ?? ""
                if !href.isEmpty { fragment = "<a href=\"\(escape(href))\">\(fragment)</a>" }
            }
            output += fragment
        }
        return output
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - Tokenizer

    fileprivate enum Token {
        case text(String)
        case open(name: String, href: String?)
        case close(name: String)
    }

    private static let hrefPattern = try! NSRegularExpression(pattern: "href\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')", options: .caseInsensitive)

    fileprivate static func tokenize(_ html: String) -> [Token] {
        var tokens: [Token] = []
        let scalars = Array(html.unicodeScalars)
        var index = 0
        var textBuffer = String.UnicodeScalarView()

        func flushText() {
            if !textBuffer.isEmpty {
                tokens.append(.text(decodeEntities(String(textBuffer))))
                textBuffer = String.UnicodeScalarView()
            }
        }

        while index < scalars.count {
            let scalar = scalars[index]
            guard scalar == "<" else {
                textBuffer.append(scalar)
                index += 1
                continue
            }
            // Comments / doctype: skip to the closing delimiter.
            if index + 1 < scalars.count, scalars[index + 1] == "!" {
                flushText()
                if index + 3 < scalars.count, scalars[index + 2] == "-", scalars[index + 3] == "-" {
                    var end = index + 4
                    while end + 2 < scalars.count, !(scalars[end] == "-" && scalars[end + 1] == "-" && scalars[end + 2] == ">") { end += 1 }
                    index = min(end + 3, scalars.count)
                } else {
                    var end = index
                    while end < scalars.count, scalars[end] != ">" { end += 1 }
                    index = min(end + 1, scalars.count)
                }
                continue
            }
            var end = index + 1
            while end < scalars.count, scalars[end] != ">" { end += 1 }
            guard end < scalars.count else {
                // Unterminated "<": treat literally.
                textBuffer.append(scalar)
                index += 1
                continue
            }
            flushText()
            var inner = String(String.UnicodeScalarView(scalars[(index + 1)..<end])).trimmingCharacters(in: .whitespacesAndNewlines)
            index = end + 1
            let isClosing = inner.hasPrefix("/")
            if isClosing { inner.removeFirst() }
            if inner.hasSuffix("/") { inner.removeLast() }
            let nameEnd = inner.firstIndex(where: { $0 == " " || $0 == "\n" || $0 == "\t" || $0 == "\r" }) ?? inner.endIndex
            let name = String(inner[..<nameEnd]).lowercased()
            guard !name.isEmpty else { continue }
            if isClosing {
                tokens.append(.close(name: name))
            } else {
                var href: String? = nil
                if name == "a" {
                    let attributesText = String(inner[nameEnd...])
                    let searchRange = NSRange(location: 0, length: attributesText.utf16.count)
                    if let match = hrefPattern.firstMatch(in: attributesText, range: searchRange) {
                        for group in 1...2 {
                            if let groupRange = Range(match.range(at: group), in: attributesText) {
                                href = decodeEntities(String(attributesText[groupRange]))
                                break
                            }
                        }
                    }
                }
                tokens.append(.open(name: name, href: href))
            }
        }
        flushText()
        return tokens
    }

    private static let namedEntities: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ",
        "ndash": "\u{2013}", "mdash": "\u{2014}", "hellip": "\u{2026}", "copy": "\u{00A9}",
        "lsquo": "\u{2018}", "rsquo": "\u{2019}", "ldquo": "\u{201C}", "rdquo": "\u{201D}"
    ]

    static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        var output = ""
        var remainder = Substring(text)
        while let ampersand = remainder.firstIndex(of: "&") {
            output += remainder[..<ampersand]
            let afterAmpersand = remainder[remainder.index(after: ampersand)...]
            guard let semicolon = afterAmpersand.firstIndex(of: ";"), afterAmpersand.distance(from: afterAmpersand.startIndex, to: semicolon) <= 10 else {
                output += "&"
                remainder = afterAmpersand
                continue
            }
            let entity = String(afterAmpersand[..<semicolon])
            var decoded: String? = namedEntities[entity]
            if decoded == nil, entity.hasPrefix("#") {
                let numberText = entity.dropFirst()
                let isHex = numberText.hasPrefix("x") || numberText.hasPrefix("X")
                let value = isHex ? UInt32(numberText.dropFirst(), radix: 16) : UInt32(numberText)
                if let value = value, let scalar = Unicode.Scalar(value) { decoded = String(Character(scalar)) }
            }
            if let decoded = decoded {
                output += decoded
                remainder = afterAmpersand[afterAmpersand.index(after: semicolon)...]
            } else {
                output += "&"
                remainder = afterAmpersand
            }
        }
        output += remainder
        return output
    }

    // MARK: - Builder

    private final class Builder {
        private let baseFont: NSFont
        private let textColor: NSColor
        private let result = NSMutableAttributedString()
        private let paragraph = NSMutableAttributedString()
        private var blockOpened = false
        private var listItemJustOpened = false
        private var bold = 0, italic = 0, underline = 0, strike = 0, code = 0
        private var links: [String] = []
        private var headingLevel: Int? = nil
        private var preformatted = 0
        private var lists: [(ordered: Bool, counter: Int)] = []

        init(baseFont: NSFont, textColor: NSColor) {
            self.baseFont = baseFont
            self.textColor = textColor
        }

        func consume(_ token: Token) {
            switch token {
            case .text(let text):
                appendText(text)
            case .open(let name, let href):
                open(name, href: href)
            case .close(let name):
                close(name)
            }
        }

        func finish() -> NSAttributedString {
            flushParagraph()
            if result.length > 0, result.string.hasSuffix("\n") {
                result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
            }
            return result
        }

        private func open(_ name: String, href: String?) {
            switch name {
            case "b", "strong": bold += 1
            case "i", "em": italic += 1
            case "u": underline += 1
            case "s", "strike", "del": strike += 1
            case "code": code += 1
            case "a": links.append(href ?? "")
            case "br": paragraph.append(NSAttributedString(string: lineSeparator, attributes: currentAttributes()))
            case "ul", "ol":
                flushParagraph()
                lists.append((ordered: name == "ol", counter: 0))
            case "li":
                flushParagraph()
                blockOpened = true
                if lists.isEmpty { lists.append((ordered: false, counter: 0)) }
                lists[lists.count - 1].counter += 1
                let marker = ListMarker.text(ordered: lists[lists.count - 1].ordered, number: lists[lists.count - 1].counter)
                paragraph.append(NSAttributedString(string: marker, attributes: currentAttributes()))
                listItemJustOpened = true
            case "pre":
                flushParagraph(); blockOpened = true; preformatted += 1
            case "h1", "h2", "h3", "h4", "h5", "h6":
                flushParagraph(); blockOpened = true
                headingLevel = Int(name.dropFirst())
            default:
                if NoteHTML.blockTags.contains(name) {
                    // A <p> directly inside a freshly opened <li> continues that item instead of ending it.
                    if listItemJustOpened { listItemJustOpened = false; return }
                    flushParagraph()
                    blockOpened = true
                }
            }
            if name != "li" { listItemJustOpened = false }
        }

        private func close(_ name: String) {
            switch name {
            case "b", "strong": bold = max(bold - 1, 0)
            case "i", "em": italic = max(italic - 1, 0)
            case "u": underline = max(underline - 1, 0)
            case "s", "strike", "del": strike = max(strike - 1, 0)
            case "code": code = max(code - 1, 0)
            case "a": if !links.isEmpty { links.removeLast() }
            case "ul", "ol":
                flushParagraph()
                if !lists.isEmpty { lists.removeLast() }
            case "pre":
                flushParagraph(); preformatted = max(preformatted - 1, 0)
            case "h1", "h2", "h3", "h4", "h5", "h6":
                flushParagraph(); headingLevel = nil
            default:
                if NoteHTML.blockTags.contains(name) { flushParagraph() }
            }
            listItemJustOpened = false
        }

        private func appendText(_ rawText: String) {
            var text = rawText
            if preformatted == 0 {
                text = collapseWhitespace(text)
                if text.hasPrefix(" "), paragraph.length == 0 || paragraph.string.hasSuffix(" ") || listItemJustOpened {
                    text.removeFirst()
                }
            } else {
                text = text.replacingOccurrences(of: "\n", with: lineSeparator)
            }
            guard !text.isEmpty else { return }
            listItemJustOpened = false
            paragraph.append(NSAttributedString(string: text, attributes: currentAttributes()))
        }

        private func collapseWhitespace(_ text: String) -> String {
            var output = ""
            var previousWasSpace = false
            for character in text {
                if character == " " || character == "\n" || character == "\t" || character == "\r" {
                    if !previousWasSpace { output.append(" ") }
                    previousWasSpace = true
                } else {
                    output.append(character)
                    previousWasSpace = false
                }
            }
            return output
        }

        private func flushParagraph() {
            defer { paragraph.setAttributedString(NSAttributedString()); blockOpened = false; listItemJustOpened = false }
            // Trim trailing whitespace so "text " round-trips as "text".
            while paragraph.length > 0, paragraph.string.hasSuffix(" ") {
                paragraph.deleteCharacters(in: NSRange(location: paragraph.length - 1, length: 1))
            }
            guard paragraph.length > 0 || blockOpened else { return }
            result.append(paragraph)
            result.append(NSAttributedString(string: "\n", attributes: currentAttributes()))
        }

        private func currentAttributes() -> [NSAttributedString.Key: Any] {
            var font = baseFont
            if let level = headingLevel {
                let multiplier = NoteHTML.headingSizeMultipliers[level] ?? 1.0
                font = NSFontManager.shared.convert(font, toSize: (font.pointSize * multiplier).rounded())
                font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            }
            if code > 0 || preformatted > 0 {
                font = NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .regular)
            }
            if bold > 0 { font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) }
            if italic > 0 { font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask) }

            var attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
            if underline > 0 { attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue }
            if strike > 0 { attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
            if let href = links.last, !href.isEmpty, let url = URL(string: href) { attributes[.link] = url }
            if let level = headingLevel { attributes[headingLevelKey] = level }
            if !lists.isEmpty { attributes[.paragraphStyle] = NoteHTML.listParagraphStyle(depth: lists.count) }
            return attributes
        }
    }
}
