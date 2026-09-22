//
//  FocusSessionStopPermissionTests.swift
//  FocusBearTests
//
//  Covers who may stop / pause a running focus session without the password gate.
//
//  Regression: a Late No More meeting session runs super-strict while it protects an unfinished
//  routine. That gate was only bypassed while the in-memory `currentAccountabilityBuddySession` was
//  alive, so once the app restarted — the session comes back super-strict from UserDefaults, the buddy
//  globals do not — the user was locked into a meeting session they never opted into and could not stop
//  or pause. The durable, focus-mode-scoped marker these tests cover is what survives that restart.
//

@testable import Focus_Bear
import XCTest

final class FocusSessionStopPermissionTests: XCTestCase {

    private let meetingModeId = "1f2ee09c-a286-4868-8a71-eb4ec6858c8a"
    private let ownModeId = "7006de5a-8a40-4883-bca7-6caac92a2bb1"

    private var savedMarker: Any?
    private var originalMarkerKey = ""
    private var savedAutoStarted = false
    private var savedRunningFocusType: [String: Any] = [:]
    private var savedFocusTypes: [[String: Any]] = []
    private var savedBuddySession: AccountabilityBuddySession?

    override func setUp() {
        super.setUp()
        // Keep the real app's session marker intact during local restart/permission tests.
        originalMarkerKey = kUserdefaultsIsFocusSessionAutoStarted
        kUserdefaultsIsFocusSessionAutoStarted = "FocusBear.Tests.FocusSessionStopPermission.\(UUID().uuidString)"
        savedMarker = UserDefaults.standard.object(forKey: kUserdefaultsIsFocusSessionAutoStarted)
        savedAutoStarted = isFocusSessionAutoStarted
        savedRunningFocusType = currentRunningFocusType
        savedFocusTypes = arrFocusType
        savedBuddySession = currentAccountabilityBuddySession
        UserDefaults.standard.removeObject(forKey: kUserdefaultsIsFocusSessionAutoStarted)
        currentAccountabilityBuddySession = nil
        // The marker is stamped against the running focus mode. Drive that from currentRunningFocusType
        // alone so these tests don't depend on whatever the test host's arrFocusType happens to hold.
        arrFocusType = []
    }

    override func tearDown() {
        if let savedMarker {
            UserDefaults.standard.set(savedMarker, forKey: kUserdefaultsIsFocusSessionAutoStarted)
        } else {
            UserDefaults.standard.removeObject(forKey: kUserdefaultsIsFocusSessionAutoStarted)
        }
        kUserdefaultsIsFocusSessionAutoStarted = originalMarkerKey
        isFocusSessionAutoStarted = savedAutoStarted
        currentRunningFocusType = savedRunningFocusType
        arrFocusType = savedFocusTypes
        currentAccountabilityBuddySession = savedBuddySession
        super.tearDown()
    }

    /// Stand in for a session start on `focusModeId`: the app records the marker against the mode that
    /// is running. `focusModeStartted` does this with `false` on every start; the auto-started paths
    /// (Late No More meeting / accountability buddy) follow it with `true`.
    private func startSession(onMode focusModeId: String, autoStarted: Bool) {
        currentRunningFocusType = ["id": focusModeId]
        setFocusSessionAutoStarted(autoStarted)
    }

    /// Stand in for the app being killed and relaunched into the still-running session: every in-memory
    /// global is gone, and `resumeFocusModeAfterAppStartted` re-reads the marker for the resumed mode.
    private func simulateRestart(resuming focusModeId: String) {
        isFocusSessionAutoStarted = false
        currentAccountabilityBuddySession = nil
        currentRunningFocusType = ["id": focusModeId]
        restoreFocusSessionAutoStartedFlag(resumedFocusModeId: focusModeId)
    }

    // MARK: - The decision itself

    func testAutoStartedSuperStrictSessionIsStoppableAndPausable() {
        XCTAssertFalse(FocusSessionStopPermission.requiresPassword(strictness: ._SUPER_STRICT_,
                                                                   flag: true,
                                                                   hasLiveBuddySession: false))
    }

    func testUserStartedSuperStrictSessionIsNeitherStoppableNorPausable() {
        XCTAssertTrue(FocusSessionStopPermission.requiresPassword(strictness: ._SUPER_STRICT_,
                                                                  flag: false,
                                                                  hasLiveBuddySession: false))
    }

    func testLiveBuddySessionKeepsItsExistingBypass() {
        // Unchanged behaviour: while the in-memory buddy session is alive it alone lifts the gate, so a
        // session started by a build that predates the durable marker still stops.
        XCTAssertFalse(FocusSessionStopPermission.requiresPassword(strictness: ._SUPER_STRICT_,
                                                                   flag: false,
                                                                   hasLiveBuddySession: true))
    }

    func testOnlySuperStrictGatesAUserStartedSession() {
        for strictness in [FOCUSMODESTRICTNESS._NORMAL_, ._STRICT_] {
            XCTAssertFalse(FocusSessionStopPermission.requiresPassword(strictness: strictness,
                                                                       flag: false,
                                                                       hasLiveBuddySession: false),
                           "\(strictness) must not demand a password")
        }
    }

    func testEitherSignalAloneMarksTheSessionAutoStarted() {
        XCTAssertTrue(FocusSessionStopPermission.isAutoStarted(flag: true, hasLiveBuddySession: false))
        XCTAssertTrue(FocusSessionStopPermission.isAutoStarted(flag: false, hasLiveBuddySession: true))
        XCTAssertTrue(FocusSessionStopPermission.isAutoStarted(flag: true, hasLiveBuddySession: true))
        XCTAssertFalse(FocusSessionStopPermission.isAutoStarted(flag: false, hasLiveBuddySession: false))
    }

    // MARK: - What a restart restores

    func testRestoredFlagOnlyCountsWhenItWasRecordedForTheResumedMode() {
        XCTAssertTrue(FocusSessionStopPermission.restoredAutoStartedFlag(
            storedFlag: true, storedFocusModeId: meetingModeId, resumedFocusModeId: meetingModeId))
        XCTAssertFalse(FocusSessionStopPermission.restoredAutoStartedFlag(
            storedFlag: true, storedFocusModeId: meetingModeId, resumedFocusModeId: ownModeId),
            "a marker from another focus mode must not unlock this session")
        XCTAssertFalse(FocusSessionStopPermission.restoredAutoStartedFlag(
            storedFlag: nil, storedFocusModeId: nil, resumedFocusModeId: meetingModeId),
            "no marker at all reads as user-started")
        XCTAssertFalse(FocusSessionStopPermission.restoredAutoStartedFlag(
            storedFlag: false, storedFocusModeId: meetingModeId, resumedFocusModeId: meetingModeId))
    }

    func testAutoStartedMarkerSurvivesARestart() {
        startSession(onMode: meetingModeId, autoStarted: true)
        simulateRestart(resuming: meetingModeId)

        XCTAssertTrue(isFocusSessionAutoStarted)
        XCTAssertTrue(isCurrentFocusSessionAutoStarted())
        XCTAssertFalse(FocusSessionStopPermission.requiresPassword(strictness: ._SUPER_STRICT_,
                                                                   flag: isFocusSessionAutoStarted,
                                                                   hasLiveBuddySession: false),
                       "a meeting session resumed after a restart must still be stoppable")
    }

    func testRestartResumingADifferentModeDoesNotInheritTheBypass() {
        startSession(onMode: meetingModeId, autoStarted: true)
        simulateRestart(resuming: ownModeId)

        XCTAssertFalse(isFocusSessionAutoStarted)
        XCTAssertTrue(FocusSessionStopPermission.requiresPassword(strictness: ._SUPER_STRICT_,
                                                                  flag: isFocusSessionAutoStarted,
                                                                  hasLiveBuddySession: false))
    }

    func testRestartWithNoMarkerAtAllReadsAsUserStarted() {
        simulateRestart(resuming: ownModeId)

        XCTAssertFalse(isFocusSessionAutoStarted)
        XCTAssertTrue(FocusSessionStopPermission.requiresPassword(strictness: ._SUPER_STRICT_,
                                                                  flag: isFocusSessionAutoStarted,
                                                                  hasLiveBuddySession: false))
    }

    // MARK: - The bypass must not leak onto the user's own session

    func testUserStartedSessionDoesNotInheritAPreviousAutoStartedBypass() {
        // A Late No More meeting session runs and ends…
        startSession(onMode: meetingModeId, autoStarted: true)
        currentAccountabilityBuddySession = nil

        // …then the user starts their own super-strict session. focusModeStartted() re-stamps the marker
        // on every start, so the meeting's bypass must not carry over.
        startSession(onMode: ownModeId, autoStarted: false)

        XCTAssertFalse(isCurrentFocusSessionAutoStarted())
        XCTAssertTrue(FocusSessionStopPermission.requiresPassword(strictness: ._SUPER_STRICT_,
                                                                  flag: isFocusSessionAutoStarted,
                                                                  hasLiveBuddySession: false),
                      "the user's own super-strict session keeps its password gate")
    }

    /// The marker also gates whether a persisted accountability-buddy record may re-attach after a
    /// relaunch: a record that outlived its session must not be adopted by a session the user started.
    func testMarkerDistinguishesNeverWrittenFromExplicitlyUserStarted() {
        XCTAssertTrue(focusSessionAutoStartedMarkerIsAbsent(),
                      "no marker written yet reads as absent, not as user-started")

        startSession(onMode: ownModeId, autoStarted: false)
        XCTAssertFalse(focusSessionAutoStartedMarkerIsAbsent(),
                       "a session recorded as user-started is a fact, not an absence")
    }

    func testTheUsersOwnSessionStaysGatedAcrossARestartToo() {
        startSession(onMode: meetingModeId, autoStarted: true)
        startSession(onMode: ownModeId, autoStarted: false)
        simulateRestart(resuming: ownModeId)

        XCTAssertFalse(isFocusSessionAutoStarted)
        XCTAssertTrue(FocusSessionStopPermission.requiresPassword(strictness: ._SUPER_STRICT_,
                                                                  flag: isFocusSessionAutoStarted,
                                                                  hasLiveBuddySession: false))
    }
}
