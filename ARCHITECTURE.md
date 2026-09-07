# Focus Bear macOS App — Architecture

A map of how this codebase actually works, written for developers (human or AI) landing in it cold.
Build/signing/release mechanics are covered in [`CLAUDE.md`](CLAUDE.md) and [`README.md`](README.md) — this
document covers **structure, data flow, and the patterns you must understand before changing anything**.
Known problems are catalogued separately in [`TECH_DEBT.md`](TECH_DEBT.md).

Line numbers below are anchors, not contracts — they drift as the code changes. Function and type names
are the stable references.

---

## 1. What the app is

Focus Bear is a productivity/ADHD-support app. On macOS it does four big things:

1. **Routine player** — walks the user through morning/evening/custom habit routines in a kiosk-style
   borderless full-screen window ("you can't escape your habits").
2. **Focus mode & blocking** — blocks distracting apps and websites during focus sessions, pomodoro
   sessions, and scheduled blocking windows. Browser blocking works by reading the active tab via
   AppleScript every second and redirecting blocked tabs to a locally-served block page.
3. **Day Plan / Schedule** — a generated timeline of the user's day (routines + calendar meetings +
   derived deep-work blocks) with a local task list.
4. **Cross-device sync** — REST API (`api.focusbear.io`) + Pusher realtime so actions on mobile/web
   reflect on the Mac.

**Tech stack:** Swift 5 / AppKit, storyboards for most UI, SwiftUI for newer surfaces
(hosted via `NSHostingView`/`NSHostingController`), CocoaPods + SPM, Sparkle auto-update, an embedded
PyInstaller **Flask** binary, an embedded **Swifter** HTTP server, a Firefox WebExtension, and an
optional ESP32 hardware "Focus Button" over USB serial. Deployment target macOS 11. ~136k lines of
Swift across ~300 files.

**Targets** (always build the workspace, scheme `Focus Bear` — see CLAUDE.md):
- `Focus Bear` — the main app. Bundle id `com.App.EarnYourScreentime` (legacy, pre-rename).
- `FBHelper` — a second full `.app` (LSUIElement) bundled inside the main app; login-item /
  keep-alive / nudge helper. See §10.
- `Focus BearTests` — XCTest bundle. See §12.

---

## 2. The three patterns you must internalize first

Almost every confusing thing in this codebase traces back to one of these.

### 2.1 Global singletons for everything

There is **no dependency injection and no ownership hierarchy**. Every view controller, window
controller, service, and most mutable state is a top-level global.

- `FocusBear/getViewControllersObject.swift` (~2,100 lines) holds **~200 VC/WC singletons**. The
  pattern is: a top-level `var xVcObj: xVc?` plus `func getXVcObject() -> xVc` that lazily
  instantiates from a storyboard and force-unwraps. A handful of core ones are **eagerly** created at
  process launch: `mainWindowControllerObj`, `mainViewControllerObj`, `firstViewControllerObj`,
  `timerViewcontrollerObj`, `menuViewControllerObj`, `activityCompletionVcObj`.
- `FocusBear/globalFile.swift` (~3,200 lines) holds ~190 top-level mutable globals and ~140 free
  functions: config, user identity, the app state machine, blocking helpers, sounds, time utilities,
  LaunchAgent management, the AppleScript serial executor.
- `appdelegate` (a global in globalFile.swift) is `NSApplication.shared.delegate as? AppDelegate` —
  code everywhere calls `appdelegate!.someMethod()`.

**Class-name traps** (repeated from CLAUDE.md because they bite constantly): `mainViewControllerObj`
is a `ViewController`; `firstViewControllerObj` is a `firstViewController` (the pre-routine habit
list + Day Plan host); `habitsVcObj` is a `habitsVc` (the routine-player container). Class names are
lowercase (`habitsVc`, `thirdVc`) and don't match their roles — grep for the *global variable name*,
not the concept.

### 2.2 One global state machine

`enum CURRENTSTATE` + `var currentState` (globalFile.swift, ~line 413/441) drives the whole app:
`_NOTHING_`, `_MORNING_HABIT_`, `_EVENING_HABIT_`, `_MICRO_BREAK_`, `_CUSTOM_ROUTINE_`,
`_POSTPONE_MORNING_HABIT_`, `_ONBOARDING_`, `_LOGIN_`, etc. `currentState` has a large `didSet`
observer that re-derives postpone state, resets flags, pokes the left menu, and schedules Day-Plan
refreshes. Alongside the enum there are ~10 free-floating `Bool` globals in
`Routine/routineData.swift` (e.g. `isCustomRoutineWasRunningInPostponeMorningHabit`) that encode
sub-state and are reconciled by hand — when routine behaviour looks wrong, check both the enum *and*
these flags.

“Is a routine active / postponed / between routines” is **derived** from time-window math over
`startTime`/`endTime`/`nextSheduledTime`/`days_of_week` (`checkCustomRoutineTime`,
`getListCustomRoutineTime`, `getNextRoutineInfo` in routineData.swift) — it is not stored anywhere.

### 2.3 View swapping by `addSubview`, state read by subview inspection

There is no navigation stack and (mostly) no child-VC containment. Screens change by
`removeSubViews()` + `containerView.addSubview(getXVcObject().view)` + manual constraints:

- `ViewController` (main window content) swaps top-level surfaces this way.
- `habitsVc.habitsView` swaps routine-player screens this way.
- `settingsContainerVc` swaps ~25 preference panes this way.

Consequently, **“which screen is showing” is often determined by inspecting subviews**, e.g.
`getHabitsVcObject().habitsView.subviews.contains(activityCompletionVcObj!.view)` (AppDelegate and
others). If you add/replace a screen, code elsewhere that infers state this way can break silently.
Also: because there is no `addChild`, `viewWillAppear`-style lifecycle callbacks are unreliable.

---

## 3. Startup sequence

Almost everything happens in `AppDelegate.applicationWillFinishLaunching` (yes, *WillFinish*, ~line
186), in roughly this order:

1. Sentry init → splash window → UUID/Stage Manager checks.
2. Custom font registration (OpenDyslexic, IntelOne Mono, Poppins, Lexend).
3. TrueTime NTP client start (anti clock-tampering, see §11) and Sparkle updater init.
4. Application Support directories + CSV/plist file-URL globals created.
5. **Flask block-page server** and **Firefox HTTP bridge** started (§7.3, §7.4).
6. Dock icon policy, global hotkeys, and the `NSStatusItem` menu-bar UI built.
7. `allApiObject.getConfigFile(...)` downloads the remote i18n/config JSON (§9); its completion
   registers the workspace/sleep/wake/lock observers and branches on auth state: first-run →
   welcome; logged out → login window; else `loadCredentialsAndDeviceId()` → Auth0 credentials →
   settings fetch → routines built.

`applicationDidFinishLaunching` (~line 1321) is comparatively empty (WiFi monitor, Focus Button
command channel, DEBUG hooks). `applicationShouldTerminate` intercepts quit for the
quit-confirmation/friction flow; `applicationWillTerminate` stops the local servers and flushes
buffers.

**Implication:** app behaviour before the config-file completion runs is different from after —
observers and auth-dependent state don't exist yet. Race-looking bugs at launch usually trace here.

---

## 4. Window architecture

- One **main window** (`mainWindowController` / global `mainWindowControllerObj`), content is
  `ViewController` (`mainViewControllerObj`), which swaps surfaces into its `containerView` (§2.3).
- **Borderless full-screen mode** is Focus Bear's own kiosk mode, *not* macOS native full screen:
  `mainWindowController.showFullSizeWindow()` sets `styleMask = [.borderless, .resizable]`,
  `.canJoinAllSpaces`, `canHide = false`; `showSmallSizeWindow()` flips back to titled.
  Branch on `checkIsFullScreenEnabled()` (globalFile.swift); live state is
  `mainWindowControllerObj?.isFullScreenVisible`.
  ⚠️ Borderless full-screen breaks `defaultButtonCell` suppression — the Return key reaches the
  routine's "Start" button unless text views guard it themselves (see CLAUDE.md "Architecture
  gotchas" and `EditOnClickTextField` / `NewlineKeepingTextView` in `Schedule/DayPlanTasks.swift`).
- **Secondary monitors** are blacked out during routines by per-screen borderless windows
  (`showBlankWindowInSecondaryMonitor`, showHideWindows.swift).
- **`showHideWindows.swift`** (~1,400 lines) is the central window orchestration layer: ~90 free
  `showX()` / `closeXIfVisible()` functions for every transient window (block popups, break
  warnings, brain dump, splash, floating top bar…). All of them reach into the `*VcObj`/`*WcObj`
  globals. When a popup misbehaves, start here.
- The **menu-bar UI** is an `NSStatusItem` whose click opens either an `NSPopover` or a detached
  window depending on `SettingsManagerObject.isMenuPopoverEnabled`. The status button doubles as a
  live focus-state indicator (color/title mutated from many AppDelegate sites). The menu content is
  `menuViewController` with a SwiftUI `FocusBearMenuView` (menuView/MenuView.swift) overlaid on it.

---

## 5. Routine player (`FocusBear/Routine/`)

The feature that runs morning/evening/custom habit routines.

**Cast of characters:**

| Global | Class | Role |
|---|---|---|
| `habitsVcObj` | `habitsVc` (~3,850 lines) | Container/orchestrator. Owns `habitsView` (screens swap into it), all postpone logic + timers, break scheduling, the time-of-day clock, routine start functions. |
| `firstViewControllerObj` | `firstViewController` | Pre-start habit list; the `ScheduleHost` that owns the Day Plan tab (`isScheduleTabSelected`, `updateScheduleTabForState`). |
| `timerViewcontrollerObj` | `timerViewcontroller` (~2,300 lines) | The per-habit player: countdown timer, embedded video/instruction webviews. `startTimerHabit(...)` / `startTimerActivity(...)`. |
| `activityCompletionVcObj` | `activityCompletionVc` (~4,500 lines) | Post-habit completion screen: progress, graphs, auto-advance countdown, and the per-routine `*HabitFinished` / `*HabitSkipped` transition functions. |
| — | `thirdVc` | **Dead code.** A byte-identical copy of `activityCompletionVc` (only the class name differs), never instantiated. Do not edit it; it should be deleted (see TECH_DEBT.md). |
| `routinePostponedInfoVcObj` | `routinePostponedInfoVc` | Shown while a routine is postponed; hosts its own Day Plan copy. |
| `habitsStateVcObj` | `habitsStateVc` | Between-routines screen ("next routine at X"); hosts a Day Plan copy. |

**Flow:** `startCustomRoutine(index:isOnDemand:)` (routineData.swift) — or the morning/evening
equivalents in AppDelegate — sets `currentState`, shows the main window (full-screen), and calls
`getHabitsVcObject().showRoutineAllHabits(...)`. Server progress is reconciled via
`GET /user/details/current-activity-props` (`getLastActivityInfo`) → the resume index is computed →
`timerViewcontroller` is swapped in per habit → on completion `activityCompletionVc` runs the
matching `*HabitFinished(index:)` and advances or ends. Completion/skip post to
`POST /completed-activity` / `POST /completed-activity/skip`, with offline fallback to CSV replay
(§8.1).

**Data model** (routineData.swift): `struct routine` and `struct habit` (~30 fields, mostly
implicitly-unwrapped optionals). State lives in module-level globals: `arrAllCustomRoutine`,
`arrAllDaysMorningHabits`/`arrAllDaysEveningHabits`, `arrFilteredMorningHabits`/`arrFilteredEveningHabits`
(their `didSet`s trigger coalesced Day-Plan refreshes), plus playback cursors `currentHabitIndex`,
`currentHabitPlaying`, etc. These are mutated from AppDelegate, habitsVc, activityCompletionVc, and
routineData functions alike — there is no single owner.

**Important routine-player facts:**
- The morning / evening / custom-routine code paths are **parallel near-duplicate function families**
  (`morningHabitFinished` / `eveningHabitFinished` / `customRoutineHabitFinished`, three ~130-line
  postpone functions, three `startDirectIncomplete*HabitAtIndex`). A fix in one usually needs the
  same fix in the siblings.
- Postpone state survives restart via `kUserDefaultsLastRoutinePostponeEndDate/State` and
  `restorePostponeStateIfNeeded()`.
- Per-habit progress-today is persisted under `kUserdefaultsHabitsDurationDoneToday`.
- The routine clock label (`habitsVc.lblCurrentDateTime`) must be hidden whenever a Day Plan is the
  front content — visibility is gated on `firstViewControllerObj?.isScheduleTabSelected`
  (see CLAUDE.md).

---

## 6. Focus mode, pomodoro & custom blocking schedules (`FocusBear/Focus mode/`, `Pomodoro mode/`)

**Focus mode is the core engine; the pomodoro screens are wrappers that start it.**

- State lives in `Focus mode/focusModeData.swift` (~3,000 lines of free functions + globals): focus
  modes are **untyped dictionaries** in the global `arrFocusType: [[String:Any]]`; the active one is
  `currentRunningFocusType`; `isFocusModeOn()` scans for `isOn == true`. Strictness is
  `FOCUSMODESTRICTNESS` (`_NORMAL_/_STRICT_/_SUPER_STRICT_`).
- All start paths (menu, `pomodoroVc`, `simplePomodoroVc`, hardware button) converge on
  `AppDelegate.setFocusModeTimer(hour:minute:)`, which arms two one-shot timers: `timerForFocusMode`
  (session end) and `timerForFocusModeEndNotification` (the pre-end warning).
- `pomodoroVc` (full work→break→habit cycle) and `simplePomodoroVc` (configure-once variant) are
  largely parallel copies of each other; the work↔break loop is driven by `focusCompletedVc`
  branching on `isFocusModeStartedFromPomodoroMode`.
- **Custom blocking schedules** (`customBlockingScheduleData.swift`): `struct customBlockingSchedule`
  (Codable; days-of-week, time window incl. cross-midnight, per-schedule strictness/AI flags), managed
  by `customBlockingScheduleManagerObj` with a serial `stateQueue`, persisted to a local JSON file +
  backend. Activation is checked opportunistically from ~9 AppDelegate call sites (there is no
  dedicated schedule timer); once active, enforcement rides the same polling path as focus mode.
- Stopping a session early goes through the friction gate `enterPasswordVc` (app password, or
  type-the-random-characters if none set). That window deliberately hides itself from screenshots.

---

## 7. Blocking enforcement (how blocking actually works)

Enforcement is **polling, not hooks**. Three layers:

### 7.1 App blocking
On every `NSWorkspace.didActivateApplicationNotification`, the frontmost app is classified. A
disallowed app is *hidden* (`runningApp.hide()` — not terminated) via `focusBlockUnwantedApp`
(focusModeData.swift) and a block popup is shown. AI-based classification and "cuddly" (soft) mode
gate this.

### 7.2 Browser URL blocking (AppleScript, 1-second poll)
When the front app is a browser, a 1 s timer starts. Each tick, `focusTimerManager.checkInBackground`
(Focus mode/focusTimerManager.swift) reads the active tab URL, classifies it (allowlist vs
blocklist), and if blocked runs an AppleScript that sets the tab URL to the local block page
(`blockWebUrlString?old_url=…`).

- Per-browser AppleScript lives in `allBrowsers.swift` (`enum BROWSER`: Chrome, Safari, Brave,
  Sidekick, Edge, Arc, Firefox, Opera, Vivaldi, Opera GX, SigmaOS).
- ⚠️ **All NSAppleScript must go through `runBrowserAppleScript` → `runAppleScriptSafely`**
  (globalFile.swift), which serializes every script onto one queue with a timeout. Concurrent
  NSAppleScript execution segfaulted inside Apple's AppleScript compiler; blocking AppleScript on the
  main thread caused the blank-Day-Plan/AppHang bug (PR #2009). Never call NSAppleScript directly.
- There are **three parallel copies** of the "poll the front tab every second" loop:
  `focusTimerManager` (focus mode + custom schedules), `focusHabitTimerManager` (habit/activity
  blocking during routines), and `suggestWorkFocusManager` — plus `AppDelegate.blockUrlsInBackground`.
  A URL-classification fix likely needs to land in more than one.

### 7.3 The block page: embedded Flask server (port 50501)
`FocusBear/server` (arm64… actually x86_64 — both binaries are x86_64 PyInstaller builds; arm64 Macs
run them under Rosetta) and `FocusBear/serverIntel` are ~12 MB committed binaries started by
`flaskServer.swift` at launch. The server serves `focus-block.html` (downloaded from the
`focus-bear.github.io` assets repo into Application Support) on `http://localhost:50501`, falling
back to the first free port ≥ 50501 (passed via the `PORT` env var; `blockWebUrlString` is updated
accordingly). "Blocking" a tab = redirecting it to this page. Rebuild with
`./scripts/build-flask-server.sh` (see CLAUDE.md; the binaries must stay mode 100755).

### 7.4 Firefox: WebExtension + Swifter bridge (port 50502)
Firefox doesn't expose tab URLs to AppleScript, so it has a dedicated path:
- `FirefoxExtension/focus-bear-blocker/` (MV2 extension, id `team@focusbear.io`) POSTs the active
  tab URL to `http://127.0.0.1:50502/check_url` and long-polls `POST /push` every second for
  block/unblock commands.
- The Swift side is `firefoxHttpServer.swift` (misleading header comment says "webSocketServer") — a
  **Swifter** `HttpServer` on port 50502. `getFirefoxActiveTabUrl()` in allBrowsers.swift just reads
  the last URL the extension pushed.
- ⚠️ Known trap: the extension's block-page URL is hardcoded to `localhost:50501` — if Flask fell
  back to another port, Firefox blocking shows a dead page. Also `/check_url` always answers
  "not blocked" (`let blocked = false`); real blocking flows through the `/push` queue only.

### 7.5 Focus Button (ESP32 hardware, USB serial)
`FocusButton/focusButtonService.swift` drives the physical button via ORSSerialPort (115200 8-N-1,
DTR/RTS deliberately deasserted so the ESP32 isn't held in reset). Text protocol:
`SET|START|<seconds>`, `SET|PAUSE`, `SET|CANCEL`, `STATUS`, … Button press starts focus mode.
`FocusButtonCommandChannel.swift` polls `~/.focusbear/focus-button-command` (1 s) so external tools
can ask the app to release the serial port for firmware flashing.

---

## 8. Networking, auth & persistence

### 8.1 API layer — `AllApi.swift` (~6,800 lines)
One god class (`allApiObject`) containing essentially every backend call (~150 methods), all raw
`URLSession.dataTask` + completion handlers (async/await is essentially unused). Each method
repeats the same shape: fetch Auth0 credentials → build request (`makeRequest` adds
`Authorization: Bearer`, `platform: mac-os`, `app-version`, `x-focus-bear-user-id`, `device-id`) →
dataTask → status-code switch → `JSONSerialization` into `NSDictionary` → completion. `Codable` is
used exactly once. Base URL is the mutable global `baseUrl = "https://api.focusbear.io"`
(AllApi.swift:10); there is no environment switching.

Offline handling: activity-logging calls that fail are appended to CSV files and replayed later by
`syncOfflineDataApi`. Connectivity via `Reachability` + `isInternetOn(...)`.

### 8.2 Auth (Auth0)
- Config in `FocusBear/Auth0/Auth0.plist` (tenant `dev-2hidr8ad.us.auth0.com`).
- Login is a Resource-Owner-Password grant from `Login/customLoginVc.swift` (realm
  `Username-Password-Authentication`, audience `https://auth.focusbear.io/api/v2/`).
- Tokens are stored by Auth0's `CredentialsManager` in the **Keychain** (never UserDefaults; only a
  `kUserdefaultsIsUserLoggedIn` flag lives there).
- Refresh: `AppDelegate.renewCredentialsIfNeeded` — hand-rolled throttle (once per 5 min, renew when
  expiry < 24 h away). Plus most API calls independently ask `credentialsManager.credentials {...}`
  before firing.
- `AuthUser` (Auth0/User.swift) decodes the access token JWT; user id and subscription status come
  from a custom-claims namespace (a legacy Render URL — don't "fix" the string, the backend really
  uses it).

### 8.3 Settings & persistence — a three-way split
State lives in **three places**; knowing which one owns a given value is half the battle:
1. **`SettingsManager`** (`SettingsManagerObject`, ~1,700 lines): ~100 stored properties (strictness,
   password-gate flags, shortcuts, blocked lists…). Synced with the backend via
   `/user-local-device-settings` (`getUserLocalDeviceSettings` / `putUserLocalDeviceSettings`) and
   persisted locally to a **plist file** (not UserDefaults).
2. **Raw `UserDefaults`** — ~197 distinct keys; constants mostly in `allUserdefaults.swift` but ~70
   keys are defined ad hoc elsewhere. Casing is inconsistent (`kUserdefaults…` vs `kUserDefaults…`).
3. **Top-level globals** in globalFile.swift (`configjson`, `currentDeviceId`, `isExpired`,
   `breakAfterMinutes`, `currentState`…) — runtime-only, set from server settings in AppDelegate.

### 8.4 Realtime (Pusher)
`pusherEvents.swift`: PusherSwift, per-user private channel `private-<userId>`, server-signed auth
via `<baseUrl>/pusher/user-auth`. Events handled: `focus-mode-started`, `focus-mode-finished`,
`activity-completed`, `settings-updated` — this is how a focus session started on mobile shows up on
the Mac.

---

## 9. i18n / remote config (`configjson`)

**There is no `Localizable.strings` and no `NSLocalizedString` anywhere.** All user-facing strings
come from a remote JSON downloaded at launch from the assets repo
(`https://focus-bear.github.io/assets/config/config[-es].json`) into the global `configjson`
NSDictionary. The lookup pattern is `configjson.value(forKey: "<sectionInfo>") as? NSDictionary`,
then per-key reads with a **hardcoded English fallback at each call site**. `ScheduleText`
(ScheduleViewController.swift) is the cleanest façade over this; most code does it inline.

**Adding a user-facing string requires three edits**: local `FocusBear/config.json`, and the assets
repo `config/config.json` + `config/config-es.json` (see CLAUDE.md "Day Plan / Schedule feature").
Never repurpose existing keys (Windows app shares them). Note most SwiftUI views currently bypass
this system entirely (hardcoded English) — that's registered debt, not a pattern to copy.

---

## 10. FBHelper (keep-alive helper app)

A tiny second app (`FBHelper/`, `LSUIElement`) copied into the main bundle and installed as a user
LaunchAgent (`~/Library/LaunchAgents/com.focusbear.focusbearhelper.plist`, written by
`createLaunchAgentForHelperApp()` in globalFile.swift, `KeepAlive=true`).

- **Purpose:** restart the main app if it's force-quit during a session, and show nag windows.
- **IPC:** `DistributedNotificationCenter` notifications (object string
  `"com.App.EarnYourScreentime"`) + a shared App Group `UserDefaults` (`sharedDefaults`). Key names
  are duplicated between `FBHelper/sharedFile.swift` and the main app — keep them in sync manually.
- The helper polls on two 10 s timers (nag logic; force-quit monitoring). The main app posts
  `mainAppQuitByUser` on legitimate quit so the helper doesn't resurrect it.

---

## 11. Day Plan / Schedule (`FocusBear/Schedule/`)

The newest major feature (PR #1935 lineage) and the only subsystem built with a clean core/UI split:

- **`ScheduleKit.swift`** — pure, AppKit-free timeline engine. `ScheduleBuilder.build(...)` takes
  routine segments (with time windows), calendar meetings, `now`, day end, leave-buffer, and pomodoro
  sprint config; packs habits into the free gaps of their routine window gap by gap
  (`placeHabitsInGaps`: within a gap the earliest habit in routine order that still fits goes next, so
  a shorter later habit fills the time before a meeting and the long one takes the first later gap;
  a habit that fits in no gap of the window becomes a "not enough time today" overflow row), inserts
  meeting blocks, and turns the free gaps left after habit placement (≥ 10 min) into deep-work
  blocks, optionally split into work/break sprints (`sprintWorkSeconds = breakAfterMinutes * 60`;
  `breakAfterMinutes` is a runtime global from server settings, default 0 — a ≤ 0 value yields
  un-split blocks). This is the **unit-tested** part (`ScheduleKitTests`).
- **`ScheduleViewController.swift`** (`scheduleViewController`, ~3,400 lines) — fully programmatic
  AppKit rendering (scroll view + stack view). Gathers inputs in `reloadLive()` via the
  `ScheduleTab` adapter enum, meetings from `CalendarManager`.
- **Hosting:** `firstViewController` conforms to `ScheduleHost`
  (`firstViewController+Schedule.swift`); the schedule VC is attached via
  `objc_setAssociatedObject`, not a stored property. Multiple hosts show Day Plan copies
  (`firstViewController`, `routinePostponedInfoVc`, `habitsStateVc`) — refresh must target
  *whichever host is visible*, not just `firstViewControllerObj`.
- **`DayPlanTasks.swift`** — `DayPlanTask` model + `DayPlanTaskStore` (UserDefaults key
  `dayPlanTasksByDay`, JSON keyed `yyyy-MM-dd`, daily rollover of incomplete tasks) + the entire
  tasks-panel UI (drag/drop, project grouping) in one file. CRUD mirrors to the backend via
  `DayPlanSync` (in CalendarManager.swift).
- **`CalendarManager.swift`** — EventKit wrapper: permission gating, `meetings(for:)` (declined
  events filtered), event create/update with recurrence, per-event colour/notes, dismissed-event
  tracking.

UI verification without seeing the window (the app usually lives on another Space): use the
offscreen render harness or `/tmp` diagnostics — see CLAUDE.md "Verifying UI without seeing the
window".

---

## 12. Preferences / Settings UI

Two generations coexist:
- Legacy monolithic storyboard panes: `focusPreferencesVc`, `focusPreferencesAdvancedVc`.
- Newer split-view: `settingsSplitViewController` = `settingsSideBarVc` (pane catalogue as dictionary
  arrays, separate "Geek" and "Simple" lists that must be kept in sync) + `settingsContainerVc`
  (~25 `show…View()` methods, subview swapping). Pane routing is a `switch` on string ids.
- Panes are instantiated from `Settings.storyboard`.
- **New/modified Mac UI should be SwiftUI** hosted in `NSHostingController` (team rule — see agent
  memory / CLAUDE.md). Current SwiftUI surfaces: Custom Blocking Schedules (the most complete
  example, under `Preferences/Settings/Custom Blocking Schedules/`), the menu redesign
  (`menuView/MenuView.swift`), break warning, evening shutdown, report-problem form, account
  conversion. Copy the Custom Blocking Schedules structure for new SwiftUI settings work.

---

## 13. Testing & CI

- `FocusBearTests/`: `AppBlockingTests`, `URLBlockingTests`, `validationTest` (URL wildcard
  matching), `ScheduleKitTests`. All pure-logic; there are no UI or persistence tests.
- CI (`.github/workflows/unit-tests.yml`) runs only the first three suites on PRs —
  **`ScheduleKitTests` is not run in CI** (debt).
- Release/notarization has **no CI**; it's manual scripts (`DMG/build.sh`, `pkg/*.sh`) — see
  CLAUDE.md, and note the hardcoded-credentials warning there.
- Other workflows: `claude.yml` (@claude mentions), `devin-on-label.yml`, `qa-evidence-check.yml`
  (hourly QA-evidence audit on the project board).

---

## 14. Ports, files & external touchpoints (quick reference)

| Thing | Value |
|---|---|
| REST API | `https://api.focusbear.io` (global `baseUrl`) |
| Config/i18n JSON | `https://focus-bear.github.io/assets/config/config[-es].json` |
| Block page source | `https://focus-bear.github.io/assets/focus-blocked/index.html` |
| Flask block-page server | `http://localhost:50501` (first free port ≥ 50501; `PORT` env var) |
| Firefox bridge (Swifter) | `http://127.0.0.1:50502` (`/check_url`, `/push`) |
| Pusher | cluster `mt1`, channel `private-<userId>`, auth `<baseUrl>/pusher/user-auth` |
| Sparkle feed | `https://downloads.focusbear.io/update/mac/new/latest-version.xml` |
| Day Plan tasks | UserDefaults `dayPlanTasksByDay` |
| Postpone restore | `kUserDefaultsLastRoutinePostponeEndDate/State` |
| Helper LaunchAgent | `~/Library/LaunchAgents/com.focusbear.focusbearhelper.plist` |
| Focus Button channel | `~/.focusbear/focus-button-command` / `focus-button-status` |
| Debug-report tasks | `~/FocusBear-Claude-Tasks/` (see CLAUDE.md workflow) |
| To-do API | `GET /to-do?...&sort_mode=SMART` (see CLAUDE.md) |

---

## 15. Rules of thumb when changing this codebase

1. **Grep for siblings.** Morning/evening/custom routine functions, the three URL-polling managers,
   and the pomodoro VCs are parallel copies — a fix usually has 2–3 more homes. (And never edit
   `thirdVc.swift`.)
2. **Never run NSAppleScript directly** — always via `runAppleScriptSafely` / `runBrowserAppleScript`.
3. **Don't trust SourceKit diagnostics for cross-file symbols** — trust `xcodebuild`
   (see CLAUDE.md).
4. **New UI in SwiftUI**, hosted via `NSHostingController`; follow the Custom Blocking Schedules
   example.
5. **Every new user-facing string goes through `configjson`** (three files: local config.json +
   assets repo en/es). Never hardcode English; never repurpose existing keys.
6. **Check both `currentState` and the routine boolean flags** when diagnosing state bugs, and
   remember screen-visibility is often inferred from subviews.
7. **Watch the Return key** in anything shown inside the borderless full-screen window.
8. **Reuse one `-derivedDataPath`** for compile checks (each is ~1 GB — see agent memory).
9. **Force-unwrapped globals crash for real.** When touching `get*VcObject()` getters or storyboard
   identifiers, a typo is a runtime crash, not a compile error.
10. Before "cleaning up" anything odd, check [`TECH_DEBT.md`](TECH_DEBT.md) — it may already be
    catalogued, sometimes with a reason it's still there.
