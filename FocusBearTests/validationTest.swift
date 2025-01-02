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
    func test_url_with_subdomain_when_main_domain_added(){
        let expectedValue = false
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
    
    override func setUp() {
        super.setUp()
        validation = urlValidation()
    }
    override func tearDown() {
        validation = nil
        super.tearDown()
    }
}
