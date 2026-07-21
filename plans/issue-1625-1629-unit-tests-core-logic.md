# PLAN: Unit Tests for Core Mac App Logic (Issues #1625–#1629)

**Issues:**
- #1625 — [Testing] Add unit tests for URL/App Blocking Decision logic
- #1626 — [Testing] Add unit tests for Routine/Habit Scheduling logic
- #1627 — [Testing] Add unit tests for Time Parsing functions
- #1628 — [Testing] Add unit tests for Focus Alignment Score calculation
- #1629 — [Testing] Add unit tests for Settings Management logic

**Branch:** `plan/issue-1625-1629`

## Context

These five issues follow the same pattern: add XCTest unit tests to `FocusBearTests/` for specific logic modules. They are grouped here because they share:
- The same test target (`FocusBearTests/`)
- The same test file structure (existing examples: `URLBlockingTests.swift`, `AppBlockingTests.swift`)
- The same approach: `@testable import Focus_Bear` + `XCTestCase` subclasses

Existing test files to follow as templates:
- `FocusBearTests/URLBlockingTests.swift`
- `FocusBearTests/AppBlockingTests.swift`

## New Test Files

### 1. `FocusBearTests/BlockingDecisionTests.swift` — Issue #1625

**Source:** `FocusBear/globalFile.swift` (functions `getBlockedUrlsToBlock()`, `getBlockedAppsToBlock()`)

Test cases:
- `test_blockedUrls_withCustomScheduleAndFocusBreak_returnsEmptyWhenBreaksEnabled` — Custom schedule on, focus break on, `DoNotBlockUrlsDuringSuperPomodoroBreaks` enabled → empty list
- `test_blockedUrls_withMicroBreakState_returnsEmptyWhenBreaksEnabled`
- `test_blockedUrls_duringMeetingWithMeetingBlockingDisabled_returnsEmpty`
- `test_blockedUrls_expiredApp_limitsCount`
- `test_blockedUrls_normalState_returnsFullList`
- `test_blockedUrls_emptyList_returnsEmpty`
- Mirror cases for `getBlockedAppsToBlock()`
- `test_stateMachine_validTransitions`
- `test_stateMachine_invalidTransitions_doNothing`

**Coverage target:** >90% for `getBlockedUrlsToBlock` and `getBlockedAppsToBlock`

### 2. `FocusBearTests/RoutineSchedulingTests.swift` — Issue #1626

**Source:** `FocusBear/Routine/routineData.swift`

Test cases for `checkCustomRoutineTime()`:
- `test_routine_triggersAtCorrectTimeOnCorrectDay`
- `test_routine_doesNotTriggerOnExcludedDay`
- `test_routine_doesNotTriggerOutsideTimeWindow`
- `test_routine_multipleOverlappingTimes_allHandled`
- `test_routine_withActivePostponement_doesNotTrigger`

Test cases for `startCustomRoutine()`:
- `test_startRoutine_validHabits_startsCorrectly`
- `test_startRoutine_emptyHabitList_handlesGracefully`
- `test_startRoutine_respectsStrictnessSettings`

Test cases for `isCustomRoutineTime()`:
- `test_isRoutineTime_withinWindow_returnsTrue`
- `test_isRoutineTime_outsideWindow_returnsFalse`
- `test_isRoutineTime_boundaryEdgeCases`

Test cases for postponement:
- `test_postponeMorning_correctDuration`
- `test_postponeEvening_correctDuration`
- `test_postponement_expiresAfterDuration`
- `test_multiplePostponements_accumulateCorrectly`

**Coverage target:** >85% for scheduling functions

### 3. `FocusBearTests/TimeParsingTests.swift` — Issue #1627

**Sources:**
- `FocusBear/globalFile.swift` → `getTimeFromString()`
- `FocusBear/Focus mode/customBlockingScheduleData.swift` → `parseTime()`

Test cases for `getTimeFromString()`:
- `test_standardAMFormat_9_00AM` → correct Date
- `test_standardPMFormat_2_30PM` → correct Date
- `test_24HourFormat_14_30` → correct Date
- `test_midnight_12_00AM` → correct Date
- `test_noon_12_00PM` → correct Date
- `test_invalidString_returnsNil`
- `test_emptyString_returnsNil`
- `test_malformedInput_returnsNil`

Test cases for `parseTime()`:
- `test_multipleFormats_allParsedCorrectly`
- `test_localeSpecificFormat_handledGracefully`
- `test_invalidInput_returnsNil`

Test cases for cross-midnight ranges:
- `test_timeRange_10pm_to_2am_isActiveAtMidnight`
- `test_timeRange_10pm_to_2am_isNotActiveAt3am`
- `test_durationCalc_acrossMidnight_correct`

### 4. `FocusBearTests/FocusAlignmentScoreTests.swift` — Issue #1628

**Source:** `FocusBear/Focus mode/focusModeData.swift`

Test cases for `calculateFocusAlignmentScore()`:
- `test_allAligned_returns100`
- `test_allUnaligned_returns0`
- `test_mixedActivities_returnsProportionalScore`
- `test_timeWeightedScoring_longerActivitiesCountMore`
- `test_emptyActivityList_returnsNilOrZero`
- `test_veryShortSession_handledGracefully`

Test cases for `getFocusAlignmentScoreFromLastEntry()`:
- `test_validEntry_returnsCorrectScore`
- `test_missingEntry_returnsNil`
- `test_aggregationLogic_multipleEntries`

Test cases for URL/App tracking:
- `test_urlTracking_doesNotDuplicateEntries`
- `test_appTracking_doesNotDuplicateEntries`
- `test_timeTracking_accurate`

### 5. `FocusBearTests/SettingsManagerTests.swift` — Issue #1629

**Source:** `FocusBear/SettingsManager.swift`

Test cases for `getUserLocalDeviceSettings()`:
- `test_loadSettings_allKeysPresent_loadsCorrectly`
- `test_loadSettings_missingKeys_usesDefaults`
- `test_loadSettings_invalidValues_fallsBackToDefault`
- `test_userIdSuffix_appliedCorrectly`
- `test_migration_oldFormat_migratedCorrectly`

Test cases for `getCurrentStrictnessLevel()`:
- `test_normal_strictness_returned`
- `test_strictMode_detected`
- `test_superStrictMode_detected`
- `test_strictness_transitions_correct`
- `test_timeBased_strictness_changes`

Test cases for `resetAllKeys()`:
- `test_allKeys_resetCorrectly`
- `test_userId_preservedAfterReset`
- `test_noDataLeakage_betweenUsers`

Test cases for `getDayOfWeek()`:
- `test_correctDay_variousDates`
- `test_localeHandling`
- `test_edgeCases_yearBoundary_DST`

## Implementation Approach

All test files should follow the pattern in existing tests:
```swift
@testable import Focus_Bear
import XCTest

class XxxTests: XCTestCase {
    override func setUp() { super.setUp() }
    override func tearDown() { super.tearDown() }
    // test functions...
}
```

**Mocking strategy:**
- `UserDefaults` — use a suite name (`UserDefaults(suiteName: "TestSuite")`) and reset in `tearDown`
- Network/API calls — confirm pure functions are testable in isolation; if not, extract dependencies behind a protocol for injection
- `Date` — use dependency injection or `setCurrentDate()` utility where needed

## Files to Create

| File | Tests for | Issue |
|------|-----------|-------|
| `FocusBearTests/BlockingDecisionTests.swift` | `globalFile.swift` — `getBlockedUrlsToBlock()`, `getBlockedAppsToBlock()` | #1625 |
| `FocusBearTests/RoutineSchedulingTests.swift` | `Routine/routineData.swift` | #1626 |
| `FocusBearTests/TimeParsingTests.swift` | `globalFile.swift`, `customBlockingScheduleData.swift` | #1627 |
| `FocusBearTests/FocusAlignmentScoreTests.swift` | `Focus mode/focusModeData.swift` | #1628 |
| `FocusBearTests/SettingsManagerTests.swift` | `FocusBear/SettingsManager.swift` | #1629 |

## Files to Modify

| File | Change |
|------|--------|
| `FocusBear/SettingsManager.swift` | May need to extract some `UserDefaults` access behind an injectable protocol to make it testable |
| `FocusBear/Routine/routineData.swift` | May need to make `Date` injectable for time-based tests |
| `FocusBear/Focus mode/focusModeData.swift` | May need to isolate pure calculation functions from side-effecting code |

## Open Design Questions

1. Are the target functions (`calculateFocusAlignmentScore`, `checkCustomRoutineTime`, etc.) currently pure/testable, or do they depend on global state that needs to be extracted first? Recommend a quick code audit before writing tests.
2. Does the project use any existing mock framework (OCMock, etc.)? If not, manual protocol-based mocking is the approach.
3. Should these be added to CI to run on every PR? (Recommended: yes, add to Xcode scheme if not already there)

## Acceptance Criteria (per issue)

- [ ] #1625: All 12+ blocking decision test cases pass; >90% coverage on target functions
- [ ] #1626: All 14+ routine scheduling test cases pass; >85% coverage on scheduling functions
- [ ] #1627: All 11+ time parsing test cases pass; all formats + midnight/noon/cross-midnight covered
- [ ] #1628: All 9+ alignment score test cases pass; time-weighted algorithm validated
- [ ] #1629: All 12+ settings management test cases pass; UserDefaults reset between tests; no cross-user leakage
