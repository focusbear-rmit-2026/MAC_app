//
//  AuthUITests.swift
//  Focus BearUITests
//
//  The real email + password form. Every other signed-in test seeds its session from the
//  environment instead (launchSignedIn), so this is the one that proves the form itself works.
//

import XCTest

final class AuthUITests: FocusBearUITestCase {
    private typealias Login = UITestContract.Identifier.Login

    func testSignInWithEmailAndPassword() throws {
        let account = try requireTestAccount()
        app.launchArguments = [UITestContract.LaunchArgument.uiTest,
                               UITestContract.LaunchArgument.reset,
                               UITestContract.LaunchArgument.skipOnboarding]
        launchIsolated()

        let goToSignIn = app.buttons[Login.goToSignInButton]
        if appears(goToSignIn, within: Self.firstLaunchTimeout, waitsOnNetwork: true) { tap(goToSignIn) }

        let email = app.textFields[Login.emailField]
        XCTAssertTrue(appears(email), "sign-in form missing")
        tap(email)
        typeIntoFocus(account.email)
        enterSecret(account.password, into: app.secureTextFields[Login.passwordField])
        tap(app.buttons[Login.signInButton])

        XCTAssertTrue(appears(app.buttons[UITestContract.Identifier.Menu.dayPlan], within: Self.signInTimeout + Self.firstLaunchTimeout, waitsOnNetwork: true),
                      "signing in should reach the main window")
        attachScreenshot(named: "signed in")
    }
}
