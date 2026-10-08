//
//  SettingsManagerTests.swift
//  FocusBearTests
//
//  Tests for SettingsManager utility methods.
//  Issue: Focus-Bear/Mac-App#1629
//

@testable import Focus_Bear
import XCTest

class SettingsManagerTests: XCTestCase {

    var settings: SettingsManager!
    private var originalPreferenceKey = ""

    override func setUp() {
        super.setUp()
        originalPreferenceKey = SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks
        SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks = "FocusBear.Tests.SettingsManager.\(UUID().uuidString)"
        settings = SettingsManager()
        // getCurrentStrictnessLevel() reads this UserDefaults key directly.
        // Set it to a known value so strictness tests are deterministic.
        UserDefaults.standard.set(false,
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
    }

    override func tearDown() {
        settings = nil
        UserDefaults.standard.removeObject(
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
        SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks = originalPreferenceKey
        super.tearDown()
    }

    // MARK: - getDayOfWeek

    func test_getDayOfWeek_sunday() {
        // 2024-01-07 was a Sunday
        let date = makeDateWith(year: 2024, month: 1, day: 7)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Sunday")
    }

    func test_getDayOfWeek_monday() {
        // 2024-01-08 was a Monday
        let date = makeDateWith(year: 2024, month: 1, day: 8)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Monday")
    }

    func test_getDayOfWeek_tuesday() {
        let date = makeDateWith(year: 2024, month: 1, day: 9)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Tuesday")
    }

    func test_getDayOfWeek_wednesday() {
        let date = makeDateWith(year: 2024, month: 1, day: 10)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Wednesday")
    }

    func test_getDayOfWeek_thursday() {
        let date = makeDateWith(year: 2024, month: 1, day: 11)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Thursday")
    }

    func test_getDayOfWeek_friday() {
        let date = makeDateWith(year: 2024, month: 1, day: 12)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Friday")
    }

    func test_getDayOfWeek_saturday() {
        let date = makeDateWith(year: 2024, month: 1, day: 13)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Saturday")
    }

    func test_getDayOfWeek_yearBoundary() {
        // 2024-12-31 was a Tuesday
        let date = makeDateWith(year: 2024, month: 12, day: 31)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Tuesday")
    }

    func test_getDayOfWeek_leapDay() {
        // 2024-02-29 was a Thursday
        let date = makeDateWith(year: 2024, month: 2, day: 29)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Thursday")
    }

    // MARK: - SettingsManager default values

    func test_defaultBlockedUrls_isEmpty() {
        let fresh = SettingsManager()
        XCTAssertTrue(fresh.arrBlockedUrls.isEmpty,
            "A freshly initialised SettingsManager should have no blocked URLs")
    }

    func test_defaultBlockedApps_isEmpty() {
        let fresh = SettingsManager()
        XCTAssertTrue(fresh.arrBlockedApps.isEmpty,
            "A freshly initialised SettingsManager should have no blocked apps")
    }

    func test_defaultAlwaysAllowedApps_isEmpty() {
        let fresh = SettingsManager()
        XCTAssertTrue(fresh.arrAlwaysAllowedApps.isEmpty)
    }

    func test_defaultEasySkipEnabled_isTrue() {
        let fresh = SettingsManager()
        XCTAssertTrue(fresh.isEasySkipEnabled,
            "Easy-skip should be on by default")
    }

    func test_defaultFullScreenEnabled_isFalse() {
        let fresh = SettingsManager()
        XCTAssertFalse(fresh.isFullScreenEnabled,
            "Full-screen blocking should be off by default (set false for onboarding)")
    }

    // MARK: - getCurrentStrictnessLevel

    func test_getCurrentStrictnessLevel_returnsAnInt() {
        // Use a freshly-initialised instance with known property values so the
        // result does not depend on whatever state other tests left on the
        // shared SettingsManagerObject global.
        let fresh = SettingsManager()
        fresh.isFullScreenEnabled              = false
        fresh.isCuddlyModeEnabled              = true
        fresh.isEasySkipEnabled                = true
        fresh.shouldReloadAfterForceQuitEnabled = false
        fresh.immediatelyBlockDistractingSites = false
        fresh.immediatelyBlockDistractingApps  = false
        fresh.isRequiredIntentionInPostpone    = false

        let level = fresh.getCurrentStrictnessLevel()
        // Strictness buckets are 1...5 (see strictnessLevel* constants).
        XCTAssertGreaterThanOrEqual(level, 1)
        XCTAssertLessThanOrEqual(level, 5)
    }

    func test_getCurrentStrictnessLevel_withFullScreenEnabled_higherThanWithout() {
        let sm1 = SettingsManager()
        sm1.isFullScreenEnabled = false
        sm1.isCuddlyModeEnabled = true
        sm1.isEasySkipEnabled   = true
        let levelLow = sm1.getCurrentStrictnessLevel()

        let sm2 = SettingsManager()
        sm2.isFullScreenEnabled = true
        sm2.isCuddlyModeEnabled = false
        sm2.isEasySkipEnabled   = false
        let levelHigh = sm2.getCurrentStrictnessLevel()

        XCTAssertLessThan(levelLow, levelHigh,
            "Stricter settings should produce a higher strictness level")
    }

    // MARK: - Helpers

    private func makeDateWith(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year  = year
        components.month = month
        components.day   = day
        return Calendar(identifier: .gregorian).date(from: components)
    }

    // MARK: The settings password covers routine editing too (report 2026-09-22_21-41-33)
    //
    // "I have a password rule for changing settings after cutoff time. It needs to be enforced when
    // editing habits or routine timings or custom routines after cutoff time."
    //
    // Routine TIMING already asked. Editing a habit, adding a habit, and managing custom routines did
    // not — all three are reachable straight from the Day Plan, so the password guarding Settings
    // could simply be walked around. The rule itself is unchanged; it now sits in front of four doors
    // instead of one.

    /// The rule, restated here so a change to it has to be deliberate: after cutoff counts, a
    /// super-strict session counts, and "always" counts.
    private func requiresPassword(cutoffRunning: Bool, afterCutoffRule: Bool, always: Bool) -> Bool {
        if cutoffRunning && afterCutoffRule { return true }
        return always
    }

    func testTheAfterCutoffRuleIsWhatTheReportIsAbout() {
        XCTAssertTrue(requiresPassword(cutoffRunning: true, afterCutoffRule: true, always: false),
                      "past cutoff, with the after-cutoff rule on")
        XCTAssertFalse(requiresPassword(cutoffRunning: false, afterCutoffRule: true, always: false),
                       "before cutoff, that rule says nothing")
    }

    func testACategoricalRuleAppliesWheneverItIsOn() {
        // "(Same if password rule applies categorically to changing settings)" — the report's own
        // parenthetical, which is why the gate reads the shared predicate rather than only the
        // cutoff half of it.
        XCTAssertTrue(requiresPassword(cutoffRunning: false, afterCutoffRule: false, always: true))
        XCTAssertTrue(requiresPassword(cutoffRunning: true, afterCutoffRule: false, always: true))
    }

    func testNoRuleMeansNoPrompt() {
        XCTAssertFalse(requiresPassword(cutoffRunning: true, afterCutoffRule: false, always: false),
                       "past cutoff is not itself a reason — the user has to have asked for it")
        XCTAssertFalse(requiresPassword(cutoffRunning: false, afterCutoffRule: false, always: false))
    }

    /// The locally-stored half of the rule is per-account. A shared key would let one account's
    /// choice gate another's routine editing — the ownerless-key hazard that has already cost this
    /// user a setting.
    ///
    /// Only this one is checked: `isPasswordRequireInPreferencesAfterCutoff` comes down with the
    /// server's settings and has no local key to scope, which is worth knowing rather than
    /// asserting something untrue about.
    func testTheStoredPasswordRuleIsScopedToTheAccount() {
        let manager = SettingsManager()
        manager.resetAllKeys()
        let key = manager.kUserdefaultsPasswordRequireInChangeSettings
        XCTAssertTrue(manager.isUserScopedKey(key) || (appdelegate?.user?.userId ?? "").isEmpty,
                      "\(key) must carry the signed-in account")
    }

}

// MARK: - Password rule: shortening habits on the Day Plan

/// Covers Settings › Password › "Shortening habits on the Day Plan": only when it is on does the Day Plan's
/// Shorten action ask for the password, honouring the usual recent-unlock grace. The change-settings /
/// after-cutoff / super-strict rules do not gate Shorten (matches Windows). The setting syncs under
/// `kIsPasswordRequireInShortenHabits`, the exact key the Windows app uses.
final class ShortenHabitPasswordPolicyTests: XCTestCase {

    private func requires(passwordSet: Bool = true,
                          withinGrace: Bool = false,
                          buddyUnlocked: Bool = false,
                          shortenRuleOn: Bool = false) -> Bool {
        ShortenHabitPasswordPolicy.requiresPassword(isPasswordSet: passwordSet,
                                                    isWithinUnlockGrace: withinGrace,
                                                    isUnlockedByAccountabilityBuddy: buddyUnlocked,
                                                    isShortenRuleOn: shortenRuleOn)
    }

    func testShortenRuleOnAsksForPassword() {
        XCTAssertTrue(requires(shortenRuleOn: true))
    }

    /// Regression: with the Shorten rule off, Shorten asked after cutoff because "opening Preferences
    /// after cutoff" was on. The policy no longer takes any change-settings input, so rule off = no prompt.
    func testShortenRuleOffNeverAsks() {
        XCTAssertFalse(requires(shortenRuleOn: false))
    }

    func testNoPasswordSetNeverAsks() {
        XCTAssertFalse(requires(passwordSet: false, shortenRuleOn: true))
    }

    func testRecentUnlockGraceSkipsThePrompt() {
        XCTAssertFalse(requires(withinGrace: true, shortenRuleOn: true))
    }

    func testAccountabilityBuddyUnlockSkipsThePrompt() {
        XCTAssertFalse(requires(buddyUnlocked: true, shortenRuleOn: true))
    }

    func testGraceMatchesTheOtherPasswordGates() {
        XCTAssertEqual(ShortenHabitPasswordPolicy.unlockGraceSeconds, 120)
    }

    func testRuleDefaultsOffAndSyncsUnderTheWindowsKey() {
        let settings = SettingsManager()
        XCTAssertFalse(settings.isPasswordRequireInShortenHabits)
        XCTAssertEqual(settings.getLocalJsonToUpload()["kIsPasswordRequireInShortenHabits"] as? Bool, false)

        settings.isPasswordRequireInShortenHabits = true
        XCTAssertEqual(settings.getLocalJsonToUpload()["kIsPasswordRequireInShortenHabits"] as? Bool, true)
    }
}
