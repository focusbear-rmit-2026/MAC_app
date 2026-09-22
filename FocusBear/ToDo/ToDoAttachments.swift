//
//  ToDoAttachments.swift
//  Focus Bear
//
//  Task attachments — the store, the list, the file picker and the in-app preview — in ONE place, so
//  every screen that shows a task's files shows the same ones and behaves the same way.
//
//  It started life inside `ToDoEditorView`. The Day Plan's task-details modal asked for the same
//  feature (report 2026-09-15_20-54-33), and a second copy would have drifted immediately: the
//  preview's ✕ / scrolling / PDF fixes landed the same evening and would have had to be made twice.
//
//  The wire flow is the backend's: `POST /to-do/:id/attachments/generate-upload-url` hands back a
//  presigned R2 URL, the bytes go straight there (no Authorization header — the signature IS the
//  auth), then `POST /to-do/:id/attachments` records it.
//

import SwiftUI
import AppKit
import PDFKit

// MARK: - An image off the clipboard

/// An image lifted from the pasteboard, ready to go through the ordinary upload path.
///
/// A pasted picture has no filename and often no PNG representation either — a screenshot taken with
/// ⌃⌘⇧4 arrives as TIFF — so both are decided here, once, rather than at each place that accepts a
/// paste.
struct ToDoPastedImage: Equatable {
    let data: Data
    let fileName: String
    let contentType: String
}

/// Reading an image off the pasteboard, and deciding whether ⌘V is ours to take.
enum ToDoImagePaste {
    /// Everything is normalised to PNG: it is lossless, every consumer of the attachment (the preview
    /// here, the web app, the phone) reads it, and it spares the rest of the app a content type that
    /// depends on which app the user copied from.
    static let contentType = "image/png"
    static let fileExtension = "png"
    /// Not localised on purpose — it is a filename, and a file the user downloads on another device
    /// should not be named in whatever language this Mac happens to run in. Shaped like macOS's own
    /// screenshot names so it sorts and reads sensibly in a file list.
    static let fileNamePrefix = "pasted-image"
    static let fileNameDateFormat = "yyyy-MM-dd-HHmmss"

    /// The PNG bytes on `pasteboard`, or nil when it carries no image at all.
    ///
    /// `NSImage` rather than the raw PNG type: the pasteboard may hold TIFF, PDF or a file promise,
    /// and `NSImage` is the one reader that copes with all of them. The bytes are then re-encoded, so
    /// what is uploaded is always a PNG whatever arrived.
    static func image(on pasteboard: NSPasteboard, now: Date = Date()) -> ToDoPastedImage? {
        guard let image = pasteboard.readObjects(forClasses: [NSImage.self])?.first as? NSImage,
              let png = pngData(from: image) else { return nil }
        return ToDoPastedImage(data: png, fileName: fileName(at: now), contentType: contentType)
    }

    /// `yyyy-MM-dd-HHmmss` in the POSIX locale, so the name cannot pick up Arabic-Indic digits or a
    /// Japanese era from the user's region and become unreadable on another device.
    static func fileName(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = fileNameDateFormat
        return "\(fileNamePrefix)-\(formatter.string(from: date)).\(fileExtension)"
    }

    static func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }

    /// Whether ⌘V should attach the clipboard image instead of reaching the focused control.
    ///
    /// The rule that matters: **a paste that could put text somewhere is never stolen.** So when the
    /// user is in a field and the clipboard carries text as well as a picture — copied from a web
    /// page, say — the text wins and this returns false. Typing a task title and pasting into it keeps
    /// working exactly as it did, which is the whole risk of the feature.
    ///
    /// A bare screenshot is the other case: it has no text representation, so pasting it into a text
    /// field does nothing at all today. Attaching it is strictly better than the no-op, and it is what
    /// was asked for, so focus does not veto that one.
    ///
    /// Focus is read from the window's first responder by the caller, never from what was last
    /// clicked: a SwiftUI button click does not move the first responder, so an AppKit field editor
    /// can still hold focus while a SwiftUI control is being used.
    /// A screenshot tool that copies a *file* rather than pixels is the case this originally got
    /// wrong. CleanShot puts the file's path on the pasteboard alongside the image, so `hasText` was
    /// true, focus vetoed the attach, and ⌘V typed
    /// `/Users/…/CleanShot 2026-09-16 at 16.44.23.png` into the field (report 2026-09-15_20-54-33).
    /// A path to an image the user just captured is not text they meant to paste, so it does not veto.
    static func shouldAttach(hasImage: Bool, hasText: Bool, isEditingText: Bool,
                             textIsOnlyAnImagePath: Bool = false) -> Bool {
        guard hasImage else { return false }
        return !(isEditingText && hasText && !textIsOnlyAnImagePath)
    }

    /// True when every string on the pasteboard is just the path/URL of an image file it also carries
    /// — the shape a screenshot tool produces, as opposed to text that happens to accompany a picture.
    static func textIsOnlyAnImagePath(on pasteboard: NSPasteboard) -> Bool {
        let urls = pasteboard.readObjects(forClasses: [NSURL.self],
                                          options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        let imageURLs = urls.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
        guard !imageURLs.isEmpty else { return false }
        let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String] ?? []
        // Nothing but those files' own paths/URLs: any other string is real text and must still win.
        let known = Set(imageURLs.flatMap { [$0.path, $0.absoluteString] })
        return strings.allSatisfy { known.contains($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "heic", "tiff", "tif", "bmp", "webp"]

    /// Whether `responder` is somewhere the user is typing.
    ///
    /// An `NSTextField` hands focus to its field editor, an `NSTextView`, which is an `NSText` — so
    /// that one case covers every field in these screens. Editability is what is actually asked: a
    /// selectable label is a text view too, and pasting has nowhere to go in one, so it must not veto.
    static func isEditingText(_ responder: NSResponder?) -> Bool {
        switch responder {
        case let text as NSText: return text.isEditable
        case let field as NSTextField: return field.isEditable
        default: return false
        }
    }

    /// Does this pasteboard carry text a focused field could accept?
    static func hasText(on pasteboard: NSPasteboard) -> Bool {
        pasteboard.canReadObject(forClasses: [NSString.self], options: nil)
    }
}

/// Where a pasted image goes on a host whose task has no server id **yet**.
///
/// The Day Plan's details sheet is the case: attachments hang off `/to-do/:id`, and a from-scratch row
/// only gets a to-do a network round trip after it is created. Without this the sheet simply refused
/// ⌘V for that whole window, and the key travelled on and typed a screenshot's path into Details
/// (report 2026-09-15_20-54-33, reported four times). It mirrors what the menu's quick-add already
/// does: hold the picture, show that it was taken, upload it when the task exists.
struct ToDoPendingImageSink {
    /// Asked the instant ⌘V is pressed. False means this host can never take the image — a Day Plan
    /// row with no name is never minted, so there would be nowhere for it to go — and the key is then
    /// left to the focused control rather than swallowed.
    let canHold: () -> Bool
    /// Take the image and see it uploaded once the task is backed.
    let hold: (ToDoPastedImage) -> Void
}

/// What a host should do with a ⌘V, given what it can do right now.
///
/// Pure so the routing — which was the actual bug, not the paste rule — is unit-tested rather than
/// inferred from a log.
enum ToDoPasteRoute: Equatable {
    /// Upload it now: the task has a server id.
    case attachNow
    /// Hold it until the task has one.
    case holdUntilBacked
    /// Leave ⌘V alone; there is nowhere for an image to go, now or later.
    case leaveAlone

    static func decide(canAttachNow: Bool, canHoldForLater: Bool) -> ToDoPasteRoute {
        if canAttachNow { return .attachNow }
        return canHoldForLater ? .holdUntilBacked : .leaveAlone
    }
}

/// Which window a ⌘V has to arrive at for a given host to claim it.
///
/// The shipped test was `event === host || event.sheetParent === host || event.parent === host` — it
/// only ever looked DOWN from the host, at sheets and child windows sitting on top of it. An
/// `NSPopover` is the other way round: its window is a **child of the window it is anchored in**, so
/// when the key is delivered to that parent the test can never pass. Measured with a probe that
/// mirrors `openTaskModal` — `popover.parent` is the main window, the shipped test answers false, a
/// reversed one answers true — and it matches the log exactly:
///
///     paste image: ⌘V ignored, event window is not this host
///                  (event=CustomWindow host=_NSPopoverWindow)
///
/// `CustomWindow` is this app's main window (`Main.storyboard`, `mainWindowController`), and the Day
/// Plan's task details is a popover anchored inside it. So the details sheet's monitor was running and
/// looking, and threw every paste away (report 2026-09-15_20-54-33, rounds 1-5).
enum ToDoPasteWindowMatch {
    /// How far up a window chain to walk. Deep enough for popover → window → sheet; short enough that
    /// a cycle cannot hang the event monitor.
    static let maximumDepth = 8

    /// Is a key event delivered to `event` one this `host` should consider its own?
    ///
    /// Walks BOTH directions, because either window can be the one hanging off the other: a sheet or
    /// popover presented *on* the host, and a host that is itself a popover *on* the event's window.
    static func isRelated(event: NSWindow?, host: NSWindow?) -> Bool {
        guard let event = event, let host = host else { return false }
        if event === host { return true }
        if chain(from: event).contains(where: { $0 === host }) { return true }
        return chain(from: host).contains(where: { $0 === event })
    }

    /// A window and everything it hangs off — its sheet parent, then its parent window.
    static func chain(from window: NSWindow) -> [NSWindow] {
        var walked: [NSWindow] = []
        var current: NSWindow? = window
        while let step = current, walked.count < maximumDepth {
            if walked.contains(where: { $0 === step }) { break }
            walked.append(step)
            current = step.sheetParent ?? step.parent
        }
        return walked
    }

    /// The chain as text for the log — the one thing that makes a rejected paste readable afterwards.
    static func describe(_ window: NSWindow?) -> String {
        guard let window = window else { return "nil" }
        return chain(from: window).map { String(describing: type(of: $0)) }.joined(separator: "<-")
    }
}

/// ⌘V on a screen that can hold attachments, written once for all of them.
///
/// A local event monitor rather than SwiftUI's `onPasteCommand`: that needs the view to be focused,
/// and the screens this serves put focus in a text field the moment they open. The monitor is scoped
/// to one window, so a paste in any other part of the app is never even looked at.
final class ToDoImagePasteMonitor {
    private var monitor: Any?
    private let window: () -> NSWindow?
    private let canAccept: () -> Bool
    private let onImage: (ToDoPastedImage) -> Void
    private let label: String

    /// - Parameters:
    ///   - window: evaluated per event, because a host's window does not exist yet when it builds its
    ///     view and can change underneath it afterwards.
    ///   - canAccept: asked at the moment ⌘V is pressed, not when the view was last drawn. Whether a
    ///     Day Plan task can take a file changes while its details sheet sits open — the to-do is
    ///     minted a round trip after the row is created — and a flag captured at render time says
    ///     "no" for the rest of the sheet's life. That stale "no" is what stopped the monitor from
    ///     ever looking at ⌘V (report 2026-09-15_20-54-33, fourth round).
    ///   - label: which screen this is, in the log. Several monitors are alive at once and every one
    ///     described its host as `_NSPopoverWindow`, so a rejected paste could not be pinned on a
    ///     surface — the ambiguity that made four rounds of this report unreadable.
    init(label: String, window: @escaping () -> NSWindow?, canAccept: @escaping () -> Bool = { true },
         onImage: @escaping (ToDoPastedImage) -> Void) {
        self.label = label
        self.window = window
        self.canAccept = canAccept
        self.onImage = onImage
    }

    deinit { stop() }

    func start() {
        guard monitor == nil else { return }
        addLog(text: "paste image [\(label)]: watching for ⌘V")
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            return self.take(event) ? nil : event
        }
    }

    func stop() {
        guard monitor != nil else { return }
        addLog(text: "paste image [\(label)]: stopped watching")
        if let monitor = monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    /// True when this paste was ours, and the key must not travel any further.
    private func take(_ event: NSEvent) -> Bool {
        guard Self.isPasteShortcut(event) else { return false }
        let host = window()
        // "No window yet" and "wrong window" used to look identical in the log and mean opposite
        // things: one is a view that never reached a window, the other a live host handed a key it
        // rejected. Four rounds were spent unable to tell them apart.
        guard host != nil else {
            addLog(text: "paste image [\(label)]: ⌘V seen, but this view is in no window yet "
                + "(event=\(ToDoPasteWindowMatch.describe(event.window)))")
            return false
        }
        guard ToDoPasteWindowMatch.isRelated(event: event.window, host: host) else {
            // Kept, and finally readable: both window CHAINS, not just their leaf classes. The leaf
            // alone said `event=CustomWindow host=_NSPopoverWindow` and left it a guess whether the
            // two were related — they were, as parent and child, which was the bug.
            addLog(text: "paste image [\(label)]: ⌘V ignored, event window is not this host "
                + "(event=\(ToDoPasteWindowMatch.describe(event.window)) "
                + "host=\(ToDoPasteWindowMatch.describe(host)) "
                + "key=\(ToDoPasteWindowMatch.describe(NSApp.keyWindow)) "
                + "focus=\(Self.describe(event.window?.firstResponder)))")
            return false
        }
        // Before the pasteboard is even read: a host with nowhere to put an image must let ⌘V through.
        // Swallowing the key and doing nothing is worse than not having the feature.
        guard canAccept() else {
            addLog(text: "paste image [\(label)]: ⌘V left alone, this host cannot take an image now")
            return false
        }
        let pasteboard = NSPasteboard.general
        let hasImage = pasteboard.canReadObject(forClasses: [NSImage.self], options: nil)
        let hasText = ToDoImagePaste.hasText(on: pasteboard)
        let editing = ToDoImagePaste.isEditingText(event.window?.firstResponder)
        let pathOnly = ToDoImagePaste.textIsOnlyAnImagePath(on: pasteboard)
        let attach = ToDoImagePaste.shouldAttach(hasImage: hasImage, hasText: hasText,
                                                 isEditingText: editing, textIsOnlyAnImagePath: pathOnly)
        // Logged because this decision is invisible when it goes wrong: the key simply travels on and
        // the user sees a path typed into a field, with nothing to distinguish "we declined" from "the
        // monitor never ran" (report 2026-09-15_20-54-33 — reported three times before this existed).
        addLog(text: "paste image [\(label)]: attach=\(attach) hasImage=\(hasImage) hasText=\(hasText) "
            + "editing=\(editing) pathOnly=\(pathOnly) focus=\(Self.describe(event.window?.firstResponder)) "
            + "types=\(pasteboard.types?.map(\.rawValue) ?? [])")
        guard attach else { return false }
        // Only now is the image decoded — an unreadable one falls through to the normal paste rather
        // than swallowing the key and doing nothing.
        guard let image = ToDoImagePaste.image(on: pasteboard) else {
            addLog(text: "paste image [\(label)]: pasteboard carried an image type but NSImage would not decode it")
            return false
        }
        onImage(image)
        return true
    }

    static func isPasteShortcut(_ event: NSEvent) -> Bool {
        event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command
            && event.charactersIgnoringModifiers?.lowercased() == "v"
    }

    /// The focused responder and the window it actually lives in — the check that says whether the
    /// field the user is typing into belongs to this host at all.
    static func describe(_ responder: NSResponder?) -> String {
        guard let responder = responder else { return "nil" }
        let kind = String(describing: type(of: responder))
        let window = (responder as? NSView)?.window ?? (responder as? NSWindow)
        return "\(kind)@\(ToDoPasteWindowMatch.describe(window))"
    }
}

/// Installs the monitor for as long as the SwiftUI view that asked for it is on screen.
struct ToDoImagePasteCatcher: NSViewRepresentable {
    let label: String
    let canAccept: () -> Bool
    let onImage: (ToDoPastedImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.canAccept = canAccept
        context.coordinator.onImage = onImage
        context.coordinator.build(for: view, label: label)
        return view
    }

    /// The monitor keeps running; what changes is the answer `canAccept` gives. It used to be torn
    /// down whenever the host said it could not attach, which meant ⌘V was never examined again even
    /// after the host could.
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.canAccept = canAccept
        context.coordinator.onImage = onImage
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator {
        var onImage: ((ToDoPastedImage) -> Void)?
        var canAccept: (() -> Bool)?
        private var monitor: ToDoImagePasteMonitor?

        func build(for view: NSView, label: String) {
            monitor = ToDoImagePasteMonitor(label: label,
                                            window: { [weak view] in view?.window },
                                            canAccept: { [weak self] in self?.canAccept?() ?? false },
                                            onImage: { [weak self] image in self?.onImage?(image) })
            monitor?.start()
        }

        func stop() { monitor?.stop() }

        deinit { monitor?.stop() }
    }
}

extension View {
    /// ⌘V attaches an image from the clipboard on this screen.
    ///
    /// `canAccept` is asked when the key is pressed, so a host whose answer changes while it is on
    /// screen — a Day Plan task waiting for its to-do to be minted — is asked again rather than
    /// judged once. See `ToDoImagePaste.shouldAttach` for the cases left to the focused control.
    func attachesPastedImages(label: String, canAccept: @escaping () -> Bool = { true },
                              onImage: @escaping (ToDoPastedImage) -> Void) -> some View {
        background(ToDoImagePasteCatcher(label: label, canAccept: canAccept, onImage: onImage))
    }
}

// MARK: - Upload guard

/// Whether a file may be attached, and why not when it may not.
///
/// Pure, so the rules the user actually runs into — the 20 MB ceiling, the 20-per-task ceiling, and a
/// task that has no server id to attach to — are unit-tested without a network or a file picker.
enum ToDoAttachmentUploadCheck: Equatable {
    case ready
    /// Impossible right now, and the UI already says so — there is no task to attach to, or an upload
    /// is already running and the button is disabled. Nothing to tell the user.
    case unavailable
    /// The message to show instead of uploading.
    case rejected(ToDoStringKey)

    /// - Parameter byteCount: the file's size, or nil when it could not be read at all.
    static func evaluate(taskId: String?, isUploading: Bool, existingCount: Int,
                         byteCount: Int?) -> ToDoAttachmentUploadCheck {
        guard taskId != nil, !isUploading else { return .unavailable }
        guard existingCount < ToDoAttachment.maximumPerTask else { return .rejected(.attachmentLimitReached) }
        guard let byteCount = byteCount else { return .rejected(.attachmentFailed) }
        guard byteCount <= ToDoAttachment.maximumBytes else { return .rejected(.attachmentTooLarge) }
        return .ready
    }
}

// MARK: - Store

/// The attachments of one task: what the server holds, plus an upload in flight.
///
/// `taskId` is the BACKEND to-do id. A task that does not exist server-side yet has none, and then
/// `canAttach` is false — every screen shows the same explicit "not yet" state rather than offering
/// a button whose endpoint cannot be built.
final class ToDoAttachmentsStore: ObservableObject {
    @Published private(set) var attachments: [ToDoAttachment] = []
    @Published private(set) var isUploading = false

    /// The BACKEND to-do id these files hang off, so a host can tell whether an existing store still
    /// belongs to the task it is about to show.
    let taskId: String?
    private let strings: ToDoStrings
    private let showStatus: (String) -> Void

    /// Called whenever the known number of files changes — on load, after an upload, after a removal.
    /// A host that shows a file badge elsewhere (the Day Plan's task list) uses this to cache the
    /// count, so it never has to fetch attachments just to decide whether to draw an icon.
    var onCountChanged: ((Int) -> Void)?

    init(taskId: String?, strings: ToDoStrings, showStatus: @escaping (String) -> Void) {
        self.taskId = taskId
        self.strings = strings
        self.showStatus = showStatus
    }

    /// False when the task has no server id — a brand-new editor task, or a Day Plan row that has not
    /// been minted as a to-do yet.
    var canAttach: Bool { taskId != nil }

    func load() {
        guard let taskId = taskId else { return }
        allApiObject.getTaskAttachments(taskId: taskId) { [weak self] attachments in
            // A failed fetch is not "zero files" — leave the last known list, and the cached count
            // with it, rather than making a badge disappear because the network blinked.
            guard let loaded = attachments else { return }
            DispatchQueue.main.async { self?.setAttachments(loaded) }
        }
    }

    /// A file chosen from disk.
    func attach(_ url: URL) {
        attach(data: try? Data(contentsOf: url),
               fileName: url.lastPathComponent,
               contentType: ToDoAttachmentType.contentType(forExtension: url.pathExtension))
    }

    /// An image taken off the clipboard. Deliberately the same door as `attach(_ url:)` — the 20 MB
    /// ceiling, the 20-per-task ceiling, the spinner that holds Save and the failure message all come
    /// from there, so a pasted screenshot cannot end up with rules of its own.
    /// - Parameter completion: whether the file reached the server. A host with no attachment list on
    ///   screen — the menu's quick-add — has nothing else to learn the outcome from, and it also tells
    ///   such a host when it may stop holding this store alive.
    func attach(pasted image: ToDoPastedImage, completion: ((Bool) -> Void)? = nil) {
        attach(data: image.data, fileName: image.fileName, contentType: image.contentType,
               completion: completion)
    }

    /// Presigned upload, then record it. The server checks the object really landed in storage and
    /// takes the size from there, so the count and size guards here are for the user's benefit —
    /// a clear message instead of a rejected request.
    private func attach(data: Data?, fileName name: String, contentType type: String,
                        completion: ((Bool) -> Void)? = nil) {
        // Report on the main queue exactly once, whichever way this ends.
        var report: ((Bool) -> Void)? = completion
        let finish: (Bool) -> Void = { ok in
            guard let once = report else { return }
            report = nil
            DispatchQueue.main.async { once(ok) }
        }
        switch ToDoAttachmentUploadCheck.evaluate(taskId: taskId, isUploading: isUploading,
                                                  existingCount: attachments.count,
                                                  byteCount: data?.count) {
        case .unavailable: finish(false); return
        case .rejected(let key): showStatus(strings[key]); finish(false); return
        case .ready: break
        }
        guard let taskId = taskId, let data = data else { finish(false); return }
        isUploading = true
        allApiObject.generateTaskAttachmentUpload(taskId: taskId, fileName: name, contentType: type) { [weak self] ticket in
            guard let self = self else { finish(false); return }
            guard let ticket = ticket else { self.failUpload(); finish(false); return }
            allApiObject.uploadTaskAttachmentData(data, to: ticket.uploadUrl, contentType: type) { uploaded in
                guard uploaded else { self.failUpload(); finish(false); return }
                allApiObject.createTaskAttachment(taskId: taskId, fileName: name, fileKey: ticket.fileKey,
                                                  contentType: type, fileSize: data.count) { saved in
                    DispatchQueue.main.async {
                        self.isUploading = false
                        guard saved != nil else {
                            self.showStatus(self.strings[.attachmentFailed]); finish(false); return
                        }
                        self.load()
                        finish(true)
                    }
                }
            }
        }
    }

    func remove(_ attachment: ToDoAttachment) {
        guard let taskId = taskId else { return }
        allApiObject.deleteTaskAttachment(taskId: taskId, attachmentId: attachment.id) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard success else { self.showStatus(self.strings[.attachmentFailed]); return }
                self.setAttachments(self.attachments.filter { $0.id != attachment.id })
            }
        }
    }

    private func setAttachments(_ list: [ToDoAttachment]) {
        attachments = list
        onCountChanged?(list.count)
    }

    private func failUpload() {
        DispatchQueue.main.async {
            self.isUploading = false
            self.showStatus(self.strings[.attachmentFailed])
        }
    }
}

// MARK: - Picker

/// Sizes and glyphs for the attachment list, named once rather than spelled out at each call site.
enum ToDoAttachmentMetrics {
    static let rowSpacing: CGFloat = 8
    static let listSpacing: CGFloat = 6
    static let nameFontSize: CGFloat = 12
    static let detailFontSize: CGFloat = 11
    static let buttonHeight: CGFloat = 26
    static let spinnerScale: CGFloat = 0.5
    /// One attachment row, for sizing a scrolling list in a host that cannot scroll by itself.
    static let rowHeight: CGFloat = 20
    static let imageSymbol = "photo"
    static let documentSymbol = "doc"
    static let removeSymbol = "trash"
    static let closeSymbol = "xmark.circle.fill"

    /// How tall `rows` attachment rows want to be.
    static func listHeight(rows: Int) -> CGFloat {
        guard rows > 0 else { return 0 }
        return CGFloat(rows) * rowHeight + CGFloat(rows - 1) * listSpacing
    }
}

/// Choosing a file to attach, as a SHEET — never `NSOpenPanel.runModal()`.
///
/// `runModal()` blocks the main run loop until the panel is dismissed, and the panel itself can open
/// behind Focus Bear, leaving nothing to dismiss: the app beachballs with no visible cause
/// (report 2026-09-14_22-12-31). A sheet is owned by the window, cannot hide behind it, and returns
/// immediately.
enum ToDoAttachmentPicker {
    /// - Parameter window: the window to hang the sheet on. Falling back to the key/main window keeps
    ///   the panel attached to *something*; only with no window at all does it run free-standing, and
    ///   then the app is brought forward first so it cannot open behind another app.
    static func present(from window: NSWindow?, onPick: @escaping (URL) -> Void) {
        // Built on the next turn of the run loop so whatever the caller just put on screen (a spinner,
        // a disabled button) actually paints before NSOpenPanel takes over the main thread.
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedFileTypes = ToDoAttachmentType.imageExtensions + ToDoAttachmentType.documentExtensions
            let handle: (NSApplication.ModalResponse) -> Void = { response in
                guard response == .OK, let url = panel.url else { return }
                onPick(url)
            }
            if let host = window ?? NSApp.keyWindow ?? NSApp.mainWindow {
                panel.beginSheetModal(for: host, completionHandler: handle)
            } else {
                NSApp.activate(ignoringOtherApps: true)
                panel.begin(completionHandler: handle)
            }
        }
    }
}

// MARK: - List

/// The attachment rows plus "Add file…", shared by the to-do editor and the Day Plan task details.
///
/// Presenting the preview is the HOST's job (`onPreview`): the editor already owns a `.sheet` at the
/// top of its own sheet, while the Day Plan lives in a transient popover and has to get out of the
/// way first. Everything else — the rows, the limit, the spinner, the unavailable state — is here.
struct ToDoAttachmentsList: View {
    @ObservedObject var store: ToDoAttachmentsStore
    let strings: ToDoStrings
    /// Why attaching is unavailable, shown in place of the list when `store.canAttach` is false.
    let unavailableMessage: String
    /// Non-nil makes the rows scroll inside that height — for a host with no scroll view of its own.
    let maximumListHeight: CGFloat?
    let onPreview: (ToDoAttachment) -> Void
    /// The focus player offers preview without changing files during a running session.
    let allowsEditing: Bool
    /// Called when "Add file…" is pressed, so a host that must dismiss something first can do it
    /// before the picker appears. Defaults to opening the picker on the view's own window.
    let onAdd: (() -> Void)?
    /// Supplied by a host that can hold a pasted image until its task is backed by a to-do. nil means
    /// it cannot, and ⌘V is then left to the focused control.
    let pendingImage: ToDoPendingImageSink?
    /// Names this screen in the paste log. Several monitors run at once and they are otherwise
    /// indistinguishable — every one of them calls its window `_NSPopoverWindow`.
    let pasteLabel: String

    init(store: ToDoAttachmentsStore, strings: ToDoStrings, unavailableMessage: String,
         maximumListHeight: CGFloat? = nil, allowsEditing: Bool = true,
         onPreview: @escaping (ToDoAttachment) -> Void,
         onAdd: (() -> Void)? = nil, pendingImage: ToDoPendingImageSink? = nil,
         pasteLabel: String = "attachments") {
        self.store = store
        self.strings = strings
        self.unavailableMessage = unavailableMessage
        self.maximumListHeight = maximumListHeight
        self.onPreview = onPreview
        self.allowsEditing = allowsEditing
        self.onAdd = onAdd
        self.pendingImage = pendingImage
        self.pasteLabel = pasteLabel
    }

    @SwiftUI.State private var hostWindow: NSWindow?

    var body: some View {
        Group {
            if store.canAttach {
                VStack(alignment: .leading, spacing: ToDoAttachmentMetrics.listSpacing) {
                    rows
                    if allowsEditing { addRow }
                }
            } else {
                Text(unavailableMessage)
                    .font(.system(size: ToDoAttachmentMetrics.detailFontSize))
                    .foregroundColor(.secondary)
            }
        }
        // Fill the width and sit at its leading edge. Without this the block keeps its own narrow
        // width and an NSHostingView CENTRES it — which is why "Add file…" sat in the middle of the
        // Day Plan's form while "Add sub-task", a plain AppKit view in the same stack, sat at the left
        // margin ("Add attachments button should be aligned with Add sub tasks",
        // report 2026-09-15_20-54-33 follow-up). Sharing the button with the sub-task row fixed how it
        // LOOKS; only this fixes where it is.
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HostWindowReader { hostWindow = $0 })
        // ⌘V anywhere on the host attaches a clipboard image, through the same upload as "Add file…".
        // Both questions are asked when the key is pressed, never captured at render time: the answer
        // changes underneath an open Day Plan sheet as its to-do is minted.
        .attachesPastedImages(label: pasteLabel, canAccept: { allowsEditing && route() != .leaveAlone }, onImage: pasted)
    }

    /// Where a ⌘V on this host should go right now.
    private func route() -> ToDoPasteRoute {
        ToDoPasteRoute.decide(canAttachNow: store.canAttach,
                              canHoldForLater: pendingImage?.canHold() ?? false)
    }

    private func pasted(_ image: ToDoPastedImage) {
        switch route() {
        case .attachNow: store.attach(pasted: image)
        case .holdUntilBacked: pendingImage?.hold(image)
        // `canAccept` said otherwise a moment ago, so the key was taken. Say so rather than eating it.
        case .leaveAlone: addLog(text: "paste image: nowhere to put the image after all; ignoring")
        }
    }

    @ViewBuilder
    private var rows: some View {
        if let cap = maximumListHeight, !store.attachments.isEmpty {
            // An explicit height, not `maxHeight`: a ScrollView has no height of its own, so a hosting
            // view that sizes itself to its content would give this one none at all.
            ScrollView { rowStack }
                .frame(height: min(cap, ToDoAttachmentMetrics.listHeight(rows: store.attachments.count)))
        } else {
            rowStack
        }
    }

    private var rowStack: some View {
        VStack(alignment: .leading, spacing: ToDoAttachmentMetrics.listSpacing) {
            ForEach(store.attachments) { attachment in
                row(attachment)
            }
        }
    }

    private func row(_ attachment: ToDoAttachment) -> some View {
        HStack(spacing: ToDoAttachmentMetrics.rowSpacing) {
            Image(systemName: attachment.isImage ? ToDoAttachmentMetrics.imageSymbol
                                                 : ToDoAttachmentMetrics.documentSymbol)
                .font(.system(size: ToDoAttachmentMetrics.nameFontSize)).foregroundColor(.secondary)
            // Previewed in the window, never handed to another app: a file opened in Preview or a
            // browser comes up BEHIND Focus Bear, so the click reads as doing nothing
            // (report 2026-09-13_21-19-23, and the same complaint again in 2026-09-15_11-16-30).
            SwiftUI.Button(action: { onPreview(attachment) }) {
                Text(verbatim: attachment.file_name)
                    .font(.system(size: ToDoAttachmentMetrics.nameFontSize)).lineLimit(1)
            }
            .buttonStyle(PlainButtonStyle()).pointingHandCursor()
            .help(strings[.previewAttachment])
            Text(verbatim: ToDoAttachmentSize.label(attachment.file_size))
                .font(.system(size: ToDoAttachmentMetrics.detailFontSize)).foregroundColor(.secondary)
            Spacer(minLength: 0)
            if allowsEditing {
                SwiftUI.Button(action: { store.remove(attachment) }) {
                    Image(systemName: ToDoAttachmentMetrics.removeSymbol)
                        .font(.system(size: ToDoAttachmentMetrics.detailFontSize))
                        .foregroundColor(ToDoTheme.overdue)
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                .help(strings[.delete])
            }
        }
    }

    /// The very same `AddItemButton` a sub-task list uses — see its note for why matching the two by
    /// copying a style onto the other was not an option.
    private var addRow: some View {
        HStack(spacing: ToDoAttachmentMetrics.rowSpacing) {
            AddItemButton(title: strings[.addAttachment], action: add)
                .disabled(store.isUploading)
                // The only thing telling anyone ⌘V works here. A keyboard shortcut nobody is told
                // about is a feature nobody uses.
                .help(strings[.attachmentPasteHint])
            if store.isUploading { ProgressView().scaleEffect(ToDoAttachmentMetrics.spinnerScale) }
        }
    }

    private func add() {
        if let onAdd = onAdd { onAdd(); return }
        ToDoAttachmentPicker.present(from: hostWindow) { url in store.attach(url) }
    }
}

// MARK: - Preview

/// One attachment, previewed inside the window.
///
/// Deliberately not `NSWorkspace.open`: the other app's window comes up BEHIND Focus Bear, so the
/// click reads as doing nothing at all — that is the whole reason the report screenshots got a
/// lightbox (report 2026-09-13_21-19-23), and the same complaint arrived for task attachments
/// (2026-09-15_11-16-30). Images are drawn here, PDFs go through PDFKit and text files are shown as
/// text; anything else offers to save a copy rather than handing the file to another app.
struct ToDoAttachmentPreviewSheet: View {
    let attachment: ToDoAttachment
    let strings: ToDoStrings
    let close: () -> Void

    @SwiftUI.State private var loaded: Data?
    @SwiftUI.State private var didFail = false

    private static let documentPadding: CGFloat = 16
    private static let headerFontSize: CGFloat = 12
    private static let closeGlyphSize: CGFloat = 16
    private static let headerSpacing: CGFloat = 8
    private static let bodySpacing: CGFloat = 10
    private static let textFontSize: CGFloat = 13
    /// The header row is pinned to this so the chrome arithmetic below is exact rather than a guess at
    /// what the font happens to measure.
    private static let headerRowHeight: CGFloat = 20

    /// Everything in the sheet that is NOT the document: the header row, the footer button row, the
    /// spacing between the three, and the padding around the lot. Derived from the same metrics the
    /// layout uses, so it cannot drift away from it.
    private static var chromeHeight: CGFloat {
        documentPadding * 2 + headerRowHeight + ToDoAttachmentMetrics.buttonHeight + bodySpacing * 2
    }

    /// The screen the sheet will appear on; a headless/unknown screen falls back to the minimum.
    /// Prefer the screen actually showing the app; `NSScreen.main` is nil in a headless/unit context
    /// and the old square fallback produced exactly the narrow sheet that was reported, so fall back
    /// to the largest attached screen before resorting to the minimum.
    static var availableScreen: CGSize {
        NSScreen.main?.visibleFrame.size
            ?? NSScreen.screens.map(\.visibleFrame.size).max(by: { $0.width < $1.width })
            ?? CGSize(width: ImagePreviewSizing.minimumSide, height: ImagePreviewSizing.minimumSide)
    }

    /// The exact size this sheet wants. An AppKit host sets it as `preferredContentSize` — see
    /// `ImagePreviewSizing.sheetSize` for why an ideal size alone is not enough.
    static var preferredSheetSize: CGSize {
        ImagePreviewSizing.sheetSize(available: availableScreen, chromeHeight: chromeHeight)
    }

    private var available: CGSize { Self.availableScreen }
    private var documentSize: CGSize {
        ImagePreviewSizing.documentBox(available: available, chromeHeight: Self.chromeHeight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.bodySpacing) {
            header
            content
            footer
        }
        .padding(Self.documentPadding)
        // An EXACT frame. `minHeight` + `idealHeight` let AppKit present this sheet at the minimum
        // (320pt) with the header and footer hanging off the edges — see ImagePreviewSizing.sheetSize.
        .frame(width: Self.preferredSheetSize.width, height: Self.preferredSheetSize.height)
        .onAppear(perform: load)
    }

    private var header: some View {
        HStack(spacing: Self.headerSpacing) {
            Text(verbatim: attachment.file_name)
                .font(.system(size: Self.headerFontSize, weight: .semibold)).lineLimit(1)
            Text(verbatim: ToDoAttachmentSize.label(attachment.file_size))
                .font(.system(size: Self.headerFontSize)).foregroundColor(.secondary)
            Spacer(minLength: 0)
            // Close belongs top-right with a recognisable glyph: at the bottom-left it read as just
            // another action next to "Save a copy" rather than the way out.
            SwiftUI.Button(action: close) {
                Image(systemName: ToDoAttachmentMetrics.closeSymbol)
                    .font(.system(size: Self.closeGlyphSize))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.cancelAction)
            .help(strings[.close])
            .accessibilityLabel(Text(strings[.close]))
        }
        .frame(height: Self.headerRowHeight)
    }

    private var footer: some View {
        HStack {
            SwiftUI.Button(action: saveCopy) { Text(strings[.attachmentSaveCopy]) }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: ToDoAttachmentMetrics.buttonHeight))
                .disabled(loaded == nil)
            Spacer()
        }
        .frame(height: ToDoAttachmentMetrics.buttonHeight)
    }

    @ViewBuilder
    private var content: some View {
        if didFail {
            message(strings[.attachmentFailed])
        } else if let data = loaded {
            preview(of: data)
        } else {
            HStack { Spacer(); ProgressView(); Spacer() }
                .frame(width: documentSize.width, height: documentSize.height)
        }
    }

    @ViewBuilder
    private func preview(of data: Data) -> some View {
        if attachment.isImage, let picture = NSImage(data: data) {
            // Fitted to the WIDTH and scrolled, not squeezed into the box: the long screenshot is the
            // shape people attach, and squeezing one into the sheet is how it ends up unreadable.
            let size = ImagePreviewSizing.scrollableFit(image: picture.naturalPixelSize, within: documentSize)
            ScrollView([.horizontal, .vertical],
                       showsIndicators: ImagePreviewSizing.needsScrolling(content: size, within: documentSize)) {
                Image(nsImage: picture)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .accessibilityLabel(Text(verbatim: attachment.file_name))
            }
            // An exact frame, like every other branch here: the sheet's size is computed from this
            // document box, so a scroll view allowed to size itself to its content would undo it.
            .frame(width: documentSize.width, height: documentSize.height)
        } else if ToDoAttachmentType.isPDF(attachment.content_type) {
            PDFDocumentView(data: data)
                .frame(width: documentSize.width, height: documentSize.height)
        } else if ToDoAttachmentType.isText(attachment.content_type), let text = String(data: data, encoding: .utf8) {
            ScrollView {
                Text(verbatim: text).font(.system(size: Self.textFontSize, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: documentSize.width, height: documentSize.height)
        } else {
            message(strings[.attachmentPreviewUnavailable])
        }
    }

    private func message(_ text: String) -> some View {
        Text(text).font(.system(size: Self.headerFontSize)).foregroundColor(.secondary)
            .frame(width: documentSize.width, alignment: .leading)
    }

    /// The server's `download_url` is a short-lived presigned link, so it is fetched without any
    /// Authorization header — the signature is the auth.
    private func load() {
        guard loaded == nil, !didFail else { return }
        guard let link = attachment.download_url, let url = URL(string: link) else { didFail = true; return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            DispatchQueue.main.async {
                guard let data = data, error == nil, (200...299).contains(code) else {
                    addLog(text: "attachment preview failed: \(error?.localizedDescription ?? "status \(code)")")
                    didFail = true
                    return
                }
                loaded = data
            }
        }.resume()
    }

    /// Saving keeps the file inside Focus Bear's own sheet — the point of previewing here is that the
    /// user never loses the window to another app.
    private func saveCopy() {
        guard let data = loaded else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = attachment.file_name
        let write: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url else { return }
            do { try data.write(to: url) } catch { addLog(text: "attachment save failed: \(error.localizedDescription)") }
        }
        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            panel.beginSheetModal(for: window, completionHandler: write)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            panel.begin(completionHandler: write)
        }
    }
}

/// The preview as an AppKit sheet, with exactly ONE way out of it.
///
/// The ✕ and the Esc key have to do the same thing, and in the Day Plan "the same thing" is more than
/// dismissing: the task details the preview was opened from have to come back. AppKit answers Esc on a
/// presented view controller by dismissing it silently, which would have left the details closed — a
/// second, quieter exit that does less than the button does. Routing `cancelOperation` through the
/// very closure the button calls removes it.
///
/// The host also has to be told the size outright; without it the sheet resolves to the SwiftUI view's
/// required minimum and the header — the ✕ — ends up outside the sheet (report 2026-09-15_20-54-33).
final class ToDoAttachmentPreviewSheetController: NSHostingController<ToDoAttachmentPreviewSheet> {
    private let onClose: () -> Void
    private var hasClosed = false

    init(attachment: ToDoAttachment, strings: ToDoStrings, onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init(rootView: ToDoAttachmentPreviewSheet(attachment: attachment, strings: strings, close: {}))
        rootView = ToDoAttachmentPreviewSheet(attachment: attachment, strings: strings,
                                              close: { [weak self] in self?.close() })
        preferredContentSize = ToDoAttachmentPreviewSheet.preferredSheetSize
    }

    @available(*, unavailable) required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    /// The one exit. Idempotent, because both routes into it can fire for a single press of Esc — the
    /// ✕ carries `.cancelAction`, and AppKit sends `cancelOperation` as well if SwiftUI has not
    /// already swallowed the key.
    func close() {
        guard !hasClosed else { return }
        hasClosed = true
        presentingViewController?.dismiss(self)
        onClose()
    }

    override func cancelOperation(_ sender: Any?) { close() }
}

/// A PDF rendered in place by PDFKit, so a document attachment never has to leave the window.
private struct PDFDocumentView: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(data: data)
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        guard view.document == nil else { return }
        view.document = PDFDocument(data: data)
    }
}
