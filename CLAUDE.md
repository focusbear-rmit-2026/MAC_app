# Focus Bear — macOS App: build & dev notes for Claude

Knowledge accumulated while working on this repo so future sessions don't re-derive it.

## Building

- **Workspace, not project:** always build via `FocusBear.xcworkspace` (it pulls in Pods + SPM).
- **Scheme name is `Focus Bear`** (with a space), NOT `FocusBear`. Common mistake:
  `error: The workspace ... does not contain a scheme named "FocusBear"`.
- Canonical Debug build:
  ```bash
  xcodebuild -workspace FocusBear.xcworkspace -scheme "Focus Bear" \
    -configuration Debug -derivedDataPath build 2>&1 \
    | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
  ```
- Built app lands at `build/Build/Products/Debug/Focus Bear.app`.
- Relaunch: `killall "Focus Bear"; open "build/Build/Products/Debug/Focus Bear.app"`.
- SPM deps: ORSSerialPort, Auth0/JWTDecode/SimpleKeychain, Swifter, NWWebSocket, PusherSwift, Sentry, TrueTime, TweetNacl.
- SourceKit live-diagnostics in the editor often show false "Cannot find type X in scope"
  across files in the same target (e.g. `ScheduleBuilder`, `ScheduleText`). These are NOT
  build errors — trust `xcodebuild`, not the inline diagnostics, for cross-file symbols.

## Code signing & permissions (Debug)

- A stable cert keeps TCC (calendar) permission grants persistent across rebuilds. Use
  `Apple Development: Jeremy Nagel` via gitignored `Config/Local.xcconfig`.
- `ENABLE_HARDENED_RUNTIME` MUST be `NO` for Debug configs in `project.pbxproj`. Hardened
  runtime blocks the TCC calendar prompt — symptom: "Grant access did nothing" / no prompt.
  (Ad-hoc signing also silently disables it.) Verify with `granted=true, status=3`.

## Signed / release build (Developer ID + notarized DMG)

Signing config lives in **`Config/*.xcconfig`** (not `project.pbxproj`), layered per target:
- `Config/Signing-Release.xcconfig` — `Developer ID Application: Focus Bear Pty Ltd (TCUD568B3U)`,
  `DEVELOPMENT_TEAM = TCUD568B3U`, `CODE_SIGN_STYLE = Manual`, set for `[sdk=macosx*]`.
- `Config/Signing-Debug.xcconfig` — identity `-` (ad-hoc, "Sign to Run Locally"); no certs needed.
  `#include? "Local.xcconfig"` lets a dev pin a stable cert (see Debug section above). `Local.xcconfig`
  is gitignored; template at `Config/Local.xcconfig.example`.
- Per-target: `FocusBear-Release.xcconfig` / `FBHelper-Release.xcconfig` include `Signing-Release` +
  their provisioning profiles (`FocusBearMainAppProfile`, `FocusBearHelperPersonalAcProfilePrashant`).

**Schemes:** both `Focus Bear` and `FBHelper` Run actions are **Debug** (so local builds need no
Developer-ID); Archive/Profile stay Release. Don't flip Run back to Release — it reintroduces the
"Embedded binary is not signed with the same certificate" failure locally.

**Entitlements:** main app `Focus Bear.entitlements` = `com.apple.security.automation.apple-events`
(AppleScript for website blocking). `FBHelper/FBHelper.entitlements` = empty (it's an `LSUIElement`
login-item/nudge helper, copied into the app bundle). The embedded Flask server uses
`com.apple.security.cs.disable-library-validation` so PyInstaller deps load under hardened runtime.

**Sparkle auto-update (2.7.0):** `Sparkle.framework` is **not committed** — fetch with
`./scripts/fetch-sparkle.sh` (downloads the official signed 2.7.0, SHA256-verified, to repo root).
`import Sparkle` uses the 2.x API (`SPUStandardUpdaterController`). `FocusBear/Info.plist` holds
`SUFeedURL = https://downloads.focusbear.io/update/mac/new/latest-version.xml` and the public
`SUPublicEDKey` (Ed25519). The appcast + `sign_update` happen server-side at downloads.focusbear.io,
not in this repo (no private key here).

**Release / notarize flow:** Xcode → Archive → Organizer → Distribute (Direct Distribution); then
DMG via `DMG/build.sh` which `codesign`s with Developer ID, `xcrun notarytool submit --wait`,
`xcrun stapler staple`, and `spctl --assess`. (`pkg/1build.sh`/`2build.sh` build the "Late No More"
`.pkg` variant with `Developer ID Installer`.) ⚠️ **Security debt:** `DMG/build.sh` and `pkg/2build.sh`
currently hardcode the Apple ID + app-specific notarization password — move these to env vars / CI
secrets before relying on them; do NOT copy the secrets into committed files or docs.

**Embedded Flask server:** `FocusBear/server` + `FocusBear/serverIntel` are x86_64 PyInstaller
binaries (arm64 app runs them under Rosetta). Rebuild reproducibly with
`./scripts/build-flask-server.sh ["Developer ID Application: …"]` (ad-hoc if no identity arg).
Gotchas already fixed: they MUST be committed mode `100755` (non-exec → `Process.run` ENOENT), and
the port is dynamic — `flaskServer.swift` picks the first free port ≥ 50501 and passes it via the
`PORT` env var (`server.py` reads it). Committed binaries are ad-hoc signed — re-sign for release.

**Xcode 26 build gotcha:** `SWIFT_ENABLE_EXPLICIT_MODULES = NO` (set in project AND the `Podfile`
`post_install` for all pod targets). Xcode 26's explicit modules can't resolve pods' C deps — symptom
`Unable to find module dependency: 'CTweetNacl'`. Also: deployment target is **macOS 11** (Auth0 /
TweetNacl need it); the Pods `*-frameworks.sh` embed scripts must keep their executable bit. More
detail in `README.md` and `docs/local-development-setup-v2.md`. Build fixes live on branch
`chore/build-fixes-xcode26`.

## Architecture gotchas (globals, full-screen, Return key)

- **View controllers are global singletons** in `getViewControllersObject.swift`. Easy to confuse:
  `mainViewControllerObj` is a `ViewController`; `firstViewControllerObj` is a `firstViewController`
  (the `ScheduleHost` — owns the Day Plan, `isScheduleTabSelected`, `updateScheduleTabForState`);
  `habitsVcObj` is a `habitsVc` (the routine player + time-of-day clock). They are NOT the same class.
- **Borderless full-screen breaks `defaultButtonCell` suppression.** Setting `window.defaultButtonCell
  = nil` to stop Return triggering a default button does NOT take effect in the app's borderless
  full-screen window, so the routine's habit **"Start" button steals Return**. Any multi-line text
  field/`NSTextView` there must guard Return itself — see `EditOnClickTextField.performKeyEquivalent`
  (single-line) and `NewlineKeepingTextView` (the Day Plan task-detail notes view) in
  `Schedule/DayPlanTasks.swift`. Symptom if missed: pressing Enter in a text area starts a habit.

## Debug-report workflow (~/FocusBear-Claude-Tasks)

The in-app "report problem" feature (`helpVc.swift` / `AppDelegate.swift`) writes a folder with
`TASK.md`, `logs/`, `screenshots/` to `~/FocusBear-Claude-Tasks/`. A `/loop` watches for new folders
and works them. Workflow rules (also in agent memory): after 8pm don't ask the user questions — act
at ≥90% confidence else move the folder to `Needs Clarification/` with a `CLAUDE-NOTES.md`; finished
reports go to `Ready for Human QA/` renamed `descriptive-hyphenated-<timestamp>` with notes. Don't
reveal report folders in Finder (that pile-up was removed).

## Verifying UI without seeing the window

The live window is usually on another macOS Space, so screenshots aren't available to the
agent. Two techniques used here:
- **Offscreen render harness:** a small `swiftc` program that instantiates the AppKit view
  and dumps its laid-out frames — used to verify layout math (wrapping, constraints).
- **`/tmp` diagnostics:** write values to a file from inside a reload/build path, then read
  it back (e.g. `/tmp/dayplan-breaks.log`). Only fires when that code path actually runs
  (the Day Plan must be visible for the schedule to build).

## Day Plan / Schedule feature (PR #1935, branch feature/habits-schedule-view)

- Files under `FocusBear/Schedule/`: `ScheduleViewController.swift` (main VC + `ScheduleText`
  i18n enum), `DayPlanTasks.swift` (tasks panel, drag/drop, store), `ScheduleKit.swift`
  (`ScheduleBuilder.build`, deep-work sprint splitting), `CalendarManager.swift` (EventKit).
- **i18n is config-driven, not Localizable.strings.** Every new user-facing string goes in
  THREE places: local `FocusBear/config.json`, and the assets repo `config/config.json` +
  `config/config-es.json` (Spanish), under the `scheduleViewInfo` block. Read via the
  `ScheduleText` enum (`configjson["scheduleViewInfo"]`). Assets changes ship in PR #350.
  Do NOT repurpose existing keys like `menuHabits` (Windows app uses them) — add new keys
  (e.g. `menuDayPlan`).
- Task persistence is local: `DayPlanTaskStore` → UserDefaults key `dayPlanTasksByDay`
  (JSON keyed by `yyyy-MM-dd`). Backend persistence tracked separately (backend #2103).
- Deep-work splitting (`ScheduleBuilder.deepWorkSprints`) uses `sprintWorkSeconds =
  breakAfterMinutes * 60` and `sprintBreakSeconds` from `kUserdefaultsBreakDurationMinutes`.
  `breakAfterMinutes` is a runtime global set from the server (`break_after_minutes`),
  default 0, NOT persisted to UserDefaults. A block shorter than the work interval (or a
  work/break value ≤ 0) yields a single un-split block.
- `breakAfterMinutes` is set in `AppDelegate.swift` (~line 2297) from server settings.

## Full-screen (borderless) mode

- "Full screen mode" in Focus Bear is NOT macOS's green-button full screen. It's the app's own
  **borderless full-screen window** (the routine/habits view fills the screen with `styleMask
  [.borderless, .resizable]`, set in `mainWindowController.showFullSizeWindow()`).
- **Global flag: `checkIsFullScreenEnabled()`** (in `globalFile.swift`, returns
  `SettingsManagerObject.isFullScreenEnabled`) — use this to branch behaviour on whether the app
  runs as a borderless full-screen window. Live runtime state is `mainWindowControllerObj?.isFullScreenVisible`.
- Example: FBTTTodayView hides the "Open Time Tracker" button in full-screen mode (launching the
  external app would yank the user out of their routine) and shows a guidance sentence instead.
- The routine's time-of-day clock is `habitsVc.lblCurrentDateTime` (`habitsVcObj`, format
  `EEE d MMM h:mm:ss`). It must be hidden whenever a Day Plan is the front content (it overlaps the
  tasks panel). Visibility is driven by `setDateTimeClockHidden(_:)` / `updateScheduleTabForState()`
  and gated in `startDateTimer()` on `firstViewControllerObj?.isScheduleTabSelected`.

## Cross-agent coordination

Multiple Claude agents (mac/mobile/backend/windows) share a board via the `/coord` skill.
`export COORD_AGENT=mac-agent`. GitHub issues/PRs are source of truth.

## To-do API (tasks for today)

`GET https://api.focusbear.io/to-do?page=1&take=50&status=NOT_STARTED&order=DESC&sort_mode=SMART`
(SMART = TOP-score order). Response items have `duration`, `eisenhower_quadrant`, `tags`.
