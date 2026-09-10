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

    func testOverflowGroupNotProducedForPreviewSegment() {
        let now = t(9, 0)
        let allDay = ScheduleMeetingInput(id: "m1", title: "Offsite", start: t(8, 0), end: t(18, 0))
        let segs = [seg([habit(0, "A", minutes: 10)], start: now, end: t(12, 0), actionable: false)]
        let blocks = habitBlocks(build(segs, meetings: [allDay], now: now, dayEnd: t(18, 0)))
        XCTAssertTrue(blocks.isEmpty, "a non-actionable (preview) routine drops what doesn't fit")
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
}
