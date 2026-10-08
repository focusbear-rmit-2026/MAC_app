@testable import Focus_Bear
import XCTest

/// "Fix" — the modal behind the Day Plan's red over-capacity warning: which routes it offers for a
/// given day, in what order, and what each one may do to a meeting (report 2026-09-17_08-15-57).
final class DayFixPlanTests: XCTestCase {

    // MARK: The routes offered on an over-committed day

    /// Ordered by capacity freed, largest first. Three equal buttons would make the user do the
    /// arithmetic the app has already done.
    func testFixRoutesAreOrderedByHowMuchRoomEachCouldFree() {
        let options = DayFixPlan.options(meetingMinutes: 45, habitMinutes: 20, taskMinutes: 180)
        XCTAssertEqual(options.map(\.route), [.tasks, .meetings, .routine],
                       "180 minutes of tasks is the answer before 45 of meetings and 20 of habits")
        XCTAssertEqual(options.first?.freeableMinutes, 180)
    }

    /// A route that cannot free a minute is a dead button, and every row in this modal is supposed to
    /// move the number at the top.
    func testARouteWithNothingBehindItIsNotOfferedAtAll() {
        XCTAssertTrue(DayFixPlan.options(meetingMinutes: 0, habitMinutes: 0, taskMinutes: 0).isEmpty)
        XCTAssertEqual(DayFixPlan.options(meetingMinutes: 0, habitMinutes: 0, taskMinutes: 90).map(\.route),
                       [.tasks], "Only what can actually help")
        XCTAssertEqual(DayFixPlan.options(meetingMinutes: 30, habitMinutes: 0, taskMinutes: 0).map(\.route),
                       [.meetings], "A day whose only slack is its meetings gets the meetings route")
    }

    func testEqualRoutesKeepTheOrderTheReportListedThemIn() {
        let options = DayFixPlan.options(meetingMinutes: 60, habitMinutes: 60, taskMinutes: 60)
        XCTAssertEqual(options.map(\.route), [.meetings, .routine, .tasks],
                       "A tie is broken by the report's own order, not arbitrarily")
    }

    // MARK: The lists inside a route

    /// "habits sorted by duration descending" — that is where the minutes are.
    func testTheRoutineListPutsTheLongestHabitFirst() {
        let sorted = DayFixPlan.longestFirst(
            [Row(seconds: 300, name: "Stretch"), Row(seconds: 1800, name: "Meditate"), Row(seconds: 600, name: "Journal")],
            seconds: { $0.seconds }, name: { $0.name })
        XCTAssertEqual(sorted.map(\.name), ["Meditate", "Journal", "Stretch"])
    }

    func testHabitsOfEqualLengthDoNotReshuffleBetweenRenders() {
        let rows = [Row(seconds: 600, name: "Zebra"), Row(seconds: 600, name: "Apple")]
        let once = DayFixPlan.longestFirst(rows, seconds: { $0.seconds }, name: { $0.name }).map(\.name)
        let twice = DayFixPlan.longestFirst(rows.reversed(), seconds: { $0.seconds }, name: { $0.name }).map(\.name)
        XCTAssertEqual(once, ["Apple", "Zebra"])
        XCTAssertEqual(once, twice, "Same habits, same order, however they arrive")
    }

    // MARK: Which habits the routine route may offer

    /// "Evening routine isn't relevant as we assume all tasks get completed before evening routine -
    /// just offer to shorten morning routine" (report follow-up). The modal used to list the whole
    /// day's habits, so it claimed hours of habits on a day whose morning routine was minutes.
    func testTheEveningRoutineIsNotOfferedAsAWayToFitTodaysTasks() {
        let day = DayFixPlanTests.day
        let habits = [
            Habit(name: "Meditate", start: DayFixPlanTests.at(7, day: day), routine: morningRoutine),
            Habit(name: "Wind down", start: DayFixPlanTests.at(21, day: day), routine: eveningRoutine),
        ]
        let offered = DayFixPlan.habitsInsideWorkingDay(
            habits, start: { $0.start }, isEveningRoutine: { $0.routine == eveningRoutine },
            eveningRoutineStart: DayFixPlanTests.at(20, day: day))
        XCTAssertEqual(offered.map(\.name), ["Meditate"])
    }

    /// The rule is the reason — anything that runs after the tasks were meant to be done frees
    /// nothing for them — so a custom routine parked at the end of the day goes too, while one at
    /// lunchtime, which really does eat into the day's tasks, stays.
    func testOnlyHabitsThatRunBeforeTheEveningRoutineCount() {
        let day = DayFixPlanTests.day
        let habits = [
            Habit(name: "Lunch reset", start: DayFixPlanTests.at(12, day: day), routine: "Midday habits"),
            Habit(name: "Tidy desk", start: DayFixPlanTests.at(22, day: day), routine: "Night habits"),
        ]
        let offered = DayFixPlan.habitsInsideWorkingDay(
            habits, start: { $0.start }, isEveningRoutine: { $0.routine == eveningRoutine },
            eveningRoutineStart: DayFixPlanTests.at(20, day: day))
        XCTAssertEqual(offered.map(\.name), ["Lunch reset"])
    }

    /// Without a shutdown time there is no evening to be after, so nothing is dropped on a guess —
    /// hiding a habit the user could have shortened is worse than listing one they won't.
    func testWithNoEveningRoutineTimeEveryHabitIsStillOffered() {
        let day = DayFixPlanTests.day
        let habits = [Habit(name: "Meditate", start: DayFixPlanTests.at(7, day: day), routine: morningRoutine),
                      Habit(name: "Read", start: DayFixPlanTests.at(23, day: day), routine: "Night habits")]
        let offered = DayFixPlan.habitsInsideWorkingDay(
            habits, start: { $0.start }, isEveningRoutine: { $0.routine == eveningRoutine },
            eveningRoutineStart: nil)
        XCTAssertEqual(offered.count, 2)
    }

    // MARK: What one meeting is allowed to offer

    /// The report's three-way rule: "Cancel (if they own it) / Decline (if there are other attendees
    /// but they don't own it) / Skip (if there are no other attendees)".
    func testAMeetingWithNobodyElseOnItIsOnlyEverSkipped() {
        for ownership in [EventOwnership.owned, .notOwned, .unknown] {
            XCTAssertEqual(DayFixPlan.meetingAction(hasOtherAttendees: false, ownership: ownership), .skip,
                           "There is nobody to notify, whoever owns it")
        }
    }

    func testTheOrganiserOfAMeetingWithAttendeesIsOfferedCancel() {
        XCTAssertEqual(DayFixPlan.meetingAction(hasOtherAttendees: true, ownership: .owned), .cancel)
    }

    func testAnAttendeeIsOfferedDeclineRatherThanCancel() {
        XCTAssertEqual(DayFixPlan.meetingAction(hasOtherAttendees: true, ownership: .notOwned), .decline)
    }

    /// Cancelling takes the meeting off everyone else's calendar, so it must never happen on a guess —
    /// the same rule the event editor's destructive button follows, stated in one place.
    func testUnknownOwnershipNeverOffersToCancelForEveryone() {
        XCTAssertEqual(DayFixPlan.meetingAction(hasOtherAttendees: true, ownership: .unknown), .decline)
    }

    // MARK: Trimming a meeting for one day

    /// The trim is the Day Plan's, not the calendar's: it shortens the slot the day reserves, on one
    /// day, and can be taken back.
    func testShorteningAMeetingOnlyAffectsTheDayItWasShortenedOn() throws {
        let defaults = try makeDefaults()
        let day = DayFixPlanTests.day
        let start = DayFixPlanTests.at(9, day: day)
        let end = start.addingTimeInterval(3600)
        DayPlanMeetingDurations.setOverride(30 * 60, forEventID: "event-1", on: day, actual: 3600,
                                            defaults: defaults)

        XCTAssertEqual(DayPlanMeetingDurations.trimmedEnd(forEventID: "event-1", on: day, start: start,
                                                          end: end, defaults: defaults),
                       start.addingTimeInterval(30 * 60))
        let tomorrow = day.addingTimeInterval(24 * 3600)
        XCTAssertEqual(DayPlanMeetingDurations.trimmedEnd(forEventID: "event-1", on: tomorrow, start: start,
                                                          end: end, defaults: defaults),
                       end, "Tomorrow's occurrence keeps its real length")
        XCTAssertEqual(DayPlanMeetingDurations.trimmedEnd(forEventID: "other", on: day, start: start,
                                                          end: end, defaults: defaults),
                       end, "Another meeting is untouched")
    }

    func testAskingForTheMeetingsRealLengthClearsTheTrimInsteadOfStoringOne() throws {
        let defaults = try makeDefaults()
        let day = DayFixPlanTests.day
        DayPlanMeetingDurations.setOverride(30 * 60, forEventID: "event-1", on: day, actual: 3600, defaults: defaults)
        XCTAssertEqual(DayPlanMeetingDurations.setOverride(3600, forEventID: "event-1", on: day, actual: 3600,
                                                          defaults: defaults), nil)
        XCTAssertNil(DayPlanMeetingDurations.overrideSeconds(forEventID: "event-1", on: day, defaults: defaults))
    }

    /// A trim only ever shortens — a stored value longer than the meeting (the meeting was extended on
    /// the calendar after it was trimmed) must not stretch the slot back out.
    func testATrimNeverMakesAMeetingLongerThanItReallyIs() throws {
        let defaults = try makeDefaults()
        let day = DayFixPlanTests.day
        let start = DayFixPlanTests.at(9, day: day)
        DayPlanMeetingDurations.setOverride(50 * 60, forEventID: "event-1", on: day, actual: 3600, defaults: defaults)
        let shorterEnd = start.addingTimeInterval(20 * 60)
        XCTAssertEqual(DayPlanMeetingDurations.trimmedEnd(forEventID: "event-1", on: day, start: start,
                                                          end: shorterEnd, defaults: defaults),
                       shorterEnd)
    }

    func testOldDaysAreDroppedSoTheTrimMapCannotGrowWithoutBound() {
        var map = [String: [String: Int]]()
        for dayOffset in 0..<(DayPlanMeetingDurations.retainedDays + 10) {
            map[String(format: "2026-01-%02d", dayOffset + 1)] = ["event-1": 600]
        }
        let pruned = DayPlanMeetingDurations.pruned(map)
        XCTAssertEqual(pruned.count, DayPlanMeetingDurations.retainedDays)
        XCTAssertEqual(pruned.keys.min(), map.keys.sorted().suffix(DayPlanMeetingDurations.retainedDays).first,
                       "The days kept are the most recent ones")
    }

    // MARK: - Fixtures

    private struct Row {
        let seconds: Int
        let name: String
    }

    private struct Habit {
        let name: String
        let start: Date
        let routine: String
    }

    private let morningRoutine = "Morning routine habits"
    private let eveningRoutine = "Evening routine habits"

    private static let day = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_757_980_800))

    private static func at(_ hour: Int, day: Date) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    /// A defaults suite of this test's own, so a stored trim can't leak into the app's real one.
    private func makeDefaults() throws -> UserDefaults {
        let name = "DayFixPlanTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        addTeardownBlock { UserDefaults.standard.removePersistentDomain(forName: name) }
        return defaults
    }
}
