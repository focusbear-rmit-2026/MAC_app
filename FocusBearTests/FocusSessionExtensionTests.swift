//
//  FocusSessionExtensionTests.swift
//  FocusBearTests
//
//  Extending a focus session must not change AI relevance checking, must ask the AI accountability
//  buddy why the extra time is needed, and must act on the answer.
//
//  Product-owner reports: "When I extended the focus session a while back, it seemed to cancel the AI
//  blocking that was in place. It should have triggered the AI accountability buddy to ask why I need
//  more time." And later, on the question itself: "this screen doesn't seem to be connected to the
//  LLM. It allowed me to continue with this input lol" — the input being "play games".
//

@testable import Focus_Bear
import XCTest

class FocusSessionExtensionTests: XCTestCase {
    func testChatExtensionCannotGrantMoreThanRequestedOrApproved() {
        let purpose = AccountabilityChatPurpose.extendSession(minutes: 10)
        XCTAssertEqual(purpose.grantedMinutes(25), 10)
        XCTAssertEqual(purpose.grantedMinutes(5), 5)
        XCTAssertEqual(purpose.grantedMinutes(0), 0)
        XCTAssertEqual(AccountabilityChatPurpose.postponeRoutine.grantedMinutes(25), 25)
    }

    private let aiBlockListId = "block-list-with-ai"
    private let noAiBlockListId = "block-list-without-ai"

    private var savedFocusTypes: [[String: Any]] = []
    private var savedRunningFocusType: [String: Any] = [:]
    private var savedSchedules: [customBlockingSchedule] = []
    private var savedIsAnyCustomScheduleOn = false
    private var savedIsFocusModeRunning = false
    private var savedIsAnyAllowedFocusModeActivityRunning = false
    private var savedGlobalAiCheck = true
    private var savedIntention = ""
    private var savedEndFocusModeTime: Date?
    private var savedBuddy: AccountabilityBuddySession?
    private var savedCompletedBuddy: AccountabilityBuddySession?

    override func setUp() {
        super.setUp()
        savedFocusTypes = arrFocusType
        savedRunningFocusType = currentRunningFocusType
        savedSchedules = customBlockingScheduleManagerObj.arrBlockingSchedule
        savedIsAnyCustomScheduleOn = customBlockingScheduleManagerObj.isAnyCustomScheduleOn
        savedIsFocusModeRunning = isFocusModeRunning
        savedIsAnyAllowedFocusModeActivityRunning = isAnyAllowedFocusModeActivityRunning
        savedGlobalAiCheck = SettingsManagerObject.isAiCheckUrlEnabled
        savedIntention = whatToAchieveInFocusBlock
        savedEndFocusModeTime = endFocusModeTime
        savedBuddy = currentAccountabilityBuddySession
        savedCompletedBuddy = lastCompletedAccountabilityBuddySession
        currentAccountabilityBuddySession = nil
        lastCompletedAccountabilityBuddySession = nil

        arrFocusType = []
        currentRunningFocusType = [:]
        customBlockingScheduleManagerObj.arrBlockingSchedule = []
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = false
        isFocusModeRunning = false
        isAnyAllowedFocusModeActivityRunning = false
        whatToAchieveInFocusBlock = ""
        endFocusModeTime = nil
    }

    override func tearDown() {
        arrFocusType = savedFocusTypes
        currentRunningFocusType = savedRunningFocusType
        customBlockingScheduleManagerObj.arrBlockingSchedule = savedSchedules
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = savedIsAnyCustomScheduleOn
        isFocusModeRunning = savedIsFocusModeRunning
        isAnyAllowedFocusModeActivityRunning = savedIsAnyAllowedFocusModeActivityRunning
        SettingsManagerObject.isAiCheckUrlEnabled = savedGlobalAiCheck
        whatToAchieveInFocusBlock = savedIntention
        endFocusModeTime = savedEndFocusModeTime
        currentAccountabilityBuddySession = savedBuddy
        lastCompletedAccountabilityBuddySession = savedCompletedBuddy
        super.tearDown()
    }

    // MARK: - Fixtures

    private func blockList(id: String, isAiEnabled: Bool?) -> [String: Any] {
        var list: [String: Any] = [
            "id": id,
            "name": "Deep work",
            "isAllowedListApproach": true,
            "isOn": true
        ]
        if let isAiEnabled = isAiEnabled { list["is_ai_enabled"] = isAiEnabled }
        return list
    }

    private func runningSchedule(forBlockListId blockListId: String) -> customBlockingSchedule {
        var schedule = customBlockingSchedule(
            id: UUID().uuidString,
            name: "Work hours",
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date().addingTimeInterval(3600),
            startTimeString: "",
            endTimeString: "",
            daysOfWeek: [Calendar.current.component(.weekday, from: Date())],
            focusModeID: blockListId,
            blockLevel: ._NORMAL_,
            // Deliberately false: AI belongs to the BLOCK LIST, not the schedule. If the gate ever
            // reads this instead of the block list's is_ai_enabled, these tests fail.
            isAIBlockingEnabled: false,
            isMicroBreaksEnabled: false
        )
        schedule.state = .on
        return schedule
    }

    /// A focus session running the given block list, with no custom schedule involved.
    private func startFocusSession(on blockList: [String: Any]) {
        arrFocusType = [blockList]
        currentRunningFocusType = blockList
        isFocusModeRunning = true
    }

    /// A custom blocking schedule enforcing the given block list.
    private func startCustomSchedule(on blockList: [String: Any]) {
        arrFocusType = [blockList]
        currentRunningFocusType = blockList
        customBlockingScheduleManagerObj.arrBlockingSchedule = [
            runningSchedule(forBlockListId: blockList["id"] as? String ?? "")
        ]
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = true
    }

    // MARK: - (a) AI blocking survives an extension

    func test_extendingKeepsAIBlockingOn_whenAScheduleWasEnforcingAnAIBlockList() {
        let list = blockList(id: aiBlockListId, isAiEnabled: true)
        startCustomSchedule(on: list)
        XCTAssertTrue(SettingsManagerObject.isAIBlockingEnabled(),
                      "Precondition: the running block list has AI on, so AI blocking is on")

        FocusSessionExtension.applyLocalExtension(focusModeId: aiBlockListId, minutes: 10)

        XCTAssertTrue(customBlockingScheduleManagerObj.isAnyCustomScheduleOn,
                      "Extending continues the session; it must not finish the running blocking schedule")
        XCTAssertTrue(SettingsManagerObject.isAIBlockingEnabled(),
                      "AI blocking must stay on for the extended minutes")
    }

    func test_theGateFallsBackToTheGlobalToggleOnceTheScheduleIsFinished() {
        // Root cause, pinned. The extend path used to call customBlockingScheduleFinished() — copied
        // from AppDelegate.focusModeStartted(), where a NEW session legitimately supersedes a running
        // schedule. This is what that teardown does to the state isAIBlockingEnabled() reads: with the
        // schedule gone the gate stops consulting the block list the schedule was enforcing and falls
        // back to the global AI toggle, which is off for anyone who drives AI per block list.
        SettingsManagerObject.isAiCheckUrlEnabled = false
        startCustomSchedule(on: blockList(id: aiBlockListId, isAiEnabled: true))
        XCTAssertTrue(SettingsManagerObject.isAIBlockingEnabled())

        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = false

        XCTAssertFalse(SettingsManagerObject.isAIBlockingEnabled(),
                       "Finishing the schedule mid-session cancels the AI blocking that was in place")
    }

    func test_extendingDoesNotSwapTheScheduleBlockListForAnother() {
        // The post-session extend popup continues the block list of the session that just finished.
        // Tearing the schedule down handed AI relevance checking to THAT list instead of the one the
        // schedule was enforcing — the reported "extending cancelled the AI blocking".
        SettingsManagerObject.isAiCheckUrlEnabled = false
        let scheduleList = blockList(id: aiBlockListId, isAiEnabled: true)
        var completedSessionList = blockList(id: noAiBlockListId, isAiEnabled: false)
        completedSessionList["isOn"] = false
        arrFocusType = [scheduleList, completedSessionList]
        currentRunningFocusType = scheduleList
        customBlockingScheduleManagerObj.arrBlockingSchedule = [runningSchedule(forBlockListId: aiBlockListId)]
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = true
        XCTAssertTrue(SettingsManagerObject.isAIBlockingEnabled())

        FocusSessionExtension.applyLocalExtension(focusModeId: noAiBlockListId, minutes: 10)

        XCTAssertTrue(customBlockingScheduleManagerObj.isAnyCustomScheduleOn,
                      "The schedule enforcing the AI block list must survive the extension")
        XCTAssertTrue(SettingsManagerObject.isAIBlockingEnabled(),
                      "AI blocking stays on across the extension — the schedule's block list still governs")
    }

    func test_extendingDoesNotChangeTheAIVerdict_whenTheGlobalToggleIsOff() {
        // On this branch a focus mode's `is_ai_enabled` is a VETO ONLY: `false` turns AI off, but
        // `true` does NOT force it on over a global toggle the user switched off (see
        // SettingsManager.isAIBlockingEnabled). main's #2402 lets the flag force AI on instead, and
        // the upstream version of this test asserted that; keeping mega's semantics is deliberate.
        //
        // What #2494 actually guards is that EXTENDING doesn't move the decision — whatever the
        // verdict was for the session, the extra minutes inherit it unchanged. With no custom
        // schedule running and the global toggle off, that verdict is `false` both sides of the
        // extension. The per-block-list flag genuinely governing AI is covered, on the path where
        // mega honours it, by test_extendingKeepsAIBlockingOn_whenTheCustomScheduleIsRunning.
        SettingsManagerObject.isAiCheckUrlEnabled = false
        startFocusSession(on: blockList(id: aiBlockListId, isAiEnabled: true))
        let before = SettingsManagerObject.isAIBlockingEnabled()

        FocusSessionExtension.applyLocalExtension(focusModeId: aiBlockListId, minutes: 15)

        XCTAssertEqual(SettingsManagerObject.isAIBlockingEnabled(), before,
                       "an extension must never move the AI decision, in either direction")
    }

    func test_extendingRespectsThePerBlockListAIVeto() {
        // The block list the user turned AI off for must stay off — an extension must not switch AI on
        // any more than it may switch it off.
        SettingsManagerObject.isAiCheckUrlEnabled = true
        startFocusSession(on: blockList(id: noAiBlockListId, isAiEnabled: false))
        XCTAssertFalse(SettingsManagerObject.isAIBlockingEnabled())

        FocusSessionExtension.applyLocalExtension(focusModeId: noAiBlockListId, minutes: 5)

        XCTAssertFalse(SettingsManagerObject.isAIBlockingEnabled(),
                       "A block list with is_ai_enabled == false stays vetoed across an extension")
    }

    func test_extendingRestoresTheAIFlagWhenTheBlockListCopyLostIt() {
        // The extend paths re-read the block list out of arrFocusType. A copy that lost is_ai_enabled
        // would read as "AI on" (absent ⇒ on) and silently switch AI on for a vetoed list.
        SettingsManagerObject.isAiCheckUrlEnabled = true
        startFocusSession(on: blockList(id: noAiBlockListId, isAiEnabled: false))
        let before = FocusSessionExtension.captureBlockingContext()

        currentRunningFocusType = blockList(id: noAiBlockListId, isAiEnabled: nil)
        XCTAssertTrue(FocusSessionExtension.reapplyBlockingContext(before),
                      "Losing the flag counts as drift and must be reported")
        XCTAssertEqual(currentRunningFocusType["is_ai_enabled"] as? Bool, false)
        XCTAssertFalse(SettingsManagerObject.isAIBlockingEnabled())
    }

    func test_preservingAILeavesADifferentBlockListAlone() {
        // "Use AI" belongs to the block list. Never fabricate a flag for a list the user didn't choose.
        startFocusSession(on: blockList(id: aiBlockListId, isAiEnabled: true))
        let before = FocusSessionExtension.captureBlockingContext()

        let other = blockList(id: noAiBlockListId, isAiEnabled: false)
        let preserved = FocusSessionExtension.focusModePreservingAI(other, before: before)

        XCTAssertEqual(preserved["is_ai_enabled"] as? Bool, false)
    }

    func test_extendingMovesTheScheduledEndOutAndKeepsTheBlockListRunning() {
        startFocusSession(on: blockList(id: aiBlockListId, isAiEnabled: true))
        let now = Date()

        let index = FocusSessionExtension.applyLocalExtension(focusModeId: aiBlockListId, minutes: 20, now: now)

        XCTAssertEqual(index, 0)
        XCTAssertEqual(arrFocusType[0]["isOn"] as? Bool, true)
        XCTAssertNotNil(arrFocusType[0]["lastScheduledEndDate"] as? String)
        XCTAssertEqual(endFocusModeTime?.timeIntervalSince(now) ?? 0, 20 * 60, accuracy: 1)
        XCTAssertTrue(isFocusModeRunning)
    }

    func test_extendingAnUnknownBlockListChangesNothing() {
        startFocusSession(on: blockList(id: aiBlockListId, isAiEnabled: true))

        let index = FocusSessionExtension.applyLocalExtension(focusModeId: "not-a-block-list", minutes: 10)

        XCTAssertNil(index)
        XCTAssertNil(endFocusModeTime)
    }

    // MARK: - (b) The AI accountability buddy asks why

    func test_buddyIsAskedWhyWhenAIBlockingGovernsTheSession() {
        startFocusSession(on: blockList(id: aiBlockListId, isAiEnabled: true))
        XCTAssertTrue(FocusSessionExtension.shouldAskWhyMoreTimeIsNeeded())
    }

    func test_buddyIsNotAskedWhenAIBlockingIsOffForTheBlockList() {
        SettingsManagerObject.isAiCheckUrlEnabled = true
        startFocusSession(on: blockList(id: noAiBlockListId, isAiEnabled: false))
        XCTAssertFalse(FocusSessionExtension.shouldAskWhyMoreTimeIsNeeded(),
                       "No AI blocking to explain yourself to — don't nag")
    }

    func testCompletedBuddyRequiresFreshApprovalEvenAfterItsAIBlockingHasStopped() {
        SettingsManagerObject.isAiCheckUrlEnabled = false
        lastCompletedAccountabilityBuddySession = AccountabilityBuddySession(
            goal: "Complete the NOAT form", allowedApps: [], allowedUrls: [], durationMinutes: 15)
        XCTAssertTrue(FocusSessionExtension.shouldAskWhyMoreTimeIsNeeded())

        var granted = false
        FocusSessionExtension.askWhyMoreTimeIsNeeded(minutes: 15, presenter: nil) { _ in granted = true }
        XCTAssertFalse(granted, "An unavailable chat must not silently restart the completed buddy")
        XCTAssertEqual(lastCompletedAccountabilityBuddySession?.goal, "Complete the NOAT form")
        XCTAssertFalse(isFocusModeRunning)
        XCTAssertNil(endFocusModeTime)
    }

    func testRunningBuddyRequiresApprovalEvenWithGlobalAISettingOff() {
        SettingsManagerObject.isAiCheckUrlEnabled = false
        currentAccountabilityBuddySession = AccountabilityBuddySession(
            goal: "Finish work", allowedApps: [], allowedUrls: [], durationMinutes: 15)
        XCTAssertTrue(FocusSessionExtension.shouldAskWhyMoreTimeIsNeeded())
    }

    func testNonPositiveExtensionDoesNotProceedWithoutAIBlocking() {
        SettingsManagerObject.isAiCheckUrlEnabled = false
        for minutes in [0, -1] {
            FocusSessionExtension.askWhyMoreTimeIsNeeded(minutes: minutes, presenter: nil) { _ in
                XCTFail("Invalid duration must not continue into routine postponement")
            }
        }
    }

    func test_extensionReasonBecomesPartOfTheFocusIntention() {
        XCTAssertEqual(
            FocusSessionExtension.intentionAfterExtension(
                previousIntention: "Write the release notes",
                reason: "Proofread the last section"),
            "Write the release notes — Proofread the last section")
    }

    func test_extensionReasonIsTheIntentionWhenThereWasNoneYet() {
        XCTAssertEqual(
            FocusSessionExtension.intentionAfterExtension(previousIntention: "", reason: "Finish the invoice"),
            "Finish the invoice")
    }

    func test_blankExtensionReasonLeavesTheIntentionUnchanged() {
        XCTAssertEqual(
            FocusSessionExtension.intentionAfterExtension(
                previousIntention: "Write the release notes", reason: "   \n "),
            "Write the release notes")
    }

    func test_repeatedExtensionReasonIsNotAppendedTwice() {
        let once = FocusSessionExtension.intentionAfterExtension(
            previousIntention: "Write the release notes", reason: "Proofread")
        XCTAssertEqual(
            FocusSessionExtension.intentionAfterExtension(previousIntention: once, reason: "Proofread"),
            once)
    }

    func test_applyingAReasonUpdatesTheRunningSessionIntention() {
        whatToAchieveInFocusBlock = "Write the release notes"
        FocusSessionExtension.applyExtensionReason("Proofread the last section")
        XCTAssertEqual(whatToAchieveInFocusBlock, "Write the release notes — Proofread the last section")
    }

    func test_applyingABlankReasonLeavesTheRunningSessionIntentionAlone() {
        whatToAchieveInFocusBlock = "Write the release notes"
        FocusSessionExtension.applyExtensionReason("")
        XCTAssertEqual(whatToAchieveInFocusBlock, "Write the release notes")
    }

    // MARK: - (c) The buddy judges the answer

    // The product owner typed "play games" into the extend sheet and was given the extra ten minutes:
    // the screen captured the answer and asked nobody. These cover the decision around the check —
    // aligns, doesn't align, and can't-reach-the-server — with the network injected.

    private func awaitVerdict(reason: String,
                              intention: String = "Write the release notes",
                              checker: TaskIntentionChecking,
                              fallback: String = "Fallback push-back",
                              timeout: TimeInterval = 2) -> ExtendReasonVerdict? {
        let answered = expectation(description: "verdict")
        var verdict: ExtendReasonVerdict?
        FocusSessionExtension.checkExtensionReason(reason,
                                                   intention: intention,
                                                   focusMode: "Deep work",
                                                   checker: checker,
                                                   fallbackPushBackMessage: fallback,
                                                   timeout: timeout) {
            verdict = $0
            answered.fulfill()
        }
        waitForExpectations(timeout: 5)
        return verdict
    }

    func test_anAlignedReasonExtendsStraightAway() {
        let checker = StubTaskIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: true, reason: "")))
        XCTAssertEqual(awaitVerdict(reason: "Proofread the last section", checker: checker), .extendNow)
        XCTAssertEqual(checker.receivedTaskName, "Proofread the last section")
        XCTAssertEqual(checker.receivedIntention, "Write the release notes")
    }

    func test_aConflictingReasonPushesBackWithTheServersWords() {
        let serverReason = #"Your focus intention is "Write the release notes", but this task is "play games"."#
        let checker = StubTaskIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: false, reason: serverReason)))
        XCTAssertEqual(awaitVerdict(reason: "play games", checker: checker),
                       .pushBack(reason: serverReason))
    }

    func test_aConflictWithNoReasonFallsBackToOurOwnWording() {
        let checker = StubTaskIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: false, reason: "  ")))
        XCTAssertEqual(awaitVerdict(reason: "play games", checker: checker, fallback: "Fallback push-back"),
                       .pushBack(reason: "Fallback push-back"))
    }

    func test_anUnreachableServerExtendsAnyway() {
        let checker = StubTaskIntentionChecker(outcome: .failure(URLError(.notConnectedToInternet)))
        XCTAssertEqual(awaitVerdict(reason: "play games", checker: checker), .extendNow,
                       "Offline must never cost the user the minutes they asked for")
    }

    func test_aServerThatNeverAnswersExtendsWhenTheCheckTimesOut() {
        XCTAssertEqual(awaitVerdict(reason: "play games", checker: SilentTaskIntentionChecker(), timeout: 0.2),
                       .extendNow,
                       "A modal sheet must never be left spinning on a stalled request")
    }

    func test_aSessionWithNoIntentionIsNotWorthChecking() {
        let checker = StubTaskIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: false, reason: "Never asked")))
        XCTAssertEqual(awaitVerdict(reason: "play games", intention: "  ", checker: checker), .extendNow)
        XCTAssertFalse(checker.wasAsked, "Nothing to compare the answer against")
    }

    func test_aSkippedQuestionIsNotSentToTheServer() {
        let checker = StubTaskIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: false, reason: "Never asked")))
        XCTAssertEqual(awaitVerdict(reason: "   ", checker: checker), .extendNow)
        XCTAssertFalse(checker.wasAsked, "Skip still means skip")
    }

    func test_anUnparseableAnswerFailsOpen() {
        XCTAssertEqual(
            FocusSessionExtension.verdictForExtensionReason(
                .failure(TaskIntentionCheckError.badResponse(statusCode: 500)),
                fallbackPushBackMessage: "Fallback push-back"),
            .extendNow)
    }
}

/// An alignment check with a canned answer, so the decision can be tested without a server.
private final class StubTaskIntentionChecker: TaskIntentionChecking {
    private let outcome: Result<TaskIntentionAlignment, Error>
    private(set) var wasAsked = false
    private(set) var receivedIntention = ""
    private(set) var receivedTaskName = ""

    init(outcome: Result<TaskIntentionAlignment, Error>) {
        self.outcome = outcome
    }

    func checkTaskIntentionAlignment(intention: String,
                                     taskName: String,
                                     focusMode: String?,
                                     completion: @escaping (Result<TaskIntentionAlignment, Error>) -> Void) {
        wasAsked = true
        receivedIntention = intention
        receivedTaskName = taskName
        DispatchQueue.main.async { completion(self.outcome) }
    }
}

/// A check that accepts the request and never answers — the offline/stalled-refresh case.
private final class SilentTaskIntentionChecker: TaskIntentionChecking {
    func checkTaskIntentionAlignment(intention: String,
                                     taskName: String,
                                     focusMode: String?,
                                     completion: @escaping (Result<TaskIntentionAlignment, Error>) -> Void) {}
}
