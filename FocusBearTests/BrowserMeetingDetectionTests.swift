//
//  BrowserMeetingDetectionTests.swift
//  Focus BearTests
//
//  The browser-meeting rules (BrowserMeetingDetection.swift): which tab URLs are a meeting, how a
//  mic-capturing helper process maps to its browser, and when an open meeting-platform tab counts.
//
//  Anchored on report 2026-10-06_13-30-40: a Teams web meeting in Chrome on
//  teams.microsoft.com/light-meetings/launch, with the mic owner logged as "Unknown[Unknown]" and
//  "no meeting app or browser-meeting matched" every five seconds — so the talking clock spoke.
//

@testable import Focus_Bear
import XCTest

final class BrowserMeetingDetectionTests: XCTestCase {

    // MARK: - URL rules

    /// The URLs the report's Chrome tab actually went through while joining the Teams meeting.
    func testTeamsJoinUrlsFromTheReportAreLiveMeetings() {
        let urls = [
            "https://teams.microsoft.com/meet/493243024120045?p=abc",
            "https://teams.microsoft.com/v2/?meetingjoin=true#/meet/493243024120045?p=abc&anon=true",
            "https://teams.microsoft.com/light-meetings/launch?p=abc&anon=true&agent=web",
        ]
        for url in urls {
            XCTAssertTrue(BrowserMeetingUrlRules.isLiveMeeting(url), url)
        }
    }

    func testTeamsClassicJoinLinksAreLiveMeetings() {
        XCTAssertTrue(BrowserMeetingUrlRules.isLiveMeeting("https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc%40thread.v2/0"))
        XCTAssertTrue(BrowserMeetingUrlRules.isLiveMeeting("https://teams.live.com/meet/9381234567890?p=xyz"))
    }

    func testNewAndGovernmentTeamsDomainsAreRecognised() {
        XCTAssertTrue(BrowserMeetingUrlRules.isLiveMeeting("https://teams.cloud.microsoft/v2/?meetingjoin=true#/meet/123"))
        XCTAssertTrue(BrowserMeetingUrlRules.isLiveMeeting("https://teams.cloud.microsoft/light-meetings/launch?p=abc"))
        XCTAssertTrue(BrowserMeetingUrlRules.isLiveMeeting("https://gov.teams.microsoft.us/l/meetup-join/19%3ameeting_abc"))
        XCTAssertTrue(BrowserMeetingUrlRules.isLiveMeeting("https://dod.teams.microsoft.us/meet/123"))
        XCTAssertTrue(BrowserMeetingUrlRules.isMeetingPlatform("https://teams.cloud.microsoft/"))
    }

    func testTeamsHomeAndLauncherPagesAreNotLiveMeetings() {
        XCTAssertFalse(BrowserMeetingUrlRules.isLiveMeeting("https://teams.microsoft.com/v2/"))
        XCTAssertFalse(BrowserMeetingUrlRules.isLiveMeeting("https://teams.cloud.microsoft/v2/"))
        // The "open in the app?" launcher precedes joining; its meeting path is percent-encoded.
        XCTAssertFalse(BrowserMeetingUrlRules.isLiveMeeting("https://teams.microsoft.com/dl/launcher/launcher.html?url=%2F_%23%2Fmeet%2F493243024120045&type=meet"))
        XCTAssertTrue(BrowserMeetingUrlRules.isMeetingPlatform("https://teams.microsoft.com/v2/"))
    }

    func testLookalikeHostsAreNotMeetingPlatforms() {
        XCTAssertFalse(BrowserMeetingUrlRules.isMeetingPlatform("https://notteams.microsoft.com/meet/1"))
        XCTAssertFalse(BrowserMeetingUrlRules.isMeetingPlatform("https://teams.microsoft.com.evil.example/meet/1"))
        XCTAssertFalse(BrowserMeetingUrlRules.isMeetingPlatform("https://docs.google.com/document/d/1/edit"))
        XCTAssertFalse(BrowserMeetingUrlRules.isMeetingPlatform("not a url"))
    }

    func testGoogleMeetAndZoomKeepTheirExistingRules() {
        XCTAssertTrue(BrowserMeetingUrlRules.isLiveMeeting("https://meet.google.com/abc-defg-hij"))
        XCTAssertFalse(BrowserMeetingUrlRules.isLiveMeeting("https://meet.google.com/"))
        XCTAssertTrue(BrowserMeetingUrlRules.isLiveMeeting("https://app.zoom.us/wc/123456789/join"))
        XCTAssertTrue(BrowserMeetingUrlRules.isLiveMeeting("https://acme.zoom.us/j/123456789"))
        XCTAssertFalse(BrowserMeetingUrlRules.isLiveMeeting("https://zoom.us/profile"))
        XCTAssertFalse(BrowserMeetingUrlRules.isLiveMeeting("https://meet.zoho.com/abc"))
    }

    // MARK: - Tab evidence

    func testEvidenceFindsALiveRoomInAnyTab() {
        let evidence = BrowserMeetingDecision.TabEvidence.from(
            tabUrls: ["https://docs.google.com/document/d/1/edit",
                      "https://teams.microsoft.com/light-meetings/launch?p=abc"],
            isAllowedMeetingUrl: { _ in false })
        XCTAssertTrue(evidence.hasLiveMeetingTab)
    }

    /// Same report, 16:30 follow-up: a Google Meet call. The scan now covers every window, so the room
    /// only has to be somewhere in the browser's tab list, not in the front tab.
    func testEvidenceFindsAGoogleMeetRoomBehindOtherTabs() {
        let evidence = BrowserMeetingDecision.TabEvidence.from(
            tabUrls: ["https://claude.ai/new",
                      "https://mail.google.com/mail/u/0/#inbox",
                      "https://meet.google.com/aee-ryqs-bxi?authuser=0"],
            isAllowedMeetingUrl: { _ in false })
        XCTAssertTrue(evidence.hasLiveMeetingTab)
        XCTAssertEqual(BrowserMeetingDecision.reason(evidence: evidence, micOwner: .none), .liveMeetingTab)
    }

    func testTheGoogleMeetHomePageCountsOnlyWithABrowserMic() {
        for homeUrl in ["https://meet.google.com/", "https://meet.google.com/landing?authuser=0"] {
            XCTAssertFalse(BrowserMeetingUrlRules.isLiveMeeting(homeUrl), homeUrl)
            let home = BrowserMeetingDecision.TabEvidence.from(tabUrls: [homeUrl], isAllowedMeetingUrl: { _ in false })
            XCTAssertEqual(BrowserMeetingDecision.reason(evidence: home, micOwner: .browser), .meetingPlatformTabWithBrowserMic, homeUrl)
            // Keep-awake alone (a video playing) with Meet's home page open is not a call.
            XCTAssertNil(BrowserMeetingDecision.reason(evidence: home, micOwner: .none), homeUrl)
        }
    }

    func testEvidenceCountsTheMeetingsFocusAllowedUrls() {
        let evidence = BrowserMeetingDecision.TabEvidence.from(
            tabUrls: ["https://calls.example.com/room/1"],
            isAllowedMeetingUrl: { $0.hasPrefix("https://calls.example.com/") })
        XCTAssertTrue(evidence.hasLiveMeetingTab)
    }

    func testEvidenceSeparatesAPlatformHomePageFromARoom() {
        let evidence = BrowserMeetingDecision.TabEvidence.from(
            tabUrls: ["https://teams.microsoft.com/v2/", "https://discord.com/channels/@me/1"],
            isAllowedMeetingUrl: { _ in false })
        XCTAssertEqual(evidence, .init(hasLiveMeetingTab: false, hasMeetingPlatformTab: true))
    }

    // MARK: - Decision table

    private let liveRoom = BrowserMeetingDecision.TabEvidence(hasLiveMeetingTab: true, hasMeetingPlatformTab: true)
    private let platformOnly = BrowserMeetingDecision.TabEvidence(hasLiveMeetingTab: false, hasMeetingPlatformTab: true)
    private let noMeetingTabs = BrowserMeetingDecision.TabEvidence()

    func testALiveRoomCountsWhoeverHoldsTheMic() {
        for owner in [MicOwnerKind.none, .unknown, .browser, .otherApp] {
            XCTAssertEqual(BrowserMeetingDecision.reason(evidence: liveRoom, micOwner: owner), .liveMeetingTab, owner.rawValue)
        }
    }

    func testAPlatformTabCountsOnlyWithABrowserOrUnnamedMicOwner() {
        XCTAssertEqual(BrowserMeetingDecision.reason(evidence: platformOnly, micOwner: .browser), .meetingPlatformTabWithBrowserMic)
        XCTAssertEqual(BrowserMeetingDecision.reason(evidence: platformOnly, micOwner: .unknown), .meetingPlatformTabWithBrowserMic)
        XCTAssertNil(BrowserMeetingDecision.reason(evidence: platformOnly, micOwner: .otherApp))
        // Keep-awake or camera alone, with an idle Teams tab, is not a call.
        XCTAssertNil(BrowserMeetingDecision.reason(evidence: platformOnly, micOwner: .none))
    }

    func testNoMeetingTabsNeverCount() {
        for owner in [MicOwnerKind.none, .unknown, .browser, .otherApp] {
            XCTAssertNil(BrowserMeetingDecision.reason(evidence: noMeetingTabs, micOwner: owner), owner.rawValue)
        }
    }

    // MARK: - Mic owner classification

    private func app(_ name: String, _ bundleID: String) -> MicApp {
        MicApp(pid: 100, appName: name, bundleID: bundleID)
    }

    func testTheReportsUnknownOwnerIsUnknown() {
        let owners = [app(MicApp.unknownName, MicApp.unknownName)]
        XCTAssertEqual(MicOwnerKind.classify(isMicOn: true, owners: owners), .unknown)
    }

    func testAnUnresolvedChromeHelperIsStillABrowser() {
        let owners = [app(MicApp.unknownName, "com.google.Chrome.helper")]
        XCTAssertEqual(MicOwnerKind.classify(isMicOn: true, owners: owners), .browser)
    }

    func testResolvedBrowsersAndOtherApps() {
        XCTAssertEqual(MicOwnerKind.classify(isMicOn: true, owners: [app("Google Chrome", "com.google.Chrome")]), .browser)
        XCTAssertEqual(MicOwnerKind.classify(isMicOn: true, owners: [app("Microsoft Edge", "com.microsoft.edgemac")]), .browser)
        XCTAssertEqual(MicOwnerKind.classify(isMicOn: true, owners: [app("Superwhisper", "com.superduper.superwhisper")]), .otherApp)
    }

    func testAnUnresolvedNonBrowserHelperIsUnknown() {
        let owners = [app(MicApp.unknownName, "com.apple.WebKit.GPU")]
        XCTAssertEqual(MicOwnerKind.classify(isMicOn: true, owners: owners), .unknown)
    }

    func testMicOnWithNoAttributedProcessIsUnknownAndMicOffIsNone() {
        XCTAssertEqual(MicOwnerKind.classify(isMicOn: true, owners: []), .unknown)
        XCTAssertEqual(MicOwnerKind.classify(isMicOn: false, owners: [app("Google Chrome", "com.google.Chrome")]), .none)
    }

    // MARK: - Helper → owning app

    func testHelperBundleIdsMapToTheirBrowser() {
        XCTAssertEqual(MicOwnerResolver.parentBundleIdentifier(ofHelper: "com.google.Chrome.helper"), "com.google.Chrome")
        XCTAssertEqual(MicOwnerResolver.parentBundleIdentifier(ofHelper: "com.google.Chrome.helper.renderer"), "com.google.Chrome")
        XCTAssertEqual(MicOwnerResolver.parentBundleIdentifier(ofHelper: "com.microsoft.edgemac.helper.GPU"), "com.microsoft.edgemac")
        XCTAssertEqual(MicOwnerResolver.parentBundleIdentifier(ofHelper: "com.brave.Browser.helper"), "com.brave.Browser")
        XCTAssertNil(MicOwnerResolver.parentBundleIdentifier(ofHelper: "com.apple.WebKit.GPU"))
        XCTAssertNil(MicOwnerResolver.parentBundleIdentifier(ofHelper: "helper"))
    }

    /// A fake process table: pid → parent, pid → responsible, and the pids that are regular apps.
    private struct ProcessTable {
        var parents: [pid_t: pid_t] = [:]
        var responsible: [pid_t: pid_t] = [:]
        var regularApps: Set<pid_t> = []

        func owner(of pid: pid_t) -> pid_t? {
            MicOwnerResolver.owningApplicationPID(of: pid,
                                                  parentPID: { parents[$0] },
                                                  responsiblePID: { responsible[$0] },
                                                  isRegularApplication: { regularApps.contains($0) })
        }
    }

    func testARegularAppOwnsItsOwnCapture() {
        let table = ProcessTable(regularApps: [500])
        XCTAssertEqual(table.owner(of: 500), 500)
    }

    func testAChromeHelperResolvesToChromeThroughItsParent() {
        // Google Chrome (500) → Google Chrome Helper audio service (510).
        let table = ProcessTable(parents: [510: 500, 500: 1], regularApps: [500])
        XCTAssertEqual(table.owner(of: 510), 500)
    }

    func testASafariWebKitServiceResolvesToSafariThroughResponsibility() {
        // com.apple.WebKit.GPU (620) is launchd's child; Safari (600) is responsible for it.
        let table = ProcessTable(parents: [620: 1], responsible: [620: 600], regularApps: [600])
        XCTAssertEqual(table.owner(of: 620), 600)
    }

    func testTheParentWalkPrefersTheBrowserOverAResponsibleTerminal() {
        // Chrome launched from a terminal: the terminal (700) is responsible, Chrome (500) is the parent.
        let table = ProcessTable(parents: [510: 500, 500: 700], responsible: [510: 700, 500: 700], regularApps: [500, 700])
        XCTAssertEqual(table.owner(of: 510), 500)
    }

    func testAnOrphanedDaemonHasNoOwner() {
        let table = ProcessTable(parents: [800: 1])
        XCTAssertNil(table.owner(of: 800))
    }

    func testAParentLoopStopsAtTheHopLimit() {
        let table = ProcessTable(parents: [900: 901, 901: 900])
        XCTAssertNil(table.owner(of: 900))
    }
}
