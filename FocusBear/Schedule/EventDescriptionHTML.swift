//
//  EventDescriptionHTML.swift
//  Focus Bear
//
//  Google Calendar stores an event's description as HTML, so the Day Plan's event editor was showing
//  the source instead of the text — "<br>Focus and Chill podcast recording<br><a href="https://…"
//  target="_blank">https://…</a>", with a stray target="_blank" mid-sentence.
//
//  Reported as: "Can you make it render HTML? (safely - don't run scripts). Best way would be just to
//  support <br>, <b>, <a> and not styles or scripts" (report 2026-09-16_10-20-00).
//
//  Deliberately NOT NSAttributedString(html:) / .documentType: .html. That instantiates a WebKit
//  parser, is main-thread only, and will fetch and run remote content — which is the exact thing
//  "don't run scripts" rules out, and blocking WebKit on the main thread has hung this app before.
//
//  The tokenizer is NoteHTML's, so the app keeps one HTML parser rather than growing a third; only
//  the rendering policy is new, and it is narrower than NoteHTML's note subset on purpose. An event
//  description is markup from whoever sent the invite, so exactly three tags are honoured — <br>,
//  <b>, <a> — and everything else is stripped.
//

import AppKit

enum EventDescriptionHTML {

    /// One stretch of description text sharing the same styling.
    struct Run: Equatable {
        var text: String
        var isBold: Bool
        var link: URL?
    }

    /// Tags whose *content* is code rather than prose, so their text is dropped along with the tag.
    /// Every other unsupported tag is stripped but keeps whatever text it wrapped, so a description
    /// wrapped in <div>/<p>/<span> still reads normally.
    private static let rawTextTags: Set<String> = ["script", "style"]

    /// The URL a description's link may actually open, or nil when it must not be clickable.
    /// `javascript:` and `file:` hrefs render as ordinary text — legible, never actionable.
    static func openableURL(from href: String) -> URL? {
        NoteHTML.openableURL(from: href)
    }

    // MARK: - Rendering

    static func runs(from html: String) -> [Run] {
        var runs: [Run] = []
        var buffer = ""
        var boldDepth = 0
        var linkDepth = 0
        var linkURL: URL?
        /// Depth inside a <script>/<style>, whose text is swallowed rather than shown.
        var suppressDepth = 0

        func flush() {
            guard !buffer.isEmpty else { return }
            runs.append(Run(text: buffer, isBold: boldDepth > 0, link: linkURL))
            buffer = ""
        }

        for token in NoteHTML.tokenize(html) {
            switch token {
            case .text(let text):
                guard suppressDepth == 0 else { continue }
                buffer += text

            case .open(let name, let href):
                switch name {
                case "br":
                    guard suppressDepth == 0 else { continue }
                    buffer += "\n"
                case "b":
                    flush()
                    boldDepth += 1
                case "a":
                    flush()
                    linkDepth += 1
                    linkURL = openableURL(from: href ?? "")
                default:
                    if rawTextTags.contains(name) { suppressDepth += 1 }
                }

            case .close(let name):
                switch name {
                case "b":
                    flush()
                    boldDepth = max(boldDepth - 1, 0)
                case "a":
                    flush()
                    linkDepth = max(linkDepth - 1, 0)
                    if linkDepth == 0 { linkURL = nil }
                default:
                    if rawTextTags.contains(name) { suppressDepth = max(suppressDepth - 1, 0) }
                }
            }
        }
        flush()
        return trimmingEnds(runs)
    }

    /// The description as the user reads it: tags gone, entities decoded, <br> as line breaks.
    static func plainText(from html: String) -> String {
        runs(from: html).map(\.text).joined()
    }

    /// The description as the editor shows it: <b> bold, an http(s) <a> as a link, nothing else.
    static func attributedString(from html: String, font: NSFont, textColor: NSColor) -> NSAttributedString {
        let bold = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        let result = NSMutableAttributedString()
        for run in runs(from: html) {
            var attributes: [NSAttributedString.Key: Any] = [
                .font: run.isBold ? bold : font,
                .foregroundColor: textColor,
            ]
            if let link = run.link {
                attributes[.link] = link
                attributes[.foregroundColor] = NSColor.linkColor
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            result.append(NSAttributedString(string: run.text, attributes: attributes))
        }
        return result
    }

    // MARK: - Saving

    /// What to write back to the calendar event's description.
    ///
    /// The field shows the description *rendered*, so saving what it displays would replace the
    /// event's HTML with flattened text — dropping the links and formatting for every other attendee,
    /// even when the user only opened the editor to move the meeting by half an hour. So the original
    /// source is kept and written back verbatim unless the user actually changed the description;
    /// only a real edit is allowed to rewrite it, and then it is their text that wins.
    static func notesToSave(edited: String, rendered: String, original: String) -> String {
        edited == rendered ? original : edited
    }

    // MARK: - Helpers

    /// Drop leading/trailing blank space, so a description that opens with `<br>` (as Google
    /// Calendar's do) doesn't render with an empty first line.
    private static func trimmingEnds(_ runs: [Run]) -> [Run] {
        var result = runs
        while let first = result.first {
            let trimmed = String(first.text.drop(while: { $0.isWhitespace }))
            if trimmed.isEmpty { result.removeFirst() } else { result[0].text = trimmed; break }
        }
        while let last = result.last {
            var text = last.text
            while let character = text.last, character.isWhitespace { text.removeLast() }
            if text.isEmpty { result.removeLast() } else { result[result.count - 1].text = text; break }
        }
        return result
    }
}
