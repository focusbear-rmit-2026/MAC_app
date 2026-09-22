//
//  EventCancellation.swift
//  Focus Bear
//
//  The Day Plan event editor's destructive action — "Cancel Event" when the signed-in user organises
//  the meeting, "Decline event" when they were invited to it — plus the editor's SwiftUI chrome (the
//  title row with its ✕ close button and the destructive button itself).
//
//  Reported as: "Cancel doesn't do what you'd expect. I want to be able to cancel the event. If I'm the
//  event owner, 'Cancel Event' should actually cancel the event for everyone. If I'm not, I should have
//  'Decline event'. The current cancel (close) behaviour should be handled via X in the top right."
//
//  WHAT EVENTKIT CAN AND CANNOT DO (this is the whole reason the two actions differ):
//   • Cancelling as the organiser is real. `EKEventStore.remove(_:span:)` on an event the user organises
//     deletes it from the account, and a synced account (CalDAV/Exchange/Google) sends the resulting
//     cancellation on to the attendees. That is the same thing Calendar.app's Delete does.
//   • Declining as an attendee CANNOT be delivered from here. `EKParticipant.participantStatus`,
//     `EKEvent.status` and `EKEvent.attendees` are all `readonly` in the EventKit headers, and the
//     framework exposes no RSVP/respond API at all. So "Decline event" removes the user's OWN copy of
//     the invitation and nothing more; whether the organiser hears about it is up to the calendar
//     account (RFC 6638 CalDAV servers turn an attendee's delete into a DECLINE reply, others don't).
//     The confirmation sheet says exactly that rather than pretending an RSVP was sent.
//

import AppKit
import EventKit
import SwiftUI

// MARK: - Ownership

/// Who owns a calendar event, as far as EventKit can tell.
///
/// The organiser is the only trustworthy signal: `EKEvent.organizer` is nil for anything that was never
/// scheduled through an invitation (a hand-made event in a local calendar, most subscribed feeds), and
/// there is no other field that says "this is yours".
enum EventOwnership: Equatable {
    /// The signed-in user organises the event.
    case owned
    /// Someone else organises it — the user is an attendee.
    case notOwned
    /// The event records no organiser, so ownership genuinely can't be established.
    case unknown
}

enum EventOwnershipResolver {
    /// `organizerIsCurrentUser` is nil when the event carries no organiser at all.
    static func ownership(organizerIsCurrentUser: Bool?) -> EventOwnership {
        guard let isCurrentUser = organizerIsCurrentUser else { return .unknown }
        return isCurrentUser ? .owned : .notOwned
    }
}

// MARK: - The destructive action

/// The destructive action the event editor offers, derived from ownership.
enum EventCancelAction: Equatable {
    /// Organiser: remove the event, which a synced calendar account passes on as a cancellation.
    case cancelEvent
    /// Attendee (or unknown ownership): remove only the user's own copy of the event.
    case declineEvent

    /// Ownership picks the action, and **unknown ownership picks the non-destructive one**. Declining
    /// only ever touches the user's own copy; cancelling takes the meeting away from everyone, and that
    /// must never happen on a guess.
    init(ownership: EventOwnership) {
        self = (ownership == .owned) ? .cancelEvent : .declineEvent
    }

    /// True only for the action that affects other people's calendars too.
    var affectsOtherAttendees: Bool { self == .cancelEvent }

    var buttonTitle: String {
        switch self {
        case .cancelEvent: return ScheduleText.eventCancelEventButton
        case .declineEvent: return ScheduleText.eventDeclineEventButton
        }
    }

    var confirmTitle: String {
        switch self {
        case .cancelEvent: return ScheduleText.eventCancelEventConfirmTitle
        case .declineEvent: return ScheduleText.eventDeclineEventConfirmTitle
        }
    }

    var confirmMessage: String {
        switch self {
        case .cancelEvent: return ScheduleText.eventCancelEventConfirmMessage
        case .declineEvent: return ScheduleText.eventDeclineEventConfirmMessage
        }
    }
}

// MARK: - The confirm → scope → remove sequence

/// Drives "confirm, then (for a repeating event) ask which occurrences, then remove".
///
/// Kept as pure logic with injected handlers so the rule that matters — *nothing is removed until the
/// user has confirmed* — is covered by unit tests without an EventKit store or a visible sheet.
enum EventCancellationFlow {
    enum Outcome: Equatable {
        /// The event was removed with this span.
        case removed(EKSpan)
        /// The user backed out, at the confirmation or at the occurrence-scope question.
        case cancelledByUser
        /// The user confirmed but EventKit refused the removal (read-only calendar, event already gone).
        case failed
    }

    /// Asks `confirm` first and only ever calls `remove` after it answers true.
    /// - Parameters:
    ///   - isRecurring: whether the this-occurrence-vs-series question applies at all.
    ///   - knownScope: the span the user has ALREADY chosen for this editing session — the editor asks
    ///     when the form opens, so by the time the destructive action runs the answer normally exists.
    ///     Non-nil means `askScope` is never called: asking a second time is the bug in report
    ///     2026-09-15_20-53-31 ("I'd already said at the start that I wanted to edit all future
    ///     events"). nil means nobody has asked yet.
    ///   - askScope: the editor's repeating-event question, for the case where no answer exists yet;
    ///     nil means "back out".
    ///   - remove: performs the removal, returning whether EventKit accepted it.
    static func run(action: EventCancelAction,
                    isRecurring: Bool,
                    knownScope: EKSpan?,
                    confirm: @escaping (EventCancelAction, @escaping (Bool) -> Void) -> Void,
                    askScope: @escaping (@escaping (EKSpan?) -> Void) -> Void,
                    remove: @escaping (EKSpan) -> Bool,
                    completion: @escaping (Outcome) -> Void) {
        let finish: (EKSpan) -> Void = { span in
            completion(remove(span) ? .removed(span) : .failed)
        }
        confirm(action) { confirmed in
            guard confirmed else { completion(.cancelledByUser); return }
            // A one-off event has only one occurrence to remove, so there is nothing to ask.
            guard isRecurring else { finish(.thisEvent); return }
            if let alreadyChosen = knownScope { finish(alreadyChosen); return }
            askScope { span in
                guard let span = span else { completion(.cancelledByUser); return }
                finish(span)
            }
        }
    }
}

// MARK: - SwiftUI chrome for the event editor

/// Sizes for the event editor's SwiftUI header/footer, kept next to the views that use them.
enum EventFormMetrics {
    static let headerFontSize: CGFloat = 14
    static let closeGlyphFontSize: CGFloat = 11
    static let closeButtonSide: CGFloat = 20
    static let rowSpacing: CGFloat = 8
    static let closeSymbolName = "xmark"
}

/// The editor's title row: the heading, and the ✕ that closes the form.
///
/// Closing used to be a button labelled "Cancel" sitting next to "Save", which read as "cancel the
/// meeting" rather than "close this form". Dismissing is now the ✕ in the top right, and "Cancel" is
/// free to mean what the user expects it to mean.
@available(macOS 11.0, *)
struct EventFormHeaderView: View {
    let title: String
    /// Tooltip / VoiceOver label for the ✕ — it has no visible text of its own.
    let closeHint: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: EventFormMetrics.rowSpacing) {
            Text(title)
                .font(.system(size: EventFormMetrics.headerFontSize, weight: .bold))
            Spacer(minLength: 0)
            SwiftUI.Button(action: onClose) {
                Image(systemName: EventFormMetrics.closeSymbolName)
                    .font(.system(size: EventFormMetrics.closeGlyphFontSize, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: EventFormMetrics.closeButtonSide,
                           height: EventFormMetrics.closeButtonSide)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            // Esc used to be the old "Cancel" button's key equivalent; keep it working now that ✕ owns
            // dismissal.
            .keyboardShortcut(.cancelAction)
            .help(closeHint)
            .accessibilityLabel(Text(closeHint))
        }
    }
}

/// "Cancel Event" / "Decline event" — the editor's destructive action, tinted so it doesn't read as an
/// ordinary footer button next to "Save".
@available(macOS 11.0, *)
struct EventDestructiveActionView: View {
    let title: String
    let action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            Text(title).foregroundColor(.red)
        }
    }
}
