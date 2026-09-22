//
//  LateNoMoreDismissSync.swift
//  Focus Bear
//
//  Cross-device Late No More meeting-dismissal sync — the macOS leg.
//
//  When the user deals with a Late No More meeting reminder on the Mac (attends it, or says "I
//  don't need to attend"), the same meeting is still queued to buzz on their phone. Reporting the
//  dismissal to the backend lets it silence every other device — see backend#2395 and
//  mobile-app#5108 for the other two legs of the contract.
//
//  Meetings cannot be matched by id across devices: the Mac's reminder comes from EventKit, the
//  phone reads its own local calendar and the backend stores the calendar provider's id, so the
//  same meeting carries three different ids. Title + start time are the only fields that agree, so
//  that is what both the wire protocol and `LateNoMoreEventMatcher` key on.
//

import Foundation

/// Why a Late No More meeting reminder stopped on this Mac. Sent as the `dismiss_reason` field.
enum LateNoMoreDismissReason: String {
    /// "Back to habits - I don't need to attend": the user is skipping the meeting entirely, so
    /// every device should stop reminding them about it. Same value the mobile app sends.
    case stopReminders = "stop_reminders"
    /// "Thanks!": the user acknowledged the reminder here and is attending the meeting on the Mac,
    /// so the phone no longer needs to nag.
    case joinedOnMac = "joined_on_mac"
}

/// Wire constants for the three-legged dismissal contract. Fixed by backend#2395 — do not rename
/// the values, only the code references.
enum LateNoMoreSyncContract {
    /// Appended to `baseUrl`. Accepts meetings the backend has never synced, and answers 204.
    static let dismissEndpointPath = "notifications/calendar-events/dismiss"
    /// `notification_type` the backend sends to a user's other devices when a meeting is dismissed.
    ///
    /// Documented here for the day the Mac can receive it. It is deliberately NOT bound to anything
    /// today: the backend delivers this payload over FCM / Pusher Beams only, and the macOS app
    /// registers for neither (no `aps-environment` entitlement, no push token upload). See the PR
    /// description for what the inbound leg needs.
    static let dismissedNotificationType = "late_no_more_event_dismissed"
    /// Backend DTO limits (`dismissCalendarEvent.dto.ts`); over-long values are rejected, so trim.
    static let maxSummaryLength = 2500
    static let maxDismissReasonLength = 255
    /// Devices round a meeting's start instant differently, so treat two starts this far apart as
    /// the same meeting. Mirrors mobile's `EVENT_MATCH_TOLERANCE_MS` and the backend's window.
    static let eventStartMatchToleranceSeconds: TimeInterval = 60
}

/// The identity of one meeting reminder, reduced to the fields that survive crossing devices.
struct LateNoMoreMeeting: Equatable {
    /// Platform-local id when one is known. Only ever a fast path — never required for a match.
    let id: String?
    let title: String
    let startDate: Date

    init(id: String? = nil, title: String, startDate: Date) {
        self.id = id
        self.title = title
        self.startDate = startDate
    }
}

/// Decides whether two references to a meeting — possibly made on different devices — are the same
/// meeting. Pure and side-effect free so it can be unit tested (`LateNoMoreEventMatcherTests`).
enum LateNoMoreEventMatcher {

    /// Priority order, copied from mobile's `findEventByTitleAndTime`:
    ///  1. fast path — both sides carry a non-empty id and the ids are equal;
    ///  2. titles equal once trimmed and case-folded, AND the start times are within
    ///     `eventStartMatchToleranceSeconds` of each other.
    static func isSameMeeting(_ candidate: LateNoMoreMeeting, as target: LateNoMoreMeeting) -> Bool {
        if let candidateId = candidate.id, let targetId = target.id,
           !candidateId.isEmpty, !targetId.isEmpty, candidateId == targetId {
            return true
        }
        guard normalisedTitle(candidate.title) == normalisedTitle(target.title),
              !normalisedTitle(target.title).isEmpty else { return false }
        let drift = abs(candidate.startDate.timeIntervalSince(target.startDate))
        return drift <= LateNoMoreSyncContract.eventStartMatchToleranceSeconds
    }

    /// The first meeting in `candidates` that is the same meeting as `target`, or nil.
    static func firstMatch(in candidates: [LateNoMoreMeeting], for target: LateNoMoreMeeting) -> LateNoMoreMeeting? {
        candidates.first { isSameMeeting($0, as: target) }
    }

    private static func normalisedTitle(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

/// Remembers which meetings the user has already dealt with on this Mac.
///
/// Late No More re-fires `focusbear://event-about-to-start` whenever its own warning state is
/// rebuilt (app relaunch, and after a sleep/wake replay), which used to re-open the appointment
/// popup for a meeting the user had already dismissed. The registry is in-memory only: it exists to
/// suppress a replay within the same app session, not to be a durable record — the backend now
/// holds that.
final class LateNoMoreDismissalRegistry {
    static let shared = LateNoMoreDismissalRegistry()

    /// A dismissal stops being interesting once the meeting is well past; drop it so the list can't
    /// grow for the lifetime of the app.
    private static let retentionSeconds: TimeInterval = 4 * 60 * 60

    private let queue = DispatchQueue(label: "io.focusbear.latenomore.dismissals")
    private var dismissedMeetings: [LateNoMoreMeeting] = []

    private init() {}

    func recordDismissal(of meeting: LateNoMoreMeeting) {
        queue.sync {
            purgeExpired()
            guard LateNoMoreEventMatcher.firstMatch(in: dismissedMeetings, for: meeting) == nil else { return }
            dismissedMeetings.append(meeting)
        }
    }

    func isDismissed(_ meeting: LateNoMoreMeeting) -> Bool {
        queue.sync {
            purgeExpired()
            return LateNoMoreEventMatcher.firstMatch(in: dismissedMeetings, for: meeting) != nil
        }
    }

    private func purgeExpired() {
        let cutoff = Date().addingTimeInterval(-Self.retentionSeconds)
        dismissedMeetings.removeAll { $0.startDate < cutoff }
    }
}

extension AllApi {

    /// Report a meeting reminder dismissed on this Mac so the user's other devices stop alerting.
    ///
    /// Best effort by design: the local dismissal has already happened by the time this runs, and a
    /// network failure must neither revert it nor be shown to the user — it is only logged.
    func reportLateNoMoreDismissal(meeting: LateNoMoreMeeting, reason: LateNoMoreDismissReason) {
        let summary = String(meeting.title.prefix(LateNoMoreSyncContract.maxSummaryLength))
        guard !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            addLog(text: "late-no-more dismiss:- skipped, meeting has no title")
            return
        }
        let dismissReason = String(reason.rawValue.prefix(LateNoMoreSyncContract.maxDismissReasonLength))

        appdelegate?.credentialsManager.credentials { credentialsInfo in
            appdelegate?.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard appdelegate?.credential != nil else {
                addLog(text: "late-no-more dismiss:- skipped, not logged in")
                return
            }
            guard let url = NSURL(string: "\(baseUrl)/\(LateNoMoreSyncContract.dismissEndpointPath)") else { return }

            let formatter = ISO8601DateFormatter()
            let json: [String: Any] = [
                "summary": summary,
                "event_begins": formatter.string(from: meeting.startDate),
                "dismiss_reason": dismissReason
            ]
            guard let body = try? JSONSerialization.data(withJSONObject: json) else { return }

            let request = makeRequest(responsePathUrl: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            addLog(text: "api call late-no-more dismiss (\(dismissReason)) \(url)")
            URLSession.shared.dataTask(with: request as URLRequest) { _, response, error in
                if let error = error {
                    addLog(text: "api call late-no-more dismiss error:- \(error.localizedDescription)")
                    return
                }
                guard let http = response as? HTTPURLResponse else { return }
                if (200...299).contains(http.statusCode) {
                    addLog(text: "api call late-no-more dismiss success")
                } else {
                    addLog(text: "api call late-no-more dismiss error:- statusCode is \(http.statusCode)")
                }
            }.resume()
        }
    }
}
