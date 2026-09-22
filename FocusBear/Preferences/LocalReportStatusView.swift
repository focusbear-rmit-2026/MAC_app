import SwiftUI

struct LocalReportStatusStrings {
    static let defaults = [
        "title": "Your local reports", "explanation": "Progress from the reports saved on this Mac.",
        "refresh": "Refresh", "loading": "Loading reports…", "empty": "No local reports for this account yet.",
        "signedOut": "Sign in to see your local reports.", "readFailed": "Couldn't read your local reports. Try refreshing.",
        "untitled": "Report without a description", "queued": "Queued",
        "investigating": "Investigating", "investigatingDetail": "This report is being investigated.",
        "readyForQA": "Ready for your review",
        "needsClarification": "Blocked or needs input", "queuedDetail": "This report is waiting to be investigated.",
        "readyForQADetail": "Work has been prepared for you to check. This does not confirm a released fix.",
        "needsClarificationDetail": "This report is waiting on a decision, more information, or another change.",
        "blockedOnBackend": "Waiting on a backend release",
        "blockedOnBackendDetail": "The Mac side is done, but this cannot be tested until a backend change is merged and deployed.",
        "openNotes": "Read review notes", "showingRecent": "Showing the most recent local reports.",
        "reportedAt": "Reported", "noteSummary": "From review notes", "reportColumn": "Report", "statusColumn": "Status",
        "addInstructions": "Add feedback or instructions", "instructionsPrompt": "What else should we know?",
        "saveInstructions": "Save instructions", "cancel": "Cancel", "instructionsSaved": "Instructions saved to this report.",
        "instructionsFailed": "Couldn't save your instructions. Refresh the reports and try again.",
        "instructionsLimit": "Use up to 4,000 characters.", "yourInstructions": "Your latest instructions",
        "confirmedFixed": "Confirmed fixed", "confirmedFixedDetail": "You confirmed that this issue is fixed.",
        "markConfirmedFixed": "Mark as confirmed fixed", "undoConfirmation": "Undo confirmation",
        "confirmationFailed": "Couldn't update this report's status. Refresh and try again.", "confirmedAt": "Confirmed",
        "showFixedReports": "Show fixed reports", "noOpenReports": "No unconfirmed reports to show.",
        "areaFilterAll": "All areas", "areaFilterLabel": "Part of the app",
        "areaDayPlan": "Day Plan", "areaFocusSession": "Focus session", "areaTasksProjects": "Tasks & projects",
        "areaBlocking": "Blocking", "areaRoutinesBreaks": "Routines & breaks", "areaReportsFeedback": "Reports",
        "areaStats": "Stats", "areaMenuBar": "Menu bar", "areaOther": "Other",
        "reworkNeeded": "Rework needed",
        "reworkNeededDetail": "You added feedback after the last review, so this is back with us.",
        "groupCount": "<COUNT>",
        "notesReadFailed": "Couldn't read these notes. Refresh the reports and try again.", "close": "Close",
        "screenshots": "Screenshots", "screenshotOpenFailed": "Couldn't open that screenshot. Refresh the reports and try again.",
        "searchPlaceholder": "Search reports", "noSearchMatches": "No reports match your search.",
        "pasteImage": "Paste image", "pasteImageHint": "Copy a screenshot, then paste it here.",
        "openInPreview": "Open in Preview",
        "pasteImageFailed": "Couldn't attach that image. Copy it again and retry.",
        "noteOriginal": "Original note", "noteUpdate": "Update",
        "noteUpdateHeading": "Update <NUMBER> of <COUNT>", "noteUpdateCount": "<COUNT> updates",
        "noteLatest": "Latest", "noteNewestFirst": "Newest update first.",
        "latestUpdate": "Latest update", "lastAIUpdate": "Last update from AI"
    ]
    let values: [String: String]
    init() {
        var values = Self.defaults
        let resource = BundledConfigLanguage.current()
        if let url = Bundle.main.url(forResource: resource, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let bundled = config["localReportStatus"] as? [String: String] { values.merge(bundled) { _, new in new } }
        if let remote = configjson["localReportStatus"] as? [String: String] { values.merge(remote) { _, new in new } }
        self.values = values
    }
    subscript(_ key: String) -> String { values[key] ?? Self.defaults[key] ?? "" }
}

/// A spinner small enough to sit inline beside a 12pt link without changing the row's height.
enum LocalReportSpinner {
    static let scale: CGFloat = 0.5
    static let side: CGFloat = 12
}

struct LocalReportStatusView: View {
    @StateObject private var store = LocalReportStatusStore()
    @SwiftUI.State private var editingReport: LocalReportStatus?
    @SwiftUI.State private var instructions = ""
    @SwiftUI.State private var saveError = false
    @SwiftUI.State private var savedReportID: String?
    @SwiftUI.State private var confirmationErrorID: String?
    @SwiftUI.State private var screenshotErrorID: String?
    @SwiftUI.State private var notesErrorID: String?
    @SwiftUI.State private var readingNotesText: String?
    /// The original diagnosis starts collapsed whenever there are updates under it, so the newest
    /// update is the first thing the reader sees (report 2026-09-15_22-26-04).
    @SwiftUI.State private var originalNoteExpanded = true
    @SwiftUI.State private var searchQuery = ""
    @SwiftUI.State private var pasteError = false
    @SwiftUI.State private var lightbox: LocalReportLightboxImage?
    @SwiftUI.State private var expandedGroups: [String: Bool] = [:]
    @SwiftUI.State private var areaFilter: LocalReportArea?
    let refreshToken: Int
    private let strings = LocalReportStatusStrings()
    // Account changes do not have a shared notification in the legacy Help host. This timer only
    // compares identity; the AppKit lifecycle helper separately refreshes visible reports every 15s.
    private let accountTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if LocalReportCapability.isEnabled(for: store.loadedAccount) { reportTable }
        }
        .onAppear { store.refresh() }
        .background(LocalReportStatusRefreshHost { store.refreshIfIdle() }.frame(width: 0, height: 0))
        .onChange(of: refreshToken) { _ in store.refresh() }
        .onChange(of: store.loadedAccount) { _ in
            editingReport = nil; instructions = ""; saveError = false; savedReportID = nil
            confirmationErrorID = nil; notesErrorID = nil; readingNotesText = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in store.refreshIfIdle() }
        .onReceive(accountTimer) { _ in store.checkAccount() }
        // Keep the draft independent of the refreshed table. A reviewer may move the folder while
        // this sheet is open; a rejected stale write must leave the text and Cancel accessible.
        .sheet(item: $editingReport) { report in
            Group {
                if let text = readingNotesText { notesReader(report, text: text) }
                else { instructionsEditor(report) }
            }.padding(20).frame(width: 520)
        }
    }

    private var reportTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().padding(.vertical, 6)
            HStack {
                Text(strings["title"]).font(.headline)
                Spacer(minLength: 8)
                SwiftUI.Button(strings["refresh"]) { store.refresh() }
                    .disabled(store.isLoading)
            }
            Text(strings["explanation"]).font(.subheadline).foregroundColor(.secondary)
            TextField(strings["searchPlaceholder"], text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            areaFilterRow
            if store.loadedAccount.isEmpty {
                statusText("signedOut")
            } else if store.failed {
                statusText("readFailed")
            } else if store.isLoading && store.reports.isEmpty {
                statusText("loading")
            } else if store.reports.isEmpty {
                statusText(store.showConfirmedFixed ? "empty" : "noOpenReports")
            } else if visibleReports.isEmpty {
                statusText("noSearchMatches")
            } else {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(LocalReportGrouping.groups(visibleReports), id: \.state) { group in
                        statusGroup(group.state, reports: group.reports)
                    }
                }
            }
            if store.isLimited { statusText("showingRecent") }
        }
    }

    /// One status accordion. Searching opens every group that still has matches — a collapsed group
    /// would otherwise hide the thing being searched for.
    @ViewBuilder
    private func statusGroup(_ state: LocalReportReviewState, reports: [LocalReportStatus]) -> some View {
        let key = state.rawValue
        let isSearching = !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let binding = Binding<Bool>(
            get: {
                if isSearching { return true }
                return expandedGroups[key] ?? LocalReportGrouping.expandedByDefault.contains(state)
            },
            set: { expandedGroups[key] = $0 })
        DisclosureGroup(isExpanded: binding) {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(reports) { report in reportRow(report) }
            }
            .padding(.top, 6)
        } label: {
            HStack(spacing: 6) {
                Text(strings[key]).font(.system(size: 12, weight: .semibold))
                Text(verbatim: "(\(reports.count))").font(.system(size: 12)).foregroundColor(.secondary)
            }
            .disclosureLabelTap(binding)
        }
    }

    /// Narrow the whole list to one part of the app. With a queue this size, "ready for review" is
    /// only useful if you can pick the reports you are able to test right now
    /// (report 2026-09-14_22-14-16). Only areas actually present are offered.
    @ViewBuilder
    private var areaFilterRow: some View {
        let areas = LocalReportArea.present(in: store.reports)
        if areas.count > 1 {
            HStack(spacing: 6) {
                Text(strings["areaFilterLabel"]).font(.system(size: 11)).foregroundColor(.secondary)
                Picker("", selection: $areaFilter) {
                    Text(strings["areaFilterAll"]).tag(LocalReportArea?.none)
                    ForEach(areas, id: \.self) { area in
                        Text(strings[areaStringKey(area)]).tag(LocalReportArea?.some(area))
                    }
                }
                .labelsHidden().pickerStyle(MenuPickerStyle()).frame(maxWidth: 200)
            }
        }
    }

    private func areaStringKey(_ area: LocalReportArea) -> String {
        "area" + area.rawValue.prefix(1).uppercased() + area.rawValue.dropFirst()
    }

    /// The rows the search box leaves standing. "Showing the most recent…" still describes the
    /// store's own cap, which applies before any filtering.
    private var visibleReports: [LocalReportStatus] {
        LocalReportSearch.matching(LocalReportArea.matching(store.reports, area: areaFilter), query: searchQuery)
    }

    private func statusText(_ key: String) -> some View {
        selectable(Text(strings[key]).font(.system(size: 12)).foregroundColor(.secondary))
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Report text is the one thing in this list a human wants to paste elsewhere — a title into a
    /// commit message, a note into a chat. `textSelection` is macOS 12+, and the app still targets
    /// macOS 11, so older systems simply keep the existing read-only behaviour.
    @ViewBuilder
    private func selectable<V: View>(_ view: V) -> some View {
        if #available(macOS 12.0, *) { view.textSelection(.enabled) } else { view }
    }

    /// How long ago the review notes were last written, and exactly when.
    ///
    /// Without it every row looks equally fresh, and a report answered four minutes ago reads the
    /// same as one untouched for a week (report 2026-09-17_06-23-46). The string is built while the
    /// list renders — which happens when a refresh lands, roughly every 15 seconds — so there is no
    /// per-row timer and no re-render of its own. A relative string a few seconds stale is exactly
    /// what "2h ago" already means.
    @ViewBuilder
    private func lastAIUpdateLabel(_ report: LocalReportStatus) -> some View {
        if let age = LocalReportUpdateAgeFormatter.shared.describe(report.lastAIUpdate, now: Date()) {
            Text(strings["lastAIUpdate"]).font(.system(size: 11)).foregroundColor(.secondary)
            selectable(Text(verbatim: age.combined).font(.system(size: 11)).foregroundColor(.secondary))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func reportRow(_ report: LocalReportStatus) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    selectable(Text(verbatim: report.title.isEmpty ? strings["untitled"] : report.title)
                        .font(.system(size: 13, weight: .semibold)).fixedSize(horizontal: false, vertical: true))
                    Text(strings["reportedAt"]).font(.system(size: 11)).foregroundColor(.secondary)
                    selectable((Text(report.createdAt, style: .date) + Text(" ") + Text(report.createdAt, style: .time))
                        .font(.system(size: 11)).foregroundColor(.secondary))
                    lastAIUpdateLabel(report)
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 6) {
                    Text(strings[report.state.rawValue]).font(.system(size: 12, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    statusText(report.state.rawValue + "Detail")
                    if report.state == .confirmedFixed, let date = report.userStatus?.updatedDate {
                        (Text(strings["confirmedAt"]) + Text(" ") + Text(date, style: .date))
                            .font(.system(size: 11)).foregroundColor(.secondary)
                    }
                    SwiftUI.Button {
                        confirmationErrorID = nil
                        store.setConfirmedFixed(report.state != .confirmedFixed, for: report) { error in
                            if error != nil { confirmationErrorID = report.id }
                        }
                    } label: {
                        // The write goes through a serial queue and can take a moment. Disabling the
                        // link alone looked like a dead control, so the wait is shown rather than
                        // merely enforced (report 2026-09-15_20-52-29).
                        HStack(spacing: 5) {
                            Text(strings[report.state == .confirmedFixed ? "undoConfirmation" : "markConfirmedFixed"])
                                .fixedSize(horizontal: false, vertical: true)
                            if store.pendingConfirmations.contains(report.id) {
                                ProgressView()
                                    .scaleEffect(LocalReportSpinner.scale)
                                    .frame(width: LocalReportSpinner.side, height: LocalReportSpinner.side)
                            }
                        }
                    }.buttonStyle(.link).font(.system(size: 12))
                        // Only this row waits on its own write; a rescan no longer disables every row.
                        .disabled(store.pendingConfirmations.contains(report.id) || editingReport != nil)
                    if confirmationErrorID == report.id { statusText("confirmationFailed") }
                }.frame(width: 180, alignment: .leading)
            }
            if let excerpt = report.notesExcerpt, !excerpt.isEmpty {
                noteExcerptLabel(report)
                selectable(Text(verbatim: excerpt).font(.system(size: 12)).fixedSize(horizontal: false, vertical: true))
            }
            if !report.screenshotURLs.isEmpty {
                Text(strings["screenshots"]).font(.system(size: 11)).foregroundColor(.secondary)
                HStack(spacing: 8) {
                    ForEach(report.screenshotURLs, id: \.self) { url in
                        SwiftUI.Button {
                            // Show it here rather than handing it to Preview: a screenshot opened in
                            // another app went behind the window and read as the click doing nothing
                            // (report 2026-09-13_21-19-23, follow-up "it doesn't do anything if I click
                            // the screenshot. It should open in a lightbox").
                            guard store.mayOpenScreenshot(url, for: report) else {
                                screenshotErrorID = report.id
                                return
                            }
                            screenshotErrorID = nil
                            lightbox = LocalReportLightboxImage(url: url, report: report)
                        } label: {
                            LocalReportThumbnail(url: url)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(url.lastPathComponent)
                    }
                }
                .sheet(item: $lightbox) { shot in
                    LocalReportLightbox(image: shot, strings: strings,
                                        openExternally: { store.openScreenshot(shot.url, for: shot.report) },
                                        close: { lightbox = nil })
                }
                if screenshotErrorID == report.id { statusText("screenshotOpenFailed") }
            }
            if report.notesURL != nil {
                SwiftUI.Button(strings["openNotes"]) {
                    guard let text = store.readNotes(for: report) else { notesErrorID = report.id; return }
                    notesErrorID = nil; readingNotesText = text; editingReport = report
                    originalNoteExpanded = LocalReportNoteParser.parse(text).updates.isEmpty
                }.buttonStyle(.link).font(.system(size: 12)).disabled(editingReport != nil)
                if notesErrorID == report.id { statusText("notesReadFailed") }
            }
            if let latest = report.latestInstructions {
                Text(strings["yourInstructions"]).font(.system(size: 11)).foregroundColor(.secondary)
                Text(verbatim: latest).font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
            }
            if savedReportID == report.id { statusText("instructionsSaved") }
            SwiftUI.Button(strings["addInstructions"]) {
                instructions = ""; saveError = false; savedReportID = nil; readingNotesText = nil; editingReport = report
            }.buttonStyle(.link).font(.system(size: 12)).disabled(editingReport != nil)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.07)))
    }

    private func instructionsEditor(_ report: LocalReportStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings["addInstructions"]).font(.headline)
            Text(verbatim: report.title.isEmpty ? strings["untitled"] : report.title)
                .font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
            Text(strings["instructionsPrompt"]).font(.system(size: 12))
            TextEditor(text: $instructions).font(.system(size: 13)).frame(height: 110)
                .padding(4).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
                .accessibilityLabel(strings["instructionsPrompt"])
            HStack(spacing: 8) {
                SwiftUI.Button(strings["pasteImage"]) { attachPastedImage(to: report) }
                statusText("pasteImageHint")
            }
            statusText("instructionsLimit")
            if saveError { statusText("instructionsFailed") }
            if pasteError { statusText("pasteImageFailed") }
            HStack {
                SwiftUI.Button(strings["saveInstructions"]) {
                    do {
                        try store.addInstructions(instructions, to: report)
                        instructions = ""; editingReport = nil; savedReportID = report.id; saveError = false
                    } catch { saveError = true }
                }.disabled(instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || instructions.count > LocalReportInstructionWriter.maximumCharacters)
                SwiftUI.Button(strings["cancel"]) {
                    editingReport = nil; instructions = ""; saveError = false; pasteError = false
                }
            }
        }
    }

    /// Put whatever image is on the clipboard into this report's screenshots folder and name it in the
    /// text, so instructions can carry a picture rather than a description of one.
    private func attachPastedImage(to report: LocalReportStatus) {
        guard let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self])?.first as? NSImage else {
            pasteError = true
            return
        }
        do {
            let reference = try store.attachPastedImage(image, to: report)
            let separator = instructions.isEmpty || instructions.hasSuffix("\n") ? "" : "\n"
            instructions += separator + reference + "\n"
            pasteError = false
        } catch { pasteError = true }
    }

    /// Review notes as the separate notes they were written as: the original diagnosis, then each
    /// `## Update` as its own card, newest first. Shown as one block of text, a later update was
    /// indistinguishable from the middle of the first one ("subsequent updates should appear as
    /// separate notes below. It's very hard for me to find the updates currently",
    /// report 2026-09-15_22-26-04).
    private func notesReader(_ report: LocalReportStatus, text: String) -> some View {
        let notes = LocalReportNoteParser.parse(text)
        return VStack(alignment: .leading, spacing: 12) {
            Text(strings["openNotes"]).font(.headline)
            Text(verbatim: report.title.isEmpty ? strings["untitled"] : report.title)
                .font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
            if !notes.updates.isEmpty { statusText("noteNewestFirst") }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    originalNote(notes)
                    ForEach(notes.newestFirst) { update in
                        noteCard(heading: updateHeading(update, of: notes.updates.count), date: update.date,
                                 isLatest: update.number == notes.updates.count,
                                 subtitle: update.summary, body: update.body)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.frame(height: 380)
            SwiftUI.Button(strings["close"]) { editingReport = nil; readingNotesText = nil }
        }
    }

    /// The first diagnosis. It stays collapsed while there are updates under it — it is the part the
    /// reader has already read — and opens with one click.
    @ViewBuilder
    private func originalNote(_ notes: LocalReportNotes) -> some View {
        if notes.original.isEmpty {
            EmptyView()
        } else if notes.updates.isEmpty {
            noteCard(heading: strings["noteOriginal"], date: nil, isLatest: false,
                     subtitle: notes.title, body: notes.original)
        } else {
            DisclosureGroup(isExpanded: $originalNoteExpanded) {
                selectable(Text(verbatim: notes.original).font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
            } label: {
                HStack(spacing: 6) {
                    Text(strings["noteOriginal"]).font(.system(size: 12, weight: .semibold))
                    if !notes.title.isEmpty {
                        Text(verbatim: notes.title).font(.system(size: 11)).foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }.disclosureLabelTap($originalNoteExpanded)
            }
            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.07)))
        }
    }

    private func noteCard(heading: String, date: Date?, isLatest: Bool, subtitle: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(verbatim: heading).font(.system(size: 12, weight: .semibold))
                if let date = date {
                    Text(date, style: .date).font(.system(size: 11)).foregroundColor(.secondary)
                }
                if isLatest {
                    Text(strings["noteLatest"]).font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.18)))
                }
                Spacer(minLength: 0)
            }
            if !subtitle.isEmpty {
                selectable(Text(verbatim: subtitle).font(.system(size: 12, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true))
            }
            selectable(Text(verbatim: body).font(.system(size: 13))
                .fixedSize(horizontal: false, vertical: true))
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.07)))
    }

    /// "Update 3 of 3", or plain "Update" when the notes carry only one.
    private func updateHeading(_ update: LocalReportNoteUpdate, of count: Int) -> String {
        guard count > 1 else { return strings["noteUpdate"] }
        return strings["noteUpdateHeading"]
            .replacingOccurrences(of: "<NUMBER>", with: String(update.number))
            .replacingOccurrences(of: "<COUNT>", with: String(count))
    }

    /// Says where a row's summary came from. When the notes have updates it is the newest one, and
    /// the row says so — the old label read "From review notes" while showing the oldest note text.
    @ViewBuilder
    private func noteExcerptLabel(_ report: LocalReportStatus) -> some View {
        if let update = report.latestUpdate {
            HStack(spacing: 6) {
                Text(strings["latestUpdate"])
                if update.number > 1 {
                    Text(verbatim: strings["noteUpdateCount"].replacingOccurrences(of: "<COUNT>",
                                                                                   with: String(update.number)))
                }
                if let date = update.date { Text(date, style: .date) }
            }.font(.system(size: 11)).foregroundColor(.secondary)
        } else {
            Text(strings["noteSummary"]).font(.system(size: 11)).foregroundColor(.secondary)
        }
    }
}

/// Help uses an AppKit tab host, so SwiftUI's onDisappear alone does not reliably observe a hidden
/// ancestor. Keep one timer while attached and unhidden; never scan a hidden/minimized window.
private struct LocalReportStatusRefreshHost: NSViewRepresentable {
    let onRefresh: () -> Void
    func makeNSView(context: Context) -> LocalReportStatusRefreshView {
        let view = LocalReportStatusRefreshView()
        view.onRefresh = onRefresh
        return view
    }
    func updateNSView(_ view: LocalReportStatusRefreshView, context: Context) { view.onRefresh = onRefresh }
    static func dismantleNSView(_ view: LocalReportStatusRefreshView, coordinator: ()) { view.stop() }
}

private final class LocalReportStatusRefreshView: NSView {
    var onRefresh: (() -> Void)?
    private var timer: Timer?
    override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); updateTimer() }
    override func viewDidHide() { super.viewDidHide(); stop() }
    override func viewDidUnhide() { super.viewDidUnhide(); updateTimer() }
    private func updateTimer() {
        stop()
        guard window != nil, !isHiddenOrHasHiddenAncestor else { return }
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            guard let self = self, let window = self.window, window.isVisible, !window.isMiniaturized,
                  !self.isHiddenOrHasHiddenAncestor else { return }
            self.onRefresh?()
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    func stop() { timer?.invalidate(); timer = nil }
    deinit { timer?.invalidate() }
}

/// A small preview of one of a report's screenshots. Loaded on appear and downscaled immediately —
/// a report list can hold a hundred rows, and full-size screen captures would be tens of megabytes
/// of pixels for pictures shown at 96 points wide.
/// One screenshot shown full size, so a click stays inside the window.
struct LocalReportLightboxImage: Identifiable {
    let url: URL
    let report: LocalReportStatus
    var id: String { url.path }
}

private struct LocalReportLightbox: View {
    let image: LocalReportLightboxImage
    let strings: LocalReportStatusStrings
    let openExternally: () -> Bool
    let close: () -> Void

    /// The screen this is opening on; the size comes from there rather than a fixed box, so the
    /// screenshot is as large as the display allows ("screenshot is too small in the lightbox. Make
    /// it larger", report 2026-09-13_21-19-23 follow-up).
    private var available: CGSize {
        NSScreen.main?.visibleFrame.size
            ?? CGSize(width: ImagePreviewSizing.minimumSide, height: ImagePreviewSizing.minimumSide)
    }

    private static let padding: CGFloat = 16
    private static let spacing: CGFloat = 10
    private static let captionHeight: CGFloat = 16
    private static let buttonRowHeight: CGFloat = 26
    /// Everything that is not the picture. The same trap as the attachment preview: fit the image to
    /// the WHOLE box and the caption and buttons are pushed off the sheet's edges.
    private static var chromeHeight: CGFloat {
        padding * 2 + captionHeight + buttonRowHeight + spacing * 2
    }
    private var pictureBox: CGSize {
        ImagePreviewSizing.documentBox(available: available, chromeHeight: Self.chromeHeight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: image.url.lastPathComponent).font(.system(size: 12)).foregroundColor(.secondary)
            if let picture = NSImage(contentsOf: image.url) {
                // Sized from the picture's real pixel resolution, not its DPI-scaled point size — a
                // Retina capture reports half its pixels that way, which halved the preview again.
                let size = ImagePreviewSizing.fit(image: picture.naturalPixelSize, within: pictureBox)
                Image(nsImage: picture)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .accessibilityLabel(Text(image.url.lastPathComponent))
            } else {
                Text(strings["screenshotOpenFailed"]).font(.system(size: 12)).foregroundColor(.secondary)
            }
            HStack {
                SwiftUI.Button(strings["openInPreview"]) { _ = openExternally() }
                Spacer()
                SwiftUI.Button(strings["close"], action: close).keyboardShortcut(.cancelAction)
            }
        }
        .padding(16)
    }
}

private struct LocalReportThumbnail: View {
    let url: URL
    @SwiftUI.State private var image: NSImage?
    private static let width: CGFloat = 96
    private static let height: CGFloat = 60

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "photo").foregroundColor(.secondary)
            }
        }
        .frame(width: Self.width, height: Self.height)
        .clipped()
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.25)))
        .cornerRadius(4)
        .onAppear(perform: load)
    }

    private func load() {
        guard image == nil else { return }
        let target = NSSize(width: Self.width * 2, height: Self.height * 2)   // Retina
        DispatchQueue.global(qos: .userInitiated).async {
            guard let full = NSImage(contentsOf: url) else { return }
            let thumbnail = NSImage(size: target)
            thumbnail.lockFocus()
            full.draw(in: NSRect(origin: .zero, size: target),
                      from: .zero, operation: .copy, fraction: 1)
            thumbnail.unlockFocus()
            DispatchQueue.main.async { self.image = thumbnail }
        }
    }
}


extension View {
    /// A `DisclosureGroup` toggles on its caret only — the label is inert, so clicking the words
    /// "Rework needed (2)" does nothing and the caret becomes a small target you have to aim at
    /// (report 2026-09-16_08-45-58). This makes the whole label a toggle, which is what every other
    /// disclosure control on the platform does.
    ///
    /// `contentShape` matters as much as the gesture: without it only the glyphs are hittable, so
    /// the gaps between words would still swallow clicks.
    func disclosureLabelTap(_ isExpanded: Binding<Bool>) -> some View {
        contentShape(Rectangle())
            .onTapGesture { isExpanded.wrappedValue.toggle() }
            .pointingHandCursor()
    }
}
