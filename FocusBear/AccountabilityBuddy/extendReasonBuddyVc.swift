//
//  extendReasonBuddyVc.swift
//  Focus Bear
//
//  The AI accountability buddy's question when a focus session is extended: "why do you need more
//  time?". Asked before the extra minutes are granted, and only while AI relevance checking is
//  governing the session (see `FocusSessionExtension.shouldAskWhyMoreTimeIsNeeded()`).
//
//  The answer does two things. It becomes the session's focus intention for the extra time, so the
//  AI relevance checks judge every app and site against it. And it is now judged itself: the buddy
//  asks the server (`/user/task-intention-check`) whether the stated reason belongs to the session
//  that is running. Reported by the product owner, who typed "play games" here and was handed the
//  extra ten minutes: "this screen doesn't seem to be connected to the LLM."
//
//  It ASKS; it does not forbid. A clear conflict is shown back to the user, who can rewrite the
//  answer or extend deliberately. The classifier is lenient and fails open, and hard-blocking on its
//  false positive would strand someone with a genuine deadline — a worse bug than letting "play
//  games" through once. Every unreachable-server path extends: the user is often offline.
//
//  The app has global AppKit types named `State` and `Button`, so SwiftUI's must be qualified
//  (`SwiftUI.State`, `SwiftUI.Button`).
//

import Cocoa
import SwiftUI

/// Placeholder the config strings use for the number of minutes being added.
private let kMinutesPlaceholder = "{0}"

/// Config block every accountability-buddy screen reads its strings from.
private let kBuddyConfigBlock = "accountabilityBuddyInfo"

/// User-facing strings for the buddy's extend question, read from the `accountabilityBuddyInfo`
/// config block (the same block the sibling buddy screens use) so they stay translatable.
struct ExtendReasonBuddyStrings {
    var title = ""
    var subtitle = ""
    var placeholder = ""
    var help = ""
    var buttonContinue = ""
    var buttonSkip = ""
    var checking = ""
    var mismatchTitle = ""
    var mismatchFallback = ""
    var buttonRevise = ""
    var buttonExtendAnyway = ""

    /// Downloaded configs lag the app: one fetched before these keys shipped carries none of them,
    /// and the bundled de/fr/pl configs have never carried this screen's keys at all. So each string
    /// falls back downloaded → bundled-for-this-language → bundled English, and an untranslated
    /// button reads in English instead of rendering blank.
    static func load(minutes: Int) -> ExtendReasonBuddyStrings {
        let downloaded = configjson.value(forKey: kBuddyConfigBlock) as? NSDictionary
        let localised = bundledBuddyBlock(named: BundledConfigLanguage.current())
        let english = bundledBuddyBlock(named: BundledConfigLanguage.resource(BundledConfigLanguage.english))

        func string(_ key: String) -> String {
            for candidate in [downloaded?[key] as? String, localised[key], english[key]] {
                if let value = candidate, !value.isEmpty { return value }
            }
            return ""
        }

        var strings = ExtendReasonBuddyStrings()
        strings.title = string("titleExtendReason")
        strings.subtitle = string("subTitleExtendReason")
            .replacingOccurrences(of: kMinutesPlaceholder, with: "\(minutes)")
        strings.placeholder = string("placeHolderExtendReason")
        strings.help = string("helpExtendReason")
        strings.buttonContinue = string("buttonExtendReasonContinue")
        strings.buttonSkip = string("buttonExtendReasonSkip")
        strings.checking = string("checkingExtendReason")
        strings.mismatchTitle = string("titleExtendReasonMismatch")
        strings.mismatchFallback = string("fallbackExtendReasonMismatch")
        strings.buttonRevise = string("buttonExtendReasonRevise")
        strings.buttonExtendAnyway = string("buttonExtendReasonAnyway")
        return strings
    }

    private static func bundledBuddyBlock(named fileName: String) -> [String: String] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return json[kBuddyConfigBlock] as? [String: String] ?? [:]
    }
}

/// Which step of the question the sheet is on.
enum ExtendReasonPhase: Equatable {
    /// Writing the answer.
    case editing
    /// The buddy is judging the answer. The sheet waits; the window stays live.
    case checking
    /// The buddy said the answer doesn't match this session, and `reason` says why.
    case pushingBack(reason: String)
}

/// State + callbacks for the SwiftUI sheet. Owned by the presenter below.
final class ExtendReasonBuddyViewModel: ObservableObject {
    @Published var strings = ExtendReasonBuddyStrings()
    @Published var phase: ExtendReasonPhase = .editing
    @Published var reason = ""
    var onSubmit: () -> Void = {}
    var onSkip: () -> Void = {}
    var onRevise: () -> Void = {}
    var onExtendAnyway: () -> Void = {}

    var canSubmit: Bool {
        !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// App-font bridges, matching the other SwiftUI screens (honours the user's selected font).
private func buddyBoldFont(_ size: CGFloat) -> Font { Font(getBoldFont(size: size)) }
private func buddyRegularFont(_ size: CGFloat) -> Font { Font(getRegularFont(size: size)) }
private func buddySemiBoldFont(_ size: CGFloat) -> Font { Font(getSemiBoldFont(size: size)) }

struct ExtendReasonBuddyView: View {
    @ObservedObject var model: ExtendReasonBuddyViewModel

    private var isEditable: Bool { model.phase == .editing }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.strings.title)
                .font(buddyBoldFont(16))
                .fixedSize(horizontal: false, vertical: true)

            Text(model.strings.subtitle)
                .font(buddyRegularFont(12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            answerEditor
            footnote
            controls
        }
        .padding(20)
        .frame(width: 420)
    }

    // ZStack rather than `.overlay(alignment:)`: the app deploys to macOS 11, where the
    // alignment-taking overlay does not exist.
    private var answerEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $model.reason)
                .font(buddyRegularFont(13))
                .frame(height: 84)
                .disabled(!isEditable)
                .opacity(isEditable ? 1 : 0.6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                )
            if model.reason.isEmpty {
                Text(model.strings.placeholder)
                    .font(buddyRegularFont(13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
        }
    }

    /// The promise under the box while the answer is being written, replaced by the buddy's
    /// push-back once it has one.
    @ViewBuilder
    private var footnote: some View {
        if case .pushingBack(let reason) = model.phase {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.strings.mismatchTitle)
                    .font(buddySemiBoldFont(12))
                Text(reason)
                    .font(buddyRegularFont(12))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.12)))
        } else {
            Text(model.strings.help)
                .font(buddyRegularFont(11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch model.phase {
        case .editing:
            HStack {
                SwiftUI.Button(model.strings.buttonSkip) { model.onSkip() }
                    .font(buddyRegularFont(13))
                Spacer()
                SwiftUI.Button(model.strings.buttonContinue) { model.onSubmit() }
                    .font(buddySemiBoldFont(13))
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.canSubmit)
            }
        case .checking:
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
                Text(model.strings.checking)
                    .font(buddyRegularFont(12))
                    .foregroundColor(.secondary)
                Spacer()
            }
        case .pushingBack:
            // Neither button takes the default action, on purpose: the user got here by pressing
            // Return on "Extend my session", and a default button would let that same keystroke blow
            // straight through the push-back. Extending anyway has to be a separate, deliberate click.
            HStack {
                SwiftUI.Button(model.strings.buttonRevise) { model.onRevise() }
                    .font(buddySemiBoldFont(13))
                Spacer()
                SwiftUI.Button(model.strings.buttonExtendAnyway) { model.onExtendAnyway() }
                    .font(buddyRegularFont(13))
            }
        }
    }
}

/// Presents the buddy's question as a sheet and reports the answer back. A skipped question reports
/// an empty reason — the extension still goes ahead (see `FocusSessionExtension`).
enum ExtendReasonBuddy {

    /// - Parameters:
    ///   - intention: the running session's focus intention, which the stated reason is judged
    ///     against. Empty means there is nothing to judge, and the answer is taken as written.
    ///   - focusMode: the running block list's name, sent as extra context for the judgement.
    ///   - checker: the alignment check itself, injected so the decision around it can be unit-tested
    ///     without a server.
    /// - Returns: `false` when the question could not be shown (no window to host the sheet), so the
    ///   caller can carry on rather than stall the extension behind a sheet that never appeared.
    @discardableResult
    static func present(minutes: Int,
                        intention: String,
                        focusMode: String?,
                        from presenter: NSViewController,
                        checker: TaskIntentionChecking = allApiObject,
                        completion: @escaping (String) -> Void) -> Bool {
        guard presenter.view.window != nil else { return false }
        let model = ExtendReasonBuddyViewModel()
        model.strings = ExtendReasonBuddyStrings.load(minutes: minutes)

        var hostingController: NSHostingController<ExtendReasonBuddyView>?
        var hasFinished = false
        func finish(with reason: String) {
            guard !hasFinished else { return }
            hasFinished = true
            if let hostingController = hostingController, hostingController.presentingViewController != nil {
                presenter.dismiss(hostingController)
            }
            // Next run-loop turn: the caller may dismiss `presenter` itself (addTaskVc does), and
            // tearing down a presenter while its own sheet is still animating out glitches.
            DispatchQueue.main.async { completion(reason) }
        }

        // `[weak model]` throughout: the model owns these closures, so capturing it strongly would
        // make a cycle and leak the model — and, through `finish`, the presenting view controller.
        model.onSubmit = { [weak model] in
            guard let model = model else { return }
            let reason = model.reason
            model.phase = .checking
            FocusSessionExtension.checkExtensionReason(
                reason,
                intention: intention,
                focusMode: focusMode,
                checker: checker,
                fallbackPushBackMessage: model.strings.mismatchFallback) { [weak model] verdict in
                    guard !hasFinished else { return }   // the sheet went away while the check was in flight
                    switch verdict {
                    case .extendNow:
                        finish(with: reason)
                    case .pushBack(let why):
                        allApiObject.capturePosthog(event: FocusExtensionAnalyticsEvent.buddyPushedBack,
                                                    metadata: [:])
                        model?.phase = .pushingBack(reason: why)
                    }
                }
        }
        model.onSkip = { finish(with: "") }
        model.onRevise = { [weak model] in
            allApiObject.capturePosthog(event: FocusExtensionAnalyticsEvent.buddyRevised, metadata: [:])
            model?.phase = .editing
        }
        model.onExtendAnyway = { [weak model] in
            allApiObject.capturePosthog(event: FocusExtensionAnalyticsEvent.buddyOverridden, metadata: [:])
            finish(with: model?.reason ?? "")
        }

        let controller = NSHostingController(rootView: ExtendReasonBuddyView(model: model))
        hostingController = controller
        // Next run-loop turn: a caller may have just dismissed another sheet on this same presenter
        // (the password prompt does), and presenting while that one is still on screen throws.
        DispatchQueue.main.async { presenter.presentAsSheet(controller) }
        return true
    }
}
