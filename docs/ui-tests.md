# UI tests (XCUITest)

`FocusBearUITests` drives the real app: it launches it, clicks through the sidebar and types into
the screens people use every day. It complements the logic tests in `FocusBearTests`, which never
show a window.

## What is covered

| Test class | Tests | Needs the test account |
|---|---|---|
| `AccountSignUpUITests` | runs first: a first launch on a new Mac walks the welcome onboarding, signs up a new `internaltest+macuitest…@focusbear.io` account through the real form, and finishes onboarding without blocking, schedules or habits; Back returns to the previous step | no — it creates the account the rest of the run uses |
| `LaunchAndNavigationUITests` | a logged-out launch offers sign-in; the sidebar shows Day Plan, Focus, To-do, Blocks, Settings and Help; each of those opens its screen | only the first doesn't |
| `AuthUITests` | signing in through the real email + password form reaches the main window | yes |
| `DayPlanAndToDoUITests` | add a Day Plan task and tick it done; add a to-do, complete it, delete it; open and close the reschedule plan | yes |
| `FocusSessionUITests` | typing a duration sets it; a focus goal can be set and cleared; the task picker offers the account's to-dos; start a session and end it | yes |
| `BlockingAndRoutineUITests` | the block lists and blocking schedules editors open; the routine player starts and skips a habit; postponing a routine asks the accountability buddy; the AI buddy chat waits for a message (nothing is sent); Help's report form takes a description (never submitted); the appearance setting switches to dark mode and back | yes |
| `BlockingEnforcementUITests` | during a session a listed site is redirected to the block page and an allowed site stays open; a listed app (TextEdit) is hidden; ending the session unblocks the site; an always-blocked site is blocked (or needs an intention) outside a session; a blocking schedule covering now blocks the site | yes, **and the dedicated runner's opt-in** — see [Blocking tests](#blocking-tests) |
| `SettingsUITests` | every pane in the settings sidebar opens and shows controls; a harmless switch (Appearance → popover menu) flips and flips back; the keyboard shortcuts pane lists shortcuts | yes |
| `ToolsUITests` | every Stats tab renders; a note is created and deleted; Focus Music and the Focus Button tool open; the web habit/routine editor loads; the menu-bar popover offers Preferences and Quit; the local reports list (developer account only) | yes |
| `ProjectsUITests` | a project is created, given a task, the task moved to another board column, and the project deleted | yes |
| `DayPlanEditorsUITests` | the habit editor opens, takes an edit and cancels; the routine timing sheet opens and cancels; the add-event form opens and closes (no event is ever created) | yes |
| `A0AccountCleanupUITests` | runs first (and in the smoke plan): deletes the to-dos and projects earlier, interrupted runs left on the test account — only titles matching `UI test <name> <8 hex digits>`, only on the `.uitests` build with `--uiTest` — and logs what it deleted | yes |
| `AccessibilityVoiceOverUITests` | Xcode's accessibility audit plus our own checks (every control named, no unlabelled images, reading order) on onboarding, sign-in and sign-up, the Day Plan and its editors, Focus screens, To-do, the routine, every Settings pane, the tools, micro-breaks, the mid-meeting popup, the non-timer activity and the menu-bar popover. Findings with an open ticket are recorded as expected failures, so a fixed one shows up as an unexpected pass | mostly |
| `KeyboardAccessibilityUITests` | with Full Keyboard Access on: every screen above can be reached with Tab and Shift-Tab, the Tab cycle wraps and never traps; Escape closes sheets, menus and the popover; a to-do, a focus session and a Day Plan editor can be driven without the mouse; arrow keys step sliders | mostly |
| `KeyboardDefaultsUITests` | with Full Keyboard Access off (the macOS default): Tab moves email → password on the sign-in and sign-up forms, a Day Plan task name → its duration, the to-do title onwards | mostly |
| `RegressionDayPlanUITests` | adding, editing (title, duration, notes; cancel keeps it), reordering by dragging, completing, removing and snoozing tasks; the planned total; the project token; day navigation; tasks on other days; the routine manager and timing sheet cancel cleanly | yes |
| `RegressionToDoUITests` | a new task survives a relaunch; ⌘N + Return; discard confirmation; editing title, description, duration, due date and outcome; row due-date presets; complete → Done → back; delete confirmation; search, due-date filter, sort modes, collapsible sections; the Eisenhower matrix; brain dump, procrastinate and reschedule sheets | yes |
| `RegressionProjectsUITests` | create, rename, delete; search; a project's task on its page in both views and in the task list; moving a to-do between projects; "show in task list"; creating a project from the task editor; the accordion | yes |
| `RegressionFocusSessionUITests` | durations (default, ±, typed minutes/hours, Escape, slider), untimed mode, the goal (set, edit, clear, carried into the session, typed during it), picking and removing a task, another block list, pause/resume, extend/reduce, cancelling the end confirmation, the task picker and notes during a session, the end screen (achievement, rating, another session) | yes |
| `RegressionBreaksUITests` | the break warning (start, skip, minutes, postpone and its hold-to-confirm), mid-meeting breaks, the break start screen, brain dump, switching break mode, skipping from the start screen, untimed activities finished with I'm done | yes |
| `RegressionRoutineUITests` | timed habits count down, pause, resume and finish; postpone; I'm done and the summary; Return / ⌘Return in untimed habits and their notes; next-habit flow; skipping and un-skipping; log-quantity habits (Return, Escape, arrows) | yes (skips without a routine due) |
| `RegressionBlockingUITests` | block lists created, renamed, kept after relaunch, deleted, names unique; websites and apps added and removed; Use AI kept per block list; blocking schedules created, edited (days, strictness), presets, name required; the tab limiter's permission prompt and count; always-allowed apps | yes |
| `RegressionSettingsUITests` | appearance, focus glow, Pomodoro ratio (validation and persistence), strictness confirmation, breaks, reduce motion, motivational message, to-do player, office mode; geek vs simple mode; settings search; permissions, account, advanced pages, export, check for updates, release notes | yes |
| `RegressionMenuBarUITests` | the popover's sections, Escape, Quit confirmation, expand, pin to a window and back, the mic button for trial users, and each section and focus tool opening its screen | yes |
| `RegressionOnboardingAuthUITests` | every welcome step forwards and back, the privacy step's terms, every way into an account, sign-up and sign-in validation (empty, malformed email, wrong password, password rules), show password, forgot password, sign out then back in, the distraction-blocking setup | partly |
| `RegressionToolsUITests` | notes (rename, relaunch, title required), every Stats tab, Focus Music (play/stop, rejecting non-music links), Focus Button, Time Tracker, Late No More and tab-audit tools, every Help tab, the report form, hiding and restoring a tool | yes |
| `RegressionManagedSafetyUITests` | a school- or parent-managed student (the policy installed in memory by `UITestManagedSafetyFixture`, see below): Settings panes, Strictness, Account and Uninstall show the locked safety policy instead of their controls, and Permissions stays open; Geek/Simple is refused; the Blocks screen has no block list or schedule editors; the active policy says whom to ask (the school, or a parent through the read-only home schedule editor); outside school hours and offline the lock holds; Focus Start says what the school blocks; the popover's Quit and managed-state gaps are recorded as expected failures. A teacher's class session can't be ended, paused or quit, and its unlock request needs a reason (never sent). VoiceOver audits of the locked pane and the unlock request | yes |
| `RegressionShortcutsUITests` | ⌘N, ⌘S, Escape in the to-do and note editors, the hide-window shortcut, the keyboard shortcuts pane, and each global shortcut opening its screen | yes |
| `EventsV2UITests` | the events-v2 stack (aws-infra #94) returns 2xx for one probe event (`mac-ui-test-events-probe`, which triggers no alert, email or push) posted through the app's real request path. It writes to the production events database for the test account, so it skips unless run with `FOCUSBEAR_EVENTS_V2=1 ./scripts/run-ui-tests.sh`. The app posts to v2 by default; the variable also pins the probe's launch to v2 (`FOCUSBEAR_EVENTS_V2=0` or `--eventsV1` would force v1) | yes |

Tests that depend on the account's state skip with a reason instead of failing: the routine tests
need a routine due at that moment, the postpone and buddy tests need one they can postpone, the
task-picker test needs an open to-do, the focus tests skip if a session is already running, the
habit and routine editors need a routine in today's Day Plan (and skip if the account asks for a
settings password), the add-event form needs calendar access for the test app, the keyboard
shortcuts pane exists only in advanced mode, and the local reports list exists only for the
developer's account.

Anything a test creates on the account — to-dos, Day Plan tasks, notes, projects, blocking fixtures
— is uniquely named and deleted by the same test. A run that is interrupted can't delete its fixtures, so
`A0AccountCleanupUITests` sweeps up whatever an earlier run left before anything else runs.

### Which keyboard class runs where

The two keyboard classes depend on macOS's Full Keyboard Access (System Settings → Keyboard →
Keyboard navigation, `AppleKeyboardUIMode`), which is the Mac's own setting — the suite never
changes it:

- **On** (the self-hosted runner and the developer's Mac today): `KeyboardAccessibilityUITests`
  runs; `KeyboardDefaultsUITests` skips.
- **Off** (the macOS default, GitHub-hosted runners): `KeyboardDefaultsUITests` runs;
  `KeyboardAccessibilityUITests` skips.

## Why the app under test has its own bundle id

XCUITest quits any running copy of the app it is about to launch, and the app's preferences, login
and Application Support folder are all keyed by bundle id. A UI test run against the normal
`com.App.EarnYourScreentime` build would therefore quit your Focus Bear, sign it out and overwrite
your settings.

So UI tests build the app as **`com.App.EarnYourScreentime.uitests`**. The app target's Debug
`PRODUCT_BUNDLE_IDENTIFIER` is `com.App.EarnYourScreentime$(FB_BUNDLE_ID_SUFFIX)`; the suffix is empty
for every normal build and `.uitests` only when `scripts/run-ui-tests.sh` passes it. Release builds
keep the literal id.

A build with that id (`UITestHost` in `globalFile.swift`) also keeps its hands off the rest of the
machine, because it runs on a developer's Mac as well as on CI:

- its preferences, shared app-group suite and logs are its own;
- it keeps credentials in memory only (`LogicTestHost.CredentialsStore`), never in the keychain, and
  signs in from the environment on each launch;
- it enforces nothing — no hiding apps, no AppleScript, no redirecting tabs — unless the blocking
  tests opt in (below), and never launches apps, clicks Do Not Disturb, runs focus-mode scripts or
  takes global shortcuts;
- it asks for no permissions (Accessibility, Calendar, Automation);
- no helper LaunchAgent, no Sparkle updates, no Sentry, no Focus Button;
- the build drops the `focusbear://` URL scheme, so Late No More links keep going to the real app;
- it doesn't start the block-page or Firefox servers (their port belongs to the installed app);
- it has its own icon (a red **TEST** banner, `AppIcon-UITest`, regenerated by
  `scripts/make-uitest-app-icon.swift`) and is named "Focus Bear (UI Test)" in the Dock and Cmd-Tab.

Two guards stop a mis-built run before it does harm: the test suite refuses to launch an app whose
built bundle id isn't `.uitests` (`FocusBearUITestCase.requireIsolatedAppUnderTest`), and the app
itself exits when launched with `--uiTest` under the shipping id (`UITestHost.refuseUnisolatedLaunch`).

## Running them

Always use the script, never Xcode's Test button (that builds without the suffix):

```bash
./scripts/run-ui-tests.sh --plan smoke        # the critical path, a few minutes
./scripts/run-ui-tests.sh --plan regression   # every UI test (the default)
# one class:
./scripts/run-ui-tests.sh -only-testing:"Focus BearUITests/LaunchAndNavigationUITests"
```

Two test plans, both in `FocusBearUITests/` and wired into the `Focus Bear UITests` scheme:

- **`Smoke.xctestplan`** — the critical path in under five minutes: sign-in, logged-out launch,
  sidebar, Day Plan add + complete, to-do add / complete / delete, a focus session start + end, a
  Settings switch, the block list editor, the menu-bar popover and Tab between the sign-in fields.
  It signs in with the run's existing account (or signs one up if there is none); the full sign-up
  through onboarding is in the regression plan. Run it on every change;
  it's what a `ui-tests`-labelled PR runs.
- **`Regression.xctestplan`** — every test class, including the `Regression…UITests` classes (one per
  area: Day Plan, To-do, Projects, focus sessions, breaks, routines, Settings, blocking, menu-bar
  menu, onboarding and sign-in, tools, keyboard shortcuts) and the accessibility suites.

The run's account: `AccountSignUpUITests` — first, because XCTest runs classes in name order —
signs up a new `internaltest+macuitest<timestamp>…@focusbear.io` account (internaltest addresses stay
out of analytics), and every signed-in test after it reuses that login. The (sandboxed) test runner
keeps it in its own container, so running a single class later reuses it too; if there is no
account yet, the first signed-in test signs one up itself. A saved account is reused for six days
only: a new account's Pro trial lasts seven, and on Basic, Geek mode — Focus Start's goal card and
task picker — is behind the upgrade nag, so an older one is replaced by a fresh sign-up. Set `FOCUSBEAR_UITEST_EMAIL` /
`FOCUSBEAR_UITEST_PASSWORD` to use an existing account instead. Never commit a password. Results land in
`UITestResults.xcresult` (open it in Xcode; every test attaches screenshots), the build in
`build-ui/`, and the script unregisters the test app from LaunchServices when it finishes.

The suite takes over the pointer and keyboard while it runs, so on your own Mac run it when you are
not using it.

Your own Focus Bear's full-screen routine, break or session screen sits above every window and takes
every click the suite makes (`scripts/installed-focus-bear-cover.swift` finds it). So the script
publishes a lease while it runs (`scripts/ui-test-runner-lease.sh`: `~/Library/Caches/com.focusbear.uitest-lease.json`
plus a `com.focusbear.uitest-lease-changed` distributed notification, renewed every 5 minutes, at most
30 minutes ahead, withdrawn on exit), and a **Debug** build of Focus Bear steps its routine window aside
for it (`FocusBear/Routine/UITestRunnerYield.swift`) only when all of these hold:

- the lease is valid — unexpired, and its runner process alive and the one that wrote it;
- nobody has touched the Mac for 5 minutes at that moment;
- a morning, evening or custom routine is waiting to start or showing a finished habit, with no habit
  playing or paused, no allowed-activity habit, no focus session and no next-habit countdown.

The window is only ordered out — nothing is ended, skipped or postponed — and comes back as soon as
the run ends (or the runner dies, or the lease expires), the routine moves on (a break, a focus
session, a habit starting), or after 2 hours; a lease gets one yield. Idle time is checked only when
it steps aside, because the suite's own clicks and typing reset it. Release builds have none of this.

When a screen is up, the script waits up to 6 minutes (`UI_TESTS_YIELD_WAIT_SECONDS`) for it to step
aside, then refuses to start (exit 75, naming it): finish or postpone it first. One that comes up
mid-run fails the next test as `covered by Focus Bear`, not with whatever step it interrupted.

### Automation Mode

macOS only lets XCUITest drive apps in **Automation Mode**. On a Mac where it needs authentication
(the default), each run asks for an administrator password, and an unanswered or cancelled prompt
fails the run before any test starts with `The test runner failed to initialize for UI testing.
(Underlying Error: Authentication cancelled. System authentication is running.)`. Check with
`automationmodetool`; the runner setup below turns the prompt off.

### Publishing a build that passed

`scripts/ui-test-and-publish.sh` runs the suite and, only if it passes, publishes a DMG of the same
commit:

```bash
npx wrangler login                                  # once; needs write access to desktop-app-releases
export CLOUDFLARE_ACCOUNT_ID=…                       # if your login has more than one account
export ZOHO_CLIQ_BACKEND_BOT_WEBHOOK=https://cliq.zoho.com.au/api/v2/bots/…/incoming
export ZOHO_CLIQ_API_KEY=…
./scripts/ui-test-and-publish.sh --plan smoke   # or --dry-run to test and build without publishing
```

The DMG comes from `scripts/build-release-dmg.sh`, which scripts the manual release steps in
`README.md` (archive, Developer ID export, DMG, signing, and notarization when `NOTARY_PROFILE` is
set). Keep it matching the process releases actually follow: it must print the DMG's path as its last
line. The DMG is uploaded with `wrangler r2 object put` to
`desktop-app-releases/mac/ui-tested/<dmg name>/` (served from `https://downloads.focusbear.io`; at most
300 MB through wrangler), and the link is posted to Cliq's #version-updates in the same message format
as the analytics reports. A failed run, one that couldn't start (exit 75), a failed build or
uncommitted work in the tree publishes nothing; the link names the commit that was tested. The
script's header lists the optional settings.

## Blocking tests

`BlockingEnforcementUITests` checks that blocking really happens: it drives Safari and TextEdit and
expects Focus Bear to redirect or hide them. That is exactly what the test build must never do on
someone's own Mac, so it is **off by default** and switched on only by an explicit opt-in:

- `FOCUSBEAR_UITEST_ENABLE_BLOCKING=1` in the environment of the app under test turns enforcement
  back on (`UITestHost.isBlockingEnabled`). The app honours it **only** when its bundle id is the
  `.uitests` one — in any other build, including the installed app, the variable is ignored (and
  logged as ignored). Without it the test build blocks nothing, as before.
- The tests pass that variable only when the runner itself has
  `TEST_RUNNER_FOCUSBEAR_UITEST_ENABLE_BLOCKING=1`; otherwise every blocking test skips. The CI
  workflow sets it only on the `focusbear-mac-ui` runner and only when the build is stably signed
  (see below). `scripts/run-ui-tests.sh` forwards `FOCUSBEAR_UITEST_ENABLE_BLOCKING` if you set it —
  don't, on a Mac you are using.

What is blocked is set up by the app itself (`UITestBlockingFixture`), through the same settings and
API paths the editors use, so enforcement is tested end to end without scripting the editors (which
have their own tests):

| Fixture | What it creates |
|---|---|
| `focusSession` | a block list — `example.org` allowed, `example.com` and TextEdit blocked, AI off, every other app allowed — and a running 15-minute session on it |
| `alwaysBlocked` | `example.com` and TextEdit on the always-blocked lists, no session |
| `blockingSchedule` | the same block list, run by a schedule from 5 minutes ago to 30 minutes from now (skips near midnight) |
| `cleanup` | removes everything above, ends a fixture session, syncs, and quits |

Everything is named `UI test fixture …`, and every blocking test runs `cleanup` **before** it starts
(to clear a crashed earlier run) and again in its teardown, so nothing is left on the test account
even when a test fails. The app publishes the fixture's outcome, and whether it holds Accessibility
and Automation over Safari, as JSON in its menu-bar icon's accessibility value (the test runner is
sandboxed, so it cannot read the app's files);
a missing grant fails the test with the step to fix it.

## The CI runner (`focusbear-mac-ui`)

Setting one up from scratch on a spare Mac, step by step: [`ci-self-hosted-mac-runner.md`](ci-self-hosted-mac-runner.md).

`.github/workflows/ui-tests.yml` runs on a self-hosted runner labelled **`focusbear-mac-ui`**. It
must be a Mac nobody works on: the suite moves the pointer and types, and the workflow refuses to run
if it finds a real Focus Bear running. **Do not** give this label to the workstation runner
(`focusbear-mac-local`), and do not install `scripts/local-runner/xcodebuild` on the UI runner — that
wrapper only permits the unit-test scheme.

One-time setup, as an administrator on the runner Mac:

1. Install Xcode (same major version as the team), open it once and accept the licence
   (`sudo xcodebuild -license accept`), and install CocoaPods.
2. Create a standard user for the runner, turn on automatic login for it, and turn off the screen
   saver, screen lock and display sleep. UI tests need a logged-in, unlocked GUI session.
3. Let UI tests run without a password prompt:
   ```bash
   sudo automationmodetool enable-automationmode-without-authentication
   sudo DevToolsSecurity -enable
   ```
4. Register the GitHub Actions runner in that user's account with the labels
   `self-hosted, macOS, focusbear-mac-ui`, and install it as a **LaunchAgent** (`./svc.sh install`
   run as that user), not a LaunchDaemon: a daemon has no GUI session to test in.
5. Run the suite once by hand in that session (`./scripts/run-ui-tests.sh`) and approve anything
   macOS asks the first time (Accessibility / "Xcode Helper wants to control this computer"), so later
   runs are unattended.
6. Optionally, add the repository secrets `FOCUSBEAR_UITEST_EMAIL` and `FOCUSBEAR_UITEST_PASSWORD` to run as an existing account; without them each run signs up a fresh internaltest account first.

For the blocking tests, additionally:

7. Install a code-signing certificate in the runner user's login keychain (an Apple Development
   certificate is enough) and set the repository variables `UI_TESTS_CODE_SIGN_IDENTITY` (its name,
   e.g. `Apple Development: CI Runner (ABCDE12345)`) and `UI_TESTS_DEVELOPMENT_TEAM`. macOS ties
   Accessibility and Automation grants to the app's signature; an ad-hoc build is a different app
   every run, so without a stable signature the grants below would be lost on every build. Without
   the variable the workflow builds ad hoc and the blocking tests skip.
8. Build once with that identity, then in **System Settings → Privacy & Security** grant the built
   `build-ui/Build/Products/Debug/Focus Bear.app` (it shows as Focus Bear):
   - **Accessibility**;
   - **Automation** → allow it to control **Safari** and **System Events** (the first blocking run
     asks; answer Allow). Add Google Chrome here too if you install it — the tests use Safari only;
   - Screen Recording is **not** needed.
9. Open Safari once so its first-launch screens are out of the way; the tests read its address field.

Nothing needs signing certificates: CI builds ad hoc (`CODE_SIGN_IDENTITY=-`), which is why the test
app keeps no keychain items — an ad-hoc binary is a new app to the keychain on every build.

The workflow starts from **Actions → UI Tests → Run workflow** (choose `smoke` or `regression`),
or runs on a pull request labelled `ui-tests` (only the tests the change needs; see below) or
`full-ui-tests` (everything). Once the runner is online, add a `push` trigger for
`main-human-verified` and a nightly `schedule`; both always run the whole Regression plan. Each run
uploads the result bundle, the exported screenshots and the xcodebuild log.

### Which tests a pull request runs

`scripts/select-ui-tests.py` diffs the pull request against its merge-base with the base branch and
looks each changed path up in **`.github/ui-test-impact.json`**:

1. **Smoke always runs.**
2. A path in an **area** (e.g. `FocusBear/Schedule/**` → the Day Plan area) adds that area's tests:
   whole classes, or single tests of the shared suites (`AccessibilityVoiceOverUITests/testDayPlan`).
   A renamed file counts for both its old and new place.
3. A path in **`fullRun`** — code every screen depends on (`AppDelegate`, globals, the window and
   view-controller plumbing, `KeyboardNavigation`, `UITestContract.swift`, the harness, the test
   plans, the project, pods, config) — runs the **whole Regression plan**.
4. A path in **`noUITests`** (docs, unit tests, release tooling) adds nothing.
5. A path in **none of them runs the whole Regression plan**: nothing says what covers it, so the
   safe answer is everything. Add it to an area when that happens often.
6. The `full-ui-tests` label, a push and a scheduled run also run everything.

The job summary lists every test chosen and the paths that chose it, or why everything ran.

Every UI test class must appear in the map. `.github/workflows/ui-test-selection.yml` runs
`select-ui-tests.py check` on any change to the suite, and fails when a class is named nowhere (a
selective build would never run it) or the map names a class or test that doesn't exist. A class that
no plan runs (in `Regression.xctestplan`'s `skippedTests`) is exempt.

## Keeping tests fast

Profile a test from its log: `t = …s` marks every step. `scratchpad`-style scripts that list each
gap over 0.3 s are the quickest way to see where a test waits. What we found, and the rule each led to:

- **Never wait on `XCTNSPredicateExpectation` / `waitForExistence`.** They re-check about once a
  second, so "wait for the sheet to close" cost a second even when it closed at once. Use
  `appears`, `waitForNonExistence`, `waitUntil(_:isTrueOf:within:)`, which poll every 50–100 ms.
- **Don't wait for something to find out it isn't there.** Check `exists` first when the answer is
  already knowable (a TOOLS item is either listed now or the section is collapsed), and when one of
  two things will show, wait for whichever comes first (`firstToAppear`). A negative assertion
  ("the discarded task wasn't saved") is the only place a full wait is right.
- **One query per question.** Every property read on an `XCUIElement` (`exists`, `frame`,
  `elementType`, `isHittable`) is a round trip. Take one `snapshot()` and read it, as the Tab walk
  and the focus checks do (`focusedSnapshot()`).
- **Ask macOS locally.** "Is the test app in front?" comes from `NSWorkspace`, not `app.state`.
- **Screenshots only when a test has failed.** `attachScreenshot` does nothing on a passing test;
  `recordDiagnostics` forces one for the failure it is about to report. Each cost about a second.
- **No window animations.** The test app launches with AppKit's window, sheet and scroll animations
  off (`noAnimationArguments`). XCUITest waits for the app to go idle after every event, and a
  closing sheet held that wait at a second.
- **Clean up without relaunching.** A test's to-dos and projects are deleted by the running app on
  request (`UITestContract.Command.cleanAccountNow`), not by relaunching it into the sweep.
- **Press, don't click, unless the pointer is the point.** XCUITest's own mouse click takes 0.4–0.6 s
  (0.35 s of it synthesizing the event). `tap` presses buttons, radio buttons, checkboxes and
  disclosure triangles the way VoiceOver does, through a gated in-app hook
  (`UITestContract.Command.press`, test build and `--uiTest` only): the app finds the control by
  identifier under the point the test saw, answers, then presses it — about 0.15 s. Text fields are
  focused the same way, and Settings sidebar rows are selected through their table. Anything the
  hook can't single out gets a real click. Pop-up and menu buttons always get a real click (their
  menu is what the test uses next), and a test about the pointer itself — something drawn over a
  control, hit-testing — uses `clickWithPointer` (the goal-editor test does, for #2691).
- **Paste, don't type.** `typeIntoFocus` pastes into a focused text field (the clipboard is put
  back) and presses a trailing newline as Return; XCUITest types a character at a time.
  `typeCharacters` is for tests about typing itself. Passwords are always pasted, so they never
  appear in the log.
- **Give each of several same-kind controls its own identifier** (`UITestContract.Identifier.named`,
  `kind:name`). Matching on a label reads every button's label: 1.5 s on the To-do screen.
- **Don't ask XCUITest `isHittable`** on a control plainly inside the window: it took up to 1.7 s on
  SwiftUI buttons. One snapshot says where it is.
- **Launch cost.** A test launch is about 3.2 s to a ready sidebar. The test build keeps the test
  account's sign-in between launches (`UITestCredentialsCache`, its own Application Support folder,
  owner-only; never the password), runs its launch hooks as soon as settings load, retries a
  requested screen every 0.1 s, and starts the block-page server only when a test enforces
  blocking. Force-ending the app in teardown is not faster: XCUITest treats it as a crash and spends
  20 s looking for a crash report.

## Managed-safety scenarios

Enforcement can't run on a developer's Mac, so `RegressionManagedSafetyUITests` checks the managed
*state* instead. `FOCUSBEAR_UITEST_MANAGED_POLICY` (`school-active`, `parent-active`, `school-inactive`,
`offline-last-known`) makes the test build install that policy snapshot straight into
`ManagedBlockingRuntime` — never through `ManagedPolicyStore` (the keychain) or the server, and with an
empty identity that `ManagedBlockingAPI` refuses before any request. `FOCUSBEAR_UITEST_TEACHER_SESSION=active`
joins a class session the server never hears of (no heartbeats). Both are honoured only by the `.uitests`
Debug build launched with `--uiTest`.

## Adding a test

- Give the control an accessibility identifier in `FocusBear/UITestContract.swift`, or in the
  area's `UITestContract+Tasks/Sessions/Settings/Onboarding/Managed.swift` (all compiled into both the app
  and the tests), and set it where the view is built. Titles come from translated config,
  so tests never match on visible text.
- AppKit: `view.setAccessibilityIdentifier(…)`. SwiftUI: `.accessibilityIdentifier(…)`. An
  `NSViewRepresentable` needs the identifier set on its `NSView` in `makeNSView`.
- Subclass `FocusBearUITestCase`; start with `launchSignedIn()` or `launchLoggedOut()`, reach screens
  with `open(menuItem:expectingAnyOf:)`, and give anything you create a `uniqueTitle(_:)`.
- Anything that depends on the time of day or the account's settings should `throw XCTSkip` with the
  reason when its precondition isn't there.
- New tests go in the area's `Regression…UITests` class. A new class must go into an area of
  `.github/ui-test-impact.json`, or the selection guard fails. Add a test to `Smoke.xctestplan` only if it
  is on the critical path and fast; the smoke plan should stay under five minutes.

### Runner safety checks without launching the app

`python3 scripts/test-ui-runner-safety.py` checks the shared test-account allowlist with pure Swift and tests cleanup against mocked executable paths and reused PIDs. It does not authenticate, launch the app, read account files, or terminate processes. The unit-test workflow runs it before building the app.

Signed-in UI tests require `internaltest+macuitest<suffix>@focusbear.io`. The runner rejects other accounts before launching, and the isolated app checks the same policy before authentication and before sending the events probe. Cleanup only stops executables whose exact `lsof` text path belongs to the selected test build, and rechecks each PID before stopping it.
