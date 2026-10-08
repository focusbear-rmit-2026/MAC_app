//
//  MarkdownText.swift
//  Focus Bear
//
//  Renders the pragmatic markdown subset the motivational-summary stream emits (paragraphs, bold,
//  italic, code, headings, bullet / numbered lines, links). The app targets macOS 11, so
//  `AttributedString(markdown:)` (macOS 12) is out; instead a tiny parser produces styled runs that
//  are concatenated into `SwiftUI.Text` values. The parser re-runs on every streamed chunk, so it
//  stays a single linear scan and leaves any marker it cannot close as literal text.
//

import SwiftUI
import AppKit

// MARK: - Model

struct MarkdownRun: Equatable {
    var text: String
    var isBold = false
    var isItalic = false
    var isCode = false
    var linkURL: String? = nil
}

enum MarkdownBlock: Equatable {
    case paragraph([MarkdownRun])
    case heading(level: Int, runs: [MarkdownRun])
    case bullet([MarkdownRun])
    case numbered(label: String, runs: [MarkdownRun])

    var runs: [MarkdownRun] {
        switch self {
        case .paragraph(let runs), .bullet(let runs): return runs
        case .heading(_, let runs), .numbered(_, let runs): return runs
        }
    }

    var plainText: String { runs.map { $0.text }.joined() }
}

// MARK: - Parser

enum MarkdownParser {
    static let maxHeadingLevel = 3
    private static let headingMarker: Character = "#"
    private static let bulletMarkers: Set<Character> = ["-", "*", "•"]
    private static let codeMarker: Character = "`"
    private static let boldMarkers = ["**", "__"]
    private static let italicMarkers: [Character] = ["*", "_"]
    private static let numberedSeparators: Set<Character> = [".", ")"]

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraphLines: [String] = []

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(.paragraph(parseInline(paragraphLines.joined(separator: "\n"))))
            paragraphLines = []
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
            } else if let block = lineBlock(line) {
                flushParagraph()
                blocks.append(block)
            } else {
                paragraphLines.append(line)
            }
        }
        flushParagraph()
        return blocks
    }

    /// Headings and list items are one line each; anything else joins the surrounding paragraph.
    private static func lineBlock(_ line: String) -> MarkdownBlock? {
        if let heading = heading(line) { return heading }
        if let bullet = bullet(line) { return bullet }
        return numbered(line)
    }

    private static func heading(_ line: String) -> MarkdownBlock? {
        let level = line.prefix { $0 == headingMarker }.count
        guard level >= 1, level <= maxHeadingLevel else { return nil }
        let rest = line.dropFirst(level)
        guard rest.first == " " else { return nil }
        return .heading(level: level, runs: parseInline(String(rest).trimmingCharacters(in: .whitespaces)))
    }

    private static func bullet(_ line: String) -> MarkdownBlock? {
        guard let marker = line.first, bulletMarkers.contains(marker) else { return nil }
        let rest = line.dropFirst()
        guard rest.first == " " else { return nil }
        return .bullet(parseInline(String(rest).trimmingCharacters(in: .whitespaces)))
    }

    private static func numbered(_ line: String) -> MarkdownBlock? {
        let digits = line.prefix { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        let afterDigits = line.dropFirst(digits.count)
        guard let separator = afterDigits.first, numberedSeparators.contains(separator) else { return nil }
        let rest = afterDigits.dropFirst()
        guard rest.first == " " else { return nil }
        return .numbered(label: String(digits) + String(separator), runs: parseInline(String(rest).trimmingCharacters(in: .whitespaces)))
    }

    // MARK: Inline

    static func parseInline(_ text: String) -> [MarkdownRun] {
        parseInline(Array(text), style: MarkdownRun(text: ""))
    }

    /// Single pass over the characters; a recognised span is parsed recursively with its style
    /// applied so `**bold *and italic***` nests, and an unmatched marker is emitted as literal text.
    private static func parseInline(_ chars: [Character], style: MarkdownRun) -> [MarkdownRun] {
        var runs: [MarkdownRun] = []
        var literal = ""
        var index = 0

        func flushLiteral() {
            guard !literal.isEmpty else { return }
            var run = style
            run.text = literal
            append(run, to: &runs)
            literal = ""
        }

        while index < chars.count {
            if let span = span(in: chars, at: index, style: style) {
                flushLiteral()
                span.runs.forEach { append($0, to: &runs) }
                index = span.end
            } else {
                literal.append(chars[index])
                index += 1
            }
        }
        flushLiteral()
        return runs
    }

    private struct Span {
        let runs: [MarkdownRun]
        let end: Int
    }

    private static func span(in chars: [Character], at index: Int, style: MarkdownRun) -> Span? {
        if style.isCode { return nil }
        if let code = codeSpan(in: chars, at: index, style: style) { return code }
        if let link = linkSpan(in: chars, at: index, style: style) { return link }
        for marker in boldMarkers where !style.isBold {
            if let bold = emphasisSpan(in: chars, at: index, marker: Array(marker), style: style, apply: { $0.isBold = true }) { return bold }
        }
        for marker in italicMarkers where !style.isItalic {
            if let italic = emphasisSpan(in: chars, at: index, marker: [marker], style: style, apply: { $0.isItalic = true }) { return italic }
        }
        return nil
    }

    private static func codeSpan(in chars: [Character], at index: Int, style: MarkdownRun) -> Span? {
        guard chars[index] == codeMarker else { return nil }
        guard let close = firstIndex(of: [codeMarker], in: chars, from: index + 1), close > index + 1 else { return nil }
        var run = style
        run.isCode = true
        run.text = String(chars[(index + 1)..<close])
        return Span(runs: [run], end: close + 1)
    }

    private static func linkSpan(in chars: [Character], at index: Int, style: MarkdownRun) -> Span? {
        guard chars[index] == "[", let closeBracket = firstIndex(of: ["]"], in: chars, from: index + 1) else { return nil }
        let urlStart = closeBracket + 1
        guard urlStart < chars.count, chars[urlStart] == "(", let closeParen = firstIndex(of: [")"], in: chars, from: urlStart + 1) else { return nil }
        let url = String(chars[(urlStart + 1)..<closeParen])
        guard !url.isEmpty, !url.contains(" ") else { return nil }
        var linkStyle = style
        linkStyle.linkURL = url
        let inner = Array(chars[(index + 1)..<closeBracket])
        return Span(runs: parseInline(inner, style: linkStyle), end: closeParen + 1)
    }

    /// A marker opens a span only when it hugs non-space text on the inside and closes only when the
    /// text before it is not a space, so "2 * 3 * 4" and snake_case_words stay literal.
    private static func emphasisSpan(in chars: [Character], at index: Int, marker: [Character], style: MarkdownRun,
                                     apply: (inout MarkdownRun) -> Void) -> Span? {
        let contentStart = index + marker.count
        guard matches(marker, in: chars, at: index), contentStart < chars.count, !chars[contentStart].isWhitespace else { return nil }
        // Either half of a `**` that has not closed yet (mid-stream) is a pending bold opener, not
        // an italic opener wrapping a stray star.
        if marker.count == 1, chars[contentStart] == marker[0] { return nil }
        if marker.count == 1, index > 0, chars[index - 1] == marker[0] { return nil }
        if marker == ["_"], index > 0, chars[index - 1].isLetter || chars[index - 1].isNumber { return nil }
        guard let close = closingIndex(of: marker, in: chars, from: contentStart) else { return nil }
        var innerStyle = style
        apply(&innerStyle)
        let inner = Array(chars[contentStart..<close])
        return Span(runs: parseInline(inner, style: innerStyle), end: close + marker.count)
    }

    private static func closingIndex(of marker: [Character], in chars: [Character], from start: Int) -> Int? {
        var index = start
        while index + marker.count <= chars.count {
            if matches(marker, in: chars, at: index) {
                let isDoubled = marker.count == 1 && index + 1 < chars.count && chars[index + 1] == marker[0]
                if isDoubled {
                    // A `**` inside a `*…*` span is a nested bold marker, not the italic closer.
                    index += 2
                    continue
                }
                if index > start, !chars[index - 1].isWhitespace {
                    if marker == ["_"], index + 1 < chars.count, chars[index + 1].isLetter || chars[index + 1].isNumber {
                        index += 1
                        continue
                    }
                    return index
                }
            }
            index += 1
        }
        return nil
    }

    private static func firstIndex(of marker: [Character], in chars: [Character], from start: Int) -> Int? {
        var index = start
        while index + marker.count <= chars.count {
            if matches(marker, in: chars, at: index) { return index }
            index += 1
        }
        return nil
    }

    private static func matches(_ marker: [Character], in chars: [Character], at index: Int) -> Bool {
        guard index + marker.count <= chars.count else { return false }
        return Array(chars[index..<(index + marker.count)]) == marker
    }

    /// Adjacent runs with identical styling merge so the rendered `Text` stays small.
    private static func append(_ run: MarkdownRun, to runs: inout [MarkdownRun]) {
        guard !run.text.isEmpty else { return }
        if var last = runs.last, last.isBold == run.isBold, last.isItalic == run.isItalic, last.isCode == run.isCode, last.linkURL == run.linkURL {
            last.text += run.text
            runs[runs.count - 1] = last
        } else {
            runs.append(run)
        }
    }
}

// MARK: - View

struct MarkdownText: View {
    let markdown: String
    var fontSize: CGFloat = 15
    var lineSpacing: CGFloat = 4
    var alignment: TextAlignment = .leading

    private static let blockSpacing: CGFloat = 10
    private static let listIndent: CGFloat = 6
    private static let bulletGlyph = "•"
    /// Extra points over the body size for `#`, `##`, `###`.
    private static let headingSizeIncrements: [CGFloat] = [8, 4, 2]
    private static let linkColor = Color(NSColor.linkColor)

    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: MarkdownText.blockSpacing) {
            ForEach(Array(MarkdownParser.parse(markdown).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch alignment {
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .paragraph(let runs):
            styledText(runs, size: fontSize, weight: .regular)
        case .heading(let level, let runs):
            styledText(runs, size: fontSize + headingIncrement(level), weight: .bold)
        case .bullet(let runs):
            listItem(marker: MarkdownText.bulletGlyph, runs: runs)
        case .numbered(let label, let runs):
            listItem(marker: label, runs: runs)
        }
    }

    private func headingIncrement(_ level: Int) -> CGFloat {
        let index = min(max(level, 1), MarkdownText.headingSizeIncrements.count) - 1
        return MarkdownText.headingSizeIncrements[index]
    }

    /// The marker hugs its text so a centred list item centres as one unit rather than leaving the
    /// marker stranded at the edge.
    private func listItem(marker: String, runs: [MarkdownRun]) -> some View {
        HStack(alignment: .top, spacing: MarkdownText.listIndent) {
            SwiftUI.Text(marker).font(.system(size: fontSize))
            paragraphText(runs, size: fontSize, weight: .regular)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func styledText(_ runs: [MarkdownRun], size: CGFloat, weight: Font.Weight) -> some View {
        paragraphText(runs, size: size, weight: weight)
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: horizontalAlignment, vertical: .center))
    }

    /// Concatenated `Text` runs wrap as one paragraph. Tapping a paragraph opens its first link —
    /// per-run tap targets need `AttributedString` links (macOS 12+).
    private func paragraphText(_ runs: [MarkdownRun], size: CGFloat, weight: Font.Weight) -> some View {
        let text = runs.map { MarkdownText.text(for: $0, size: size, weight: weight) }.reduce(SwiftUI.Text(""), +)
        let firstLink = runs.compactMap { $0.linkURL }.first.flatMap(URL.init(string:))
        return text
            .lineSpacing(lineSpacing)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture {
                if let url = firstLink { NSWorkspace.shared.open(url) }
            }
    }

    private static func text(for run: MarkdownRun, size: CGFloat, weight: Font.Weight) -> SwiftUI.Text {
        var text = SwiftUI.Text(run.text)
        text = text.font(.system(size: size, weight: run.isBold ? .bold : weight, design: run.isCode ? .monospaced : .default))
        if run.isItalic { text = text.italic() }
        if run.linkURL != nil { text = text.foregroundColor(linkColor).underline() }
        return text
    }
}
