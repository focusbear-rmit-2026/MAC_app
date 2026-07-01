//
//  ScheduleKitTests.swift
//  Focus BearTests
//
//  Unit tests for the pure Day Plan scheduling engine (ScheduleBuilder). These lock in the
//  placement rules that have been bug-prone: in-order packing, stopping when a habit can't fit,
//  pushing past meetings, capping at the routine window, and dropping past-cutoff habits.
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

    // MARK: - Stop when a habit doesn't fit (the continue→break fix)

    func testStopsAtFirstHabitThatDoesNotFit() {
        let now = t(9, 0)
        // Window 9:00–9:20. A=10m fits; B=30m doesn't; C=5m WOULD fit but must not show out of order.
        let segs = [seg([habit(0, "A", minutes: 10),
                         habit(1, "B", minutes: 30),
                         habit(2, "C", minutes: 5)], start: now, end: t(9, 20))]
        let blocks = habitBlocks(build(segs, now: now, dayEnd: t(18, 0)))
        XCTAssertEqual(blocks.map { $0.title }, ["A"],
                       "Once a habit can't fit, later (shorter) habits must not leap-frog it")
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
}
