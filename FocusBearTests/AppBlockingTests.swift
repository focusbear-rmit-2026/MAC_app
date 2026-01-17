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
}

class URLBlockingTests: XCTestCase {
    
    var validation: urlValidation!
    
    override func setUp() {
        super.setUp()
        validation = urlValidation()
    }
    
    override func tearDown() {
        validation = nil
        super.tearDown()
    }
    
    func test_url_in_always_blocked_list() {
        let alwaysBlockedURLs = ["facebook.com", "twitter.com"]
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://www.facebook.com", alwaysBlockedURLs: alwaysBlockedURLs)
        XCTAssertTrue(result)
    }
    
    func test_url_not_in_always_blocked_list() {
        let alwaysBlockedURLs = ["facebook.com", "twitter.com"]
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://www.github.com", alwaysBlockedURLs: alwaysBlockedURLs)
        XCTAssertFalse(result)
    }
    
    func test_url_in_allowed_list() {
        let allowedURLs = ["github.com", "stackoverflow.com"]
        let result = URLBlockingHelper.isURLInAllowedList(url: "https://github.com/Focus-Bear", allowedURLs: allowedURLs)
        XCTAssertTrue(result)
    }
    
    func test_url_not_in_allowed_list() {
        let allowedURLs = ["github.com", "stackoverflow.com"]
        let result = URLBlockingHelper.isURLInAllowedList(url: "https://www.facebook.com", allowedURLs: allowedURLs)
        XCTAssertFalse(result)
    }
    
    func test_should_block_url_when_in_always_blocked_list() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://www.facebook.com",
            alwaysBlockedURLs: ["facebook.com"],
            allowedURLs: ["facebook.com"],
            isAllowedListApproach: false
        )
        XCTAssertTrue(result, "URL in always blocked list should be blocked")
    }
    
    func test_should_block_url_when_not_in_allowed_list_with_allowed_list_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://www.twitter.com",
            alwaysBlockedURLs: [],
            allowedURLs: ["github.com", "stackoverflow.com"],
            isAllowedListApproach: true
        )
        XCTAssertTrue(result, "URL not in allowed list should be blocked when using allowed list approach")
    }
    
    func test_should_not_block_url_when_in_allowed_list_with_allowed_list_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://github.com/Focus-Bear",
            alwaysBlockedURLs: [],
            allowedURLs: ["github.com"],
            isAllowedListApproach: true
        )
        XCTAssertFalse(result, "URL in allowed list should not be blocked when using allowed list approach")
    }
    
    func test_should_not_block_url_when_not_using_allowed_list_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://www.twitter.com",
            alwaysBlockedURLs: [],
            allowedURLs: [],
            isAllowedListApproach: false
        )
        XCTAssertFalse(result, "URL should not be blocked when not using allowed list approach and not in blocked list")
    }
    
    func test_always_blocked_takes_priority_over_allowed() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://www.facebook.com",
            alwaysBlockedURLs: ["facebook.com"],
            allowedURLs: ["facebook.com"],
            isAllowedListApproach: true
        )
        XCTAssertTrue(result, "Always blocked should take priority over allowed list")
    }
    
    func test_url_with_wildcard_in_blocked_list() {
        let alwaysBlockedURLs = ["*facebook*"]
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://m.facebook.com/messages", alwaysBlockedURLs: alwaysBlockedURLs)
        XCTAssertTrue(result)
    }
    
    func test_url_with_subdomain_blocked() {
        let alwaysBlockedURLs = ["*.facebook.com"]
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://m.facebook.com", alwaysBlockedURLs: alwaysBlockedURLs)
        XCTAssertTrue(result)
    }
    
    func test_empty_always_blocked_list() {
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://www.facebook.com", alwaysBlockedURLs: [])
        XCTAssertFalse(result)
    }
    
    func test_empty_allowed_list() {
        let result = URLBlockingHelper.isURLInAllowedList(url: "https://www.github.com", allowedURLs: [])
        XCTAssertFalse(result)
    }
}
