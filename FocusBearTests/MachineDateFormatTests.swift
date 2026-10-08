//
//  MachineDateFormatTests.swift
//  FocusBearTests
//
//  Machine-readable dates stay Gregorian on a Mac set to the Buddhist, Japanese or Islamic calendar
//  (backend#2526: a Thai-calendar Mac uploaded activity dated 2569). The user's calendar and locale are
//  injected — the system settings are never changed.
//

@testable import Focus_Bear
import XCTest

final class MachineDateFormatTests: XCTestCase {

    /// 2026-10-06 00:00:00 UTC.
    private static let fixedDate = Date(timeIntervalSince1970: 1_791_244_800)
    private static let gregorianTimestamp = "2026-10-06T00:00:00.000Z"
    private static let gregorianDayKey = "2026-10-06"

    private struct UserSettings {
        let localeIdentifier: String
        let calendar: Calendar.Identifier
        /// What a bare `DateFormatter()` wrote for `fixedDate` on that Mac.
        let legacyTimestamp: String

        var locale: Locale { Locale(identifier: localeIdentifier) }
    }

    private static let nonGregorianUsers = [
        UserSettings(localeIdentifier: "th_TH@calendar=buddhist", calendar: .buddhist,
                     legacyTimestamp: "2569-10-06T00:00:00.000Z"),
        UserSettings(localeIdentifier: "en_AU@calendar=buddhist", calendar: .buddhist,
                     legacyTimestamp: "2569-10-06T00:00:00.000Z"),
        UserSettings(localeIdentifier: "ja_JP@calendar=japanese", calendar: .japanese,
                     legacyTimestamp: "0008-10-06T00:00:00.000Z"),
        UserSettings(localeIdentifier: "ar_SA@calendar=islamic-umalqura", calendar: .islamicUmmAlQura,
                     legacyTimestamp: "١٤٤٨-٠٤-٢٥T٠٠:٠٠:٠٠.٠٠٠Z"),
        UserSettings(localeIdentifier: "en_AU@calendar=islamic-umalqura", calendar: .islamicUmmAlQura,
                     legacyTimestamp: "1448-04-25T00:00:00.000Z"),
    ]

    private static let nonEnglishGregorianLocales = ["es_ES", "de_DE", "pl_PL", "fr_FR", "ar_AE", "hi_IN"]

    private func userCalendar(_ user: UserSettings, timeZone: TimeZone = MachineDateFormat.utc) -> Calendar {
        var calendar = Calendar(identifier: user.calendar)
        calendar.locale = user.locale
        calendar.timeZone = timeZone
        return calendar
    }

    /// A formatter as a bare `DateFormatter()` comes out on that Mac, plus the `calendar = .current`
    /// some call sites added.
    private func inheritedFormatter(_ user: UserSettings, format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = user.locale
        formatter.calendar = userCalendar(user)
        formatter.timeZone = MachineDateFormat.utc
        formatter.dateFormat = format
        return formatter
    }

    // MARK: - Writing

    func test_inheritedFormatter_reproducesTheNonGregorianYears() {
        for user in Self.nonGregorianUsers {
            let written = inheritedFormatter(user, format: MachineDateFormat.utcTimestamp).string(from: Self.fixedDate)
            XCTAssertEqual(written, user.legacyTimestamp, user.localeIdentifier)
        }
    }

    func test_configure_writesGregorianAsciiTimestamps_whateverTheFormatterInherited() {
        for user in Self.nonGregorianUsers {
            let formatter = inheritedFormatter(user, format: MachineDateFormat.utcTimestamp)
            MachineDateFormat.configure(formatter, timeZone: MachineDateFormat.utc)
            XCTAssertEqual(formatter.string(from: Self.fixedDate), Self.gregorianTimestamp, user.localeIdentifier)
        }
    }

    func test_configure_writesAsciiDigits_inNonEnglishLocales() {
        for identifier in Self.nonEnglishGregorianLocales {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: identifier)
            formatter.dateFormat = MachineDateFormat.utcTimestamp
            MachineDateFormat.configure(formatter, timeZone: MachineDateFormat.utc)
            XCTAssertEqual(formatter.string(from: Self.fixedDate), Self.gregorianTimestamp, identifier)
        }
    }

    func test_sharedHelpers_areGregorianPosix() {
        for zone in [CachedDateFormatters.Zone.local, .utc] {
            let formatter = CachedDateFormatters.formatter(format: MachineDateFormat.dayKey, zone: zone)
            XCTAssertEqual(formatter.calendar.identifier, .gregorian)
            XCTAssertEqual(formatter.locale.identifier, MachineDateFormat.locale.identifier)
        }
        XCTAssertEqual(getStringFromDateInUtc(date: Self.fixedDate, dateFormat: MachineDateFormat.utcTimestamp),
                       Self.gregorianTimestamp)
    }

    func test_dayPlanDayKeys_useTheGregorianCalendar() {
        let key = DayPlanHabitSkips.dayKey(Self.fixedDate)
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = .current
        let parts = gregorian.dateComponents([.year, .month, .day], from: Self.fixedDate)
        XCTAssertEqual(key, String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0))
        XCTAssertEqual(DayPlanHabitDurations.dayKey(Self.fixedDate), key)
    }

    // MARK: - Display

    func test_sharedDisplayFormatter_inheritsTheUsersCalendarAndLocale() {
        let formatter = CachedDateFormatters.formatter(format: "EEE d MMM", zone: .local, style: .display)
        XCTAssertEqual(formatter.calendar.identifier, Calendar.current.identifier)
        XCTAssertEqual(formatter.locale.identifier, Locale.current.identifier)
    }

    func test_legacyReader_followsTheUsersCalendar_likeTheOldFormatterDid() {
        for user in Self.nonGregorianUsers {
            let reader = MachineDateFormat.legacyFormatters(MachineDateFormat.utcTimestamp, timeZone: MachineDateFormat.utc,
                                                            legacyLocale: user.locale).first
            XCTAssertEqual(reader?.string(from: Self.fixedDate), user.legacyTimestamp, user.localeIdentifier)
        }
    }

    func test_storeFormatters_recoverLegacyDays_too() {
        let formatter = MachineDateFormat.formatter(MachineDateFormat.dayKey, timeZone: MachineDateFormat.utc,
                                                    legacyLocale: Locale(identifier: "th_TH@calendar=buddhist"),
                                                    now: { Self.fixedDate })
        XCTAssertEqual(formatter.date(from: "2569-10-06"), Self.fixedDate)
        XCTAssertEqual(formatter.string(from: Self.fixedDate), Self.gregorianDayKey)
    }

    // MARK: - Reading

    func test_parse_readsServerTimestampsAsGregorian() {
        for user in Self.nonGregorianUsers {
            XCTAssertEqual(MachineDateFormat.date(from: Self.gregorianTimestamp, format: MachineDateFormat.utcTimestamp,
                                                  timeZone: MachineDateFormat.utc, legacyLocale: user.locale,
                                                  now: Self.fixedDate),
                           Self.fixedDate, user.localeIdentifier)
        }
    }

    func test_parse_recoversWhatAnOlderBuildWroteInTheUsersCalendar() {
        for user in Self.nonGregorianUsers {
            XCTAssertEqual(MachineDateFormat.date(from: user.legacyTimestamp, format: MachineDateFormat.utcTimestamp,
                                                  timeZone: MachineDateFormat.utc, legacyLocale: user.locale,
                                                  now: Self.fixedDate),
                           Self.fixedDate, user.localeIdentifier)
        }
    }

    func test_parse_recoversBuddhistYears_afterTheMacSwitchedBackToGregorian() {
        let parsed = MachineDateFormat.date(from: "2569-10-06T00:00:00.000Z", format: MachineDateFormat.utcTimestamp,
                                            timeZone: MachineDateFormat.utc, legacyLocale: Locale(identifier: "en_AU"),
                                            now: Self.fixedDate)
        XCTAssertEqual(parsed, Self.fixedDate)
    }

    func test_parse_leavesSentinelDatesAlone() {
        let epoch = MachineDateFormat.date(from: "1970-01-01T00:00:00.000Z", format: MachineDateFormat.utcTimestamp,
                                           timeZone: MachineDateFormat.utc,
                                           legacyLocale: Locale(identifier: "th_TH@calendar=buddhist"),
                                           now: Self.fixedDate)
        XCTAssertEqual(epoch, Date(timeIntervalSince1970: 0))
    }

    func test_normalizedLegacyString_rewritesOnlyNonGregorianDays() {
        let buddhist = Locale(identifier: "th_TH@calendar=buddhist")
        func normalized(_ text: String) -> String? {
            MachineDateFormat.normalizedLegacyString(text, format: MachineDateFormat.dayKey, timeZone: MachineDateFormat.utc,
                                                     legacyLocale: buddhist, now: Self.fixedDate)
        }
        XCTAssertEqual(normalized("2569-10-06"), Self.gregorianDayKey)
        XCTAssertNil(normalized(Self.gregorianDayKey))
        XCTAssertNil(normalized("not a day"))
        XCTAssertNil(normalized(""))
    }
}
