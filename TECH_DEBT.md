# Focus Bear macOS App — Tech Debt Register

Findings from a full-codebase audit (2026-07). Companion to [`ARCHITECTURE.md`](ARCHITECTURE.md).
Line numbers are anchors from the time of the audit and will drift; symbol names are the stable
reference. Severity: **P0** fix ASAP (security/correctness) · **P1** high-value (bugs, crash risk,
big wins) · **P2** structural (plan refactors) · **P3** hygiene.

## Codebase-wide numbers (for calibration)

| Metric | Count |
|---|---|
| Swift LoC (app + helper + tests) | ~136,500 |
| Force-unwrap `!` occurrences (heuristic) | ~2,850 (`AllApi` 316, `AppDelegate` 288, `habitsVc` 240) |
| `as!` force casts / `try!` | 42 / 4 |
| Raw-string `forKey:` call sites (UserDefaults etc.) | ~3,671 (~197 distinct UD keys; ~70 defined outside `allUserdefaults.swift`) |
| `DispatchQueue.global().sync {}` (anti-pattern) | 51 |
| `Timer` scheduling sites | ~385 |
| `print(` statements / `addLog(` calls / os_log | 830 / 2,310 / 18 (three logging systems) |
| `DispatchQueue.main.asyncAfter` magic-delay hacks | 25 |
| Classes with lowercase names | 266 |
| Commented-out code (code-shaped comment lines) | ~1,400+ |

---

## P0 — Security & privacy

| # | Finding | Where | Detail |
|---|---|---|---|
| P0-1 | ~~**Access tokens logged in plaintext**~~ — fixed | `log.swift` `addLog` | The last four `accessToken is:-` lines are gone, and every line now passes through `LogRedactor` (JWTs, `Bearer`, token/password fields, emails). Logs written before the fix are rewritten once at launch (`LegacyLogScrubber`), and report extracts are redacted again on the way out. |
| P0-2 | **Notarization credentials committed** | `DMG/build.sh:9`, `pkg/2build.sh:20` | Apple ID (personal gmail) + app-specific password in plaintext in two scripts. Rotate the password and move to env vars / CI secrets. (Already flagged in CLAUDE.md.) |
| P0-3 | **Sentry `sendDefaultPii = true`** with `debug = true` in release | `AppDelegate.swift:189-193` | PII shipped to Sentry; debug logging on in production builds. |

## P1 — Correctness bugs & crash risk

| # | Finding | Where | Detail |
|---|---|---|---|
| P1-1 | **`days_of_week` Sunday bug (×3 copies)** | `Routine/routineData.swift:396/400`, `:554/558`, `:960/964` | Weekday/weekend checks test `"sat"` twice instead of `"sat"`/`"sun"`: `!contains("sat") && !contains("sat")` and `contains("sat") \|\| contains("sat")`. Net effect: "weekdays" routines incorrectly run on Sundays; "weekend" routines never run on Sundays. Verified present at all three copy-pasted sites. |
| P1-2 | **Firefox block page hardcodes port 50501** | `FirefoxExtension/.../background.js:6`; also `globalFile.swift:3203` (`defaultAllowedUrl`) | The Flask server falls back to the first free port ≥ 50501 (`flaskServer.swift:49`), but the extension's block-page URL and the allowlist entry are hardcoded — if the port shifts, Firefox blocking shows a dead page. |
| P1-3 | **Vestigial `/check_url` never blocks** | `firefoxHttpServer.swift:117` | `let blocked = false` hardcoded; the endpoint the extension calls per-URL is a no-op, all blocking rides the 1 s `/push` poll. Either implement or remove. |
| P1-4 | **Dead WebSocket client retries forever** | `FirefoxExtension/.../background.js:18-56` | Extension tries `ws://127.0.0.1:50502` every 2 s; the Swift side is plain HTTP (Swifter) with no WS upgrade — it can never connect. |
| P1-5 | **Force-unwrap density on optional globals** | ~2,850 sites; every `get*VcObject()` getter (`getViewControllersObject.swift`, 225 `instantiateController` sites) | `appdelegate!.credential!.accessToken`, `activityCompletionVcObj!.view`, `return xVcObj!` after `as?`. A storyboard-ID typo or nil-during-transition is a hard crash. Highest-risk clusters: AllApi, AppDelegate, habitsVc. |
| P1-6 | **`DispatchQueue.global().sync` (51 sites), incl. timer creation** | e.g. `AppDelegate.swift:1186, 1623…`; `timerViewcontroller.swift:1596`; `activityCompletionVc.swift:3448`; `habitsVc.swift:2717` | Blocks the calling thread to hop queues for no benefit; several wrap `RunLoop.main.add(timer:)`. Deadlock-adjacent and pointless — should be `DispatchQueue.main.async` or nothing. |
| P1-7 | **Blocking sleeps on UI paths** | `menuView/menuViewController.swift:1449` (`usleep(500000)`), `focusCompletedVc.swift:1261/1265`, `focusButtonService.swift:683` | 0.5 s and 50 ms spins on paths that touch menus/UI. |
| P1-8 | **Observers never removed; strong self captures** | `AppDelegate.swift` — 12× `addObserver`, 0× `removeObserver`; block observers at `:487-488, 563-576` without stored tokens | Leaks + double-fire risk if registration paths re-run. Only 6 `[weak self]` in 9,683 lines. |
| P1-9 | **`unusedCode.swift` contains ~200 lines of LIVE code** | `FocusBear/unusedCode.swift` (1,571 lines) | The "graveyard" file is mostly comments but has live top-level declarations (e.g. `@objc func topIconClickd()` ~line 1131). Extract the live bits, delete the rest. |
| P1-10 | **`NSUserNotification` (deprecated since macOS 11)** | `globalFile.swift:1481-1485` | Migrate to `UserNotifications`. |

## P2 — Duplication & structure (plan as refactors)

| # | Finding | Where | Detail |
|---|---|---|---|
| P2-1 | **`thirdVc.swift` = 4,500-line dead byte-duplicate** | `Routine/thirdVc.swift` vs `activityCompletionVc.swift` | Verified: diff is 12 lines (class/extension names only); zero references, no storyboard entry. **Delete the file** — cheapest 4,500-line win in the repo. |
| P2-2 | **Morning/evening/custom routine function families copy-pasted** | `activityCompletionVc.swift` (`*HabitFinished` ×4, `*HabitSkipped` ×4, `*SkippedAndDoneAlready` ×4), `habitsVc.swift` (3 postpone fns ~130 lines each; 3 `startDirectIncomplete*HabitAtIndex`) | Parallel copies differing only in state/keys. This is where P1-1-style copy-paste bugs breed. Unify around a routine-kind parameter. |
| P2-3 | **Three parallel 1 s browser-polling engines** | `focusTimerManager.swift:50`, `focusHabitTimerManager.swift:50`, `suggestWorkFocusManager.swift:21`, + `AppDelegate.blockUrlsInBackground` (~:8184) | ~600-line near-duplicates incl. duplicated `urlInvalidCloseEveryThing()`. Any URL-classification change must land in several places. |
| P2-4 | **`pomodoroVc` vs `simplePomodoroVc`** | `Pomodoro mode/` (1,765 vs 1,437 lines) | Substantially overlapping, genuinely diverged — riskier merge than P2-1/2 but still one feature in two copies. |
| P2-5 | **God files** | `AppDelegate.swift` 9,683 · `AllApi.swift` 6,842 · `activityCompletionVc` 4,500 · `habitsVc` 3,851 · `ScheduleViewController` 3,430 · `globalFile.swift` 3,231 · `focusModeData.swift` 2,976 · `menuViewController` 2,877 · `DayPlanTasks.swift` 2,408 | AppDelegate alone contains auth, the focus-mode engine, sleep/wake, status bar, subscription, meetings, blocking. Extract by subsystem before feature work compounds it. |
| P2-6 | **Global-singleton architecture** | `getViewControllersObject.swift` (~200 VC singletons), `globalFile.swift` (~190 globals), `routineData.swift` module globals | No ownership, no DI, screens never deallocate, state mutated from everywhere. Long-term direction, not a quick fix; new code should at least avoid adding globals. |
| P2-7 | **API layer: no Codable, no typed errors, callback pyramids** | `AllApi.swift` throughout | 73 dataTask sites × ~90 lines of boilerplate; success codes vary per endpoint (200/201/204/2xx); failures flattened to `completionHandler(nil, 0)`; `NSDictionary` parsing. Introduce a typed request helper + Codable models incrementally. |
| P2-8 | **Settings state fragmented across three stores** | `SettingsManager` (+plist), raw UserDefaults (~197 keys, ~70 uncentralized, inconsistent `kUserdefaults`/`kUserDefaults` casing), globals | See ARCHITECTURE.md §8.3. At minimum: centralize key constants. |
| P2-9 | **i18n bypassed by SwiftUI + hardcoded strings; English fallbacks duplicated inline in ~150 files** | e.g. `helpVc.swift:447`, `settingsSideBarVc.swift:60`, DayPlan labels | No `NSLocalizedString` at all; remote-config lookups with per-call-site fallbacks. New SwiftUI surfaces mostly hardcode English. |
| P2-10 | **UI state inferred by subview inspection** | `AppDelegate.swift:2683/2725/2795/4920`, `selectJsonVc.swift:581`, `habitsVc.swift:431/612/621` | `habitsView.subviews.contains(xVcObj!.view)` as a state query. Replace with an explicit current-screen variable. |
| P2-11 | **View swapping without child-VC containment** | `ViewController.swift:335-582`, `settingsContainerVc.swift:82-228`, `habitsVc` | `addSubview`/`removeFromSuperview` only; lifecycle callbacks unreliable; schedule VC held via `objc_setAssociatedObject` (`firstViewController+Schedule.swift:18-20`). |
| P2-12 | **Browser name-mapping copy-pasted ≥7×; magic enum raw values** | `allBrowsers.swift:41-67, 113-139, 215-237, 283-305, 335-357, 489-507, 559-578, 669-692`; `enum BROWSER` raw values start at 152 | Plus `arrBrowsersLowerCasedNames` carries a "must also change in onboarding" manual-sync warning. |
| P2-13 | **Two local HTTP server stacks** | Swifter (`firefoxHttpServer.swift`, :50502) + PyInstaller Flask (`flaskServer.swift`, :50501) | Two runtimes serving local HTTP; the Flask side is a 2×12 MB committed binary rebuildable only by one named developer (`flaskServer.swift:13-28`) — bus factor + Rosetta dependency on arm64. Consolidating onto the Swift server would delete the Python toolchain entirely. |
| P2-14 | **Test coverage gaps** | `FocusBearTests/` | Only pure blocking/URL/ScheduleKit logic tested. Nothing for `DayPlanTaskStore` (persistence/rollover), `CalendarManager`, `DayPlanSync`, routine state machine, postpone logic, or any UI. And CI runs only 3 of the 4 real suites — **`ScheduleKitTests` is not in `unit-tests.yml`** (one-line fix). |

## P3 — Build, dependencies & hygiene

| # | Finding | Where | Detail |
|---|---|---|---|
| P3-1 | **Git repo bloat: 1.1 GB `.git`** | `pkg/files/…/LateNoMore` (~44 MB unrelated app!), `DMG/Focus Bear1.16.316.dmg` (34 MB), `DMG/Archive.zip` (23 MB), full built app bundles under `DMG/` & `pkg/files/`, 10 MB gif, 6 MB mp4s | Remove built artifacts from the tree; consider history rewrite when convenient. |
| P3-2 | **Auth0.swift pinned to `master` branch** | `Package.resolved` | Non-reproducible builds. Pin a release tag. |
| P3-3 | **Abandoned dependencies** | swifter 1.5.0 (2019), TrueTime 5.0.3 (~2019), NWWebSocket 0.5.4, TweetNacl 1.0.2 | No upstream fixes coming; TweetNacl is the cause of the Xcode 26 `SWIFT_ENABLE_EXPLICIT_MODULES = NO` hack (`Podfile:14-24`, duplicated in CI). |
| P3-4 | **CocoaPods + SPM split** | `Podfile` / `Package.resolved` | Two package managers; migrate pods to SPM over time. |
| P3-5 | **Min-OS declared three ways** | pbxproj `MACOSX_DEPLOYMENT_TARGET = 11` vs `Podfile:2` `10.15` vs appcast `minimumSystemVersion 10.15` | Align on 11 (Auth0/TweetNacl need it). |
| P3-6 | **Signing identity inconsistency + personal profiles** | `Config/Signing-Release.xcconfig` (org identity) vs `DMG/build.sh`/`pkg/2build.sh` (personal "Jeremy Nagel" identity); `FBHelper-Release.xcconfig` profile `FocusBearHelperPersonalAcProfilePrashant` | Release paths sign with different identities; helper profile tied to a former dev's personal account. |
| P3-7 | **Legacy bundle id** | `com.App.EarnYourScreentime` (`project.pbxproj`) | Also used as the DistributedNotificationCenter object string for FBHelper IPC — renaming requires coordinated change. |
| P3-8 | **Stale packaging files** | `pkg/postinstall` (opens nonexistent `/Applications/CLA.app`), `pkg/preinstall` (macOS 12-only gate), `pkg/preinstall copy`, `update_builds/` (Sparkle 1.26 notes, `/Users/prashant/...` paths) | Delete or fix. |
| P3-9 | **No release CI** | `.github/workflows/` | DMG/PKG/notarize entirely manual; combined with P0-2 this is the riskiest ops gap. |
| P3-10 | **Logging chaos** | 830 `print` + 2,310 `addLog` + 18 os_log; `addLog(text:)// remove this` markers ×8 in `activityCompletionVc.swift`; launch-path font enumeration printing every installed font (`AppDelegate.swift:244-253`) | Pick one logging path (os_log/Logger with levels); kill the launch print loop. |
| P3-11 | **Naming conventions** | 266 lowercase class names, mixed `Vc`/`VC`/`ViewController` suffixes, typos (`cickableBackgroundView`), positional names (`thirdVc`, `firstViewController`) | Rename opportunistically when files get touched; don't mass-rename in one PR. |
| P3-12 | **Commented-out code & dead flags** | ~1,400 code-shaped comment lines; `routineData.swift:309` computes `statusLowerCased` then never uses it; commented legacy Firefox AppleScript (`allBrowsers.swift:833-888`) | Delete on contact. |
| P3-13 | **Hardcoded infra values** | Pusher key (`pusherEvents.swift:21`), Sentry DSN (`AppDelegate.swift:188`), Auth0 client id/domain (`Auth0.plist` — a `dev-` tenant serving prod), `baseUrl` with alt URL in a comment, PostHog URL (`AllApi.swift:437`), test-user flag read from `~/Desktop/is_fb_test_user.txt` (`AppDelegate.swift:292`) | These are publishable client-side values (not secrets) but there's no environment abstraction at all. |
| P3-14 | **Stringly-typed offline replay** | `AllApi.swift:1709…` CSV append + `syncOfflineDataApi` (:2017) | Failed activity posts serialized to CSV by string concatenation, no schema/versioning. |
| P3-15 | **`DispatchQueue.main.asyncAfter` timing hacks (25)** | e.g. `ViewController.swift:820/839/850`, `AppDelegate.swift:1337` | Magic 0.2–2 s delays papering over ordering races. |

---

## P1-15 — Relevance freshness still blocks the main thread on AppleScript

`urlRelevanceTargetIsCurrent` (`FocusBear/Focus mode/focusModeData.swift`) re-reads the active tab's
URL and title before applying an AI relevance verdict. Each read is a **blocking AppleScript
round-trip on the main thread, capped at 1.2s**, so a verdict can freeze the UI for up to 2.4s. This
is a beachball users report.

Two of the four have been removed: the reads are lazy (they only run once the cheap frontmost check
has passed) and, as of 2026-09-17, memoised (`memoisedRead`), so the diagnostics line no longer
re-reads what the decision already read. **The remaining two are still synchronous and still on
main.**

The likely fix is a short-TTL cache rather than an async refactor. `checkInBackground` already reads
the active tab URL roughly **once a second**, so a cache of the last successful read — written by
whichever caller performed it — would make the verdict path a cache hit almost every time and cost
no AppleScript at all.

The design question to settle first, because it is a real trade-off and not a detail: the re-read
exists to prove the user has not navigated away since the check began. A reading up to ~1s old
mostly answers that (and `currentUrlRelevanceKey == key` already proves no newer check started), but
it does weaken the guarantee in exactly the case the code was written for. Decide the TTL
deliberately and test the boundary; do not bolt a cache on without it.

---

## Suggested attack order (highest value ÷ risk first)

1. **P0-1 / P0-2 / P0-3** — stop logging tokens, rotate & externalize notarization creds, turn off Sentry PII/debug. Hours of work, real exposure.
2. **P2-1** — delete `thirdVc.swift` (verified dead).
3. **P1-1** — fix the Sunday `days_of_week` bug in one shared helper (kills 3 copies), and add a unit test.
4. **P2-14 (CI part)** — add `ScheduleKitTests` to `unit-tests.yml`.
5. **P1-2 / P1-3 / P1-4** — Firefox bridge port + vestigial code.
6. **P1-9 + P3-12** — dissolve `unusedCode.swift`, delete commented-out code on contact.
7. **P2-2 / P2-3** — unify the routine transition/postpone families and the polling engines (do this *before* the next feature touches them).
8. Then the long arcs: AllApi modernization (P2-7), settings-key centralization (P2-8), AppDelegate decomposition (P2-5), repo slimming (P3-1).
