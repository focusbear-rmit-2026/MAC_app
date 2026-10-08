//
//  UITestManagedSafetyFixture.swift
//  Focus Bear
//
//  What the managed-safety UI tests are managed by (RegressionManagedSafetyUITests). Enforcement can't be
//  tested on a developer's Mac, so these put the app into a managed student's STATE — the policy snapshot
//  a school or parent would send, or a teacher's running class session — and the tests check what the
//  student can and can't change, and what they are told.
//
//  Both live in this process only. The policy goes straight into `ManagedBlockingRuntime`, never through
//  `ManagedPolicyStore` (which writes the keychain) or the server; the class session is started without
//  the server ever hearing of it. Reached only from a Debug build under the isolated `.uitests` id,
//  launched by XCUITest with `--uiTest` and the scenario named in the environment.
//

#if DEBUG
import Cocoa

enum UITestManagedSafetyFixture {
    private typealias Scenario = UITestContract.ManagedPolicyScenario
    private typealias Policies = UITestContract.ManagedPolicyFixture
    private typealias ClassSession = UITestContract.TeacherSessionFixture

    /// What `ManagedBlockingRuntime.installForUITests` installs.
    struct PolicyState {
        let snapshot: ManagedPolicySnapshot
        let syncState: ManagedSyncState
        let lastSyncedAt: Date
        /// The instant the scenario was built for, which is when its windows do or don't cover.
        let now: Date
    }

    private static let secondsPerHour: TimeInterval = 3600
    /// The server's `MANAGED_BLOCKING_OFFLINE_LEASE_SECONDS` default: a day.
    private static let offlineLeaseSeconds: TimeInterval = 24 * secondsPerHour
    /// How long ago the offline scenario last reached the server — well inside the lease.
    private static let offlineSinceSeconds: TimeInterval = 2 * secondsPerHour
    private static let snapshotSchemaVersion = 1
    private static let publishedStatus = "published"
    private static let fallbackAllow = "allow"
    private static let fallbackBlock = "block"
    private static let schoolDayStart = "08:30"
    private static let schoolDayEnd = "15:30"
    private static let homeEveningStart = "16:00"
    private static let homeEveningEnd = "20:00"
    /// An all-day window ignores its times; these are what the server sends with one.
    private static let allDayTime = "00:00"

    // MARK: - Managed policy

    /// The scenario the test launch asked for, built for the current time; nil for every other launch.
    static var requestedPolicy: PolicyState? {
        guard UITestHost.isEnabled, UITestHost.has(UITestContract.LaunchArgument.uiTest),
              let raw = ProcessInfo.processInfo.environment[UITestContract.Environment.managedPolicy],
              let scenario = Scenario(rawValue: raw) else { return nil }
        addLog(text: "UITestManagedSafetyFixture: \(raw)")
        return policyState(for: scenario, at: Date())
    }

    private static func policyState(for scenario: Scenario, at now: Date) -> PolicyState {
        let today = weekdayCode(of: now)
        let coveringNow = [ManagedWindow(daysOfWeek: [today], startTime: allDayTime, endTime: allDayTime, allDay: true)]
        let otherDays = ManagedDay.codes.filter { $0 != today }
        let schoolDays = [ManagedWindow(daysOfWeek: otherDays, startTime: schoolDayStart, endTime: schoolDayEnd, allDay: false)]
        let evenings = [ManagedWindow(daysOfWeek: otherDays, startTime: homeEveningStart, endTime: homeEveningEnd, allDay: false)]
        switch scenario {
        case .schoolActive:
            return online(snapshot(school: school(windows: coveringNow), home: home(windows: evenings), at: now))
        case .parentActive:
            return online(snapshot(school: school(windows: schoolDays), home: home(windows: coveringNow), at: now))
        case .schoolInactive:
            return online(snapshot(school: school(windows: schoolDays), home: nil, at: now))
        case .offlineLastKnown:
            let lastSync = now.addingTimeInterval(-offlineSinceSeconds)
            return PolicyState(snapshot: snapshot(school: school(windows: coveringNow), home: home(windows: evenings), at: lastSync),
                               syncState: .offline, lastSyncedAt: lastSync, now: now)
        }
    }

    private static func online(_ snapshot: ManagedPolicySnapshot) -> PolicyState {
        let now = snapshot.serverTime.flatMap(ManagedDate.parse) ?? Date()
        return PolicyState(snapshot: snapshot, syncState: .online, lastSyncedAt: now, now: now)
    }

    /// A lease `ManagedPolicyLease.isUsable` accepts, as the server builds one.
    private static func snapshot(school: ManagedPolicy?, home: ManagedPolicy?, at serverTime: Date) -> ManagedPolicySnapshot {
        let policies = [school, home].compactMap { $0 }.map { "\($0.id):\($0.revision)" }.joined(separator: ",")
        return ManagedPolicySnapshot(school: school, home: home, settingsLocked: true, schemaVersion: snapshotSchemaVersion,
                                     serverTime: ManagedDate.string(serverTime),
                                     offlineValidUntil: ManagedDate.string(serverTime.addingTimeInterval(offlineLeaseSeconds)),
                                     snapshotId: ManagedResource.hash(policies))
    }

    private static func school(windows: [ManagedWindow]) -> ManagedPolicy {
        policy(id: "uitest-school-policy", kind: Policies.schoolKind, name: Policies.schoolPolicyName, revision: 3, windows: windows,
               blocking: ["adult", "gambling", "games", "social_networking"],
               allowlist: [ManagedException(url: "https://example.org/homework", includeSubdomains: false,
                                            reason: "Class resources", expiresAt: nil)])
    }

    private static func home(windows: [ManagedWindow]) -> ManagedPolicy {
        policy(id: "uitest-home-policy", kind: Policies.homeKind, name: Policies.homePolicyName, revision: 1, windows: windows,
               blocking: ["adult", "dating", "gambling"], allowlist: [])
    }

    private static func policy(id: String, kind: String, name: String, revision: Int, windows: [ManagedWindow],
                               blocking categories: [String], allowlist: [ManagedException]) -> ManagedPolicy {
        ManagedPolicy(id: id, schoolId: "uitest-school", studentId: nil, kind: kind, revision: revision,
                      status: publishedStatus, name: name, timeZone: TimeZone.current.identifier, isEnabled: true,
                      windows: windows, blockedCategories: categories, allowlist: allowlist, excludedDates: [],
                      unknownAction: fallbackAllow, unavailableAction: fallbackBlock)
    }

    /// Today's day code, in the time zone the policies use.
    private static func weekdayCode(of date: Date) -> String {
        ManagedDay.code(at: Calendar(identifier: .gregorian).component(.weekday, from: date) - 1)
    }

    // MARK: - Teacher's class session

    private static var hasStartedTeacherSession = false

    /// The keys a class session arrives with (`teacherSessionManager.startTeacherSession`).
    private enum SessionKey {
        static let id = "id"
        static let name = "name"
        static let teamId = "team_id"
        static let allowedApps = "allowed_apps"
        static let allowedUrls = "allowed_urls"
        static let scheduledFinishTime = "scheduled_finish_time"
        static let allowlistVersion = "allowlist_version"
        static let aiBlockingEnabled = "ai_blocking_enabled"
    }
    private static let sessionIdPrefix = "uitest-class-"
    private static let firstAllowlistVersion = 1
    private static let secondsPerMinute: TimeInterval = 60

    /// Joins a class session once settings have loaded, as accepting a teacher's invite does, then shows
    /// it. Called on every launch tick; waits while a routine or a personal session runs, because joining
    /// would postpone or end those — which only the server can do properly — and the tests skip instead.
    static func startTeacherSessionIfRequested() {
        guard !hasStartedTeacherSession, UITestHost.isEnabled, UITestHost.has(UITestContract.LaunchArgument.uiTest),
              ProcessInfo.processInfo.environment[UITestContract.Environment.teacherSession] == UITestContract.Environment.teacherSessionActive,
              !isFocusModeOnOrPaused(), currentState == ._NOTHING_ || currentState.isRoutinePostponed else { return }
        hasStartedTeacherSession = true
        addLog(text: "UITestManagedSafetyFixture: starting a class session")
        teacherSessionManagerObject.startForUITests(sessionDic: classSession(finishingAt: Date().addingTimeInterval(Double(ClassSession.minutes) * secondsPerMinute)))
        // Joining may close the main window (a student not shown the to-do player); the tests need it.
        showRunningFocusSessionWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    private static func classSession(finishingAt finish: Date) -> [String: Any] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = teacherSessionManagerObject.teacherSessionDateFormat
        return [
            SessionKey.id: sessionIdPrefix + getUuid(),
            SessionKey.name: ClassSession.sessionName,
            SessionKey.teamId: "",
            SessionKey.allowedApps: [String](),
            SessionKey.allowedUrls: [ClassSession.allowedDomain],
            SessionKey.scheduledFinishTime: formatter.string(from: finish),
            SessionKey.allowlistVersion: firstAllowlistVersion,
            SessionKey.aiBlockingEnabled: false,
        ]
    }
}
#endif
