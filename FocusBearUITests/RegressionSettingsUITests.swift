//
//  RegressionSettingsUITests.swift
//  Focus BearUITests
//
//  Regression suite: Settings. Runs in the Regression test plan; the critical path is in Smoke.
//
//  Settings sync to the test account's server profile, so every test puts back what it changes
//  (`restoreAfterTest`), and the ones that check persistence relaunch the app: a launch resets the
//  test app's local settings (`--uiTestReset`), so whatever comes back came from the server.
//

import AppKit
import XCTest

/// Shared steps for the Settings, blocking and menu-bar regression suites. A base class rather than
/// an extension of FocusBearUITestCase, so these helper names can never collide with another area's.
class SettingsAreaUITestCase: FocusBearUITestCase {
    typealias Area = UITestContract.Identifier.SettingsRegression
    typealias Settings = UITestContract.Identifier.Settings
    typealias Blocking = UITestContract.Identifier.Blocking
    typealias Menu = UITestContract.Identifier.Menu

    /// Settings upload when the Settings screen closes (`settingsSplitViewController.viewWillDisappear`),
    /// and block lists and schedules as they are saved. Nothing on screen says an upload finished, so
    /// a step that quits or relaunches the app first gives it time for one. The app log shows these
    /// uploads answered within the second they were sent; the full eight-second allowance for a slow
    /// response, spent on every upload, was several minutes of a Regression run.
    static let uploadWait: TimeInterval = 2

    private var restorations: [() -> Void] = []

    // MARK: Putting the account back

    /// Queues `restore` to put a setting back once the test ends, pass or fail. The queue runs last in,
    /// first out, with Settings open (relaunching the app if the test left it closed); then Settings
    /// closes so the restored values upload.
    func restoreAfterTest(_ restore: @escaping () -> Void) {
        if restorations.isEmpty {
            addTeardownBlock { [weak self] in self?.runRestorations() }
        }
        restorations.append(restore)
    }

    private func runRestorations() {
        guard !restorations.isEmpty else { return }
        if app.state == .notRunning, (try? launchSignedIn()) == nil {
            return XCTFail("couldn't relaunch the app to restore the test account's settings")
        }
        closeStraySheets()
        openSettings()
        for restore in restorations.reversed() { restore() }
        restorations.removeAll()
        closeSettingsSoTheyUpload()
    }

    /// A test that failed with a sheet up (a file picker, an alert) would block every step after it.
    func closeStraySheets() {
        for sheet in app.sheets.allElementsBoundByIndex where sheet.exists {
            press(.escape)
            _ = waitForNonExistence(of: sheet, timeout: Self.optionalWait)
        }
    }

    // MARK: Settings navigation

    func openSettings() {
        open(menuItem: Menu.settings, expectingAnyOf: element(Settings.appearanceTab))
    }

    func launchIntoSettings() throws {
        try launchSignedIn()
        openSettings()
    }

    /// Opens a sidebar pane. A row that is already selected doesn't reopen its pane when clicked (the
    /// table only reports a changed selection), so from one of its sub-pages the test detours via
    /// another row. Skips when the pane isn't in the sidebar in the account's current mode.
    @discardableResult
    func openPane(_ paneId: String) throws -> XCUIElement {
        let tab = element(Settings.tabPrefix + paneId)
        guard appears(tab) else {
            throw XCTSkip("The \(paneId) pane isn't in the settings sidebar for the test account's mode.")
        }
        tapSettingsTab(paneId)
        let pane = element(Settings.panePrefix + paneId)
        if !appears(pane, within: Self.optionalWait) {
            let detour = paneId == Settings.Pane.ui ? Settings.Pane.account : Settings.Pane.ui
            tapSettingsTab(detour)
            tapSettingsTab(paneId)
        }
        XCTAssertTrue(appears(pane), "the \(paneId) pane didn't open")
        return pane
    }

    /// Leaves Settings for the Day Plan, which uploads what changed, and gives the upload its round trip.
    func closeSettingsSoTheyUpload() {
        tap(app.buttons[Menu.dayPlan])
        waitForUpload()
    }

    func waitForUpload() {
        RunLoop.current.run(until: Date().addingTimeInterval(Self.uploadWait))
    }

    /// Polls `condition` for up to a screen's worth of time — for state no single element's existence shows.
    func waitUntil(_ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(Self.screenTimeout)
        while !condition(), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(Self.optionalWait / 4))
        }
    }

    /// Uploads, quits and comes back with Settings open — everything shown after this came from the server.
    func relaunchIntoSettings() throws {
        closeSettingsSoTheyUpload()
        app.terminate()
        try launchIntoSettings()
    }

    // MARK: Geek and Simple mode

    private var geekModeSegments: [XCUIElement] {
        let control = element(Area.geekModeControl)
        let segments = control.radioButtons.allElementsBoundByIndex + control.buttons.allElementsBoundByIndex
        return segments.filter(\.exists).sorted { $0.frame.minX < $1.frame.minX }
    }

    /// Segment 0 is Geek, segment 1 Simple.
    var isInGeekMode: Bool {
        guard let geek = geekModeSegments.first else { return false }
        return isChosen(geek)
    }

    func isChosen(_ element: XCUIElement) -> Bool {
        element.isSelected || (element.value as? Int) == 1
    }

    /// Switches Geek/Simple with the control in Settings' title bar; Settings must be open.
    func switchMode(toGeek geek: Bool) {
        let segments = geekModeSegments
        guard segments.count >= 2 else { return XCTFail("the Geek / Simple switch has no segments") }
        guard isInGeekMode != geek else { return }
        tap(geek ? segments[0] : segments[1])
        waitUntil { self.isInGeekMode == geek }
    }

    /// Geek mode for the panes and rows that only it shows, switched back after the test. Skips when
    /// the account can't have it (an expired trial is offered Pro instead).
    func requireGeekMode() throws {
        guard !isInGeekMode else { return }
        switchMode(toGeek: true)
        guard isInGeekMode else {
            closeStraySheets()
            throw XCTSkip("The test account can't switch to Geek mode (an expired trial is Simple only).")
        }
        restoreAfterTest { [unowned self] in self.switchMode(toGeek: false) }
    }

    // MARK: Controls

    /// Flips a switch in a pane and queues flipping it back. Returns the value it started with.
    @discardableResult
    func flipSwitch(_ identifier: String, inPane paneId: String) throws -> Int? {
        try openPane(paneId)
        let toggle = app.switches[identifier]
        XCTAssertTrue(appears(toggle), "\(identifier) is missing")
        let original = toggle.value as? Int
        tap(toggle)
        XCTAssertNotEqual(toggle.value as? Int, original, "\(identifier) didn't change")
        restoreAfterTest { [unowned self] in self.setSwitch(identifier, inPane: paneId, to: original) }
        return original
    }

    func setSwitch(_ identifier: String, inPane paneId: String, to value: Int?) {
        guard let value, (try? openPane(paneId)) != nil else { return }
        let toggle = app.switches[identifier]
        guard appears(toggle), toggle.value as? Int != value else { return }
        tap(toggle)
    }

    /// Selects everything in a text field and types over it.
    func replaceText(of field: XCUIElement, with text: String) {
        tap(field)
        press("a", modifiers: .command)
        typeIntoFocus(text)
    }

    /// What a control shows: AppKit fields and pop-ups carry it as their value, labels as their label.
    func text(of element: XCUIElement) -> String {
        (element.value as? String) ?? element.label
    }

    // MARK: Pictures

    /// The mean brightness of what `element` draws, 0 (black) to 1 (white), from a thumbnail of its
    /// screenshot — enough to tell a dark appearance from a light one.
    func averageBrightness(of element: XCUIElement) -> CGFloat? {
        let thumbnailSide = 32
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        guard let image = element.screenshot().image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        var pixels = [UInt8](repeating: 0, count: thumbnailSide * thumbnailSide * bytesPerPixel)
        let isDrawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: thumbnailSide, height: thumbnailSide,
                                          bitsPerComponent: bitsPerComponent, bytesPerRow: thumbnailSide * bytesPerPixel,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: thumbnailSide, height: thumbnailSide))
            return true
        }
        guard isDrawn else { return nil }
        var total: CGFloat = 0
        for pixel in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            // Rec. 709 luma of the red, green and blue bytes.
            total += 0.2126 * CGFloat(pixels[pixel]) + 0.7152 * CGFloat(pixels[pixel + 1]) + 0.0722 * CGFloat(pixels[pixel + 2])
        }
        return total / CGFloat(thumbnailSide * thumbnailSide) / CGFloat(UInt8.max)
    }
}

final class RegressionSettingsUITests: SettingsAreaUITestCase {
    /// The Appearance pop-up's items, in the order uIVc adds them.
    private enum AppearanceChoice: Int {
        case system = 0, dark, light
    }
    /// How much darker "always dark" must draw than "never dark" to count as a visible change.
    private static let minimumBrightnessDifference: CGFloat = 0.15

    // MARK: Appearance

    func testDarkAppearanceDarkensTheWindow() throws {
        try launchIntoSettings()
        let popup = try appearancePopup()
        let original = text(of: popup)
        restoreAfterTest { [unowned self] in self.chooseAppearance(titled: original) }

        chooseMenuItem(at: AppearanceChoice.dark.rawValue, openedBy: popup)
        let dark = try brightnessOnceSettled(popup)
        attachScreenshot(named: "always dark")
        chooseMenuItem(at: AppearanceChoice.light.rawValue, openedBy: popup)
        let light = try brightnessOnceSettled(popup)
        attachScreenshot(named: "never dark")

        XCTAssertLessThan(dark + Self.minimumBrightnessDifference, light,
                          "“Always Dark Mode” should draw the window visibly darker than “Never Dark Mode”")
    }

    func testAppearanceChoicePersistsAfterRelaunch() throws {
        try launchIntoSettings()
        let popup = try appearancePopup()
        let original = text(of: popup)
        restoreAfterTest { [unowned self] in self.chooseAppearance(titled: original) }
        let other: AppearanceChoice = original == titleOfAppearance(.dark, in: popup) ? .light : .dark
        chooseMenuItem(at: other.rawValue, openedBy: popup)
        let chosen = text(of: popup)
        XCTAssertNotEqual(chosen, original, "the appearance didn't change")

        try relaunchIntoSettings()
        XCTAssertEqual(text(of: try appearancePopup()), chosen, "the appearance didn't survive a relaunch")
    }

    func testFocusGlowBorderSettingPersistsAfterRelaunch() throws {
        try launchIntoSettings()
        let original = try flipSwitch(Area.focusGlowBorderSwitch, inPane: Settings.Pane.ui)

        try relaunchIntoSettings()
        try openPane(Settings.Pane.ui)
        let toggle = app.switches[Area.focusGlowBorderSwitch]
        XCTAssertTrue(appears(toggle), "the glow-border switch is missing after relaunch")
        XCTAssertNotEqual(toggle.value as? Int, original, "the glow-border setting didn't survive a relaunch")
    }

    // MARK: Modes and search

    func testGeekAndSimpleModeChangeWhatSettingsShow() throws {
        try launchIntoSettings()
        let startedInGeek = isInGeekMode
        restoreAfterTest { [unowned self] in self.switchMode(toGeek: startedInGeek) }

        switchMode(toGeek: !startedInGeek)
        XCTAssertEqual(isInGeekMode, !startedInGeek, "the Geek / Simple switch didn't change mode")
        try openPane(Settings.Pane.strictness)
        // The strictness level is a Geek-mode control; Simple mode hides it.
        let slider = app.sliders[Area.strictnessSlider]
        if startedInGeek {
            XCTAssertTrue(waitForNonExistence(of: slider), "Simple mode still shows the strictness level")
        } else {
            XCTAssertTrue(appears(slider), "Geek mode doesn't show the strictness level")
        }
        attachScreenshot(named: startedInGeek ? "simple mode" : "geek mode")

        switchMode(toGeek: startedInGeek)
        XCTAssertEqual(isInGeekMode, startedInGeek, "the mode didn't switch back")
    }

    /// Searches by a setting's title, taken from the switch it names, so the test works in any language.
    func testSearchFindsASettingAndOpensItsPane() throws {
        try launchIntoSettings()
        try openPane(Settings.Pane.ui)
        let toggle = app.switches[Settings.popoverMenuSwitch]
        XCTAssertTrue(appears(toggle), "the popover-menu switch is missing")
        let term = toggle.label
        try XCTSkipIf(term.isEmpty, "The popover-menu switch has no title to search for.")
        try openPane(Settings.Pane.account)

        tap(element(Area.searchField))
        typeCharacters(term)   // the search runs as the user types
        let results = element(Area.searchResults)
        XCTAssertTrue(appears(results.tableRows.firstMatch), "searching for “\(term)” found nothing")
        attachScreenshot(named: "search results")
        press(.downArrow)
        press(.return)

        XCTAssertTrue(appears(element(Settings.panePrefix + Settings.Pane.ui)), "choosing the result didn't open its pane")
        XCTAssertTrue(appears(toggle), "the pane the result opened doesn't show the setting")
    }

    // MARK: Focus sessions (Pomodoro)

    func testPomodoroRatioFieldsRejectZeroAndLetters() throws {
        try launchIntoSettings()
        try requireGeekMode()
        try openPane(Settings.Pane.pomodoro)
        let work = app.textFields[Area.pomodoroWorkRatioField]
        XCTAssertTrue(appears(work), "the work ratio field is missing")
        let original = text(of: work)
        restoreAfterTest { [unowned self] in self.setRatio(Area.pomodoroWorkRatioField, to: original) }

        replaceText(of: work, with: "0")
        XCTAssertEqual(text(of: work), "1", "a zero work ratio should become 1")
        replaceText(of: work, with: "x")
        XCTAssertFalse(text(of: work).contains("x"), "the work ratio took a letter")

        let typed = original == "7" ? "8" : "7"
        replaceText(of: work, with: typed)
        XCTAssertTrue(text(of: element(Area.pomodoroRatioDescription)).contains(typed),
                      "the ratio description didn't follow the typed value")
        replaceText(of: work, with: original)
        press(.tab)
    }

    func testPomodoroBreakRatioPersistsAfterRelaunch() throws {
        try launchIntoSettings()
        try requireGeekMode()
        try openPane(Settings.Pane.pomodoro)
        let breakRatio = app.textFields[Area.pomodoroBreakRatioField]
        XCTAssertTrue(appears(breakRatio), "the break ratio field is missing")
        let original = text(of: breakRatio)
        restoreAfterTest { [unowned self] in self.setRatio(Area.pomodoroBreakRatioField, to: original) }
        let changed = original == "2" ? "3" : "2"
        replaceText(of: breakRatio, with: changed)
        press(.tab)   // the field saves when editing ends

        try relaunchIntoSettings()
        try openPane(Settings.Pane.pomodoro)
        XCTAssertTrue(appears(breakRatio), "the break ratio field is missing after relaunch")
        XCTAssertEqual(text(of: breakRatio), changed, "the break ratio didn't survive a relaunch")
    }

    // MARK: Strictness

    /// Moving the level asks "How strict do you want Focus Bear to be?" first; Cancel keeps the level.
    func testStrictnessLevelAsksBeforeChangingAndCancelKeepsIt() throws {
        try launchIntoSettings()
        try requireGeekMode()
        try openPane(Settings.Pane.strictness)
        let slider = app.sliders[Area.strictnessSlider]
        XCTAssertTrue(appears(slider), "the strictness level is missing")
        let original = sliderValue(slider)

        tap(slider)
        let sheetSlider = app.sliders[Area.strictnessSheetSlider]
        XCTAssertTrue(appears(sheetSlider), "changing the level didn't ask how strict to be")
        attachScreenshot(named: "strictness sheet")
        tap(element(Area.strictnessSheetCancelButton))

        XCTAssertTrue(waitForNonExistence(of: sheetSlider), "Cancel didn't close the strictness sheet")
        XCTAssertEqual(sliderValue(slider), original, "Cancel changed the strictness level")
    }

    // MARK: Breaks, accessibility, AI and to-do

    func testBreaksSettingPersistsAfterRelaunch() throws {
        try launchIntoSettings()
        let original = try flipSwitch(Area.showBreaksInCallSwitch, inPane: Settings.Pane.microBreaks)

        try relaunchIntoSettings()
        try openPane(Settings.Pane.microBreaks)
        let toggle = app.switches[Area.showBreaksInCallSwitch]
        XCTAssertTrue(appears(toggle), "the breaks-in-calls switch is missing after relaunch")
        XCTAssertNotEqual(toggle.value as? Int, original, "the breaks-in-calls setting didn't survive a relaunch")
    }

    func testReduceMotionIsKeptWhenThePaneReopens() throws {
        try launchIntoSettings()
        try assertSwitchIsKeptWhenThePaneReopens(Area.reduceMotionSwitch, inPane: Settings.Pane.accessibility)
    }

    func testMotivationalMessageIsKeptWhenThePaneReopens() throws {
        try launchIntoSettings()
        try assertSwitchIsKeptWhenThePaneReopens(Area.motivationalMessageSwitch, inPane: Settings.Pane.ai)
    }

    func testToDoPlayerSettingIsKeptWhenThePaneReopens() throws {
        try launchIntoSettings()
        try assertSwitchIsKeptWhenThePaneReopens(Area.showToDoPlayerSwitch, inPane: Settings.Pane.toDoList)
    }

    // MARK: Office mode, permissions, account

    /// Office mode needs an office-friendly break. Without one the app asks to add it, and declining
    /// leaves the mode alone; with one, the mode switches (and is switched back afterwards).
    func testOfficeModeAsksForAnOfficeFriendlyBreakOrSwitches() throws {
        try launchIntoSettings()
        try openPane(Settings.Pane.officeMode)
        let office = element(Area.officeModeRadio)
        let workFromHome = element(Area.workFromHomeRadio)
        XCTAssertTrue(appears(office) && appears(workFromHome), "the office / work-from-home choice is missing")
        try XCTSkipIf(isChosen(office), "The test account is already in office mode.")
        restoreAfterTest { [unowned self] in
            guard (try? self.openPane(Settings.Pane.officeMode)) != nil, self.isChosen(office) else { return }
            self.tap(workFromHome)
        }

        tap(office)
        let decline = element(Area.officeModeDeclineButton)
        if appears(decline) {
            attachScreenshot(named: "office-friendly break offer")
            tap(decline)
            XCTAssertTrue(waitForNonExistence(of: decline), "declining didn't close the question")
            XCTAssertTrue(isChosen(workFromHome), "declining should leave the mode on working from home")
        } else {
            XCTAssertTrue(isChosen(office), "choosing office mode didn't take")
        }
    }

    func testPermissionsPaneListsBrowsers() throws {
        try launchIntoSettings()
        try openPane(Settings.Pane.permissions)
        let table = element(Area.permissionsTable)
        XCTAssertTrue(appears(table), "the permissions list is missing")
        XCTAssertTrue(appears(table.tableRows.firstMatch), "the permissions pane lists no browsers")
    }

    func testAccountPaneShowsTheTestAccountEmail() throws {
        try launchIntoSettings()
        let account = try requireTestAccount()
        try openPane(Settings.Pane.account)
        let email = element(Area.accountEmail)
        XCTAssertTrue(appears(email), "the account pane shows no email")
        XCTAssertEqual(text(of: email).lowercased(), account.email.lowercased(), "the account pane shows another email")
    }

    // MARK: Advanced

    /// Every Advanced row (Meetings, Privacy, Add Ons, Talking Clock, Research) opens a page with controls.
    func testEveryAdvancedPageOpens() throws {
        try launchIntoSettings()
        try requireGeekMode()
        try openPane(Area.advancedPane)
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", Area.advancedRowPrefix))
        let pageIds = rows.allElementsBoundByIndex.map { String($0.identifier.dropFirst(Area.advancedRowPrefix.count)) }
        XCTAssertFalse(pageIds.isEmpty, "the Advanced pane lists nothing")
        for pageId in pageIds {
            try openPane(Area.advancedPane)
            tap(element(Area.advancedRowPrefix + pageId))
            let page = element(Settings.panePrefix + pageId)
            XCTAssertTrue(appears(page), "the \(pageId) page didn't open")
            XCTAssertTrue(hasControls(page), "the \(pageId) page shows no controls")
            attachScreenshot(named: "advanced \(pageId)")
        }
    }

    // MARK: Sidebar footer

    func testExportDataOffersAFolderAndCancels() throws {
        try launchIntoSettings()
        let export = element(Area.exportDataButton)
        XCTAssertTrue(appears(export), "Export Data is missing")
        tap(export)
        let picker = app.sheets.firstMatch
        XCTAssertTrue(appears(picker), "Export Data didn't ask where to export to")
        attachScreenshot(named: "export folder picker")
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: picker), "Escape didn't cancel the export")
    }

    /// The UI-test build never starts the updater, so this checks the button is there and that pressing
    /// it leaves nothing behind — any window it does raise has to close with Escape.
    func testCheckForUpdatesLeavesNothingBehind() throws {
        try launchIntoSettings()
        let check = element(Area.checkForUpdatesButton)
        XCTAssertTrue(appears(check), "Check for updates is missing")
        let windowsBefore = app.windows.count
        tap(check)
        if let raised = firstToAppear([app.sheets.firstMatch, app.dialogs.firstMatch], timeout: Self.optionalWait) {
            attachScreenshot(named: "check for updates")
            press(.escape)
            XCTAssertTrue(waitForNonExistence(of: raised), "the update check's window didn't close")
        }
        XCTAssertLessThanOrEqual(app.windows.count, windowsBefore, "checking for updates left a window open")
        XCTAssertTrue(element(Settings.appearanceTab).exists, "checking for updates took the app away from Settings")
    }

    /// Release notes open in the default browser — outside the app — so the button is checked, not pressed.
    func testReleaseNotesAndVersionAreShown() throws {
        try launchIntoSettings()
        let releaseNotes = element(Area.releaseNotesButton)
        XCTAssertTrue(appears(releaseNotes), "Release notes is missing")
        XCTAssertTrue(releaseNotes.isEnabled, "Release notes is disabled")
        let version = element(Area.versionLabel)
        XCTAssertTrue(appears(version), "the version is missing")
        XCTAssertNotNil(text(of: version).rangeOfCharacter(from: .decimalDigits), "the version label shows no version number")
    }

    // MARK: - Steps

    private func appearancePopup() throws -> XCUIElement {
        try openPane(Settings.Pane.ui)
        let popup = app.popUpButtons[Settings.darkModePopup]
        XCTAssertTrue(appears(popup), "the appearance setting is missing")
        return popup
    }

    /// Reading the pop-up first makes XCUITest wait for the app to go idle, so the window has redrawn.
    private func brightnessOnceSettled(_ popup: XCUIElement) throws -> CGFloat {
        XCTAssertTrue(popup.exists, "the appearance setting went away")
        return try XCTUnwrap(averageBrightness(of: mainWindow), "couldn't read the window's pixels")
    }

    private func titleOfAppearance(_ choice: AppearanceChoice, in popup: XCUIElement) -> String? {
        let titles = openMenu(of: popup)?.map(\.title) ?? []
        press(.escape)
        return titles.indices.contains(choice.rawValue) ? titles[choice.rawValue] : nil
    }

    private func chooseAppearance(titled title: String) {
        guard let popup = try? appearancePopup(), text(of: popup) != title else { return }
        chooseMenuItem(titled: title, openedBy: popup)
    }

    private func setRatio(_ identifier: String, to value: String) {
        guard (try? openPane(Settings.Pane.pomodoro)) != nil else { return }
        let field = app.textFields[identifier]
        guard appears(field), text(of: field) != value else { return }
        replaceText(of: field, with: value)
        press(.tab)
    }

    private func sliderValue(_ slider: XCUIElement) -> Double? {
        if let number = slider.value as? NSNumber { return number.doubleValue }
        return (slider.value as? String).flatMap(Double.init)
    }

    /// Flips a switch, leaves the pane and comes back: the pane re-reads the setting when it appears,
    /// so the switch only stays flipped if the setting really changed. Flipped back afterwards.
    private func assertSwitchIsKeptWhenThePaneReopens(_ identifier: String, inPane paneId: String) throws {
        let original = try flipSwitch(identifier, inPane: paneId)
        try openPane(paneId == Settings.Pane.account ? Settings.Pane.ui : Settings.Pane.account)
        try openPane(paneId)
        let toggle = app.switches[identifier]
        XCTAssertTrue(appears(toggle), "\(identifier) is missing when the pane reopens")
        XCTAssertNotEqual(toggle.value as? Int, original, "\(identifier) went back when the pane reopened")
    }

    private func hasControls(_ page: XCUIElement) -> Bool {
        let controls = [page.buttons, page.switches, page.checkBoxes, page.popUpButtons, page.textFields, page.sliders, page.tables]
        return controls.contains { $0.count > 0 }
    }
}
