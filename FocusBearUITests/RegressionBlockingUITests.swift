//
//  RegressionBlockingUITests.swift
//  Focus BearUITests
//
//  Regression suite: Blocking. Runs in the Regression test plan; the critical path is in Smoke.
//
//  Configuration only: block lists, blocking schedules, the tab limiter and always-allowed apps are
//  created, edited and removed here, but nothing is enforced — BlockingEnforcementUITests owns that.
//  Everything a test creates is uniquely named and deleted by the same test, even when it fails; the
//  schedules run tomorrow only, so none is ever active while the suite runs.
//

import XCTest

final class RegressionBlockingUITests: SettingsAreaUITestCase {
    /// An app every Mac has and nobody blocks, added to lists and removed again.
    private static let sampleAppPath = "/System/Applications/Chess.app"
    private static var sampleAppFileName: String { URL(fileURLWithPath: sampleAppPath).lastPathComponent }
    /// Weekdays as the schedule editor's day pills number them: 1 = Sunday … 7 = Saturday.
    private static let weekdays = Calendar.current.maximumRange(of: .weekday).map(Array.init) ?? []
    /// The editor's strictness choices, left to right.
    private enum ScheduleStrictness: Int {
        case flexible = 0, moderate, strict
    }

    // MARK: - Block lists

    func testBlockListIsCreatedKeptAfterRelaunchAndDeleted() throws {
        try launchIntoBlockLists()
        let name = uniqueTitle("UI test block list")
        let card = createBlockList(named: name)

        try relaunchIntoBlockLists()
        XCTAssertTrue(appears(card), "the new block list didn't survive a relaunch")
        deleteBlockList(named: name)
    }

    func testBlockListNamesMustBeUnique() throws {
        try launchIntoBlockLists()
        let name = uniqueTitle("UI test block list")
        createBlockList(named: name)

        tap(element(Area.blockListCreateButton))
        let field = element(Area.addBlockListNameField)
        XCTAssertTrue(appears(field), "the Add Block List sheet didn't open")
        tap(field)
        typeIntoFocus(name)
        tap(element(Area.addBlockListAddButton))
        XCTAssertTrue(appears(element(Area.addBlockListError)), "a second block list with the same name wasn't refused")
        attachScreenshot(named: "duplicate name")
        tap(element(Area.addBlockListCancelButton))
        XCTAssertTrue(waitForNonExistence(of: field), "Cancel didn't close the Add Block List sheet")
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: Area.blockListCardPrefix + name).count, 1,
                       "the duplicate block list was added anyway")
    }

    func testBlockListCanBeRenamed() throws {
        try launchIntoBlockLists()
        let name = uniqueTitle("UI test block list")
        let renamed = uniqueTitle("UI test renamed list")
        deleteBlockListsAfterTest(named: [renamed])
        tap(createBlockList(named: name))

        tap(element(Area.blockListRenameButton))
        let field = element(Area.blockListNameField)
        XCTAssertTrue(appears(field), "renaming didn't open the name field")
        replaceText(of: field, with: renamed)
        press(.return)

        XCTAssertTrue(appears(element(Area.blockListCardPrefix + renamed)), "the renamed block list isn't listed")
        XCTAssertTrue(waitForNonExistence(of: element(Area.blockListCardPrefix + name)), "the old name is still listed")
    }

    func testWebsiteIsAddedToABlockListKeptAfterRelaunchAndRemoved() throws {
        try launchIntoBlockLists()
        let name = uniqueTitle("UI test block list")
        let card = createBlockList(named: name)
        tap(card)
        // `.example` is reserved (RFC 2606), so the entry can never match a real site.
        let website = "uitest-\(UUID().uuidString.prefix(8).lowercased()).example"
        tap(element(Area.blockListSearchField))
        typeIntoFocus(website)
        tap(element(Area.blockListAddWebsiteCard))
        let row = element(Area.blockListEntryPrefix + website)
        XCTAssertTrue(appears(row), "the added website isn't listed")

        try relaunchIntoBlockLists()
        tap(card)
        XCTAssertTrue(appears(row), "the website didn't survive a relaunch")
        tap(removeButton(in: row))
        XCTAssertTrue(waitForNonExistence(of: row), "the removed website is still listed")
    }

    func testAppIsAddedToABlockListAndRemoved() throws {
        try XCTSkipUnless(FileManager.default.fileExists(atPath: Self.sampleAppPath), "\(Self.sampleAppPath) isn't on this Mac.")
        try launchIntoBlockLists()
        tap(createBlockList(named: uniqueTitle("UI test block list")))

        // A query no installed app matches, so the quick-add row offers the file picker.
        tap(element(Area.blockListSearchField))
        typeIntoFocus("uitest-no-such-app-\(UUID().uuidString.prefix(8).lowercased())")
        tap(element(Area.blockListAddAppManuallyCard))
        chooseInFilePicker(Self.sampleAppPath)
        let row = element(Area.blockListEntryPrefix + Self.sampleAppPath)
        XCTAssertTrue(appears(row), "the chosen app isn't listed")
        attachScreenshot(named: "app in block list")
        tap(removeButton(in: row))
        XCTAssertTrue(waitForNonExistence(of: row), "the removed app is still listed")
    }

    /// "Use AI for this block list" belongs to the block list (is_ai_enabled), not to schedules: it is
    /// kept per list, across the Advanced sheet closing and across a relaunch (from the server).
    func testUseAIIsKeptPerBlockListAcrossARelaunch() throws {
        try launchIntoBlockLists()
        let card = createBlockList(named: uniqueTitle("UI test block list"))
        tap(card)
        let useAi = openAdvancedSheet()
        let original = useAi.value as? Int
        tap(useAi)
        let flipped = useAi.value as? Int
        XCTAssertNotEqual(flipped, original, "the Use AI checkbox didn't change")
        closeAdvancedSheet()

        XCTAssertEqual(openAdvancedSheet().value as? Int, flipped, "Use AI went back when the sheet reopened")
        closeAdvancedSheet()

        try relaunchIntoBlockLists()
        tap(card)
        let kept = openAdvancedSheet().value as? Int
        XCTAssertEqual(kept, flipped, "Use AI didn't survive a relaunch")

        closeAdvancedSheet()
    }

    // MARK: - Blocking schedules

    func testBlockingScheduleIsCreatedAndDeleted() throws {
        try launchIntoSchedules()
        let name = uniqueTitle("UI test schedule")
        createSchedule(named: name, onlyOn: weekday(daysFromToday: 1))
        attachScreenshot(named: "schedule created")
        deleteSchedule(named: name)
        XCTAssertFalse(element(Area.scheduleCardPrefix + name).exists, "the deleted schedule is still listed")
    }

    func testBlockingScheduleDaysAndStrictnessAreEditedAndKept() throws {
        try launchIntoSchedules()
        let name = uniqueTitle("UI test schedule")
        let card = createSchedule(named: name, onlyOn: weekday(daysFromToday: 1))
        let before = summary(of: card)

        tap(card)
        let nameField = element(Area.scheduleNameField)
        XCTAssertTrue(appears(nameField), "the schedule didn't open for editing")
        XCTAssertEqual(text(of: nameField), name, "the editor opened a different schedule")
        tap(element(Area.scheduleDayPrefix + String(weekday(daysFromToday: 2))))
        tap(element(Area.scheduleStrictnessPrefix + String(ScheduleStrictness.moderate.rawValue)))
        tap(element(Area.scheduleSaveButton))
        answerQuestionsAfterSaving()
        XCTAssertTrue(appears(card), "saving didn't return to the schedule list")
        let after = summary(of: card)
        XCTAssertNotEqual(after, before, "the schedule's card doesn't show the new days and strictness")

        waitForUpload()
        app.terminate()
        try launchIntoSchedules()
        XCTAssertTrue(appears(card), "the edited schedule didn't survive a relaunch")
        XCTAssertEqual(summary(of: card), after, "the edit didn't survive a relaunch")
    }

    /// Picking a preset opens the editor filled in; the Custom tile opens it blank. Cancelling creates nothing.
    func testSchedulePresetsFillInTheEditor() throws {
        try launchIntoSchedules()
        let schedulesBefore = scheduleCards().count
        openPresets()
        let tiles = presetTiles()
        XCTAssertGreaterThan(tiles.count, 1, "the presets offer nothing but Custom")
        attachScreenshot(named: "presets")

        tap(tiles[0])
        let nameField = element(Area.scheduleNameField)
        XCTAssertTrue(appears(nameField), "picking a preset didn't open the editor")
        XCTAssertFalse(text(of: nameField).isEmpty, "the preset didn't fill in a name")
        tap(element(Area.scheduleCancelButton))
        XCTAssertTrue(waitForNonExistence(of: nameField), "Cancel didn't leave the editor")

        openPresets()
        tap(try XCTUnwrap(presetTiles().last))
        XCTAssertTrue(appears(nameField), "the Custom tile didn't open the editor")
        XCTAssertTrue(text(of: nameField).isEmpty, "a custom schedule should start without a name")
        tap(element(Area.scheduleCancelButton))
        XCTAssertTrue(waitForNonExistence(of: nameField), "Cancel didn't leave the editor")
        XCTAssertEqual(scheduleCards().count, schedulesBefore, "cancelling created a schedule")
    }

    func testBlockingScheduleNeedsAName() throws {
        try launchIntoSchedules()
        let schedulesBefore = scheduleCards().count
        startCustomSchedule()
        tap(element(Area.scheduleSaveButton))
        let alert = app.sheets.firstMatch
        XCTAssertTrue(appears(alert), "saving a schedule without a name wasn't refused")
        attachScreenshot(named: "schedule needs a name")
        press(.return)
        XCTAssertTrue(waitForNonExistence(of: alert), "the alert didn't close")
        XCTAssertTrue(element(Area.scheduleNameField).exists, "the refused schedule left the editor")
        tap(element(Area.scheduleCancelButton))
        XCTAssertEqual(scheduleCards().count, schedulesBefore, "a schedule without a name was created")
    }

    // MARK: - Browser tab limiter

    /// Turning the limiter on first asks for permission to manage browser tabs; Cancel leaves it off.
    func testTabLimiterAsksForBrowserPermissionFirst() throws {
        try launchIntoTabLimiter()
        let toggle = app.switches[Area.tabLimiterSwitch]
        XCTAssertTrue(appears(toggle), "the tab limiter switch is missing")
        try XCTSkipIf(toggle.value as? Int == 1, "The tab limiter is already on for the test account.")

        tap(toggle)
        let cancel = element(Area.tabLimiterPermissionCancelButton)
        XCTAssertTrue(appears(cancel), "turning the tab limiter on didn't ask for browser permission")
        attachScreenshot(named: "tab limiter permission")
        tap(cancel)
        XCTAssertTrue(waitForNonExistence(of: cancel), "Cancel didn't close the question")
        XCTAssertEqual(toggle.value as? Int, 0, "cancelling should leave the tab limiter off")
    }

    func testTabLimiterCountRejectsZero() throws {
        try launchIntoTabLimiter()
        let field = app.textFields[Area.tabLimiterCountField]
        XCTAssertTrue(appears(field), "the tab limit field is missing")
        let original = text(of: field)

        replaceText(of: field, with: "0")
        press(.tab)
        confirmDestructiveAlert()   // "Tab count can not be 0." has one button
        XCTAssertEqual(text(of: field), original, "a zero tab limit should put the old limit back")
    }

    func testTabLimiterCountPersistsAfterRelaunch() throws {
        try launchIntoTabLimiter()
        let field = app.textFields[Area.tabLimiterCountField]
        XCTAssertTrue(appears(field), "the tab limit field is missing")
        let original = text(of: field)
        restoreAfterTest { [unowned self] in self.setTabLimit(to: original) }

        tap(app.steppers[Area.tabLimiterStepper].incrementArrows.firstMatch)
        let raised = text(of: field)
        XCTAssertNotEqual(raised, original, "the stepper didn't raise the tab limit")

        try relaunchIntoSettings()
        try openTabLimiterPane()
        XCTAssertTrue(appears(field), "the tab limit field is missing after relaunch")
        XCTAssertEqual(text(of: field), raised, "the tab limit didn't survive a relaunch")
    }

    // MARK: - Always-allowed apps

    func testAlwaysAllowedAppIsAddedAndRemoved() throws {
        try XCTSkipUnless(FileManager.default.fileExists(atPath: Self.sampleAppPath), "\(Self.sampleAppPath) isn't on this Mac.")
        try launchIntoSettings()
        try requireGeekMode()   // the list is a Geek-mode row
        try openAlwaysAllowedApps()
        let row = alwaysAllowedRow()
        try XCTSkipIf(row.exists, "\(Self.sampleAppFileName) is already always allowed for the test account.")
        restoreAfterTest { [unowned self] in self.removeSampleAppFromAlwaysAllowed() }

        tap(element(Area.alwaysAllowedAppsAddButton))
        chooseInFilePicker(Self.sampleAppPath)
        XCTAssertTrue(appears(row), "the chosen app isn't always allowed")
        attachScreenshot(named: "always allowed app")
        tap(row)
        tap(element(Area.alwaysAllowedAppsRemoveButton))
        XCTAssertTrue(waitForNonExistence(of: row), "the removed app is still always allowed")
    }

    // MARK: - Block list steps

    private func launchIntoBlockLists() throws {
        try launchSignedIn()
        openBlockLists()
    }

    private func relaunchIntoBlockLists() throws {
        waitForUpload()
        app.terminate()
        try launchIntoBlockLists()
    }

    private func openBlockLists() {
        guard !element(Blocking.blockListsEditor).exists else { return }
        openBlocksScreen()
        tap(element(Blocking.blockListsRow))
        XCTAssertTrue(appears(element(Blocking.blockListsEditor)), "the block list editor didn't open")
    }

    /// The Blocks screen's list of editors. Its sidebar item does nothing while already selected, so from
    /// inside one of the editors the way back is through another screen.
    private func openBlocksScreen() {
        if !element(Blocking.blockListsRow).exists { tap(app.buttons[Menu.dayPlan]) }
        open(menuItem: Menu.blocks, expectingAnyOf: element(Blocking.blockListsRow))
    }

    /// Creates a block list through "Create New Block List" and queues its deletion.
    @discardableResult
    private func createBlockList(named name: String) -> XCUIElement {
        deleteBlockListsAfterTest(named: [name])
        tap(element(Area.blockListCreateButton))
        let field = element(Area.addBlockListNameField)
        XCTAssertTrue(appears(field), "the Add Block List sheet didn't open")
        tap(field)
        typeIntoFocus(name)
        tap(element(Area.addBlockListAddButton))
        let card = element(Area.blockListCardPrefix + name)
        // Listed once the server has saved it.
        XCTAssertTrue(appears(card, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the new block list isn't listed")
        return card
    }

    /// Deletes the named block lists once the test ends, pass or fail — relaunching if it has to.
    private func deleteBlockListsAfterTest(named names: [String]) {
        addTeardownBlock { [weak self] in
            guard let self else { return }
            if self.app.state == .notRunning, (try? self.launchSignedIn()) == nil {
                return XCTFail("couldn't relaunch the app to delete \(names)")
            }
            self.closeStraySheets()
            self.openBlockLists()
            names.forEach(self.deleteBlockList(named:))
        }
    }

    private func deleteBlockList(named name: String) {
        let card = element(Area.blockListCardPrefix + name)
        guard card.exists else { return }
        tap(card)
        let delete = card.descendants(matching: .any).matching(identifier: Area.blockListDeleteButton).firstMatch
        XCTAssertTrue(appears(delete), "the selected block list offers no delete")
        tap(delete)
        confirmDestructiveAlert()
        // The list goes once the server confirms the delete.
        XCTAssertTrue(waitForNonExistence(of: card, timeout: Self.apiRoundTripTimeout), "the deleted block list is still listed")
    }

    private func removeButton(in row: XCUIElement) -> XCUIElement {
        row.descendants(matching: .any).matching(identifier: Area.blockListRemoveEntryButton).firstMatch
    }

    /// Opens the selected list's Advanced sheet and returns its "Use AI for this block list" checkbox.
    private func openAdvancedSheet() -> XCUIElement {
        tap(element(Area.blockListEditButton))
        let useAi = app.checkBoxes[Area.blockListUseAiCheckbox]
        XCTAssertTrue(appears(useAi), "the block list's Advanced sheet has no Use AI checkbox")
        return useAi
    }

    private func closeAdvancedSheet() {
        let done = element(Area.blockListAdvancedOkButton)
        tap(done)
        XCTAssertTrue(waitForNonExistence(of: done), "the Advanced sheet didn't close")
    }

    /// Picks `path` in the open file picker through Go to Folder, the way a keyboard user would.
    private func chooseInFilePicker(_ path: String) {
        let picker = app.sheets.firstMatch
        XCTAssertTrue(appears(picker), "no file picker opened")
        press("g", modifiers: [.command, .shift])
        waitUntil { self.focusedElement()?.elementType == .textField }
        press("a", modifiers: .command)
        typeIntoFocus(path)
        press(.return)   // goes to the app and selects it
        let appName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        waitUntil { picker.descendants(matching: .any).matching(NSPredicate(format: "isSelected == true AND label CONTAINS %@", appName)).firstMatch.exists }
        press(.return)   // the picker's default button chooses it
        XCTAssertTrue(waitForNonExistence(of: picker), "the file picker didn't close with the app chosen")
    }

    // MARK: - Schedule steps

    private func launchIntoSchedules() throws {
        try launchSignedIn()
        openSchedules()
    }

    private func openSchedules() {
        guard !element(Area.scheduleAddButton).exists else { return }
        openBlocksScreen()
        tap(element(Blocking.blockingSchedulesRow))
        leavePresetsIfShown()
        XCTAssertTrue(appears(element(Area.scheduleAddButton)), "the blocking schedules list didn't open")
    }

    /// The schedules screen comes back as it was left, so after a test that stopped on the presets the
    /// cleanup finds them again instead of the list. Custom, then Cancel, is the way back to the list
    /// that carries identifiers (the presets' Back button has none).
    private func leavePresetsIfShown() {
        let list = element(Area.scheduleAddButton)
        guard firstToAppear([list, presetTileQuery.firstMatch]) != list, let custom = presetTiles().last else { return }
        tap(custom)
        let cancel = element(Area.scheduleCancelButton)
        XCTAssertTrue(appears(cancel), "the Custom tile didn't open the editor")
        tap(cancel)
    }

    private func scheduleCards() -> [XCUIElement] {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", Area.scheduleCardPrefix)).allElementsBoundByIndex
    }

    /// Waits on a tile, not on the presets screen itself: in Settings `Area.schedulePresets` never
    /// reaches the accessibility tree (the schedules screen's own container, which holds nothing but the
    /// presets while they show, keeps its identifier instead), though the tiles inside it do.
    private func openPresets() {
        tap(element(Area.scheduleAddButton))
        XCTAssertTrue(appears(presetTileQuery.firstMatch), "adding a schedule didn't offer the presets")
    }

    private var presetTileQuery: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", Area.schedulePresetPrefix))
    }

    /// The preset tiles in their order; the last is Custom.
    private func presetTiles() -> [XCUIElement] {
        presetTileQuery.allElementsBoundByIndex.sorted {
            (Int($0.identifier.dropFirst(Area.schedulePresetPrefix.count)) ?? 0) < (Int($1.identifier.dropFirst(Area.schedulePresetPrefix.count)) ?? 0)
        }
    }

    private func startCustomSchedule() {
        openPresets()
        guard let custom = presetTiles().last else { return XCTFail("the presets have no Custom tile") }
        tap(custom)
        XCTAssertTrue(appears(element(Area.scheduleEditor)), "the schedule editor didn't open")
    }

    /// A custom schedule on one weekday only (a custom schedule starts on every day), and queues its deletion.
    @discardableResult
    private func createSchedule(named name: String, onlyOn weekday: Int) -> XCUIElement {
        deleteSchedulesAfterTest(named: [name])
        startCustomSchedule()
        tap(element(Area.scheduleNameField))
        typeIntoFocus(name)
        for day in Self.weekdays where day != weekday {
            tap(element(Area.scheduleDayPrefix + String(day)))
        }
        tap(element(Area.scheduleSaveButton))
        answerQuestionsAfterSaving()
        let card = element(Area.scheduleCardPrefix + name)
        XCTAssertTrue(appears(card), "the new schedule isn't listed")
        return card
    }

    /// Saving can warn that another schedule on the account shares the time ("Save Anyway" is the
    /// default button), and the account's first schedule offers to grant permissions, which is declined.
    private func answerQuestionsAfterSaving() {
        let declinePermissions = element(Area.schedulePermissionsDeclineButton)
        let questionsAtMost = 2
        for _ in 0..<questionsAtMost {
            guard let question = firstToAppear([declinePermissions, app.sheets.firstMatch], timeout: Self.optionalWait) else { return }
            if declinePermissions.exists {
                tap(declinePermissions)
            } else {
                press(.return)
            }
            _ = waitForNonExistence(of: question)
        }
    }

    private func deleteSchedulesAfterTest(named names: [String]) {
        addTeardownBlock { [weak self] in
            guard let self else { return }
            if self.app.state == .notRunning, (try? self.launchSignedIn()) == nil {
                return XCTFail("couldn't relaunch the app to delete \(names)")
            }
            self.closeStraySheets()
            self.openSchedules()
            names.forEach(self.deleteSchedule(named:))
            self.waitForUpload()   // a schedule is deleted locally first, then on the server
        }
    }

    private func deleteSchedule(named name: String) {
        let card = element(Area.scheduleCardPrefix + name)
        guard card.exists else { return }
        tap(card)
        let delete = element(Area.scheduleDeleteButton)
        XCTAssertTrue(appears(delete), "the schedule editor offers no delete")
        tap(delete)
        // Only a schedule that is running asks first.
        if appears(app.sheets.firstMatch, within: Self.optionalWait) { confirmDestructiveAlert() }
        XCTAssertTrue(waitForNonExistence(of: card), "the deleted schedule is still listed")
    }

    /// Everything a schedule's card says, to tell whether an edit reached it. Only words, numbers and
    /// punctuation: a schedule without an emoji gets one picked afresh on every launch.
    /// The card's words, without its icons: an emoji's presentation selector (U+FE0F) is a mark, which
    /// `alphanumerics` keeps, and the card drew the same icon with it before a relaunch and without after.
    private func summary(of card: XCUIElement) -> String {
        let kept = CharacterSet.alphanumerics.subtracting(.nonBaseCharacters).union(.punctuationCharacters).union(.whitespaces)
        let texts = [card.label] + card.staticTexts.allElementsBoundByIndex.map { text(of: $0) }
        return texts.map { String(String.UnicodeScalarView($0.unicodeScalars.filter(kept.contains))) }.joined(separator: " | ")
    }

    private func weekday(daysFromToday days: Int) -> Int {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return calendar.component(.weekday, from: day)
    }

    // MARK: - Strictness list steps

    private func launchIntoTabLimiter() throws {
        try launchIntoSettings()
        try openTabLimiterPane()
    }

    private func openTabLimiterPane() throws {
        try openPane(Settings.Pane.strictness)
        tap(element(Area.tabLimiterRow))
        XCTAssertTrue(appears(element(Settings.panePrefix + Area.tabLimiterPane)), "the tab limiter didn't open")
    }

    private func setTabLimit(to value: String) {
        guard (try? openTabLimiterPane()) != nil else { return }
        let field = app.textFields[Area.tabLimiterCountField]
        guard appears(field), text(of: field) != value else { return }
        replaceText(of: field, with: value)
        press(.tab)
    }

    private func openAlwaysAllowedApps() throws {
        try openPane(Settings.Pane.strictness)
        tap(element(Area.alwaysAllowedAppsRow))
        XCTAssertTrue(appears(element(Settings.panePrefix + Area.alwaysAllowedAppsPane)), "Always Allowed Apps didn't open")
    }

    private func alwaysAllowedRow() -> XCUIElement {
        element(Area.alwaysAllowedAppsTable).staticTexts.matching(showing(Self.sampleAppFileName)).firstMatch
    }

    private func removeSampleAppFromAlwaysAllowed() {
        guard (try? openAlwaysAllowedApps()) != nil else { return }
        let row = alwaysAllowedRow()
        guard appears(row) else { return }
        tap(row)
        tap(element(Area.alwaysAllowedAppsRemoveButton))
    }
}
