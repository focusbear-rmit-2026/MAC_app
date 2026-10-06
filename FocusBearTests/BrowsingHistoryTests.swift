import XCTest
@testable import Focus_Bear

/// The 30-minute browsing history: sealed at rest, pruned to the window, buffered in memory until the
/// store opens, and exported decrypted only into a problem report.
final class BrowsingHistoryTests: XCTestCase {
    private typealias F = SecureStoreFixture
    private static let registry = SensitiveKeyRegistry(
        keys: F.registry.keys,
        files: F.registry.files + [SensitiveFile(fileName: kBrowsingHistoryFileName, durability: .serverBacked)])
    private static let start = Date(timeIntervalSince1970: 1_790_000_000)
    private static let minute: TimeInterval = 60
    private static let privateURL = "https://docs.example.org/d/quarterly-restructure?usp=sharing"
    private static let privateTitle = "Quarterly restructure — confidential"
    private static let browserBundle = "com.google.Chrome"

    private var fixture: SecureStoreFixture!
    private var now = BrowsingHistoryTests.start

    override func setUp() {
        super.setUp()
        fixture = SecureStoreFixture()
        now = Self.start
    }

    override func tearDown() {
        fixture.destroy()
        fixture = nil
        super.tearDown()
    }

    private var plaintextURL: URL { fixture.plaintextURL(kBrowsingHistoryFileName) }

    private func makeStore(available: Bool = true, encrypting: Bool = true) -> SecureStore {
        fixture.keys.isAvailable = available
        let store = fixture.makeStore(isEncryptionEnabled: encrypting, registry: Self.registry)
        store.activate(accountId: F.accountA)
        return store
    }

    private func makeHistory(_ store: SecureStore) -> (BrowsingHistory, SecureFileStore) {
        let files = SecureFileStore(store: store)
        let history = BrowsingHistory(files: files, fileURL: plaintextURL, now: { [unowned self] in self.now })
        history.waitUntilIdle()
        return (history, files)
    }

    private func recordPrivatePage(_ history: BrowsingHistory, url: String = privateURL) {
        history.record(.blocked, url: url, title: Self.privateTitle, app: Self.browserBundle,
                       reason: BrowsingReason.alwaysBlocked, focusMode: "Deep work", aiScore: 0.12, aiReason: "Off task")
        history.waitUntilIdle()
    }

    private func advance(minutes: Double) {
        now = now.addingTimeInterval(minutes * Self.minute)
    }

    // MARK: Retention

    func testKeepsOnlyTheLastThirtyMinutesInMemoryAndOnDisk() throws {
        let (history, files) = makeHistory(makeStore())
        recordPrivatePage(history, url: "https://old.example.org/first")
        advance(minutes: 20)
        recordPrivatePage(history, url: "https://new.example.org/second")
        advance(minutes: 11)

        history.pruneNow()
        XCTAssertEqual(history.currentEntries().map(\.url), ["https://new.example.org/second"])

        advance(minutes: BrowsingHistory.compactionSlack / Self.minute)
        history.pruneNow()
        let sealed = try files.readText(plaintextURL)
        XCTAssertFalse(sealed.contains("old.example.org"), "the sealed file is rewritten without the expired entry")
        XCTAssertTrue(sealed.contains("new.example.org"))

        advance(minutes: 30)
        history.pruneNow()
        XCTAssertTrue(history.currentEntries().isEmpty)
        XCTAssertFalse(files.exists(plaintextURL), "an empty window leaves no file behind")
    }

    func testSurvivesARestartWithinTheWindowButNotBeyondIt() {
        let store = makeStore()
        do {
            let (history, _) = makeHistory(store)
            recordPrivatePage(history)
        }
        advance(minutes: 10)
        let (restarted, _) = makeHistory(store)
        XCTAssertEqual(restarted.currentEntries().map(\.url), [Self.privateURL])

        advance(minutes: 25)
        let (muchLater, _) = makeHistory(store)
        XCTAssertTrue(muchLater.currentEntries().isEmpty)
    }

    func testRepeatsOfTheSameEventAreRecordedAgainOnlyAfterAMinute() {
        let (history, _) = makeHistory(makeStore())
        recordPrivatePage(history)
        advance(minutes: 0.5)
        recordPrivatePage(history)
        XCTAssertEqual(history.currentEntries().count, 1)
        advance(minutes: 1)
        recordPrivatePage(history)
        XCTAssertEqual(history.currentEntries().count, 2, "a long stay still shows once its first entry ages out")
    }

    // MARK: Encryption at rest

    func testIsSealedOnDiskWithNoPlaintextBytes() throws {
        let (history, files) = makeHistory(makeStore())
        recordPrivatePage(history)

        XCTAssertTrue(files.exists(plaintextURL))
        XCTAssertFalse(FileManager.default.fileExists(atPath: plaintextURL.path), "nothing at the plaintext path")
        for secret in [Self.privateURL, "quarterly-restructure", Self.privateTitle, "docs.example.org", "Off task"] {
            XCTAssertFalse(fixture.diskContains(secret), "\(secret) is on disk in plaintext")
        }
        XCTAssertTrue(try files.readText(plaintextURL).contains("quarterly-restructure"), "the key reads it back")
    }

    func testBuffersInMemoryUntilTheKeyIsAvailableThenSealsWhatWasBuffered() throws {
        let store = makeStore(available: false)
        let (history, files) = makeHistory(store)
        recordPrivatePage(history)

        XCTAssertEqual(history.currentEntries().map(\.url), [Self.privateURL])
        XCTAssertTrue(fixture.allBytesOnDisk().isEmpty, "nothing is written while the key is unavailable")
        XCTAssertFalse(FileManager.default.fileExists(atPath: plaintextURL.path))

        fixture.keys.isAvailable = true
        store.retryKeyIfNeeded()
        history.pruneNow()

        XCTAssertTrue(try files.readText(plaintextURL).contains("quarterly-restructure"))
        XCTAssertFalse(fixture.diskContains("quarterly-restructure"))
    }

    func testABuildThatNeverEncryptsKeepsTheHistoryInMemoryOnly() {
        let (history, _) = makeHistory(makeStore(encrypting: false))
        recordPrivatePage(history)
        history.pruneNow()

        XCTAssertEqual(history.currentEntries().count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: plaintextURL.path), "never a plaintext fallback")
        XCTAssertTrue(fixture.allBytesOnDisk().isEmpty)
    }

    func testSignOutDeletesTheSealedHistory() {
        let store = makeStore()
        let (history, files) = makeHistory(store)
        recordPrivatePage(history)

        store.signOut()

        store.activate(accountId: F.accountA)
        XCTAssertFalse(files.exists(plaintextURL), "a disposable cache goes with the session")
    }

    // MARK: Export

    func testExportListsTheWindowWithFullDetailAndTheSiteTheLogShows() {
        let (history, _) = makeHistory(makeStore())
        recordPrivatePage(history, url: "https://expired.example.org/x")
        advance(minutes: 31)
        recordPrivatePage(history)

        let text = history.exportText()

        XCTAssertTrue(text.contains(BrowsingHistory.exportedAtLabel), text)
        XCTAssertFalse(text.contains("expired.example.org"), "only the last 30 minutes")
        for expected in ["blocked", "url=\"\(Self.privateURL)\"", "title=\"\(Self.privateTitle)\"",
                         "app=\"\(Self.browserBundle)\"", "reason=\"\(BrowsingReason.alwaysBlocked)\"",
                         "focus-mode=\"Deep work\"", "ai-score=0.12", "site=\(LogPrivacy.site(Self.privateURL))"] {
            XCTAssertTrue(text.contains(expected), "\(expected) missing from \(text)")
        }
    }

    func testExportedLinesStayOneLineWhateverATitleHolds() {
        let entry = BrowsingHistoryEntry(time: Self.start, decision: .seen, source: "test", url: nil,
                                         title: "two\nlines \"quoted\"", app: nil, reason: nil, focusMode: nil,
                                         aiScore: nil, aiReason: nil)
        let line = BrowsingHistory.exportLine(entry)
        XCTAssertFalse(line.contains("\n"))
        XCTAssertTrue(line.contains(#"title="two\nlines \"quoted\"""#), line)
    }
}

/// The main log names the site of every page and describes window titles; the full values are only in
/// the browsing history.
final class BrowsingLogPrivacyTests: XCTestCase {
    private static let title = "Quarterly restructure — confidential"

    func testSiteKeepsTheDomainAndAStableReferenceAndNothingElse() {
        let site = LogPrivacy.site("https://docs.example.org/d/quarterly-restructure?usp=sharing#heading")
        XCTAssertTrue(site.hasPrefix("<site:docs.example.org:"), site)
        XCTAssertFalse(site.contains("quarterly"))
        XCTAssertEqual(site, LogPrivacy.site("https://docs.example.org/d/quarterly-restructure?usp=sharing#heading"))
        XCTAssertNotEqual(site, LogPrivacy.site("https://docs.example.org/d/other"))
        XCTAssertTrue(LogPrivacy.site("youtube.com/watch?v=abc").hasPrefix("<site:youtube.com:"))
        XCTAssertTrue(LogPrivacy.site("localhost:3000/admin").hasPrefix("<site:localhost:"))
        XCTAssertTrue(LogPrivacy.site("file:///Users/me/Secret plan.pdf").hasPrefix("<site:file:"))
        XCTAssertTrue(LogPrivacy.site("Visual Studio Code").hasPrefix("<text:"), "not a URL, so described as text")
        XCTAssertEqual(LogPrivacy.site(site), site, "describing twice changes nothing")
        XCTAssertEqual(LogPrivacy.site(nil), LogPrivacy.noValue)
    }

    func testOlderLogLinesLoseTheirPagesAndTitlesButKeepTheDomain() {
        let lines = [
            "2026-10-05 09:00:00 - focusTryToBlockUnwantedUrl:- youtube.com/watch?v=secretvideo",
            "2026-10-05 09:00:01 - checked chatGPTIsURLSafe:- docs.example.org/d/quarterly, dProbability:0.2",
            "2026-10-05 09:00:02 - relevance verdict discarded for docs.example.org/d/quarterly: superseded keyLive=true"
                + " urlMatch=false liveURL=https://docs.example.org/d/quarterly-v2 keyTarget=https://docs.example.org/d/quarterly"
                + " titleMatch=false liveTitle=\(Self.title) v2 keyTitle=\(Self.title)",
            "2026-10-05 09:00:03 - func:- showAiBlockBuddyWindow item=https://reddit.com/r/secrets isApp=false",
            "2026-10-05 09:00:04 - checkAppFromAi: iTerm2 window title 'ssh prod — Jeremy's box' added to AI context",
            "2026-10-05 09:00:05 - claude chat title: '\(Self.title)' frame={{1, 2}, {3, 4}} of 9 texts",
            "2026-10-05 09:00:06 - func:- showSetIntentionBlockedUrlsWindow :- currentApp: Safari, url: news.example.com/story/1",
            "2026-10-05 09:00:07 - relevance verdict discarded for file:///Users/me/Secret%20plan.pdf: userLeft(frontmost: \"com.apple.finder\")",
            "2026-10-05 09:00:08 - ai-block reprompt scheduled for url:twitter.com/someone/status/42 in 5m",
            "2026-10-05 09:00:09 - aiBlockBuddy: not re-showing url:twitter.com/someone/status/43 — another app took the front",
        ].joined(separator: "\n")
        let scrubbed = LogContentScrubber.scrub(lines)
        for leaked in ["secretvideo", "quarterly", "Quarterly", "r/secrets", "ssh prod", "story/1", "Secret", "someone"] {
            XCTAssertFalse(scrubbed.contains(leaked), "\(leaked) survived in \(scrubbed)")
        }
        for kept in ["<site:youtube.com:", "<site:docs.example.org:", "dProbability:0.2", ": superseded keyLive=true",
                     "<site:reddit.com:", "isApp=false", "iTerm2 window title <text:", "added to AI context",
                     "claude chat title: <text:", "frame={{1, 2}, {3, 4}}", "currentApp: Safari, url: <site:news.example.com:",
                     "<site:file:", "userLeft(frontmost: \"com.apple.finder\")",
                     "reprompt scheduled for url:<site:twitter.com:", " in 5m", "not re-showing url:<site:twitter.com:"] {
            XCTAssertTrue(scrubbed.contains(kept), "\(kept) missing from \(scrubbed)")
        }
        XCTAssertEqual(LogContentScrubber.scrub(scrubbed), scrubbed, "scrubbing twice changes nothing")
    }

    func testFocusBearsOwnRequestsAndAppNamesStayReadable() {
        let lines = [
            "api call getConfigFile https://focus-bear.github.io/assets/config.json",
            "api call getSettings https://api.focusbear.io/user/settings",
            "func:- showAiBlockBuddyWindow item=Slack isApp=true",
            "relevance verdict discarded for <site:example.org:1a2b>: superseded liveURL=nil keyTarget=<site:example.org:1a2b>"
                + " titleMatch=false liveTitle=nil keyTitle=<text:9f3c:len12>",
        ]
        for line in lines {
            XCTAssertEqual(LogContentScrubber.scrubEntry(line), line)
        }
    }

    func testTheLegacyRewriteRunsAgainForThisChange() {
        XCTAssertGreaterThanOrEqual(LegacyLogScrubber.version, 3, "older logs still hold full URLs and titles")
    }
}
