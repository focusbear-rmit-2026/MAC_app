//
//  ClaudeTitleReader.swift
//  FocusBear
//
//  Created by Manish Jain on 02/06/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//


import Cocoa
import ApplicationServices

/// The Accessibility-derived titles of an app's focused window.
struct AppWindowTitles {
    /// Plain title-bar text — e.g. iTerm's "literature-search". Tells the AI relevance check what a
    /// blocked app is actually showing, since the app name alone ("iTerm") is uninformative.
    var focusedWindow: String?
    /// Claude's active conversation title, dug out of its static-text hierarchy.
    var chat: String?

    static let empty = AppWindowTitles()
}

/// Reads window titles over Accessibility **off the main thread**, and hands callers the last value read.
///
/// Every `AXUIElementCopyAttributeValue` blocks the *calling* thread in `mach_msg` until the target
/// app's AX server replies. `axMessagingTimeoutSeconds` caps one message, but `conversationTitle`
/// walks a whole window tree, so a single title read is an unbounded number of those round trips. Run
/// from the 1s allowed-app timer and from `frontApplicationChanged`, that walk froze the UI for
/// seconds at a time (Sentry FOCUS-BEAR-MACOS-1AD / -1EH: `chatTitle` → `AXUIElementCopyAttributeValue`
/// → `mach_msg2_trap` on thread 0).
///
/// So the walk now runs on `queue`, and main-thread callers read whatever the last completed read
/// produced. A title one tick stale is fine — it is advisory context for a relevance check. A caller
/// *waiting* for it is not: there is deliberately **no semaphore here and nothing that blocks**. An
/// earlier fix of this shape bounced the work onto the main thread behind a semaphore and caused
/// exactly this beachball (PR #2009); `fetchBrowserAllTabUrlsInBackground` carries the same warning.
final class claudeTitleReader {

    static let shared = claudeTitleReader()

    private init() {}

    /// Cap for AX messages to a target app. Without it, `AXUIElementCopyAttributeValue` blocks in
    /// `mach_msg` waiting on a slow/unresponsive app's AX server. Set on the application element, it
    /// applies to all AX messages to that app (incl. child window/text elements). A missed title just
    /// returns nil (today's "blank" behaviour), which is fine — the AI check works without it.
    private static let axMessagingTimeoutSeconds: Float = 0.5

    /// The only app whose in-window conversation title is worth the extra tree walk. Ask through
    /// `wantsChatTitle(appName:)` so the name lives in one place.
    private static let chatTitleAppName = "Claude"

    /// How long a completed read stays good before the next request kicks off a refresh.
    private static let titleFreshnessSeconds: TimeInterval = 2

    /// How long `hasSettledTitles` waits for the *first* read of an app before telling callers to give
    /// up and carry on without a title. Bounds the delay a slow AX server can add: a result arriving a
    /// tick late is acceptable, a decision that never happens is not.
    private static let firstReadDeadlineSeconds: TimeInterval = 2

    /// Entries untouched for this long are dropped, so a long session does not keep one per process
    /// that was ever frontmost.
    private static let entryIdleEvictionSeconds: TimeInterval = 300

    private struct Entry {
        var titles = AppWindowTitles.empty
        /// When a read last completed. Nil until the first one does — "no title read yet" and "this app
        /// has no title" must not look the same to `hasSettledTitles`.
        var resolvedAt: Date?
        /// When the in-flight read started; nil when none is running. Keeps one read per app in flight.
        var readStartedAt: Date?
        /// When a caller last asked about this app, for eviction.
        var lastRequestedAt = Date()
    }

    private let queue = DispatchQueue(label: "io.focusbear.ax-window-titles", qos: .userInitiated)
    /// Guards `entries` only. Never held across an AX call — that would put the blocking back on
    /// whichever thread wanted to read the cache.
    private let lock = NSLock()
    private var entries: [pid_t: Entry] = [:]

    /// Whether this app's conversation title is worth the extra tree walk.
    ///
    /// Derived from the app itself rather than taken from the caller, so every call site agrees about a
    /// given app. If one caller could ask without the walk, its cheaper read would land in the cache and
    /// overwrite a conversation title another caller had just paid for — and the relevance key would
    /// flap between "with chat title" and "without" on alternating ticks.
    private static func wantsChatTitle(_ runningApp: NSRunningApplication) -> Bool {
        runningApp.bundleURL?.deletingPathExtension().lastPathComponent == chatTitleAppName
    }

    /// The last titles read for `runningApp`. Never blocks; schedules a background refresh when the
    /// cached value is stale or missing.
    func titles(for runningApp: NSRunningApplication) -> AppWindowTitles {
        requestRead(for: runningApp).titles
    }

    /// Whether callers building a cache key from these titles should go ahead.
    ///
    /// False only while the very first read for this app is still in flight and inside
    /// `firstReadDeadlineSeconds`. Keying on a title that is merely late would fire one AI check on the
    /// bare app name and a second one a tick later when the title landed; waiting one tick instead
    /// keeps today's single-check behaviour. The app stays blocked either way.
    func hasSettledTitles(for runningApp: NSRunningApplication) -> Bool {
        let entry = requestRead(for: runningApp)
        if entry.resolvedAt != nil { return true }
        guard let startedAt = entry.readStartedAt else { return false }
        return Date().timeIntervalSince(startedAt) >= Self.firstReadDeadlineSeconds
    }

    /// Claude's active conversation title from the last background read.
    func chatTitle(for runningApp: NSRunningApplication) -> String? {
        titles(for: runningApp).chat
    }

    /// The focused window's title-bar text from the last background read.
    func focusedWindowTitle(for runningApp: NSRunningApplication) -> String? {
        titles(for: runningApp).focusedWindow
    }

    /// Records the request, decides whether a refresh is due, and returns the entry as the caller sees
    /// it now. The AX work itself is dispatched after the lock is released.
    private func requestRead(for runningApp: NSRunningApplication) -> Entry {
        let pid = runningApp.processIdentifier
        let includeChatTitle = Self.wantsChatTitle(runningApp)
        let now = Date()

        lock.lock()
        var entry = entries[pid] ?? Entry()
        entry.lastRequestedAt = now
        let isStale = entry.resolvedAt.map { now.timeIntervalSince($0) >= Self.titleFreshnessSeconds } ?? true
        let shouldRead = isStale && entry.readStartedAt == nil
        if shouldRead { entry.readStartedAt = now }
        entries[pid] = entry
        // Deliberately no eviction here: this runs on the main thread once per timer tick, and sweeping
        // every entry to save a handful of small structs would be the wrong trade. `publish` sweeps
        // instead, on the background queue.
        lock.unlock()

        if shouldRead { scheduleRead(pid: pid, includeChatTitle: includeChatTitle) }
        return entry
    }

    private func scheduleRead(pid: pid_t, includeChatTitle: Bool) {
        queue.async { [weak self] in
            guard let self = self else { return }
            // Everything below waits on the target app's AX server. That is the whole reason it runs
            // here: on the main thread this is the beachball.
            var titles = AppWindowTitles.empty
            let appElement = AXUIElementCreateApplication(pid)
            AXUIElementSetMessagingTimeout(appElement, Self.axMessagingTimeoutSeconds)
            if let window = Self.copyElement(from: appElement, attribute: kAXFocusedWindowAttribute) {
                titles.focusedWindow = Self.title(of: window)
                if includeChatTitle { titles.chat = Self.conversationTitle(from: window) }
            }
            self.publish(titles, pid: pid)
        }
    }

    private func publish(_ titles: AppWindowTitles, pid: pid_t) {
        let now = Date()
        lock.lock()
        var entry = entries[pid] ?? Entry()
        entry.titles = titles
        entry.resolvedAt = now
        entry.readStartedAt = nil
        entries[pid] = entry
        evictIdleEntries(now: now)
        lock.unlock()
    }

    /// Caller must hold `lock`.
    private func evictIdleEntries(now: Date) {
        entries = entries.filter { _, entry in
            entry.readStartedAt != nil
                || now.timeIntervalSince(entry.lastRequestedAt) < Self.entryIdleEvictionSeconds
        }
    }

    private static func copyElement(from element: AXUIElement, attribute: String) -> AXUIElement? {
        var valueRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &valueRef) == .success,
              let value = valueRef else { return nil }
        guard CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    private static func title(of window: AXUIElement) -> String? {
        var titleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
              let title = (titleRef as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            return nil
        }
        return title
    }

    /// One piece of static text and where it sits on screen.
    struct PlacedText: Equatable {
        let text: String
        let frame: CGRect
    }

    /// Picks the active conversation title out of every static text in Claude's window.
    ///
    /// This used to be `texts[3]` — the fourth static text found depth-first, with a comment saying
    /// the hierarchy happened to put the title there. It is a position, not an identity, so anything
    /// that changes how much text precedes the header moves it. A pinned-chats sidebar does exactly
    /// that: the read returned "Shui cao Chinese translation", a pinned conversation the user was not
    /// in, and the relevance check then blocked their actual work for being about Chinese translation
    /// (report 2026-09-22_16-01-02).
    ///
    /// Geometry is the stable signal. The sidebar is a narrow left column; the conversation title is
    /// the topmost text in the wide pane beside it. That holds however many chats are pinned, and
    /// keeps holding when the sidebar is collapsed — then everything is in the content pane and the
    /// topmost text is still the header.
    enum ChatTitlePicker {

        /// Fraction of the window's width treated as sidebar. Claude's is roughly a third; a third is
        /// also comfortably clear of the content pane's left edge, so the exact value is not load
        /// bearing — it only has to separate two columns that are far apart.
        static let sidebarWidthFraction: CGFloat = 0.34

        /// Below this, text in the content pane is almost certainly a button ("New", "Chat", "Add")
        /// rather than a conversation title.
        ///
        /// A trade-off, and deliberately the cautious side of it: a genuinely three-character title
        /// is missed, which costs the relevance check some context. Picking up a toolbar button
        /// instead would send the AI a confident wrong answer — and being confidently wrong about
        /// what the user is doing is exactly what caused this report.
        static let minimumTitleLength = 4

        static func pick(from texts: [PlacedText], windowFrame: CGRect) -> String? {
            guard windowFrame.width > 0 else { return nil }
            let contentBegins = windowFrame.minX + windowFrame.width * sidebarWidthFraction
            let candidates = texts.filter { placed in
                placed.frame.minX >= contentBegins
                    && placed.text.count >= minimumTitleLength
            }
            // AX y grows downward, so the smallest minY is the highest on screen. Ties broken by x so
            // the result cannot depend on tree-walk order.
            return candidates
                .min { ($0.frame.minY, $0.frame.minX) < ($1.frame.minY, $1.frame.minX) }?
                .text
        }
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let positionValue = positionRef, let sizeValue = sizeRef,
              CFGetTypeID(positionValue) == AXValueGetTypeID(), CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else { return nil }
        var origin = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &origin),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else { return nil }
        return CGRect(origin: origin, size: size)
    }

    private static func conversationTitle(from window: AXUIElement) -> String? {
        var texts: [PlacedText] = []

        func collectTexts(_ element: AXUIElement) {
            var roleRef: CFTypeRef?

            if AXUIElementCopyAttributeValue(
                element,
                kAXRoleAttribute as CFString,
                &roleRef
            ) == .success,
               let role = roleRef as? String,
               role == kAXStaticTextRole {

                var valueRef: CFTypeRef?

                if AXUIElementCopyAttributeValue(
                    element,
                    kAXValueAttribute as CFString,
                    &valueRef
                ) == .success,
                   let value = valueRef as? String {

                    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty, let frame = Self.frame(of: element) {
                        texts.append(PlacedText(text: trimmed, frame: frame))
                    }
                }
            }

            var childrenRef: CFTypeRef?

            if AXUIElementCopyAttributeValue(
                element,
                kAXChildrenAttribute as CFString,
                &childrenRef
            ) == .success,
               let children = childrenRef as? [AXUIElement] {

                children.forEach(collectTexts)
            }
        }

        collectTexts(window)
        guard let windowFrame = Self.frame(of: window) else { return nil }
        return ChatTitlePicker.pick(from: texts, windowFrame: windowFrame)
    }
}
