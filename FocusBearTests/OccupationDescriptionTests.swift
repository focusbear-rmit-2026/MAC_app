//
//  OccupationDescriptionTests.swift
//  Focus BearTests
//
//  What the backend is told about someone's occupation when it generates their suggested work
//  sites. The persona used to be thrown away the moment the user typed anything into the free-text
//  box, which lost the more reliable half of the signal and broke a backend rule that depends on it.
//

import XCTest
@testable import Focus_Bear

final class OccupationDescriptionTests: XCTestCase {

    func testAnEmptyDetailLeavesThePersonaAlone() {
        XCTAssertEqual(OccupationDescription.forRelevantSites(persona: "student", detail: ""), "student")
        XCTAssertEqual(OccupationDescription.forRelevantSites(persona: "employee", detail: "   "), "employee")
    }

    /// The bug: "Computer Science" alone says nothing about whether this is a student, a lecturer or
    /// a recruiter — and it is the persona the backend's rules key off.
    func testTheDetailIsAddedToThePersonaNotSwappedForIt() {
        let described = OccupationDescription.forRelevantSites(persona: "student", detail: "Computer Science")

        XCTAssertEqual(described, "student: Computer Science")
        XCTAssertTrue(described.contains("student"), "the persona must survive the detail")
    }

    /// Canvas is suggested for students by matching the occupation against /\bstudents?\b/i
    /// (backend PR #2446). Before this, a student who typed their course did not match it.
    func testAStudentWhoTypesTheirCourseStillReadsAsAStudent() {
        let pattern = try! NSRegularExpression(pattern: "\\bstudents?\\b", options: .caseInsensitive)
        for detail in ["Computer Science", "Law", "", "Master of Public Health"] {
            let described = OccupationDescription.forRelevantSites(persona: "student", detail: detail)
            let range = NSRange(described.startIndex..., in: described)
            XCTAssertNotNil(pattern.firstMatch(in: described, range: range),
                            "\"\(described)\" must match the backend's student rule")
        }
    }

    func testEveryPersonaKeepsItsLabel() {
        for persona in ["student", "business owner", "employee", "freelancer", "other"] {
            let described = OccupationDescription.forRelevantSites(persona: persona, detail: "something typed")
            XCTAssertTrue(described.hasPrefix(persona), "\(persona) lost its label: \(described)")
        }
    }

    func testAPersonaTypedIntoTheDetailBoxIsNotRepeated() {
        XCTAssertEqual(OccupationDescription.forRelevantSites(persona: "student", detail: "Student"),
                       "student", "\"student: Student\" helps nobody")
    }

    func testWhitespaceIsTrimmedFromBothSides() {
        XCTAssertEqual(OccupationDescription.forRelevantSites(persona: "  employee  ", detail: "  nursing  "),
                       "employee: nursing")
    }

    func testAMissingPersonaFallsBackToTheDetail() {
        XCTAssertEqual(OccupationDescription.forRelevantSites(persona: "", detail: "nursing"), "nursing")
        XCTAssertEqual(OccupationDescription.forRelevantSites(persona: "", detail: ""), "")
    }
}
