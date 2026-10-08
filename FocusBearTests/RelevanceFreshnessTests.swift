import XCTest
@testable import Focus_Bear

/// The AI relevance check costs an API call and then decides whether to block. A verdict that is
/// computed and silently discarded looks exactly like one that never ran, which is how this shipped
/// broken: on a real machine 8 consecutive checks returned successfully and 0 were ever applied.
final class RelevanceFreshnessTests: XCTestCase {

    func testHeadlessChromeIsExcludedEvenAfterItBecomesARegularApplication() {
        for flag in ["--headless", "--headless=new"] {
            XCTAssertFalse(ChromeProcessTabs.isUserBrowser(bundleIdentifier: "com.google.Chrome",
                bundleName: "Google Chrome.app", activationPolicy: .regular, arguments: ["chrome", flag]))
        }
        XCTAssertTrue(ChromeProcessTabs.isUserBrowser(bundleIdentifier: "com.google.Chrome",
            bundleName: "Google Chrome.app", activationPolicy: .regular,
            arguments: ["chrome", "https://example.com/?q=--headless"]))
    }

    func testProcessArgumentDecodingStopsBeforeEnvironmentAndPreservesEmptyArguments() {
        var argc: Int32 = 3
        var data = withUnsafeBytes(of: &argc) { Data($0) }
        data.append(Data("/Applications/Chrome\0\0chrome\0\0--headless=new\0TOKEN=private\0".utf8))
        XCTAssertEqual(ChromeProcessTabs.decodeProcessArguments(data), ["chrome", "", "--headless=new"])
        XCTAssertEqual(ChromeProcessTabs.decodeProcessArguments(Data()), [])
        XCTAssertEqual(ChromeProcessTabs.decodeProcessArguments(data.prefix(8)), [])
    }

    func testActiveChromeProcessPrefersForegroundAndRemembersItWhileOurPopupIsFrontmost() {
        XCTAssertEqual(ChromeActiveTabReader.selectProcess(frontPID: 202, previousPID: 101, candidates: [101, 202]), 202)
        XCTAssertEqual(ChromeActiveTabReader.selectProcess(frontPID: 999, previousPID: 202, candidates: [101, 202]), 202)
        XCTAssertEqual(ChromeActiveTabReader.selectProcess(frontPID: nil, previousPID: 101, candidates: [202]), 202)
        XCTAssertNil(ChromeActiveTabReader.selectProcess(frontPID: nil, previousPID: nil, candidates: [101, 202]))
    }

    private func chromeTabProperties(id: Int32, url: String, title: String) -> NSAppleEventDescriptor {
        let record = NSAppleEventDescriptor.record()
        record.setDescriptor(.init(int32: id), forKeyword: ChromeProcessTabs.code("ID  "))
        record.setDescriptor(.init(string: url), forKeyword: ChromeProcessTabs.code("URL "))
        record.setDescriptor(.init(string: title), forKeyword: ChromeProcessTabs.code("pnam"))
        return record
    }

    private func chromeBounds() -> NSAppleEventDescriptor {
        let rect: [Int16] = [10, 20, 310, 420]
        return rect.withUnsafeBytes {
            NSAppleEventDescriptor(descriptorType: ChromeProcessTabs.code("qdrt"), data: Data($0))!
        }
    }

    func testNativeChromeSnapshotKeepsURLTitleAndBoundsFromTheSelectedTab() throws {
        var replies: [NSAppleEventDescriptor] = [
            .init(int32: 7), chromeTabProperties(id: 42, url: "https://cliq.zoho.com.au/", title: "Cliq"),
            chromeBounds(), .init(int32: 7), .init(int32: 42)
        ]
        let result = try XCTUnwrap(ChromeActiveTabReader.snapshot { _ in
            XCTAssertFalse(replies.isEmpty)
            return replies.removeFirst()
        })
        XCTAssertEqual(result, .init(windowID: 7, url: "https://cliq.zoho.com.au/", title: "Cliq", bounds: [20, 10, 420, 310]))
        XCTAssertTrue(replies.isEmpty)
    }

    func testNativeChromeSnapshotRejectsATabSwitchDuringTheRead() throws {
        var replies: [NSAppleEventDescriptor] = [
            .init(int32: 7), chromeTabProperties(id: 42, url: "https://example.com/quote", title: "Quote"),
            chromeBounds(), .init(int32: 7), .init(int32: 43)
        ]
        XCTAssertNil(try ChromeActiveTabReader.snapshot { _ in replies.removeFirst() })
    }

    func testNativeChromeSnapshotRejectsAWindowSwitchDuringTheRead() throws {
        var replies: [NSAppleEventDescriptor] = [
            .init(int32: 7), chromeTabProperties(id: 42, url: "https://example.com/quote", title: "Quote"),
            chromeBounds(), .init(int32: 8)
        ]
        XCTAssertNil(try ChromeActiveTabReader.snapshot { _ in replies.removeFirst() })
    }

    func testNativeChromeSnapshotPreservesBlankCallWindowFallbackWithinItsProcess() throws {
        let windows = NSAppleEventDescriptor.list()
        windows.insert(.init(int32: 7), at: 1); windows.insert(.init(int32: 8), at: 2)
        var replies: [NSAppleEventDescriptor] = [
            .init(int32: 7), chromeTabProperties(id: 42, url: "about:blank", title: "Call"), chromeBounds(),
            windows, chromeTabProperties(id: 43, url: "https://meet.google.com/example", title: "Meet"), chromeBounds(),
            .init(int32: 7), .init(int32: 42), .init(int32: 43)
        ]
        XCTAssertEqual(try ChromeActiveTabReader.snapshot { _ in replies.removeFirst() }?.windowID, 8)
        XCTAssertTrue(replies.isEmpty)
    }

    func testHeadlessChromeAndClonedAppsDoNotConsumeTheUserTabLimit() {
        XCTAssertTrue(ChromeProcessTabs.isUserBrowser(bundleIdentifier: "com.google.Chrome",
            bundleName: "Google Chrome.app", activationPolicy: .regular))
        XCTAssertFalse(ChromeProcessTabs.isUserBrowser(bundleIdentifier: "com.google.Chrome",
            bundleName: "Google Chrome.app", activationPolicy: .prohibited))
        XCTAssertFalse(ChromeProcessTabs.isUserBrowser(bundleIdentifier: "com.google.Chrome",
            bundleName: "Safe FB Team Comms.app", activationPolicy: .regular))
    }

    func testChromeEveryWindowSelectorUsesAppleScriptAbsoluteOrdinalEncoding() {
        // Captured from AppleScript's `return a reference to every window`; no browser access needed.
        XCTAssertEqual(ChromeProcessTabs.allItems.descriptorType, 0x6162736f) // 'abso'
        XCTAssertEqual(ChromeProcessTabs.allItems.data, NSAppleEventDescriptor(enumCode: 0x616c6c20).data)
    }

    func testChromeSnapshotKeepsWindowsFromDifferentProcessesSeparate() {
        func list(_ values: [NSAppleEventDescriptor]) -> NSAppleEventDescriptor {
            let result = NSAppleEventDescriptor.list()
            for (index, value) in values.enumerated() { result.insert(value, at: index + 1) }
            return result
        }
        var reads: [pid_t: Int] = [:]
        let snapshot = ChromeProcessTabs.windows(processIDs: [101, 202, 101]) { pid, _ in
            reads[pid, default: 0] += 1
            // Both Chrome instances independently assigned their window ID 7.
            if reads[pid] == 1 { return list([.init(int32: 7)]) }
            return list((0..<(pid == 101 ? 2 : 4)).map { .init(string: "https://example.com/\($0)") })
        }
        XCTAssertEqual(snapshot?["101:7"]?.count, 2)
        XCTAssertEqual(snapshot?["202:7"]?.count, 4)
        XCTAssertEqual(snapshot?.values.reduce(0) { $0 + $1.count }, 6)
        XCTAssertEqual(reads, [101: 2, 202: 2], "Each process must be read once even if discovery repeats it")
    }

    func testChromeSnapshotDiscardsPartialReadOnFailure() {
        var count = 0
        let snapshot = ChromeProcessTabs.windows(processIDs: [101, 202]) { _, _ in
            count += 1
            if count == 1 { return .list() } // First process legitimately has no windows.
            throw NSError(domain: NSOSStatusErrorDomain, code: -1712)
        }
        XCTAssertNil(snapshot, "A failed process read must not become an undercounted successful snapshot")
    }

    func testTabLimitUsesObservedCountWhenSeveralTabsOpenTogether() {
        XCTAssertEqual(BrowserTabLimitDecision.evaluate(previous: 3, current: 7, otherBrowsers: 0, limit: 5), .rejectNew)
        XCTAssertEqual(BrowserTabLimitDecision.evaluate(previous: 3, current: 4, otherBrowsers: 2, limit: 5), .rejectNew)
        XCTAssertEqual(BrowserTabLimitDecision.evaluate(previous: 3, current: 5, otherBrowsers: 0, limit: 5), .allow)
    }

    func testExistingExcessWarnsWithoutGuessingWhichOldTabToDelete() {
        XCTAssertEqual(BrowserTabLimitDecision.evaluate(previous: 0, current: 8, otherBrowsers: 0, limit: 5), .warnExisting)
        XCTAssertEqual(BrowserTabLimitDecision.evaluate(previous: 8, current: 8, otherBrowsers: 0, limit: 5), .warnExisting)
        XCTAssertEqual(BrowserTabLimitDecision.evaluate(previous: 8, current: 6, otherBrowsers: 0, limit: 5), .warnExisting)
        XCTAssertEqual(BrowserTabLimitDecision.evaluate(previous: 6, current: 5, otherBrowsers: 0, limit: 5), .allow)
        XCTAssertEqual(BrowserTabLimitDecision.evaluate(previous: 8, current: 9, otherBrowsers: 0, limit: 5), .rejectNew)
    }

    private let chrome = "com.google.Chrome"
    private let focusBear = "com.App.EarnYourScreentime"

    func testChromeFrontWindowWinsOverAnEarlierBackgroundGardeningWindow() throws {
        let garden = ChromeActiveTabSnapshot(windowID: 1, url: "http://127.0.0.1:3118/",
                                            title: "Request a plant quote", bounds: [0, 0, 600, 400])
        let cloudflare = ChromeActiveTabSnapshot(windowID: 2, url: "https://dash.cloudflare.com/ai-gateway",
                                                title: "AI Gateway", bounds: [100, 100, 1100, 900])
        let selected = try XCTUnwrap(ChromeActiveTabSnapshot.select(frontWindowID: 2, windows: [garden, cloudflare]))
        XCTAssertEqual(selected, cloudflare, "URL, title and warning bounds must all describe the front window")
        let freshness = RelevanceFreshness.decide(
            keyIsLive: true, frontmostBundleID: focusBear, selfBundleID: focusBear,
            targetBundleID: chrome, liveURL: { selected.url }, liveTitle: { selected.title },
            observationMatches: matcher(url: garden.url, title: garden.title))
        XCTAssertFalse(freshness.shouldApplyVerdict, "An old gardening verdict cannot block Cloudflare")
    }

    func testChromeTabSwitchInTheSameWindowChangesTheObservedPage() {
        let switched = ChromeActiveTabSnapshot(windowID: 1, url: "https://dash.cloudflare.com/",
                                               title: "Cloudflare", bounds: [0, 0, 600, 400])
        XCTAssertEqual(ChromeActiveTabSnapshot.select(frontWindowID: 1, windows: [switched]), switched)
    }

    func testChromeUnreadableFrontWindowDoesNotFallBackToBackgroundTab() {
        let garden = ChromeActiveTabSnapshot(windowID: 1, url: "http://127.0.0.1:3118/",
                                            title: "Garden", bounds: [0, 0, 600, 400])
        XCTAssertNil(ChromeActiveTabSnapshot.select(frontWindowID: 2, windows: [garden]))
    }

    func testChromeBlankCallWindowKeepsTheBrowsingWindowFallbackConsistent() {
        let call = ChromeActiveTabSnapshot(windowID: 1, url: "about:blank", title: "Call", bounds: [0, 0, 100, 100])
        let page = ChromeActiveTabSnapshot(windowID: 2, url: "https://example.com/", title: "Page", bounds: [0, 0, 600, 400])
        XCTAssertEqual(ChromeActiveTabSnapshot.select(frontWindowID: 1, windows: [call, page]), page)
        XCTAssertEqual(ChromeActiveTabSnapshot.select(frontWindowID: 1, windows: [call]), call)
    }

    /// Matches when the re-read tab is the one we asked about.
    private func matcher(url: String, title: String) -> (String, String, String?) -> Bool {
        { liveURL, liveTitle, _ in liveURL == url && liveTitle == title }
    }

    func testAppliesTheVerdictWhenTheUserIsStillOnTheSamePage() {
        let freshness = RelevanceFreshness.decide(
            keyIsLive: true, frontmostBundleID: chrome, selfBundleID: focusBear,
            targetBundleID: chrome, liveURL: { "crazygames.com/t/tank" }, liveTitle: { "tank games" },
            observationMatches: matcher(url: "crazygames.com/t/tank", title: "tank games"))
        XCTAssertEqual(freshness, .current)
        XCTAssertTrue(freshness.shouldApplyVerdict)
    }

    /// The regression this class exists for. Focus Bear's own popup/buddy/Day Plan windows take focus
    /// while a check is in flight; that is us interrupting, not the user navigating away.
    func testFocusBearTakingFocusDoesNotDiscardTheVerdict() {
        let freshness = RelevanceFreshness.decide(
            keyIsLive: true, frontmostBundleID: focusBear, selfBundleID: focusBear,
            targetBundleID: chrome, liveURL: { "crazygames.com/t/tank" }, liveTitle: { "tank games" },
            observationMatches: matcher(url: "crazygames.com/t/tank", title: "tank games"))
        XCTAssertEqual(freshness, .current)
        XCTAssertTrue(freshness.shouldApplyVerdict, "Our own window stealing focus must not drop a block decision")
    }

    /// A slow or failed AppleScript read proves nothing. Treating it as "the user moved on" threw
    /// away correct verdicts whenever the browser was briefly unresponsive.
    func testAFailedBrowserReadStillAppliesTheVerdict() {
        let freshness = RelevanceFreshness.decide(
            keyIsLive: true, frontmostBundleID: chrome, selfBundleID: focusBear,
            targetBundleID: chrome, liveURL: { nil }, liveTitle: { nil },
            observationMatches: { _, _, _ in XCTFail("must not be consulted when the read failed"); return false })
        XCTAssertEqual(freshness, .unverifiable)
        XCTAssertTrue(freshness.shouldApplyVerdict)
    }

    func testAPartialBrowserReadIsAlsoUnverifiable() {
        let freshness = RelevanceFreshness.decide(
            keyIsLive: true, frontmostBundleID: chrome, selfBundleID: focusBear,
            targetBundleID: chrome, liveURL: { "crazygames.com/t/tank" }, liveTitle: { nil },
            observationMatches: { _, _, _ in XCTFail("must not be consulted when the read failed"); return false })
        XCTAssertEqual(freshness, .unverifiable)
    }

    /// Switching to a genuinely different app must still discard the verdict — the guard has a real
    /// job, and loosening it must not turn it off.
    func testSwitchingToAnotherAppDiscardsTheVerdict() {
        let freshness = RelevanceFreshness.decide(
            keyIsLive: true, frontmostBundleID: "com.apple.mail", selfBundleID: focusBear,
            targetBundleID: chrome, liveURL: { "crazygames.com/t/tank" }, liveTitle: { "tank games" },
            observationMatches: matcher(url: "crazygames.com/t/tank", title: "tank games"))
        XCTAssertEqual(freshness, .userLeft(frontmost: "com.apple.mail"))
        XCTAssertFalse(freshness.shouldApplyVerdict)
    }

    func testNavigatingToADifferentPageDiscardsTheVerdict() {
        let freshness = RelevanceFreshness.decide(
            keyIsLive: true, frontmostBundleID: chrome, selfBundleID: focusBear,
            targetBundleID: chrome, liveURL: { "example.com" }, liveTitle: { "example" },
            observationMatches: matcher(url: "crazygames.com/t/tank", title: "tank games"))
        XCTAssertEqual(freshness, .superseded)
        XCTAssertFalse(freshness.shouldApplyVerdict)
    }

    func testASupersededCheckIsDiscarded() {
        let freshness = RelevanceFreshness.decide(
            keyIsLive: false, frontmostBundleID: chrome, selfBundleID: focusBear,
            targetBundleID: chrome, liveURL: { "crazygames.com/t/tank" }, liveTitle: { "tank games" },
            observationMatches: matcher(url: "crazygames.com/t/tank", title: "tank games"))
        XCTAssertEqual(freshness, .superseded)
    }

    /// A nil self bundle id must not make an unrelated frontmost app look like us.
    func testUnknownSelfBundleIdentifierDoesNotExcuseAnotherApp() {
        let freshness = RelevanceFreshness.decide(
            keyIsLive: true, frontmostBundleID: nil, selfBundleID: nil,
            targetBundleID: chrome, liveURL: { "crazygames.com/t/tank" }, liveTitle: { "tank games" },
            observationMatches: matcher(url: "crazygames.com/t/tank", title: "tank games"))
        XCTAssertEqual(freshness, .userLeft(frontmost: "unknown"))
    }

    /// Each browser read is an AppleScript round-trip capped at 1.2s on the main thread. Evaluating
    /// them before the cheap checks froze the UI in a real session, so laziness is a correctness
    /// property here, not a micro-optimisation.
    func testBrowserReadsAreNotPerformedWhenTheUserHasAlreadyLeft() {
        var reads = 0
        _ = RelevanceFreshness.decide(
            keyIsLive: true, frontmostBundleID: "com.apple.mail", selfBundleID: focusBear,
            targetBundleID: chrome,
            liveURL: { reads += 1; return "crazygames.com/t/tank" },
            liveTitle: { reads += 1; return "tank games" },
            observationMatches: { _, _, _ in true })
        XCTAssertEqual(reads, 0, "Must not pay for a browser read when the verdict is already discarded")
    }

    func testBrowserReadsAreNotPerformedForASupersededCheck() {
        var reads = 0
        _ = RelevanceFreshness.decide(
            keyIsLive: false, frontmostBundleID: chrome, selfBundleID: focusBear,
            targetBundleID: chrome,
            liveURL: { reads += 1; return "crazygames.com/t/tank" },
            liveTitle: { reads += 1; return "tank games" },
            observationMatches: { _, _, _ in true })
        XCTAssertEqual(reads, 0)
    }

    // MARK: - The reads are memoised because each one is a blocking AppleScript call

    func testAMemoisedReadRunsOnceHoweverOftenItIsAsked() {
        // The freshness decision reads the tab's URL and title, and the log line explaining a
        // discarded verdict read both AGAIN — four AppleScript round-trips, 1.2s cap each, on the
        // main thread while the user waits. This is what collapses them to two.
        var calls = 0
        let read = memoisedRead { () -> String? in
            calls += 1
            return "https://example.com"
        }
        XCTAssertEqual(read(), "https://example.com")
        XCTAssertEqual(read(), "https://example.com")
        XCTAssertEqual(read(), "https://example.com")
        XCTAssertEqual(calls, 1)
    }

    func testAMemoisedReadDoesNotRunUntilItIsAsked() {
        // Laziness is the other half: an unread tab must cost nothing, because these only become
        // worth paying for once the cheap frontmost check has already passed.
        var calls = 0
        _ = memoisedRead { () -> String? in
            calls += 1
            return "unused"
        }
        XCTAssertEqual(calls, 0)
    }

    func testAMemoisedReadRemembersAFailureRatherThanRetryingIt() {
        // A browser read that failed once will not succeed a millisecond later, and retrying it is
        // another blocking script. nil has to be a remembered answer, not an empty cache.
        var calls = 0
        let read = memoisedRead { () -> String? in
            calls += 1
            return nil
        }
        XCTAssertNil(read())
        XCTAssertNil(read())
        XCTAssertEqual(calls, 1)
    }
}
