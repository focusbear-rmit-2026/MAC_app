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
//  The inbound leg: the backend broadcasts every dismissal as the Pusher Channels event
//  `late-no-more-event-dismissed` on `private-<userId>`, sender included. This Mac drops its own
//  echo by `device_id`, remembers the meeting, and relays it to the Late No More app, which owns
//  the alerts and the speech. Late No More has no account of its own, so it also relays the user's
//  own acknowledgements back here to be reported. The two apps talk over distributed notifications
//  (`LateNoMoreBridgeContract`), so neither has to be frontmost or launch the other.
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
    /// Pusher Channels event on `private-<userId>` carrying a dismissal made on any of the user's
    /// devices. The macOS app has no APNs/FCM registration, so this is the only way it hears one.
    static let dismissedPusherEventName = "late-no-more-event-dismissed"
    /// Request body keys (`DismissCalendarEventDto`).
    static let summaryKey = "summary"
    static let dismissReasonKey = "dismiss_reason"
    /// The meeting's start instant, under the same key in the request and in the broadcast.
    static let eventBeginsKey = "event_begins"
    /// The reporting device, echoed back in the broadcast so it can ignore its own dismissal.
    static let deviceIdKey = "device_id"
    /// Broadcast-only keys (`CalendarEventDismissalBroadcast`).
    static let broadcastTitleKey = "event_title"
    static let broadcastEventIdKey = "event_id"
    /// Backend DTO limits (`dismissCalendarEvent.dto.ts`); over-long values are rejected, so trim.
    static let maxSummaryLength = 2500
    static let maxDismissReasonLength = 255
    /// Devices round a meeting's start instant differently, so treat two starts this far apart as
    /// the same meeting. Mirrors mobile's `EVENT_MATCH_TOLERANCE_MS` and the backend's window.
    static let eventStartMatchToleranceSeconds: TimeInterval = 60
}

/// Wire contract with the Late No More app (`FocusBearDismissalBridge` in its
/// `MeetingDismissalSync.swift`). The two copies must keep these values identical.
enum LateNoMoreBridgeContract {
    /// Focus Bear → Late No More: the meeting was dealt with on another device, so stop alerting.
    static let dismissedElsewhereNotification = Notification.Name("io.focusbear.late-no-more.meeting-dismissed-elsewhere")
    /// Late No More → Focus Bear: the user dealt with the meeting in Late No More, so report it.
    static let acknowledgedNotification = Notification.Name("io.focusbear.late-no-more.meeting-acknowledged")
    static let eventTitleKey = "event_title"
    /// ISO-8601, same format as the `event_start_time` of `focusbear://event-about-to-start`.
    static let eventBeginsKey = "event_begins"
    static let dismissReasonKey = "dismiss_reason"
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

/// Decoding for both inbound legs. Pure, so the rules are unit tested (`LateNoMoreEventMatcherTests`).
enum LateNoMoreDismissalDecoder {

    /// The meeting a `late-no-more-event-dismissed` broadcast names, or nil when it is this Mac's
    /// own echo or does not name a meeting.
    static func meetingFromBroadcast(_ payload: [String: Any], ownDeviceId: String) -> LateNoMoreMeeting? {
        if let sender = payload[LateNoMoreSyncContract.deviceIdKey] as? String, !sender.isEmpty, sender == ownDeviceId {
            return nil
        }
        guard let title = payload[LateNoMoreSyncContract.broadcastTitleKey] as? String,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let beginsText = payload[LateNoMoreSyncContract.eventBeginsKey] as? String,
              let startDate = parseDate(beginsText) else { return nil }
        return LateNoMoreMeeting(id: payload[LateNoMoreSyncContract.broadcastEventIdKey] as? String,
                                 title: title, startDate: startDate)
    }

    /// The meeting and reason in an acknowledgement relayed by the Late No More app, or nil if malformed.
    static func acknowledgementFromLateNoMore(_ userInfo: [AnyHashable: Any]?) -> (meeting: LateNoMoreMeeting, reason: LateNoMoreDismissReason)? {
        guard let title = userInfo?[LateNoMoreBridgeContract.eventTitleKey] as? String,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let beginsText = userInfo?[LateNoMoreBridgeContract.eventBeginsKey] as? String,
              let startDate = parseDate(beginsText) else { return nil }
        let reasonText = userInfo?[LateNoMoreBridgeContract.dismissReasonKey] as? String ?? ""
        return (LateNoMoreMeeting(title: title, startDate: startDate),
                LateNoMoreDismissReason(rawValue: reasonText) ?? .stopReminders)
    }

    /// The `userInfo` Late No More expects for a meeting dismissed elsewhere.
    static func lateNoMoreUserInfo(for meeting: LateNoMoreMeeting) -> [String: String] {
        [LateNoMoreBridgeContract.eventTitleKey: meeting.title,
         LateNoMoreBridgeContract.eventBeginsKey: ISO8601DateFormatter().string(from: meeting.startDate)]
    }

    /// The `device_id` to send with a dismissal: the backend rejects anything that is not a UUID.
    static func reportableDeviceId(_ deviceId: String) -> String? {
        UUID(uuidString: deviceId) == nil ? nil : deviceId
    }

    /// The backend sends milliseconds (`2026-09-14T09:00:00.000Z`); Late No More sends whole seconds.
    private static func parseDate(_ text: String) -> Date? {
        let withFractionalSeconds = ISO8601DateFormatter()
        withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFractionalSeconds.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }
}

/// Connects the backend's dismissal broadcast and the Late No More app.
enum LateNoMoreDismissalRelay {

    /// Handle a `late-no-more-event-dismissed` Pusher event. Returns whether it named another device's dismissal.
    @discardableResult
    static func handleBroadcast(eventData: String?) -> Bool {
        guard let bytes = eventData?.data(using: .utf8),
              let payload = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: Any],
              let meeting = LateNoMoreDismissalDecoder.meetingFromBroadcast(payload, ownDeviceId: currentDeviceId) else {
            return false
        }
        // Remembered so a later `event-about-to-start` for it does not pause the routine. A popup
        // already on screen stays: it decides how this Mac's routine is postponed, not whether to alert.
        LateNoMoreDismissalRegistry.shared.recordDismissal(of: meeting)
        DistributedNotificationCenter.default().postNotificationName(
            LateNoMoreBridgeContract.dismissedElsewhereNotification,
            object: nil,
            userInfo: LateNoMoreDismissalDecoder.lateNoMoreUserInfo(for: meeting),
            deliverImmediately: true)
        return true
    }

    /// Report the meetings the user deals with inside the Late No More app. Call once, at launch.
    static func startRelayingLateNoMoreAcknowledgements() {
        DistributedNotificationCenter.default().addObserver(
            forName: LateNoMoreBridgeContract.acknowledgedNotification,
            object: nil,
            queue: .main) { notification in
                guard let acknowledgement = LateNoMoreDismissalDecoder.acknowledgementFromLateNoMore(notification.userInfo) else {
                    addLog(text: "late-no-more relay:- ignoring a malformed acknowledgement")
                    return
                }
                addLog(text: "late-no-more relay:- acknowledged in Late No More (\(acknowledgement.reason.rawValue))")
                LateNoMoreDismissalRegistry.shared.recordDismissal(of: acknowledgement.meeting)
                allApiObject.reportLateNoMoreDismissal(meeting: acknowledgement.meeting, reason: acknowledgement.reason)
            }
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
            var json: [String: Any] = [
                LateNoMoreSyncContract.summaryKey: summary,
                LateNoMoreSyncContract.eventBeginsKey: formatter.string(from: meeting.startDate),
                LateNoMoreSyncContract.dismissReasonKey: dismissReason
            ]
            // Lets this Mac recognise the backend's broadcast of its own dismissal and ignore it.
            if let deviceId = LateNoMoreDismissalDecoder.reportableDeviceId(currentDeviceId) {
                json[LateNoMoreSyncContract.deviceIdKey] = deviceId
            }
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
