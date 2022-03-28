//
//  validationTest.swift
//  Earn Your ScreentimeTests
//
//  Created by Prashant Sawnani on 26/03/22.
//  Copyright © 2022 MugPhotography. All rights reserved.
//
@testable import Earn_Your_Screentime
import XCTest

class validationTest: XCTestCase {

    var validation:urlValidation!// = urlValidation()
    func test_url_starts_with_star(){
        let expectedValue = true
        let url = "https://www.facebook.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "*facebook.com", domain: getDomainFromUrl(url: url))

        XCTAssertEqual(bool, expectedValue)
    }

    func test_url_ends_with_star(){
        let expectedValue = true
        let url = "https://www.facebook.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "facebook*", domain: getDomainFromUrl(url: url))

        XCTAssertEqual(bool, expectedValue)
    }
    
    func test_url_starts_and_ends_with_star(){
        let expectedValue = true
        let url = "https://www.facebook.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "*facebook*", domain: getDomainFromUrl(url: url))

        XCTAssertEqual(bool, expectedValue)
    }
    
    func test_url_without_star(){
        let expectedValue = true
        let url = "https://www.facebook.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "facebook", domain: getDomainFromUrl(url: url))

        XCTAssertEqual(bool, expectedValue)
    }
    
    func test_url_star_at_middle(){
        let expectedValue = true
        let url = "https://www.fammmcebllllook.c88m"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "f*ce*ook.c*m", domain: getDomainFromUrl(url: url))

        XCTAssertEqual(bool, expectedValue)
    }
    
    
    func test_url_local_file(){
        let expectedValue = true
        let url = "file:///Users/prashant/Desktop/claimage.jpg"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "file:///*", domain: getDomainFromUrl(url: url))

        XCTAssertEqual(bool, expectedValue)
    }
    
    
    func test_url_with_subdomain_when_main_domain_added(){
        let expectedValue = true
        let url = "https://desk.zoho.com"
        let bool = validation.isUrlValid(urlToCheck: url, allowUrl: "zoho.com", domain: getDomainFromUrl(url: url))

        XCTAssertEqual(bool, expectedValue)
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
