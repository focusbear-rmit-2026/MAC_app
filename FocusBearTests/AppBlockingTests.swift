//
//  AppBlockingTests.swift
//  Focus BearTests
//
//  Created by Devin AI on 17/01/26.
//

@testable import Focus_Bear
import XCTest

class AppBlockingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_app_in_always_allowed_list_returns_true() {
        let alwaysAllowedApps = ["/Applications/Calculator.app", "/Applications/Notes.app"]
        let result = AppBlockingHelper.isAppInAlwaysAllowedList(appName: "Calculator", alwaysAllowedApps: alwaysAllowedApps)
        XCTAssertTrue(result)
    }
    
    func test_app_not_in_always_allowed_list_returns_false() {
        let alwaysAllowedApps = ["/Applications/Calculator.app", "/Applications/Notes.app"]
        let result = AppBlockingHelper.isAppInAlwaysAllowedList(appName: "Safari", alwaysAllowedApps: alwaysAllowedApps)
        XCTAssertFalse(result)
    }
    
    func test_app_in_always_allowed_list_case_insensitive() {
        let alwaysAllowedApps = ["/Applications/Calculator.app"]
        let result = AppBlockingHelper.isAppInAlwaysAllowedList(appName: "CALCULATOR", alwaysAllowedApps: alwaysAllowedApps)
        XCTAssertTrue(result)
    }
    
    func test_app_in_blocked_list_returns_true() {
        let blockedApps = ["/Applications/Twitter.app", "/Applications/Facebook.app"]
        let result = AppBlockingHelper.isAppInBlockedList(appName: "Twitter", blockedApps: blockedApps)
        XCTAssertTrue(result)
    }
    
    func test_app_not_in_blocked_list_returns_false() {
        let blockedApps = ["/Applications/Twitter.app", "/Applications/Facebook.app"]
        let result = AppBlockingHelper.isAppInBlockedList(appName: "Safari", blockedApps: blockedApps)
        XCTAssertFalse(result)
    }
    
    func test_app_in_allowed_list_returns_true() {
        let allowedApps = ["/Applications/Xcode.app", "/Applications/Terminal.app"]
        let result = AppBlockingHelper.isAppInAllowedList(appName: "Xcode", allowedApps: allowedApps)
        XCTAssertTrue(result)
    }
    
    func test_app_not_in_allowed_list_returns_false() {
        let allowedApps = ["/Applications/Xcode.app", "/Applications/Terminal.app"]
        let result = AppBlockingHelper.isAppInAllowedList(appName: "Safari", allowedApps: allowedApps)
        XCTAssertFalse(result)
    }
    
    func test_should_block_app_when_in_always_allowed_list() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Calculator",
            alwaysAllowedApps: ["/Applications/Calculator.app"],
            blockedApps: ["/Applications/Calculator.app"],
            allowedApps: [],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: []
        )
        XCTAssertFalse(result, "App in always allowed list should never be blocked")
    }
    
    func test_should_block_app_when_in_blocked_list() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Twitter",
            alwaysAllowedApps: [],
            blockedApps: ["/Applications/Twitter.app"],
            allowedApps: [],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: []
        )
        XCTAssertTrue(result, "App in blocked list should be blocked")
    }
    
    func test_should_not_block_app_when_all_apps_allowed_in_focus() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Safari",
            alwaysAllowedApps: [],
            blockedApps: [],
            allowedApps: [],
            isAllowedAllAppsInFocus: true,
            defaultAllowedApps: []
        )
        XCTAssertFalse(result, "App should not be blocked when all apps are allowed in focus")
    }
    
    func test_should_not_block_app_when_in_default_allowed_apps() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "finder",
            alwaysAllowedApps: [],
            blockedApps: [],
            allowedApps: [],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: ["finder", "universalaccessauthwarn"]
        )
        XCTAssertFalse(result, "App in default allowed apps should not be blocked")
    }
    
    func test_should_not_block_app_when_in_allowed_list() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Xcode",
            alwaysAllowedApps: [],
            blockedApps: [],
            allowedApps: ["/Applications/Xcode.app"],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: []
        )
        XCTAssertFalse(result, "App in allowed list should not be blocked")
    }
    
    func test_should_block_app_when_not_in_any_allowed_list() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Safari",
            alwaysAllowedApps: [],
            blockedApps: [],
            allowedApps: ["/Applications/Xcode.app"],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: ["finder"]
        )
        XCTAssertTrue(result, "App not in any allowed list should be blocked")
    }
    
    func test_always_allowed_takes_priority_over_blocked() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Calculator",
            alwaysAllowedApps: ["/Applications/Calculator.app"],
            blockedApps: ["/Applications/Calculator.app"],
            allowedApps: [],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: []
        )
        XCTAssertFalse(result, "Always allowed should take priority over blocked list")
    }
    
    func test_blocked_takes_priority_over_allowed_all_apps() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Twitter",
            alwaysAllowedApps: [],
            blockedApps: ["/Applications/Twitter.app"],
            allowedApps: [],
            isAllowedAllAppsInFocus: true,
            defaultAllowedApps: []
        )
        XCTAssertTrue(result, "Blocked list should take priority over allowed all apps setting")
    }
    
    func test_empty_always_allowed_list() {
        let result = AppBlockingHelper.isAppInAlwaysAllowedList(appName: "Calculator", alwaysAllowedApps: [])
        XCTAssertFalse(result)
    }
    
    func test_app_path_with_spaces() {
        let alwaysAllowedApps = ["/Applications/Visual Studio Code.app"]
        let result = AppBlockingHelper.isAppInAlwaysAllowedList(appName: "Visual Studio Code", alwaysAllowedApps: alwaysAllowedApps)
        XCTAssertTrue(result)
    }

    // =========================================================================
    // ADDED: list-membership edge cases
    // =========================================================================
    func test_blocked_list_is_case_insensitive() {
        let result = AppBlockingHelper.isAppInBlockedList(appName: "TWITTER", blockedApps: ["/Applications/Twitter.app"])
        XCTAssertTrue(result)
    }

    func test_allowed_list_matches_nested_path() {
        let result = AppBlockingHelper.isAppInAllowedList(appName: "Xcode", allowedApps: ["/Users/me/Apps/Xcode.app"])
        XCTAssertTrue(result)
    }

    func test_always_allowed_matches_path_without_app_extension() {
        let result = AppBlockingHelper.isAppInAlwaysAllowedList(appName: "Slack", alwaysAllowedApps: ["/Applications/Slack"])
        XCTAssertTrue(result)
    }

    func test_always_allowed_matches_second_entry() {
        let result = AppBlockingHelper.isAppInAlwaysAllowedList(appName: "Notes", alwaysAllowedApps: ["/Applications/Calculator.app", "/Applications/Notes.app"])
        XCTAssertTrue(result)
    }

    func test_empty_blocked_list_returns_false() {
        XCTAssertFalse(AppBlockingHelper.isAppInBlockedList(appName: "Safari", blockedApps: []))
    }

    func test_empty_allowed_list_returns_false() {
        XCTAssertFalse(AppBlockingHelper.isAppInAllowedList(appName: "Safari", allowedApps: []))
    }

    func test_empty_app_name_against_empty_list() {
        XCTAssertFalse(AppBlockingHelper.isAppInBlockedList(appName: "", blockedApps: []))
    }

    func test_empty_app_name_against_nonempty_list() {
        XCTAssertFalse(AppBlockingHelper.isAppInBlockedList(appName: "", blockedApps: ["/Applications/Twitter.app"]))
    }

    func test_allowed_list_with_spaces_second_entry() {
        let allowedApps = ["/Applications/Xcode.app", "/Applications/Visual Studio Code.app"]
        XCTAssertTrue(AppBlockingHelper.isAppInAllowedList(appName: "Visual Studio Code", allowedApps: allowedApps))
    }

    // =========================================================================
    // ADDED: shouldBlockApp decision matrix & precedence
    // =========================================================================
    func test_should_not_block_app_in_allowed_list_by_path() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Xcode",
            alwaysAllowedApps: [],
            blockedApps: [],
            allowedApps: ["/Applications/Xcode.app"],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: []
        )
        XCTAssertFalse(result)
    }

    /// defaultAllowedApps is compared against the lowercased app name with an
    /// exact `contains`, so its entries must already be lowercase to match.
    func test_default_allowed_entry_must_be_lowercase_to_match() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "finder",
            alwaysAllowedApps: [],
            blockedApps: [],
            allowedApps: [],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: ["finder"]
        )
        XCTAssertFalse(result, "Lowercase default-allowed entry should match the normalised app name")
    }

    func test_default_allowed_entry_with_capital_does_not_match() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Finder",
            alwaysAllowedApps: [],
            blockedApps: [],
            allowedApps: [],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: ["Finder"]
        )
        XCTAssertTrue(result, "A capitalised default-allowed entry never matches the lowercased app name, so the app is blocked")
    }

    func test_blocked_takes_priority_over_allowed_list() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Twitter",
            alwaysAllowedApps: [],
            blockedApps: ["/Applications/Twitter.app"],
            allowedApps: ["/Applications/Twitter.app"],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: []
        )
        XCTAssertTrue(result, "Blocked list should win over allowed list")
    }

    func test_blocked_takes_priority_over_default_allowed() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "twitter",
            alwaysAllowedApps: [],
            blockedApps: ["/Applications/Twitter.app"],
            allowedApps: [],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: ["twitter"]
        )
        XCTAssertTrue(result, "Blocked list is checked before default-allowed apps")
    }

    func test_always_allowed_when_all_apps_in_focus_false() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "Calculator",
            alwaysAllowedApps: ["/Applications/Calculator.app"],
            blockedApps: [],
            allowedApps: [],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: []
        )
        XCTAssertFalse(result)
    }

    func test_unknown_app_is_blocked_with_full_config() {
        let result = AppBlockingHelper.shouldBlockApp(
            appName: "RandomApp",
            alwaysAllowedApps: ["/Applications/Calculator.app"],
            blockedApps: ["/Applications/Twitter.app"],
            allowedApps: ["/Applications/Xcode.app"],
            isAllowedAllAppsInFocus: false,
            defaultAllowedApps: ["finder"]
        )
        XCTAssertTrue(result, "An app in none of the lists should be blocked")
    }

    // MARK: The login-item LaunchAgent (report 2026-09-21_18-01-43, issue #409)
    //
    // macOS announced the auto-start item as: «"open" is an item that can run in the background».
    // It was named after the program launchd ran, and that program was /usr/bin/open.

    private var helperBundle: URL {
        URL(fileURLWithPath: "/Applications/Focus Bear.app/Contents/Resources/FBHelper.app")
    }

    func testLaunchdRunsTheHelperItselfNotUsrBinOpen() {
        let arguments = HelperLaunchAgent.programArguments(helperBundle: helperBundle)

        XCTAssertFalse(arguments.contains("/usr/bin/open"),
                       "the background item is named after this program — it must not be `open`")
        XCTAssertEqual(arguments.count, 1, "no wrapper process, so KeepAlive supervises the helper")
        XCTAssertTrue(arguments[0].hasSuffix("FBHelper.app/Contents/MacOS/FBHelper"),
                      "inside the bundle, so macOS can attribute the item to it")
    }

    func testThePlistIsWhatLaunchdNeeds() {
        let plist = HelperLaunchAgent.plist(helperBundle: helperBundle)

        XCTAssertEqual(plist["Label"] as? String, "com.focusbear.focusbearhelper")
        XCTAssertNotEqual(plist["Label"] as? String, "com.focusbear.focusbearhelper.plist",
                          "a label is not a filename")
        XCTAssertEqual(plist["RunAtLoad"] as? Bool, true)
        XCTAssertEqual(plist["KeepAlive"] as? Bool, true)
    }

    /// The check that decides whether to leave an existing agent alone. The old one returned early
    /// whenever any argument merely mentioned the helper — so the legacy /usr/bin/open agent would
    /// have been treated as current and never replaced.
    func testALegacyOpenBasedAgentIsNotMistakenForACurrentOne() {
        let legacy = ["/usr/bin/open", "-F", "-g", helperBundle.path, "--args"]
        XCTAssertFalse(HelperLaunchAgent.matchesCurrentDesign(existingArguments: legacy,
                                                              helperBundle: helperBundle),
                       "it mentions the helper, but it is exactly what we are replacing")

        let current = HelperLaunchAgent.programArguments(helperBundle: helperBundle)
        XCTAssertTrue(HelperLaunchAgent.matchesCurrentDesign(existingArguments: current,
                                                             helperBundle: helperBundle),
                      "a correct agent must be left alone, or every launch rewrites it")
    }

    func testAnAgentForSomeOtherProgramIsNotOurs() {
        XCTAssertFalse(HelperLaunchAgent.matchesCurrentDesign(existingArguments: nil,
                                                              helperBundle: helperBundle))
        XCTAssertFalse(HelperLaunchAgent.matchesCurrentDesign(existingArguments: ["/usr/bin/true"],
                                                              helperBundle: helperBundle))
    }

}
