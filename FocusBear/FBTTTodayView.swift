//
//  FBTTTodayView.swift
//  Focus Bear
//
//  Read-only "Today" view for Focus Bear Time Tracker (FBTT), shown in-place on
//  the existing left-menu "Time Tracker" item once FBTT is installed and has
//  tracked data. It reads FBTT's own SQLite store directly (Focus Bear is not
//  sandboxed, so it can read another app's Application Support container) and
//  renders today's totals in SwiftUI. It never writes — to edit categories /
//  assign projects you open FBTT itself.
//
//  Pieces (kept in one file for the spike):
//    • FBTTReader            — read-only sqlite3 access to FBTT's records.sqlite
//    • TodayTrackerViewModel — ObservableObject the AppKit VC updates
//    • FBTTTodayView         — the SwiftUI view (styling mirrors BreakWarningView)
//    • TodayTrackerVc        — NSViewController hosting the SwiftUI view
//

import Cocoa
import SwiftUI
import SQLite3

// sqlite3_bind_text needs SQLITE_TRANSIENT so it copies the bound string.
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - Models

/// One row in a breakdown list (a project or an app), with its share of time.
struct FBTTSlice: Identifiable {
    let id = UUID()
    let label: String
    let seconds: Int
    let color: Color?
}

/// Today's tracked totals, as read from FBTT's database.
struct FBTTTodaySummary {
    let totalSeconds: Int
    let projects: [FBTTSlice]
    let apps: [FBTTSlice]

    var isEmpty: Bool { totalSeconds == 0 && projects.isEmpty && apps.isEmpty }
}

// MARK: - Reader

/// Read-only access to Focus Bear Time Tracker's SQLite store. Every call opens
/// its own short-lived connection, so it is safe to call from a background queue.
enum FBTTReader {

    static let appPath = "/Applications/Focus Bear Time Tracker.app"

    /// `~/Library/Application Support/com.focusbear.screentime/records.sqlite`
    static var databaseURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.focusbear.screentime/records.sqlite")
    }

    static var isFBTTInstalled: Bool { FileManager.default.fileExists(atPath: appPath) }
    static var hasData: Bool { FileManager.default.fileExists(atPath: databaseURL.path) }

    /// Reads today's summary, or nil if the DB is missing / unreadable.
    static func todaySummary(for date: Date = Date()) -> FBTTTodaySummary? {
        guard FileManager.default.fileExists(atPath: databaseURL.path) else { return nil }

        var db: OpaquePointer?
        // Open read-only and forbid writes. FBTT runs WAL; same-user read-only
        // access sees committed data (the live -shm exists while FBTT runs).
        guard sqlite3_open_v2(databaseURL.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            sqlite3_close(db)
            return nil
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, 2000)
        exec(db, "PRAGMA query_only = ON;")

        let day = dayString(date)

        // Total = sum of top-level (root) record durations for the day, matching
        // FBTT's "All Activities" total.
        let total = scalarInt(db,
            "SELECT COALESCE(SUM(duration), 0) FROM records WHERE day = ? AND parent_rowid IS NULL",
            day)

        let meta = projectMeta(db)   // tag -> (name, colour)

        var projects: [FBTTSlice] = []
        forEachRow(db,
            """
            SELECT project_tag, SUM(duration) FROM records
            WHERE day = ? AND project_tag IS NOT NULL
            GROUP BY project_tag ORDER BY SUM(duration) DESC
            """, day) { stmt in
            let tag = Int(sqlite3_column_int64(stmt, 0))
            let secs = Int(sqlite3_column_int64(stmt, 1))
            let m = meta[tag]
            projects.append(FBTTSlice(label: m?.name ?? "Project \(tag)", seconds: secs, color: m?.color))
        }

        // Time per native app (a leaf with neither domain nor file_url), mirroring
        // FBTT's stats "by app" lens — independent of project assignment, so an app
        // used inside a project still counts here. Excludes the synthetic empty-
        // bundle "Idle time" rows so the list shows real apps.
        var apps: [FBTTSlice] = []
        forEachRow(db,
            """
            SELECT MIN(app_name), SUM(duration) FROM records
            WHERE day = ? AND bundle_id IS NOT NULL AND bundle_id <> ''
              AND domain IS NULL AND file_url IS NULL
            GROUP BY bundle_id ORDER BY SUM(duration) DESC LIMIT 8
            """, day) { stmt in
            let name = sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? "Unknown"
            let secs = Int(sqlite3_column_int64(stmt, 1))
            apps.append(FBTTSlice(label: name, seconds: secs, color: nil))
        }

        return FBTTTodaySummary(totalSeconds: total, projects: projects, apps: apps)
    }

    // MARK: Query helpers

    /// tag -> (name, colour) for every leaf project. Colours are stored 0…1.
    private static func projectMeta(_ db: OpaquePointer?) -> [Int: (name: String, color: Color?)] {
        var out: [Int: (String, Color?)] = [:]
        forEachRow(db,
            "SELECT tag, name, color_r, color_g, color_b, color_a FROM projects WHERE tag IS NOT NULL",
            nil) { stmt in
            let tag = Int(sqlite3_column_int64(stmt, 0))
            let name = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? "Project \(tag)"
            let r = sqlite3_column_double(stmt, 2)
            let g = sqlite3_column_double(stmt, 3)
            let b = sqlite3_column_double(stmt, 4)
            let a = sqlite3_column_double(stmt, 5)
            let color: Color? = a > 0 ? Color(red: r, green: g, blue: b, opacity: a) : nil
            out[tag] = (name, color)
        }
        return out
    }

    private static func exec(_ db: OpaquePointer?, _ sql: String) {
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    private static func scalarInt(_ db: OpaquePointer?, _ sql: String, _ dayParam: String?) -> Int {
        var value = 0
        forEachRow(db, sql, dayParam) { stmt in value = Int(sqlite3_column_int64(stmt, 0)) }
        return value
    }

    /// Prepares `sql`, optionally binds `dayParam` to ?1, and calls `body` per row.
    private static func forEachRow(_ db: OpaquePointer?, _ sql: String, _ dayParam: String?,
                                   _ body: (OpaquePointer?) -> Void) {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        if let day = dayParam {
            sqlite3_bind_text(stmt, 1, day, -1, SQLITE_TRANSIENT)
        }
        while sqlite3_step(stmt) == SQLITE_ROW { body(stmt) }
    }

    private static func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"   // local time zone, matching FBTT's day key
        return f.string(from: date)
    }
}

// MARK: - View model

/// State for the SwiftUI Today view. Owned and refreshed by TodayTrackerVc.
final class TodayTrackerViewModel: ObservableObject {
    @Published var summary: FBTTTodaySummary?
    @Published var isLoading = true
    @Published var updatedAt = ""
    @Published var hasAccess = true   // trial or subscription; false → upgrade screen
    /// Whether Focus Bear Time Tracker is enabled. Drives the always-on toggle at the top of
    /// the view; the tracker content below is shown only when this is true. Mirrors
    /// `kUserdefaultsScreenTimeEnabled`; the host VC updates it after the enable/disable flow.
    @Published var isTrackingEnabled = (UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool) == true

    var onOpenFBTT: () -> Void = {}
    var onRefresh: () -> Void = {}
    var onUpgrade: () -> Void = {}
    /// The host VC runs the real enable/disable flow (which may show an install alert) and then
    /// updates `isTrackingEnabled` with the resolved state.
    var onToggleTracking: (Bool) -> Void = { _ in }

    init() {
        // The enable flow can complete elsewhere (e.g. the first-run TimeTrackerVc intro window),
        // so observe the global state change and re-sync the toggle + reload while this view is up.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackerStateChanged),
                                               name: .timeTrackerEnabledStateChanged,
                                               object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func trackerStateChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let enabled = (UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool) == true
            self.isTrackingEnabled = enabled
            if enabled { self.onRefresh() }
        }
    }
}

extension Notification.Name {
    /// Posted whenever Focus Bear Time Tracker is enabled or disabled, so any live FBTT view
    /// re-syncs its toggle.
    static let timeTrackerEnabledStateChanged = Notification.Name("timeTrackerEnabledStateChanged")
}

// MARK: - SwiftUI view

private let fbAccent = Color(red: 232 / 255, green: 136 / 255, blue: 0 / 255)
private func appBold(_ s: CGFloat) -> Font { Font(getBoldFont(size: s)) }
private func appSemiBold(_ s: CGFloat) -> Font { Font(getSemiBoldFont(size: s)) }
private func appRegular(_ s: CGFloat) -> Font { Font(getRegularFont(size: s)) }
private func appMedium(_ s: CGFloat) -> Font { Font(getMediumFont(size: s)) }

/// "1h 23m" / "45m" / "12s".
private func formatDuration(_ seconds: Int) -> String {
    if seconds <= 0 { return "0m" }
    let h = seconds / 3600, m = (seconds % 3600) / 60
    if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
    if m > 0 { return "\(m)m" }
    return "\(seconds)s"
}

struct FBTTTodayView: View {
    @ObservedObject var model: TodayTrackerViewModel

    /// When true (the standalone 380×520 window) the view fills its parent and pins the footer to the
    /// bottom, scrolling only the project/app list. When false (the inline Tools pane, where the host
    /// container hugs the content height) the view takes its natural height instead — the caller wraps
    /// it in a ScrollView so tall content scrolls rather than overflowing past the window bottom.
    var fillsParent: Bool = true

    /// Cap the content column so labels and their durations sit close together instead of
    /// stretching across the full (very wide) main window.
    private let contentMaxWidth: CGFloat = 440

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Page title + separator, always shown, so it reads as the Time Tracker screen header
            // above the enable setting.
            TimeTrackerTitleHeader()

            // The enable/disable toggle lives at the top and is ALWAYS shown.
            enableSection

            if !model.hasAccess {
                // No Pro access → always show the upgrade prompt, regardless of the toggle state.
                upgradeState
            } else if model.isTrackingEnabled {
                trackerContent
            } else if fillsParent {
                Spacer(minLength: 0)   // keep the toggle pinned to the top when nothing's shown below
            }
        }
        .padding(28)   // match the other Tools panes (Focus Button / Late No More)
        // Fully flexible (no minimum) so it fills both its 380×520 window and an inline Tools pane
        // without imposing a minimum size that would force the main window to resize.
        .frame(maxWidth: .infinity, maxHeight: fillsParent ? .infinity : nil, alignment: .topLeading)
        .background(Color("backgroundColor"))
    }

    // MARK: Enable toggle (moved here from Advanced → Add-Ons)

    private var enableSection: some View {
        TimeTrackerEnableToggleView(
            isEnabled: model.isTrackingEnabled,
            onToggle: model.onToggleTracking
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trackerContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            if let summary = model.summary, !summary.isEmpty {
                let sections = VStack(alignment: .leading, spacing: 20) {
                    if !summary.projects.isEmpty {
                        section(title: ttLocalized("ttProjects", "Projects"), slices: summary.projects, showDot: true)
                    }
                    if !summary.apps.isEmpty {
                        section(title: ttLocalized("ttMostUsedApps", "Most used apps"), slices: summary.apps, showDot: false)
                    }
                }
                // Inline (fillsParent == false) the outer host ScrollView scrolls everything, so don't
                // nest another ScrollView here; in the standalone window the list scrolls on its own.
                if fillsParent { ScrollView { sections } } else { sections }
            } else {
                emptyState
            }

            if fillsParent { Spacer(minLength: 0) }
            footer
        }
        // Fill the height so the footer button pins to the bottom (it was floating up to the content)
        // — but only when filling the parent; inline we take natural height for the wrapping ScrollView.
        .frame(maxWidth: contentMaxWidth, maxHeight: fillsParent ? .infinity : nil, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(ttLocalized("ttToday", "Today"))
                    .font(appBold(20))
                    .foregroundColor(.primary)
                Spacer()
                if model.isLoading {
                    ProgressView().scaleEffect(0.6).frame(width: 16, height: 16)
                }
            }
            Text(formatDuration(model.summary?.totalSeconds ?? 0))
                .font(appBold(30))
                .foregroundColor(fbAccent)
            if !model.updatedAt.isEmpty {
                Text(ttLocalized("ttUpdated", "Updated") + " \(model.updatedAt)")
                    .font(appRegular(11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func section(title: String, slices: [FBTTSlice], showDot: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(appSemiBold(11))
                .foregroundColor(.secondary)
            ForEach(slices) { slice in
                HStack(spacing: 10) {
                    if showDot {
                        Circle()
                            .fill(slice.color ?? Color.secondary.opacity(0.4))
                            .frame(width: 10, height: 10)
                    }
                    Text(slice.label)
                        .font(appRegular(13))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 12)
                    Text(formatDuration(slice.seconds))
                        .font(appSemiBold(13))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ttLocalized("ttEmptyTitle", "No activity tracked yet today."))
                .font(appSemiBold(13))
                .foregroundColor(.primary)
            Text(ttLocalized("ttEmptyBody", "Focus Bear Time Tracker logs your apps and sites automatically — check back soon."))
                .font(appRegular(12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            // In full-screen (borderless) mode, launching the external Time Tracker app would yank the
            // user out of their routine — show guidance instead of the button. checkIsFullScreenEnabled()
            // is the global flag for "the app runs as a borderless full-screen window".
            if checkIsFullScreenEnabled() {
                Text(ttLocalized("ttFullscreenHint", "When you're finished with your habits, you can open the Time Tracker app to see more stats and edit your settings."))
                    .font(appRegular(12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                SwiftUI.Button(action: model.onOpenFBTT) {
                    Text(ttLocalized("ttOpenTracker", "Open Time Tracker"))
                        .font(appSemiBold(13))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(fbAccent))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                Text(ttLocalized("ttOpenTrackerSubtitle", "To change settings and view more data"))
                    .font(appRegular(11))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: Upgrade screen (no trial / subscription)
    private var upgradeState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer(minLength: 0)
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(fbAccent)
            Text(ttLocalized("ttUpgradeTitle", "Automatically log your time"))
                .font(appBold(22))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text(ttLocalized("ttUpgradeBody", "Upgrade to Focus Bear Pro to get automated time tracking."))
                .font(appRegular(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            SwiftUI.Button(action: model.onUpgrade) {
                Text(ttLocalized("ttUpgradeButton", "Upgrade to Pro"))
                    .font(appSemiBold(14))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(fbAccent))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: contentMaxWidth, alignment: .leading)
    }
}

// MARK: - Page title (reusable)

/// "Time Tracker" screen title + a separator, shown at the very top of the Time Tracker pane in
/// every state (downloaded or not) so the title never merges with the enable setting below it.
struct TimeTrackerTitleHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Match the other Tools titles ("Focus Button", "Late No More").
            Text(ttLocalized("menuTimeTracker", "Time Tracker"))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            Divider()
        }
    }
}

// MARK: - Enable toggle (reusable)

/// The "Enable Focus Bear Time Tracker" title + description + switch. Lives at the top of the
/// Time Tracker view, and is also stacked above the download screen when FBTT isn't installed, so
/// the toggle is always visible. `onToggle` runs the host VC's enable/disable flow.
struct TimeTrackerEnableToggleView: View {
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    private var title: String {
        (configjson.value(forKey: "settingsNew") as? NSDictionary)?
            .value(forKey: "focusBearTrackerSettingTitle") as? String
            ?? "Enable Focus Bear Time Tracker"
    }

    private var trackerDescription: String {
        (configjson.value(forKey: "settingsNew") as? NSDictionary)?
            .value(forKey: "focusBearTrackerDescriptionTitle") as? String
            ?? "Analyse your productivity by tracking how much time you spend on different websites and apps. You can automatically categorise time logs into different projects (helpful for timesheets). Data is stored locally for privacy reasons."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(appSemiBold(15))
                        .foregroundColor(.primary)
                    Text(trackerDescription)
                        .font(appRegular(12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                // The setter routes through the host VC's flow instead of flipping the state
                // directly, so the switch only turns on once the tracker is really enabled.
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }
            Divider()
        }
    }
}

// MARK: - Hosting view controller

/// Programmatic NSViewController that hosts FBTTTodayView and refreshes it from
/// FBTT's database. Shown by showTimeTrackerWindow() when FBTT has data.
class TodayTrackerVc: NSViewController {

    let viewModel = TodayTrackerViewModel()
    private var refreshTimer: Timer?

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 520))
        let hosting = NSHostingView(rootView: FBTTTodayView(model: viewModel))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        view = container
        preferredContentSize = NSSize(width: 380, height: 520)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.onOpenFBTT = { openFBTTApp() }
        viewModel.onRefresh = { [weak self] in self?.refresh() }
        viewModel.onToggleTracking = { [weak self] enabled in
            setTimeTrackerEnabled(enabled, presentingWindow: self?.view.window) { resolved in
                self?.viewModel.isTrackingEnabled = resolved
                if resolved { self?.refresh() }
            }
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        viewModel.isTrackingEnabled = (UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool) == true
        refresh()
        // Light polling while the window is visible so the totals stay current.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Loads today's summary off the main thread, then updates the view model.
    func refresh() {
        viewModel.isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let summary = FBTTReader.todaySummary()
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            let stamp = f.string(from: Date())
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.viewModel.summary = summary
                self.viewModel.updatedAt = stamp
                self.viewModel.isLoading = false
            }
        }
    }
}

// Singleton accessor matching the app's getXxxObject() convention.
var todayTrackerVcObj: TodayTrackerVc?
func getTodayTrackerVcObject() -> TodayTrackerVc {
    if todayTrackerVcObj == nil { todayTrackerVcObj = TodayTrackerVc() }
    return todayTrackerVcObj!
}

/// Launches the installed FBTT app (where edits/category changes happen).
func openFBTTApp() {
    NSWorkspace.shared.open(URL(fileURLWithPath: FBTTReader.appPath))
}
