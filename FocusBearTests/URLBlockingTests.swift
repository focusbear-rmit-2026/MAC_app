//
//  URLBlockingTests.swift
//  Focus BearTests
//
//  Created by Devin AI on 17/01/26.
//

@testable import Focus_Bear
import XCTest

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
