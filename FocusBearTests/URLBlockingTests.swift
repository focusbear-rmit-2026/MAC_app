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

    // =========================================================================
    // ADDED: case-insensitivity, keywords, paths, multi-entry lists
    // =========================================================================
    func test_always_blocked_is_case_insensitive() {
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "HTTPS://TWITTER.COM", alwaysBlockedURLs: ["twitter.com"])
        XCTAssertTrue(result)
    }

    func test_always_blocked_matches_keyword_without_dot() {
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://m.facebook.com/messages", alwaysBlockedURLs: ["facebook"])
        XCTAssertTrue(result)
    }

    func test_always_blocked_empty_url_does_not_match() {
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "", alwaysBlockedURLs: ["facebook.com"])
        XCTAssertFalse(result)
    }

    func test_allowed_list_matches_url_with_path() {
        let result = URLBlockingHelper.isURLInAllowedList(url: "https://github.com/Focus-Bear/repo", allowedURLs: ["github.com"])
        XCTAssertTrue(result)
    }

    func test_allowed_list_matches_second_entry() {
        let result = URLBlockingHelper.isURLInAllowedList(url: "https://stackoverflow.com/q/1", allowedURLs: ["github.com", "stackoverflow.com"])
        XCTAssertTrue(result)
    }

    // =========================================================================
    // ADDED: shouldBlockURL decision matrix
    // =========================================================================
    func test_should_block_url_matches_blocked_keyword() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://reddit.com",
            alwaysBlockedURLs: ["reddit"],
            allowedURLs: [],
            isAllowedListApproach: false
        )
        XCTAssertTrue(result, "Keyword in always-blocked list should block the URL")
    }

    func test_should_not_block_url_in_allowed_list_with_path() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://github.com/explore",
            alwaysBlockedURLs: [],
            allowedURLs: ["github.com"],
            isAllowedListApproach: true
        )
        XCTAssertFalse(result, "URL whose domain is in the allowed list should not be blocked")
    }

    /// With the allowed-list approach an EMPTY allowed list blocks everything
    /// (nothing is whitelisted). Contrast with `test_empty_pattern_matches_any_url`
    /// in validationTest: an empty *list* is not the same as an empty *pattern*.
    func test_should_block_url_when_allowed_list_is_empty_in_allowed_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://github.com",
            alwaysBlockedURLs: [],
            allowedURLs: [],
            isAllowedListApproach: true
        )
        XCTAssertTrue(result)
    }

    func test_should_not_block_unlisted_url_without_allowed_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://anything.com",
            alwaysBlockedURLs: ["reddit.com"],
            allowedURLs: [],
            isAllowedListApproach: false
        )
        XCTAssertFalse(result, "Without allowed-list approach, only always-blocked URLs are blocked")
    }

    func test_always_blocked_overrides_allowed_in_allowed_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://x.com",
            alwaysBlockedURLs: ["x.com"],
            allowedURLs: ["x.com"],
            isAllowedListApproach: true
        )
        XCTAssertTrue(result, "Always-blocked should win even when the URL is also in the allowed list")
    }
}
