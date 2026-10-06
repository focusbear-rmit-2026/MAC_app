//
//  EventsService.swift
//  Focus Bear
//
//  Where `EventBuffer` posts analytics events and the shape of each one. Foundation only, so the UI
//  tests can compile it too and share the switch and URLs rather than copy them.
//

import Foundation

/// The events-service stack `EventBuffer` posts to.
///
/// v2 (aws-infra #94) is the stack every launch posts to: it splits DB writes from third-party
/// notifications, accepts the same payload, auth header and batch shape as v1, and went live on
/// production on 2026-10-04 (EventsV2UITests got HTTP 204 for the Mac's payload, unchanged). v1
/// (`events.aws.focusbear.io`) stays reachable per launch as the escape hatch if v2 misbehaves.
enum EventsEndpoint: String, CaseIterable {
    case v1
    case v2

    /// The stack a launch posts to when nothing in its environment or arguments picks one.
    static let defaultEndpoint: EventsEndpoint = .v2

    /// Set in the environment to pick the stack for this launch: `enabledValue` for v2,
    /// `disabledValue` for v1. Any other value leaves `defaultEndpoint`.
    static let environmentKey = "FOCUSBEAR_EVENTS_V2"
    static let enabledValue = "1"
    static let disabledValue = "0"
    /// Forces v1 as a launch argument, for launches that can't set the environment.
    static let forceV1LaunchArgument = "--eventsV1"

    /// Chosen once per launch: switching stacks mid-session would split one session's events.
    static let current = select(environment: ProcessInfo.processInfo.environment,
                                arguments: ProcessInfo.processInfo.arguments)

    /// v1 wins when both are asked for: it is the way out when v2 is the thing going wrong.
    static func select(environment: [String: String], arguments: [String]) -> EventsEndpoint {
        let requested = environment[environmentKey]
        if requested == disabledValue || arguments.contains(forceV1LaunchArgument) {
            return .v1
        }
        if requested == enabledValue {
            return .v2
        }
        return defaultEndpoint
    }

    /// Production hosts. v2's is `EVENTS_V2_DOMAIN_CONFIG[PROD].domainName` in aws-infra
    /// `lib/service/backend-service.ts`.
    static let v1Host = "events.aws.focusbear.io"
    static let v2Host = "events-v2.aws.focusbear.io"
    /// Both stacks ingest at the same scheme and path.
    static let scheme = "https"
    static let ingestPath = "/events"

    var host: String {
        switch self {
        case .v1: return Self.v1Host
        case .v2: return Self.v2Host
        }
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = host
        components.path = Self.ingestPath
        return components.url!
    }

    /// v2's ingest rejects a larger request with 413 (`MAX_BATCH_SIZE` in the events-v2 stack).
    static let serverMaxEventsPerRequest = 1000
}

/// One event in the body `EventBuffer` posts: the fields the events service's `TrackEventDto`
/// validates. v1 and v2 share that DTO, and it is strict: `user_properties`, `event_data` and
/// `operating_system` have no `@IsOptional`, so an event missing any of them is rejected, and
/// the whitelist silently drops any top-level field it doesn't declare.
enum TrackEventPayload {
    enum Key {
        static let eventType = "event_type"
        static let userProperties = "user_properties"
        static let eventData = "event_data"
        static let data = "data"
        static let operatingSystem = "operating_system"
        /// Sent since #1255, but not in the DTO, so both stacks drop it and read the version from
        /// the `app-version` header instead.
        static let appVersion = "app_version"
        static let userName = "USERNAME"
        static let userId = "id"
        static let usesMacApp = "USES_MAC_APP"
    }

    static let operatingSystem = "macos"

    static func make(event: String, metadata: [String: Any], userId: String, userName: String,
                     appVersion: String) -> [String: Any] {
        [
            Key.eventType: event,
            Key.userProperties: [
                Key.userName: userName,
                Key.userId: userId,
                Key.usesMacApp: true,
            ] as [String: Any],
            Key.eventData: [Key.data: metadata],
            Key.operatingSystem: operatingSystem,
            Key.appVersion: appVersion,
        ]
    }
}
