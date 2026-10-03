//
//  LeftMenuAvailabilityTests.swift
//  Focus BearTests
//
//  The left menu's enabled/disabled rule as a pure function of CURRENTSTATE
//  (LeftMenuAvailability in leftMenuVc.swift). Issue: Blocking was greyed out during a routine while
//  Settings and Edit Habits were not, and the restriction outlived the routine into the postponed
//  states — postponed is not active.
//

@testable import Focus_Bear
import XCTest

final class LeftMenuAvailabilityTests: XCTestCase {

    /// The states in which a routine genuinely owns the main window.
    private let activeRoutineStates: [CURRENTSTATE] = [._MORNING_HABIT_, ._EVENING_HABIT_, ._FOCUS_SUMMARY_,
                                                       ._SHUTOFFMAC_, ._CUSTOM_ROUTINE_]
    private let postponedStates: [CURRENTSTATE] = [._POSTPONE_MORNING_HABIT_, ._POSTPONE_EVENING_HABIT_,
                                                   ._POSTPONE_FOCUS_SUMMARY_]

    // MARK: - Preferences stay reachable

    func testBlockingSettingsAndEditHabitsStayEnabledInEveryState() {
        // The reported bug: Blocking was disabled during a routine while its two siblings were not.
        // All three are "go and change a preference" tabs and must behave identically everywhere.
        for state in activeRoutineStates + postponedStates + [._NOTHING_] {
            for item in LeftMenuAvailability.alwaysAvailable {
                XCTAssertTrue(LeftMenuAvailability.isEnabled(item, during: state),
                              "\(item) should be enabled in \(state)")
            }
        }
    }

    func testAlwaysAvailableIsExactlyTheThreePreferencesTabs() {
        XCTAssertEqual(LeftMenuAvailability.alwaysAvailable, [.editHabits, .settings, .blocking])
    }

    // MARK: - Active routines

    func testAHabitRoutineKeepsOnlyItsOwnTabAndThePreferencesTabs() {
        for state in [CURRENTSTATE._MORNING_HABIT_, ._EVENING_HABIT_, ._FOCUS_SUMMARY_, ._SHUTOFFMAC_] {
            XCTAssertTrue(LeftMenuAvailability.isEnabled(.habits, during: state), "\(state)")
            XCTAssertFalse(LeftMenuAvailability.isEnabled(.customRoutine, during: state), "\(state)")
            XCTAssertFalse(LeftMenuAvailability.isEnabled(.microBreaks, during: state), "\(state)")
            XCTAssertFalse(LeftMenuAvailability.isEnabled(.focusSession, during: state), "\(state)")
        }
    }

    func testACustomRoutineKeepsTheCustomRoutineTabInsteadOfHabits() {
        XCTAssertTrue(LeftMenuAvailability.isEnabled(.customRoutine, during: ._CUSTOM_ROUTINE_))
        XCTAssertFalse(LeftMenuAvailability.isEnabled(.habits, during: ._CUSTOM_ROUTINE_))
        XCTAssertFalse(LeftMenuAvailability.isEnabled(.microBreaks, during: ._CUSTOM_ROUTINE_))
        XCTAssertFalse(LeftMenuAvailability.isEnabled(.focusSession, during: ._CUSTOM_ROUTINE_))
    }

    // MARK: - Live habit-attached focus session carve-out (#2793)

    func testALiveHabitSessionKeepsTheFocusSessionTabReachableDuringARoutine() {
        // A habit with a focus mode attached runs in a routine state, but the user was dropped into a
        // live session they must be able to return to — so Focus Session stays clickable while one runs.
        for state in activeRoutineStates {
            XCTAssertTrue(LeftMenuAvailability.isEnabled(.focusSession, during: state,
                                                         isAllowedActivityRunning: true), "\(state)")
        }
    }

    func testWithNoLiveSessionTheCarveOutMatchesTheBaseRule() {
        // The carve-out must not loosen anything else: with no live session every item matches the
        // base (item, state) rule, so Focus Session is still disabled during a routine.
        for state in activeRoutineStates + postponedStates + [._NOTHING_] {
            for item in LeftMenuRoutineItem.allCases {
                XCTAssertEqual(LeftMenuAvailability.isEnabled(item, during: state, isAllowedActivityRunning: false),
                               LeftMenuAvailability.isEnabled(item, during: state), "\(item) in \(state)")
            }
        }
    }

    func testTheCarveOutOnlyAffectsTheFocusSessionTab() {
        // A live session must not re-enable the OTHER routine tabs (e.g. the other routine's tab).
        XCTAssertFalse(LeftMenuAvailability.isEnabled(.customRoutine, during: ._MORNING_HABIT_,
                                                      isAllowedActivityRunning: true))
        XCTAssertFalse(LeftMenuAvailability.isEnabled(.microBreaks, during: ._MORNING_HABIT_,
                                                      isAllowedActivityRunning: true))
    }

    // MARK: - Postponed is not active

    func testEveryPostponedStateLeavesTheWholeMenuEnabled() {
        for state in postponedStates {
            XCTAssertTrue(state.isRoutinePostponed, "\(state) should read as postponed")
            for item in LeftMenuRoutineItem.allCases {
                XCTAssertTrue(LeftMenuAvailability.isEnabled(item, during: state),
                              "\(item) should be enabled while \(state)")
            }
            XCTAssertNil(LeftMenuAvailability.disableReason(for: state), "\(state) restricts nothing")
        }
    }

    func testAnActiveRoutineDoesNotReadAsPostponed() {
        for state in activeRoutineStates {
            XCTAssertFalse(state.isRoutinePostponed, "\(state)")
        }
        XCTAssertFalse(CURRENTSTATE._NOTHING_.isRoutinePostponed)
    }

    // MARK: - Idle

    func testIdleLeavesTheWholeMenuEnabled() {
        for item in LeftMenuRoutineItem.allCases {
            XCTAssertTrue(LeftMenuAvailability.isEnabled(item, during: ._NOTHING_), "\(item)")
        }
        XCTAssertNil(LeftMenuAvailability.disableReason(for: ._NOTHING_))
    }

    // MARK: - Reasons

    func testEachActiveRoutineStateNamesItsOwnReason() {
        XCTAssertEqual(LeftMenuAvailability.disableReason(for: ._MORNING_HABIT_), .morningRoutine)
        XCTAssertEqual(LeftMenuAvailability.disableReason(for: ._EVENING_HABIT_), .eveningRoutine)
        XCTAssertEqual(LeftMenuAvailability.disableReason(for: ._FOCUS_SUMMARY_), .focusSummary)
        XCTAssertEqual(LeftMenuAvailability.disableReason(for: ._SHUTOFFMAC_), .shutoffTime)
        XCTAssertEqual(LeftMenuAvailability.disableReason(for: ._CUSTOM_ROUTINE_), .customRoutine)
    }

    /// A micro break runs its own (stricter) disable pass in `microBreaksStarted`, so the routine rule
    /// must not claim it — otherwise a state change would re-enable the tabs the break just closed off.
    func testAMicroBreakIsNotGovernedByTheRoutineRule() {
        XCTAssertNil(LeftMenuAvailability.disableReason(for: ._MICRO_BREAK_))
    }
}

/// The focus-mode picker in the menu-bar popover is an `NSComboBox` driven by SwiftUI. `updateNSView`
/// runs on every refresh, so writing the selected mode's name back unconditionally made the field
/// impossible to type in: each keystroke left `stringValue` differing from the selection, and the next
/// refresh overwrote it. Typing "Deep" reverted to "Meetings" letter by letter.
final class BlockListComboBoxTextTests: XCTestCase {

    func testTypedTextIsNotOverwrittenWhileEditing() {
        XCTAssertFalse(BlockListComboBox.shouldOverwriteText(isEditing: true, current: "Deep",
                                                             selectedName: "Meetings"),
                       "While the user is typing, their text is the truth")
        for partial in ["D", "De", "Dee", "Deep"] {
            XCTAssertFalse(BlockListComboBox.shouldOverwriteText(isEditing: true, current: partial,
                                                                 selectedName: "Meetings"),
                           "\(partial) must survive a SwiftUI refresh")
        }
    }

    /// The sync still has to happen, or the field stops reflecting a selection made elsewhere.
    func testSelectionIsWrittenBackWhenNotEditing() {
        XCTAssertTrue(BlockListComboBox.shouldOverwriteText(isEditing: false, current: "Deep",
                                                            selectedName: "Meetings"))
        XCTAssertTrue(BlockListComboBox.shouldOverwriteText(isEditing: false, current: "",
                                                            selectedName: "Meetings"))
    }

    /// No redundant writes: rewriting an identical value would move the insertion point.
    func testNoWriteWhenTheTextAlreadyMatches() {
        XCTAssertFalse(BlockListComboBox.shouldOverwriteText(isEditing: false, current: "Meetings",
                                                             selectedName: "Meetings"))
        XCTAssertFalse(BlockListComboBox.shouldOverwriteText(isEditing: true, current: "Meetings",
                                                             selectedName: "Meetings"))
    }
}
