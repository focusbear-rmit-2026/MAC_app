//
//  EventCancellationTests.swift
//  Focus BearTests
//
//  The Day Plan event editor's destructive action (EventCancellation.swift): which of "Cancel Event" /
//  "Decline event" the editor offers, and the rule that nothing is removed until the user confirms.
//
//  Reported as: "Cancel doesn't do what you'd expect… If I'm the event owner, 'Cancel Event' should
//  actually cancel the event for everyone. If I'm not, I should have 'Decline event'."
//

@testable import Focus_Bear
import EventKit
import XCTest

final class EventCancellationTests: XCTestCase {

    /// The English string the app ships for `key`. `ScheduleText` reads whatever config is live at
    /// runtime (which may be a downloaded or translated one), so the exact wording is asserted against
    /// the bundled English config instead — that is what the report asked for, word for word.
    private static func bundledEnglish(_ key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let schedule = root["scheduleViewInfo"] as? [String: Any] else { return nil }
        return schedule[key] as? String
    }

    // MARK: - Ownership → action

    func testOrganiserIsTheCurrentUserMeansTheEventIsOwned() {
        XCTAssertEqual(EventOwnershipResolver.ownership(organizerIsCurrentUser: true), .owned)
    }

    func testSomeoneElsesOrganiserMeansTheEventIsNotOwned() {
        XCTAssertEqual(EventOwnershipResolver.ownership(organizerIsCurrentUser: false), .notOwned)
    }

    func testNoOrganiserAtAllLeavesOwnershipUnknown() {
        // A hand-made event in a local calendar carries no organiser — EventKit simply can't say.
        XCTAssertEqual(EventOwnershipResolver.ownership(organizerIsCurrentUser: nil), .unknown)
    }

    func testOwnerGetsCancelEvent() {
        let action = EventCancelAction(ownership: .owned)
        XCTAssertEqual(action, .cancelEvent)
        XCTAssertEqual(action.buttonTitle, ScheduleText.eventCancelEventButton)
        XCTAssertEqual(Self.bundledEnglish("eventCancelEventButton"), "Cancel Event")
        XCTAssertTrue(action.affectsOtherAttendees, "cancelling takes the meeting off everyone's calendar")
    }

    func testNonOwnerGetsDeclineEvent() {
        let action = EventCancelAction(ownership: .notOwned)
        XCTAssertEqual(action, .declineEvent)
        XCTAssertEqual(action.buttonTitle, ScheduleText.eventDeclineEventButton)
        XCTAssertEqual(Self.bundledEnglish("eventDeclineEventButton"), "Decline event")
        XCTAssertFalse(action.affectsOtherAttendees, "declining must leave the event intact for everyone else")
    }

    func testUnknownOwnershipFallsBackToTheNonDestructiveAction() {
        let action = EventCancelAction(ownership: .unknown)
        XCTAssertEqual(action, .declineEvent, "never offer to cancel a meeting for everyone on a guess")
        XCTAssertEqual(action.buttonTitle, ScheduleText.eventDeclineEventButton)
        XCTAssertFalse(action.affectsOtherAttendees)
    }

    func testEachActionHasItsOwnConfirmationCopy() {
        XCTAssertNotEqual(EventCancelAction.cancelEvent.confirmTitle,
                          EventCancelAction.declineEvent.confirmTitle)
        // The decline copy must be honest that Focus Bear can't send an RSVP — EventKit has no API for it.
        XCTAssertTrue(EventCancelAction.declineEvent.confirmMessage.contains("RSVP"),
                      "the decline confirmation has to state the EventKit limitation")
        XCTAssertFalse(EventCancelAction.cancelEvent.confirmMessage.isEmpty)
    }

    // MARK: - The confirm → scope → remove sequence

    /// Records what the flow asked for, so a test can assert the ORDER as well as the outcome.
    private final class FlowSpy {
        private(set) var confirmCount = 0
        private(set) var scopeCount = 0
        private(set) var removedSpans: [EKSpan] = []
        private(set) var outcome: EventCancellationFlow.Outcome?

        var confirmAnswer = true
        var scopeAnswer: EKSpan? = .thisEvent
        var removeSucceeds = true

        func run(action: EventCancelAction, isRecurring: Bool, knownScope: EKSpan? = nil) {
            EventCancellationFlow.run(
                action: action,
                isRecurring: isRecurring,
                knownScope: knownScope,
                confirm: { _, done in self.confirmCount += 1; done(self.confirmAnswer) },
                askScope: { done in self.scopeCount += 1; done(self.scopeAnswer) },
                remove: { span in self.removedSpans.append(span); return self.removeSucceeds },
                completion: { self.outcome = $0 })
        }
    }

    func testNothingIsRemovedUntilTheUserConfirms() {
        let spy = FlowSpy()
        spy.confirmAnswer = false
        spy.run(action: .cancelEvent, isRecurring: false)

        XCTAssertEqual(spy.confirmCount, 1, "the confirmation is not optional")
        XCTAssertTrue(spy.removedSpans.isEmpty, "declining the confirmation must remove nothing")
        XCTAssertEqual(spy.outcome, .cancelledByUser)
    }

    func testNothingIsRemovedUntilTheUserConfirmsARepeatingEventEither() {
        let spy = FlowSpy()
        spy.confirmAnswer = false
        spy.run(action: .declineEvent, isRecurring: true)

        XCTAssertEqual(spy.scopeCount, 0, "backing out at the confirmation must not go on to ask the scope")
        XCTAssertTrue(spy.removedSpans.isEmpty)
        XCTAssertEqual(spy.outcome, .cancelledByUser)
    }

    func testConfirmingAOneOffEventRemovesJustThatEventWithoutAskingTheScope() {
        let spy = FlowSpy()
        spy.run(action: .cancelEvent, isRecurring: false)

        XCTAssertEqual(spy.scopeCount, 0, "a non-repeating event has no this-occurrence-vs-series question")
        XCTAssertEqual(spy.removedSpans, [.thisEvent])
        XCTAssertEqual(spy.outcome, .removed(.thisEvent))
    }

    func testARepeatingEventIsAskedTheScopeAfterConfirmation() {
        let spy = FlowSpy()
        spy.scopeAnswer = .futureEvents
        spy.run(action: .cancelEvent, isRecurring: true)

        XCTAssertEqual(spy.confirmCount, 1)
        XCTAssertEqual(spy.scopeCount, 1, "reuse the editor's existing repeating-event question")
        XCTAssertEqual(spy.removedSpans, [.futureEvents])
        XCTAssertEqual(spy.outcome, .removed(.futureEvents))
    }

    func testBackingOutOfTheScopeQuestionRemovesNothing() {
        let spy = FlowSpy()
        spy.scopeAnswer = nil
        spy.run(action: .cancelEvent, isRecurring: true)

        XCTAssertTrue(spy.removedSpans.isEmpty, "Cancel on the scope question must leave the event alone")
        XCTAssertEqual(spy.outcome, .cancelledByUser)
    }

    // MARK: - The scope is asked ONCE (report 2026-09-15_20-53-31)

    func testAScopeAlreadyChosenWhenTheFormOpenedIsNotAskedForAgain() {
        // "when I declined a calendar series it asked me this at the end — I'd already said at the
        // start that I wanted to edit all future events."
        let spy = FlowSpy()
        spy.run(action: .declineEvent, isRecurring: true, knownScope: .futureEvents)

        XCTAssertEqual(spy.confirmCount, 1, "the destructive confirmation is still shown")
        XCTAssertEqual(spy.scopeCount, 0, "the user answered this when the form opened; asking again is the bug")
        XCTAssertEqual(spy.outcome, .removed(.futureEvents))
    }

    func testTheScopeChosenWhenTheFormOpenedIsTheOneTheRemovalUses() {
        // Asking once but then removing the wrong span would be worse than asking twice.
        for chosen in [EKSpan.thisEvent, .futureEvents] {
            let spy = FlowSpy()
            spy.scopeAnswer = (chosen == .thisEvent) ? .futureEvents : .thisEvent   // must be ignored
            spy.run(action: .cancelEvent, isRecurring: true, knownScope: chosen)

            XCTAssertEqual(spy.removedSpans, [chosen], "the removal must apply to the span the user picked")
            XCTAssertEqual(spy.outcome, .removed(chosen))
        }
    }

    func testANonRecurringEventIsNeverAskedTheScopeEvenWithOneRecorded() {
        // A one-off event has a single occurrence; there is no series question to answer.
        let spy = FlowSpy()
        spy.run(action: .declineEvent, isRecurring: false, knownScope: .futureEvents)

        XCTAssertEqual(spy.scopeCount, 0)
        XCTAssertEqual(spy.removedSpans, [.thisEvent], "a one-off event only ever removes itself")
    }

    func testARepeatingEventWithNoRecordedScopeStillGetsAsked() {
        // The editor normally asks when the form opens, so this is the fallback path — it must still
        // ask rather than silently guessing a span.
        let spy = FlowSpy()
        spy.scopeAnswer = .futureEvents
        spy.run(action: .cancelEvent, isRecurring: true, knownScope: nil)

        XCTAssertEqual(spy.scopeCount, 1)
        XCTAssertEqual(spy.removedSpans, [.futureEvents])
    }

    func testARecordedScopeStillWaitsForTheDestructiveConfirmation() {
        let spy = FlowSpy()
        spy.confirmAnswer = false
        spy.run(action: .cancelEvent, isRecurring: true, knownScope: .futureEvents)

        XCTAssertTrue(spy.removedSpans.isEmpty, "a recorded scope must not skip the confirmation")
        XCTAssertEqual(spy.outcome, .cancelledByUser)
    }

    func testARefusedRemovalReportsFailureRatherThanPretendingItWorked() {
        // A read-only calendar (a subscribed feed) rejects the removal; the editor must say so instead
        // of closing as if the event had gone.
        let spy = FlowSpy()
        spy.removeSucceeds = false
        spy.run(action: .declineEvent, isRecurring: false)

        XCTAssertEqual(spy.removedSpans, [.thisEvent])
        XCTAssertEqual(spy.outcome, .failed)
    }
}
