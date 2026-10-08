//
//  SettingsUITests.swift
//  Focus BearUITests
//

import XCTest

final class SettingsUITests: FocusBearUITestCase {
    private typealias Settings = UITestContract.Identifier.Settings

    /// Every pane in the sidebar opens and shows at least one control. Nothing is changed.
    func testEverySettingsPaneOpens() throws {
        try openSettings()
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", Settings.tabPrefix))
        let paneIds = rows.allElementsBoundByIndex.map(\.identifier).map { String($0.dropFirst(Settings.tabPrefix.count)) }
        XCTAssertFalse(paneIds.isEmpty, "the settings sidebar lists no panes")
        for paneId in paneIds {
            tapSettingsTab(paneId)
            let pane = element(Settings.panePrefix + paneId)
            XCTAssertTrue(appears(pane), "the \(paneId) pane didn't open")
            XCTAssertTrue(hasControls(pane), "the \(paneId) pane shows no controls")
            attachScreenshot(named: "settings \(paneId)")
        }
    }

    /// A harmless switch (Appearance → popover menu) flips and flips back, leaving the account as it was.
    func testAToggleRoundTrips() throws {
        try openSettings()
        tap(element(Settings.appearanceTab))
        let toggle = app.switches[Settings.popoverMenuSwitch]
        XCTAssertTrue(appears(toggle), "the popover-menu switch is missing")
        let original = toggle.value as? Int

        tap(toggle)
        XCTAssertNotEqual(toggle.value as? Int, original, "the switch didn't change")
        tap(toggle)
        XCTAssertEqual(toggle.value as? Int, original, "the switch didn't go back")
    }

    func testKeyboardShortcutsPaneListsShortcuts() throws {
        try openSettings()
        let tab = element(Settings.keyboardShortcutsTab)
        guard appears(tab) else {
            throw XCTSkip("Keyboard shortcuts are an advanced-mode pane, and the test account is in simple mode.")
        }
        tap(tab)
        let pane = element(Settings.panePrefix + Settings.Pane.keyboardShortcuts)
        XCTAssertTrue(appears(pane), "the keyboard shortcuts pane didn't open")
        XCTAssertTrue(hasControls(pane), "the keyboard shortcuts pane lists nothing to change")
    }

    private func openSettings() throws {
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.settings, expectingAnyOf: element(Settings.appearanceTab))
    }

    private func hasControls(_ pane: XCUIElement) -> Bool {
        let controls = [pane.buttons, pane.switches, pane.checkBoxes, pane.popUpButtons, pane.textFields, pane.sliders, pane.tables]
        return controls.contains { $0.count > 0 }
    }
}
