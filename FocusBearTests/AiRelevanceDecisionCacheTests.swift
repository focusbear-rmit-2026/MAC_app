import XCTest
@testable import Focus_Bear

final class AiRelevanceDecisionCacheTests: XCTestCase {
    private func key(_ target: String = "https://example.com/a", taskID: String = "task-1",
                     intention: String = "Process emails", title: String = "Inbox",
                     account: String = "account-1", policy: Int = 1, model: String = "v1") -> AiRelevanceDecisionKey {
        let context = [account, taskID, intention, String(policy), model]
        return AiRelevanceDecisionKey(context: try! JSONSerialization.data(withJSONObject: context),
                                      kind: "url", target: target, content: [title])
    }

    func testReturningAToBToAReusesBothAllowedAndBlockedDecisions() {
        for probability in [0.1, 0.95] {
            let cache = AiRelevanceDecisionCache<Double>()
            var requests = 0
            var responses: [Double] = []
            for target in ["A", "B", "A"] {
                cache.resolve(for: key(target), isCurrent: { true }, shouldCache: { _ in true }, load: { done in
                    requests += 1
                    done(probability)
                }, completion: { responses.append($0) })
            }
            XCTAssertEqual(requests, 2)
            XCTAssertEqual(responses, [probability, probability, probability])
        }
    }

    func testChangedTaskOrIntentionMustReevaluate() {
        let cache = AiRelevanceDecisionCache<Double>()
        cache.store(0.9, for: key())
        XCTAssertNil(cache.value(for: key(taskID: "task-2")))
        XCTAssertNil(cache.value(for: key(intention: "Write code")))
    }

    func testSameTitleTasksRemainDistinctAndUnrelatedQueueEditsDoNotInvalidate() {
        let first = "[{\"id\":\"1\",\"title\":\"Email\",\"isPlaying\":true}]"
        let second = "[{\"id\":\"2\",\"title\":\"Email\",\"isPlaying\":true}]"
        let unrelated = "[{\"id\":\"1\",\"title\":\"Email\",\"isPlaying\":true},{\"id\":\"3\",\"title\":\"Later\"}]"
        XCTAssertNotEqual(AiRelevanceDecisionKey.activeTaskIdentity(in: first, popupTask: ""),
                          AiRelevanceDecisionKey.activeTaskIdentity(in: second, popupTask: ""))
        XCTAssertEqual(AiRelevanceDecisionKey.activeTaskIdentity(in: first, popupTask: ""),
                       AiRelevanceDecisionKey.activeTaskIdentity(in: unrelated, popupTask: ""))
    }

    func testAccountPolicyModelAndContentChangesCannotReuseDecision() {
        let cache = AiRelevanceDecisionCache<Double>()
        cache.store(0.95, for: key())
        for changed in [key(account: "account-2"), key(policy: 2), key(model: "v2"), key(title: "Games"),
                        key("https://example.com/b"), key("https://example.com/a?video=2"),
                        key("https://example.com/a#different-document")] {
            XCTAssertNil(cache.value(for: changed))
        }
    }

    func testSameAppWithDifferentWindowContentMustReevaluate() {
        let cache = AiRelevanceDecisionCache<Double>()
        let terminal = AiRelevanceDecisionKey(context: key().context, kind: "app", target: "com.googlecode.iterm2", content: ["Project A"])
        let otherWindow = AiRelevanceDecisionKey(context: terminal.context, kind: terminal.kind, target: terminal.target, content: ["Project B"])
        cache.store(0.95, for: terminal)
        XCTAssertNil(cache.value(for: otherWindow))
    }

    func testLateResponseAfterNavigationOrTaskChangeIsNotStoredOrApplied() {
        let cache = AiRelevanceDecisionCache<Double>()
        var current = key()
        let requested = current
        var finish: ((Double) -> Void)?
        var applied = false
        cache.resolve(for: requested, isCurrent: { current == requested }, shouldCache: { _ in true },
                      load: { finish = $0 }, completion: { _ in applied = true })
        current = key(taskID: "task-2")
        finish?(0.95)
        XCTAssertFalse(applied)
        XCTAssertNil(cache.value(for: requested))
    }

    func testCachedResponseCannotReopenPopupAfterNavigation() {
        let cache = AiRelevanceDecisionCache<Double>()
        cache.store(0.1, for: key())
        var applied = false
        cache.resolve(for: key(), isCurrent: { false }, shouldCache: { _ in true },
                      load: { _ in XCTFail("Cached result should not fetch") }, completion: { _ in applied = true })
        XCTAssertFalse(applied)
    }

    func testSuccessfulHTTPFallbackIsNotAReusableClassifierDecision() {
        XCTAssertFalse(AiRelevanceDecisionKey.isCacheable(probability: 0.5,
            reason: "Unable to get a decision from AI. Trusting you to decide whether the site is relevant 😅"))
        let invalid: [Double?] = [nil, Double.nan, -Double.infinity, -0.1, 1.1]
        for probability in invalid {
            XCTAssertFalse(AiRelevanceDecisionKey.isCacheable(probability: probability, reason: ""))
        }
        for probability in [0.0, 0.5, 1.0] {
            XCTAssertTrue(AiRelevanceDecisionKey.isCacheable(probability: probability, reason: "A classifier decision"))
        }
    }

    func testErrorsRemainRetryableAndDoNotBecomeAllowedCacheEntries() {
        let cache = AiRelevanceDecisionCache<Double>()
        var requests = 0
        for _ in 0..<2 {
            cache.resolve(for: key(), isCurrent: { true }, shouldCache: { $0.isFinite && (0...1).contains($0) },
                          load: { done in requests += 1; done(.nan) }, completion: { XCTAssertTrue($0.isNaN) })
        }
        XCTAssertEqual(requests, 2)
        XCTAssertNil(cache.value(for: key()))
    }

    func testResetRejectsOldInFlightResponseEvenAfterReturningToIdenticalTask() {
        let cache = AiRelevanceDecisionCache<Double>()
        var finish: ((Double) -> Void)?
        var applied = false
        cache.resolve(for: key(), isCurrent: { true }, shouldCache: { _ in true },
                      load: { finish = $0 }, completion: { _ in applied = true })
        cache.removeAll()
        finish?(0.95)
        XCTAssertFalse(applied)
        XCTAssertNil(cache.value(for: key()))
    }

    func testSessionResetAndBoundedLRUEviction() {
        let cache = AiRelevanceDecisionCache<Double>(capacity: 2)
        cache.store(0.9, for: key("A"))
        cache.store(0.1, for: key("B"))
        XCTAssertEqual(cache.value(for: key("A")), 0.9)
        cache.store(0.9, for: key("C"))
        XCTAssertNil(cache.value(for: key("B")))
        XCTAssertEqual(cache.value(for: key("A")), 0.9)
        cache.removeAll()
        XCTAssertNil(cache.value(for: key("A")))
        XCTAssertNil(cache.value(for: key("C")))
    }
    func testRedirectChecksExactCaseSensitiveURLBeforeMutation() {
        let script = "set active_tab to active tab in front window\nset URL of active_tab to \"blocked\""
        let guarded = AiRelevanceRedirectGuard.script(script, expectedURL: "https://example.com/A?item=2#part")
        XCTAssertTrue(guarded.contains("considering case"))
        XCTAssertTrue(guarded.contains("if (URL of active_tab as text) is not equal to \"https://example.com/A?item=2#part\" then return"))
        XCTAssertTrue(guarded.range(of: "then return")!.lowerBound < guarded.range(of: "set URL of active_tab to")!.lowerBound)
    }

    func testRedirectGuardEscapesLiteralAndRejectsControlCharacters() {
        let script = "set URL of active tab in front window to \"blocked\""
        let guarded = AiRelevanceRedirectGuard.script(script, expectedURL: "https://example.com/\"\\value")
        XCTAssertTrue(guarded.contains("https://example.com/\\\"\\\\value"))
        XCTAssertEqual(AiRelevanceRedirectGuard.script(script, expectedURL: "https://example.com/\nreturn"), "return")
        XCTAssertEqual(AiRelevanceRedirectGuard.script(script, expectedURL: ""), "return")
    }

    func testFirefoxPayloadIsNotTreatedAsAppleScript() {
        let payload = "old_url=https://example.com/a&focus_mode=Work"
        XCTAssertEqual(AiRelevanceRedirectGuard.script(payload, expectedURL: "https://example.com/a"), payload)
    }

    /// The exact case that shipped broken: the key holds the title lowercased (the caller lowercases
    /// it for the relevance payload) while a live browser read returns the original casing. Comparing
    /// them exactly discarded 17 of 20 verdicts on a real session — the AI ran, answered, and its
    /// decision was thrown away, so nothing was ever blocked.
    func testTitleCasingFromTheBrowserStillMatchesTheLowercasedKey() {
        let request = AiRelevanceDecisionKey(context: Data(), kind: "url",
                                             target: "https://www.magicpatterns.com/dashboard",
                                             content: ["magicpatterns.com/dashboard", "magic patterns", "com.google.Chrome"])
        XCTAssertTrue(request.matchesURLObservation(url: "https://www.magicpatterns.com/dashboard",
                                                    title: "Magic Patterns", bundleIdentifier: "com.google.Chrome"),
                      "A browser title differing only in case is the same page")
    }

    func testHostCasingStillMatches() {
        let request = AiRelevanceDecisionKey(context: Data(), kind: "url", target: "https://Example.com/A",
                                             content: ["example.com/a", "inbox", "browser-1"])
        XCTAssertTrue(request.matchesURLObservation(url: "https://example.com/A", title: "Inbox",
                                                    bundleIdentifier: "browser-1"))
    }

    /// Case-insensitivity must not weaken the guard into matching a genuinely different page.
    func testADifferentTitleStillFailsRegardlessOfCase() {
        let request = AiRelevanceDecisionKey(context: Data(), kind: "url", target: "https://example.com/a",
                                             content: ["example.com/a", "inbox", "browser-1"])
        XCTAssertFalse(request.matchesURLObservation(url: "https://example.com/a", title: "GAMES",
                                                     bundleIdentifier: "browser-1"))
        XCTAssertFalse(request.matchesURLObservation(url: "https://example.com/b", title: "Inbox",
                                                     bundleIdentifier: "browser-1"))
        XCTAssertFalse(request.matchesURLObservation(url: "https://example.com/a", title: "Inbox",
                                                     bundleIdentifier: "OTHER-APP"),
                       "Bundle identifiers are case-sensitive and must stay an exact match")
    }

    func testQueuedCachedDenyRequiresFreshExactBrowserObservation() {
        let request = AiRelevanceDecisionKey(context: Data(), kind: "url", target: "https://example.com/a?item=1",
                                              content: ["example.com/a", "Inbox", "browser-1"])
        XCTAssertTrue(request.matchesURLObservation(url: request.target, title: "Inbox", bundleIdentifier: "browser-1"))
        XCTAssertFalse(request.matchesURLObservation(url: "https://example.com/a?item=2", title: "Inbox", bundleIdentifier: "browser-1"))
        XCTAssertFalse(request.matchesURLObservation(url: request.target, title: "Games", bundleIdentifier: "browser-1"))
        XCTAssertFalse(request.matchesURLObservation(url: request.target, title: "Inbox", bundleIdentifier: "other-app"))
        XCTAssertFalse(request.matchesURLObservation(url: nil, title: "Inbox", bundleIdentifier: "browser-1"))
    }


    // Sentry BACKEND-HC: a long Claude chat title pushed appName past the backend's limit.
    func testAppSafeAppNameKeepsShortTitlesWhole() {
        XCTAssertEqual(AppSafeRequestAppName.withWindowTitle("Claude", "Plan the week"), "Claude - Plan the week")
    }

    func testAppSafeAppNameTrimsLongTitlesToTheLimit() {
        let name = AppSafeRequestAppName.withWindowTitle("Claude", String(repeating: "x", count: 3_000))
        XCTAssertEqual(name.count, AppSafeRequestAppName.maximumLength)
        XCTAssertTrue(name.hasPrefix("Claude - "))
        XCTAssertTrue(name.hasSuffix(AppSafeRequestAppName.truncationMarker))
    }
}
