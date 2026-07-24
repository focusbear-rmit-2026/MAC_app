//
//  FocusAlignmentScoreTests.swift
//  FocusBearTests
//
//  Tests for calculateFocusAlignmentScore() and related global state
//  in focusModeData.swift.
//  Issue: Focus-Bear/Mac-App#1628
//

@testable import Focus_Bear
import XCTest

class FocusAlignmentScoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear the tracking dictionary and reset score globals before each test
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.removeAll()
        currentFocusAlignmentScore = 100
        lastFocusAlignmentScore    = 0
        // Disable the visual indicator so tests don't trigger UI side-effects
        SettingsManagerObject.isFocusVisualIndicatorEnabled = false
    }

    override func tearDown() {
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.removeAll()
        currentFocusAlignmentScore = 100
        lastFocusAlignmentScore    = 0
        SettingsManagerObject.isFocusVisualIndicatorEnabled = false
        super.tearDown()
    }

    // MARK: - Empty activity list → defaults to 100

    func test_emptyActivityList_scoreSetsTo100() {
        // No entries in the dictionary
        calculateFocusAlignmentScore()
        XCTAssertEqual(currentFocusAlignmentScore, 100,
            "With no tracked activities the score should default to 100")
    }

    // MARK: - All aligned (probability = 1.0) → score near 100

    func test_allAligned_scoreIsHigh() {
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["xcode"] = [
            "probability": 1.0,
            "totalSeconds": 600,
            "isVisibleApp": false,
            "isVisibleUrl": false
        ]
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["github.com"] = [
            "probability": 1.0,
            "totalSeconds": 300,
            "isVisibleUrl": false,
            "isVisibleApp": false
        ]

        calculateFocusAlignmentScore()

        XCTAssertGreaterThanOrEqual(currentFocusAlignmentScore, 90,
            "Fully aligned activities (probability 1.0) should yield a score near 100")
    }

    // MARK: - All unaligned (probability = 0.0) → score is 0

    func test_allUnaligned_scoreIsZero() {
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["reddit.com"] = [
            "probability": 0.0,
            "totalSeconds": 600,
            "isVisibleUrl": false,
            "isVisibleApp": false
        ]

        calculateFocusAlignmentScore()

        XCTAssertEqual(currentFocusAlignmentScore, 0,
            "All unaligned activities (probability 0.0) should yield a score of 0")
    }

    // MARK: - Mixed activities → proportional score

    func test_mixedActivities_proportionalScore() {
        // 300s aligned (prob 1.0) + 300s unaligned (prob 0.0) → ~50
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["focused-tool"] = [
            "probability": 1.0,
            "totalSeconds": 300,
            "isVisibleApp": false,
            "isVisibleUrl": false
        ]
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["distraction.com"] = [
            "probability": 0.0,
            "totalSeconds": 300,
            "isVisibleUrl": false,
            "isVisibleApp": false
        ]

        calculateFocusAlignmentScore()

        // Score = (1.0*300 + 0.0*300) / 600 * 100 = 50
        XCTAssertEqual(currentFocusAlignmentScore, 50.0, accuracy: 0.01,
            "50/50 aligned vs unaligned time should yield score ≈ 50")
    }

    // MARK: - Time-weighted: longer aligned activity dominates

    func test_timeWeightedScoring_longerAlignedActivityDominates() {
        // 900s aligned vs 100s unaligned → (900*1.0)/(1000)*100 = 90
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["productive-app"] = [
            "probability": 1.0,
            "totalSeconds": 900,
            "isVisibleApp": false,
            "isVisibleUrl": false
        ]
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["distraction"] = [
            "probability": 0.0,
            "totalSeconds": 100,
            "isVisibleUrl": false,
            "isVisibleApp": false
        ]

        calculateFocusAlignmentScore()

        XCTAssertEqual(currentFocusAlignmentScore, 90.0, accuracy: 0.01,
            "90% aligned time should yield score ≈ 90")
    }

    // MARK: - Score is capped at 100

    func test_scoreNeverExceeds100() {
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["work"] = [
            "probability": 1.5, // above 1.0 — edge case
            "totalSeconds": 600,
            "isVisibleApp": false,
            "isVisibleUrl": false
        ]
        calculateFocusAlignmentScore()
        XCTAssertLessThanOrEqual(currentFocusAlignmentScore, 100,
            "Score should never exceed 100 regardless of probability values")
    }

    // MARK: - lastFocusAlignmentScore is updated

    func test_lastFocusAlignmentScore_updatedAfterCalc() {
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["work"] = [
            "probability": 1.0,
            "totalSeconds": 300,
            "isVisibleApp": false,
            "isVisibleUrl": false
        ]
        lastFocusAlignmentScore = 0
        calculateFocusAlignmentScore()
        XCTAssertEqual(lastFocusAlignmentScore, currentFocusAlignmentScore,
            "lastFocusAlignmentScore should mirror currentFocusAlignmentScore after calculation")
    }

    // MARK: - Score is rounded to 2 decimal places

    func test_score_roundedToTwoDecimalPlaces() {
        // 1s aligned + 2s unaligned → 1/3 * 100 = 33.333... → 33.33
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["a"] = [
            "probability": 1.0, "totalSeconds": 1, "isVisibleApp": false, "isVisibleUrl": false
        ]
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus["b"] = [
            "probability": 0.0, "totalSeconds": 2, "isVisibleUrl": false, "isVisibleApp": false
        ]
        calculateFocusAlignmentScore()
        let rounded = (currentFocusAlignmentScore * 100).rounded() / 100
        XCTAssertEqual(currentFocusAlignmentScore, rounded,
            "Score should be rounded to at most 2 decimal places")
    }
}
