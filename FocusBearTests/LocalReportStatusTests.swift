@testable import Focus_Bear
import AppKit
import Foundation
import XCTest

final class LocalReportStatusTests: XCTestCase {
    private var root: URL!
    private let account = "account-a"

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = FileManager.default.temporaryDirectory.appendingPathComponent("LocalReportStatusTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws {
        if let root = root { try FileManager.default.removeItem(at: root) }
        root = nil
        try super.tearDownWithError()
    }
    private func task(owner: String = "account-a", created: String = "2026-09-10_17-51-34", description: String = "The report status is missing") -> String {
        "# Focus Bear — Claude debug task\n- Created: \(created)\n- App version: 3.36\n- User: \(owner)\n\n## What to investigate\n\n\(description)\n\n## Logs\nprivate log path and token\n## Screenshots\nprivate screenshot path\n"
    }
    @discardableResult
    private func folder(_ name: String, task text: String? = nil, notes: String? = nil) throws -> URL {
        let url = root.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try (text ?? task()).write(to: url.appendingPathComponent("TASK.md"), atomically: true, encoding: .utf8)
        if let notes = notes { try notes.write(to: url.appendingPathComponent("CLAUDE-NOTES.md"), atomically: true, encoding: .utf8) }
        return url
    }
    private func scan(_ owner: String = "account-a") throws -> LocalReportStatusSnapshot {
        try LocalReportStatusReader.scan(root: root, accountID: owner)
    }
    private func drainCallbacks() {
        let drained = expectation(description: "queued callbacks delivered")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 2)
    }

    func test_reportContentAllowsDescriptionOrScreenshotButRejectsWhitespaceOnly() {
        for note in ["", " \t\n\r", "\u{00a0}\u{2003}\n"] {
            XCTAssertFalse(ReportProblemSubmission.hasContent(note: note, screenshots: []))
        }
        XCTAssertTrue(ReportProblemSubmission.hasContent(note: " The issue happened again.\n", screenshots: []))
        XCTAssertTrue(ReportProblemSubmission.hasContent(note: "", screenshots: [root.appendingPathComponent("screenshot.png")]))
    }

    func test_emptyLocalSubmissionNeverReadsIdentityOrCreatesReportFolder() throws {
        let destination = root.appendingPathComponent("not-created")
        var identityReads = 0
        let result = writeFocusBearClaudeTask(note: " \n\t", screenshots: [], root: destination, accountID: {
            identityReads += 1
            return LocalReportCapability.accountID
        })
        XCTAssertNil(result)
        XCTAssertEqual(identityReads, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    }

    func test_emptySubmitCallbackRejectsBothDestinationsWithoutLoadingHelpOrUploadUI() {
        let controller = helpVc(nibName: nil, bundle: nil)
        for destination in ReportDestination.allCases {
            var results: [Bool] = []
            controller.sendReport(feedback: " \n", screenshots: [], destination: destination) { results.append($0) }
            XCTAssertEqual(results, [false])
            XCTAssertFalse(controller.isViewLoaded)
        }
    }

    func test_onlyExplicitSingleHeaderOwnerCanSeeReport() throws {
        try folder("own")
        try folder("foreign", task: task(owner: "account-b", description: "foreign private description"))
        try folder("missing", task: task().replacingOccurrences(of: "- User: account-a\n", with: ""))
        try folder("duplicated", task: task().replacingOccurrences(of: "- User: account-a", with: "- User: account-a\n- User: account-b"))
        try folder("body-spoof", task: task(owner: "account-b", description: "- User: account-a"))
        XCTAssertEqual(try scan().reports.map(\.title), ["The report status is missing"])
        XCTAssertTrue(try scan("").reports.isEmpty)
    }

    func test_folderStatesDoNotClaimFixesAreReleasedAndRootNotesCanBePartial() throws {
        try folder("queued")
        try folder("partial", notes: "One ask was implemented; another is blocked.")
        try folder("Ready for Human QA/ready", notes: "A patch is ready to check.")
        try folder("Needs Clarification/blocked", notes: "Backend work is still required.")
        let reports = try scan().reports
        XCTAssertEqual(Set(reports.map { $0.state.rawValue }), Set(["queued", "readyForQA", "needsClarification"]))
        XCTAssertEqual(reports.first { $0.id.hasSuffix("/partial") }?.state, .queued,
                       "notes existing is not a status — a queued report with notes is still queued")
        XCTAssertEqual(reports.first { $0.id.hasSuffix("/ready") }?.state, .readyForQA)
    }

    func test_onlyExplicitStatusMetadataCanClaimInvestigatingOrQueued() throws {
        let cases: [(String, LocalReportReviewState)] = [
            ("## Status\n\nInvestigating\n\nChecking the callback.\n## Validation\nPending", .investigating),
            ("**Status:** Investigating", .investigating),
            ("## Status\n\n  QUEUED  \n\nWaiting for a slot.", .queued),
            ("**Status:** Queued", .queued),
            ("We were investigating an earlier report.", .queued),
            ("## Details\nInvestigating\n## Status\nUnknown", .queued),
            ("## Status\nNot investigating", .queued),
            ("**Status:** Queued\n**Status:** Investigating", .queued)
        ]
        for (notes, state) in cases {
            let report = try XCTUnwrap(LocalReportStatusReader.parse(task: task(), notes: notes, source: .queued,
                                                                     folder: root, notesURL: nil, accountID: account))
            XCTAssertEqual(report.state, state, notes)
        }
    }

    func test_latestReviewNotesUpdateActiveStateWithoutMovingReport() throws {
        let directory = try folder("Ready for Human QA/report", notes: "## Status\n\nQueued")
        XCTAssertEqual(try scan().reports.first?.state, .queued)
        let latest = directory.appendingPathComponent("CODEX-NOTES.md")
        try "## Status\n\nInvestigating\n\nRechecking the new feedback.".write(to: latest, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: 10)], ofItemAtPath: latest.path)
        let report = try XCTUnwrap(scan().reports.first)
        XCTAssertEqual(report.state, .investigating)
        XCTAssertEqual(report.notesURL?.resolvingSymlinksInPath().standardizedFileURL,
                       latest.resolvingSymlinksInPath().standardizedFileURL)
        XCTAssertTrue(report.id.hasSuffix("/Ready for Human QA/report"))
        XCTAssertTrue(try scan("other-account").reports.isEmpty)
    }

    func test_userConfirmationRemainsAuthoritativeOverInvestigatingNotesAndUndoRevealsThem() throws {
        let owner = LocalReportCapability.accountID
        try folder("report", task: task(owner: owner), notes: "**Status:** Investigating")
        let investigating = try XCTUnwrap(scan(owner).reports.first)
        XCTAssertEqual(investigating.state, .investigating)
        try LocalReportConfirmationWriter.setConfirmedFixed(true, for: investigating, root: root, accountID: { owner })
        let confirmed = try XCTUnwrap(scan(owner).reports.first)
        XCTAssertEqual(confirmed.state, .confirmedFixed)
        try LocalReportConfirmationWriter.setConfirmedFixed(false, for: confirmed, root: root, accountID: { owner })
        XCTAssertEqual(try scan(owner).reports.first?.state, .investigating)
    }

    func test_reviewExcerptPrefersUpdateAndDoesNotRepeatLoneStatusBadge() throws {
        for status in ["## Status\n\nInvestigating", "**Status:** Queued"] {
            let bare = try XCTUnwrap(LocalReportStatusReader.parse(task: task(), notes: status, source: .queued,
                folder: root, notesURL: nil, accountID: account))
            XCTAssertNil(bare.notesExcerpt)
            let detailed = try XCTUnwrap(LocalReportStatusReader.parse(task: task(),
                notes: status + "\n\n## Update\nThe callback guard is being checked.\n## Next action\nWait for validation.",
                source: .queued, folder: root, notesURL: nil, accountID: account))
            XCTAssertEqual(detailed.notesExcerpt, "The callback guard is being checked.")
        }
        let legacy = try XCTUnwrap(LocalReportStatusReader.parse(task: task(), notes: "**Status:** Waiting for a backend change.",
            source: .queued, folder: root, notesURL: nil, accountID: account))
        XCTAssertEqual(legacy.notesExcerpt, "Waiting for a backend change.")
    }

    func test_periodicRefreshSkipsAnOverlappingLoadAndAlwaysAsksForFinishedReports() throws {
        var requested: [Bool] = []
        var completions: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        let store = LocalReportStatusStore(accountID: { self.account }, loader: { _, showFixed, done in
            requested.append(showFixed); completions.append(done)
        })
        store.refresh()
        store.refreshIfIdle(); store.refreshIfIdle()   // both no-ops while the first load is in flight
        XCTAssertEqual(requested, [true], "Finished reports live in a collapsed group, so they load too")
        completions[0](.success(.init(reports: [], isLimited: false))); drainCallbacks()
        store.refreshIfIdle()
        XCTAssertEqual(requested, [true, true])
        completions[1](.success(.init(reports: [], isLimited: false))); drainCallbacks()
        store.refreshIfIdle()
        XCTAssertEqual(requested, [true, true, true])
        XCTAssertTrue(store.showConfirmedFixed)
    }

    func test_titleAndNotesExcerptsAreBoundedAndDoNotReadLogsSections() throws {
        let long = String(repeating: "🐻", count: 450)
        try folder("described", task: task(description: long + "\nextra description"),
                   notes: "# Internal notes\nprivate credentials outside the selected section\n## What a human should decide\n\n\(long)\n## Logs\nprivate log payload")
        let report = try XCTUnwrap(scan().reports.first)
        XCTAssertEqual(report.title, String(long.prefix(180)))
        XCTAssertEqual(report.notesExcerpt, String(long.prefix(400)))
        XCTAssertFalse(report.title.contains("private"))
        XCTAssertFalse(report.notesExcerpt?.contains("private") ?? true)
    }

    func test_statusLineAndUpdatedNotesAtOriginalLocationAreRecognized() throws {
        let url = try folder("unchanged-folder")
        XCTAssertEqual(try scan().reports.first?.state, .queued)
        try "**Status:** Waiting for the backend change.\nMore internal details".write(to: url.appendingPathComponent("CLAUDE-NOTES.md"), atomically: true, encoding: .utf8)
        XCTAssertEqual(try scan().reports.first?.notesExcerpt, "Waiting for the backend change.")
        try "## Next action\nPlease check the latest app.\n## Validation\nAdditional details".write(to: url.appendingPathComponent("CODEX-NOTES.md"), atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: 10)], ofItemAtPath: url.appendingPathComponent("CODEX-NOTES.md").path)
        let updated = try XCTUnwrap(scan().reports.first)
        XCTAssertEqual(updated.notesExcerpt, "Please check the latest app.")
        XCTAssertEqual(updated.notesURL?.lastPathComponent, "CODEX-NOTES.md")
        XCTAssertEqual(updated.state, .queued)
    }

    func test_missingRootDoesNotCreateDirectoriesAndInvalidDatesAreIgnored() throws {
        let missing = root.appendingPathComponent("not-created")
        XCTAssertTrue(try LocalReportStatusReader.scan(root: missing, accountID: account).reports.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing.path))
        try folder("invalid-date", task: task(created: "2026-02-30_12-00-00"))
        try folder("missing-date", task: task(created: ""))
        try folder("extra-date-text", task: task(created: "2026-09-10_17-51-34 extra"))
        XCTAssertTrue(try scan().reports.isEmpty)
    }

    func test_oversizedTasksAreIgnoredButLargeNotesStillHaveHonestLink() throws {
        try folder("oversized-task", task: task(description: String(repeating: "x", count: LocalReportStatusReader.maximumTextBytes)))
        try folder("large-notes", notes: String(repeating: "x", count: LocalReportStatusReader.maximumTextBytes + 1))
        let report = try XCTUnwrap(scan().reports.first)
        XCTAssertEqual(try scan().reports.count, 1)
        XCTAssertEqual(report.state, .queued)
        XCTAssertNil(report.notesExcerpt)
        XCTAssertNotNil(report.notesURL)
    }

    func test_linkedTaskNotesAndReportDirectoriesAreExcluded() throws {
        let original = try folder("original", notes: "**Status:** Review requested.")
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("linked-folder"), withDestinationURL: original)
        let linkedTask = root.appendingPathComponent("linked-task")
        try FileManager.default.createDirectory(at: linkedTask, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: linkedTask.appendingPathComponent("TASK.md"), withDestinationURL: original.appendingPathComponent("TASK.md"))
        let linkedNotes = try folder("linked-notes")
        try FileManager.default.createSymbolicLink(at: linkedNotes.appendingPathComponent("CLAUDE-NOTES.md"), withDestinationURL: original.appendingPathComponent("CLAUDE-NOTES.md"))
        let reports = try scan().reports
        XCTAssertEqual(reports.count, 2)
        XCTAssertNil(reports.first { $0.id.hasSuffix("/linked-notes") }?.notesURL)
        XCTAssertEqual(reports.first { $0.id.hasSuffix("/linked-notes") }?.state, .queued)
    }

    func test_newestReportsComeFirstAndListingIsBounded() throws {
        for index in 0...LocalReportStatusReader.maximumReports {
            let date = String(format: "2026-09-10_%02d-%02d-00", index / 60, index % 60)
            try folder("report-\(index)", task: task(created: date, description: "Report \(index)"))
        }
        let snapshot = try scan()
        XCTAssertEqual(snapshot.reports.count, LocalReportStatusReader.maximumReports)
        XCTAssertEqual(snapshot.reports.first?.title, "Report 100")
        XCTAssertEqual(snapshot.reports.last?.title, "Report 1")
        XCTAssertTrue(snapshot.isLimited)
    }

    func test_hiddenConfirmedReportsDoNotConsumeDisplayLimitOrHideOlderOpenReports() throws {
        let owner = LocalReportCapability.accountID
        for index in 0...LocalReportStatusReader.maximumReports {
            let date = String(format: "2026-09-10_%02d-%02d-00", index / 60, index % 60)
            let url = try folder(date, task: task(owner: owner, created: date, description: "Fixed \(index)"))
            let status = LocalReportUserStatus(schemaVersion: 1, accountID: owner, reportCreated: date,
                                               confirmedFixed: true, updatedAt: "2026-09-10T10:00:00Z")
            try JSONEncoder().encode(status).write(to: url.appendingPathComponent(LocalReportUserStatus.fileName))
        }
        try folder("Needs Clarification/2026-09-09_10-00-00", task: task(owner: owner, created: "2026-09-09_10-00-00", description: "Older open report"))
        try folder("2026-09-11_10-00-00", task: task(owner: "another-account", created: "2026-09-11_10-00-00", description: "Foreign report"))
        let open = try LocalReportStatusReader.scan(root: root, accountID: owner, includeConfirmedFixed: false)
        XCTAssertEqual(open.reports.map(\.title), ["Older open report"])
        XCTAssertEqual(open.reports.first?.state, .needsClarification)
        XCTAssertFalse(open.isLimited)
        let all = try LocalReportStatusReader.scan(root: root, accountID: owner, includeConfirmedFixed: true)
        XCTAssertEqual(all.reports.count, LocalReportStatusReader.maximumReports)
        XCTAssertEqual(all.reports.first?.title, "Fixed 100")
        XCTAssertTrue(all.isLimited)
    }

    func test_hiddenFixedFilterKeepsReportsWithInvalidConfirmationVisible() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("owned", task: task(owner: owner))
        let status = LocalReportUserStatus(schemaVersion: 1, accountID: "another-account", reportCreated: "2026-09-10_17-51-34",
                                           confirmedFixed: true, updatedAt: "2026-09-10T10:00:00Z")
        try JSONEncoder().encode(status).write(to: url.appendingPathComponent(LocalReportUserStatus.fileName))
        XCTAssertEqual(try LocalReportStatusReader.scan(root: root, accountID: owner, includeConfirmedFixed: false).reports.first?.state, .queued)
    }

    func test_aLateResponseFromASupersededLoadIsIgnored() throws {
        try folder("open")
        let snapshot = try scan()
        var completions: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        let store = LocalReportStatusStore(accountID: { self.account }, loader: { _, _, done in
            completions.append(done)
        })
        store.refresh()
        store.refresh()   // supersedes the first
        completions[0](.success(snapshot)); drainCallbacks()
        XCTAssertTrue(store.reports.isEmpty, "The superseded load must not populate the list")
        XCTAssertTrue(store.isLoading)
        completions[1](.success(snapshot)); drainCallbacks()
        XCTAssertFalse(store.isLoading)
        XCTAssertEqual(store.reports.count, snapshot.reports.count)
    }

    func test_accountSwitchRejectsThePreviousAccountsResponse() throws {
        try folder("open")
        let snapshot = try scan()
        var current = account
        var completions: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        let store = LocalReportStatusStore(accountID: { current }, loader: { _, _, done in completions.append(done) })
        store.refresh()
        current = "another-account"; store.checkAccount()
        completions[0](.success(snapshot)); drainCallbacks()
        XCTAssertTrue(store.reports.isEmpty, "Another account's reports must never appear")
    }

    func test_openNotesRechecksCurrentAccountAndOnDiskOwnership() throws {
        let url = try folder("owned", notes: "Review notes")
        let report = try XCTUnwrap(scan().reports.first)
        XCTAssertTrue(LocalReportStatusReader.mayOpenNotes(report, accountID: account))
        XCTAssertFalse(LocalReportStatusReader.mayOpenNotes(report, accountID: "account-b"))
        try task(owner: "account-b").write(to: url.appendingPathComponent("TASK.md"), atomically: true, encoding: .utf8)
        XCTAssertFalse(LocalReportStatusReader.mayOpenNotes(report, accountID: account))
    }

    func test_inAppNotesReadIsBoundedAndRejectsStaleIdentityOrAccount() throws {
        let notes = "## Status\n\nInvestigating\n\n## Update\nChecking the report."
        let directory = try folder("owned", notes: notes)
        let report = try XCTUnwrap(scan().reports.first)
        XCTAssertEqual(LocalReportStatusReader.readNotes(report, accountID: { self.account }), notes)
        XCTAssertNil(LocalReportStatusReader.readNotes(report, accountID: { "other-account" }))
        var checks = 0
        XCTAssertNil(LocalReportStatusReader.readNotes(report, accountID: {
            checks += 1; return checks == 1 ? self.account : "other-account"
        }))
        let taskURL = directory.appendingPathComponent("TASK.md")
        try task(created: "2026-09-11_12-00-00").write(to: taskURL, atomically: true, encoding: .utf8)
        XCTAssertNil(LocalReportStatusReader.readNotes(report, accountID: { self.account }))
        try task().write(to: taskURL, atomically: true, encoding: .utf8)
        let notesURL = directory.appendingPathComponent("CLAUDE-NOTES.md")
        try String(repeating: "x", count: LocalReportStatusReader.maximumTextBytes + 1).write(to: notesURL, atomically: true, encoding: .utf8)
        XCTAssertNil(LocalReportStatusReader.readNotes(report, accountID: { self.account }))
        try FileManager.default.removeItem(at: notesURL)
        try FileManager.default.createSymbolicLink(at: notesURL, withDestinationURL: taskURL)
        XCTAssertNil(LocalReportStatusReader.readNotes(report, accountID: { self.account }))
    }

    func test_notesReadRejectsReportDirectoryReplacedWithLinkAfterSuccessfulRead() throws {
        let directory = try folder("owned", notes: "Original review notes")
        let report = try XCTUnwrap(scan().reports.first)
        XCTAssertEqual(LocalReportStatusReader.readNotes(report, accountID: { self.account }), "Original review notes")
        let moved = root.appendingPathComponent("moved")
        try FileManager.default.moveItem(at: directory, to: moved)
        try FileManager.default.createSymbolicLink(at: directory, withDestinationURL: moved)
        XCTAssertNil(LocalReportStatusReader.readNotes(report, accountID: { self.account }))
    }

    func test_accountSwitchClearsPreviousReportsAndRejectsLateLoad() throws {
        try folder("a")
        let a = try scan()
        var current = account
        var completions: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        let store = LocalReportStatusStore(accountID: { current }, loader: { _, _, done in completions.append(done) })
        store.refresh(); completions[0](.success(a)); drainCallbacks()
        XCTAssertEqual(store.reports.count, 1)
        store.refresh()
        current = "account-b"; store.checkAccount()
        XCTAssertTrue(store.reports.isEmpty)
        completions[1](.success(a)); drainCallbacks()
        XCTAssertTrue(store.reports.isEmpty)
        XCTAssertTrue(store.isLoading)
        completions[2](.success(.init(reports: [], isLimited: false))); drainCallbacks()
        XCTAssertFalse(store.isLoading)
        XCTAssertEqual(store.loadedAccount, "account-b")
    }

    func test_lateCallbackDetectsAccountChangeEvenBeforeTimer() throws {
        try folder("a")
        var current = account
        var requested: [String] = []
        var completions: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        let store = LocalReportStatusStore(accountID: { current }, loader: { account, _, done in requested.append(account); completions.append(done) })
        store.refresh(); current = "account-b"
        completions[0](.success(try scan())); drainCallbacks()
        XCTAssertEqual(requested, [account, "account-b"])
        XCTAssertTrue(store.reports.isEmpty)
        current = ""; store.checkAccount()
        completions[1](.success(try scan())); drainCallbacks()
        XCTAssertTrue(store.reports.isEmpty)
        XCTAssertFalse(store.isLoading)
    }

    func test_aConfirmationReleasesItsRowEvenIfTheRescanNeverLands() throws {
        // The user's click writes the file BEFORE the rescan runs, so the row is only ever waiting on
        // the list catching up. When that rescan never landed, the spinner turned forever and the
        // control stayed disabled over an operation that had already succeeded — which reads as a
        // hang (report 2026-09-17: "it seems to be stuck at confirming fixed?").
        let owner = LocalReportCapability.accountID
        _ = try folder("Ready for Human QA/owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        var wrote = false
        let store = LocalReportStatusStore(accountID: { owner },
                                           loader: { _, _, _ in /* deliberately never answers */ },
                                           confirmer: { _, _, _ in wrote = true })
        store.confirmationRescanTimeout = 0.05
        store.refresh()

        let released = expectation(description: "the row is released")
        store.setConfirmedFixed(true, for: report) { _ in released.fulfill() }
        wait(for: [released], timeout: 2)

        XCTAssertTrue(wrote, "the write itself must still have happened")
        XCTAssertFalse(store.pendingConfirmations.contains(report.id), "the row must not stay disabled")
    }

    func test_aConfirmationReleasesItsRowOnlyOnceWhenTheRescanAlsoLands() throws {
        // Both the cap and the rescan call the same release. Firing twice would remove a pending id
        // that a LATER click had legitimately re-added, re-enabling a row mid-write.
        let owner = LocalReportCapability.accountID
        _ = try folder("Ready for Human QA/owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        var completions: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        let store = LocalReportStatusStore(accountID: { owner },
                                           loader: { _, _, done in completions.append(done) },
                                           confirmer: { _, _, _ in })
        store.confirmationRescanTimeout = 0.05
        store.refresh()

        var releases = 0
        let released = expectation(description: "released")
        store.setConfirmedFixed(true, for: report) { _ in
            releases += 1
            if releases == 1 { released.fulfill() }
        }
        wait(for: [released], timeout: 2)
        completions.forEach { $0(.success((try? self.scan(owner)) ?? LocalReportStatusSnapshot(reports: [], isLimited: false))) }
        drainCallbacks()
        XCTAssertEqual(releases, 1)
    }

    func test_olderRefreshCannotReplaceNewerResultOrClearItsError() throws {
        try folder("a")
        var completions: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        let store = LocalReportStatusStore(accountID: { self.account }, loader: { _, _, done in completions.append(done) })
        store.refresh(); store.refresh()
        completions[1](.failure(NSError(domain: "fixture", code: 1))); drainCallbacks()
        completions[0](.success(try scan())); drainCallbacks()
        XCTAssertTrue(store.failed)
        XCTAssertTrue(store.reports.isEmpty)
        XCTAssertFalse(store.isLoading)
    }

    func test_instructionsPreserveTaskAndInterveningReviewChangesAndAppearOnRescan() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("Ready for Human QA/owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        let current = task(owner: owner) + "\n## Review update\nNew reviewer information after the list loaded.\n"
        try current.write(to: url.appendingPathComponent("TASK.md"), atomically: true, encoding: .utf8)
        try LocalReportInstructionWriter.append("Please check the narrow window too. 🐻", to: report, root: root,
                                                accountID: { owner }, now: Date(timeIntervalSince1970: 0))
        let saved = try String(contentsOf: url.appendingPathComponent("TASK.md"), encoding: .utf8)
        XCTAssertTrue(saved.hasPrefix(current))
        XCTAssertTrue(saved.contains("- Added: 1970-01-01T00:00:00Z"))
        XCTAssertEqual(try scan(owner).reports.first?.latestInstructions, "Please check the narrow window too. 🐻")
        try LocalReportInstructionWriter.append("Actually, check both sizes.", to: report, root: root, accountID: { owner })
        let second = try String(contentsOf: url.appendingPathComponent("TASK.md"), encoding: .utf8)
        XCTAssertTrue(second.hasPrefix(saved))
        XCTAssertEqual(try scan(owner).reports.first?.latestInstructions, "Actually, check both sizes.")
    }

    func test_instructionsAreOnlyEnabledForTheExistingTesterCapability() throws {
        let url = try folder("other-owned")
        let report = try XCTUnwrap(scan().reports.first)
        let original = try Data(contentsOf: url.appendingPathComponent("TASK.md"))
        XCTAssertThrowsError(try LocalReportInstructionWriter.append("Change this", to: report, root: root, accountID: { self.account }))
        XCTAssertEqual(try Data(contentsOf: url.appendingPathComponent("TASK.md")), original)
        XCTAssertFalse(LocalReportCapability.isEnabled(for: ""))
        XCTAssertFalse(LocalReportCapability.isEnabled(for: account))
    }

    func test_accountSwitchDuringReplyCannotWriteToOldAccountTask() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        let original = try Data(contentsOf: url.appendingPathComponent("TASK.md"))
        var checks = 0
        XCTAssertThrowsError(try LocalReportInstructionWriter.append("Private reply", to: report, root: root, accountID: {
            checks += 1; return checks < 3 ? owner : "other-account"
        }))
        XCTAssertEqual(try Data(contentsOf: url.appendingPathComponent("TASK.md")), original)
    }

    func test_blankOversizedAndReassignedRepliesCannotChangeTask() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        let original = try Data(contentsOf: url.appendingPathComponent("TASK.md"))
        for text in [" \n ", String(repeating: "x", count: LocalReportInstructionWriter.maximumCharacters + 1)] {
            XCTAssertThrowsError(try LocalReportInstructionWriter.append(text, to: report, root: root, accountID: { owner }))
        }
        XCTAssertEqual(try Data(contentsOf: url.appendingPathComponent("TASK.md")), original)
        try task(owner: "another-account").write(to: url.appendingPathComponent("TASK.md"), atomically: true, encoding: .utf8)
        let reassigned = try Data(contentsOf: url.appendingPathComponent("TASK.md"))
        XCTAssertThrowsError(try LocalReportInstructionWriter.append("Private reply", to: report, root: root, accountID: { owner }))
        XCTAssertEqual(try Data(contentsOf: url.appendingPathComponent("TASK.md")), reassigned)
    }

    func test_movedOrLinkedTaskCannotBeRecreatedByReply() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        let moved = root.appendingPathComponent("moved")
        try FileManager.default.moveItem(at: url, to: moved)
        XCTAssertThrowsError(try LocalReportInstructionWriter.append("Reply", to: report, root: root, accountID: { owner }))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: moved)
        XCTAssertThrowsError(try LocalReportInstructionWriter.append("Reply", to: report, root: root, accountID: { owner }))
        XCTAssertEqual(try String(contentsOf: moved.appendingPathComponent("TASK.md"), encoding: .utf8), task(owner: owner))
    }

    func test_userConfirmationAndUndoRoundTripWithoutChangingTaskNotesOrInstructions() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("Ready for Human QA/owned", task: task(owner: owner), notes: "**Status:** Ready to check.")
        let report = try XCTUnwrap(scan(owner).reports.first)
        // New instructions can arrive after the table snapshot: confirmation must preserve them.
        try LocalReportInstructionWriter.append("Check the latest change too.", to: report, root: root, accountID: { owner })
        let taskBefore = try Data(contentsOf: url.appendingPathComponent("TASK.md"))
        let notesBefore = try Data(contentsOf: url.appendingPathComponent("CLAUDE-NOTES.md"))
        // Confirmed AFTER that feedback arrived, which is the real ordering: you read it, then say it
        // is fixed. This used to pass an epoch-0 timestamp, which makes the confirmation older than
        // the feedback — and that now means "feedback this confirmation hasn't answered", i.e. rework
        // (report 2026-09-16_20-26-48).
        let confirmedAt = Date().addingTimeInterval(60)
        try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root, accountID: { owner }, now: confirmedAt)
        let confirmed = try XCTUnwrap(scan(owner).reports.first)
        XCTAssertEqual(confirmed.state, .confirmedFixed)
        XCTAssertEqual(confirmed.userStatus?.updatedDate?.timeIntervalSince1970 ?? 0,
                       confirmedAt.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(confirmed.latestInstructions, "Check the latest change too.")
        XCTAssertEqual(try Data(contentsOf: url.appendingPathComponent("TASK.md")), taskBefore)
        XCTAssertEqual(try Data(contentsOf: url.appendingPathComponent("CLAUDE-NOTES.md")), notesBefore)
        try LocalReportConfirmationWriter.setConfirmedFixed(false, for: confirmed, root: root, accountID: { owner })
        let reopened = try XCTUnwrap(scan(owner).reports.first)
        XCTAssertEqual(reopened.state, .readyForQA)
        XCTAssertEqual(reopened.userStatus?.confirmedFixed, false)
        XCTAssertEqual(try Data(contentsOf: url.appendingPathComponent("TASK.md")), taskBefore)
        XCTAssertEqual(try Data(contentsOf: url.appendingPathComponent("CLAUDE-NOTES.md")), notesBefore)
    }

    func test_userConfirmationFollowsReportIntoExistingReviewFolder() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root, accountID: { owner })
        let location = root.appendingPathComponent("Needs Clarification")
        try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
        let destination = location.appendingPathComponent("renamed-owned")
        try FileManager.default.moveItem(at: url, to: destination)
        let moved = try XCTUnwrap(scan(owner).reports.first)
        XCTAssertEqual(moved.state, .confirmedFixed)
        XCTAssertTrue(moved.id.hasSuffix("/Needs Clarification/renamed-owned"))
        XCTAssertThrowsError(try LocalReportConfirmationWriter.setConfirmedFixed(false, for: report, root: root, accountID: { owner }))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        try LocalReportConfirmationWriter.setConfirmedFixed(false, for: moved, root: root, accountID: { owner })
        XCTAssertEqual(try scan(owner).reports.first?.state, .needsClarification)
    }

    func test_invalidOrForeignUserMetadataCannotClaimConfirmationOrBeSilentlyReplaced() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root, accountID: { owner })
        let statusURL = url.appendingPathComponent(LocalReportUserStatus.fileName)
        let valid = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: statusURL)) as? [String: Any])
        for (key, value) in [("schema_version", 2), ("account_id", "other-account"),
                             ("report_created", "2026-09-09_10-00-00"), ("updated_at", "not-a-date"),
                             ("confirmed_fixed", "true")] as [(String, Any)] {
            var invalid = valid; invalid[key] = value
            let data = try JSONSerialization.data(withJSONObject: invalid)
            try data.write(to: statusURL, options: .atomic)
            let loaded = try XCTUnwrap(scan(owner).reports.first)
            XCTAssertEqual(loaded.state, .queued, key)
            XCTAssertThrowsError(try LocalReportConfirmationWriter.setConfirmedFixed(true, for: loaded, root: root, accountID: { owner }), key)
            XCTAssertEqual(try Data(contentsOf: statusURL), data)
        }
        for data in [Data("{broken".utf8), Data(repeating: 32, count: LocalReportUserStatus.maximumBytes + 1)] {
            try data.write(to: statusURL, options: .atomic)
            XCTAssertEqual(try scan(owner).reports.first?.state, .queued)
        }
    }

    func test_staleConfirmationCannotReplaceNewerUserChoice() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("owned", task: task(owner: owner))
        let original = try XCTUnwrap(scan(owner).reports.first)
        try LocalReportConfirmationWriter.setConfirmedFixed(true, for: original, root: root, accountID: { owner })
        let confirmed = try XCTUnwrap(scan(owner).reports.first)
        let statusURL = url.appendingPathComponent(LocalReportUserStatus.fileName)
        let confirmedData = try Data(contentsOf: statusURL)
        XCTAssertThrowsError(try LocalReportConfirmationWriter.setConfirmedFixed(false, for: original, root: root, accountID: { owner }))
        XCTAssertEqual(try Data(contentsOf: statusURL), confirmedData)
        try LocalReportConfirmationWriter.setConfirmedFixed(false, for: confirmed, root: root, accountID: { owner })
        let reopenedData = try Data(contentsOf: statusURL)
        XCTAssertThrowsError(try LocalReportConfirmationWriter.setConfirmedFixed(true, for: confirmed, root: root, accountID: { owner }))
        XCTAssertEqual(try Data(contentsOf: statusURL), reopenedData)
        XCTAssertEqual(try scan(owner).reports.first?.state, .queued)
    }

    func test_confirmationRechecksAccountAndTaskIdentityBeforeWriting() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        let statusURL = url.appendingPathComponent(LocalReportUserStatus.fileName)
        var checks = 0
        XCTAssertThrowsError(try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root, accountID: {
            checks += 1; return checks < 3 ? owner : "another-account"
        }))
        XCTAssertFalse(FileManager.default.fileExists(atPath: statusURL.path))
        for replacement in [task(owner: "another-account"), task(owner: owner, created: "2026-09-09_10-00-00")] {
            try replacement.write(to: url.appendingPathComponent("TASK.md"), atomically: true, encoding: .utf8)
            XCTAssertThrowsError(try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root, accountID: { owner }))
            XCTAssertFalse(FileManager.default.fileExists(atPath: statusURL.path))
            XCTAssertEqual(try String(contentsOf: url.appendingPathComponent("TASK.md"), encoding: .utf8), replacement)
        }
    }

    func test_confirmationRejectsLinkedStatusAndTaskFilesIncludingDanglingLinks() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        let statusURL = url.appendingPathComponent(LocalReportUserStatus.fileName)
        let target = root.appendingPathComponent("outside.json")
        for existing in [false, true] {
            if existing { try Data("keep outside content".utf8).write(to: target) }
            try FileManager.default.createSymbolicLink(at: statusURL, withDestinationURL: target)
            XCTAssertEqual(try scan(owner).reports.first?.state, .queued)
            XCTAssertThrowsError(try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root, accountID: { owner }))
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: statusURL.path), target.path)
            if existing { XCTAssertEqual(try String(contentsOf: target, encoding: .utf8), "keep outside content") }
            else { XCTAssertFalse(FileManager.default.fileExists(atPath: target.path)) }
            try FileManager.default.removeItem(at: statusURL)
        }
        let taskURL = url.appendingPathComponent("TASK.md")
        let original = root.appendingPathComponent("original-task.md")
        try FileManager.default.moveItem(at: taskURL, to: original)
        try FileManager.default.createSymbolicLink(at: taskURL, withDestinationURL: original)
        XCTAssertThrowsError(try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root, accountID: { owner }))
        XCTAssertFalse(FileManager.default.fileExists(atPath: statusURL.path))
    }

    func test_confirmationCannotChangeTaskEditedDuringValidation() throws {
        let owner = LocalReportCapability.accountID
        let url = try folder("owned", task: task(owner: owner))
        let report = try XCTUnwrap(scan(owner).reports.first)
        let taskURL = url.appendingPathComponent("TASK.md")
        let changed = task(owner: owner) + "\n## Additional instructions\n\nPlease check the latest edit.\n"
        var checks = 0
        XCTAssertThrowsError(try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root, accountID: {
            checks += 1
            if checks == 3 { try? changed.write(to: taskURL, atomically: true, encoding: .utf8) }
            return owner
        }))
        XCTAssertEqual(try String(contentsOf: taskURL, encoding: .utf8), changed)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.appendingPathComponent(LocalReportUserStatus.fileName).path))
    }

    // MARK: - Screenshots on the report row (report 2026-09-13_21-19-23)

    /// "it should let me see the screenshots from these old logs — I can't interpret them just from
    /// the text." Only real image files sitting directly in the report's own screenshots folder are
    /// offered, and only this account's.
    func testScreenshotsComeOnlyFromTheReportsOwnFolder() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let folder = root.appendingPathComponent("2026-09-13_21-19-23")
        let shots = folder.appendingPathComponent("screenshots")
        try FileManager.default.createDirectory(at: shots, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for name in ["b.png", "a.PNG", "notes.txt", "nested"] {
            if name == "nested" {
                try FileManager.default.createDirectory(at: shots.appendingPathComponent(name), withIntermediateDirectories: true)
            } else {
                try Data("x".utf8).write(to: shots.appendingPathComponent(name))
            }
        }
        let found = LocalReportStatusReader.screenshotURLs(in: folder).map { $0.lastPathComponent }
        XCTAssertEqual(found, ["a.PNG", "b.png"], "Images only, sorted, whatever the extension's case")
    }

    func testScreenshotsAreEmptyWithoutAScreenshotsFolder() {
        let folder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        XCTAssertTrue(LocalReportStatusReader.screenshotURLs(in: folder).isEmpty)
    }

    // MARK: Searching the report list (report 2026-09-14_12-08-07)

    private func searchable(_ title: String, notes: String? = nil, instructions: String? = nil,
                            created: String = "2026-09-14_12-00-00") -> LocalReportStatus {
        LocalReportStatus(id: title, accountID: account, reportCreated: created, createdAt: Date(),
                          title: title, state: .queued, notesExcerpt: notes, notesURL: nil,
                          latestUpdate: nil, latestInstructions: instructions, lastAIUpdate: nil,
                          userStatus: nil, userStatusData: nil, screenshotURLs: [])
    }

    func testAnEmptySearchLeavesEveryReportStanding() {
        let reports = [searchable("Delete task"), searchable("Window resize")]
        XCTAssertEqual(LocalReportSearch.matching(reports, query: "   ").map(\.title),
                       reports.map(\.title))
    }

    func testSearchIgnoresCaseAndAccents() {
        let reports = [searchable("Búsqueda de informes"), searchable("Something else")]
        XCTAssertEqual(LocalReportSearch.matching(reports, query: "busqueda").map(\.title),
                       ["Búsqueda de informes"])
    }

    func testSearchAlsoLooksAtNotesInstructionsAndTheReportDate() {
        let byNotes = searchable("A", notes: "the postpone silently did nothing")
        let byInstructions = searchable("B", instructions: "happened again just now")
        let byDate = searchable("C", created: "2026-09-14_15-04-30")
        let reports = [byNotes, byInstructions, byDate]
        XCTAssertEqual(LocalReportSearch.matching(reports, query: "postpone").map(\.title), ["A"])
        XCTAssertEqual(LocalReportSearch.matching(reports, query: "again").map(\.title), ["B"])
        XCTAssertEqual(LocalReportSearch.matching(reports, query: "15-04").map(\.title), ["C"])
    }

    func testSearchWithNoMatchesReturnsNothingRatherThanEverything() {
        XCTAssertTrue(LocalReportSearch.matching([searchable("Delete task")], query: "zzz").isEmpty)
    }

    // MARK: Pasted images (report 2026-09-14_12-08-59)

    func testPastedImageFileNameSortsBesideTheReportsOwnCaptures() {
        var components = DateComponents()
        components.year = 2026; components.month = 9; components.day = 14
        components.hour = 16; components.minute = 5; components.second = 9
        let when = Calendar(identifier: .gregorian).date(from: components)!
        XCTAssertEqual(LocalReportImageWriter.fileName(now: when), "pasted-2026-09-14_16-05-09.png")
    }

    func testTheInstructionLineNamesTheFileInsideTheScreenshotsFolder() {
        XCTAssertEqual(LocalReportImageWriter.reference("pasted-x.png"), "[image: screenshots/pasted-x.png]")
    }

    func testAnImageTooLargeToBeAPasteIsRefused() {
        let huge = NSImage(size: NSSize(width: 1, height: 1))
        huge.lockFocus(); NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 1, height: 1)); huge.unlockFocus()
        XCTAssertNotNil(LocalReportImageWriter.pngData(for: huge), "A normal paste converts to PNG")
        XCTAssertNil(LocalReportImageWriter.pngData(for: NSImage()), "An empty image has nothing to save")
    }

    func testAPastedImageLandsInTheReportsScreenshotsFolder() throws {
        let owner = LocalReportCapability.accountID   // the writer only serves the enabled account
        let text = task(owner: owner, created: "2026-09-14_12-08-59")
        let folder = try folder("2026-09-14_12-08-59", task: text)
        let report = try XCTUnwrap(LocalReportStatusReader.parse(task: text, notes: nil, source: .queued,
                                                                folder: folder, notesURL: nil, accountID: owner))
        let image = NSImage(size: NSSize(width: 2, height: 2))
        image.lockFocus(); NSColor.blue.drawSwatch(in: NSRect(x: 0, y: 0, width: 2, height: 2)); image.unlockFocus()

        let name = try LocalReportImageWriter.save(image, to: report, root: root, accountID: { owner })
        let written = folder.appendingPathComponent("screenshots").appendingPathComponent(name)
        XCTAssertTrue(FileManager.default.fileExists(atPath: written.path))
        XCTAssertEqual(LocalReportStatusReader.screenshotURLs(in: folder).map(\.lastPathComponent), [name],
                       "The list picks it up as one of the report's screenshots")
    }

    func testAnotherAccountCannotWriteAnImageIntoThisReport() throws {
        let owner = LocalReportCapability.accountID
        let text = task(owner: owner, created: "2026-09-14_12-09-59")
        let folder = try folder("2026-09-14_12-09-59", task: text)
        let report = try XCTUnwrap(LocalReportStatusReader.parse(task: text, notes: nil, source: .queued,
                                                                folder: folder, notesURL: nil, accountID: owner))
        let image = NSImage(size: NSSize(width: 2, height: 2))
        image.lockFocus(); NSColor.blue.drawSwatch(in: NSRect(x: 0, y: 0, width: 2, height: 2)); image.unlockFocus()
        XCTAssertThrowsError(try LocalReportImageWriter.save(image, to: report, root: root,
                                                             accountID: { "someone-else" }))
    }

    // MARK: Grouping and rework (reports 2026-09-14_19-49-11 and _20-06-22)

    func testGroupsPutAttentionFirstAndFinishedLast() {
        let order = LocalReportGrouping.order
        XCTAssertEqual(order.first, .reworkNeeded)
        XCTAssertEqual(order.last, .confirmedFixed)
        XCTAssertLessThan(order.firstIndex(of: .readyForQA)!, order.firstIndex(of: .queued)!)
    }

    func testQueuedAndFinishedGroupsStartCollapsed() {
        XCTAssertFalse(LocalReportGrouping.expandedByDefault.contains(.queued))
        XCTAssertFalse(LocalReportGrouping.expandedByDefault.contains(.confirmedFixed))
        XCTAssertTrue(LocalReportGrouping.expandedByDefault.contains(.reworkNeeded))
    }

    func testEmptyGroupsAreNotShown() {
        let text = task(owner: account, created: "2026-09-14_10-00-00")
        let folder = try! folder("2026-09-14_10-00-00", task: text)
        let report = LocalReportStatusReader.parse(task: text, notes: nil, source: .queued, folder: folder,
                                                   notesURL: nil, accountID: account)!
        let groups = LocalReportGrouping.groups([report])
        XCTAssertEqual(groups.map(\.state), [.queued])
    }

    func testFeedbackNewerThanTheNotesMeansReworkNeeded() throws {
        let base = task(owner: account, created: "2026-09-14_11-00-00")
        let withFeedback = base + "\n## Additional instructions\n\n- Added: 2026-09-14T09:00:00Z\n\nstill broken\n"
        let folder = try folder("2026-09-14_11-00-00", task: withFeedback)
        let older = Date(timeIntervalSince1970: 1_757_800_000)   // before the stamp above
        let report = try XCTUnwrap(LocalReportStatusReader.parse(task: withFeedback, notes: "## Status\nQueued",
                                                                 source: .readyForQA, folder: folder, notesURL: nil,
                                                                 accountID: account, notesModified: older))
        XCTAssertEqual(report.state, .reworkNeeded)
    }

    func testFeedbackOlderThanTheNotesLeavesTheStateAlone() throws {
        let base = task(owner: account, created: "2026-09-14_12-00-00")
        let withFeedback = base + "\n## Additional instructions\n\n- Added: 2026-09-14T09:00:00Z\n\nold note\n"
        let folder = try folder("2026-09-14_12-00-00", task: withFeedback)
        let newer = Date(timeIntervalSince1970: 1_800_000_000)   // after the stamp above
        let report = try XCTUnwrap(LocalReportStatusReader.parse(task: withFeedback, notes: nil,
                                                                 source: .readyForQA, folder: folder, notesURL: nil,
                                                                 accountID: account, notesModified: newer))
        XCTAssertEqual(report.state, .readyForQA, "Already answered — not rework")
    }

    // MARK: Filtering by part of the app (report 2026-09-14_22-14-16)

    func testAReportIsFiledUnderTheAreaItTalksAbout() {
        XCTAssertEqual(LocalReportArea.detect(title: "Day plan free time is wrong", notes: nil), .dayPlan)
        XCTAssertEqual(LocalReportArea.detect(title: "Focus session UI looks broken", notes: nil), .focusSession)
        XCTAssertEqual(LocalReportArea.detect(title: "Delete task does nothing", notes: nil), .tasksProjects)
        XCTAssertEqual(LocalReportArea.detect(title: "Something entirely new", notes: nil), .other)
    }

    func testTheNotesCountWhenTheTitleSaysNothingUseful() {
        XCTAssertEqual(LocalReportArea.detect(title: "still seeing this", notes: "The break screen took over"), .routinesBreaks)
    }

    func testOnlyAreasThatExistAreOffered() {
        let reports = [searchable("Day plan capacity"), searchable("Delete task")]
        XCTAssertEqual(LocalReportArea.present(in: reports), [.dayPlan, .tasksProjects])
    }

    func testFilteringKeepsOnlyThatArea() {
        let reports = [searchable("Day plan capacity"), searchable("Delete task")]
        XCTAssertEqual(LocalReportArea.matching(reports, area: .dayPlan).map(\.title), ["Day plan capacity"])
        XCTAssertEqual(LocalReportArea.matching(reports, area: nil).count, 2, "No filter shows everything")
    }

    // MARK: Review notes split into the original note and its updates (report 2026-09-15_22-26-04)

    private func parse(_ notes: String) -> LocalReportNotes { LocalReportNoteParser.parse(notes) }

    func testANoteWithoutUpdatesIsAllOriginalAndHasNoLatest() {
        let notes = parse("# Due date modal\n\nThe sheet closed on its own.\n\n## How to test\n1. Open it.\n")
        XCTAssertEqual(notes.title, "Due date modal")
        XCTAssertEqual(notes.original, "The sheet closed on its own.\n\n## How to test\n1. Open it.")
        XCTAssertTrue(notes.updates.isEmpty)
        XCTAssertNil(notes.latest)
    }

    func testOneUpdateBecomesItsOwnNoteBelowTheOriginal() {
        let notes = parse("# Title\n\nFirst diagnosis.\n\n---\n\n## Update\nIt is built now.\n")
        XCTAssertEqual(notes.original, "First diagnosis.", "The rule separating the notes is not part of either")
        XCTAssertEqual(notes.updates.count, 1)
        XCTAssertEqual(notes.latest?.number, 1)
        XCTAssertEqual(notes.latest?.summary, "", "A bare `## Update` heading adds no words of its own")
        XCTAssertEqual(notes.latest?.body, "It is built now.")
    }

    func testSeveralUpdatesKeepTheirOrderAndTheNewestIsLast() {
        let notes = parse("""
        # Shorten a habit

        Built the first version.

        ## Update
        The button is in the action bar.

        ## Update 2 — type a duration
        You can type a length now.

        ### You can type a length now
        The sheet keeps the preset buttons.

        ## How to test Update 2
        1. Type `1h30`.

        ## Update — 2026-09-15 22:40 — the marker is in the list
        A trimmed habit shows "(shortened)".
        """)
        XCTAssertEqual(notes.updates.map(\.number), [1, 2, 3])
        XCTAssertEqual(notes.updates.map(\.summary), ["", "type a duration", "the marker is in the list"])
        XCTAssertEqual(notes.latest?.lead, "A trimmed habit shows \"(shortened)\".")
        XCTAssertEqual(notes.newestFirst.map(\.number), [3, 2, 1], "The reader shows the newest first")
        // Sub-sections written under an update belong to it, not to the next one.
        let second = notes.updates[1]
        XCTAssertTrue(second.body.contains("### You can type a length now"))
        XCTAssertTrue(second.body.contains("## How to test Update 2"))
        XCTAssertEqual(second.lead, "You can type a length now.", "A row summary stops at the first sub-heading")
    }

    func testAStampedHeadingSurfacesItsMomentAndAnUnstampedOneStillRenders() throws {
        let stamped = parse("## Update — 2026-09-15 22:40 — rendered as cards").latest
        let day = parse("## Update (2026-09-15) — the lightbox sizes itself").latest
        let bare = parse("## Update\nNo date anywhere.").latest
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        XCTAssertEqual(stamped?.date, formatter.date(from: "2026-09-15 22:40"))
        XCTAssertEqual(stamped?.summary, "rendered as cards", "The stamp is shown as a date, not repeated in the words")
        XCTAssertEqual(day?.date, formatter.date(from: "2026-09-15 00:00"))
        XCTAssertEqual(day?.summary, "the lightbox sizes itself")
        XCTAssertNil(bare?.date, "Every note already written is unstamped and must still render")
        XCTAssertEqual(bare?.body, "No date anywhere.")
    }

    func testMalformedAndLookalikeHeadingsAreHandledRatherThanSplitOn() {
        let notes = parse("""
        Original text.

        ##update 2 —  missing its space

        Still the second update's own body.

        ### Update 3 — a sub-heading, not a new note
        Detail.

        ## Updated the parser again
        Prose that only starts with the word.
        """)
        XCTAssertEqual(notes.updates.count, 1, "Only a level-2 `## Update` heading starts a new note")
        XCTAssertEqual(notes.updates.first?.summary, "missing its space")
        XCTAssertTrue(notes.updates.first?.body.contains("### Update 3") == true)
        XCTAssertTrue(notes.updates.first?.body.contains("## Updated the parser again") == true)
        XCTAssertEqual(notes.original, "Original text.")
    }

    func testNotesThatAreNothingButUpdatesStillParse() {
        let notes = parse("## Update\nOnly ever an update.")
        XCTAssertEqual(notes.title, "")
        XCTAssertEqual(notes.original, "")
        XCTAssertEqual(notes.updates.count, 1)
        XCTAssertEqual(parse("").updates.count, 0, "An empty file is not a crash")
        XCTAssertEqual(parse("").original, "")
    }

    func testTheRowSummarisesTheNEWESTUpdateNotTheOldest() throws {
        let notes = "## Update\nThe first diagnosis.\n\n## Update 2 — fixed\nThe second, newer answer.\n"
        let report = try XCTUnwrap(LocalReportStatusReader.parse(task: task(), notes: notes, source: .queued,
            folder: root, notesURL: nil, accountID: account))
        XCTAssertEqual(report.notesExcerpt, "The second, newer answer.")
        XCTAssertEqual(report.latestUpdate?.number, 2)
        XCTAssertEqual(report.latestUpdate?.summary, "fixed")
    }

    func testAReportWithoutUpdatesHasNoLatestUpdateOnItsRow() throws {
        let report = try XCTUnwrap(LocalReportStatusReader.parse(task: task(), notes: "## Next action\nWait for the backend.",
            source: .queued, folder: root, notesURL: nil, accountID: account))
        XCTAssertNil(report.latestUpdate)
        XCTAssertEqual(report.notesExcerpt, "Wait for the backend.")
    }

    // MARK: The wait after "Mark as confirmed fixed" (report 2026-09-15_20-52-29)

    /// A store whose confirmation write and whose rescans are both held open, so the state the row
    /// shows mid-flight can be looked at rather than guessed at.
    private struct HeldConfirmation {
        let store: LocalReportStatusStore
        /// Let the write that is waiting on the queue finish.
        let finishWrite: () -> Void
        /// Answer the newest scan the store asked for.
        let finishScan: () -> Void
        /// How many scans the store has asked for so far.
        let scanCount: () -> Int
    }

    private func heldConfirmation(failing: Bool = false) -> HeldConfirmation {
        let started = DispatchSemaphore(value: 0), mayFinish = DispatchSemaphore(value: 0)
        var scans: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        let store = LocalReportStatusStore(accountID: { self.account },
            loader: { _, _, done in DispatchQueue.main.async { scans.append(done) } },
            confirmer: { _, _, _ in
                started.signal()
                mayFinish.wait()
                if failing { throw LocalReportInstructionError.changed }
            })
        return HeldConfirmation(store: store,
                                finishWrite: { started.wait(); mayFinish.signal() },
                                finishScan: { DispatchQueue.main.async { scans.last?(.success(.init(reports: [], isLimited: false))) } },
                                scanCount: { scans.count })
    }

    /// Spin the main run loop until `condition` holds, so no test depends on how many main-queue
    /// hops a background write happens to take.
    private func waitUntil(_ description: String, _ condition: @escaping () -> Bool) {
        let met = expectation(description: description)
        func check() {
            if condition() { met.fulfill() } else { DispatchQueue.main.async { check() } }
        }
        DispatchQueue.main.async { check() }
        wait(for: [met], timeout: 5)
    }

    private func started(_ held: HeldConfirmation) -> LocalReportStatus {
        held.store.refresh()
        waitUntil("the first scan was asked for") { held.scanCount() == 1 }
        held.finishScan()
        waitUntil("the list is loaded") { !held.store.isLoading }
        return searchable("Due date modal closes")
    }

    private func pending(_ held: HeldConfirmation, _ report: LocalReportStatus) -> Bool {
        held.store.pendingConfirmations.contains(report.id)
    }

    func testTheRowStaysBusyUntilTheRescanThatShowsTheNewStatusHasLanded() {
        let held = heldConfirmation()
        let report = started(held)
        var finished = false
        held.store.setConfirmedFixed(true, for: report) { error in
            XCTAssertNil(error)
            finished = true
        }
        XCTAssertTrue(pending(held, report), "The row is busy from the moment it is clicked")
        held.finishWrite()
        waitUntil("the rescan was asked for") { held.scanCount() == 2 }
        XCTAssertTrue(pending(held, report), "The file is written, but the list still shows the old status")
        XCTAssertFalse(finished, "Nothing has shown the user their click landed yet")
        held.finishScan()
        waitUntil("the row is free again") { !self.pending(held, report) }
        XCTAssertTrue(finished)
    }

    func testASecondClickIsIgnoredWhileTheFirstIsStillInFlight() {
        let held = heldConfirmation()
        let report = started(held)
        var completions = 0
        held.store.setConfirmedFixed(true, for: report) { _ in completions += 1 }
        held.store.setConfirmedFixed(true, for: report) { _ in completions += 1 }
        held.finishWrite()
        waitUntil("the rescan was asked for") { held.scanCount() == 2 }
        held.finishScan()
        waitUntil("the row is free again") { !self.pending(held, report) }
        XCTAssertEqual(completions, 1, "The second click never reached the writer")
        XCTAssertEqual(held.scanCount(), 2, "One click, one rescan")
    }

    func testAFailedConfirmationFreesTheRowImmediatelyAndReportsTheError() {
        let held = heldConfirmation(failing: true)
        let report = started(held)
        var thrown: Error?
        var answered = false
        held.store.setConfirmedFixed(true, for: report) { error in
            thrown = error
            answered = true
        }
        XCTAssertTrue(pending(held, report))
        held.finishWrite()
        waitUntil("the failure came back") { answered }
        XCTAssertFalse(pending(held, report), "A failed write gives the button back so it can be retried")
        XCTAssertNotNil(thrown, "The row can say so instead of looking like nothing happened")
        XCTAssertEqual(held.scanCount(), 1, "A write that failed changed nothing to rescan")
    }

    func testOnlyTheClickedRowWaits() {
        let held = heldConfirmation()
        let clicked = started(held)
        let other = searchable("Day plan capacity")
        held.store.setConfirmedFixed(true, for: clicked)
        XCTAssertTrue(pending(held, clicked))
        XCTAssertFalse(pending(held, other), "One click must not grey out the whole list")
        held.finishWrite()
        waitUntil("the rescan was asked for") { held.scanCount() == 2 }
        held.finishScan()
        waitUntil("the row is free again") { held.store.pendingConfirmations.isEmpty }
    }

    // MARK: A list that cannot latch into "Loading…" (report 2026-09-16_10-25-00)

    /// The list may say "Loading reports…" — and grey out Refresh — only while a scan that can still
    /// change it is running. Each early return in the callback used to leave that flag standing, and
    /// the 15s timer then skipped every later refresh because it believed a scan was still in flight.

    func testAnAccountThatChangesAndChangesBackCannotLeaveTheListLoadingForever() throws {
        try folder("open")
        var completions: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        // The callback's guard sees a different account; by the time it asks again the account is
        // back, so nothing starts a replacement scan and nothing else would ever clear the flag.
        var reads = 0
        let store = LocalReportStatusStore(accountID: { reads += 1; return reads == 2 ? "account-b" : self.account },
                                           loader: { _, _, done in completions.append(done) })
        store.refresh()
        XCTAssertTrue(store.isLoading)
        completions[0](.success(try scan())); drainCallbacks()
        XCTAssertFalse(store.isLoading, "No scan is in flight, so the list must not claim to be loading")
        XCTAssertEqual(completions.count, 1, "Nothing started a replacement scan")
        store.refreshIfIdle()
        XCTAssertEqual(completions.count, 2, "And a later refresh must still be able to start")
    }

    func testTheFlagIsReleasedByTheLoadThatClaimedItAndNoOther() throws {
        try folder("open")
        let snapshot = try scan()
        var completions: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        let store = LocalReportStatusStore(accountID: { self.account }, loader: { _, _, done in completions.append(done) })
        store.refresh()
        store.refresh()
        completions[0](.success(snapshot)); drainCallbacks()
        XCTAssertTrue(store.isLoading, "The superseding scan is still running and still owns the flag")
        completions[1](.success(snapshot)); drainCallbacks()
        XCTAssertFalse(store.isLoading)
        completions[0](.success(snapshot)); drainCallbacks()
        XCTAssertFalse(store.isLoading, "A late loser cannot put the list back into loading")
    }

    func testATimerRefreshReplacesAScanThatNeverCameBack() throws {
        try folder("open")
        let snapshot = try scan()
        var completions: [(Result<LocalReportStatusSnapshot, Error>) -> Void] = []
        let store = LocalReportStatusStore(accountID: { self.account }, loader: { _, _, done in completions.append(done) })
        let start = Date(timeIntervalSince1970: 1_000_000)
        store.refresh(now: start)
        store.refreshIfIdle(now: start.addingTimeInterval(LocalReportStatusStore.abandonedLoadTimeout - 1))
        XCTAssertEqual(completions.count, 1, "A scan that is merely slow is left alone to finish")
        store.refreshIfIdle(now: start.addingTimeInterval(LocalReportStatusStore.abandonedLoadTimeout))
        XCTAssertEqual(completions.count, 2, "A scan this old has been lost; waiting on it is what sticks")
        completions[1](.success(snapshot)); drainCallbacks()
        XCTAssertFalse(store.isLoading)
        XCTAssertEqual(store.reports.count, snapshot.reports.count)
    }

    // MARK: The parsed folders persist across launches (SQLite index)

    private var indexURL: URL { root.appendingPathComponent("index/LocalReportIndex.sqlite") }

    /// A cache as a fresh launch has it: empty memory, the index on disk.
    private func launchedCache() -> LocalReportFolderCache {
        let url = indexURL
        return LocalReportFolderCache(openIndex: { LocalReportIndex(url: url) })
    }

    func testARelaunchReadsNoFolderThatHasNotChanged() throws {
        try folder("2026-09-10_17-51-34", notes: "## Update\nFirst diagnosis.")
        var opened: [String] = []
        let reader = countingReader { opened.append($0) }
        let first = try LocalReportStatusReader.scan(root: root, accountID: account, cache: launchedCache(), files: reader)
        XCTAssertEqual(opened.sorted(), ["CLAUDE-NOTES.md", "TASK.md"])
        opened.removeAll()
        let afterRelaunch = try LocalReportStatusReader.scan(root: root, accountID: account, cache: launchedCache(), files: reader)
        XCTAssertEqual(opened, [], "parsed once, remembered across the relaunch")
        XCTAssertEqual(afterRelaunch.reports.map(\.title), first.reports.map(\.title))
        XCTAssertEqual(afterRelaunch.reports.first?.latestUpdate?.lead, first.reports.first?.latestUpdate?.lead)
    }

    func testAFolderEditedWhileTheAppWasClosedIsReadAgain() throws {
        let url = try folder("2026-09-10_17-51-34", notes: "## Update\nFirst diagnosis.")
        _ = try LocalReportStatusReader.scan(root: root, accountID: account, cache: launchedCache())
        try "## Update\nFirst diagnosis.\n\n## Update — 2026-09-25 10:00 — second\nFixed it.".write(
            to: url.appendingPathComponent("CLAUDE-NOTES.md"), atomically: true, encoding: .utf8)
        try touch(url.appendingPathComponent("CLAUDE-NOTES.md"), Date().addingTimeInterval(60))
        var opened: [String] = []
        let snapshot = try LocalReportStatusReader.scan(root: root, accountID: account, cache: launchedCache(),
                                                        files: countingReader { opened.append($0) })
        XCTAssertTrue(opened.contains("CLAUDE-NOTES.md"))
        XCTAssertEqual(snapshot.reports.first?.latestUpdate?.lead, "Fixed it.")
    }

    func testAMovedFolderIsReadAtItsNewPlaceAndItsOldRowIsDropped() throws {
        let url = try folder("2026-09-10_17-51-34")
        _ = try LocalReportStatusReader.scan(root: root, accountID: account, cache: launchedCache())
        XCTAssertEqual(LocalReportIndex(url: indexURL)?.count, 1)
        let ready = root.appendingPathComponent(LocalReportFolders.readyForQA, isDirectory: true)
        try FileManager.default.createDirectory(at: ready, withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: url, to: ready.appendingPathComponent(url.lastPathComponent))
        let snapshot = try LocalReportStatusReader.scan(root: root, accountID: account, cache: launchedCache())
        XCTAssertEqual(snapshot.reports.first?.state, .readyForQA, "the state of where it now lives")
        XCTAssertEqual(LocalReportIndex(url: indexURL)?.count, 1, "the old path's row is gone")
    }

    func testAnUnreadableIndexLeavesTheListWorking() throws {
        try folder("2026-09-10_17-51-34")
        try FileManager.default.createDirectory(at: indexURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "this is not a database file, only some text".write(to: indexURL, atomically: true, encoding: .utf8)
        XCTAssertNil(LocalReportIndex(url: indexURL))
        XCTAssertEqual(try LocalReportStatusReader.scan(root: root, accountID: account, cache: launchedCache()).reports.count, 1)
    }

    // MARK: Logs leave a report once it is confirmed fixed

    private func reportWithLogs(_ created: String, in location: String? = nil) throws -> (LocalReportStatus, URL) {
        let owner = LocalReportCapability.accountID
        let root = try XCTUnwrap(self.root)
        let parent = location.map { root.appendingPathComponent($0, isDirectory: true) } ?? root
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let url = parent.appendingPathComponent(created, isDirectory: true)
        try FileManager.default.createDirectory(at: url.appendingPathComponent("logs"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: url.appendingPathComponent("screenshots"), withIntermediateDirectories: true)
        try "log".write(to: url.appendingPathComponent("logs/Debug_Logs.txt"), atomically: true, encoding: .utf8)
        try "png".write(to: url.appendingPathComponent("screenshots/shot.png"), atomically: true, encoding: .utf8)
        try task(owner: owner, created: created).write(to: url.appendingPathComponent("TASK.md"), atomically: true, encoding: .utf8)
        let report = try XCTUnwrap(try LocalReportStatusReader.scan(root: root, accountID: owner).reports.first { $0.reportCreated == created })
        return (report, url)
    }

    func testConfirmingAReportFixedRemovesItsLogsButKeepsItsRecord() throws {
        let (report, url) = try reportWithLogs("2026-09-20_09-00-00", in: LocalReportFolders.readyForQA)
        try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root,
                                                            accountID: { LocalReportCapability.accountID })
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.appendingPathComponent("logs").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.appendingPathComponent("screenshots/shot.png").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.appendingPathComponent("TASK.md").path))
    }

    func testRefreshPrunesOnlyReportsStillConfirmedFixed() throws {
        let owner = LocalReportCapability.accountID
        let (fixed, fixedURL) = try reportWithLogs("2026-09-20_09-00-00")
        try LocalReportConfirmationWriter.setConfirmedFixed(true, for: fixed, root: root, accountID: { owner })
        try FileManager.default.createDirectory(at: fixedURL.appendingPathComponent("logs"), withIntermediateDirectories: true)
        let (_, openURL) = try reportWithLogs("2026-09-21_09-00-00")
        let reports = try LocalReportStatusReader.scan(root: root, accountID: owner).reports
        XCTAssertEqual(LocalReportLogPruner.prune(reports, root: root), 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixedURL.appendingPathComponent("logs").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: openURL.appendingPathComponent("logs").path),
                      "an unconfirmed report keeps its logs")
    }

    func testFeedbackAfterConfirmingKeepsTheLogs() throws {
        let owner = LocalReportCapability.accountID, created = "2026-09-20_09-00-00"
        let (report, url) = try reportWithLogs(created)
        try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root, accountID: { owner },
                                                            now: Date(timeIntervalSince1970: 1_790_000_000))
        try FileManager.default.createDirectory(at: url.appendingPathComponent("logs"), withIntermediateDirectories: true)
        let reopened = task(owner: owner, created: created) + "\n## Additional instructions\n\n- Added: 2099-01-01T00:00:00Z\n\nstill broken\n"
        try reopened.write(to: url.appendingPathComponent("TASK.md"), atomically: true, encoding: .utf8)
        let reports = try LocalReportStatusReader.scan(root: root, accountID: owner).reports
        XCTAssertEqual(reports.first?.state, .reworkNeeded)
        XCTAssertEqual(LocalReportLogPruner.prune(reports, root: root), 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.appendingPathComponent("logs").path))
    }

    func testALinkedLogsFolderIsNeverFollowedOrDeleted() throws {
        let owner = LocalReportCapability.accountID
        let (report, url) = try reportWithLogs("2026-09-20_09-00-00")
        let elsewhere = root.appendingPathComponent("elsewhere", isDirectory: true)
        try FileManager.default.createDirectory(at: elsewhere, withIntermediateDirectories: true)
        try FileManager.default.removeItem(at: url.appendingPathComponent("logs"))
        try FileManager.default.createSymbolicLink(at: url.appendingPathComponent("logs"), withDestinationURL: elsewhere)
        try LocalReportConfirmationWriter.setConfirmedFixed(true, for: report, root: root, accountID: { owner })
        XCTAssertTrue(FileManager.default.fileExists(atPath: elsewhere.path))
    }

    // MARK: A report carries the last minutes of log, not the log files

    private static let logStampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = ReportLogExtract.timestampFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    private let reportTime = LocalReportStatusTests.logStampFormatter.date(from: "2026-09-25 10:30:00")!

    private func logLine(minutesBefore minutes: Double, _ text: String) -> String {
        "\(Self.logStampFormatter.string(from: reportTime.addingTimeInterval(-minutes * 60))) - \(text)\n"
    }

    private func logsFolder(current: String, rotated: String? = nil) throws -> URL {
        let folder = root.appendingPathComponent("Logs", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try current.write(to: folder.appendingPathComponent(ReportLogExtract.currentLogName), atomically: true, encoding: .utf8)
        if let rotated = rotated {
            try rotated.write(to: folder.appendingPathComponent(ReportLogExtract.rotatedLogPrefix + "2026-09-25.txt"),
                              atomically: true, encoding: .utf8)
        }
        return folder
    }

    private func extractedText(_ folder: URL) -> String {
        ReportLogExtract.extract(sources: ReportLogExtract.sources(in: folder), reportTime: reportTime).map(\.text).joined()
    }

    func testTheExtractStartsExactlyAtTheWindow() throws {
        let folder = try logsFolder(current: logLine(minutesBefore: 6, "too old") + logLine(minutesBefore: 5, "edge")
                                    + logLine(minutesBefore: 1, "recent"))
        XCTAssertEqual(extractedText(folder), logLine(minutesBefore: 5, "edge") + logLine(minutesBefore: 1, "recent"),
                       "exactly five minutes back is inside; anything older is not")
    }

    func testAnOldEntrysContinuationLinesStayOutWithIt() throws {
        let folder = try logsFolder(current: logLine(minutesBefore: 9, "old") + "  old continuation\n"
                                    + logLine(minutesBefore: 2, "new") + "  new continuation\n")
        XCTAssertEqual(extractedText(folder), logLine(minutesBefore: 2, "new") + "  new continuation\n")
    }

    func testTheExtractCrossesIntoTheRotatedLogWhenTheWindowStartsThere() throws {
        let rotated = logLine(minutesBefore: 8, "before window") + logLine(minutesBefore: 4, "rotated in window")
            + "  continues across the rotation\n"
        let folder = try logsFolder(current: logLine(minutesBefore: 3, "current"), rotated: rotated)
        let portions = ReportLogExtract.extract(sources: ReportLogExtract.sources(in: folder), reportTime: reportTime)
        XCTAssertEqual(portions.map { $0.source.lastPathComponent },
                       [ReportLogExtract.rotatedLogPrefix + "2026-09-25.txt", ReportLogExtract.currentLogName],
                       "oldest first")
        XCTAssertEqual(portions.map(\.text).joined(),
                       logLine(minutesBefore: 4, "rotated in window") + "  continues across the rotation\n"
                       + logLine(minutesBefore: 3, "current"))
        XCTAssertEqual(portions[0].startOffset, UInt64(logLine(minutesBefore: 8, "before window").utf8.count),
                       "SOURCES.md can send an agent back to exactly this byte")
    }

    func testTheRotatedLogIsNotReadWhenTheCurrentOneCoversTheWindow() throws {
        let folder = try logsFolder(current: logLine(minutesBefore: 20, "old") + logLine(minutesBefore: 1, "new"),
                                    rotated: logLine(minutesBefore: 2, "should not appear"))
        XCTAssertEqual(extractedText(folder), logLine(minutesBefore: 1, "new"))
    }

    func testOnlyTheTailOfALongLogIsRead() throws {
        var text = ""
        for index in 0..<20_000 { text += logLine(minutesBefore: 120 - Double(index) * 0.006, "entry \(index) with some padding") }
        let folder = try logsFolder(current: text)
        let log = folder.appendingPathComponent(ReportLogExtract.currentLogName)
        var bytesRead = 0
        var reader = ReportLogExtract.Reader.live
        let read = reader.read
        reader.read = { url, offset, length in
            let data = read(url, offset, length)
            bytesRead += data?.count ?? 0
            return data
        }
        let result = try XCTUnwrap(ReportLogExtract.tail(of: log, since: reportTime.addingTimeInterval(-ReportLogExtract.window), reader: reader))
        XCTAssertFalse(result.wholeFileInWindow)
        XCTAssertLessThan(bytesRead, text.utf8.count / 5, "reads backwards from the end and stops at the window")
    }

    func testEmptyAndMissingLogsExtractNothing() throws {
        let folder = try logsFolder(current: "")
        XCTAssertEqual(extractedText(folder), "")
        XCTAssertNil(ReportLogExtract.tail(of: root.appendingPathComponent("missing.txt"), since: reportTime, reader: .live))
    }

    func testAReportWritesTheExtractAndItsSourcesInsteadOfCopyingLogs() throws {
        let logs = try logsFolder(current: logLine(minutesBefore: 30, "old") + logLine(minutesBefore: 1, "recent"),
                                  rotated: logLine(minutesBefore: 900, "yesterday"))
        let reports = root.appendingPathComponent("reports", isDirectory: true)
        let history = "2026-09-26 09:59:00 blocked focusBlockUnwantedUrl url=\"https://example.org/cb?code=oauth-secret&page=2\"\n"
        let folder = try XCTUnwrap(writeFocusBearClaudeTask(note: "It froze", screenshots: [], root: reports,
                                                            logsFolder: logs, now: reportTime,
                                                            accountID: { LocalReportCapability.accountID },
                                                            browsingHistory: { history }))
        let written = try FileManager.default.contentsOfDirectory(atPath: folder.appendingPathComponent("logs").path).sorted()
        XCTAssertEqual(written, [ReportLogExtract.extractFileName, ReportLogExtract.sourcesFileName,
                                 BrowsingHistory.exportFileName].sorted(),
                       "no log file is copied; the browsing history sits beside the extract")
        let exported = try String(contentsOf: folder.appendingPathComponent("logs/\(BrowsingHistory.exportFileName)"))
        XCTAssertTrue(exported.contains("https://example.org/cb?code="), "the full URL is what the report is for")
        XCTAssertFalse(exported.contains("oauth-secret"), "credentials in a URL are still redacted")
        let extract = try String(contentsOf: folder.appendingPathComponent("logs/\(ReportLogExtract.extractFileName)"))
        XCTAssertEqual(extract, logLine(minutesBefore: 1, "recent"))
        let sources = try String(contentsOf: folder.appendingPathComponent("logs/\(ReportLogExtract.sourcesFileName)"))
        XCTAssertTrue(sources.contains(logs.path), "points back to the real Logs folder")
        XCTAssertTrue(sources.contains(BrowsingHistory.exportFileName), "SOURCES.md lists the browsing history")
        let task = try String(contentsOf: folder.appendingPathComponent("TASK.md"))
        XCTAssertTrue(task.contains("logs/\(ReportLogExtract.extractFileName)"))
        XCTAssertTrue(task.contains("logs/\(ReportLogExtract.sourcesFileName)"))
        XCTAssertTrue(task.contains("logs/\(BrowsingHistory.exportFileName)"))
    }

    // MARK: How many rows an open group draws (Sentry FOCUS-BEAR-MACOS-1K7)

    func testAnOpenGroupDrawsOnlyTheFirstRowsUntilAskedForAll() {
        let rows = Array(1...57)
        let capped = LocalReportGrouping.visible(rows, showingAll: false, limit: 20)
        XCTAssertEqual(capped.rows, Array(1...20), "newest first, exactly the limit")
        XCTAssertEqual(capped.hiddenCount, 37)
        let all = LocalReportGrouping.visible(rows, showingAll: true, limit: 20)
        XCTAssertEqual(all.rows.count, 57)
        XCTAssertEqual(all.hiddenCount, 0)
    }

    func testAGroupAtOrUnderTheLimitOffersNothingMore() {
        XCTAssertEqual(LocalReportGrouping.visible(Array(1...20), showingAll: false, limit: 20).hiddenCount, 0)
        XCTAssertEqual(LocalReportGrouping.visible([Int](), showingAll: false, limit: 20).rows, [])
    }

    func testTheShowAllLinkHasWordsAndACount() {
        XCTAssertTrue(LocalReportStatusStrings()["showAllReports"].contains("<COUNT>"))
    }

    // MARK: Re-reading only the folders that changed

    /// A `LocalReportFileReader` that records the name of every file whose text a scan actually reads.
    private func countingReader(into opened: @escaping (String) -> Void) -> LocalReportFileReader {
        var reader = LocalReportFileReader.live
        let live = reader.text
        reader.text = { url in
            opened(url.lastPathComponent)
            return live(url)
        }
        return reader
    }

    private func touch(_ url: URL, _ date: Date) throws {
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    }

    func testAnUnchangedFolderIsNotReadAgainOnTheNextScan() throws {
        try folder("2026-09-10_17-51-34", notes: "## Update\nFirst diagnosis.")
        let cache = LocalReportFolderCache()
        var opened: [String] = []
        let reader = countingReader { opened.append($0) }
        let first = try LocalReportStatusReader.scan(root: root, accountID: account, cache: cache, files: reader)
        XCTAssertEqual(first.reports.count, 1)
        XCTAssertEqual(opened.sorted(), ["CLAUDE-NOTES.md", "TASK.md"])
        opened.removeAll()
        let second = try LocalReportStatusReader.scan(root: root, accountID: account, cache: cache, files: reader)
        XCTAssertTrue(opened.isEmpty, "A folder nothing has touched must cost stats, not reads: \(opened)")
        XCTAssertEqual(second.reports.first?.notesExcerpt, first.reports.first?.notesExcerpt)
        XCTAssertEqual(second.reports.first?.state, first.reports.first?.state)
        XCTAssertEqual(second.reports.first?.latestUpdate?.lead, "First diagnosis.")
    }

    func testChangedNotesAreReadAgainAndTheExcerptFollowsThem() throws {
        let directory = try folder("2026-09-10_17-51-34", notes: "## Update\nFirst diagnosis.")
        let cache = LocalReportFolderCache()
        var opened: [String] = []
        let reader = countingReader { opened.append($0) }
        _ = try LocalReportStatusReader.scan(root: root, accountID: account, cache: cache, files: reader)
        opened.removeAll()
        let notes = directory.appendingPathComponent("CLAUDE-NOTES.md")
        try "## Update\nFirst diagnosis.\n\n## Update — 2026-09-16 10:25 — retested\nThe second look.".write(
            to: notes, atomically: true, encoding: .utf8)
        try touch(notes, Date(timeIntervalSince1970: 1_800_000_000))
        let report = try XCTUnwrap(LocalReportStatusReader.scan(root: root, accountID: account, cache: cache,
                                                               files: reader).reports.first)
        XCTAssertEqual(opened.sorted(), ["CLAUDE-NOTES.md", "TASK.md"], "Its stamp moved, so it is read again")
        XCTAssertEqual(report.notesExcerpt, "The second look.")
        XCTAssertEqual(report.latestUpdate?.summary, "retested")
    }

    func testNewInstructionsInTaskStillFlipAReportToReworkNeeded() throws {
        let directory = try folder("\(LocalReportFolders.readyForQA)/2026-09-10_17-51-34", notes: "Reviewed and fixed.")
        let cache = LocalReportFolderCache()
        var opened: [String] = []
        let reader = countingReader { opened.append($0) }
        let before = try XCTUnwrap(LocalReportStatusReader.scan(root: root, accountID: account, cache: cache,
                                                               files: reader).reports.first)
        XCTAssertEqual(before.state, .readyForQA)
        opened.removeAll()
        let taskURL = directory.appendingPathComponent("TASK.md")
        try (task() + "\n## Additional instructions\n\n- Added: 2030-01-01T09:00:00Z\n\nStill broken.\n")
            .write(to: taskURL, atomically: true, encoding: .utf8)
        try touch(taskURL, Date(timeIntervalSince1970: 1_800_000_000))
        let after = try XCTUnwrap(LocalReportStatusReader.scan(root: root, accountID: account, cache: cache,
                                                              files: reader).reports.first)
        XCTAssertTrue(opened.contains("TASK.md"), "A changed TASK.md is read again")
        XCTAssertEqual(after.state, .reworkNeeded)
        XCTAssertEqual(after.latestInstructions, "Still broken.")
    }

    func testAFolderMovedBetweenStateFoldersIsNotServedFromItsOldEntry() throws {
        let name = "2026-09-10_17-51-34"
        let directory = try folder("\(LocalReportFolders.readyForQA)/\(name)", notes: "Reviewed and fixed.")
        let shots = directory.appendingPathComponent(LocalReportStatusReader.screenshotsFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: shots, withIntermediateDirectories: true)
        try Data([0x89]).write(to: shots.appendingPathComponent("evidence.png"))
        let cache = LocalReportFolderCache()
        let reader = countingReader { _ in }
        let before = try XCTUnwrap(LocalReportStatusReader.scan(root: root, accountID: account, cache: cache,
                                                               files: reader).reports.first)
        XCTAssertEqual(before.state, .readyForQA)
        XCTAssertEqual(cache.count, 1)
        // The reviewer moves it back to the top level, which this workflow does constantly.
        let moved = root.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.moveItem(at: directory, to: moved)
        let after = try XCTUnwrap(LocalReportStatusReader.scan(root: root, accountID: account, cache: cache,
                                                              files: reader).reports.first)
        XCTAssertEqual(after.state, .queued, "It must show where it is now, not where it was")
        XCTAssertEqual(after.id, moved.standardizedFileURL.path)
        XCTAssertEqual(after.screenshotURLs.map { $0.deletingLastPathComponent().standardizedFileURL.path },
                       [moved.appendingPathComponent(LocalReportStatusReader.screenshotsFolderName).standardizedFileURL.path],
                       "Screenshot paths cached under the old location no longer exist")
        XCTAssertEqual(cache.count, 1, "The entry for the folder that is gone is dropped, not kept forever")
    }

    // Report 2026-09-16_20-26-48: "I left feedback on this issue that I had marked as fixed. It
    // should have gone back to Rework needed." Confirming used to be final. It is not — a
    // confirmation is simply another dated event the feedback has to beat, alongside the notes.
    //
    // Dates are injected rather than round-tripped through the filesystem, like the sibling rework
    // tests above: in a real report the notes were written well before the feedback, and a fixture
    // whose files are all stamped "now" cannot express that ordering at all.

    /// Builds the confirmation file the way the app does, via the real model, so the decode guards
    /// (schema version, account, report id) are exercised rather than bypassed by handwritten JSON.
    /// Built via the real model so the decode guards (schema version, account, report id) are
    /// exercised rather than bypassed. Note the owner must be `LocalReportCapability.accountID`:
    /// `decode` refuses a confirmation for any other account, so the fixture account these sibling
    /// tests use would silently produce `nil` and the status would read as never confirmed.
    private func confirmation(_ confirmedFixed: Bool, at updatedAt: String, created: String) throws -> Data {
        try JSONEncoder().encode(LocalReportUserStatus(schemaVersion: 1, accountID: LocalReportCapability.accountID,
                                                       reportCreated: created, confirmedFixed: confirmedFixed,
                                                       updatedAt: updatedAt))
    }

    func testFeedbackLeftAfterConfirmingReopensTheReportForRework() throws {
        let owner = LocalReportCapability.accountID, created = "2026-09-14_11-00-00"
        let withFeedback = task(owner: owner, created: created)
            + "\n## Additional instructions\n\n- Added: 2026-09-14T12:00:00Z\n\nstill broken\n"
        let folder = try folder(created, task: withFeedback)
        let report = try XCTUnwrap(LocalReportStatusReader.parse(
            task: withFeedback, notes: "## Status\nFixed", source: .readyForQA, folder: folder, notesURL: nil,
            accountID: owner,
            userStatusData: try confirmation(true, at: "2026-09-14T10:00:00Z", created: created),
            notesModified: Date(timeIntervalSince1970: 1_757_800_000)))
        XCTAssertEqual(report.userStatus?.confirmedFixed, true, "fixture must actually decode, or this proves nothing")
        XCTAssertEqual(report.state, .reworkNeeded,
                       "feedback on a report you marked fixed is how you say it is not fixed")
    }

    func testConfirmingAfterFeedbackStaysFixedRatherThanBouncingBackToRework() throws {
        let owner = LocalReportCapability.accountID, created = "2026-09-14_11-00-00"
        let withFeedback = task(owner: owner, created: created)
            + "\n## Additional instructions\n\n- Added: 2026-09-14T12:00:00Z\n\none more thing\n"
        let folder = try folder(created, task: withFeedback)
        let report = try XCTUnwrap(LocalReportStatusReader.parse(
            task: withFeedback, notes: "## Status\nFixed", source: .readyForQA, folder: folder, notesURL: nil,
            accountID: owner,
            userStatusData: try confirmation(true, at: "2026-09-14T13:00:00Z", created: created),
            notesModified: Date(timeIntervalSince1970: 1_757_800_000)))
        XCTAssertEqual(report.userStatus?.confirmedFixed, true, "fixture must actually decode, or this proves nothing")
        XCTAssertEqual(report.state, .confirmedFixed,
                       "confirming with the feedback in front of you answers it — otherwise it could never be closed")
    }

    // MARK: "Last update from AI" (report 2026-09-17_06-23-46)

    /// A fixed locale and time zone, so the assertions below are about the rule, not about whatever
    /// the machine running them happens to be set to.
    private func ageFormatter() -> LocalReportUpdateAgeFormatter {
        LocalReportUpdateAgeFormatter(locale: Locale(identifier: "en_US"),
                                      timeZone: TimeZone(identifier: "Australia/Melbourne")!)
    }
    /// ICU separates the time from AM/PM with a narrow no-break space, and has changed which
    /// invisible character it uses between OS releases. The assertions below are about wording, so
    /// every kind of space is compared as a plain one.
    private func spacing(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{202f}", with: " ").replacingOccurrences(of: "\u{00a0}", with: " ")
    }
    private func ageReference() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Melbourne")!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: 17, hour: 6, minute: 30))!
    }

    func testMinutesAndHoursReadAsMinutesAndHours() {
        let now = ageReference(), formatter = ageFormatter()
        XCTAssertEqual(formatter.describe(now.addingTimeInterval(-5 * 60), now: now)?.relative, "5m ago")
        XCTAssertEqual(formatter.describe(now.addingTimeInterval(-2 * 3600), now: now)?.relative, "2h ago")
    }

    func testYesterdayIsNamedRatherThanDated() throws {
        let formatter = ageFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Melbourne")!
        // DateFormatter's relative labels use the system clock, not describe's injected `now`.
        // Anchor this integration assertion to today so it still means yesterday tomorrow.
        let today = calendar.startOfDay(for: Date())
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let lastNight = try XCTUnwrap(calendar.date(bySettingHour: 20, minute: 30, second: 0,
                                                  of: yesterday))
        let now = lastNight.addingTimeInterval(10 * 3600)
        let age = try XCTUnwrap(formatter.describe(lastNight, now: now))
        XCTAssertEqual(spacing(age.absolute), "Yesterday at 8:30 PM")
        XCTAssertEqual(age.relative, "10h ago")
        XCTAssertEqual(spacing(age.combined), "10h ago \u{00b7} Yesterday at 8:30 PM",
                       "both halves on one row: the glance and the exact moment")
    }

    func testSeveralDaysAgoKeepsBothHalvesUseful() throws {
        let now = ageReference(), formatter = ageFormatter()
        let age = try XCTUnwrap(formatter.describe(now.addingTimeInterval(-3 * 86_400), now: now))
        XCTAssertEqual(age.relative, "3d ago")
        XCTAssertEqual(spacing(age.absolute), "Sep 14, 2026 at 6:30 AM",
                       "past yesterday the exact date is the only unambiguous half")
    }

    /// The whole point of leaning on the system formatter: it rolls units up on its own.
    func testAVeryOldUpdateRollsUpToYearsInsteadOfCountingDays() throws {
        let now = ageReference(), formatter = ageFormatter()
        let age = try XCTUnwrap(formatter.describe(now.addingTimeInterval(-400 * 86_400), now: now))
        XCTAssertEqual(age.relative, "1y ago")
        XCTAssertFalse(age.relative.contains("400"))
    }

    func testAnUpdateInsideTheLastMinuteReadsAsNowRatherThanZeroSeconds() throws {
        let now = ageReference(), formatter = ageFormatter()
        for seconds in [0.0, 5, 59] {
            let age = try XCTUnwrap(formatter.describe(now.addingTimeInterval(-seconds), now: now))
            XCTAssertEqual(age.relative, "now", "\(seconds)s ago should not be counted in seconds")
        }
    }

    /// A notes file stamped by a clock running slightly ahead of ours must not say "in 3m".
    func testAFutureStampReadsAsNowRatherThanCountingForwards() throws {
        let now = ageReference(), formatter = ageFormatter()
        let age = try XCTUnwrap(formatter.describe(now.addingTimeInterval(180), now: now))
        XCTAssertEqual(age.relative, "now")
    }

    func testAReportWithNoNotesHasNoLastUpdateAtAll() {
        XCTAssertNil(ageFormatter().describe(nil, now: ageReference()))
    }

    func testTheNewestNotesFileModificationDateIsWhatTheRowShows() throws {
        let created = "2026-09-14_11-00-00"
        let folder = try folder(created, task: task(owner: account, created: created))
        let written = Date(timeIntervalSince1970: 1_757_800_000)
        let report = try XCTUnwrap(LocalReportStatusReader.parse(
            task: task(owner: account, created: created), notes: "## Status\nInvestigating", source: .queued,
            folder: folder, notesURL: nil, accountID: account, notesModified: written))
        XCTAssertEqual(report.lastAIUpdate, written)
    }

    func testAScannedReportWithoutNotesCarriesNoLastUpdate() throws {
        let created = "2026-09-14_12-00-00"
        try folder(created, task: task(owner: account, created: created))
        let report = try XCTUnwrap(try scan(account).reports.first)
        XCTAssertNil(report.lastAIUpdate)
    }

    func testScanningAReportWithNotesReadsTheNotesFileModificationDate() throws {
        let created = "2026-09-14_13-00-00"
        let url = try folder(created, task: task(owner: account, created: created), notes: "## Status\nInvestigating")
        let stamped = Date(timeIntervalSince1970: 1_757_800_000)
        try FileManager.default.setAttributes([.modificationDate: stamped],
                                              ofItemAtPath: url.appendingPathComponent("CLAUDE-NOTES.md").path)
        let report = try XCTUnwrap(try scan(account).reports.first)
        XCTAssertEqual(report.lastAIUpdate?.timeIntervalSince1970 ?? 0, stamped.timeIntervalSince1970, accuracy: 1)
    }
}
