//
//  LaunchAndNavigationUITests.swift
//  Focus BearUITests
//

import XCTest

final class LaunchAndNavigationUITests: FocusBearUITestCase {
    private typealias Menu = UITestContract.Identifier.Menu

    /// Needs no account: the one test every runner can execute.
    func testLoggedOutLaunchOffersSignIn() {
        launchLoggedOut()
        let askLogin = app.buttons[UITestContract.Identifier.Login.goToSignInButton]
        let loginForm = app.textFields[UITestContract.Identifier.Login.emailField]
        let appeared = appears(askLogin, within: Self.firstLaunchTimeout, waitsOnNetwork: true) || loginForm.exists
        attachScreenshot(named: "logged out launch")
        XCTAssertTrue(appeared, "a logged-out launch should offer sign-in")
    }

    func testSidebarShowsTheMainDestinations() throws {
        try launchSignedIn()
        if !app.buttons[Menu.todo].exists { expandToolsSection() }
        for identifier in [Menu.dayPlan, Menu.focusSession, Menu.todo, Menu.blocks, Menu.settings, Menu.help] {
            XCTAssertTrue(app.buttons[identifier].exists, "sidebar item \(identifier) missing")
        }
        attachScreenshot(named: "main window")
    }

    func testEachSidebarDestinationOpensItsScreen() throws {
        try launchSignedIn()
        open(menuItem: Menu.todo, expectingAnyOf: element(UITestContract.Identifier.ToDo.newTaskButton))
        // The start screen, or the running session if one is already going.
        open(menuItem: Menu.focusSession, expectingAnyOf: element(UITestContract.Identifier.FocusStart.startButton),
             element(UITestContract.Identifier.FocusSession.endButton))
        open(menuItem: Menu.blocks, expectingAnyOf: element(UITestContract.Identifier.Blocking.blockListsRow))
        open(menuItem: Menu.help, expectingAnyOf: element(UITestContract.Identifier.Help.tabView))
        open(menuItem: Menu.dayPlan, expectingAnyOf: element(UITestContract.Identifier.DayPlan.view))
    }
}
