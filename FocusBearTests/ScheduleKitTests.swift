//
//  ScheduleKitTests.swift
//  Focus BearTests
//
//  Unit tests for the pure Day Plan scheduling engine (ScheduleBuilder). These lock in the
//  placement rules that have been bug-prone: in-order packing, filling the gap before a meeting
//  with a shorter later habit, capping at the routine window, and dropping past-cutoff habits.
//

@testable import Focus_Bear
import XCTest

final class ScheduleKitTests: XCTestCase {

    // MARK: - Builders

    /// A Date at h:m today (the engine packs habits from `now`, all same-day here).
    private func t(_ h: Int, _ m: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date())!
    }

    /// A Date at h:m `dayOffset` days from today — for the past/future-day plans, which anchor at that
    /// day's morning-routine start rather than `Date()`.
    private func day(_ dayOffset: Int, _ h: Int, _ m: Int = 0) -> Date {
        let cal = Calendar.current
        let base = cal.date(byAdding: .day, value: dayOffset, to: Date())!
        return cal.date(bySettingHour: h, minute: m, second: 0, of: base)!
    }

    private func habit(_ idx: Int, _ title: String, minutes: Int,
                       cutoff: Date? = nil, playing: Bool = false, elapsed: Int = 0) -> ScheduleHabitInput {
        ScheduleHabitInput(index: idx, title: title, durationSeconds: minutes * 60,
                           isPlaying: playing, elapsedSeconds: elapsed, cutoff: cutoff)
    }

    private func seg(_ habits: [ScheduleHabitInput], start: Date, end: Date,
                     actionable: Bool = true, name: String = "Morning") -> ScheduleRoutineSegment {
        ScheduleRoutineSegment(name: name, habits: habits, windowStart: start, windowEnd: end, actionable: actionable)
    }

    private func build(_ segs: [ScheduleRoutineSegment], meetings: [ScheduleMeetingInput] = [],
                       now: Date, dayEnd: Date, buffer: Int = 0) -> [ScheduleBlock] {
        ScheduleBuilder.build(segments: segs, meetings: meetings, now: now, dayEnd: dayEnd,
                              leaveBufferSeconds: buffer, outOfOrderAllowed: false)
    }

    private func habitBlocks(_ blocks: [ScheduleBlock]) -> [ScheduleBlock] {
        blocks.filter { $0.kind == .habit }.sorted { $0.start < $1.start }
    }

    // MARK: - Placement order

    func testHabitsPackedInOrderBackToBack() {
        let now = t(9, 0)
        let segs = [seg([habit(0, "A", minutes: 10),
                         habit(1, "B", minutes: 15),
                         habit(2, "C", minutes: 5)], start: now, end: t(12, 0))]
        let blocks = habitBlocks(build(segs, now: now, dayEnd: t(18, 0)))
        XCTAssertEqual(blocks.map { $0.title }, ["A", "B", "C"])
        XCTAssertEqual(blocks[0].start, now)
        XCTAssertEqual(blocks[1].start, blocks[0].end)   // back-to-back
        XCTAssertEqual(blocks[2].start, blocks[1].end)
    }

    // MARK: - Gap filling: a shorter later habit fills what's left of a gap

    func testShorterLaterHabitFillsRemainingWindow() {
        let now = t(9, 0)
        // Window 9:00–9:20. A=10m fits; B=30m doesn't fit anywhere; C=5m fits in the 10 min left, so
        // it's pulled forward rather than leaving that time as deep work. B is the only overflow.
        let segs = [seg([habit(0, "A", minutes: 10),
                         habit(1, "B", minutes: 30),
                         habit(2, "C", minutes: 5)], start: now, end: t(9, 20))]
        let blocks = habitBlocks(build(segs, now: now, dayEnd: t(18, 0)))
        let timed = blocks.filter { !$0.didOverflow }
        XCTAssertEqual(timed.map { $0.title }, ["A", "C"])
        XCTAssertEqual(timed[1].start, timed[0].end, "C is pulled forward into the time B couldn't use")
        // The habit that fit nowhere isn't dropped: it forms the "not enough time today" group,
        // anchored after the last habit that did fit so it sorts below it.
        let overflow = blocks.filter { $0.didOverflow }
        XCTAssertEqual(overflow.map { $0.title }, ["B"])
        XCTAssertTrue(overflow.allSatisfy { $0.start >= timed[1].end })
        XCTAssertTrue(overflow.allSatisfy { $0.isActionable })
    }

    // MARK: - Gap before a meeting (the reported morning: 06:30 routine, meetings from 07:00)

    private var screenshotHabits: [ScheduleHabitInput] {
        [habit(0, "A", minutes: 5), habit(1, "B", minutes: 8), habit(2, "C", minutes: 45),
         habit(3, "D", minutes: 10), habit(4, "E", minutes: 20)]
    }

    private var screenshotMeetings: [ScheduleMeetingInput] {
        [ScheduleMeetingInput(id: "m1", title: "Help with Sean", start: t(7, 0), end: t(8, 0)),
         ScheduleMeetingInput(id: "m2", title: "Standup", start: t(8, 15), end: t(9, 0))]
    }

    func testGapBeforeMeetingFilledByShorterHabitAndLongHabitMovesPastMeetings() {
        let now = t(6, 30)
        // Window runs well past the meetings (the morning window ends at the shutdown time).
        let segs = [seg(screenshotHabits, start: now, end: t(12, 0))]
        let blocks = build(segs, meetings: screenshotMeetings, now: now, dayEnd: t(18, 0))
        let habits = habitBlocks(blocks)
        XCTAssertTrue(habits.allSatisfy { !$0.didOverflow }, "everything fits somewhere in the window")
        // A and B fill 06:30–06:43; C (45m) can't finish before 07:00, so D (10m) is pulled forward
        // into 06:43–06:53. E (20m) doesn't fit in the 7 min left, nor in the 15 min between meetings.
        // C then lands in the first gap after the meetings that fits it, and E follows in order.
        XCTAssertEqual(habits.map { $0.title }, ["A", "B", "D", "C", "E"])
        XCTAssertEqual(habits[2].start, t(6, 43))
        XCTAssertEqual(habits[2].end, t(6, 53))
        XCTAssertEqual(habits[3].start, t(9, 0))
        XCTAssertEqual(habits[4].start, t(9, 45))
        // The gap before the meeting is filled with habits, not deep work.
        let deepWorkBeforeMeeting = blocks.filter { $0.kind == .deepWork && $0.start < t(7, 0) }
        XCTAssertTrue(deepWorkBeforeMeeting.isEmpty, "no deep-work block before the meeting while a habit still fits")
        // The 15 min between the meetings fits no remaining habit, so that gap IS deep work.
        XCTAssertTrue(blocks.contains { $0.kind == .deepWork && $0.start == t(8, 0) && $0.end == t(8, 15) })
        XCTAssertEqual(habits.filter { $0.isCurrent }.map { $0.title }, ["A"])
    }

    func testHabitThatFitsNowhereInWindowOverflows() {
        let now = t(6, 30)
        // Window ends at 09:30: after the meetings only 30 min remain, so C (45m) fits nowhere and
        // must surface in the "not enough time today" group; E (20m) still takes the 09:00 slot.
        let segs = [seg(screenshotHabits, start: now, end: t(9, 30))]
        let habits = habitBlocks(build(segs, meetings: screenshotMeetings, now: now, dayEnd: t(18, 0)))
        let timed = habits.filter { !$0.didOverflow }
        XCTAssertEqual(timed.map { $0.title }, ["A", "B", "D", "E"])
        XCTAssertEqual(timed[3].start, t(9, 0))
        let overflow = habits.filter { $0.didOverflow }
        XCTAssertEqual(overflow.map { $0.title }, ["C"])
        XCTAssertTrue(overflow.allSatisfy { $0.start >= t(9, 20) }, "overflow sorts below the last placed habit")
        XCTAssertTrue(overflow.allSatisfy { $0.isActionable })
    }

    func testLeaveBufferShrinksGapBeforeMeeting() {
        let now = t(6, 30)
        // 5 min buffer: the gap is 06:30–06:43 (not 06:48), so A (15m) can't be squeezed in and moves
        // past the meeting while B (10m) fills the gap.
        let meeting = ScheduleMeetingInput(id: "m1", title: "Standup", start: t(6, 48), end: t(7, 0))
        let segs = [seg([habit(0, "A", minutes: 15), habit(1, "B", minutes: 10)], start: now, end: t(12, 0))]
        let habits = habitBlocks(build(segs, meetings: [meeting], now: now, dayEnd: t(18, 0), buffer: 5 * 60))
        XCTAssertEqual(habits.map { $0.title }, ["B", "A"])
        XCTAssertEqual(habits[0].start, now)
        XCTAssertEqual(habits[1].start, t(7, 0))
    }

    func testPlayingHabitUsesRemainingDurationToFit() {
        let now = t(6, 30)
        // A is 30m but has 20m elapsed: its remaining 10m fits before the 06:45 meeting.
        let meeting = ScheduleMeetingInput(id: "m1", title: "Standup", start: t(6, 45), end: t(7, 0))
        let segs = [seg([habit(0, "A", minutes: 30, playing: true, elapsed: 20 * 60)], start: now, end: t(12, 0))]
        let habits = habitBlocks(build(segs, meetings: [meeting], now: now, dayEnd: t(18, 0)))
        XCTAssertEqual(habits.map { $0.start }, [now])
        XCTAssertEqual(habits[0].end, t(6, 40))
    }

    // MARK: - Not enough time today (overflow group)

    func testWholeDayEventPutsEntireRoutineInOverflowGroup() {
        let now = t(9, 0)
        // A meeting spanning the whole routine window: no habit can be placed at all. The routine must
        // still be visible (and doable) as one collapsed "not enough time today" group — not vanish.
        let allDay = ScheduleMeetingInput(id: "m1", title: "Offsite", start: t(8, 0), end: t(18, 0))
        let segs = [seg([habit(0, "A", minutes: 10),
                         habit(1, "B", minutes: 15)], start: now, end: t(12, 0))]
        let blocks = habitBlocks(build(segs, meetings: [allDay], now: now, dayEnd: t(18, 0)))
        XCTAssertEqual(blocks.map { $0.title }, ["A", "B"])
        XCTAssertTrue(blocks.allSatisfy { $0.didOverflow }, "nothing fit, so the whole routine overflows")
        XCTAssertTrue(blocks.allSatisfy { $0.isActionable })
        // With no timed habit, the first overflow habit is the routine's next-up selection.
        XCTAssertEqual(blocks.filter { $0.isCurrent }.map { $0.title }, ["A"])
    }

    /// A preview (non-actionable) routine used to DROP the habits that didn't fit, so the plan silently
    /// claimed the routine fitted. It must surface them as an overflow group too — just not actionable.
    func testPreviewSegmentSurfacesOverflowGroupWithoutMakingItActionable() {
        let now = t(9, 0)
        let allDay = ScheduleMeetingInput(id: "m1", title: "Offsite", start: t(8, 0), end: t(18, 0))
        let segs = [seg([habit(0, "A", minutes: 10)], start: now, end: t(12, 0), actionable: false)]
        let blocks = habitBlocks(build(segs, meetings: [allDay], now: now, dayEnd: t(18, 0)))
        XCTAssertEqual(blocks.map { $0.title }, ["A"])
        XCTAssertTrue(blocks.allSatisfy { $0.didOverflow })
        XCTAssertTrue(blocks.allSatisfy { !$0.isActionable && !$0.isCurrent }, "a preview routine stays read-only")
        XCTAssertTrue(blocks.allSatisfy { $0.isEditable })
    }

    /// The reported case (Sat 12 Sep): a FUTURE day whose plan is boxed in by all-day-ish events —
    /// sleep until 6:30, then meetings from 7:00 through past the evening routine start. Only 27
    /// minutes of the morning routine fit; the rest has nowhere to go anywhere in the routine's
    /// window, and the plan must say so instead of rendering a tidy 6:30–6:57 range.
    func testFutureDayWithNoRoomFlagsTheRestOfTheRoutineAsOverflow() {
        // Another day's plan anchors at that day's morning-routine start, not `Date()`.
        let now = day(2, 5, 0)
        let meetings = [
            ScheduleMeetingInput(id: "sleep", title: "Sleep", start: day(2, 0, 0), end: day(2, 6, 30)),
            ScheduleMeetingInput(id: "m1", title: "Help with Sean", start: day(2, 7, 0), end: day(2, 8, 0)),
            ScheduleMeetingInput(id: "m2", title: "Look after Sean", start: day(2, 8, 0), end: day(2, 20, 30)),
        ]
        // Morning routine window runs to the evening routine start (8pm) — which the last meeting
        // outlasts, so there is no later gap for the long habit to move into.
        let segs = [seg([habit(0, "A", minutes: 10),
                         habit(1, "B", minutes: 10),
                         habit(2, "C", minutes: 7),
                         habit(3, "D", minutes: 30)],
                        start: now, end: day(2, 20, 0), actionable: false)]
        let blocks = habitBlocks(build(segs, meetings: meetings, now: now, dayEnd: day(2, 23, 59), buffer: 2 * 60))

        let fitted = blocks.filter { !$0.didOverflow }
        XCTAssertEqual(fitted.map { $0.title }, ["A", "B", "C"])
        XCTAssertEqual(fitted.first?.start, day(2, 6, 30), "the first habit starts when sleep ends")
        XCTAssertEqual(fitted.last?.end, day(2, 6, 57), "and the last one stops before the 7am meeting")

        let overflow = blocks.filter { $0.didOverflow }
        XCTAssertEqual(overflow.map { $0.title }, ["D"], "the 30m habit fits nowhere in the day")
        XCTAssertEqual(overflow.first?.overflowDurationSeconds, 30 * 60, "its own length drives the row's label")
        XCTAssertEqual(overflow.first?.start, overflow.first?.end, "overflow is zero-duration so it doesn't eat free time")
        XCTAssertEqual(overflow.first?.start, day(2, 6, 57), "anchored after the last habit that fit")
    }

    /// The same future day, but with the routine window reaching past the meetings: the long habit is
    /// MOVED to the free evening slot rather than reported as not fitting (that rule stays intact).
    func testFutureDayMovesTheLongHabitLaterWhenThereIsRoom() {
        let now = day(2, 5, 0)
        let meetings = [
            ScheduleMeetingInput(id: "sleep", title: "Sleep", start: day(2, 0, 0), end: day(2, 6, 30)),
            ScheduleMeetingInput(id: "m1", title: "Meetings", start: day(2, 7, 0), end: day(2, 20, 30)),
        ]
        let segs = [seg([habit(0, "D", minutes: 30),
                         habit(1, "A", minutes: 10)],
                        start: now, end: day(2, 21, 30), actionable: false)]
        let blocks = habitBlocks(build(segs, meetings: meetings, now: now, dayEnd: day(2, 23, 59), buffer: 2 * 60))
        XCTAssertTrue(blocks.allSatisfy { !$0.didOverflow }, "everything fits once there's a later gap")
        // A (10m) is pulled forward into the short morning gap; D (30m) takes the evening slot.
        XCTAssertEqual(blocks.map { $0.title }, ["A", "D"])
        XCTAssertEqual(blocks[0].start, day(2, 6, 30))
        XCTAssertEqual(blocks[1].start, day(2, 20, 30))
    }

    /// "Earlier today" history is laid out with no window cap, so it never produces an overflow group
    /// (which would double up habits already rendered above it).
    func testEarlierSectionNeverOverflows() {
        let now = t(12, 0)
        var earlier = seg([habit(0, "A", minutes: 45)], start: t(7, 0), end: t(7, 10),
                          actionable: false, name: "Earlier")
        earlier.isEarlier = true
        let blocks = habitBlocks(build([earlier], now: now, dayEnd: t(23, 0)))
        XCTAssertEqual(blocks.map { $0.title }, ["A"])
        XCTAssertTrue(blocks.allSatisfy { !$0.didOverflow })
    }

    // MARK: - Meetings

    func testHabitPushedPastOverlappingMeeting() {
        let now = t(9, 0)
        let meeting = ScheduleMeetingInput(id: "m1", title: "Standup", start: t(9, 5), end: t(9, 35))
        let segs = [seg([habit(0, "A", minutes: 20)], start: now, end: t(12, 0))]
        let blocks = habitBlocks(build(segs, meetings: [meeting], now: now, dayEnd: t(18, 0)))
        XCTAssertEqual(blocks.count, 1)
        // A (20m) can't finish before the 9:05 meeting, so it starts no earlier than the meeting end.
        XCTAssertGreaterThanOrEqual(blocks[0].start, t(9, 35))
    }

    func testMeetingAppearsAsBlock() {
        let now = t(9, 0)
        let meeting = ScheduleMeetingInput(id: "m1", title: "Standup", start: t(10, 0), end: t(10, 30))
        let blocks = build([seg([habit(0, "A", minutes: 10)], start: now, end: t(12, 0))],
                           meetings: [meeting], now: now, dayEnd: t(18, 0))
        XCTAssertTrue(blocks.contains { $0.kind == .meeting && $0.eventID == "m1" })
    }

    // MARK: - Window capping

    func testHabitsNeverSpillPastWindowEnd() {
        let now = t(9, 0)
        let segs = [seg([habit(0, "A", minutes: 30)], start: now, end: t(9, 45))]
        let blocks = habitBlocks(build(segs, now: now, dayEnd: t(18, 0)))
        XCTAssertTrue(blocks.allSatisfy { $0.end <= t(9, 45) })
    }

    // MARK: - Cutoff

    func testPastCutoffHabitDroppedButLaterShown() {
        let now = t(9, 0)
        // A's cutoff (8:00) already passed → dropped; B (no cutoff) still shows. (continue, not break)
        let segs = [seg([habit(0, "A", minutes: 10, cutoff: t(8, 0)),
                         habit(1, "B", minutes: 10)], start: now, end: t(12, 0))]
        let blocks = habitBlocks(build(segs, now: now, dayEnd: t(18, 0)))
        XCTAssertEqual(blocks.map { $0.title }, ["B"])
    }

    // MARK: - Actionability

    func testOnlyNextHabitIsCurrentInActionableSegment() {
        let now = t(9, 0)
        let segs = [seg([habit(0, "A", minutes: 10), habit(1, "B", minutes: 10)],
                        start: now, end: t(12, 0), actionable: true)]
        let blocks = habitBlocks(build(segs, now: now, dayEnd: t(18, 0)))
        XCTAssertEqual(blocks.filter { $0.isCurrent }.count, 1)
        XCTAssertTrue(blocks.first?.isCurrent ?? false)   // the earliest habit is the current one
        XCTAssertTrue(blocks.allSatisfy { $0.isActionable })
    }

    func testPreviewSegmentNotActionable() {
        let now = t(9, 0)
        let segs = [seg([habit(0, "A", minutes: 10)], start: now, end: t(12, 0), actionable: false)]
        let blocks = habitBlocks(build(segs, now: now, dayEnd: t(18, 0)))
        XCTAssertTrue(blocks.allSatisfy { !$0.isActionable && !$0.isCurrent })
    }

    /// Every habit is editable from the Day Plan — a preview (future) routine's, and "earlier today"
    /// history's too, since the editor changes the habit's settings rather than the day's record. Only
    /// `isActionable` (Play/Done/Skip on today's row) distinguishes the active routine.
    func testEverySegmentIsEditableIncludingEarlierAndPreview() {
        let now = t(9, 0)
        let active = seg([habit(0, "A", minutes: 10)], start: now, end: t(12, 0), actionable: true, name: "Morning")
        let preview = seg([habit(1, "B", minutes: 10)], start: t(17, 0), end: t(18, 0), actionable: false, name: "Evening")
        var earlier = seg([habit(2, "C", minutes: 10)], start: t(7, 0), end: t(8, 0), actionable: false, name: "Earlier")
        earlier.isEarlier = true
        let blocks = habitBlocks(build([earlier, active, preview], now: now, dayEnd: t(23, 0)))

        let byName = Dictionary(uniqueKeysWithValues: blocks.map { ($0.routineName ?? "", $0) })
        XCTAssertEqual(byName["Morning"]?.isActionable, true)
        XCTAssertEqual(byName["Morning"]?.isEditable, true)
        XCTAssertEqual(byName["Evening"]?.isActionable, false)
        XCTAssertEqual(byName["Evening"]?.isEditable, true)
        XCTAssertEqual(byName["Earlier"]?.isActionable, false)
        XCTAssertEqual(byName["Earlier"]?.isEditable, true, "completed/past habits are edited, not re-run")
    }

    // MARK: - Mid-routine habit switch (Day Plan Play while a habit is playing/paused)
    //
    // Regression: with a habit paused, tapping Play on a *different* habit in the Day Plan did
    // nothing. The switch now mirrors the player's "Select another habit" sheet — the chosen habit
    // takes the currently-playing slot and the habit that was paused stays directly behind it, so
    // it's neither skipped nor completed.

    func testMovingLaterHabitToAnchorPutsPausedHabitDirectlyBehindIt() {
        let order = RoutineReorder.moving(["A", "B", "C", "D"], at: 3, toAnchor: 1)
        XCTAssertEqual(order, ["A", "D", "B", "C"])   // B (playing/paused) still next after D
    }

    func testMovingEarlierHabitToAnchorKeepsItJustBeforeThePausedHabit() {
        let order = RoutineReorder.moving(["A", "B", "C", "D"], at: 0, toAnchor: 2)
        XCTAssertEqual(order, ["B", "A", "C", "D"])   // C (playing/paused) still follows A
    }

    func testMovingHabitAlreadyAtAnchorIsANoOp() {
        XCTAssertNil(RoutineReorder.moving(["A", "B", "C"], at: 1, toAnchor: 1))
    }

    func testMovingOutOfRangeIndexIsANoOp() {
        XCTAssertNil(RoutineReorder.moving(["A", "B"], at: 5, toAnchor: 0))
        XCTAssertNil(RoutineReorder.moving([String](), at: 0, toAnchor: 0))
    }

    func testAnchorPastTheEndClampsToTheLastPosition() {
        let order = RoutineReorder.moving(["A", "B", "C"], at: 0, toAnchor: 99)
        XCTAssertEqual(order, ["B", "A", "C"])   // anchor clamps to C, so A lands just before it
    }

    func testDueDateIsCanonicalAndOverdueStartsToday() {
        XCTAssertEqual(DayPlanDueProjection.canonicalDay(dueDate: "2026-09-21", today: "2026-09-18"), "2026-09-21")
        XCTAssertEqual(DayPlanDueProjection.canonicalDay(dueDate: "2026-09-01", today: "2026-09-18"), "2026-09-18")
        XCTAssertNil(DayPlanDueProjection.canonicalDay(dueDate: nil, today: "2026-09-18"))
    }

    func testChangedDueDateRemovesOldPlacementWithoutReprioritising() {
        let task = DayPlanTask(title: "Task", sourceTaskId: "remote")
        let stored = ["2026-09-21": [task]]
        let result = DayPlanDueProjection.reconcile(stored, rows: [("2026-09-23", task)], today: "2026-09-18")
        XCTAssertNil(result["2026-09-21"])
        XCTAssertEqual(result["2026-09-23"], [task])
        XCTAssertNil(result["2026-09-24"])
        XCTAssertEqual(result.values.flatMap { $0 }.count, 1)
    }

    func testDueTaskIgnoresFutureLegacyPlacementAndKeepsHistoryAndLocalTasks() {
        let task = DayPlanTask(title: "Reopened", sourceTaskId: "remote")
        let history = DayPlanTask(title: "Done previously", done: true, sourceTaskId: "remote")
        let local = DayPlanTask(title: "Local")
        let noLongerDue = DayPlanTask(title: "No date", sourceTaskId: "cleared")
        let stored = ["2026-09-01": [history], "2026-09-18": [local, noLongerDue], "2026-09-30": [task]]
        let result = DayPlanDueProjection.reconcile(stored, rows: [("2026-09-18", task), ("2026-09-18", task)], today: "2026-09-18")
        XCTAssertEqual(result["2026-09-01"], [history])
        XCTAssertEqual(result["2026-09-18"], [local, task])
        XCTAssertNil(result["2026-09-30"])
    }

    func testSaturdayDoesNotIncludeFridaysDueOrOverdueTasks() throws {
        let wasMock = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        defer { DayPlanTaskStore.mockMode = wasMock }
        let store = DayPlanTaskStore(mockTasks: [:])
        let friday = try XCTUnwrap(ToDoDates.parse("2026-09-18"))
        let saturday = try XCTUnwrap(ToDoDates.parse("2026-09-19"))
        let sunday = try XCTUnwrap(ToDoDates.parse("2026-09-20"))
        XCTAssertTrue(store.mergeDueTodos([
            ["id": "overdue", "title": "Overdue", "due_date": "2026-09-17", "status": "NOT_STARTED"],
            ["id": "friday", "title": "Friday", "due_date": "2026-09-18", "status": "NOT_STARTED"],
            ["id": "saturday", "title": "Saturday", "due_date": "2026-09-19", "status": "NOT_STARTED"]
        ], into: friday))
        XCTAssertEqual(store.allTasks(for: friday).map(\.title), ["Overdue", "Friday"])
        XCTAssertEqual(store.allTasks(for: saturday).map(\.title), ["Saturday"])
        XCTAssertTrue(store.allTasks(for: sunday).isEmpty)
        XCTAssertEqual(store.allTasks(for: friday).map(\.title), ["Overdue", "Friday"],
                       "Navigating into the future must not move today's backlog")
    }

    func testPendingCompletionTodayDoesNotResurface() {
        var task = DayPlanTask(title: "Just finished", sourceTaskId: "remote")
        let unfinished = task
        task.done = true
        let result = DayPlanDueProjection.reconcile(["2026-09-18": [task]], rows: [("2026-09-18", unfinished)], today: "2026-09-18")
        XCTAssertEqual(result["2026-09-18"], [task])
    }

    // MARK: - Free time vs. time-boxed task load (report 2026-09-10_07-53-47)

    /// The user's own example: 20m of tasks on a 10m block costs the day 10 extra minutes, not 30.
    func testExcessIsTaskTimeBeyondTheBlock() {
        XCTAssertEqual(DayPlanFreeTime.excessMinutes(taskMinutes: 20, blockMinutes: 10), 10)
    }

    /// Tasks that fit inside the block are already paid for by the block itself.
    func testTasksUnderTheBlockDurationCostNothing() {
        XCTAssertEqual(DayPlanFreeTime.excessMinutes(taskMinutes: 5, blockMinutes: 10), 0)
    }

    func testTasksEqualToTheBlockDurationCostNothing() {
        XCTAssertEqual(DayPlanFreeTime.excessMinutes(taskMinutes: 10, blockMinutes: 10), 0)
    }

    /// An empty block never hands time back — free time must not go UP.
    func testNoTasksLeavesFreeTimeUntouched() {
        XCTAssertEqual(DayPlanFreeTime.excessMinutes(taskMinutes: 0, blockMinutes: 10), 0)
        XCTAssertEqual(DayPlanFreeTime.adjustedFreeMinutes(rawFreeMinutes: 120,
                                                          blocks: [.init(blockMinutes: 10, taskMinutes: 0)]),
                       120)
    }

    /// A task with no linked block contributes no block load at all, so free time is unchanged.
    func testNoLinkedBlocksLeavesFreeTimeUntouched() {
        XCTAssertEqual(DayPlanFreeTime.adjustedFreeMinutes(rawFreeMinutes: 120, blocks: []), 120)
    }

    /// Every block's overflow adds up, and only the overflow.
    func testAdjustedFreeTimeDeductsOnlyTheOverflow() {
        let blocks: [DayPlanFreeTime.BlockLoad] = [
            .init(blockMinutes: 10, taskMinutes: 20),   // 10 over
            .init(blockMinutes: 30, taskMinutes: 15),   // fits — costs nothing
            .init(blockMinutes: 25, taskMinutes: 40),   // 15 over
        ]
        XCTAssertEqual(DayPlanFreeTime.adjustedFreeMinutes(rawFreeMinutes: 120, blocks: blocks), 95)
    }

    /// An over-committed day reports no free time rather than a negative one.
    func testAdjustedFreeTimeClampsAtZero() {
        XCTAssertEqual(DayPlanFreeTime.adjustedFreeMinutes(rawFreeMinutes: 10,
                                                          blocks: [.init(blockMinutes: 5, taskMinutes: 90)]),
                       0)
    }

    /// A zero-length (or nonsense) block can't absorb anything, but must not amplify either.
    func testZeroLengthBlockChargesTheFullTaskTime() {
        XCTAssertEqual(DayPlanFreeTime.excessMinutes(taskMinutes: 20, blockMinutes: 0), 20)
        XCTAssertEqual(DayPlanFreeTime.excessMinutes(taskMinutes: 20, blockMinutes: -5), 20)
    }

    // MARK: - to-do `duration` field parsing

    /// The `/to-do` API renders `duration` as a STRING ("300"), so the old `as? Int` cast always
    /// failed and every imported to-do fell back to 15 minutes — inflating the Day Plan's totals.
    func testDurationParsesTheStringTheApiActuallySends() {
        XCTAssertEqual(TodoFieldParsing.durationSeconds("300"), 300)
        XCTAssertEqual(TodoFieldParsing.durationMinutes("300"), 5)
        XCTAssertEqual(TodoFieldParsing.durationMinutes("3600"), 60)
    }

    func testDurationStillParsesNumbers() {
        XCTAssertEqual(TodoFieldParsing.durationMinutes(300), 5)
        XCTAssertEqual(TodoFieldParsing.durationMinutes(NSNumber(value: 900)), 15)
    }

    /// Unset / unparseable durations fall back to the 15-minute default, and a sub-minute duration
    /// still reads as at least a minute.
    func testDurationFallsBackWhenUnset() {
        XCTAssertEqual(TodoFieldParsing.durationMinutes("0"), 15)
        XCTAssertEqual(TodoFieldParsing.durationMinutes(nil), 15)
        XCTAssertEqual(TodoFieldParsing.durationMinutes("not a number"), 15)
        XCTAssertEqual(TodoFieldParsing.durationMinutes("30"), 1, "30s rounds up to a minute, not zero")
    }

    // MARK: - Local edits to a meeting you don't own (report 2026-09-11_21-00-07)

    func testLocalOverrideTimesApplyOnlyToTheOccurrenceTheyWereMadeOn() {
        let start = Date(timeIntervalSince1970: 1_789_000_000)
        let end = start.addingTimeInterval(1200)
        let day = CalendarManager.dayKey(start)
        let override = CalendarManager.LocalEventOverride(title: "Stand up", start: start, end: end,
                                                          notes: nil, occurrenceDay: day)
        let applied = CalendarManager.overrideTimes(override, onDay: day)
        XCTAssertEqual(applied?.start, start)
        XCTAssertEqual(applied?.end, end, "The edited end time reaches the Day Plan")
        XCTAssertNil(CalendarManager.overrideTimes(override, onDay: "2026-01-01"),
                     "Another occurrence of the same series keeps the calendar's own times")
    }

    /// Report 2026-09-11_21-00-30: "when I edit a recurring event, it should ask me if I want to edit
    /// just that event or the whole series". For an event the user doesn't own, "all future events"
    /// has to mean a time of day — replaying one absolute date would pile the series onto that day.
    func testSeriesOverrideAppliesItsClockTimeToEveryOccurrence() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Melbourne")!
        let edited = calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 12, minute: 0))!
        let override = CalendarManager.LocalEventOverride(title: "Stand up", start: edited,
                                                          end: edited.addingTimeInterval(20 * 60), notes: nil,
                                                          occurrenceDay: CalendarManager.dayKey(edited),
                                                          appliesToSeries: true)
        let laterOccurrence = calendar.date(from: DateComponents(year: 2026, month: 9, day: 21, hour: 9, minute: 30))!
        let applied = CalendarManager.overrideTimes(override, onDay: CalendarManager.dayKey(laterOccurrence),
                                                    occurrenceStart: laterOccurrence, calendar: calendar)
        XCTAssertEqual(applied?.start, calendar.date(from: DateComponents(year: 2026, month: 9, day: 21, hour: 12, minute: 0)),
                       "Next week's occurrence moves to noon on its own day, not onto the edited day")
        XCTAssertEqual(applied?.end.timeIntervalSince(applied!.start), 20 * 60, "The edited duration carries over")
    }

    func testSeriesOverrideNeedsTheOccurrenceItIsBeingAppliedTo() {
        let start = Date(timeIntervalSince1970: 1_789_000_000)
        let override = CalendarManager.LocalEventOverride(title: "Stand up", start: start,
                                                          end: start.addingTimeInterval(1200), notes: nil,
                                                          occurrenceDay: CalendarManager.dayKey(start),
                                                          appliesToSeries: true)
        XCTAssertNil(CalendarManager.overrideTimes(override, onDay: CalendarManager.dayKey(start)))
    }

    func testLegacyLocalOverrideWithoutAnOccurrenceStillOnlyRenamesTheEvent() {
        let start = Date(timeIntervalSince1970: 1_789_000_000)
        let override = CalendarManager.LocalEventOverride(title: "Stand up", start: start,
                                                          end: start.addingTimeInterval(1200), notes: nil,
                                                          occurrenceDay: nil)
        XCTAssertNil(CalendarManager.overrideTimes(override, onDay: CalendarManager.dayKey(start)))
        XCTAssertNil(CalendarManager.overrideTimes(nil, onDay: "2026-09-11"))
    }

    func testMeetingCardIdentifierCarriesTheClickedOccurrence() {
        let start = Date(timeIntervalSince1970: 1_789_000_000), end = start.addingTimeInterval(1800)
        let raw = "edit:ABC:DEF\(scheduleViewController.occurrenceSeparator)\(start.timeIntervalSince1970)-\(end.timeIntervalSince1970)"
        let parsed = scheduleViewController.parseMeetingCardIdentifier(raw)
        XCTAssertEqual(parsed?.eventID, "ABC:DEF", "An EventKit id containing a colon survives the round trip")
        XCTAssertEqual(parsed?.start, start)
        XCTAssertEqual(parsed?.end, end)
        XCTAssertEqual(scheduleViewController.parseMeetingCardIdentifier("edit:ABC:DEF")?.start, .distantPast,
                       "A card without occurrence times still opens the editor")
        XCTAssertNil(scheduleViewController.parseMeetingCardIdentifier("dismiss:ABC"))
    }


    // MARK: - Completion made on another device (report 2026-09-13_20-06-43)

    /// A project with a kanban board finishes a task by moving it into a column flagged
    /// `should_complete_task`; the to-do's own `status` is untouched. The Day Plan read only the
    /// status, so tasks completed on the phone kept their unticked boxes here.
    func testBackendCompletionCountsABoardColumnThatFinishesTheTask() {
        let completing: Set<String> = ["col-done"]
        XCTAssertTrue(DayPlanTaskStore.isFinished(status: "COMPLETED", customStatusId: nil,
                                                  completingStatusIds: []))
        XCTAssertTrue(DayPlanTaskStore.isFinished(status: "IN_PROGRESS", customStatusId: "col-done",
                                                  completingStatusIds: completing),
                      "The column completes the task whatever the status says")
        XCTAssertFalse(DayPlanTaskStore.isFinished(status: "NOT_STARTED", customStatusId: "col-doing",
                                                   completingStatusIds: completing))
        XCTAssertFalse(DayPlanTaskStore.isFinished(status: nil, customStatusId: nil,
                                                   completingStatusIds: completing))
        XCTAssertFalse(DayPlanTaskStore.isFinished(status: "NOT_STARTED", customStatusId: "",
                                                   completingStatusIds: completing),
                       "An empty column id is no column at all")
    }


    // MARK: - The routine's "get focused" prompt (report 2026-09-13_20-30-50)

    func testVisualizePromptIsShownOncePerRoutinePerDay() {
        XCTAssertTrue(RoutineVisualizePrompt.shouldShow(lastShownDay: nil, today: "2026-09-13"),
                      "Never shown: ask")
        XCTAssertTrue(RoutineVisualizePrompt.shouldShow(lastShownDay: "", today: "2026-09-13"))
        XCTAssertFalse(RoutineVisualizePrompt.shouldShow(lastShownDay: "2026-09-13", today: "2026-09-13"),
                       "Already answered today — restarting the routine must not ask again")
        XCTAssertTrue(RoutineVisualizePrompt.shouldShow(lastShownDay: "2026-09-13", today: "2026-09-14"),
                      "A new day asks again")
    }

    func testVisualizePromptKeepsCustomRoutinesApart() {
        XCTAssertEqual(RoutineVisualizePrompt.Routine.morning.storageKey, "routineVisualizeShownDay.morning")
        XCTAssertEqual(RoutineVisualizePrompt.Routine.evening.storageKey, "routineVisualizeShownDay.evening")
        XCTAssertNotEqual(RoutineVisualizePrompt.Routine.custom("a").storageKey,
                          RoutineVisualizePrompt.Routine.custom("b").storageKey,
                          "Answering one custom routine must not silence another")
    }

    func testVisualizePromptRoundTripsThroughStorage() {
        let defaults = UserDefaults(suiteName: "RoutineVisualizePromptTests")!
        defaults.removePersistentDomain(forName: "RoutineVisualizePromptTests")
        let now = Date(timeIntervalSince1970: 1_789_000_000)
        XCTAssertTrue(RoutineVisualizePrompt.shouldShow(for: .evening, now: now, defaults: defaults))
        RoutineVisualizePrompt.markShown(for: .evening, now: now, defaults: defaults)
        XCTAssertFalse(RoutineVisualizePrompt.shouldShow(for: .evening, now: now, defaults: defaults))
        XCTAssertTrue(RoutineVisualizePrompt.shouldShow(for: .morning, now: now, defaults: defaults),
                      "Marking the evening leaves the morning alone")
        XCTAssertTrue(RoutineVisualizePrompt.shouldShow(for: .evening, now: now.addingTimeInterval(86_400 * 2),
                                                        defaults: defaults))
        defaults.removePersistentDomain(forName: "RoutineVisualizePromptTests")
    }


    // MARK: - Habits skipped ahead of time (report 2026-09-13_20-13-58)

    private func skipDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "DayPlanHabitSkipsTests")!
        defaults.removePersistentDomain(forName: "DayPlanHabitSkipsTests")
        return defaults
    }

    func testSkippingAHabitAheadAppliesToThatDayOnly() {
        let defaults = skipDefaults()
        let tomorrow = Date(timeIntervalSince1970: 1_789_000_000)
        let anotherDay = tomorrow.addingTimeInterval(86_400)
        XCTAssertTrue(DayPlanHabitSkips.toggle("meditate", on: tomorrow, defaults: defaults))
        XCTAssertTrue(DayPlanHabitSkips.isSkipped("meditate", on: tomorrow, defaults: defaults))
        XCTAssertFalse(DayPlanHabitSkips.isSkipped("meditate", on: anotherDay, defaults: defaults),
                       "Skipping tomorrow leaves every other day alone")
        XCTAssertFalse(DayPlanHabitSkips.isSkipped("stretch", on: tomorrow, defaults: defaults))
        defaults.removePersistentDomain(forName: "DayPlanHabitSkipsTests")
    }

    func testSkippingAheadTogglesBackOff() {
        let defaults = skipDefaults()
        let day = Date(timeIntervalSince1970: 1_789_000_000)
        XCTAssertTrue(DayPlanHabitSkips.toggle("meditate", on: day, defaults: defaults))
        XCTAssertFalse(DayPlanHabitSkips.toggle("meditate", on: day, defaults: defaults), "Second press unskips")
        XCTAssertFalse(DayPlanHabitSkips.isSkipped("meditate", on: day, defaults: defaults))
        XCTAssertTrue(DayPlanHabitSkips.skippedIds(on: day, defaults: defaults).isEmpty,
                      "An emptied day leaves nothing behind")
        defaults.removePersistentDomain(forName: "DayPlanHabitSkipsTests")
    }

    func testSkipsAreNeverStoredForAnEmptyHabitId() {
        let defaults = skipDefaults()
        XCTAssertFalse(DayPlanHabitSkips.isSkipped("", on: Date(), defaults: defaults))
        XCTAssertFalse(DayPlanHabitSkips.isSkipped(nil, on: Date(), defaults: defaults))
        defaults.removePersistentDomain(forName: "DayPlanHabitSkipsTests")
    }

    func testOldSkipDaysArePrunedAwayInDateOrder() {
        var map: [String: [String]] = [:]
        for day in 1...(DayPlanHabitSkips.retainedDays + 5) {
            map[String(format: "2026-01-%02d", day)] = ["h"]
        }
        let pruned = DayPlanHabitSkips.pruned(map)
        XCTAssertEqual(pruned.count, DayPlanHabitSkips.retainedDays)
        XCTAssertNil(pruned["2026-01-01"], "The oldest days go first")
        XCTAssertNotNil(pruned[String(format: "2026-01-%02d", DayPlanHabitSkips.retainedDays + 5)])
    }

    // MARK: - The routine honours a skip made in advance (report 2026-09-16_15-14-58)

    /// Scheduled for every weekday, so only the skip can keep a habit out of the routine.
    private static let everyWeekday = ["all"]
    private static let skipTestDay = Date(timeIntervalSince1970: 1_789_000_000)

    func testAHabitSkippedForADayDoesNotPlayThatDay() {
        let defaults = skipDefaults()
        let day = Self.skipTestDay
        XCTAssertTrue(RoutineHabitSchedule.shouldPlay(habitId: "read", daysOfWeek: Self.everyWeekday,
                                                     on: day, defaults: defaults),
                      "Nothing is skipped yet, so the habit plays")
        DayPlanHabitSkips.toggle("read", on: day, defaults: defaults)
        XCTAssertFalse(RoutineHabitSchedule.shouldPlay(habitId: "read", daysOfWeek: Self.everyWeekday,
                                                      on: day, defaults: defaults),
                       "A habit skipped for this day must not be played by this day's routine")
    }

    func testASkipMadeTheNightBeforeAppliesToTheNextDayAndNotToToday() {
        let defaults = skipDefaults()
        let tonight = Self.skipTestDay
        let tomorrow = tonight.addingTimeInterval(86_400)
        // What the Day Plan writes when you skip ahead while looking at tomorrow.
        DayPlanHabitSkips.toggle("read", on: tomorrow, defaults: defaults)
        XCTAssertFalse(RoutineHabitSchedule.shouldPlay(habitId: "read", daysOfWeek: Self.everyWeekday,
                                                      on: tomorrow, defaults: defaults),
                       "Tomorrow's routine must honour the skip recorded for tomorrow")
        XCTAssertTrue(RoutineHabitSchedule.shouldPlay(habitId: "read", daysOfWeek: Self.everyWeekday,
                                                     on: tonight, defaults: defaults),
                      "A skip for tomorrow must not leak into tonight's routine")
    }

    func testSkippingOneHabitLeavesTheRestOfTheRoutineAlone() {
        let defaults = skipDefaults()
        DayPlanHabitSkips.toggle("read", on: Self.skipTestDay, defaults: defaults)
        XCTAssertTrue(RoutineHabitSchedule.shouldPlay(habitId: "shower", daysOfWeek: Self.everyWeekday,
                                                     on: Self.skipTestDay, defaults: defaults))
    }

    func testUnskippingPutsTheHabitBackIntoThatDaysRoutine() {
        let defaults = skipDefaults()
        DayPlanHabitSkips.toggle("read", on: Self.skipTestDay, defaults: defaults)
        DayPlanHabitSkips.toggle("read", on: Self.skipTestDay, defaults: defaults)
        XCTAssertTrue(RoutineHabitSchedule.shouldPlay(habitId: "read", daysOfWeek: Self.everyWeekday,
                                                     on: Self.skipTestDay, defaults: defaults))
    }

    func testSkippingAheadDoesNotReplaceTheWeekdayRule() {
        let defaults = skipDefaults()
        let day = Self.skipTestDay
        let otherWeekday = day.dayOfWeek().uppercased() == "SAT" ? "SUN" : "SAT"
        XCTAssertFalse(RoutineHabitSchedule.shouldPlay(habitId: "read", daysOfWeek: [otherWeekday],
                                                      on: day, defaults: defaults),
                       "Skipping ahead is an extra rule, not a replacement for the weekday rule")
    }

    // MARK: - Habits shortened for one day (report 2026-09-15_20-29-02)

    private static let shortenSuite = "DayPlanHabitDurationsTests"
    private static let runMinutes = 30
    private static let trimmedMinutes = 10

    private func shortenDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: Self.shortenSuite)!
        defaults.removePersistentDomain(forName: Self.shortenSuite)
        return defaults
    }

    func testShorteningAHabitAppliesToThatDayOnly() {
        let defaults = shortenDefaults()
        let monday = Date(timeIntervalSince1970: 1_789_000_000)
        let tuesday = monday.addingTimeInterval(86_400)
        let real = Self.runMinutes * 60
        let trimmed = Self.trimmedMinutes * 60

        XCTAssertEqual(DayPlanHabitDurations.setOverride(trimmed, for: "run", on: monday, actual: real,
                                                        defaults: defaults), trimmed)
        XCTAssertEqual(DayPlanHabitDurations.effectiveSeconds(for: "run", on: monday, actual: real,
                                                              defaults: defaults), trimmed)
        XCTAssertEqual(DayPlanHabitDurations.effectiveSeconds(for: "run", on: tuesday, actual: real,
                                                              defaults: defaults), real,
                       "Shortening Monday leaves every other day alone")
        XCTAssertEqual(DayPlanHabitDurations.effectiveSeconds(for: "stretch", on: monday, actual: real,
                                                              defaults: defaults), real,
                       "Only the habit that was shortened is affected")
        defaults.removePersistentDomain(forName: Self.shortenSuite)
    }

    func testShorteningNeverChangesTheHabitsRealDuration() {
        let defaults = shortenDefaults()
        let monday = Date(timeIntervalSince1970: 1_789_000_000)
        let real = Self.runMinutes * 60
        DayPlanHabitDurations.setOverride(Self.trimmedMinutes * 60, for: "run", on: monday, actual: real,
                                          defaults: defaults)
        // The store only ever reports a trim; the real length is whatever the caller passes in, and a
        // caller asking with the true duration still gets the true duration for any other day.
        XCTAssertEqual(DayPlanHabitDurations.overrideSeconds(for: "run", on: monday, defaults: defaults),
                       Self.trimmedMinutes * 60)
        XCTAssertEqual(DayPlanHabitDurations.effectiveSeconds(for: "run", on: monday.addingTimeInterval(86_400),
                                                              actual: real, defaults: defaults), real)
        defaults.removePersistentDomain(forName: Self.shortenSuite)
    }

    func testShortenedHabitSurvivesAReloadOfTheStore() {
        let defaults = shortenDefaults()
        let monday = Date(timeIntervalSince1970: 1_789_000_000)
        DayPlanHabitDurations.setOverride(Self.trimmedMinutes * 60, for: "run", on: monday,
                                          actual: Self.runMinutes * 60, defaults: defaults)
        defaults.synchronize()
        // A fresh handle on the same suite is what a relaunch sees: the trim is in UserDefaults, not memory.
        let reopened = UserDefaults(suiteName: Self.shortenSuite)!
        XCTAssertEqual(DayPlanHabitDurations.overrideSeconds(for: "run", on: monday, defaults: reopened),
                       Self.trimmedMinutes * 60)
        defaults.removePersistentDomain(forName: Self.shortenSuite)
    }

    func testShorteningClearsBackToTheFullDuration() {
        let defaults = shortenDefaults()
        let monday = Date(timeIntervalSince1970: 1_789_000_000)
        let real = Self.runMinutes * 60
        DayPlanHabitDurations.setOverride(Self.trimmedMinutes * 60, for: "run", on: monday, actual: real,
                                          defaults: defaults)
        DayPlanHabitDurations.clearOverride(for: "run", on: monday, defaults: defaults)
        XCTAssertNil(DayPlanHabitDurations.overrideSeconds(for: "run", on: monday, defaults: defaults))
        XCTAssertEqual(DayPlanHabitDurations.effectiveSeconds(for: "run", on: monday, actual: real,
                                                              defaults: defaults), real)
        defaults.removePersistentDomain(forName: Self.shortenSuite)
    }

    func testAskingForTheRealLengthOrLongerClearsTheTrimInsteadOfStoringIt() {
        let defaults = shortenDefaults()
        let monday = Date(timeIntervalSince1970: 1_789_000_000)
        let real = Self.runMinutes * 60
        DayPlanHabitDurations.setOverride(Self.trimmedMinutes * 60, for: "run", on: monday, actual: real,
                                          defaults: defaults)
        XCTAssertNil(DayPlanHabitDurations.setOverride(real, for: "run", on: monday, actual: real, defaults: defaults),
                     "This only ever shortens — asking for the full length removes the trim")
        XCTAssertNil(DayPlanHabitDurations.overrideSeconds(for: "run", on: monday, defaults: defaults))
        defaults.removePersistentDomain(forName: Self.shortenSuite)
    }

    func testATrimIsNeverShorterThanTheFloorAndNeverLongerThanTheHabit() {
        let defaults = shortenDefaults()
        let monday = Date(timeIntervalSince1970: 1_789_000_000)
        let real = Self.runMinutes * 60
        XCTAssertEqual(DayPlanHabitDurations.setOverride(1, for: "run", on: monday, actual: real, defaults: defaults),
                       DayPlanHabitDurations.minimumSeconds, "Clamped up to the floor")
        // A stored trim longer than the habit (the habit was shortened in settings since) must not lengthen it.
        DayPlanHabitDurations.setOverride(real - 60, for: "run", on: monday, actual: real, defaults: defaults)
        XCTAssertEqual(DayPlanHabitDurations.effectiveSeconds(for: "run", on: monday, actual: 120, defaults: defaults),
                       120, "Never longer than the habit's real length")
        defaults.removePersistentDomain(forName: Self.shortenSuite)
    }

    func testTrimsAreNeverStoredForAnEmptyHabitId() {
        let defaults = shortenDefaults()
        XCTAssertNil(DayPlanHabitDurations.setOverride(600, for: "", on: Date(), actual: 1800, defaults: defaults))
        XCTAssertNil(DayPlanHabitDurations.overrideSeconds(for: "", on: Date(), defaults: defaults))
        XCTAssertNil(DayPlanHabitDurations.overrideSeconds(for: nil, on: Date(), defaults: defaults))
        defaults.removePersistentDomain(forName: Self.shortenSuite)
    }

    func testOldShortenedDaysArePrunedAwayInDateOrder() {
        var map: [String: [String: Int]] = [:]
        for day in 1...(DayPlanHabitDurations.retainedDays + 5) {
            map[String(format: "2026-01-%02d", day)] = ["h": 600]
        }
        let pruned = DayPlanHabitDurations.pruned(map)
        XCTAssertEqual(pruned.count, DayPlanHabitDurations.retainedDays)
        XCTAssertNil(pruned["2026-01-01"], "The oldest days go first")
        XCTAssertNotNil(pruned[String(format: "2026-01-%02d", DayPlanHabitDurations.retainedDays + 5)])
    }

    func testShortenOptionsAreOnlyLengthsShorterThanTheHabit() {
        XCTAssertEqual(DayPlanHabitDurations.options(forActualSeconds: 25 * 60), [20 * 60, 15 * 60, 10 * 60, 5 * 60])
        XCTAssertEqual(DayPlanHabitDurations.options(forActualSeconds: 6 * 60), [5 * 60])
        XCTAssertEqual(DayPlanHabitDurations.options(forActualSeconds: 3 * 60), [DayPlanHabitDurations.minimumSeconds],
                       "A habit below the shortest preset still gets the one-minute trim")
        XCTAssertTrue(DayPlanHabitDurations.options(forActualSeconds: DayPlanHabitDurations.minimumSeconds).isEmpty,
                      "A habit already at the floor has nothing shorter to offer")
    }

    func testMinutesLabelNeverRoundsARealHabitDownToZero() {
        XCTAssertEqual(DayPlanHabitDurations.minutesLabel(90), 2)
        XCTAssertEqual(DayPlanHabitDurations.minutesLabel(20), 1)
        XCTAssertEqual(DayPlanHabitDurations.minutesLabel(30 * 60), 30)
    }

    // MARK: Typing a length (follow-up: "needs to let me type a duration")

    func testTypedLengthUsesTheDayPlansOwnDurationGrammar() {
        // Same parser as every other Day Plan duration field, so "4h" is four hours here too.
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("1h30", actualSeconds: 2 * 60 * 60), .apply(seconds: 90 * 60))
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("90min", actualSeconds: 2 * 60 * 60), .apply(seconds: 90 * 60))
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("2 hrs", actualSeconds: 3 * 60 * 60), .apply(seconds: 2 * 60 * 60))
    }

    func testTypedBareNumberIsMinutes() {
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("10", actualSeconds: Self.runMinutes * 60),
                       .apply(seconds: 10 * 60))
        XCTAssertEqual(DayPlanHabitDurations.typedTrim(" 25 ", actualSeconds: Self.runMinutes * 60),
                       .apply(seconds: 25 * 60))
    }

    func testTypedLengthLongerThanTheHabitIsRefusedRatherThanLengtheningIt() {
        // "4h" on a 30-minute habit: four hours, not four minutes — and this only ever shortens.
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("4h", actualSeconds: Self.runMinutes * 60), .notShorter)
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("30", actualSeconds: Self.runMinutes * 60), .notShorter,
                       "Exactly the real length isn't shorter either")
    }

    func testTypedLengthThatIsntADurationIsRejected() {
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("", actualSeconds: 1800), .notADuration)
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("soon", actualSeconds: 1800), .notADuration)
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("0", actualSeconds: 1800), .notADuration)
    }

    func testTypedLengthIsClampedToTheFloorAndStillCantLengthen() {
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("1", actualSeconds: 1800),
                       .apply(seconds: DayPlanHabitDurations.minimumSeconds))
        XCTAssertEqual(DayPlanHabitDurations.typedTrim("1", actualSeconds: DayPlanHabitDurations.minimumSeconds),
                       .notShorter, "A habit already at the floor can't be trimmed further")
    }

    func testATypedLengthGoesThroughTheSameEffectiveSecondsPathAsAPreset() {
        let defaults = shortenDefaults()
        let monday = Date(timeIntervalSince1970: 1_789_000_000)
        let real = Self.runMinutes * 60
        guard case .apply(let seconds) = DayPlanHabitDurations.typedTrim("12", actualSeconds: real) else {
            return XCTFail("12 minutes is shorter than 30 and should apply")
        }
        DayPlanHabitDurations.setOverride(seconds, for: "run", on: monday, actual: real, defaults: defaults)
        XCTAssertEqual(DayPlanHabitDurations.effectiveSeconds(for: "run", on: monday, actual: real,
                                                              defaults: defaults), 12 * 60)
        // The stale-trim guard still holds for a typed value: the habit shrinking in settings wins.
        XCTAssertEqual(DayPlanHabitDurations.effectiveSeconds(for: "run", on: monday, actual: 5 * 60,
                                                              defaults: defaults), 5 * 60)
        defaults.removePersistentDomain(forName: Self.shortenSuite)
    }

    // MARK: The "(shortened)" marker in the day's list

    private static let shortenedTagText = "(shortened)"

    func testShortenedTagIsAppendedAfterTheHabitName() {
        let base = NSAttributedString(string: "Professional development")
        let tagged = DayPlanShortenedTag.appended(to: base, tag: Self.shortenedTagText, color: .secondaryLabelColor)
        XCTAssertEqual(tagged.string, "Professional development \(Self.shortenedTagText)")
    }

    func testShortenedTagIsSmallerAndDimmerThanTheName() {
        let nameFont = NSFont.systemFont(ofSize: 16)
        let base = NSAttributedString(string: "Run", attributes: [.font: nameFont, .foregroundColor: NSColor.labelColor])
        let tagged = DayPlanShortenedTag.appended(to: base, tag: Self.shortenedTagText, color: .secondaryLabelColor)
        let tagFont = tagged.attribute(.font, at: tagged.length - 1, effectiveRange: nil) as? NSFont
        XCTAssertEqual(tagFont?.pointSize, DayPlanShortenedTag.fontSize)
        XCTAssertLessThan(try XCTUnwrap(tagFont?.pointSize), nameFont.pointSize)
        // The name keeps its own attributes — the marker must not restyle what it follows.
        XCTAssertEqual(tagged.attribute(.font, at: 0, effectiveRange: nil) as? NSFont, nameFont)
    }

    func testShortenedTagKeepsTheStrikeThroughOfACompletedHabit() {
        let base = NSAttributedString(string: "Run", attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
        let tagged = DayPlanShortenedTag.appended(to: base, tag: Self.shortenedTagText, color: .secondaryLabelColor)
        XCTAssertNotNil(tagged.attribute(.strikethroughStyle, at: 0, effectiveRange: nil))
    }

    func testShortenedTagIsNotAddedWhenThereIsNoNameToTag() {
        let empty = NSAttributedString(string: "")
        XCTAssertEqual(DayPlanShortenedTag.appended(to: empty, tag: Self.shortenedTagText, color: .secondaryLabelColor).string, "")
    }

    func testTheListMarkerAndTheActionBarCaptionReadTheSameFact() {
        let defaults = shortenDefaults()
        let monday = Date(timeIntervalSince1970: 1_789_000_000)
        let tuesday = monday.addingTimeInterval(86_400)
        // Both the row marker and the button caption ask this one question, for the day being viewed.
        func isShortened(on day: Date) -> Bool {
            DayPlanHabitDurations.overrideSeconds(for: "run", on: day, defaults: defaults) != nil
        }
        XCTAssertFalse(isShortened(on: monday))
        DayPlanHabitDurations.setOverride(10 * 60, for: "run", on: monday, actual: Self.runMinutes * 60,
                                          defaults: defaults)
        XCTAssertTrue(isShortened(on: monday))
        XCTAssertFalse(isShortened(on: tuesday), "Only the day that was shortened is marked")
        DayPlanHabitDurations.clearOverride(for: "run", on: monday, defaults: defaults)
        XCTAssertFalse(isShortened(on: monday), "Cleared, the marker goes away")
        defaults.removePersistentDomain(forName: Self.shortenSuite)
    }

    func testShortenedHabitReflowsTheRestOfTheDay() {
        let defaults = shortenDefaults()
        let now = t(9, 0)
        let real = Self.runMinutes * 60
        let trimmed = Self.trimmedMinutes * 60
        DayPlanHabitDurations.setOverride(trimmed, for: "run", on: now, actual: real, defaults: defaults)

        // Exactly what ScheduleTab.habitInputs composes: the real duration, passed through the trim.
        func inputs() -> [ScheduleHabitInput] {
            [ScheduleHabitInput(index: 0, title: "Run",
                                durationSeconds: DayPlanHabitDurations.effectiveSeconds(for: "run", on: now,
                                                                                        actual: real, defaults: defaults),
                                isPlaying: false, elapsedSeconds: 0, cutoff: nil, id: "run"),
             habit(1, "Journal", minutes: 10)]
        }
        let blocks = habitBlocks(build([seg(inputs(), start: now, end: t(12, 0))], now: now, dayEnd: t(18, 0)))
        XCTAssertEqual(blocks.map { $0.title }, ["Run", "Journal"])
        XCTAssertEqual(blocks[0].durationSeconds, trimmed, "The run is laid out at its trimmed length")
        XCTAssertEqual(blocks[1].start, now.addingTimeInterval(TimeInterval(trimmed)),
                       "Everything after it moves earlier by the time the trim freed")

        DayPlanHabitDurations.clearOverride(for: "run", on: now, defaults: defaults)
        let full = habitBlocks(build([seg(inputs(), start: now, end: t(12, 0))], now: now, dayEnd: t(18, 0)))
        XCTAssertEqual(full[0].durationSeconds, real, "Cleared, the habit is back to its real length")
        XCTAssertEqual(full[1].start, now.addingTimeInterval(TimeInterval(real)))
        defaults.removePersistentDomain(forName: Self.shortenSuite)
    }

    // MARK: Forecast snapshot placement (report 2026-09-14_09-09-13)

    func testTodaysForecastIsBuiltFromNowWithoutCompletedHabits() {
        let now = Date()
        let point = scheduleViewController.forecastBuildPoint(for: now, now: now)
        XCTAssertEqual(point.start, now,
                       "Today must be built from the current time so unfinished habits sit where the plan puts them")
        XCTAssertFalse(point.includeCompleted, "Re-placing a habit that already ran would book its time twice")
    }

    func testAnotherDaysForecastKeepsTheWholeTimetable() {
        let now = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let point = scheduleViewController.forecastBuildPoint(for: tomorrow, now: now, calendar: calendar)
        XCTAssertEqual(point.start, calendar.startOfDay(for: tomorrow))
        XCTAssertTrue(point.includeCompleted)
    }


    // MARK: Block durations read as hours once they are hours (report 2026-09-21_17-57-15)
    //
    // "(103 min)" made the reader do the division. "Make this 1h43m."

    private func bracketed(_ minutes: Int) -> String {
        ScheduleDuration.bracketed(minutes,
                                   minutesOnly: "(%d min)",
                                   hoursOnly: "(%dh)",
                                   hoursAndMinutes: "(%dh%dm)")
    }

    func testTheReportedCase() {
        XCTAssertEqual(bracketed(103), "(1h43m)")
    }

    func testUnderAnHourStaysInMinutes() {
        XCTAssertEqual(bracketed(45), "(45 min)")
        XCTAssertEqual(bracketed(59), "(59 min)", "\"0h59m\" would be noise")
        XCTAssertEqual(bracketed(1), "(1 min)")
    }

    func testAnExactHourDropsTheMinutes() {
        XCTAssertEqual(bracketed(60), "(1h)", "not \"1h0m\"")
        XCTAssertEqual(bracketed(120), "(2h)")
        XCTAssertEqual(bracketed(480), "(8h)")
    }

    func testTheBoundaryItself() {
        XCTAssertEqual(bracketed(59), "(59 min)")
        XCTAssertEqual(bracketed(60), "(1h)")
        XCTAssertEqual(bracketed(61), "(1h1m)")
    }

    func testZeroAndNegativeDurations() {
        XCTAssertEqual(bracketed(0), "(0 min)")
        // A block cannot run backwards; "(-1h-43m)" is a worse way to show a bug than "(0 min)".
        XCTAssertEqual(bracketed(-103), "(0 min)")
        XCTAssertEqual(ScheduleDuration.hoursAndMinutes(-5).hours, 0)
        XCTAssertEqual(ScheduleDuration.hoursAndMinutes(-5).minutes, 0)
    }

    func testTheSplitIsWholeHoursAndRemainder() {
        XCTAssertEqual(ScheduleDuration.hoursAndMinutes(103).hours, 1)
        XCTAssertEqual(ScheduleDuration.hoursAndMinutes(103).minutes, 43)
        XCTAssertEqual(ScheduleDuration.hoursAndMinutes(1439).hours, 23)
        XCTAssertEqual(ScheduleDuration.hoursAndMinutes(1439).minutes, 59)
    }

    /// The live call path, so a wiring mistake between ScheduleText and ScheduleDuration is caught
    /// and not only the arithmetic underneath it.
    func testScheduleTextUsesTheHourForm() {
        XCTAssertTrue(ScheduleText.durationMinutesBrackets(103).contains("1"),
                      "the live formatter must go through ScheduleDuration")
        XCTAssertFalse(ScheduleText.durationMinutesBrackets(103).contains("103"),
                       "103 raw minutes is exactly what the report asked to stop seeing")
    }

}

// MARK: - Day Plan reload instrumentation

/// Locks in the per-phase reload log: a healthy tick stays silent, a slow one names the phase that
/// held the main thread. Pure — no view controller, no clock.
final class DayPlanReloadTimingTests: XCTestCase {

    func test_fast_reload_is_not_logged() {
        let timing = DayPlanReloadTiming(segments: 0.001, meetings: 0.002, build: 0.004,
                                         render: 0.010, finish: 0.001)
        XCTAssertFalse(timing.isSlow(threshold: 0.5))
    }

    func test_slow_reload_is_logged_and_names_the_slowest_phase() {
        // The shape of the proven freeze: everything cheap except the EventKit read.
        let timing = DayPlanReloadTiming(segments: 0.002, meetings: 17.18, build: 0.009,
                                         render: 0.011, finish: 0.002)
        XCTAssertTrue(timing.isSlow(threshold: 0.5))
        XCTAssertEqual(timing.slowestPhase, "meetings")
        XCTAssertEqual(timing.summary,
                       "total=17204ms slowest=meetings segments=2ms meetings=17180ms build=9ms render=11ms finish=2ms")
    }

    func test_render_bound_reload_names_render_not_meetings() {
        let timing = DayPlanReloadTiming(segments: 0.01, meetings: 0.01, build: 0.02,
                                         render: 1.4, finish: 0.05)
        XCTAssertEqual(timing.slowestPhase, "render")
        XCTAssertTrue(timing.isSlow(threshold: 0.5))
    }

    func test_empty_timing_has_no_slowest_phase() {
        XCTAssertEqual(DayPlanReloadTiming().slowestPhase, "none")
        XCTAssertFalse(DayPlanReloadTiming().isSlow(threshold: 0.5))
    }
}

/// The staleness policy that keeps EventKit's blocking query off the main thread: served from cache,
/// refreshed in the background, never dropped. See CalendarManager's "Meetings cache" note.
final class MeetingsCacheTests: XCTestCase {

    private let today = Calendar.current.startOfDay(for: Date())

    private func key(_ day: Date? = nil, includeDismissed: Bool = false) -> MeetingsCache.Key {
        MeetingsCache.Key(dayStart: day ?? today, includeDismissed: includeDismissed)
    }

    private func meeting(_ id: String, hour: Int) -> ScheduleMeetingInput {
        let start = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: today)!
        return ScheduleMeetingInput(id: id, title: "📅 \(id)", start: start,
                                    end: start.addingTimeInterval(1800))
    }

    func test_first_lookup_serves_nothing_and_asks_for_a_refresh() {
        let cache = MeetingsCache()
        let lookup = cache.lookup(key())
        XCTAssertEqual(lookup.meetings, [])
        XCTAssertTrue(lookup.needsRefresh)
    }

    func test_cached_day_is_served_without_another_fetch() {
        let cache = MeetingsCache()
        let stored = [meeting("standup", hour: 9)]
        cache.store(stored, for: key())
        let lookup = cache.lookup(key())
        XCTAssertEqual(lookup.meetings, stored)
        XCTAssertFalse(lookup.needsRefresh, "a warm entry must not send the caller back to EventKit")
    }

    func test_invalidation_still_serves_the_old_value_while_asking_for_a_refresh() {
        let cache = MeetingsCache()
        let stored = [meeting("standup", hour: 9)]
        cache.store(stored, for: key())

        XCTAssertEqual(cache.invalidateAll(), [key()])

        let lookup = cache.lookup(key())
        XCTAssertEqual(lookup.meetings, stored, "a stale entry is served, never dropped — dropping it "
                       + "would put the main thread back on the blocking EventKit query")
        XCTAssertTrue(lookup.needsRefresh)
    }

    func test_storing_the_refresh_clears_the_stale_mark() {
        let cache = MeetingsCache()
        cache.store([meeting("standup", hour: 9)], for: key())
        cache.invalidateAll()
        cache.store([meeting("standup", hour: 9), meeting("retro", hour: 15)], for: key())
        XCTAssertFalse(cache.lookup(key()).needsRefresh)
    }

    func test_store_reports_whether_the_ui_needs_re_rendering() {
        let cache = MeetingsCache()
        let stored = [meeting("standup", hour: 9)]
        XCTAssertTrue(cache.store(stored, for: key()), "first fetch is a change")
        XCTAssertFalse(cache.store(stored, for: key()), "an unchanged calendar must not re-render")
        XCTAssertTrue(cache.store(stored + [meeting("retro", hour: 15)], for: key()))
    }

    func test_refresh_is_coalesced_until_it_finishes() {
        let cache = MeetingsCache()
        XCTAssertTrue(cache.beginRefresh(key()))
        XCTAssertFalse(cache.beginRefresh(key()), "a second tick must not stack another EventKit query")
        cache.endRefresh(key())
        XCTAssertTrue(cache.beginRefresh(key()))
    }

    func test_days_and_dismissed_visibility_are_cached_separately() {
        let cache = MeetingsCache()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        cache.store([meeting("standup", hour: 9)], for: key())

        XCTAssertTrue(cache.lookup(key(yesterday)).needsRefresh)
        XCTAssertTrue(cache.lookup(key(includeDismissed: true)).needsRefresh)
        XCTAssertFalse(cache.lookup(key()).needsRefresh)
    }

    func test_has_value_separates_an_unread_day_from_a_clear_one() {
        let cache = MeetingsCache()
        XCTAssertFalse(cache.hasValue(key()), "nothing read yet — the [] lookup serves is a placeholder")
        cache.store([], for: key())
        XCTAssertTrue(cache.hasValue(key()), "a day read and found empty is known to be clear")
        XCTAssertEqual(cache.lookup(key()).meetings, [], "both cases still serve [] to the main thread")
    }

    func test_a_stale_entry_still_counts_as_known() {
        let cache = MeetingsCache()
        cache.store([meeting("standup", hour: 9)], for: key())
        cache.invalidateAll()
        XCTAssertTrue(cache.hasValue(key()), "stale is a real answer one refresh old, not an absent one")
    }

    func test_invalidation_only_refreshes_days_that_were_actually_cached() {
        let cache = MeetingsCache()
        XCTAssertTrue(cache.invalidateAll().isEmpty)
        cache.store([meeting("standup", hour: 9)], for: key())
        cache.store([], for: key(includeDismissed: true))
        XCTAssertEqual(Set(cache.invalidateAll()), [key(), key(includeDismissed: true)])
    }
}

// MARK: - Date-picker day badges

/// The date-picker grid's per-day capacity badge. The rule under test is the one the picker got wrong
/// (report 2026-09-17_21-51-06): a day whose meetings have not been read yet must render as UNKNOWN,
/// not as "plenty of room". `CalendarManager` serves [] for both an unread day and a genuinely clear
/// one, and [] meetings feeds the capacity model a whole free day — so deciding a colour before the
/// day is loaded paints the most reassuring badge on precisely the days nobody has checked.
final class DayPlanDayBadgeTests: XCTestCase {

    func test_a_day_whose_meetings_have_not_loaded_gets_no_badge() {
        // The capacity the cold cache computes — a whole empty day — is exactly what must NOT be shown.
        let badge = DayPlanDayBadge.color(isFuture: true, inputsAreLoaded: false, netFreeMinutes: 480)
        XCTAssertNil(badge, "an unread day is unknown, not free — badging it green is the reported bug")
    }

    func test_an_unloaded_day_is_not_measured_at_all() {
        var measured = false
        _ = DayPlanDayBadge.color(isFuture: true, inputsAreLoaded: false,
                                  netFreeMinutes: { measured = true; return 480 }())
        XCTAssertFalse(measured, "no point building a schedule from meetings we haven't read")
    }

    func test_a_loaded_day_is_badged_from_its_free_minutes() {
        XCTAssertEqual(DayPlanDayBadge.color(isFuture: true, inputsAreLoaded: true, netFreeMinutes: 480),
                       NSColor.systemGreen)
        XCTAssertEqual(DayPlanDayBadge.color(isFuture: true, inputsAreLoaded: true, netFreeMinutes: 90),
                       NSColor.systemBlue)
        XCTAssertEqual(DayPlanDayBadge.color(isFuture: true, inputsAreLoaded: true, netFreeMinutes: 30),
                       NSColor.systemOrange)
        XCTAssertEqual(DayPlanDayBadge.color(isFuture: true, inputsAreLoaded: true, netFreeMinutes: -60),
                       NSColor.systemRed, "over-committed stays red however far past zero it goes")
    }

    func test_a_loaded_day_with_no_schedule_gets_no_badge() {
        XCTAssertNil(DayPlanDayBadge.color(isFuture: true, inputsAreLoaded: true, netFreeMinutes: nil))
    }

    func test_today_and_past_days_are_never_badged() {
        XCTAssertNil(DayPlanDayBadge.color(isFuture: false, inputsAreLoaded: true, netFreeMinutes: -60),
                     "today's free time is in the tasks-panel header; past days can't be re-planned")
    }
}

// MARK: - Event card heights

/// Shared duration scale: long events must remain distinct instead of hitting a ceiling.
final class DayPlanEventHeightTests: XCTestCase {

    private func points(minutes: Int) -> CGFloat {
        DayPlanEventHeight.points(forDurationSeconds: minutes * 60)
    }

    func test_short_events_ask_for_less_than_a_row_so_their_text_decides() {
        // Applied as a >= constraint, anything under the ~34pt a single text row occupies is inert —
        // which is how a 15-minute event keeps a legible, clickable card instead of becoming a sliver.
        XCTAssertLessThan(points(minutes: 15), 34)
        XCTAssertLessThan(points(minutes: 30), 34)
        XCTAssertLessThan(points(minutes: 60), 34, "the everyday meeting must look exactly as it does today")
    }

    func test_long_events_grow_with_their_length() {
        XCTAssertGreaterThan(points(minutes: 120), points(minutes: 90))
        XCTAssertGreaterThan(points(minutes: 90), points(minutes: 60))
        XCTAssertEqual(points(minutes: 120), 66, accuracy: 0.01)
    }

    func test_long_events_keep_growing_without_a_ceiling() {
        XCTAssertEqual(points(minutes: 8 * 60), 264, accuracy: 0.01)
        XCTAssertEqual(points(minutes: 12 * 60 + 30), 412.5, accuracy: 0.01)
        XCTAssertEqual(points(minutes: 12 * 60), 2 * points(minutes: 6 * 60), accuracy: 0.01)
    }

    func test_an_eight_hour_event_no_longer_matches_a_fifteen_minute_one() {
        // The report, stated as a test.
        XCTAssertGreaterThan(points(minutes: 8 * 60), points(minutes: 15) + 60)
    }

    func test_a_zero_length_event_asks_for_nothing() {
        XCTAssertEqual(DayPlanEventHeight.points(forDurationSeconds: 0), 0)
        XCTAssertEqual(DayPlanEventHeight.points(forDurationSeconds: -60), 0,
                       "an end before its start must not produce a negative constraint")
    }
}


extension ScheduleKitTests {
    @MainActor
    func testIdleRoutineHostDoesNotExposeStaleMorningActions() throws {
        guard Bundle.main.bundleIdentifier?.hasSuffix(".logictests") == true,
              fbSharedDefaultsSuiteName.hasSuffix(".logictests") else {
            throw XCTSkip("Requires isolated logic-test defaults")
        }
        let previousState = currentState
        let previousMorning = arrFilteredMorningHabits
        defer {
            currentState = previousState
            arrFilteredMorningHabits = previousMorning
        }
        let staleHabit = Focus_Bear.habit(id: "stale-morning", name: "Make bed", durationSeconds: 60,
            urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false,
            allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "morning",
            run_micro_breaks: false, take_notes: NO_NOTE, isPriorityHigh: false,
            days_of_week: ["all"], text_instructions: "", imgUrls: [], completion_requirements: "",
            useTimer: true, checkList: [], tutorial: "")
        arrFilteredMorningHabits = [staleHabit]
        currentState = ._NOTHING_
        let host = firstViewController()
        XCTAssertFalse(host.supportsLiveHabitActions)
        host.scheduleDone(index: 0)
        host.scheduleSkip(index: 0)
        host.scheduleStart(index: 0)
        XCTAssertEqual(currentState, ._NOTHING_)
        XCTAssertEqual(arrFilteredMorningHabits.map(\.id), [staleHabit.id])
        let previousStart = startTime
        let previousShutoff = shutOffTime
        let previousEvening = arrFilteredEveningHabits
        let previousAllEvening = arrAllDaysEveningHabits
        let previousCustom = arrAllCustomRoutine
        defer {
            startTime = previousStart
            shutOffTime = previousShutoff
            arrFilteredEveningHabits = previousEvening
            arrAllDaysEveningHabits = previousAllEvening
            arrAllCustomRoutine = previousCustom
        }
        let now = Date()
        let calendar = Calendar.current
        let earlier = calendar.date(byAdding: .hour, value: -1, to: now)!
        let later = calendar.date(byAdding: .hour, value: 1, to: now)!
        shutOffTime = Time(hour: calendar.component(.hour, from: earlier), minute: 0, second: 0)
        startTime = Time(hour: calendar.component(.hour, from: later), minute: 0, second: 0)
        var eveningHabit = staleHabit
        eveningHabit.id = "current-evening"
        eveningHabit.name = "Prepare for tomorrow"
        arrFilteredEveningHabits = [eveningHabit]
        arrAllDaysEveningHabits = [eveningHabit]
        arrAllCustomRoutine = []
        let segments = host.scheduleSegments(now: now)
        XCTAssertEqual(segments.first?.name, ScheduleText.eveningRoutineHabits)
        XCTAssertEqual(segments.first?.habits.map(\.title), [eveningHabit.name!],
                       "Never reuse the retained morning array")
        try captureIdleEveningCardIfRequested(host: host, segments: segments, now: now)
        currentState = ._EVENING_HABIT_
        XCTAssertTrue(host.supportsLiveHabitActions)
    }

    func testIdleCutoffNavigationKeepsExistingFullscreenOnly() {
        func keeps(_ state: CURRENTSTATE = ._NOTHING_, visible: Bool = true,
                   enabled: Bool = true, cutoff: Bool = true, allowed: Bool = false) -> Bool {
            leftMenuVc.shouldKeepCutoffWindow(state: state, isFullScreenVisible: visible,
                isFullScreenEnabled: enabled, isCutoffPassed: cutoff, isAllowedActivityRunning: allowed)
        }
        XCTAssertTrue(keeps())
        XCTAssertFalse(keeps(visible: false))
        XCTAssertFalse(keeps(enabled: false))
        XCTAssertFalse(keeps(cutoff: false))
        XCTAssertFalse(keeps(allowed: true))
        XCTAssertFalse(keeps(._POSTPONE_EVENING_HABIT_))
        XCTAssertFalse(keeps(._ABORT_))
    }
}


private final class IdleRoutineFixtureWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private enum IdleRoutineCapture {
    static let environmentKey = "FOCUSBEAR_IDLE_ROUTINE_CAPTURE_DIRECTORY"
    static let offscreen: CGFloat = -12000
    static let width: CGFloat = 740
    static let minimumHeight: CGFloat = 160
    static let settle: TimeInterval = 0.1
    static let filename = "idle-evening-routine.png"
}

extension ScheduleKitTests {
    @MainActor
    private func captureIdleEveningCardIfRequested(host: firstViewController,
                                                   segments: [ScheduleRoutineSegment], now: Date) throws {
        let environment = ProcessInfo.processInfo.environment
        guard let directory = environment[IdleRoutineCapture.environmentKey]
                ?? environment["TEST_RUNNER_" + IdleRoutineCapture.environmentKey] else { return }
        let end = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        let blocks = ScheduleBuilder.build(segments: segments, meetings: [], now: now, dayEnd: end,
                                           leaveBufferSeconds: 0, outOfOrderAllowed: false)
            .filter { $0.kind == .habit }
        XCTAssertFalse(blocks.isEmpty)
        let controller = scheduleViewController()
        controller.host = host
        let card = controller.makeHabitGroupCard(blocks)
        let window = IdleRoutineFixtureWindow(contentRect: NSRect(x: IdleRoutineCapture.offscreen,
            y: IdleRoutineCapture.offscreen, width: IdleRoutineCapture.width,
            height: IdleRoutineCapture.minimumHeight), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true
        window.contentView = card
        window.orderBack(nil)
        defer { window.orderOut(nil); window.contentView = nil; window.close() }
        card.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(IdleRoutineCapture.settle))
        let bitmap = try XCTUnwrap(card.bitmapImageRepForCachingDisplay(in: card.bounds))
        card.cacheDisplay(in: card.bounds, to: bitmap)
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        let output = URL(fileURLWithPath: directory, isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        try png.write(to: output.appendingPathComponent(IdleRoutineCapture.filename), options: .atomic)
    }
}
