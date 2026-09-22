//
//  AiBlockBuddyScreen.swift
//  Focus Bear
//
//  The SwiftUI replacement for the legacy AppKit block popup (`popUpBlockConfirmVc`) when the AI
//  relevance check decides the current app/site does NOT match the focus intention + current task.
//  Instead of the old "do you need this?" dialog, it routes the moment through the accountability
//  buddy: it shows the user their TOP THREE Day Plan tasks and asks whether they'd rather work on one
//  of those. Flows:
//    1. Pick a top task  → switch the active task to it immediately and re-check the current page
//       against the new task (it may now be relevant and unblock; otherwise a fresh check-in shows).
//    2. Argue with the AI → a chat (reusing `evaluateBlockRelevanceConversation`) where the user
//       claims the app/site IS relevant to their top task; the AI re-judges. Approve ⇒ allow it.
//    3. Block it            → just block the distraction and close.
//    Separately, "Save what I'm doing as a task" captures the current activity to the Day Plan.
//
//  This file owns the gate, context, window presentation, dismissal and the block/allow primitives. The
//  SwiftUI screen itself (Figma "AI Blocking Latest"), its strings registry (`AiBlockBuddyText`) and the
//  window size constants live in `AiBlockBuddyView.swift`.
//

import Cocoa
import SwiftUI

// MARK: - Feature gate

/// Whether the AI-block moment should present the new SwiftUI buddy screen instead of the legacy popup.
/// True only for an actual AI relevance decision (`isBlockByAi`) while AI blocking is on and we're not in
/// the curated "block super distracting" mode — the exact case the redesign targets. Everything else
/// (non-AI block-list blocks, super-distracting mode) still uses the legacy popup untouched.
func shouldUseAiBlockBuddy(isBlockByAi: Bool, isBrowser: Bool) -> Bool {
    guard isBlockByAi else { return false }
    guard SettingsManagerObject.isAIBlockingEnabled() else { return false }
    if isBlockSuperDistractingFocusModeOn() { return false }
    return true
}

// MARK: - Which of the two things is actually off-task

/// What the check-in's subtitle is saying.
///
/// The screen has always phrased a block one way: "<this app/site> doesn't seem to align with your
/// current task". That is only true when the current task itself serves the session. When the task the
/// user set does NOT serve the stated focus intention, *everything* reads as off-task — and the old
/// wording sent the user off trying to justify an app that could never be justified, because the app was
/// never the problem (report 2026-09-17_13-52-25). These cases let the screen name which of the two
/// things is wrong.
///
/// `currentTaskOffIntention` is raised ONLY where the session demanded that the user's activity align
/// with the intention — `isTaskRequiredToAlignToFocusIntention()`, the same predicate the relevance
/// request uses. That is the product decision behind the report ("this only applies when the focus
/// session is in the strictest mode"), and it is where the mis-blame is a trap rather than an annoyance:
/// a super-strict session locks the intention (`selectJsonVc` refuses `send_intention` at
/// `._SUPER_STRICT_`), so "argue with the AI" is the only door the screen shows and it is nailed shut.
/// The predicate also covers an accountability-buddy session, which forces the same strict judgement
/// server-side and so mis-blames the app in exactly the same way. Every other session keeps the wording
/// it has always had, and makes no check at all.
enum AiBlockBuddySubtitle: Equatable {
    /// The session has neither a task nor an intention to judge against — the "working on something
    /// lower priority (<item>)" line.
    case noCurrentTask
    /// The current task fits the session (or the server couldn't say) — the caught item is what's off.
    case itemOffTask
    /// The current TASK conflicts with the session's focus intention. `reason` is the server's own
    /// sentence, already localised and naming both the intention and the task; empty when it gave none,
    /// and then the screen falls back to its own wording.
    case currentTaskOffIntention(reason: String)
}

/// Whether the current task itself serves the session intention — asked once per (intention, task) pair,
/// and only in a session that demanded the alignment in the first place.
///
/// The gate is `isTaskRequiredToAlignToFocusIntention()` — the SAME predicate the relevance request uses
/// to send `task_must_align_to_focus_intention` (super-strict focus mode, or an accountability-buddy
/// session). Deriving a second notion of "strict enough" here would let the two drift: the check-in
/// would blame the task in sessions the server was never asked to judge that way. It is passed in rather
/// than read here so the decision stays a pure function the tests can drive.
///
/// Asking at all is a stopgap. `askWhetherTaskDiverges` below is the one seam: today it spends a second
/// round trip on `POST /user/task-intention-check` — from a modal the user is already sitting in front
/// of, against an endpoint that is advisory and fails open by design (it was built for the
/// extend-session flow). backend#2428 puts `task_diverges_from_focus_goal` on the `/user/is-url-safe-to-use`
/// response the block path has already fetched — the same request that carries `intention`,
/// `current_tasks`, `currentTaskInToDoPlayer` and the strict-alignment flag, so the server can answer it
/// there. When it lands, that one function reads the flag off the relevance decision and the checker,
/// the extra request and the 6s timeout all go away; the gate, `subtitle(for:)` and the screen do not
/// change. Nothing else should be built on the interim endpoint in the meantime.
enum AiBlockBuddyTaskIntention {
    /// The existing safety response owns this verdict; rendering must never buy another AI call.
    static func subtitle(misaligned: Bool?, mustAlign: Bool, reason: String) -> AiBlockBuddySubtitle {
        guard mustAlign, misaligned == true else { return .itemOffTask }
        return .currentTaskOffIntention(reason: reason.trimmingCharacters(in: .whitespacesAndNewlines))
    }


    /// How long the check may take before the screen settles for the ordinary wording. Shorter than the
    /// extend sheet's 10s: nothing waits on this one — the check-in is already on screen and readable —
    /// so a late answer that rewrites the heading under the user's eyes is worse than no answer.
    static let checkTimeout: TimeInterval = 6

    /// Whether the pair is worth asking about.
    ///
    /// Two gates, in order:
    ///  1. Only where the session demanded the alignment — `isTaskRequiredToAlignToFocusIntention()`.
    ///     Anywhere else the screen keeps the wording it has always had, so the answer would never be
    ///     shown, and an answer that is never shown must not cost a request. That is most sessions: the
    ///     ordinary strict and normal ones now make no check at all.
    ///  2. Something to compare. Nothing to compare (no intention, or no task) means there is no
    ///     question — and the endpoint rejects an empty `intention`/`task_name` anyway. Equal strings
    ///     mean the check-in's CURRENT TASK row is just echoing the intention
    ///     (`aiBlockBuddyCurrentTaskLabel`'s fallback for a session with a goal and no task), which can
    ///     never disagree with itself.
    static func shouldCheck(intention: String, taskName: String, mustAlignToFocusIntention: Bool) -> Bool {
        guard mustAlignToFocusIntention else { return false }
        let intention = intention.trimmingCharacters(in: .whitespacesAndNewlines)
        let task = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !intention.isEmpty, !task.isEmpty else { return false }
        return intention.caseInsensitiveCompare(task) != .orderedSame
    }

    /// Turn the server's answer into what the subtitle should say.
    ///
    /// FAILS OPEN, like every other use of this endpoint: an unreachable server, a timeout or a body
    /// that didn't parse leaves the ordinary "this app is off-task" wording in place. Telling someone
    /// their task is wrong on the strength of a request that never happened would be worse than the
    /// imprecision this fixes. Only an explicit `aligns: false` — which the deliberately lenient
    /// classifier gives only for a clear conflict — changes the copy.
    static func subtitle(for outcome: Result<TaskIntentionAlignment, Error>) -> AiBlockBuddySubtitle {
        guard case .success(let alignment) = outcome, !alignment.aligns else { return .itemOffTask }
        return .currentTaskOffIntention(
            reason: alignment.reason.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Ask (or recall) whether `taskName` serves `intention`, and report what the subtitle should say.
    ///
    /// Never blocks the caller and never leaves it waiting: the check-in renders immediately with
    /// `.itemOffTask` and this refines it in place if and when an answer arrives. `completion` is called
    /// exactly once, on the main queue.
    static func check(intention: String,
                      taskName: String,
                      focusMode: String?,
                      mustAlignToFocusIntention: Bool,
                      checker: TaskIntentionChecking,
                      timeout: TimeInterval = checkTimeout,
                      completion: @escaping (AiBlockBuddySubtitle) -> Void) {
        guard shouldCheck(intention: intention,
                          taskName: taskName,
                          mustAlignToFocusIntention: mustAlignToFocusIntention) else {
            DispatchQueue.main.async { completion(.itemOffTask) }
            return
        }
        let key = cacheKey(intention: intention, taskName: taskName)
        if let cached = aiBlockBuddyTaskIntentionCache[key] {
            DispatchQueue.main.async { completion(cached) }
            return
        }

        // `hasFinished` is only ever touched on the main queue — both the timeout and the checker's
        // answer hop there first — so the two racing paths can't both fire the completion.
        var hasFinished = false
        func finishOnMain(_ subtitle: AiBlockBuddySubtitle) {
            guard !hasFinished else { return }
            hasFinished = true
            completion(subtitle)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !hasFinished else { return }
            addLog(text: "ai-block buddy: task/intention check timed out — keeping the ordinary wording")
            finishOnMain(.itemOffTask)
        }

        askWhetherTaskDiverges(intention: intention,
                               taskName: taskName,
                               focusMode: focusMode,
                               checker: checker) { answer, isRealAnswer in
            // Only a real answer is remembered. Caching a fail-open would let one dropped request
            // silence the explanation for the rest of the session.
            if isRealAnswer { aiBlockBuddyTaskIntentionCache[key] = answer }
            DispatchQueue.main.async { finishOnMain(answer) }
        }
    }

    /// THE SEAM for backend#2428: the only place that sources "does the current task diverge from the
    /// focus goal?". Today it asks the interim `POST /user/task-intention-check`; when the relevance
    /// decision carries `task_diverges_from_focus_goal`, this reads that flag and the whole request —
    /// `checker`, the timeout, the second round trip — disappears from the check-in with nothing above
    /// or below it changing. `isRealAnswer` is false for anything that failed open, which must not be
    /// cached as an answer.
    private static func askWhetherTaskDiverges(intention: String,
                                               taskName: String,
                                               focusMode: String?,
                                               checker: TaskIntentionChecking,
                                               completion: @escaping (AiBlockBuddySubtitle, Bool) -> Void) {
        checker.checkTaskIntentionAlignment(intention: intention,
                                            taskName: taskName,
                                            focusMode: focusMode) { outcome in
            var isRealAnswer = false
            if case .success = outcome { isRealAnswer = true }
            completion(subtitle(for: outcome), isRealAnswer)
        }
    }

    /// Identity of an (intention, task) pair, case- and whitespace-insensitive. `\u{1}` separates the two
    /// halves so "ab" + "c" can't collide with "a" + "bc".
    static func cacheKey(intention: String, taskName: String) -> String {
        let intention = intention.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let task = taskName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return intention + "\u{1}" + task
    }
}

/// Answers already given this session, keyed by `AiBlockBuddyTaskIntention.cacheKey`. The check-in is
/// re-presented for every distinct app/site the user wanders onto, and the answer depends only on the
/// intention and the task — so without this, one off-intention task would buy a Gemini round trip per
/// block. Cleared with the rest of the per-session AI state in `refreshFocusModeData()`.
var aiBlockBuddyTaskIntentionCache: [String: AiBlockBuddySubtitle] = [:]

// MARK: - Context carried into the screen

/// Everything the buddy screen needs to block or allow the caught app/site, mirroring the arguments the
/// legacy `showPopupBlockConfirmWindow` receives so block/allow behave identically.
struct AiBlockContext {
    var blockedAppName: String
    var currentApp: NSRunningApplication?
    var url: String
    var fullUrl: String
    var script: String
    var browser: BROWSER?
    var isAppBlocking: Bool
    var isBrowser: Bool
    var aiBlockReason: String?
    var scoreForThisSiteApp: Double?
    var payload: [String: Any]?
    var isTaskMisalignedWithIntention: Bool? = nil

    /// Human label for the caught thing — the app name when blocking an app, else the URL.
    var itemLabel: String { isAppBlocking ? blockedAppName : (fullUrl.isEmpty ? url : fullUrl) }
}

// MARK: - Caught-item display label

/// Max length of the short URL shown in parentheses on the check-in header (host + a little path, then an
/// ellipsis — never the query string / fragment). Keeps a long link (e.g. a Stripe checkout URL with a huge
/// query string) from dumping across many unreadable lines.
private let kAiBlockBuddyUrlLabelMaxLength = 40

/// A short, readable form of a caught URL for display: scheme, query, and fragment stripped, leaving the
/// host and a little of the path, truncated to `kAiBlockBuddyUrlLabelMaxLength` with a trailing ellipsis
/// when it's longer (preferring a path-boundary cut so it doesn't end mid-token). Never shows the query
/// string / fragment, so a giant Stripe checkout link collapses to e.g. `checkout.stripe.com/c/pay/…`.
func aiBlockBuddyTruncatedUrl(_ rawUrl: String) -> String {
    var s = rawUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    for scheme in ["https://", "http://"] where s.lowercased().hasPrefix(scheme) {
        s.removeFirst(scheme.count)
    }
    if let cut = s.firstIndex(where: { $0 == "?" || $0 == "#" }) { s = String(s[..<cut]) }
    while s.hasSuffix("/") { s.removeLast() }
    guard s.count > kAiBlockBuddyUrlLabelMaxLength else { return s }
    let clipped = String(s.prefix(kAiBlockBuddyUrlLabelMaxLength))
    // Prefer to end at a path boundary (…/c/pay/… reads better than a mid-token cut like …/c/pay/cs_liv…).
    if let lastSlash = clipped.lastIndex(of: "/"), lastSlash > clipped.startIndex {
        return String(clipped[...lastSlash]) + "…"
    }
    return clipped + "…"
}

/// The header/label text for the caught item on the check-in. App blocks keep their existing label (app
/// name / window title). A URL block shows the page/tab TITLE with a short URL in parentheses — so a long
/// link (query string + fragment) never dumps across many lines — falling back to just the truncated URL
/// when no page title is available.
func aiBlockBuddyDisplayItemLabel(context: AiBlockContext, pageTitle: String) -> String {
    guard !context.isAppBlocking else { return context.itemLabel }
    let shortUrl = aiBlockBuddyTruncatedUrl(context.fullUrl.isEmpty ? context.url : context.fullUrl)
    let title = pageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty else { return shortUrl }
    return "\(title) (\(shortUrl))"
}

/// How long the user must hold the offline unlock button, and how long the caught app/site is then allowed
/// before the buddy re-checks in (a fresh hold if still offline).
let kAiBlockOfflineHoldSeconds: Double = 10
let kAiBlockOfflineAllowMinutes = 15

// MARK: - Meeting-related apps & domains (auto-allow while a meeting is on)

/// Named registry of the apps and website domains that a live meeting legitimately needs, so the AI-block
/// buddy never gets in the way of a call. Matched loosely (substring, case-insensitive) against the caught
/// app name / bundle id and URL. One place — no scattered magic strings.
enum AiBlockMeetingTargets {
    /// Lowercased fragments matched against the blocked app's display name and bundle identifier.
    static let appFragments = [
        "zoom", "microsoft teams", "com.microsoft.teams", "teams",
        "google meet", "webex", "cisco webex", "slack", "facetime",
        "google chat", "skype", "gotomeeting", "whereby", "discord",
        "calendar",   // the system Calendar app
    ]
    /// Lowercased domain fragments matched against the blocked URL.
    static let urlFragments = [
        "zoom.us", "teams.microsoft.com", "teams.live.com", "meet.google.com",
        "webex.com", "slack.com", "gotomeeting.com", "whereby.com",
        "chat.google.com", "discord.com", "skype.com",
    ]

    /// Whether the caught app/site in `context` looks meeting-related.
    static func matches(_ context: AiBlockContext) -> Bool {
        if context.isAppBlocking {
            let name = context.blockedAppName.lowercased()
            let bundle = (context.currentApp?.bundleIdentifier ?? "").lowercased()
            return appFragments.contains { !$0.isEmpty && (name.contains($0) || bundle.contains($0)) }
        }
        let haystack = (context.fullUrl.isEmpty ? context.url : context.fullUrl).lowercased()
        return urlFragments.contains { haystack.contains($0) }
    }
}

// MARK: - Presentation

var aiBlockBuddyWcObj: commonWindowController?

/// Watches for the user leaving the blocked app/site while the buddy is shown, so a stale prompt can
/// auto-dismiss (see `AiBlockBuddyDismissObserver`). Lives only while the window is on screen.
private var aiBlockBuddyDismissObserver: AiBlockBuddyDismissObserver?

/// Stable identity of the blocked item the buddy is CURRENTLY showing (nil when nothing is shown). Lets a
/// repeated `showAiBlockBuddyWindow` for the same still-caught item be a no-op instead of rebuilding the
/// SwiftUI root (which would reset the scroll position). Cleared when the window closes.
private var aiBlockBuddyShownItemKey: String?

/// The context of the buddy currently on screen, so the title-bar close button (handled in
/// `commonWindowController.windowShouldClose`) can block THIS caught app/site (#2577). Cleared on close.
private var aiBlockBuddyActiveContext: AiBlockContext?

/// The user closed the AI block popup via its title-bar close button (or ⌘W). Treat that as a deliberate
/// block of the caught app/site — the check-in offers no direct block on its primary/argue screens, so a
/// silent dismiss would be an escape hatch (#2577). Returns false: `aiBlockBuddyBlock` closes the window
/// itself, so we don't also let the default close run. Returns true (allow the plain close) only if no
/// context is known. The auto-dismiss path uses `window.close()`, which never calls this.
func aiBlockBuddyCloseButtonBlocks() -> Bool {
    guard let context = aiBlockBuddyActiveContext else { return true }
    aiBlockBuddyBlock(context)
    return false
}

/// When the user last picked/updated a task VIA the check-in (top-3 switch or "update your current task").
/// Set in `aiBlockBuddyAdoptPickedTask` (the shared adopt path). A check-in re-shown within
/// `kAiBlockBuddyCompactAfterPickSeconds` of a pick opens compact (pickers collapsed behind the "Switch to
/// another task" link) — the user JUST chose a task, so re-block ⇒ re-show shouldn't nag them with the full
/// selector again. Otherwise (first check-in, or no recent pick) the full pickers show. nil until the first
/// pick. Set from normal app code (never inside a SwiftUI body) so `Date()` here is fine.
var lastAiBlockBuddyTaskPickAt: Date? = nil

/// How recently a check-in task pick keeps a re-shown check-in compact (see `lastAiBlockBuddyTaskPickAt`).
let kAiBlockBuddyCompactAfterPickSeconds: TimeInterval = 15

/// Stable identity for an AI-block item: the app's bundle id (falling back to its name) for an app block,
/// or the URL for a site block. One definition shared by the re-prompt scheduler (which keys its timers on
/// it) and the duplicate-present guard, so both agree on what "the same item" means.
func aiBlockBuddyItemKey(for context: AiBlockContext) -> String {
    if context.isAppBlocking {
        return "app:" + (context.currentApp?.bundleIdentifier ?? context.blockedAppName)
    }
    return "url:" + (context.url.isEmpty ? context.fullUrl : context.url)
}

/// The buddy window/view height: the desired height, but never dominating a short screen. On a 13" laptop
/// the old 580 with a mere 40-pt margin filled almost the whole screen (and could push the pinned input
/// off the bottom); cap at both a generous margin AND ~80% of the usable height so it always sits fully
/// on-screen with breathing room. The window frame, the hosting view, and the SwiftUI `.frame` all use
/// this one value so they agree and the content controls stay reachable.
func aiBlockBuddyHeight() -> CGFloat {
    let usable = NSScreen.main?.visibleFrame.height ?? kAiBlockBuddyDesiredHeight
    let available = min(usable - 80, usable * 0.80)
    return min(kAiBlockBuddyDesiredHeight, max(kAiBlockBuddyMinHeight, available))
}

/// Which design variant to present: the blurred-over-the-app one whenever the blur backdrop window is up
/// behind the buddy (it blurs the blocked app; the buddy window lets it show through), else plain.
private func aiBlockBuddyBackdrop() -> AiBlockBuddyBackdrop {
    (blurWcObj?.window?.isVisible ?? false) ? .blurredBehindWindow : .plain
}

/// Present the SwiftUI AI-block buddy screen centered over the (already shown) blur backdrop, replacing
/// the legacy popup for the not-relevant AI decision. Mirrors the legacy window's level/centering.
func showAiBlockBuddyWindow(context: AiBlockContext) {
    addLog(text: "func:- showAiBlockBuddyWindow item=\(context.itemLabel) isApp=\(context.isAppBlocking)")

    // The focus block loop re-detects the still-caught app/site ~once a second and calls this again. If the
    // buddy is already on screen for the SAME item, rebuilding the hosting controller / re-framing the
    // window would reset the SwiftUI ScrollView to the top and throw away the user's scroll position. So a
    // repeat present for the same visible item is a no-op: keep the existing content, window, and
    // dismiss observer exactly as they are. A genuinely different item (or a not-yet-visible window) falls
    // through and rebuilds/reframes as before.
    let itemKey = aiBlockBuddyItemKey(for: context)
    if aiBlockBuddyWcObj?.window?.isVisible == true, aiBlockBuddyShownItemKey == itemKey {
        return
    }
    aiBlockBuddyShownItemKey = itemKey

    // #2577: the popup keeps its native title-bar close button. Closing it is a deliberate BLOCK of the
    // caught app/site (see commonWindowController.windowShouldClose), because the check-in itself offers no
    // direct block on its primary/argue screens — so the close button must not be a silent escape.
    aiBlockBuddyActiveContext = context
    if aiBlockBuddyWcObj == nil {
        aiBlockBuddyWcObj = mainStoryboard.instantiateController(
            withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        aiBlockBuddyWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
        aiBlockBuddyWcObj?.window?.styleMask.insert(.closable)
        aiBlockBuddyWcObj?.window?.title = appName
        aiBlockBuddyWcObj?.window?.isMovable = false
    }
    // Over the blur backdrop the screen uses the design's blurred variant: the (already blurred) app
    // shows through under a near-opaque white gradient, so the window itself must be transparent. With
    // no backdrop it's an opaque solid dialog — a see-through window over the raw desktop is unreadable.
    let backdrop = aiBlockBuddyBackdrop()
    aiBlockBuddyWcObj?.window?.isOpaque = !backdrop.isBlurred
    aiBlockBuddyWcObj?.window?.backgroundColor = backdrop.isBlurred ? NSColor.clear : NSColor.windowBackgroundColor
    aiBlockBuddyWcObj?.window?.alphaValue = 1

    let vc = AiBlockBuddyHostingController(context: context, backdrop: backdrop)
    aiBlockBuddyWcObj?.contentViewController = vc

    let width = kAiBlockBuddyWidth, height = aiBlockBuddyHeight()
    let blurFrame = blurWcObj?.window?.frame
    var midX = blurFrame?.midX ?? 0
    var midY = blurFrame?.midY ?? 0
    if !(blurWcObj?.window?.isVisible ?? false) {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        midX = screenFrame.width / 2
        midY = screenFrame.height / 2
    }
    // Clamp the origin so the (possibly screen-capped) window sits fully inside the visible area — never
    // hanging off the bottom where the input/action row would be unreachable.
    let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    let originX = min(max(midX - width / 2, visible.minX), visible.maxX - width)
    let originY = min(max(midY - height / 2, visible.minY), visible.maxY - height)
    aiBlockBuddyWcObj?.window?.setFrame(NSRect(x: originX, y: originY, width: width, height: height), display: true)
    aiBlockBuddyWcObj?.showWindow(nil)

    // Auto-dismiss the prompt once the user moves off the distraction — either by switching to a
    // different app, or (for a browser) by switching tabs / windows / navigating away from the blocked
    // URL. The stale prompt is about the caught page, so leaving it should dismiss and let the focus loop
    // re-check whatever they moved to. For an APP block whose blocked app is actually a browser (e.g. a
    // Chrome site-specific-browser window that shares Chrome's bundle id), we poll the active tab too —
    // moving to a different window/tab of the SAME browser fires no app-activation notice.
    let pollTarget = aiBlockBuddyBrowserPollTarget(for: context)
    aiBlockBuddyDismissObserver?.invalidate()
    aiBlockBuddyDismissObserver = AiBlockBuddyDismissObserver(
        blockedBundleId: context.currentApp?.bundleIdentifier,
        blockedAppName: context.isAppBlocking ? context.blockedAppName : nil,
        browser: pollTarget.browser,
        blockedUrl: pollTarget.url,
        onLeaveBlockedApp: { closeAiBlockBuddyWindow() })
}

/// The browser + active-tab URL the dismiss observer should poll, so leaving the blocked page dismisses
/// even when it can't be seen as an app switch:
///  • URL block → the caught browser + caught URL (unchanged from before).
///  • APP block whose blocked app is a browser (resolved from the bundle id, so a Chrome SSB / PWA window
///    counts even though its app name isn't "Google Chrome") → that browser + its current active-tab URL,
///    so switching to a DIFFERENT window/tab of the same browser (same bundle id, no activation notice)
///    still dismisses the stale prompt.
///  • APP block for a non-browser → (nil, nil): no URL poll, app-activation dismiss is enough.
private func aiBlockBuddyBrowserPollTarget(for context: AiBlockContext) -> (browser: BROWSER?, url: String?) {
    guard context.isAppBlocking else {
        return (context.browser, context.fullUrl.isEmpty ? context.url : context.fullUrl)
    }
    guard let bundleId = context.currentApp?.bundleIdentifier,
          let browser = browserFromBundleId(bundleId) else { return (nil, nil) }
    return (browser, getActiveTabUrlOf(browser: browser))
}

/// Close the buddy window + its blur backdrop and stop the AI URL/app timers (same teardown the legacy
/// popup does on its terminal actions). Also tears down the frontmost-app observer so it can't fire
/// after dismissal.
private func closeAiBlockBuddyWindow() {
    addLog(text: "closeAiBlockBuddyWindow called")   // FLICKER-DIAG
    aiBlockBuddyDismissObserver?.invalidate()
    aiBlockBuddyDismissObserver = nil
    aiBlockBuddyShownItemKey = nil
    aiBlockBuddyActiveContext = nil
    aiBlockBuddyWcObj?.window?.close()
    blurWcObj?.window?.close()
}

// MARK: - Auto-dismiss when the user leaves the blocked app/site

/// While the buddy is on screen, dismiss the prompt once the user moves off the blocked distraction:
///  • switches to a DIFFERENT app (frontmost-app notification), or
///  • moves the blocked browser AWAY from the blocked URL — switching tabs, or switching to a different
///    window of the SAME browser (a same-bundle-id switch, e.g. from a Chrome site-specific-browser window
///    to a normal Chrome window, fires NO app-activation notice) — detected by polling the active tab URL.
/// The prompt is about the caught page, so it's stale the moment they leave it. Activating Focus Bear's
/// own windows never dismisses. The observer is invalidated when the window closes, so it can't leak or
/// fire after dismissal.
final class AiBlockBuddyDismissObserver {
    private let blockedBundleId: String?
    private let blockedAppNameLower: String?
    private let browser: BROWSER?
    private let normalizedBlockedUrl: String?
    private let onLeaveBlockedApp: () -> Void
    private var token: NSObjectProtocol?
    private var keyWindowToken: NSObjectProtocol?
    private var urlPollTimer: Timer?
    private var frontWindowPollTimer: Timer?
    /// Whether a tab read from the URL poll is still outstanding. The read no longer happens on the
    /// main thread, so a slow browser would otherwise let ticks pile one read on top of another.
    private var isReadingPolledUrl = false

    /// When this observer (and so the buddy) was created. Presenting the buddy can itself briefly activate
    /// Focus Bear; a Focus-Bear activation within `focusBearActivationGrace` of that is treated as the
    /// prompt's own appearance, not the user switching back to the app — so the fresh prompt never
    /// dismisses itself.
    private let presentedAt = Date()

    /// How often to re-read the blocked browser's active tab URL. A tab switch/navigation raises no
    /// app-activation notification, so we poll; kept gentle to stay off the AppleScript hot path.
    private static let urlPollInterval: TimeInterval = 1.5

    /// Grace after presentation during which a Focus-Bear activation is ignored (see `presentedAt`).
    private static let focusBearActivationGrace: TimeInterval = 1.0

    init(blockedBundleId: String?, blockedAppName: String?, browser: BROWSER?, blockedUrl: String?,
         onLeaveBlockedApp: @escaping () -> Void) {
        self.blockedBundleId = blockedBundleId
        let trimmedName = blockedAppName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.blockedAppNameLower = (trimmedName?.isEmpty == false) ? trimmedName : nil
        self.browser = browser
        self.normalizedBlockedUrl = blockedUrl.map(AiBlockBuddyDismissObserver.normalize)
        self.onLeaveBlockedApp = onLeaveBlockedApp
        token = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] note in
                self?.handleActivation(note)
            }
        // Switching to Focus Bear's OWN main window (e.g. the Day Plan) fires no app-activation notice
        // when the buddy already made Focus Bear frontmost. Watch key-window changes so moving onto the
        // app itself (off the distraction) dismisses — while interacting with the buddy does not.
        keyWindowToken = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] note in
                self?.handleWindowBecameKey(note)
            }
        startUrlPollIfBrowserBlock()
        startFrontWindowPoll()
    }

    /// Notification-independent backstop: poll the frontmost user-facing WINDOW's owning app name and
    /// dismiss once it's no longer the blocked app. This catches cases the app-activation + URL polls miss —
    /// notably a Chrome PWA / site-specific-browser (e.g. "Safe FB Team Comms"): switching from its window to
    /// a normal Chrome window fires NO app-activation, and the browser URL poll targets the MAIN Chrome app
    /// (a different window than the PWA), so neither detects the move. The frontmost on-screen window's owner
    /// name DOES change (e.g. "Safe FB Team Comms" → "Google Chrome"), so we compare against that.
    private func startFrontWindowPoll() {
        guard let blockedName = blockedAppNameLower else { return }   // app blocks only
        // Only needed for BROWSER app blocks — a Chrome PWA/SSB window shares the browser's bundle id, so a
        // same-bundle-id window switch fires no app-activation and must be caught by owner NAME. For a normal
        // app, `handleActivation` (bundle-id based) already handles leaving, and comparing owner NAME here
        // false-positives whenever the CGWindow owner name differs from the block's app name (e.g. iTerm's
        // owner name is "iTerm2" but the block name is "iTerm") — which dismissed the buddy every second.
        guard browser != nil else { return }
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // nil = couldn't read a foreign window this tick — don't dismiss on a read miss.
            guard let frontOwner = self.frontmostNonFocusBearWindowOwnerName()?.lowercased() else { return }
            if frontOwner != blockedName { self.onLeaveBlockedApp() }
        }
        RunLoop.main.add(timer, forMode: .common)
        frontWindowPollTimer = timer
    }

    /// The owning app name of the frontmost on-screen normal window that is NOT one of Focus Bear's own
    /// windows (the buddy / blur sit on top but belong to us). This is the app the user is actually looking
    /// at behind the prompt — reliable even for PWAs that share Chrome's process and fire no activation.
    private func frontmostNonFocusBearWindowOwnerName() -> String? {
        let myPid = NSRunningApplication.current.processIdentifier
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        guard let infoList = CGWindowListCopyWindowInfo(options, CGWindowID(0)) as? [[String: AnyObject]] else {
            return nil
        }
        for info in infoList {
            let layer = info[kCGWindowLayer as String] as? Int ?? 0
            guard layer == 0 else { continue }   // normal app windows only (skip menu bar / overlays)
            let ownerPid = info[kCGWindowOwnerPID as String] as? pid_t ?? -1
            if ownerPid == myPid { continue }     // skip Focus Bear's own windows (buddy, blur)
            return info[kCGWindowOwnerName as String] as? String
        }
        return nil
    }

    /// A Focus Bear window took key focus. If it's the buddy or its blur backdrop, the user is engaging
    /// with the prompt — keep it up. Any OTHER Focus Bear window (the Day Plan / main window) becoming key
    /// means they switched to the app itself, off the blocked distraction — so dismiss the stale prompt.
    /// (This notification is app-local, so `window` is always one of our own windows.)
    private func handleWindowBecameKey(_ note: Notification) {
        guard let window = note.object as? NSWindow else { return }
        if window == aiBlockBuddyWcObj?.window || window == blurWcObj?.window { return }
        // Only the app's MAIN window (the Day Plan) becoming key means the user moved off the distraction
        // ONTO the app itself. Other transient Focus Bear windows — the To-Do player, the meeting/appointment
        // popup, etc. — routinely take key focus while the buddy is up; dismissing on those closed and
        // immediately reopened the buddy every time one appeared, which read as rapid flickering.
        guard window == mainWindowControllerObj?.window else { return }
        addLog(text: "aiBlockBuddy dismiss: main window became key")   // FLICKER-DIAG
        onLeaveBlockedApp()
    }

    private func handleActivation(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        let activatedBundleId = app.bundleIdentifier
        // Focus Bear itself came forward. This is the reliable signal for the reported repro: bringing the
        // Day Plan up from the Dock / menu bar activates the app but does NOT make the main window key (the
        // buddy sits at popUpMenuWindow level and keeps key), so `handleWindowBecameKey` never fires. So
        // decide here whether the user is on the app itself vs the prompt — don't blindly ignore it.
        if activatedBundleId == mainAppBundelId {
            handleFocusBearActivated()
            return
        }
        // Still on the blocked app/site — keep the prompt up.
        if let blocked = blockedBundleId, activatedBundleId == blocked { return }
        addLog(text: "aiBlockBuddy dismiss: app activated \(activatedBundleId ?? "?") (blocked=\(blockedBundleId ?? "?"))")   // FLICKER-DIAG
        onLeaveBlockedApp()
    }

    /// Focus Bear was activated. If the user is now looking at the app's own content (the Day Plan / main
    /// window) rather than the buddy or its blur backdrop, the prompt about the caught page is stale —
    /// dismiss it. Ignored during the brief post-presentation grace so the prompt's own appearance (which
    /// can momentarily activate Focus Bear) doesn't dismiss the freshly shown prompt.
    private func handleFocusBearActivated() {
        guard Date().timeIntervalSince(presentedAt) > Self.focusBearActivationGrace else { return }
        // Let the key/main window settle after activation before deciding which window is in front.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isUserEngagingBuddy() { return }
            addLog(text: "aiBlockBuddy dismiss: Focus Bear activated + not engaging buddy (main window front)")   // FLICKER-DIAG
            self.onLeaveBlockedApp()
        }
    }

    /// Whether the user is interacting with the prompt rather than the app itself. Checked in order:
    ///  1. The buddy (or its blur) is the KEY window → they're actively interacting with the prompt (e.g.
    ///     they clicked it to argue / update the task) → keep it up.
    ///  2. Otherwise, if Focus Bear's own main window (the Day Plan) is the app's key OR main window, they
    ///     brought the app forward to look at it (the repro: activated from the Dock / menu bar, which does
    ///     NOT make the Day Plan the KEY window, so the didBecomeKey observer misses it — but it does become
    ///     the app's `mainWindow`) → the prompt is stale → dismiss.
    ///  3. Ambiguous → default to keeping the prompt (the buddy is a high-level popup; don't dismiss blindly).
    private func isUserEngagingBuddy() -> Bool {
        if let key = NSApp.keyWindow, key == aiBlockBuddyWcObj?.window || key == blurWcObj?.window {
            return true
        }
        if let main = mainWindowControllerObj?.window, main.isVisible,
           main.isKeyWindow || NSApp.mainWindow == main {
            return false
        }
        return true
    }

    /// For a browser URL block, poll the active tab URL and dismiss once it no longer matches the blocked
    /// URL — i.e. the user switched tabs or navigated away. No-op for app blocks (nil browser/URL).
    /// NOTE: we deliberately do NOT gate on the browser being frontmost — presenting the buddy makes Focus
    /// Bear the frontmost app, so such a gate would never fire. `getActiveTabUrlOf` queries the browser via
    /// AppleScript regardless of which app is frontmost, so reading it here is safe and correct.
    private func startUrlPollIfBrowserBlock() {
        guard let browser = browser, normalizedBlockedUrl != nil else { return }
        let timer = Timer(timeInterval: Self.urlPollInterval, repeats: true) { [weak self] _ in
            guard let self = self, !self.isReadingPolledUrl else { return }
            self.isReadingPolledUrl = true
            // `getActiveTabUrlOf` runs AppleScript and blocks whichever thread asks until the browser
            // answers. On the main thread that is a frozen UI on every tick a browser is slow to reply —
            // `runAppleScriptSafely` caps the main-thread wait at 1.2s, which bounds the freeze without
            // removing it (Sentry FOCUS-BEAR-MACOS-19R caught the same call blocking thread 0). So read
            // on a background queue and decide back on main. Deliberately no semaphore and no bounce
            // onto main while waiting: that is the shape PR #2009 had to undo — see
            // `fetchBrowserAllTabUrlsInBackground`, which documents why a background caller may call
            // straight into the browser helpers.
            DispatchQueue.global(qos: .userInitiated).async {
                let current = getActiveTabUrlOf(browser: browser)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isReadingPolledUrl = false
                    // A read started before the poll was invalidated must not still act on it. The
                    // synchronous version could not fire after `invalidate()` ran on main, and neither
                    // may this: `urlPollTimer` is cleared there, and this hop is on main too.
                    guard self.urlPollTimer != nil else { return }
                    // nil = couldn't read the tab this tick (permission/AppleScript hiccup) — don't
                    // dismiss on a read failure, just wait for the next tick.
                    guard let current = current else { return }
                    if Self.normalize(current) != self.normalizedBlockedUrl {
                        self.onLeaveBlockedApp()
                    }
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        urlPollTimer = timer
    }

    /// Loosely normalize a URL for "same page?" comparison: lowercase, drop scheme, a leading `www.`, and
    /// any trailing slash. Deliberately coarse — a query-string tweak shouldn't count as leaving, but a
    /// real tab/navigation change should.
    private static func normalize(_ url: String) -> String {
        var s = url.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for scheme in ["https://", "http://"] where s.hasPrefix(scheme) { s.removeFirst(scheme.count) }
        if s.hasPrefix("www.") { s.removeFirst(4) }
        while s.hasSuffix("/") { s.removeLast() }
        return s
    }

    func invalidate() {
        if let token = token {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        token = nil
        if let keyWindowToken = keyWindowToken {
            NotificationCenter.default.removeObserver(keyWindowToken)
        }
        keyWindowToken = nil
        urlPollTimer?.invalidate()
        urlPollTimer = nil
        frontWindowPollTimer?.invalidate()
        frontWindowPollTimer = nil
    }

    deinit { invalidate() }
}

// MARK: - Block / allow actions (reuse the legacy primitives)

/// Block the caught app/site exactly as the legacy popup's "Block" does, then tear down. Cancels any
/// pending time-box re-prompt for this item — the user chose to block, so there's nothing to re-check.
private func aiBlockBuddyBlock(_ context: AiBlockContext) {
    AiBlockRepromptScheduler.shared.cancel(context: context)
    if context.isAppBlocking, let app = context.currentApp {
        focusBlockUnwantedApp(runningApp: app, appName: context.blockedAppName,
                              showNotification: false, isAppBlockByAi: true)
    } else {
        focusBlockUnwantedUrl(script: context.script, url: context.url,
                              lastBlockReasonFromAi: context.aiBlockReason, browser: context.browser,
                              isUrlBlockByAi: true, blockReason: "")
    }
    closeAiBlockBuddyWindow()
}

/// Add the caught app/site to this focus session's allow-list, mirroring the legacy "yes, just this time"
/// path. Shared by the argue→allow flow and the meeting auto-allow.
private func aiBlockBuddyAddToSessionAllowList(_ context: AiBlockContext) {
    if context.isAppBlocking, let app = context.currentApp {
        arrAllowedAppsInCuddlyModeCurrentFocus.append(app)
        if let browser = context.browser, let title = getActiveTabTitleOf(browser: browser)?.lowercased() {
            arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(title)
        }
    } else {
        arrAllowedUrlsInCuddlyModeCurrentFocus.append(context.url)
    }
}

/// Dismiss the prompt WITHOUT blocking or allow-listing, then refocus the caught app/site so the normal
/// focus loop re-evaluates it against the (just-changed) intention. Used when the user switches their
/// active task: the page may now be relevant to the new task, so we let the loop re-decide rather than
/// blindly blocking. Cancels any pending re-prompt for this item first. If it's still off-task the loop
/// raises a fresh check-in for the new task.
private func aiBlockBuddyRecheckAgainstCurrentIntention(_ context: AiBlockContext) {
    AiBlockRepromptScheduler.shared.cancel(context: context)
    closeAiBlockBuddyWindow()
    aiBlockBuddyRefocus(context)
}

/// Re-focus the caught app/site after allowing it (Focus Bear steps out of the way).
private func aiBlockBuddyRefocus(_ context: AiBlockContext) {
    DispatchQueue.main.async {
        NSApplication.shared.deactivate()
        if let app = context.currentApp {
            app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        } else if let last = lastFrontMostApplication {
            last.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        }
    }
}

/// Allow the caught app/site for `minutes`, then re-check in (used when the AI is convinced it's relevant).
/// Adds it to the session allow-list, records the user's argue justification so later backend URL/app
/// safety checks see it (see `recordAiBlockBuddyJustification`), schedules a time-boxed re-prompt, closes
/// the buddy, and re-focuses the app. The allow is NOT permanent — after `minutes` the buddy re-appears for
/// a fresh check-in while the session is still running.
///
/// `justification` is the user's stated reason from the argue chat. Recording it into the same session
/// state the legacy convince-AI flow uses means a DIFFERENT URL on the same allowed domain (e.g. another
/// photo on photos.google.com) is re-judged WITH the prior reason instead of being blocked from scratch.
private func aiBlockBuddyAllow(_ context: AiBlockContext, minutes: Int, justification: String) {
    aiBlockBuddyAddToSessionAllowList(context)
    let pageTitle = context.browser.flatMap { getActiveTabTitleOf(browser: $0) } ?? ""
    recordAiBlockBuddyJustification(justification: justification, isApp: context.isAppBlocking,
                                    appName: context.blockedAppName, url: context.url,
                                    fullUrl: context.fullUrl, pageTitle: pageTitle,
                                    allowedMinutes: minutes)
    AiBlockRepromptScheduler.shared.schedule(context: context, minutes: minutes)
    closeAiBlockBuddyWindow()
    aiBlockBuddyRefocus(context)
}

/// The AI buddy can't run offline (every verdict is a backend call), so instead of leaving the user stuck
/// on a chat that only ever errors, we gate the unlock behind a deliberate hold. Once they've held the
/// button for `kAiBlockOfflineHoldSeconds`, allow the caught app/site for a time-boxed window (added to the
/// session allow-list + a re-prompt scheduled) and step out of the way — mirroring `aiBlockBuddyAllow`
/// without the argue justification (there's no chat offline).
private func aiBlockBuddyOfflineHoldUnlock(_ context: AiBlockContext) {
    allApiObject.capturePosthog(event: "ai-block-buddy-offline-hold-unlocked",
                                metadata: ["is_app": context.isAppBlocking ? "true" : "false"])
    aiBlockBuddyAddToSessionAllowList(context)
    AiBlockRepromptScheduler.shared.schedule(context: context, minutes: kAiBlockOfflineAllowMinutes)
    closeAiBlockBuddyWindow()
    aiBlockBuddyRefocus(context)
}

/// A meeting is happening now and the caught app/site is meeting-related — allow it silently for the
/// session (no buddy, no block, no time-box) so a live meeting is never interrupted. Reads the meeting
/// state LIVE. Returns true when it handled the moment (the caller should stop and NOT show the buddy).
func autoAllowMeetingRelatedIfNeeded(context: AiBlockContext) -> Bool {
    guard currentMeetingTitleIfAny() != nil, AiBlockMeetingTargets.matches(context) else { return false }
    allApiObject.capturePosthog(event: "ai-block-buddy-meeting-auto-allowed",
                                metadata: ["is_app": context.isAppBlocking ? "true" : "false"])
    aiBlockBuddyAddToSessionAllowList(context)
    closeAiBlockBuddyWindow()   // dismiss the blur backdrop the block flow already raised
    aiBlockBuddyRefocus(context)
    return true
}

// MARK: - Time-boxed re-prompt

/// Schedules and tracks the "re-check in after the allowed minutes" timers for the argue→allow flow.
/// Keeps one timer per app/site (keyed by bundle id / URL) so allows never stack duplicate timers, and
/// cancels cleanly when the user blocks, the session ends, or the item is re-allowed. Main-thread only:
/// timers run on the main run loop and the registry is only touched from main-thread UI/focus-loop code.
final class AiBlockRepromptScheduler {
    static let shared = AiBlockRepromptScheduler()
    private var timers: [String: Timer] = [:]
    private init() {}

    private func key(for context: AiBlockContext) -> String {
        aiBlockBuddyItemKey(for: context)
    }

    /// Allow expires after `minutes`; then re-check in. Replaces any existing timer for the same item so
    /// two allows can't stack timers.
    func schedule(context: AiBlockContext, minutes: Int) {
        let itemKey = key(for: context)
        timers[itemKey]?.invalidate()
        let clamped = min(kAiBlockMaxAllowMinutes, max(kAiBlockMinAllowMinutes, minutes))
        let timer = Timer(timeInterval: TimeInterval(clamped) * 60, repeats: false) { [weak self] timer in
            timer.invalidate()
            self?.fire(itemKey: itemKey, context: context)   // added to RunLoop.main → fires on main thread
        }
        RunLoop.main.add(timer, forMode: .common)
        timers[itemKey] = timer
        addLog(text: "ai-block reprompt scheduled for \(itemKey) in \(clamped)m")
    }

    private func fire(itemKey: String, context: AiBlockContext) {
        timers.removeValue(forKey: itemKey)
        // Session over → nothing to re-check (the allow-list was already cleared at session end).
        guard isFocusModeRunning else { return }
        // Time box elapsed: drop the temporary allow so the app/site is guarded again.
        removeFromSessionAllowList(context)
        // Only re-prompt if they're still ON it; otherwise the normal block loop re-checks when they
        // return, so re-showing now would interrupt whatever they moved on to.
        guard isBlockedItemFrontmost(context) else { return }
        showAiBlockBuddyReprompt(context: context)
    }

    /// Cancel the pending re-prompt for one item (user blocked it, or it's being re-allowed).
    func cancel(context: AiBlockContext) {
        let itemKey = key(for: context)
        timers[itemKey]?.invalidate()
        timers.removeValue(forKey: itemKey)
    }

    /// Cancel every pending re-prompt — called when the focus session ends so no timer fires afterwards.
    func cancelAll() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
    }

    /// Remove the item from the session allow-list, mirroring `aiBlockBuddyAddToSessionAllowList`.
    private func removeFromSessionAllowList(_ context: AiBlockContext) {
        if context.isAppBlocking {
            if let bundleId = context.currentApp?.bundleIdentifier {
                arrAllowedAppsInCuddlyModeCurrentFocus.removeAll { $0.bundleIdentifier == bundleId }
            }
            if let browser = context.browser, let title = getActiveTabTitleOf(browser: browser)?.lowercased() {
                arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll { $0 == title }
            }
        } else {
            arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll { $0 == context.url }
        }
    }

    /// Whether the blocked app/site is the frontmost app right now (for both app and browser-URL blocks
    /// the caught app is `context.currentApp`).
    private func isBlockedItemFrontmost(_ context: AiBlockContext) -> Bool {
        guard let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
              let blocked = context.currentApp?.bundleIdentifier else { return false }
        return front == blocked
    }

    /// Re-raise the blur backdrop + the buddy for a fresh check-in on the same app/site.
    private func showAiBlockBuddyReprompt(context: AiBlockContext) {
        allApiObject.capturePosthog(event: "ai-block-buddy-reprompt-shown",
                                    metadata: ["is_app": context.isAppBlocking ? "true" : "false"])
        showBlurBackdropForFrontmostApp(browser: context.browser)
        showAiBlockBuddyWindow(context: context)
    }
}

// MARK: - Hosting controller

/// Hosts `AiBlockBuddyView` in the buddy window and wires its callbacks to the block/allow primitives,
/// Day Plan store, and the AI relevance evaluation.
final class AiBlockBuddyHostingController: NSViewController {
    private let context: AiBlockContext
    private let backdrop: AiBlockBuddyBackdrop

    init(context: AiBlockContext, backdrop: AiBlockBuddyBackdrop) {
        self.context = context
        self.backdrop = backdrop
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        let ctx = context
        // The browser tab title (or, for an APP block, the app's focused-window title — e.g. iTerm's
        // "literature-search" — via Accessibility; the app name alone is uninformative). Read now, while the
        // blocked app is still the user-facing frontmost app (Focus Bear is only briefly on top). Fed to the
        // AI title guess AND used to build the caught-item display label.
        let pageTitle: String
        if let browser = ctx.browser {
            pageTitle = getActiveTabTitleOf(browser: browser) ?? ""
        } else if ctx.isAppBlocking, let app = currentUserFacingApp() {
            pageTitle = claudeTitleReader.shared.focusedWindowTitle(for: app) ?? ""
        } else {
            pageTitle = ""
        }
        // For a URL block, show the page title with a short truncated URL in parentheses instead of the raw
        // (possibly enormous) link; app blocks keep their app-name / window-title label.
        let displayItemLabel = aiBlockBuddyDisplayItemLabel(context: ctx, pageTitle: pageTitle)
        // Offline → the AI buddy's every verdict is a backend call, so the chat can only error. Replace it
        // with a deliberate hold-to-unlock gate instead of a dead chat.
        if !Reachability.isConnectedToNetwork() {
            let offlineView = AiBlockHoldToUnlockView(
                itemLabel: displayItemLabel,
                contentHeight: aiBlockBuddyHeight(),
                backdrop: backdrop,
                onBlock: { aiBlockBuddyBlock(ctx) },
                onHoldComplete: { aiBlockBuddyOfflineHoldUnlock(ctx) })
            let offlineHost = NSHostingView(rootView: offlineView)
            offlineHost.frame = NSRect(x: 0, y: 0, width: kAiBlockBuddyWidth, height: aiBlockBuddyHeight())
            self.view = offlineHost
            return
        }
        // Read the Day Plan fresh at present-time (a new hosting controller is built per presentation)
        // so the top-3 list and project names reflect edits the user just made — never a value cached
        // at window creation. The store hydrates synchronously from UserDefaults, so this is the latest.
        let topTasks = topDayPlanTasks(limit: 3)
        let dayPlanTaskLines = accountabilityBuddyDayPlanTasks()
        // The caught URL, used to prefill the save-task Description — read now, while the app/site is frontmost.
        let itemUrl = ctx.fullUrl.isEmpty ? ctx.url : ctx.fullUrl
        // The session's stated GOAL and the task the user is actually working on are two different things
        // (the safety endpoints keep them apart too): the goal is `whatToAchieveInFocusBlock`, the task is
        // the queue's active entry. The check-in's CURRENT TASK row shows the task, falling back to the goal
        // when the session has no task. Read fresh at present-time like the top-3 list.
        let focusIntention = whatToAchieveInFocusBlock.trimmingCharacters(in: .whitespacesAndNewlines)
        let activeTaskTitle = getCurrentTaskInFocusMode()?.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentTaskLabel = aiBlockBuddyCurrentTaskLabel(activeTaskTitle: activeTaskTitle,
                                                            focusIntention: focusIntention)
        let todaysTasks = DayPlanTaskStore.shared.tasks(for: Date())
        let existingTaskTitles = todaysTasks.filter { !$0.done }.map { $0.title }
        // The Day Plan task behind that label (same title match `aiBlockBuddyUpdateCurrentTask` uses), so
        // the row can show its project and be ticked done. nil when the label is free text.
        let currentTask = todaysTasks.first { $0.title.caseInsensitiveCompare(currentTaskLabel) == .orderedSame }
        // Collapse the pickers only when the user JUST chose a task via the check-in — i.e. this re-shown
        // check-in is the ~15s re-block after a pick — not merely because a focus intention is set (that's
        // almost always the case, which wrongly collapsed the very first check-in). Computed here in app
        // code so `Date()` isn't touched inside a SwiftUI body.
        let taskPickedRecently = lastAiBlockBuddyTaskPickAt
            .map { Date().timeIntervalSince($0) < kAiBlockBuddyCompactAfterPickSeconds } ?? false
        // The block list the session is running, named for the alignment check so the server can weigh the
        // task against the mode the user chose ("Deep work" reads differently from "Admin").
        let runningFocusModeName = currentRunningFocusType[FocusModeDictionaryKey.name] as? String
        let view = AiBlockBuddyView(
            itemLabel: displayItemLabel,
            currentIntention: currentTaskLabel,
            sessionIntention: focusIntention,
            currentTask: currentTask,
            taskPickedRecently: taskPickedRecently,
            topTasks: topTasks,
            existingTaskTitles: existingTaskTitles,
            projectNames: DayPlanTaskStore.shared.allProjectNames(),
            defaultNotes: ctx.isAppBlocking ? "" : itemUrl,
            pageTitle: pageTitle,
            contentHeight: aiBlockBuddyHeight(),
            backdrop: backdrop,
            onUpdateCurrentTask: { name in aiBlockBuddyUpdateCurrentTask(name, context: ctx) },
            onSwitch: { picked in
                // Switch the ACTIVE task to the picked one, then immediately re-check the current page.
                aiBlockBuddyAdoptPickedTask(picked)
                allApiObject.capturePosthog(event: "ai-block-buddy-switched-to-top-task", metadata: [:])
                // Don't hard-block the current page: switching the active task changes what counts as
                // relevant, so this page may now fit the new task. Close the prompt and refocus; the focus
                // loop re-evaluates the current app/site against the new intention (its convince cache was
                // just reset by `clearAiBlockingDecisionsForNewFocusTarget`) and re-blocks only if it's
                // STILL off-task.
                aiBlockBuddyRecheckAgainstCurrentIntention(ctx)
            },
            onSetTaskDone: { task, done in
                // Tick (or un-tick — a mis-click must be reversible) a top-3 / current task straight from the check-in,
                // using the same path the Day Plan uses (set done + `update`, which syncs the backing to-do's
                // status via DayPlanSync).
                aiBlockBuddySetTopTaskDone(task, done: done)
            },
            onSaveTask: { task in
                // "Save what I'm doing as a task" straight from the check-in — persist to the Day Plan
                // without switching to a top task or blocking; the user stays on the check-in to decide.
                DayPlanTaskStore.shared.add(task, for: Date())
                allApiObject.capturePosthog(event: "ai-block-buddy-saved-current-as-task", metadata: [:])
            },
            onEvaluate: { topTaskTitle, messages, done in
                let msgs = messages.map { (role: $0.role.apiRole, text: $0.text) }
                // Send the three things the safety endpoints keep separate: the session GOAL (`intention`),
                // the task being worked on right now (`currentTaskInToDoPlayer`) — judged against first, so
                // a user deliberately on a lower-priority planned task isn't nagged about a different one —
                // and today's plan (`current_tasks`, filled in by AllApi). Re-read at send time so a task
                // the user just switched to in this check-in is the one judged.
                allApiObject.evaluateBlockRelevanceConversation(
                    item: ctx.itemLabel, topTask: topTaskTitle,
                    currentTask: getCurrentTaskInFocusMode() ?? currentTaskLabel,
                    intention: currentFocusIntentionForRequest(),
                    windowTitle: pageTitle, isApp: ctx.isAppBlocking, messages: msgs,
                    dayPlanTasks: dayPlanTaskLines, completion: done)
            },
            onSuggestTitle: { done in
                allApiObject.suggestTaskTitleForBlockedItem(
                    appName: ctx.blockedAppName, url: itemUrl, pageTitle: pageTitle, completion: done)
            },
            onAllow: { minutes, justification in
                allApiObject.capturePosthog(event: "ai-block-buddy-argued-and-allowed",
                                            metadata: ["minutes": "\(minutes)"])
                aiBlockBuddyAllow(ctx, minutes: minutes, justification: justification)
            },
            aiBlockReason: ctx.aiBlockReason,
            alignmentScore: ctx.scoreForThisSiteApp,
            onReportBadAi: { reason in
                // Same event AND the same reason field as the legacy report-bad-AI screen, so both
                // feed one review stream that can actually be read (report 2026-09-14_15-05-53).
                allApiObject.capturePosthog(event: "bad-ai-blocking-decision", metadata: [
                    "userFeedbackOnDecision": reason,
                    "source": "ai-block-buddy",
                    "item": ctx.itemLabel,
                    "is_app": ctx.isAppBlocking ? "true" : "false",
                    // The goal and the task are separate signals — a bad-decision report needs both.
                    "intention": focusIntention,
                    "current_task": activeTaskTitle ?? "",
                    "ai_reason": ctx.aiBlockReason ?? "",
                    "focus_alignment_score": ctx.scoreForThisSiteApp.map { "\(Int($0.rounded()))" } ?? "",
                ])
            },
            onCheckTaskAlignment: { done in
                done(AiBlockBuddyTaskIntention.subtitle(
                    misaligned: ctx.isTaskMisalignedWithIntention,
                    mustAlign: isTaskRequiredToAlignToFocusIntention(),
                    reason: ctx.aiBlockReason ?? ""))
            })
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: kAiBlockBuddyWidth, height: aiBlockBuddyHeight())
        self.view = host
    }
}

/// Adopt the picked Day Plan task as the CURRENT TASK — never as the session's focus intention.
///
/// Picking a task used to assign `whatToAchieveInFocusBlock` (via `updateFocusModeIntention`) whenever no
/// accountability-buddy session was running. That was a strictness bypass: a super-strict session forbids
/// changing the focus goal, and this path edited it anyway — and it conflated two things the safety
/// endpoints keep apart (`intention` vs `currentTaskInToDoPlayer`), so the AI judged against a goal that
/// no longer matched what the user had stated. Setting a task now routes through the task queue only, in
/// every strictness. `clearAiBlockingDecisionsForNewFocusTarget` still runs so cached allow/deny decisions
/// are re-judged against the new task.
private func aiBlockBuddyAdoptPickedTask(_ picked: DayPlanTask) {
    // Record that the user just chose a task via the check-in, so a check-in re-shown within
    // `kAiBlockBuddyCompactAfterPickSeconds` opens compact instead of the full picker.
    lastAiBlockBuddyTaskPickAt = Date()
    clearAiBlockingDecisionsForNewFocusTarget()
    aiBlockBuddySetCurrentFocusTask(title: picked.title, id: picked.sourceTaskId ?? picked.id,
                                    durationSeconds: max(60, picked.durationMinutes * 60))
}

/// Set what the user is working on right now, from the check-in's picker. Routes through the task queue
/// and **never** writes `whatToAchieveInFocusBlock` — the session goal is the user's, and a super-strict
/// session forbids changing it. (PR #2433 adds a shared `setCurrentFocusTask` in `focusModeData.swift`;
/// once that lands on this branch this should call it instead of duplicating the queue hop.)
func aiBlockBuddySetCurrentFocusTask(title: String, id: String, durationSeconds: Int) {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    addLog(text: "aiBlockBuddySetCurrentFocusTask: \(trimmed)")
    taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: trimmed, id: id,
                                                 duration: durationSeconds,
                                                 shouldCompleteCurrentTask: false)
}

/// The session's stated goal at request time. Read live (not captured at present-time) so a goal edited
/// elsewhere during the check-in is the one the AI judges against. (PR #2433's `currentFocusIntention()`
/// is the same read; swap to it once that lands here.)
func currentFocusIntentionForRequest() -> String {
    whatToAchieveInFocusBlock.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// What the check-in shows as the CURRENT TASK: the task the user is actually working on when the session
/// has one, otherwise the stated focus goal (a session can run with a goal and no task). Pure so the
/// fallback is unit-testable.
func aiBlockBuddyCurrentTaskLabel(activeTaskTitle: String?, focusIntention: String) -> String {
    let task = activeTaskTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return task.isEmpty ? focusIntention.trimmingCharacters(in: .whitespacesAndNewlines) : task
}

/// Mark a top-3 Day Plan task complete (or not) straight from the check-in, mirroring the Day Plan's own
/// "Done" checkbox (`toggleDone`): set `done`, persist via `DayPlanTaskStore.update` (which reflects the
/// flip onto the backing to-do's status through `DayPlanSync` so web/mobile update), and fire the same
/// completion analytics. The buddy stays open — the user can then pick another task, argue, or block.
private func aiBlockBuddySetTopTaskDone(_ task: DayPlanTask, done: Bool) {
    var updated = task
    updated.done = done
    DayPlanAnalytics.capture(done ? DayPlanAnalytics.taskCompleted : DayPlanAnalytics.taskUncompleted,
                             ["from_todo": task.sourceTaskId != nil])
    DayPlanTaskStore.shared.update(updated, for: Date())
    allApiObject.capturePosthog(event: done ? "ai-block-buddy-completed-top-task" : "ai-block-buddy-uncompleted-top-task", metadata: [:])
}

/// Set the active task from a name the user typed or picked in the "update your current task" field: adopt
/// the existing Day Plan task with that title, or (no match) create a brand-new task, add it to today's
/// Day Plan, and adopt it. Adopting resets the AI decisions (`clearAiBlockingDecisionsForNewFocusTarget`)
/// so the caught item is re-judged against the new task — the session goal is untouched — then
/// the prompt dismisses and refocuses for that re-check — the site may now fit, or a fresh check-in shows.
private func aiBlockBuddyUpdateCurrentTask(_ name: String, context: AiBlockContext) {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let today = Date()
    let existing = DayPlanTaskStore.shared.tasks(for: today)
        .first { $0.title.caseInsensitiveCompare(trimmed) == .orderedSame }
    let task: DayPlanTask
    if let existing = existing {
        task = existing
    } else {
        task = DayPlanTask(title: trimmed)
        DayPlanTaskStore.shared.add(task, for: today)
    }
    allApiObject.capturePosthog(event: "ai-block-buddy-updated-current-task",
                                metadata: ["was_new": existing == nil ? "true" : "false"])
    aiBlockBuddyAdoptPickedTask(task)
    aiBlockBuddyRecheckAgainstCurrentIntention(context)
}
