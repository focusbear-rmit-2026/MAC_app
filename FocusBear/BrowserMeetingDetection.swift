//
//  BrowserMeetingDetection.swift
//  Focus Bear
//
//  Pure rules for recognising a call held in a web browser, kept out of AppDelegate so they can be
//  tested. Report 2026-10-06_13-30-40: a Teams web meeting in Chrome went undetected and the talking
//  clock spoke mid-call. The mic owner read as "Unknown" (Chrome captures audio in a helper process
//  that is not an app), and only Chrome's front window was searched for the meeting tab.
//

import AppKit

/// What kind of process holds the microphone, as far as meeting detection needs to know.
enum MicOwnerKind: String, Equatable {
    /// The mic is off.
    case none
    /// The mic is on but no owner could be named: CoreAudio listed no process (some Bluetooth
    /// inputs), or a process whose app could not be resolved.
    case unknown
    /// A recognised web browser holds the mic.
    case browser
    /// A named app that is not a browser holds the mic (dictation, a desktop meeting app…).
    case otherApp

    static func classify(isMicOn: Bool, owners: [MicApp]) -> MicOwnerKind {
        guard isMicOn else { return .none }
        if owners.isEmpty { return .unknown }
        if owners.contains(where: { $0.browser != nil }) { return .browser }
        if owners.contains(where: { $0.isUnresolved }) { return .unknown }
        return .otherApp
    }
}

extension MicApp {
    /// Placeholder name/bundle id for a mic process whose app could not be resolved.
    static let unknownName = "Unknown"

    /// No app could be resolved. Its bundle id may still be CoreAudio's (e.g. a helper's).
    var isUnresolved: Bool { appName == Self.unknownName }

    /// The browser behind this mic owner — by bundle id (which also covers helper bundle ids such as
    /// `com.google.Chrome.helper`) or, failing that, by app name.
    var browser: BROWSER? {
        browserFromBundleId(bundleID) ?? getCurrentBrowserFrom(browserName: appName.lowercased())
    }
}

/// Browser meeting URLs: which hosts belong to a meeting platform, and which URLs on them are a live
/// room rather than the platform's home page.
enum BrowserMeetingUrlRules {
    struct Rule {
        /// Matched by suffix so per-org subdomains (`acme.zoom.us`, `gov.teams.microsoft.us`) count.
        let hostSuffix: String
        /// Fragments that mark a live room. Empty ⇒ any non-root path on the host is a room
        /// (e.g. `whereby.com/my-room`), except `homePagePaths`.
        let liveMeetingFragments: [String]
        /// Paths that are the platform's home page even though they are not "/".
        var homePagePaths: [String] = []
    }

    /// Teams web keeps a joined meeting on several URL shapes: the classic `meetup-join` link, the
    /// anonymous `light-meetings/launch` page, `/meet/<id>` links and the v2 client's
    /// `/v2/?meetingjoin=true#/meet/<id>`. A signed-in v2 call can also sit on a bare `/v2/` URL,
    /// which only counts together with a browser-held mic (see `BrowserMeetingDecision`).
    private static let teamsLiveMeetingFragments = ["meetup-join", "light-meetings", "/l/meeting", "/meet/", "meetingjoin=true", "#/meet"]

    static let rules: [Rule] = [
        Rule(hostSuffix: "teams.microsoft.com", liveMeetingFragments: teamsLiveMeetingFragments),
        Rule(hostSuffix: "teams.live.com", liveMeetingFragments: teamsLiveMeetingFragments),
        Rule(hostSuffix: "teams.cloud.microsoft", liveMeetingFragments: teamsLiveMeetingFragments),
        // Government clouds: gov.teams.microsoft.us, dod.teams.microsoft.us.
        Rule(hostSuffix: "teams.microsoft.us", liveMeetingFragments: teamsLiveMeetingFragments),
        Rule(hostSuffix: "zoom.us", liveMeetingFragments: ["/j/", "/wc/", "/s/", "/my/"]),
        // Meet's home page redirects to /landing.
        Rule(hostSuffix: "meet.google.com", liveMeetingFragments: [], homePagePaths: ["/landing"]),
        Rule(hostSuffix: "meet.jit.si", liveMeetingFragments: []),
        Rule(hostSuffix: "whereby.com", liveMeetingFragments: []),
        // Zoho Meeting rooms live on meeting.zoho.<region> — never meet.zoho.com (#2388).
        Rule(hostSuffix: "meeting.zoho.com", liveMeetingFragments: []),
        Rule(hostSuffix: "meeting.zoho.eu", liveMeetingFragments: []),
        Rule(hostSuffix: "meeting.zoho.in", liveMeetingFragments: []),
        Rule(hostSuffix: "meeting.zoho.com.au", liveMeetingFragments: []),
        Rule(hostSuffix: "webex.com", liveMeetingFragments: ["/meet/", "/join/", "/wbxmjs/", "/j.php"]),
    ]

    static func rule(for url: String) -> Rule? {
        let host = getDomainFromUrl(url: url).lowercased()
        guard !host.isEmpty else { return nil }
        return rules.first { host == $0.hostSuffix || host.hasSuffix("." + $0.hostSuffix) }
    }

    /// True when `url` is on a meeting platform at all, home page included.
    static func isMeetingPlatform(_ url: String) -> Bool {
        rule(for: url) != nil
    }

    /// True when `url` is a live room or join link, not the platform's home page.
    static func isLiveMeeting(_ url: String) -> Bool {
        guard let rule = rule(for: url) else { return false }
        guard !rule.liveMeetingFragments.isEmpty else {
            let path = NSURL(string: url)?.path ?? ""
            return path.count > 1 && !rule.homePagePaths.contains(path.lowercased())
        }
        let loweredUrl = url.lowercased()
        return rule.liveMeetingFragments.contains { loweredUrl.contains($0) }
    }
}

/// Decides whether the open browser tabs show a call, given who holds the mic. Only consulted while
/// the mic, camera or a keep-awake assertion is already on.
enum BrowserMeetingDecision {
    enum Reason: String, Equatable {
        /// A tab is a live room/join link (or one of the Meetings focus's allowed URLs).
        case liveMeetingTab
        /// A tab is on a meeting platform and a browser — or a process nobody could name — holds the
        /// mic. Covers a Teams v2 call whose URL stays on `/v2/`.
        case meetingPlatformTabWithBrowserMic
    }

    struct TabEvidence: Equatable {
        var hasLiveMeetingTab = false
        var hasMeetingPlatformTab = false

        static func from(tabUrls: [String], isAllowedMeetingUrl: (String) -> Bool) -> TabEvidence {
            var evidence = TabEvidence()
            for url in tabUrls {
                if BrowserMeetingUrlRules.isLiveMeeting(url) || isAllowedMeetingUrl(url) {
                    evidence.hasLiveMeetingTab = true
                    return evidence
                }
                if BrowserMeetingUrlRules.isMeetingPlatform(url) {
                    evidence.hasMeetingPlatformTab = true
                }
            }
            return evidence
        }
    }

    static func reason(evidence: TabEvidence, micOwner: MicOwnerKind) -> Reason? {
        if evidence.hasLiveMeetingTab { return .liveMeetingTab }
        guard evidence.hasMeetingPlatformTab else { return nil }
        // A named non-browser owner (a dictation app, say) is not the browser tab talking; with the
        // mic off a platform tab is just an open tab.
        switch micOwner {
        case .browser, .unknown: return .meetingPlatformTabWithBrowserMic
        case .none, .otherApp: return nil
        }
    }
}

/// Maps a process that is capturing audio to the app the user sees. Browsers capture in helper
/// processes — "Google Chrome Helper", Edge/Brave helpers, Firefox's plugin-container, Safari's
/// WebKit GPU process — none of which `NSRunningApplication` resolves to the browser.
enum MicOwnerResolver {
    /// A helper is normally a direct child of its browser; the bound only stops a broken process table
    /// from looping.
    static let maxParentHops = 8

    /// The owning app's pid: the process itself if it is a regular app, else the first regular-app
    /// ancestor (Chromium and Firefox helpers are children of the browser), else the process macOS holds
    /// responsible (WebKit's XPC services are children of launchd, but Safari is responsible for them).
    static func owningApplicationPID(of pid: pid_t,
                                     parentPID: (pid_t) -> pid_t?,
                                     responsiblePID: (pid_t) -> pid_t?,
                                     isRegularApplication: (pid_t) -> Bool) -> pid_t? {
        if isRegularApplication(pid) { return pid }
        var current = pid
        for _ in 0..<maxParentHops {
            guard let parent = parentPID(current), parent > 1, parent != current else { break }
            if isRegularApplication(parent) { return parent }
            current = parent
        }
        if let responsible = responsiblePID(pid), responsible != pid, isRegularApplication(responsible) {
            return responsible
        }
        return nil
    }

    /// `com.google.Chrome.helper.renderer` → `com.google.Chrome`. Nil when the bundle id has no
    /// `helper` component (WebKit's `com.apple.WebKit.GPU` serves every WebKit app, so it can't be
    /// mapped by name).
    static func parentBundleIdentifier(ofHelper bundleID: String) -> String? {
        let components = bundleID.split(separator: ".")
        guard let helperIndex = components.firstIndex(where: { $0.lowercased() == "helper" }),
              helperIndex > 0 else { return nil }
        return components[..<helperIndex].joined(separator: ".")
    }

    static func owningApplication(of pid: pid_t, coreAudioBundleID: String?) -> NSRunningApplication? {
        if let ownerPID = owningApplicationPID(of: pid, parentPID: parentPID, responsiblePID: responsiblePID,
                                               isRegularApplication: isRegularApplication),
           let owner = NSRunningApplication(processIdentifier: ownerPID) {
            return owner
        }
        if let own = NSRunningApplication(processIdentifier: pid) { return own }
        guard let helperBundleID = coreAudioBundleID,
              let parentBundleID = parentBundleIdentifier(ofHelper: helperBundleID) else { return nil }
        return NSRunningApplication.runningApplications(withBundleIdentifier: parentBundleID).first
    }

    private static func isRegularApplication(_ pid: pid_t) -> Bool {
        NSRunningApplication(processIdentifier: pid)?.activationPolicy == .regular
    }

    private static func parentPID(_ pid: pid_t) -> pid_t? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0, size > 0 else { return nil }
        return info.kp_eproc.e_ppid
    }

    private typealias ResponsiblePIDFunction = @convention(c) (pid_t) -> pid_t

    /// `responsibility_get_pid_responsible_for_pid` is not in the public headers, so it is looked up
    /// at runtime; when it is missing the parent walk is all there is.
    private static let responsiblePIDSymbol = "responsibility_get_pid_responsible_for_pid"
    /// `RTLD_DEFAULT`, which Swift does not import (it is a C macro for `(void *)-2`).
    private static let dlsymSearchAllImages = UnsafeMutableRawPointer(bitPattern: -2)

    private static let responsiblePIDFunction: ResponsiblePIDFunction? = {
        guard let symbol = dlsym(dlsymSearchAllImages, responsiblePIDSymbol) else {
            return nil
        }
        return unsafeBitCast(symbol, to: ResponsiblePIDFunction.self)
    }()

    private static func responsiblePID(_ pid: pid_t) -> pid_t? {
        guard let function = responsiblePIDFunction else { return nil }
        let responsible = function(pid)
        return responsible > 0 ? responsible : nil
    }
}
