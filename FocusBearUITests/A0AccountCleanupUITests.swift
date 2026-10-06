//
//  A0AccountCleanupUITests.swift
//  Focus BearUITests
//
//  Runs first (XCTest runs classes in name order, hence "A0"): deletes what earlier runs left on the
//  test account — to-dos and projects titled like `uniqueTitle` makes them — so a later test isn't
//  thrown by an auto-picked goal or a section pushed below the fold by old rows. The app does the
//  deleting (UITestAccountCleanup) and reports on its status item when it is done.
//

import XCTest

final class A0AccountCleanupUITests: FocusBearUITestCase {
    /// Some hundreds of deletes, one request each.
    private static let cleanupTimeout: TimeInterval = 90

    func testLeftoversFromEarlierRunsAreRemoved() throws {
        _ = try requireTestAccount()
        XCTAssertTrue(removeTestItemsThroughTheApp(within: Self.cleanupTimeout),
                      "the account clean-up didn't finish; see the UITestAccountCleanup lines in the app's log")
        let statusItem = element(UITestContract.Identifier.MenuBar.statusItem)
        print("UITestAccountCleanup deleted (to-dos,projects): \(statusItem.value as? String ?? "")")
    }
}
