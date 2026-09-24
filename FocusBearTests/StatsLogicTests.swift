//
//  StatsLogicTests.swift
//  Focus BearTests
//
//  Tests for the pure Stats-screen builders (heat-map grid, leaderboard ordering).
//

import AppKit
import XCTest
@testable import Focus_Bear

final class StatsLogicTests: XCTestCase {

    func testPepTalkDecoderPreservesUnicodeAcrossEveryPacketBoundaryAndHidesPrompt() {
        let payload = Data("data: Ahoy 🏴‍☠️, ánimo!\r\n\r\ndata: [DONE]\r\n\r\ndata: PROMPT: private\n\n".utf8)
        for boundary in 0...payload.count {
            var decoder = MotivationalSummaryDecoder()
            let events = decoder.consume(Data(payload.prefix(boundary))) + decoder.consume(Data(payload.dropFirst(boundary)))
            XCTAssertEqual(events, [.text("Ahoy 🏴‍☠️, ánimo!"), .done])
            XCTAssertTrue(decoder.consume(Data("data: hidden\n".utf8)).isEmpty)
        }
    }

    func testPepTalkDecoderReportsFatalAndMalformedStreamsWithoutPublishingBodies() {
        var fatal = MotivationalSummaryDecoder()
        XCTAssertEqual(fatal.consume(Data("event: fatal_error\ndata: private server error\n".utf8)), [.fatal])
        var invalid = MotivationalSummaryDecoder()
        XCTAssertEqual(invalid.consume(Data([100, 97, 116, 97, 58, 32, 255, 10])), [.invalid])
        var oversized = MotivationalSummaryDecoder()
        XCTAssertEqual(oversized.consume(Data(repeating: 65, count: 65_537)), [.invalid])
    }

    func testPepTalkDecoderKeepsSentenceSpacesAndWaitsForWholeLines() {
        var decoder = MotivationalSummaryDecoder()
        XCTAssertTrue(decoder.consume(Data("data: Hello".utf8)).isEmpty)
        XCTAssertEqual(decoder.consume(Data("\ndata:  world\n\ndata: [DONE]\n".utf8)), [.text("Hello"), .text(" world"), .done])
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        StatsCalendar.calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func weekday(_ date: Date) -> Int { StatsCalendar.calendar.component(.weekday, from: date) }

    // Wed 26 Aug → Tue 8 Sep 2026, "today" = Sun 6 Sep: starts mid-week and crosses a month boundary.
    func testGridPadsToWholeWeeksAndGivesEveryDayACell() {
        let counts = [StatsDates.dayKey(day(2026, 8, 26)): 2, StatsDates.dayKey(day(2026, 9, 1)): 1]
        let model = HeatMapBuilder.grid(from: day(2026, 8, 26), to: day(2026, 9, 8), today: day(2026, 9, 6), counts: counts)

        XCTAssertEqual(model.columns.count, 3)
        XCTAssertTrue(model.columns.allSatisfy { $0.count == HeatMapBuilder.daysInWeek })
        XCTAssertEqual(model.columns[0][0].date, day(2026, 8, 23))
        XCTAssertEqual(model.columns[2][6].date, day(2026, 9, 12))
        XCTAssertEqual(weekday(model.columns[0][0].date), StatsCalendar.calendar.firstWeekday)

        let allDays = model.columns.joined().map { $0.dayKey }
        XCTAssertEqual(Set(allDays).count, 21, "every day appears exactly once")
        XCTAssertEqual(model.columns[0][3].count, 2)
        XCTAssertEqual(model.columns[1][2].count, 1)
        XCTAssertEqual(model.maxCount, 2)
    }

    func testGridMarksDaysAfterTodayAsFuture() {
        let model = HeatMapBuilder.grid(from: day(2026, 8, 26), to: day(2026, 9, 8), today: day(2026, 9, 6), counts: [:])
        let futureKeys = model.columns.joined().filter { $0.isFuture }.map { $0.dayKey }
        XCTAssertEqual(futureKeys, (7...12).map { StatsDates.dayKey(day(2026, 9, $0)) })
        XCTAssertFalse(model.columns[2][0].isFuture, "today itself is not future")
    }

    func testMonthLabelSitsOnTheWeekContainingTheFirst() {
        let model = HeatMapBuilder.grid(from: day(2026, 8, 26), to: day(2026, 9, 8), today: day(2026, 9, 6), counts: [:])
        XCTAssertEqual(model.monthLabels.map { $0.weekIndex }, [1], "Aug would overlap Sep on the adjacent column")
        XCTAssertEqual(model.monthLabels[0].label, StatsDates.format(day(2026, 9, 1), "MMM"))
    }

    func testFirstColumnGetsItsOwnMonthWhenThereIsRoom() {
        let model = HeatMapBuilder.grid(from: day(2026, 8, 16), to: day(2026, 9, 8), today: day(2026, 9, 6), counts: [:])
        XCTAssertEqual(model.columns.count, 4)
        XCTAssertEqual(model.monthLabels.map { $0.weekIndex }, [0, 2])
        XCTAssertEqual(model.monthLabels.map { $0.label },
                       [StatsDates.format(day(2026, 8, 1), "MMM"), StatsDates.format(day(2026, 9, 1), "MMM")])
    }

    func testBuildCoversFiveWeeksBackPlusTheCurrentWeek() {
        let today = day(2026, 9, 4)   // a Friday
        let model = HeatMapBuilder.build(items: [], joinDate: nil, today: today)
        XCTAssertEqual(model.columns.count, HeatMapBuilder.weeksToShow + 1)
        XCTAssertEqual(model.columns[0][0].date, day(2026, 7, 26))
        XCTAssertEqual(model.columns.last?.last?.date, day(2026, 9, 5))
        XCTAssertLessThanOrEqual(StatsCalendar.daysBetween(model.columns[0][0].date, today) + 1, HeatMapBuilder.fetchDays,
                                 "the request must cover the whole grid")
    }

    // MARK: - Leaderboard ordering

    private func user(_ name: String, morning: (streak: Double, percent: Double?, done: Double, days: Double) = (0, 0, 0, 90),
                      micro: (streak: Double, percent: Double?, done: Double, days: Double) = (0, 0, 0, 90),
                      evening: (streak: Double, percent: Double?, done: Double, days: Double) = (0, 0, 0, 90),
                      focus: (streak: Double, done: Double, days: Double) = (0, 0, 90),
                      window: Double? = 90) -> LeaderboardUser {
        LeaderboardUser(id: name, username: name,
                        morningRoutinesStreak: FlexibleNumber(morning.streak), eveningRoutinesStreak: FlexibleNumber(evening.streak),
                        focusModesStreak: FlexibleNumber(focus.streak), microBreaksStreak: FlexibleNumber(micro.streak),
                        morningPercentNumberDayOfStatsCompleted: morning.percent.map(FlexibleNumber.init),
                        eveningPercentNumberDayOfStatsCompleted: evening.percent.map(FlexibleNumber.init),
                        microPercentNumberDayOfStatsCompleted: micro.percent.map(FlexibleNumber.init),
                        morningNumberDaysCompleted: FlexibleNumber(morning.done), morningNumDaysOfStats: FlexibleNumber(morning.days),
                        eveningNumberDaysCompleted: FlexibleNumber(evening.done), eveningNumDaysOfStats: FlexibleNumber(evening.days),
                        microBreaksNumberDaysCompleted: FlexibleNumber(micro.done), microBreaksNumDaysOfStats: FlexibleNumber(micro.days),
                        focusModesNumberDaysCompleted: FlexibleNumber(focus.done), focusModesNumDaysOfStats: FlexibleNumber(focus.days),
                        numDaysOfStats: window.map(FlexibleNumber.init))
    }

    private func names(_ users: [LeaderboardUser]) -> [String] { users.map { $0.username ?? "" } }

    /// The reported bug: rows in rank order (77%, 10%, 28%, 0%, 2%) because the sort used the raw
    /// streak count. Break streak must order by the percentage the column shows.
    func testBreakStreakSortsByPercentageNotStreakCount() {
        let users = [user("jeznag", micro: (19, 77, 69, 90)), user("andrea", micro: (0, 10, 9, 90)),
                     user("bev", micro: (0, 28, 25, 90)), user("gwest", micro: (0, 0, 0, 90)), user("richter", micro: (0, 2, 2, 90))]
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .microBreak, ascending: false)),
                       ["jeznag", "bev", "andrea", "richter", "gwest"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .microBreak, ascending: true)),
                       ["gwest", "richter", "andrea", "bev", "jeznag"])
    }

    func testEachColumnSortsByItsOwnPercentage() {
        let users = [user("a", morning: (1, 10, 9, 90), micro: (1, 90, 81, 90), evening: (1, 50, 45, 90), focus: (1, 9, 90)),
                     user("b", morning: (1, 90, 81, 90), micro: (1, 10, 9, 90), evening: (1, 20, 18, 90), focus: (1, 81, 90)),
                     user("c", morning: (1, 50, 45, 90), micro: (1, 50, 45, 90), evening: (1, 90, 81, 90), focus: (1, 45, 90))]
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .morning, ascending: false)), ["b", "c", "a"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .microBreak, ascending: false)), ["a", "c", "b"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .evening, ascending: false)), ["c", "a", "b"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .focusMode, ascending: false)), ["b", "c", "a"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .morning, ascending: true)), ["a", "c", "b"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .focusMode, ascending: true)), ["a", "c", "b"])
    }

    func testTiesBreakOnDaysCompletedThenStreakThenServerOrder() {
        // Same 50%: more days completed wins; same days: longer streak wins; identical: server order.
        let users = [user("first", evening: (2, 50, 30, 60)), user("second", evening: (9, 50, 30, 60)),
                     user("third", evening: (3, 50, 45, 90)), user("fourth", evening: (2, 50, 30, 60))]
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .evening, ascending: false)), ["third", "second", "first", "fourth"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .evening, ascending: true)), ["first", "fourth", "second", "third"],
                       "ascending flips the comparison but fully tied rows keep the server's order")
    }

    func testFocusModePercentageComesFromTheDayPair() {
        XCTAssertEqual(LeaderboardSorting.metric(user("x", focus: (138, 84, 90)), key: .focusMode).percentage, 93)
        XCTAssertEqual(LeaderboardSorting.metric(user("x", focus: (138, 84, 90)), key: .focusMode).streak, 138)
        XCTAssertEqual(LeaderboardSorting.metric(user("x", focus: (0, 1, 3)), key: .focusMode).percentage, 33)
        XCTAssertEqual(LeaderboardSorting.metric(user("x", focus: (0, 0, 0)), key: .focusMode).percentage, 0, "no window → 0%, not NaN")
        XCTAssertEqual(LeaderboardSorting.percentage(completedDays: 90, windowDays: 90), 100)
    }

    func testServerPercentageWinsWhenPresentAndIsDerivedOtherwise() {
        XCTAssertEqual(LeaderboardSorting.metric(user("x", morning: (1, 50, 88, 90)), key: .morning).percentage, 50,
                       "the web shows the server's percentage column as-is")
        XCTAssertEqual(LeaderboardSorting.metric(user("x", morning: (1, nil, 88, 90)), key: .morning).percentage, 98)
    }

    // MARK: - Forgiven days (report: "why is it saying 84/84? I've clearly got > 90 days of data")

    /// The account in the report: a 149-day focus streak whose tally reads 84 of 84. Backend #2424
    /// made every streak walk and its 90-day tally forgive the same days (a weekend with no focus
    /// session is neither a hit nor a miss), so the denominator is the measured-day count and the
    /// six-day gap to the window has to be explained rather than silently dropped.
    func testForgivenDaysAreTheGapBetweenTheMeasuredDaysAndTheWindow() {
        let metric = LeaderboardSorting.metric(user("jeznag", focus: (149, 84, 84)), key: .focusMode)
        XCTAssertEqual(metric.percentage, 100, "84 of 84 measured days is 100%, not 84/90 = 93%")
        XCTAssertEqual(metric.windowDays, 84)
        XCTAssertEqual(metric.windowSpanDays, 90)
        XCTAssertEqual(metric.forgivenDays, 6)
        XCTAssertTrue(metric.hasForgivenDays)
    }

    func testNothingIsForgivenWhenEveryWindowDayWasMeasured() {
        let metric = LeaderboardSorting.metric(user("jeznag", morning: (71, 98, 88, 90)), key: .morning)
        XCTAssertEqual(metric.forgivenDays, 0)
        XCTAssertFalse(metric.hasForgivenDays)
    }

    /// Breaks forgive weekends exactly like focus does, so a break column gets the same treatment —
    /// "74 of 77" with three of the last 90 days forgiven, not "74 of 90".
    func testBreaksForgiveDaysTheSameWayFocusDoes() {
        let metric = LeaderboardSorting.metric(user("jeznag", micro: (31, 96, 74, 77)), key: .microBreak)
        XCTAssertEqual(metric.windowDays, 77)
        XCTAssertEqual(metric.forgivenDays, 13)
        XCTAssertTrue(metric.hasForgivenDays)
    }

    func testForgivenDaysStayNonNegativeWhenTheServerDisagreesWithItself() {
        let metric = LeaderboardSorting.metric(user("x", focus: (1, 95, 95), window: 90), key: .focusMode)
        XCTAssertEqual(metric.forgivenDays, 0, "a window shorter than the measured days must not go negative")
        XCTAssertEqual(metric.windowSpanDays, 95)
        XCTAssertEqual(LeaderboardSorting.metric(user("y", focus: (1, 84, 84), window: nil), key: .focusMode).forgivenDays, 0,
                       "no window from the server → nothing is known to be forgiven")
    }

    /// The caption must not claim "out of last 84 days" — that is what read as lost history.
    func testCompletionSummaryNamesTheForgivenDaysOnlyWhenThereAreSome() {
        let strings = StatsStrings()
        let forgiving = LeaderboardSorting.metric(user("jeznag", focus: (149, 84, 84)), key: .focusMode)
        XCTAssertEqual(LeaderboardSorting.completionSummary(forgiving, strings: strings),
                       "Last 90 days: 84 completed, 6 weekend days forgiven")
        let plain = LeaderboardSorting.metric(user("jeznag", morning: (71, 98, 88, 90)), key: .morning)
        XCTAssertEqual(LeaderboardSorting.completionSummary(plain, strings: strings),
                       "88 days completed out of last 90 days")
    }

    func testSortKeysAreTheBackendStreakTypes() {
        XCTAssertEqual(LeaderboardSortKey.allCases.map { $0.rawValue },
                       ["morning_routines_streak", "micro_breaks_streak", "evening_routines_streak", "focus_modes_streak"])
    }

    // MARK: - Heat-map weekday labels

    func testWeekdayLabelsAreSundayFirstInTheAppLanguage() {
        XCTAssertEqual(StatsCalendar.shortWeekdaySymbols(languageCode: "en"), ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
        let spanish = StatsCalendar.shortWeekdaySymbols(languageCode: "es")
        XCTAssertEqual(spanish.count, 7)
        XCTAssertTrue(spanish[0].lowercased().hasPrefix("dom"), "\(spanish)")
        XCTAssertEqual(StatsCalendar.shortWeekdaySymbols(languageCode: "").count, 7)
    }

    // MARK: - Per-level artwork

    func testEveryLevelUpToTheMaxHasArtworkThatLoadsFromTheAssetCatalog() {
        for level in 0...LevelTargets.maxLevel {
            guard let name = LevelArtwork.assetName(level: level) else {
                return XCTFail("level \(level) has no artwork mapped")
            }
            XCTAssertNotNil(NSImage(named: name), "\(name) is missing from Assets.xcassets")
        }
    }

    func testArtworkIsKeyedByLevelIndexTheSameWayTheWebDashboardKeysIt() {
        // Mirrors `getLevelIconAndName` in web_dashboard/src/utils/stats.util.ts, where the level is a
        // direct index into [Novice, Apprentice, Explorer, Disciplined, Diligent, Strategist, Mentor,
        // Scholar, Guardian, Achiever]. Level 6 = Mentor is the case in the bug report's screenshot.
        XCTAssertEqual(LevelArtwork.assetName(level: 0), "levelNovice")
        XCTAssertEqual(LevelArtwork.assetName(level: 6), "levelMentor")
        XCTAssertEqual(LevelArtwork.assetName(level: LevelTargets.maxLevel), "levelAchiever")
    }

    func testArtworkNamesLineUpWithTheDisplayedLevelNames() {
        let strings = StatsStrings()
        for level in 0...LevelTargets.maxLevel {
            XCTAssertEqual(LevelArtwork.assetName(level: level), "level" + strings.levelName(level),
                           "the default English level names and the artwork must stay in the same order")
        }
    }

    func testAnUnknownLevelHasNoArtworkSoTheViewCanFallBack() {
        XCTAssertNil(LevelArtwork.assetName(level: -1))
        XCTAssertNil(LevelArtwork.assetName(level: LevelTargets.maxLevel + 1))
    }

    // MARK: Why a pep talk failed (report 2026-09-22_07-45-26)
    //
    // "What was the error here?" — the log said HTTP 429 five times in two minutes, two of them two
    // seconds apart. The UI said "try again later" because the stream handed it a bare Bool, so
    // every failure looked identical and Retry looked worth pressing.

    func testARateLimitIsToldApartFromEveryOtherFailure() {
        XCTAssertEqual(PepTalkFailure.from(status: 429, retryAfterHeader: nil),
                       .rateLimited(retryAfter: nil))
        XCTAssertEqual(PepTalkFailure.from(status: 500, retryAfterHeader: nil), .serverError)
        XCTAssertEqual(PepTalkFailure.from(status: 503, retryAfterHeader: nil), .serverError)
        XCTAssertEqual(PepTalkFailure.from(status: 0, retryAfterHeader: nil), .connection)
        XCTAssertEqual(PepTalkFailure.from(status: 404, retryAfterHeader: nil), .other)
    }

    func testTheServersOwnRetryAfterIsHonoured() {
        XCTAssertEqual(PepTalkFailure.from(status: 429, retryAfterHeader: "30"),
                       .rateLimited(retryAfter: 30))
        XCTAssertEqual(PepTalkFailure.from(status: 429, retryAfterHeader: "  45 "),
                       .rateLimited(retryAfter: 45), "headers arrive padded")
    }

    /// Retry-After may be an HTTP date, which needs a clock both ends agree on. Getting that wrong
    /// would hold the button for hours, so only the seconds form is honoured and the rest falls back.
    func testAnUnusableRetryAfterFallsBackRatherThanGuessing() {
        for header in ["Wed, 21 Oct 2026 07:28:00 GMT", "soon", "", "-5", "0"] {
            XCTAssertEqual(PepTalkFailure.from(status: 429, retryAfterHeader: header),
                           .rateLimited(retryAfter: nil), header)
        }
    }

    func testAnAbsurdRetryAfterIsCapped() {
        // A misconfigured header must not disable the feature for the rest of the day.
        XCTAssertEqual(PepTalkFailure.from(status: 429, retryAfterHeader: "86400"),
                       .rateLimited(retryAfter: PepTalkFailure.maximumHonouredWait))
    }

    func testOnlyARateLimitHoldsTheRetryButton() {
        XCTAssertEqual(PepTalkFailure.rateLimited(retryAfter: 30).retryDelay, 30)
        XCTAssertEqual(PepTalkFailure.rateLimited(retryAfter: nil).retryDelay,
                       PepTalkFailure.defaultRateLimitWait,
                       "a 429 with no advice still has to wait for something")

        // Guessing a delay for these would be inventing a number — retrying a server error or a
        // dropped connection immediately is perfectly reasonable.
        XCTAssertNil(PepTalkFailure.serverError.retryDelay)
        XCTAssertNil(PepTalkFailure.connection.retryDelay)
        XCTAssertNil(PepTalkFailure.other.retryDelay)
    }


    // MARK: Not spending the daily budget on screen appearances (report 2026-09-22_07-45-26)
    //
    // The 429 was not an aggressive limit. The backend allows 60 pep talks a day per user, and this
    // one Mac made 57, 60, 49 and 48 on consecutive days — the routine screen builds a fresh store
    // on every appearance, and each one generated a new message.

    func testARecentPepTalkIsWorthShowingAgain() {
        let now = Date()
        XCTAssertTrue(PepTalkCache.isFresh(cachedAt: now.addingTimeInterval(-60), now: now))
        XCTAssertTrue(PepTalkCache.isFresh(cachedAt: now.addingTimeInterval(-PepTalkCache.reuseWindow + 1),
                                           now: now))
    }

    func testAnOldOneIsNot() {
        let now = Date()
        XCTAssertFalse(PepTalkCache.isFresh(cachedAt: now.addingTimeInterval(-PepTalkCache.reuseWindow),
                                            now: now), "the window is exclusive at its own edge")
        XCTAssertFalse(PepTalkCache.isFresh(cachedAt: now.addingTimeInterval(-24 * 60 * 60), now: now))
        XCTAssertFalse(PepTalkCache.isFresh(cachedAt: nil, now: now), "nothing cached yet")
    }

    /// A timestamp in the future means the clock moved — a timezone change, an NTP correction, a
    /// laptop waking. Trusting it would pin a stale message for the whole window.
    func testAFutureTimestampIsTreatedAsStale() {
        let now = Date()
        XCTAssertFalse(PepTalkCache.isFresh(cachedAt: now.addingTimeInterval(60), now: now))
    }

    func testAReusableMessageIsReturnedWithItsOwnTone() {
        PepTalkCache.clear()
        let now = Date()
        PepTalkCache.store(text: "go get em", tone: "pirate", language: "en", now: now)

        let reusable = PepTalkCache.reusable(language: "en", now: now.addingTimeInterval(60))
        XCTAssertEqual(reusable?.text, "go get em")
        XCTAssertEqual(reusable?.tone, "pirate", "the tone must travel with the text, or the chips lie")
        PepTalkCache.clear()
    }

    func testAMessageInAnotherLanguageIsNotReused() {
        PepTalkCache.clear()
        PepTalkCache.store(text: "go get em", tone: "pirate", language: "en")
        XCTAssertNil(PepTalkCache.reusable(language: "es"),
                     "reusing English for a Spanish session would be worse than another request")
        PepTalkCache.clear()
    }

    func testAnEmptyMessageIsNeverCached() {
        PepTalkCache.clear()
        PepTalkCache.store(text: "", tone: "pirate", language: "en")
        XCTAssertNil(PepTalkCache.reusable(language: "en"),
                     "a failed stream must not pin a blank message for half an hour")
        PepTalkCache.clear()
    }

    /// The reason the empty check lives in `store` and not only in `reusable`: without it, a failed
    /// stream OVERWRITES a perfectly good cached message — and refreshes its timestamp while doing
    /// so. The next appearance would then generate a new one, which is the behaviour being fixed.
    func testAFailedStreamDoesNotDestroyAGoodCachedMessage() {
        PepTalkCache.clear()
        let now = Date()
        PepTalkCache.store(text: "go get em", tone: "pirate", language: "en", now: now)
        PepTalkCache.store(text: "", tone: "scientist", language: "en", now: now.addingTimeInterval(1))

        let reusable = PepTalkCache.reusable(language: "en", now: now.addingTimeInterval(2))
        XCTAssertEqual(reusable?.text, "go get em", "the good message must survive a later failure")
        XCTAssertEqual(reusable?.tone, "pirate")
        PepTalkCache.clear()
    }

    func testAnExpiredMessageIsNotReused() {
        PepTalkCache.clear()
        let now = Date()
        PepTalkCache.store(text: "go get em", tone: "pirate", language: "en", now: now)
        XCTAssertNil(PepTalkCache.reusable(language: "en",
                                           now: now.addingTimeInterval(PepTalkCache.reuseWindow + 1)))
        PepTalkCache.clear()
    }


    // MARK: Once per routine start per day (report 2026-09-22_07-45-26, follow-up)
    //
    // "It's only meant to show the stats view once per routine start per day. Once in the morning and
    // once in the evening. How could it be 26 times?"
    //
    // Because the pep talk lives on the "visualize" screen, which is shown for EVERY habit. On the
    // reported day, 15 of the 26 requests were immediately preceded by
    // "Showing morning/evening habits from habit completed back button".

    private typealias Display = PepTalkRoutineDisplay

    func testTheFirstRoutineOfTheDayShowsIt() {
        XCTAssertTrue(Display.shouldShow(routine: ._MORNING_HABIT_, lastShown: [:]))
    }

    func testCompletingHabitsDoesNotBringItBack() {
        // Fixed times of day: offsets from the real clock crossed midnight when the suite ran after
        // 20:00, and the "same routine, later that day" case became "tomorrow".
        let calendar = Calendar.current
        let routineStart = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
        let shown = Display.recording(._MORNING_HABIT_, at: routineStart, into: [:])
        // Every subsequent habit in the same routine returns to this screen.
        XCTAssertFalse(Display.shouldShow(routine: ._MORNING_HABIT_,
                                          now: routineStart.addingTimeInterval(5 * 60), lastShown: shown))
        XCTAssertFalse(Display.shouldShow(routine: ._MORNING_HABIT_,
                                          now: routineStart.addingTimeInterval(4 * 60 * 60), lastShown: shown))
    }

    func testTheEveningRoutineStillGetsItsOwn() {
        let now = Date()
        let shown = Display.recording(._MORNING_HABIT_, at: now, into: [:])
        XCTAssertTrue(Display.shouldShow(routine: ._EVENING_HABIT_, now: now, lastShown: shown),
                      "once in the morning AND once in the evening")
    }

    /// Postponing and resuming the morning routine is not a new day, so it does not earn a second one.
    func testResumingTheSameRoutineDoesNotEarnAnother() {
        let calendar = Calendar.current
        let morning = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
        let afternoon = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!
        let shown = Display.recording(._MORNING_HABIT_, at: morning, into: [:])
        XCTAssertFalse(Display.shouldShow(routine: ._MORNING_HABIT_, now: afternoon, lastShown: shown))
    }

    func testTomorrowStartsAgain() {
        let now = Date()
        let shown = Display.recording(._MORNING_HABIT_, at: now, into: [:])
        XCTAssertTrue(Display.shouldShow(routine: ._MORNING_HABIT_,
                                         now: now.addingTimeInterval(24 * 60 * 60), lastShown: shown),
                      "per DAY — a new day gets a fresh one")
    }

}
