# Focus Bear — macOS App: build & dev notes for Claude

Knowledge accumulated while working on this repo so future sessions don't re-derive it.

Start with [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the app is structured (subsystems, data
flow, the global-singleton/state-machine/view-swapping patterns) and [`TECH_DEBT.md`](TECH_DEBT.md)
for the known-problems register before "fixing" anything that looks odd.

## Where work goes: PRs into `main-human-verified`

**`integration/mac-swiftui-rebuild` was merged on 2026-09-22 (#2569, squash) and is finished.** New
Mac-App work branches off `main-human-verified` and comes back as its own PR:

```bash
git fetch origin
git checkout -b fix/<what-it-is> origin/main-human-verified
# …work…
gh pr create --base main-human-verified
```

The global "always open a PR when finishing a self-contained task" rule therefore applies here again,
like every other repo. The two earlier regimes — commit straight to integration, then stack a PR onto
it — are both over; they are recorded below only because they explain the repo's history.

### ⚠️ #2569 was a SQUASH merge — ancestry lies

None of integration's ~755 commits are ancestors of `main-human-verified`, even though all of their
content is in it. So this is **wrong** and will tell you a landed fix is missing:

```bash
git merge-base --is-ancestor <sha> origin/main-human-verified   # says NO for everything
```

Check the **content** instead:

```bash
git show origin/main-human-verified:path/to/File.swift | grep "the line the fix added"
```

This cost a wrong P1 issue (#2614): a fix that had been on main for two days was reported as unshipped
because ancestry said so.

### Why integration existed

The per-change PRs were all extractions from that one branch, so each carried the whole mega/main
divergence. That reached 102 open PRs, sixteen of which (#2528–#2560) were cumulative snapshots of one
another — the largest +123,291 lines. 77 were closed on 2026-09-17 after verifying by content sampling
that their added lines were already on the branch. Never force-push a shared branch; other agents build
on it concurrently.

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
- Local testing runs from `~/Applications/Focus Bear.app` through LaunchServices (`open -a`).
  Stage and verify the signed build before replacing that installed copy. Follow the exact helper
  job/process shutdown sequence in `HANDOVER-CODEX.md`; a stale helper job can relaunch the old
  DerivedData copy. Do not run the user app from the build/test output directory.
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

### Keychain prompts ("Focus Bear wants to use your confidential information…")

- The Auth0 tokens are a **generic password** in the login keychain, service
  `com.App.EarnYourScreentime`, account `credentials`
  (`security find-generic-password -s com.App.EarnYourScreentime`).
- macOS grants access by matching the calling binary against the item's ACL **designated
  requirement**. For a properly signed build that is certificate-based and survives rebuilds
  and updates; for an **ad-hoc** build (`CODE_SIGN_IDENTITY = -`, the Debug default) the
  designated requirement is literally `cdhash H"…"`, so *every rebuild is a different app* and
  macOS re-prompts. Verified with a signing probe: rebuilt ad-hoc binary → `errSecAuthFailed`,
  rebuilt Apple-Development-signed binary → reads fine.
- So: **a worktree without `Config/Local.xcconfig` builds ad-hoc and re-prompts on every
  build** (and loses TCC grants). Copy `Config/Local.xcconfig` into every new worktree.
- `security dump-keychain -a ~/Library/Keychains/login.keychain-db` prints each item's ACL
  and partition list — accumulated `cdhash:` entries are the fingerprint of this problem.
- Signed **Release** builds store the tokens in the **data-protection keychain** instead
  (`CredentialsKeychainStorage`), which has no ACLs and never prompts. That needs the
  restricted `keychain-access-groups` entitlement, which lives only in
  `Focus Bear-Release.entitlements` — macOS **SIGKILLs** a process that claims it without a
  provisioning profile granting it, and ad-hoc Debug/CI builds embed no profile.

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

**The queue is not "are there new folders?".** Five reports sat in *Rework needed* for days with
nobody looking, and four were already fixed — the fixes landed 3–12 minutes after the user tested, so
the feedback was about a build that did not contain them. Run
**`scripts/check-report-rework.py`** before concluding there is nothing to do; it reproduces
`LocalReportStatus.status(...)` from outside the app and lists both rework and still-open reports.

**Feedback on a FILED report wakes nobody by default.** The queue monitor watches for new folders;
feedback appended to an existing `TASK.md` creates none. On 2026-09-22 two reports sat in rework for
five hours for exactly that reason — hours after `check-report-rework.py` existed. Detectable on
demand is not the same as noticed, so run
**`scripts/watch-report-rework.sh`** as a second monitor alongside the queue one; it prints a line
the moment a report ENTERS rework.

*Rework needed* is computed, never stored: the newest `- Added:` stamp in `TASK.md` versus
`CLAUDE-NOTES.md`'s mtime. So **a fix that ships without its notes being stamped stays in rework
forever**, however finished it is. Stamp the update at INSTALL time, not commit time — a commit is
not an install, and filing before installing is what caused every one of those five.

**Writing notes: one original note, then stamped updates.** The app parses a notes file
(`LocalReportNoteParser`) into the first diagnosis plus every `## Update` section, and renders each
as its own card — original first (collapsed when updates exist), updates below it newest-first. So:
append a new `## Update` section rather than editing the diagnosis, and stamp the heading —
`## Update — 2026-09-15 22:40 — what changed` — so the card can show when it was written. Unstamped
headings (`## Update`, `## Update 2 — …`) still parse; they just render without a date. Anything
written under an update (`### …`, `## How to test Update 2`) belongs to that update's card.

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

## AI blocking ownership: it's a per-block-list setting, NOT per-schedule

"Use AI for this block list" belongs to the **block list (focus mode)**, not to blocking
schedules. Custom blocking schedules must NOT expose their own "Use AI" option — a schedule
just activates a block list, and the block list's `is_ai_enabled` governs AI relevance
checking. When adding/moving AI-related toggles, keep them on the focus-mode settings screen
(`focusPreferencesAdvancedVc`), read/write `arrFocusType[row]["is_ai_enabled"]`, and **sync to
the server** via `editFocusMode` — per-mode fields round-trip through the focus mode's
`metadata` (write: `editFocusMode` nests the dict under `metadata`; read: AppDelegate flattens
`metadata` back onto the focus dict, so `focusType["is_ai_enabled"]` is available).
