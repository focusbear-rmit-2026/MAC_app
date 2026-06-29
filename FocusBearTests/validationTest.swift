//
//  validationTest.swift
//  Focus BearTests
//
//  Created by Prashant Sawnani on 26/03/22.

@testable import Focus_Bear
import XCTest

class validationTest: XCTestCase {

    var validation:urlValidation!// = urlValidation()
    func test_url_starts_with_star(){
        let expectedValue = true
        let url = "https://www.facebook.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "*facebook.com")

        XCTAssertEqual(bool, expectedValue)
    }

    func test_url_ends_with_star(){
        let expectedValue = true
        let url = "https://www.facebook.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "facebook*")

        XCTAssertEqual(bool, expectedValue)
    }
    
    func test_url_starts_and_ends_with_star(){
        let expectedValue = true
        let url = "https://www.facebook.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "*facebook*")

        XCTAssertEqual(bool, expectedValue)
    }
    
    func test_url_without_star(){
        let expectedValue = true
        let url = "https://www.facebook.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "facebook")

        XCTAssertEqual(bool, expectedValue)
    }
    
    func test_url_star_at_middle(){
        let expectedValue = true
        let url = "https://www.fammmcebllllook.c88m"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "f*ce*ook.c*m")

        XCTAssertEqual(bool, expectedValue)
    }
    
    
    func test_url_local_file(){
        let expectedValue = true
        let url = "file:///Users/prashant/Desktop/claimage.jpg"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "file:///*")

        XCTAssertEqual(bool, expectedValue)
    }
    
    func test_perfect_url(){
        let expectedValue = true
        let url = "https://www.facebook.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "https://www.facebook.com")

        XCTAssertEqual(bool, expectedValue)
    }
    // A bare domain is wrapped to "*zoho.com*", so it matches its subdomains.
    // This is the desired behaviour: blocking/allowing "zoho.com" also covers
    // "desk.zoho.com". (Originally asserted false; updated to match the shipped
    // matcher — see issue history for the move to substring matching.)
    func test_url_with_subdomain_when_main_domain_added(){
        let expectedValue = true
        let url = "https://desk.zoho.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "zoho.com")

        XCTAssertEqual(bool, expectedValue)
    }
    func test_url_with_subdomain_when_main_domain_added_with_leading_star_and_dot(){
        let expectedValue = true
        let url = "https://desk.zoho.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "*.zoho.com")

        XCTAssertEqual(bool, expectedValue)
    }
    func test_url_with_subdomain_when_main_domain_added_with_leading_star_without_dot(){
        let expectedValue = true
        let url = "https://desk.zoho.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "*zoho.com")

        XCTAssertEqual(bool, expectedValue)
    }

    func test_is_Url_allowed_blocked_combination_allowed(){
        let expectedValue = true
        let allowedUrl = "github.com"
        let blockedUrl = "github.com/ram"
        let currentTestUrl = "github.com"

        var isBlocked = false
        isBlocked = self.validation.isUrlValid(urlToCheck: currentTestUrl, allowUrl: blockedUrl)
        
        var isAllowed = false
        if !isBlocked{
            isAllowed = self.validation.isUrlValid(urlToCheck: currentTestUrl, allowUrl: allowedUrl)
        }
        XCTAssertEqual(isAllowed, expectedValue)
    }
    
    func test_is_Url_allowed_blocked_combination_blocked(){
        let expectedValue = false
        let allowedUrl = "github.com"
        let blockedUrl = "github.com/ram"
        let currentTestUrl = "github.com/ram"

        var isBlocked = false
        isBlocked = self.validation.isUrlValid(urlToCheck: currentTestUrl, allowUrl: blockedUrl)
        
        var isAllowed = false
        if !isBlocked{
            isAllowed = self.validation.isUrlValid(urlToCheck: currentTestUrl, allowUrl: allowedUrl)
        }
        XCTAssertEqual(isAllowed, expectedValue)
    }
    func test_is_Url_allowed_blocked_combination_blocked_2(){
        let expectedValue = true
        let allowedUrl = "github.com"
        let blockedUrl = "github.com/ram"
        let currentTestUrl = "github.com/ram/shyam"

        var isBlocked = false
        isBlocked = self.validation.isUrlValid(urlToCheck: currentTestUrl, allowUrl: blockedUrl)
        
        var isAllowed = false
        if !isBlocked{
            isAllowed = self.validation.isUrlValid(urlToCheck: currentTestUrl, allowUrl: allowedUrl)
        }
        XCTAssertEqual(!isAllowed, expectedValue)
    }
   
    func test_is_Url_allowed_blocked_same_combination_blocked(){
        let expectedValue = true
        let allowedUrl = "github.com/ram"
        let blockedUrl = "github.com/ram"
        let currentTestUrl = "github.com/ram/shyam"

        var isBlocked = false
        isBlocked = self.validation.isUrlValid(urlToCheck: currentTestUrl, allowUrl: blockedUrl)
        
        var isAllowed = false
        if !isBlocked{
            isAllowed = self.validation.isUrlValid(urlToCheck: currentTestUrl, allowUrl: allowedUrl)
        }
        XCTAssertEqual(!isAllowed, expectedValue)
    }
    
    // =========================================================================
    // ADDED: scheme / case / path normalisation
    // =========================================================================
    func test_http_scheme_is_stripped() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "http://www.facebook.com", allowUrl: "facebook.com"))
    }

    func test_match_is_case_insensitive_for_uppercase_url() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "HTTPS://WWW.FACEBOOK.COM", allowUrl: "facebook.com"))
    }

    func test_match_is_case_insensitive_for_uppercase_pattern() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "https://www.facebook.com", allowUrl: "FACEBOOK.COM"))
    }

    func test_url_with_path_matches_domain() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "https://www.facebook.com/feed", allowUrl: "facebook.com"))
    }

    func test_url_with_query_string_matches_domain() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "https://facebook.com/?ref=1", allowUrl: "facebook.com"))
    }

    func test_keyword_without_dot_matches_subdomain() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "https://m.facebook.com", allowUrl: "facebook"))
    }

    func test_unrelated_url_does_not_match() {
        XCTAssertFalse(validation.isUrlValid(urlToCheck: "https://github.com", allowUrl: "facebook.com"))
    }

    func test_www_prefixed_pattern_matches() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "https://www.facebook.com", allowUrl: "www.facebook.com"))
    }

    // =========================================================================
    // ADDED: wildcard quirks (these document ACTUAL behaviour of isUrlValid)
    // =========================================================================

    /// An empty pattern is wrapped to "**", which LIKE-matches every string.
    /// Documents a footgun: an empty allow/block entry matches every URL.
    func test_empty_pattern_matches_any_url() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "https://github.com", allowUrl: ""))
    }

    /// "?" is a single-character wildcard in NSPredicate LIKE.
    func test_question_mark_is_single_char_wildcard() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "ab", allowUrl: "a?"))
    }

    /// "*.zoho.com" requires a leading "." so it does NOT match the bare domain.
    func test_leading_star_dot_does_not_match_bare_domain() {
        XCTAssertFalse(validation.isUrlValid(urlToCheck: "https://zoho.com", allowUrl: "*.zoho.com"))
    }

    // =========================================================================
    // ADDED: x.com special-case (issue #1209 — avoid matching e.g. netflix.com)
    // =========================================================================
    func test_x_com_matches_exact() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "https://x.com", allowUrl: "x.com"))
    }

    func test_x_com_matches_with_www() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "https://www.x.com", allowUrl: "x.com"))
    }

    func test_x_com_does_not_match_netflix() {
        XCTAssertFalse(validation.isUrlValid(urlToCheck: "https://netflix.com", allowUrl: "x.com"))
    }

    func test_x_com_does_not_match_max() {
        XCTAssertFalse(validation.isUrlValid(urlToCheck: "https://max.com", allowUrl: "x.com"))
    }

    func test_x_com_does_not_match_twitter() {
        XCTAssertFalse(validation.isUrlValid(urlToCheck: "https://twitter.com", allowUrl: "x.com"))
    }

    /// No letter precedes "x.com" in "x.company", so the guard does not fire
    /// and it still matches — documents a remaining edge of the #1209 fix.
    func test_x_com_matches_x_company() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "https://x.company", allowUrl: "x.com"))
    }

    // =========================================================================
    // ADDED: file:// handling
    // =========================================================================
    func test_file_pattern_matches_file_url() {
        XCTAssertTrue(validation.isUrlValid(urlToCheck: "file:///Users/a/photo.jpg", allowUrl: "file:///*"))
    }

    func test_file_pattern_does_not_match_http_url() {
        XCTAssertFalse(validation.isUrlValid(urlToCheck: "https://x.com", allowUrl: "file:///*"))
    }

    override func setUp() {
        super.setUp()
        validation = urlValidation()
    }
    override func tearDown() {
        validation = nil
        super.tearDown()
    }
}
