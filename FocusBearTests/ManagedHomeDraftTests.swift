import XCTest
@testable import Focus_Bear

final class ManagedHomeDraftTests: XCTestCase {
    private func home() -> ManagedPolicy {
        ManagedPolicy(id: "home", schoolId: "school", studentId: "child", kind: "home",
            revision: 7, status: "published", name: "Evenings", timeZone: "Australia/Melbourne",
            isEnabled: true, windows: [ManagedWindow(daysOfWeek: ["MON", "TUE", "WED", "THU", "FRI"], startTime: "16:00", endTime: "20:00", allDay: nil)],
            blockedCategories: ["games", "adult"],
            allowlist: [ManagedException(url: "https://example.edu/lesson", includeSubdomains: false,
                reason: "Class task", expiresAt: "2026-12-01T18:00:00+11:00")],
            excludedDates: [ManagedExcludedDates(startDate: "2026-12-20", endDate: "2027-01-01")],
            unknownAction: "allow", unavailableAction: "block")
    }

    func testOpeningEditorPreservesExactPublishedPayloadIncludingOptionalFields() {
        let policy = home()
        let draft = ManagedHomeDraft(policy)
        XCTAssertEqual(draft.changes, policy.changes)
        XCTAssertEqual(draft.baseRevision, 7)
        XCTAssertFalse(draft.hasChanges)
        XCTAssertNil(draft.validationKey)
        XCTAssertNil(draft.changes.windows[0].allDay)
        XCTAssertEqual(draft.changes.allowlist[0].expiresAt, "2026-12-01T18:00:00+11:00")
    }

    func testEditingCategoryDoesNotChangeSchoolOrOriginalHomeSnapshot() {
        let policy = home()
        var draft = ManagedHomeDraft(policy)
        draft.blockedCategories.append("social_networking")
        XCTAssertTrue(draft.hasChanges)
        XCTAssertEqual(policy.blockedCategories, ["games", "adult"])
        XCTAssertEqual(draft.changes.allowlist, policy.allowlist)
        XCTAssertEqual(draft.changes.windows, policy.windows)
    }

    func testOvernightAllowedButZeroLengthRequiresExplicitAllDay() {
        var draft = ManagedHomeDraft(home())
        draft.windows[0].value.startTime = "22:00"
        draft.windows[0].value.endTime = "06:00"
        XCTAssertNil(draft.validationKey)
        draft.windows[0].value.endTime = "22:00"
        XCTAssertEqual(draft.validationKey, "invalidWindow")
        draft.windows[0].value.allDay = true
        XCTAssertNil(draft.validationKey)
    }

    func testInvalidDatesAndReversedInclusiveRangeCannotBeProposed() {
        var draft = ManagedHomeDraft(home())
        draft.excludedDates[0].value.startDate = "2026-02-30"
        XCTAssertEqual(draft.validationKey, "invalidDates")
        draft.excludedDates[0].value.startDate = "2027-01-02"
        XCTAssertEqual(draft.validationKey, "invalidDates")
        draft.excludedDates[0].value.startDate = "2027-01-01"
        XCTAssertNil(draft.validationKey)
    }

    func testExceptionCannotBroadenSensitiveURLIntoAnAllowedHost() {
        for invalidURL in ["https://example.edu/lesson?token=secret", "https://example.edu/lesson#task", "https://user:password@example.edu", "file:///private/lesson"] {
            var draft = ManagedHomeDraft(home())
            draft.allowlist[0].value.url = invalidURL
            XCTAssertEqual(draft.validationKey, "invalidException")
            XCTAssertEqual(draft.changes.allowlist[0].url, invalidURL, "Validation must not silently strip query or credentials into a different exception")
        }
    }

    func testDuplicateRowsHaveStableDistinctIdentitiesAndPreserveRemainingContent() {
        var draft = ManagedHomeDraft(home())
        let first = draft.windows[0]
        draft.windows.append(ManagedEditorRow(value: first.value))
        let secondID = draft.windows[1].id
        XCTAssertNotEqual(first.id, secondID)
        draft.windows.removeAll { $0.id == first.id }
        XCTAssertEqual(draft.windows[0].id, secondID)
        XCTAssertEqual(draft.windows[0].value, first.value)
    }

    func testEmptyCategorySelectionIsAnExplicitValidParentProposal() {
        var draft = ManagedHomeDraft(home())
        draft.blockedCategories = []
        XCTAssertNil(draft.validationKey)
        XCTAssertTrue(draft.hasChanges)
        XCTAssertEqual(draft.changes.unavailableAction, "block", "Do not silently mutate fallback settings when categories are cleared")
    }
}
