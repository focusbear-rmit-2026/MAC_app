//
//  NoteRichTextEditor.swift
//  Focus Bear
//
//  A small rich-text editor (bold / italic / underline / bulleted + numbered lists) for the native
//  Notes view. NSTextView wrapped for SwiftUI; the bound value is the note body as HTML (see NoteHTML)
//  so the web dashboard renders exactly what was typed here.
//

import SwiftUI
import AppKit

/// Lets the SwiftUI formatting toolbar drive the underlying text view.
final class NoteEditorController: ObservableObject {
    fileprivate weak var textView: NoteTextView?

    func toggleBold() { textView?.toggleFontTrait(.boldFontMask) }
    func toggleItalic() { textView?.toggleFontTrait(.italicFontMask) }
    func toggleUnderline() { textView?.toggleUnderline() }
    func toggleBulletList() { textView?.toggleList(ordered: false) }
    func toggleNumberedList() { textView?.toggleList(ordered: true) }
    func focus() { textView?.window?.makeFirstResponder(textView) }
}

struct NoteRichTextEditor: NSViewRepresentable {
    @Binding var html: String
    let placeholder: String
    let controller: NoteEditorController

    static let baseFontSize: CGFloat = 14

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor

        let textView = NoteTextView()
        textView.delegate = context.coordinator
        textView.placeholder = placeholder
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.setContent(html: html)
        scrollView.documentView = textView

        controller.textView = textView
        context.coordinator.lastEmittedHTML = html
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NoteTextView else { return }
        textView.placeholder = placeholder
        // Only reload when the value changed from outside the editor (e.g. the brain dump arriving from
        // the API); the editor's own edits already match and reloading would reset the cursor.
        if html != context.coordinator.lastEmittedHTML {
            context.coordinator.lastEmittedHTML = html
            textView.setContent(html: html)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NoteRichTextEditor
        var lastEmittedHTML: String?

        init(_ parent: NoteRichTextEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NoteTextView else { return }
            let html = NoteHTML.html(from: textView.attributedString())
            lastEmittedHTML = html
            parent.html = html
            textView.needsDisplay = true
        }
    }
}

final class NoteTextView: NSTextView {
    var placeholder: String = "" { didSet { needsDisplay = true } }

    private static let returnKeyCode: UInt16 = 36
    private static let keypadEnterKeyCode: UInt16 = 76

    private var baseFont: NSFont { getRegularFont(size: NoteRichTextEditor.baseFontSize) }
    private var baseAttributes: [NSAttributedString.Key: Any] {
        [.font: baseFont, .foregroundColor: NSColor.textColor]
    }

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        configure()
    }

    convenience init() {
        let storage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)
        let container = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        layoutManager.addTextContainer(container)
        self.init(frame: .zero, textContainer: container)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isRichText = true
        importsGraphics = false
        usesFontPanel = false
        usesRuler = false
        allowsUndo = true
        isAutomaticLinkDetectionEnabled = false
        isContinuousSpellCheckingEnabled = true
        drawsBackground = true
        backgroundColor = .textBackgroundColor
        textColor = .textColor
        insertionPointColor = .textColor
        font = baseFont
        typingAttributes = baseAttributes
    }

    func setContent(html: String) {
        let attributed = NoteHTML.attributedString(fromHTML: html, baseFont: baseFont, textColor: .textColor)
        textStorage?.setAttributedString(attributed)
        typingAttributes = baseAttributes
        undoManager?.removeAllActions()
        needsDisplay = true
    }

    // MARK: Placeholder

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard string.isEmpty, !placeholder.isEmpty else { return }
        let attributes: [NSAttributedString.Key: Any] = [.font: baseFont, .foregroundColor: NSColor.placeholderTextColor]
        let origin = NSPoint(x: textContainerInset.width + (textContainer?.lineFragmentPadding ?? 5),
                             y: textContainerInset.height)
        (placeholder as NSString).draw(at: origin, withAttributes: attributes)
    }

    override func becomeFirstResponder() -> Bool {
        needsDisplay = true
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        needsDisplay = true
        return super.resignFirstResponder()
    }

    // MARK: Keys

    /// Return must be swallowed at the key-equivalent stage: in the app's borderless full-screen
    /// window the default button (the routine's habit "Start") otherwise fires first — see
    /// NewlineKeepingTextView in Schedule/DayPlanTasks.swift. ⌘B / ⌘I / ⌘U format because the app's
    /// main menu has no Format menu to provide those key equivalents.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown, window?.firstResponder === self else {
            return super.performKeyEquivalent(with: event)
        }
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if event.keyCode == NoteTextView.returnKeyCode || event.keyCode == NoteTextView.keypadEnterKeyCode {
            if modifiers.contains(.shift) || modifiers.contains(.option) {
                insertLineBreak(nil)
            } else {
                insertNewline(nil)
            }
            return true
        }
        if modifiers == .command, let key = event.charactersIgnoringModifiers?.lowercased() {
            switch key {
            case "b": toggleFontTrait(.boldFontMask); return true
            case "i": toggleFontTrait(.italicFontMask); return true
            case "u": toggleUnderline(); return true
            default: break
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    /// Continue a list on Return; Return on an empty list item ends the list instead.
    override func insertNewline(_ sender: Any?) {
        let selection = selectedRange()
        let nsString = string as NSString
        let paragraphRange = nsString.paragraphRange(for: NSRange(location: selection.location, length: 0))
        let paragraphText = nsString.substring(with: paragraphRange).trimmingCharacters(in: CharacterSet(charactersIn: "\n"))
        guard selection.length == 0, let marker = NoteHTML.ListMarker.detect(in: paragraphText) else {
            super.insertNewline(sender)
            return
        }
        if paragraphText.utf16.count == marker.length {
            // Empty item: remove the marker and leave the list.
            let markerRange = NSRange(location: paragraphRange.location, length: marker.length)
            replace(range: markerRange, with: "", attributes: baseAttributes, paragraphStyle: NSParagraphStyle.default)
            return
        }
        let depth = NoteHTML.listDepth(of: typingAttributes[.paragraphStyle] as? NSParagraphStyle)
        super.insertNewline(sender)
        let nextMarker = NoteHTML.ListMarker.text(ordered: marker.ordered, number: marker.number + 1)
        var attributes = typingAttributes
        attributes[.paragraphStyle] = NoteHTML.listParagraphStyle(depth: depth)
        replace(range: selectedRange(), with: nextMarker, attributes: attributes, paragraphStyle: NoteHTML.listParagraphStyle(depth: depth))
    }

    /// Pasted rich text is normalised through the HTML converter so foreign fonts/colours never leak
    /// into a note; anything without HTML pastes as plain text.
    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        if let htmlData = pasteboard.data(forType: .html), let html = String(data: htmlData, encoding: .utf8) {
            let attributed = NoteHTML.attributedString(fromHTML: html, baseFont: baseFont, textColor: .textColor)
            let range = selectedRange()
            if shouldChangeText(in: range, replacementString: attributed.string) {
                textStorage?.replaceCharacters(in: range, with: attributed)
                didChangeText()
                setSelectedRange(NSRange(location: range.location + attributed.length, length: 0))
            }
            return
        }
        pasteAsPlainText(sender)
    }

    // MARK: Formatting

    func toggleFontTrait(_ trait: NSFontTraitMask) {
        let fontManager = NSFontManager.shared
        let range = selectedRange()
        if range.length == 0 {
            var attributes = typingAttributes
            let font = attributes[.font] as? NSFont ?? baseFont
            let hasTrait = fontManager.traits(of: font).contains(trait)
            attributes[.font] = hasTrait ? fontManager.convert(font, toNotHaveTrait: trait) : fontManager.convert(font, toHaveTrait: trait)
            typingAttributes = attributes
            return
        }
        guard let storage = textStorage, shouldChangeText(in: range, replacementString: nil) else { return }
        var everyRunHasTrait = true
        storage.enumerateAttribute(.font, in: range, options: []) { value, _, _ in
            let font = value as? NSFont ?? baseFont
            if !fontManager.traits(of: font).contains(trait) { everyRunHasTrait = false }
        }
        storage.beginEditing()
        storage.enumerateAttribute(.font, in: range, options: []) { value, runRange, _ in
            let font = value as? NSFont ?? baseFont
            let newFont = everyRunHasTrait ? fontManager.convert(font, toNotHaveTrait: trait) : fontManager.convert(font, toHaveTrait: trait)
            storage.addAttribute(.font, value: newFont, range: runRange)
        }
        storage.endEditing()
        didChangeText()
    }

    /// Underline toggle done directly on the storage / selection (not the system `underline(_:)`),
    /// so it works even though clicking the SwiftUI toolbar button takes first responder off the text
    /// view — matching how toggleFontTrait handles bold/italic.
    func toggleUnderline() {
        let single = NSUnderlineStyle.single.rawValue
        let range = selectedRange()
        if range.length == 0 {
            var attributes = typingAttributes
            let underlined = (attributes[.underlineStyle] as? Int ?? 0) != 0
            if underlined { attributes[.underlineStyle] = 0 } else { attributes[.underlineStyle] = single }
            typingAttributes = attributes
            return
        }
        guard let storage = textStorage, shouldChangeText(in: range, replacementString: nil) else { return }
        var everyRunUnderlined = true
        storage.enumerateAttribute(.underlineStyle, in: range, options: []) { value, _, _ in
            if (value as? Int ?? 0) == 0 { everyRunUnderlined = false }
        }
        storage.beginEditing()
        storage.addAttribute(.underlineStyle, value: everyRunUnderlined ? 0 : single, range: range)
        storage.endEditing()
        didChangeText()
    }

    /// Adds list markers to every paragraph in the selection, or removes them when they all already
    /// carry a marker of the requested kind.
    func toggleList(ordered: Bool) {
        guard let storage = textStorage else { return }
        let nsString = string as NSString
        let selection = selectedRange()
        let affected = nsString.paragraphRange(for: selection)
        var paragraphRanges: [NSRange] = []
        var location = affected.location
        repeat {
            let range = nsString.paragraphRange(for: NSRange(location: location, length: 0))
            paragraphRanges.append(range)
            location = NSMaxRange(range)
        } while location < NSMaxRange(affected) && location < nsString.length
        if paragraphRanges.isEmpty { paragraphRanges = [affected] }

        let markers = paragraphRanges.map { NoteHTML.ListMarker.detect(in: nsString.substring(with: $0)) }
        let removing = markers.allSatisfy { $0 != nil && $0!.ordered == ordered }

        guard shouldChangeText(in: affected, replacementString: nil) else { return }
        storage.beginEditing()
        var number = 0
        // Edit back-to-front so earlier ranges stay valid.
        for (index, paragraphRange) in paragraphRanges.enumerated().reversed() {
            let existing = markers[index]
            let existingLength = existing?.length ?? 0
            let markerRange = NSRange(location: paragraphRange.location, length: existingLength)
            if removing {
                storage.replaceCharacters(in: markerRange, with: "")
                let remaining = NSRange(location: paragraphRange.location, length: paragraphRange.length - existingLength)
                storage.addAttribute(.paragraphStyle, value: NSParagraphStyle.default, range: remaining)
            } else {
                number = paragraphRanges.count - index
                let marker = NSAttributedString(string: NoteHTML.ListMarker.text(ordered: ordered, number: number), attributes: baseAttributes)
                storage.replaceCharacters(in: markerRange, with: marker)
                let updated = NSRange(location: paragraphRange.location, length: paragraphRange.length - existingLength + marker.length)
                storage.addAttribute(.paragraphStyle, value: NoteHTML.listParagraphStyle(depth: 1), range: updated)
            }
        }
        storage.endEditing()
        didChangeText()
        var typing = typingAttributes
        typing[.paragraphStyle] = removing ? NSParagraphStyle.default : NoteHTML.listParagraphStyle(depth: 1)
        typingAttributes = typing
    }

    private func replace(range: NSRange, with text: String, attributes: [NSAttributedString.Key: Any], paragraphStyle: NSParagraphStyle) {
        guard let storage = textStorage, shouldChangeText(in: range, replacementString: text) else { return }
        var styled = attributes
        styled[.paragraphStyle] = paragraphStyle
        storage.replaceCharacters(in: range, with: NSAttributedString(string: text, attributes: styled))
        didChangeText()
        setSelectedRange(NSRange(location: range.location + (text as NSString).length, length: 0))
        var typing = typingAttributes
        typing[.paragraphStyle] = paragraphStyle
        typingAttributes = typing
    }
}
