//
//  BreakStartKitTests.swift
//  Focus BearTests
//
//  Covers the pure logic behind the SwiftUI break start screen: the auto-start decision (the
//  5-second countdown is opt-in now), the countdown formatting, the chair-exercises /
//  full-movement mode mapping onto the app's office-mode setting and the activity filtering that
//  follows from it, plus the brain-dump save rules the screen inherits from NotesStore.
//

import XCTest
@testable import Focus_Bear

final class BreakStartKitTests: XCTestCase {

    // MARK: - Helpers

    private func makeActivity(name: String, isOfficeFriendly: Bool) -> breakActivity {
        breakActivity(id: name, name: name, durationSeconds: 15, IncludeInEveryBreak: false, urlsArray: [],
                      logQuantity: false, choiceType: ._NONE_, choices: [], logQuantityQuestion: nil,
                      openSpecificApps: false, allowUrls: [], allowApps: [], isOfficeFriendly: isOfficeFriendly,
                      allowedFocusMode: "", logQuantityType: "", activity_sequence_id: "", take_notes: "",
                      text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList: [])
    }

    // MARK: - Auto-start

    func testAutoStartOffLeavesTheScreenWaiting() {
        XCTAssertFalse(BreakStartKit.startDecision(autoStartEnabled: false).runsCountdown,
                       "with auto-start off the screen must wait for the Start button")
    }

    func testAutoStartOnRunsTheCountdown() {
        XCTAssertTrue(BreakStartKit.startDecision(autoStartEnabled: true).runsCountdown)
    }

    func testAutoStartCountdownKeepsTheFiveSecondsTheScreenAlwaysUsed() {
        XCTAssertEqual(BreakStartKit.autoStartCountdownSeconds, 5)
    }

    // MARK: - Countdown

    func testCountdownPadsToMinutesAndSeconds() {
        XCTAssertEqual(BreakStartKit.countdownText(remainingSeconds: 5), "00:05")
        XCTAssertEqual(BreakStartKit.countdownText(remainingSeconds: 60), "01:00")
        XCTAssertEqual(BreakStartKit.countdownText(remainingSeconds: 65), "01:05")
    }

    func testCountdownClampsAtZero() {
        XCTAssertEqual(BreakStartKit.countdownText(remainingSeconds: 0), "00:00")
        XCTAssertEqual(BreakStartKit.countdownText(remainingSeconds: -3), "00:00")
    }

    // MARK: - Mode mapping

    func testChairExercisesIsOfficeMode() {
        XCTAssertEqual(BreakStartKit.BreakMode.from(isOfficeModeEnabled: true), .chairExercises)
        XCTAssertTrue(BreakStartKit.BreakMode.chairExercises.isOfficeMode)
    }

    func testFullMovementIsWorkFromHome() {
        XCTAssertEqual(BreakStartKit.BreakMode.from(isOfficeModeEnabled: false), .fullMovement)
        XCTAssertFalse(BreakStartKit.BreakMode.fullMovement.isOfficeMode)
    }

    // MARK: - Which habits each mode lists

    func testChairExercisesListsOnlyOfficeFriendlyHabits() {
        let all = [makeActivity(name: "Chair stretch", isOfficeFriendly: true),
                   makeActivity(name: "Pushups", isOfficeFriendly: false)]
        let listed = BreakStartKit.activities(from: all, mode: .chairExercises)
        XCTAssertEqual(listed.map { $0.name }, ["Chair stretch"])
    }

    func testFullMovementListsEveryHabit() {
        let all = [makeActivity(name: "Chair stretch", isOfficeFriendly: true),
                   makeActivity(name: "Pushups", isOfficeFriendly: false)]
        let listed = BreakStartKit.activities(from: all, mode: .fullMovement)
        XCTAssertEqual(listed.count, 2)
    }

    func testSwitchingModeChangesWhichHabitsAreListed() {
        let all = [makeActivity(name: "Chair stretch", isOfficeFriendly: true),
                   makeActivity(name: "Dance", isOfficeFriendly: false)]
        XCTAssertNotEqual(BreakStartKit.activities(from: all, mode: .chairExercises).count,
                          BreakStartKit.activities(from: all, mode: .fullMovement).count)
    }

    func testOfficeModeIsOfferedOnlyWhenSomethingIsOfficeFriendly() {
        XCTAssertTrue(BreakStartKit.canEnterOfficeMode(from: [makeActivity(name: "Chair stretch", isOfficeFriendly: true)]))
        XCTAssertFalse(BreakStartKit.canEnterOfficeMode(from: [makeActivity(name: "Pushups", isOfficeFriendly: false)]))
        XCTAssertFalse(BreakStartKit.canEnterOfficeMode(from: []))
    }

    // MARK: - Where a break ends

    func testModeSwitchKeepsCompletedAndCurrentActivityWithOriginalRandomChoice() throws {
        let choice = activityChoice(name: "Original choice", urlsArray: [], logQuantityQuestion: "",
                                    logQuantity: false, logQuantityType: "", id: "choice-original")
        let done = breakActivityFilter(activity: makeActivity(name: "Done", isOfficeFriendly: true), randomChoice: nil)
        let current = breakActivityFilter(activity: makeActivity(name: "Current", isOfficeFriendly: true), randomChoice: choice)
        let next = breakActivityFilter(activity: makeActivity(name: "Dance", isOfficeFriendly: false), randomChoice: nil)
        let result = try XCTUnwrap(BreakStartKit.replacingUpcomingActivities(in: [done, current], currentIndex: 1,
                                                                          selected: [done, current, next]))
        XCTAssertEqual(result.map { $0.activity?.id }, ["Done", "Current", "Dance"])
        XCTAssertEqual(result[1].randomChoice?.id, "choice-original")
        XCTAssertEqual(result[1].activity?.durationSeconds, current.activity?.durationSeconds)
    }

    func testRepeatedModeSwitchesNeverReplayCompletedActivityIDs() throws {
        let rows = ["Done", "Current", "Dance", "Chair"].map {
            breakActivityFilter(activity: makeActivity(name: $0, isOfficeFriendly: $0 != "Dance"), randomChoice: nil)
        }
        let first = try XCTUnwrap(BreakStartKit.replacingUpcomingActivities(in: Array(rows.prefix(2)), currentIndex: 1, selected: rows))
        let second = try XCTUnwrap(BreakStartKit.replacingUpcomingActivities(in: first, currentIndex: 2, selected: rows))
        XCTAssertEqual(second.map { $0.activity?.id }, ["Done", "Current", "Dance", "Chair"])
    }

    func testModeSelectionExcludesPlayedActivitiesBeforeSamplingAndCanExhaustCandidates() {
        let chair = makeActivity(name: "Chair", isOfficeFriendly: true)
        let dance = makeActivity(name: "Dance", isOfficeFriendly: false)
        let available = BreakStartKit.unplayedActivities(from: [chair, dance], excludingIDs: ["Chair"])
        XCTAssertEqual(available.map { $0.id }, ["Dance"])
        XCTAssertTrue(BreakStartKit.activities(from: available, mode: .chairExercises).isEmpty)
        XCTAssertTrue(BreakStartKit.canEnterOfficeMode(from: [chair, dance]), "Exhausting this break must not turn office mode off")
        XCTAssertTrue(BreakStartKit.unplayedActivities(from: [chair, dance], excludingIDs: ["Chair", "Dance"]).isEmpty)
    }

    func testModeSwitchCountsThePreservedPrefixAgainstTheExistingActivityLimit() throws {
        let rows = ["Done", "Current", "Dance", "Chair"].map {
            breakActivityFilter(activity: makeActivity(name: $0, isOfficeFriendly: true), randomChoice: nil)
        }
        let result = try XCTUnwrap(BreakStartKit.replacingUpcomingActivities(in: Array(rows.prefix(2)), currentIndex: 1,
                                                                          selected: rows, totalLimit: 3))
        XCTAssertEqual(result.map { $0.activity?.id }, ["Done", "Current", "Dance"])
    }

    func testModeSwitchRejectsAnInvalidCurrentActivityWithoutReplacingTheQueue() {
        let row = breakActivityFilter(activity: makeActivity(name: "Current", isOfficeFriendly: true), randomChoice: nil)
        XCTAssertNil(BreakStartKit.replacingUpcomingActivities(in: [row], currentIndex: -1, selected: []))
        XCTAssertNil(BreakStartKit.replacingUpcomingActivities(in: [row], currentIndex: 1, selected: []))
        XCTAssertNil(BreakStartKit.replacingUpcomingActivities(in: [.init(activity: nil, randomChoice: nil)], currentIndex: 0, selected: [row]))
    }

    func testUnidentifiedActivitiesCannotReplayAfterAnUnidentifiedCurrentActivity() throws {
        var unknown = makeActivity(name: "Unknown", isOfficeFriendly: true)
        unknown.id = nil
        var empty = makeActivity(name: "Empty", isOfficeFriendly: true)
        empty.id = ""
        let known = makeActivity(name: "Dance", isOfficeFriendly: false)
        XCTAssertEqual(BreakStartKit.unplayedActivities(from: [unknown, empty, known], excludingIDs: []).count, 3,
                       "Existing callers keep their default selection behavior")
        XCTAssertEqual(BreakStartKit.unplayedActivities(from: [unknown, empty, known], excludingIDs: [""]).map { $0.id }, ["Dance"])
        let result = try XCTUnwrap(BreakStartKit.replacingUpcomingActivities(
            in: [.init(activity: unknown, randomChoice: nil)], currentIndex: 0,
            selected: [unknown, empty, known].map { .init(activity: $0, randomChoice: nil) }))
        XCTAssertEqual(result.count, 2)
        XCTAssertNil(result[0].activity?.id)
        XCTAssertEqual(result[1].activity?.id, "Dance")
    }

    func testPlayerButtonRoutesOppositeModesAndCannotActWhenHiddenOrRestricted() {
        var selected: [BreakStartKit.BreakMode] = []
        let button = BreakPlayerModeButton { selected.append($0) }
        button.update(mode: .chairExercises, isActiveBreak: true, isSelecting: false,
                      fullMovementTitle: "Full movement translated", seatedTitle: "Seated translated")
        XCTAssertEqual(button.title, "Full movement translated")
        button.performClick(nil)
        button.update(mode: .fullMovement, isActiveBreak: true, isSelecting: false,
                      fullMovementTitle: "Full movement translated", seatedTitle: "Seated translated")
        XCTAssertEqual(button.title, "Seated translated")
        button.performClick(nil)
        button.update(mode: .chairExercises, isActiveBreak: true, isSelecting: true,
                      fullMovementTitle: "Full movement translated", seatedTitle: "Seated translated")
        button.performClick(nil)
        button.update(mode: .chairExercises, isActiveBreak: false, isSelecting: false,
                      fullMovementTitle: "Full movement translated", seatedTitle: "Seated translated")
        button.performClick(nil)
        XCTAssertEqual(selected, [.fullMovement, .chairExercises])
        XCTAssertEqual(selected.map(\.profileName), ["wfh", "office"])
    }

    func testSpanishPlayerCopyFallsBackToInstalledTranslationsWhenRemoteConfigIsStale() {
        let oldRemote = ["buttonVideoText": "Vídeo", "buttonSwitchToSeatedBreak": "   "]
        let expected: [BreakPlayerText.Key: String] = [
            .fullMovement: "Cambiar a una pausa de movimiento completo",
            .seated: "Cambiar a una pausa con ejercicios sentados",
            .currentActivityHelp: "Tu actividad actual y tu progreso se mantienen. Las actividades restantes de la pausa usan el modo seleccionado.",
            .noRemainingHelp: "Tu actividad actual continúa. No quedan más actividades en esta pausa; el modo seleccionado se aplicará a tu próxima pausa.",
            .meetingHelp: "Esta pausa usa ejercicios sentados mientras tu reunión está en curso. Puedes cambiar de modo cuando termine la reunión.",
            .officeActivityPrompt: "No tienes ninguna actividad de descanso para la oficina ¿Quieres que agregue una para pararte y estirarte por 20 segundos?",
            .addOfficeActivity: "Si, suena bien",
            .declineOfficeActivity: " ¡No, soy una máquina! No necesito descanso."
        ]
        for key in BreakPlayerText.Key.allCases {
            XCTAssertEqual(BreakPlayerText.localized(key, languageCode: "es-MX", remote: oldRemote), expected[key])
        }
    }

    func testPlayerCopyUsesUpdatedRemoteTranslationWithoutCachingThePreviousLanguage() {
        XCTAssertEqual(BreakPlayerText.localized(.seated, languageCode: "es", remote: ["buttonSwitchToSeatedBreak": "Texto actualizado"]), "Texto actualizado")
        XCTAssertEqual(BreakPlayerText.localized(.seated, languageCode: "en", remote: [:]), "Switch to seated break")
        XCTAssertEqual(BreakPlayerText.localized(.seated, languageCode: "es", remote: [:]), "Cambiar a una pausa con ejercicios sentados")
    }

    func testBreakEndingDuringARunningSessionReturnsToTheSession() {
        XCTAssertEqual(BreakStartKit.destinationAfterBreak(isFocusSessionActive: true), .focusSession,
                       "a break must hand the user back to the session it interrupted, not to a task list")
    }

    func testBreakEndingWithNoSessionDoesNotOpenTheSessionScreen() {
        XCTAssertEqual(BreakStartKit.destinationAfterBreak(isFocusSessionActive: false), .suggestFocusSession,
                       "with nothing interrupted, keep the pre-session behaviour")
    }

    // MARK: - Brain dump save rules

    func testBrainDumpDoesNotSaveWhenNothingChanged() {
        XCTAssertFalse(NotesStore.shouldScheduleBrainDumpSave(body: "<p>same</p>", lastSavedBody: "<p>same</p>"))
        XCTAssertFalse(NotesStore.shouldCommitBrainDump(body: "<p>same</p>", lastSavedBody: "<p>same</p>",
                                                        hasExistingNote: true))
    }

    func testBrainDumpSavesAnEdit() {
        XCTAssertTrue(NotesStore.shouldScheduleBrainDumpSave(body: "<p>new thought</p>", lastSavedBody: ""))
        XCTAssertTrue(NotesStore.shouldCommitBrainDump(body: "<p>new thought</p>", lastSavedBody: "",
                                                       hasExistingNote: false))
    }

    func testEmptyBrainDumpNeverCreatesANote() {
        XCTAssertFalse(NotesStore.shouldCommitBrainDump(body: "<p>&nbsp;</p>", lastSavedBody: "<p>old</p>",
                                                        hasExistingNote: false),
                       "an empty body must not create a brand-new brain dump")
    }

    func testClearingAnExistingBrainDumpIsSaved() {
        XCTAssertTrue(NotesStore.shouldCommitBrainDump(body: "", lastSavedBody: "<p>old</p>",
                                                       hasExistingNote: true),
                      "clearing an existing brain dump should stick")
    }

    func testBrainDumpDebounceMatchesTheNotesScreen() {
        XCTAssertEqual(NotesStore.brainDumpSaveDelaySeconds, 2.0,
                       "the break start screen relies on the same 2 s debounce the Notes screen uses")
    }
}
