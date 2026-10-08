//
//  RegressionToolsUITests.swift
//  Focus BearUITests
//
//  Regression suite: Tools. Runs in the Regression test plan; the critical path is in Smoke.
//
//  Several tools reach outside the app — the Time Tracker and Late No More apps, a Focus Button on
//  USB, every browser's tabs, the support queue. Those controls are checked for being offered and
//  never pressed.
//

import AppKit
import XCTest

final class RegressionToolsUITests: FocusBearUITestCase {
    private typealias Tools = UITestContract.Identifier.Tools
    private typealias Notes = UITestContract.Identifier.Notes
    private typealias Regression = UITestContract.Identifier.OnboardingRegression
    private typealias Help = UITestContract.Identifier.Help

    /// `ToolID.stats.rawValue` (leftMenu/ToolVisibilityStore.swift), which names its Restore button.
    private static let statsToolId = "stats"
    /// Matched the way the app's own ExternalToolModel spots the Time Tracker running.
    private static let timeTrackerAppName = "focus bear time tracker"
    /// Neither a Spotify nor a YouTube Music link.
    private static let notAMusicLink = "https://example.com/not-music"

    // MARK: - Notes

    func testNoteCanBeRenamed() throws {
        try openNotes()
        let title = uniqueTitle("UI test note")
        let renamed = uniqueTitle("UI test renamed note")
        let row = createNote(titled: title)

        tap(row.descendants(matching: .any).matching(identifier: Regression.noteEditButton).firstMatch)
        let titleField = app.textFields[Notes.editorTitleField]
        XCTAssertTrue(appears(titleField), "Edit doesn't open the note")
        XCTAssertEqual(titleField.value as? String, title, "the editor opened a different note")
        tap(titleField)
        press("a", modifiers: .command)
        typeIntoFocus(renamed)
        tap(element(Notes.editorSaveButton))

        let renamedRow = noteRow(titled: renamed)
        XCTAssertTrue(appears(renamedRow, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the renamed note isn't listed")
        XCTAssertTrue(waitForNonExistence(of: noteRow(titled: title)), "the old title is still listed")
        deleteNote(renamedRow)
    }

    func testNoteIsStillThereAfterARelaunch() throws {
        try openNotes()
        let title = uniqueTitle("UI test lasting note")
        _ = createNote(titled: title)
        app.terminate()

        try openNotes()
        let row = noteRow(titled: title)
        XCTAssertTrue(appears(row, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the note didn't survive a relaunch")
        deleteNote(row)
    }

    func testNoteEditorNeedsATitleAndCancelSavesNothing() throws {
        try openNotes()
        tap(element(Notes.newNoteButton))
        let titleField = app.textFields[Notes.editorTitleField]
        let save = element(Notes.editorSaveButton)
        XCTAssertTrue(appears(titleField), "the note editor didn't open")
        XCTAssertFalse(save.isEnabled, "a note without a title can be saved")

        let title = uniqueTitle("UI test cancelled note")
        tap(titleField)
        typeIntoFocus(title)
        XCTAssertTrue(waitForEnabled(save), "a titled note can't be saved")
        tap(element(Regression.noteEditorCancelButton))
        XCTAssertTrue(waitForNonExistence(of: titleField), "Cancel doesn't close the note editor")
        XCTAssertFalse(appears(noteRow(titled: title), within: Self.optionalWait), "a cancelled note was saved")
    }

    // MARK: - Stats

    /// Each tab ends up showing its data (a card, chart or table) or an empty state — never stuck
    /// loading and never the load-failed message.
    func testEveryStatsTabLoadsIntoContentOrAnEmptyState() throws {
        try launchSignedIn()
        try open(tool: Tools.stats)
        let tabs = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", UITestContract.Identifier.Stats.tabPrefix))
        XCTAssertTrue(appears(tabs.firstMatch), "Stats shows no tabs")
        let failed = element(Regression.statsError)
        let outcomes = [Regression.statsCard, Regression.statsChart, Regression.statsTable, Regression.statsEmptyState]
            .map { element($0) } + [failed]
        for index in 0..<tabs.count {
            let tab = tabs.element(boundBy: index)
            let name = tab.identifier
            tap(tab)
            XCTAssertNotNil(firstToAppear(outcomes, timeout: Self.apiRoundTripTimeout), "\(name) never finished loading")
            XCTAssertFalse(failed.exists, "\(name) couldn't load its data")
            attachScreenshot(named: name)
        }
    }

    // MARK: - Focus Music

    /// Played and stopped straight away: the check is that playback starts and stops.
    func testFocusMusicTrackPlaysAndStops() throws {
        try launchSignedIn()
        try open(tool: Tools.focusMusic)
        let play = try playButtonOfADownloadedTrack()
        tap(play)
        let nowPlaying = element(Regression.musicNowPlaying)
        XCTAssertTrue(appears(nowPlaying), "playing a track shows nothing as now playing")
        tap(element(Regression.musicNowPlayingStopButton))
        XCTAssertTrue(waitForNonExistence(of: nowPlaying), "stopping leaves the track playing")
    }

    func testAddingYourOwnMusicRejectsLinksThatAreNotMusic() throws {
        try launchSignedIn()
        try open(tool: Tools.focusMusic)
        tap(element(Regression.musicAddOwnButton))
        let sources = [(field: Regression.musicSpotifyField, add: Regression.musicSpotifyAddButton, error: Regression.musicSpotifyError),
                       (field: Regression.musicYouTubeField, add: Regression.musicYouTubeAddButton, error: Regression.musicYouTubeError)]
        for source in sources {
            let field = element(source.field)
            XCTAssertTrue(appears(field), "\(source.field) is missing")
            tap(field)
            typeIntoFocus(Self.notAMusicLink)
            tap(element(source.add))
            XCTAssertTrue(appears(element(source.error)), "\(source.field) took a link that isn't music")
        }
    }

    // MARK: - Tools that reach outside the app

    /// The UI-test build never talks to a Focus Button, so Connect is offered and never pressed.
    func testFocusButtonToolExplainsHowToConnect() throws {
        try launchSignedIn()
        try open(tool: Tools.focusButton)
        XCTAssertTrue(appears(element(Regression.focusButtonStatus)), "the Focus Button tool shows no connection status")
        let connect = element(Regression.focusButtonConnectButton)
        XCTAssertTrue(connect.exists, "the Focus Button tool offers no way to connect")
        XCTAssertTrue(connect.isEnabled, "Connect is disabled")
        XCTAssertTrue(element(Regression.focusButtonShopLink).exists, "no way to get a Focus Button")
    }

    /// Whichever screen the account and Mac call for — upgrade, download or today's summary — has the
    /// enable switch. The switch can launch the Time Tracker, the user's own app, so it is never flipped.
    func testTimeTrackerToolOpensWithoutStartingTheTimeTracker() throws {
        try launchSignedIn()
        let runningBefore = Self.runningTimeTrackerCount()
        try open(tool: Regression.timeTrackerMenuItem)
        XCTAssertTrue(appears(element(Regression.timeTrackerEnableToggle)), "the Time Tracker tool has no enable switch")
        XCTAssertLessThanOrEqual(Self.runningTimeTrackerCount(), runningBefore, "opening the tool started the Time Tracker")
    }

    /// Open / Download is offered, never pressed: it opens the app or its download page.
    func testLateNoMoreToolOffersTheApp() throws {
        try launchSignedIn()
        try open(tool: Regression.lateNoMoreMenuItem)
        XCTAssertTrue(appears(element(Regression.externalToolStatus)), "Late No More shows no install status")
        XCTAssertTrue(element(Regression.externalToolPrimaryButton).exists, "Late No More offers no way to get it")
    }

    /// Extract is offered, never pressed: it reads every browser's open tabs.
    func testTabAuditToolOffersTheAudit() throws {
        try launchSignedIn()
        try open(tool: Regression.tabAuditMenuItem)
        XCTAssertTrue(appears(element(Regression.tabAuditExtractButton)), "Tab Audit offers no audit")
    }

    // MARK: - Help & Support

    func testEveryHelpTabOpens() throws {
        try launchSignedIn()
        let tabs = openHelpTabs()
        XCTAssertGreaterThan(tabs.count, 1, "Help has no tabs to choose between")
        for tab in tabs {
            tap(tab)
            XCTAssertEqual(tab.value as? Int, 1, "a Help tab doesn't open when chosen")
        }
    }

    /// Send is checked for being enabled, never pressed: a sent report reaches the support queue (or,
    /// for the developer, the local task queue).
    func testReportProblemSendWaitsForADescription() throws {
        try launchSignedIn()
        let report = element(Help.reportProblemText)
        for tab in openHelpTabs() where !report.isHittable {
            tap(tab)
            _ = appears(report, within: Self.optionalWait)
        }
        XCTAssertTrue(report.isHittable, "no Help tab holds the report form")
        let send = element(Regression.reportProblemSendButton)
        XCTAssertTrue(send.exists, "the report form has no Send")
        XCTAssertFalse(send.isEnabled, "an empty report can be sent")

        tap(report)
        typeIntoFocus(uniqueTitle("UI test description"))
        XCTAssertTrue(waitForEnabled(send), "a described problem can't be sent")
        press("a", modifiers: .command)
        press(.delete)
        XCTAssertTrue(waitUntilDisabled(send), "clearing the description leaves Send enabled")
    }

    // MARK: - Hiding tools

    /// Clicking a row leaves the pointer on it, which is what shows its ✕. Hidden tools are kept in the
    /// test app's own preferences, which every launch resets.
    func testAToolCanBeHiddenAndRestored() throws {
        try launchSignedIn()
        let stats = app.buttons[Tools.stats]
        if !stats.exists { expandToolsSection() }
        XCTAssertTrue(appears(stats), "Stats isn't in the sidebar")
        // The ✕ shows under the pointer, so this click has to move it there.
        clickWithPointer(stats)
        let hide = element(Regression.hideToolButton)
        XCTAssertTrue(appears(hide), "the tool under the pointer shows no ✕")
        tap(hide)
        XCTAssertTrue(waitForNonExistence(of: stats), "the hidden tool is still in the sidebar")

        tap(element(Regression.hiddenToolsButton))
        let restore = element(Regression.restoreToolPrefix + Self.statsToolId)
        XCTAssertTrue(appears(restore), "the TOOLS gear doesn't list the hidden tool")
        tap(restore)
        XCTAssertTrue(appears(stats), "the restored tool isn't back in the sidebar")
    }

    // MARK: - Helpers

    private func openNotes() throws {
        try launchSignedIn()
        try open(tool: Tools.notes)
    }

    private func noteRow(titled title: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: Notes.row).containing(showing(title)).firstMatch
    }

    private func createNote(titled title: String) -> XCUIElement {
        tap(element(Notes.newNoteButton))
        let titleField = app.textFields[Notes.editorTitleField]
        XCTAssertTrue(appears(titleField), "the note editor didn't open")
        tap(titleField)
        typeIntoFocus(title)
        tap(element(Notes.editorSaveButton))
        let row = noteRow(titled: title)
        XCTAssertTrue(appears(row, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the saved note isn't listed")
        return row
    }

    private func deleteNote(_ row: XCUIElement) {
        tap(row.descendants(matching: .any).matching(identifier: Notes.deleteButton).firstMatch)
        confirmDestructiveAlert()
        XCTAssertTrue(waitForNonExistence(of: row), "the deleted note is still listed")
    }

    /// A library track's play button, downloading the first track if none is on this Mac yet. The
    /// download lands in the test app's Application Support, which later runs keep.
    private func playButtonOfADownloadedTrack() throws -> XCUIElement {
        let plays = matching(prefix: Regression.musicTrackPlayPrefix)
        let downloads = matching(prefix: Regression.musicTrackDownloadPrefix)
        // The library comes from the API with the rest of the account's settings.
        guard firstToAppear([plays.firstMatch, downloads.firstMatch], timeout: Self.apiRoundTripTimeout) != nil else {
            throw SetupError(description: "the focus music library lists no tracks")
        }
        if plays.firstMatch.exists { return plays.firstMatch }
        let download = downloads.firstMatch
        let trackIndex = String(download.identifier.dropFirst(Regression.musicTrackDownloadPrefix.count))
        tap(download)
        let play = element(Regression.musicTrackPlayPrefix + trackIndex)
        guard appears(play, within: Self.apiRoundTripTimeout, waitsOnNetwork: true) else {
            throw XCTSkip("No focus music track was downloaded yet, and the first is still downloading; it stays downloaded for the next run.")
        }
        return play
    }

    private func matching(prefix: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
    }

    /// AppKit exposes a tab view's tabs as radio buttons or as tabs, depending on its style.
    private func openHelpTabs() -> [XCUIElement] {
        open(menuItem: UITestContract.Identifier.Menu.help, expectingAnyOf: element(Help.tabView))
        let tabView = element(Help.tabView)
        return tabView.radioButtons.allElementsBoundByIndex + tabView.descendants(matching: .tab).allElementsBoundByIndex
    }

    private func waitUntilDisabled(_ element: XCUIElement) -> Bool {
        wait(for: element, toMatch: "isEnabled == false", timeout: Self.screenTimeout)
    }

    private static func runningTimeTrackerCount() -> Int {
        NSWorkspace.shared.runningApplications
            .filter { ($0.localizedName ?? "").lowercased().contains(timeTrackerAppName) }
            .count
    }
}
