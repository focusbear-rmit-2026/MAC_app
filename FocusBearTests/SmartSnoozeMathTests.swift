//
//  SmartSnoozeMathTests.swift
//  Focus BearTests
//
//  Unit tests for the "Choose a good time for me" smart-snooze maths (SmartSnoozeMath): the cumulative
//  rollover model (half of each day's task load spills into the next day) and the task distribution that
//  uses it to spread snoozed tasks out to genuinely empty days.
//

@testable import Focus_Bear
import XCTest

final class SmartSnoozeMathTests: XCTestCase {

    private let rollover = 0.5   // the app's smartSnoozeRolloverFraction

    // MARK: - effectiveFree

    func testEffectiveFree_subtractsOwnLoad() {
        // One day, 480 min free, 200 min of tasks → 280 effective free.
        XCTAssertEqual(SmartSnoozeMath.effectiveFree(scheduleFree: [480], load: [200], rolloverFraction: rollover),
                       [280])
    }

    func testEffectiveFree_cumulativeRollover() {
        // The user's example: Thu 4h tasks, Fri 4h tasks, Mon empty; 8h (480m) free each day.
        // Thu: 480-240 = 240 free            (carry = 0.5 * 240 = 120 into Fri)
        // Fri: 480-(240+120) = 120 free      (carry = 0.5 * 360 = 180 into Mon)
        // Mon: 480-(0+180) = 300 free
        XCTAssertEqual(SmartSnoozeMath.effectiveFree(scheduleFree: [480, 480, 480], load: [240, 240, 0],
                                                     rolloverFraction: rollover),
                       [240, 120, 300])
    }

    func testEffectiveFree_canGoNegativeWhenOverCommitted() {
        // Day0: 120-200 = -80  (carry = 100). Day1: 120-(200+100) = -180.
        XCTAssertEqual(SmartSnoozeMath.effectiveFree(scheduleFree: [120, 120], load: [200, 200],
                                                     rolloverFraction: rollover),
                       [-80, -180])
    }

    func testEffectiveFree_zeroRolloverIsPlainNet() {
        // With no rollover, effective free is just schedule − that day's own load.
        XCTAssertEqual(SmartSnoozeMath.effectiveFree(scheduleFree: [300, 300], load: [100, 50],
                                                     rolloverFraction: 0),
                       [200, 250])
    }

    func testEffectiveFree_emptyInput() {
        XCTAssertEqual(SmartSnoozeMath.effectiveFree(scheduleFree: [], load: [], rolloverFraction: rollover), [])
    }

    // MARK: - distribute

    func testDistribute_landsOnFirstDayWithRoom() {
        // Day0 already full (60/60), day1 empty → the 60-min task goes to day1.
        XCTAssertEqual(SmartSnoozeMath.distribute(taskDurations: [60], scheduleFree: [60, 480],
                                                  startLoad: [60, 0], rolloverFraction: rollover),
                       [1])
    }

    func testDistribute_spreadsAcrossDaysInsteadOfPiling() {
        // Several tasks that can't all share one day get spread forward (distinct, increasing days) —
        // the pile-up bug's fix, made stricter by the rollover.
        let idx = SmartSnoozeMath.distribute(taskDurations: [60, 60, 60, 60],
                                             scheduleFree: [90, 90, 90, 90, 90, 90],
                                             startLoad: [0, 0, 0, 0, 0, 0], rolloverFraction: rollover)
        XCTAssertEqual(idx.count, 4)
        XCTAssertEqual(idx, idx.sorted(), "tasks are placed forward in time")
        XCTAssertEqual(Set(idx).count, idx.count, "no two tasks piled on the same day when they don't fit together")
    }

    func testDistribute_fallsBackToEmptiestWhenNothingFits() {
        // A 500-min task can't fit any 100-min day → the emptiest effective day (day 0, before carry grows).
        XCTAssertEqual(SmartSnoozeMath.distribute(taskDurations: [500], scheduleFree: [100, 100, 100],
                                                  startLoad: [0, 0, 0], rolloverFraction: rollover),
                       [0])
    }

    func testDistribute_rolloverPushesPastANominallyFreeDay() {
        // Day1 looks free by its own load (0), but the rollover from a heavily-loaded day0 fills it, so a
        // task that wouldn't fit day1's effective free is pushed further out.
        // day0: schedule 100, load 100 → eff 0, carry 50. day1: schedule 100, load 0 → eff 100-50 = 50.
        // A 60-min task doesn't fit day0 (eff would be -60) nor day1 (eff 50-60 = -10) → day2.
        let idx = SmartSnoozeMath.distribute(taskDurations: [60], scheduleFree: [100, 100, 100, 100],
                                             startLoad: [100, 0, 0, 0], rolloverFraction: rollover)
        XCTAssertEqual(idx, [2])
    }
}
