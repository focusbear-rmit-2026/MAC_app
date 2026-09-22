# Mac local feedback follow-up, 10 September 2026

The user app is installed in `~/Applications/Focus Bear.app`, launched through LaunchServices
with `open -a`. The installed source is `594e02e6f3e556a2a2a813fa3e02d156cf30967f`
(started at22:36 AEST, PID74248). See the22:36 follow-up below for the latest installed fixes.
Later test/documentation-only commits do not require a user-app rebuild.

Keep the stable signing configuration in `Config/Local.xcconfig`. The installed app and its
embedded `Contents/Resources/FBHelper.app` passed deep/strict signature verification. The app's
designated requirement matches the previously installed developer build. Do not reset TCC.

The old helper LaunchAgent retained the DerivedData bundle path and relaunched that copy.
Unloading the exact `gui/<uid>/com.focusbear.focusbearhelper.plist` job before stopping the helper
fixed installation routing. After restart, the app, helper and two embedded server processes all
used `~/Applications`. Do not directly execute the app binary or stop unrelated server processes.

## Installed fixes and validation

- Navigation preserves the permanent root-level minimize controls. An earlier positioning change
  moved them out of `boxContainer`; generic page cleanup then removed/deallocated the weak outlets,
  causing `mainWindowController.showFullSizeWindow()` to trap on sidebar clicks. The real cleanup
  regression now covers the lifetime/visibility/action of the controls across page switches.
- Sidebar icon, label and padding use the same hit target. Enabled rows accept first clicks. Native
  tooltips replace transient sidebar popovers, which could consume the click used to dismiss them.
  The separate tool-hide action and disabled/selection-veto behavior are retained.
- Project notes use standard formatting icons with English/Spanish accessibility labels/tooltips.
- Report Problem includes an account-restricted local-report table with actual folder/notes status,
  and a per-report instructions sheet. Replies append to the existing TASK after account/ownership
  checks; failed writes retain the draft. Only the pre-existing tester capability sees this feature.
- Calendar status is independent of forecast API success. The installed process reported EventKit
  status3/readable=true. System Events remains unknown in the passive menu probe; this is not evidence
  of denial. Only the explicit wizard button requests consent.

The18:22 combined local run passed34 tests:17 report/reply tests,4 sidebar interaction tests,
9 window/layout/navigation tests and4 isolated-host tests. A normal signed build then succeeded.
Earlier focused permission/forecast validation passed132 tests. Project-note JavaScript validation
passed15 tests and reproduced the bundled output/licenses; native WebKit coverage also passed.

Validation artifacts are in `/private/tmp/focusbear-ui-followup-validation-20260910`, including
`FeedbackPanelResults.xcresult`, `SidebarRecoveryResults.xcresult`, `LiveFeedbackResults.xcresult`,
`NoteEditorFinalResults.xcresult`, per-run logs/exit files, and install records. Synthetic tests do
not write live project notes or start sessions. The user app remains separate from test/build output.

## Pull requests

All target `main-human-verified`; none were merged or deployed. Mac CI uses the existing local
self-hosted runner, with heavy jobs serialized. Native tests passed on these published branches before the evening wave (later heads/results are below):

| PR | Change | Native result |
| --- | --- | --- |
| [2405](https://github.com/Focus-Bear/Mac-App/pull/2405) | Fullscreen/window chrome/navigation cleanup |249 passed |
| [2449](https://github.com/Focus-Bear/Mac-App/pull/2449) | Focus-start design, project/task search, whole-button hits |291 passed;32 visual scenarios |
| [2433](https://github.com/Focus-Bear/Mac-App/pull/2433) | Ongoing-session layout, task editing fallback, browser warnings |385 passed;10 captures |
| [2466](https://github.com/Focus-Bear/Mac-App/pull/2466) | Native collaborative project notes |281 passed, including12 WebKit cases |
| [2467](https://github.com/Focus-Bear/Mac-App/pull/2467) | Sidebar first-click behavior |244 passed at final d80a231ea; real clipped-layout fixture |
| [2468](https://github.com/Focus-Bear/Mac-App/pull/2468) | Local report status and follow-up instructions |257 passed |
| [2444](https://github.com/Focus-Bear/Mac-App/pull/2444) | White break-start surface and existing SwiftUI break flow |258 passed |
| [2451](https://github.com/Focus-Bear/Mac-App/pull/2451) | Accurate partial-permission status and due-date previews |274 passed |

The isolated test-host prerequisite is [2465](https://github.com/Focus-Bear/Mac-App/pull/2465).
Configuration checks still await translation PR merges; do not bypass them. Assets453/458/459/460
were marked ready only after parity/content review;461/462 conflicts were repaired. Assets462
contains the menu, note-editor and report-status keys plus an explicit `habitInvalidCutoff` backfill.
The backfill was present in assets453's branch history but not its PR diff, so453 alone was not a
valid dependency. English/Spanish keys and placeholders were checked; assets checks passed.

## Local report workflow and remaining checks

Five reports were moved to `Ready for Human QA` with CODEX-NOTES:17:37:03 (window controls/crash),
17:51:34 (assets/status table),17:52:12 (note icons),18:04:20 (sidebar clicks),18:04:53 (account-only
status/replies). These are ready for human review, not claims of a released fix.

Watch TASK.md changes both at the inbox root and one report-folder level inside `Ready for Human QA`
and `Needs Clarification`, because instructions can be added to already actioned reports. Ignore
our status-only folder moves as new-user events. The bounded watcher helper is
`/private/tmp/focusbear-feedback-watch-20260910.py`; an active turn must own/renew it. Do not claim
indefinite monitoring after the agent stops.

The forecast report `2026-09-10_17-37-15` moved to Ready for Human QA after the20:35 build.
The later live read counted all128 native projects and proceeded to task pagination. The user
subsequently opened the forecast and submitted specific follow-up feedback about its grouped
project presentation and hidden calendar events. See the evening follow-up for the catalogue fix.

Still separate: unrestricted editing of unplanned tasks depends on backend2385. Full personal
block-list Figma migration still needs access to file ULUYn4BTeP7siyAGFAEkq4/node5436:95408; the
other focus-screen design file was accessible. Do not claim that migration is finished.


## Evening feedback follow-up (20:35 local installation)

The earlier watcher stopped at18:38. The user asked again at20:08; the resumed watcher became
active at20:12 and caught four reports received during that gap. It now observes TASK.md replies
and identity-bound USER-STATUS.json confirmation/undo changes in ten-minute intervals while the
active turn owns/renews it. Do not describe this as unattended AI triage after a turn ends.

Installed fixes:

- **Confirm fixes:** each owned report offers Mark as confirmed fixed and Undo confirmation.
  The versioned USER-STATUS.json sidecar retains report/account/Created identity; TASK.md,
  reviewer notes and replies are unchanged. Stale, linked, corrupt and foreign metadata writes
  fail safely. Six new English/Spanish keys are also in assets462.
- **Forecast:** the20:04 diagnostics showed128 native projects plus three imported first-page
  extras reusing migrated native IDs from page two. The catalogue now counts native source IDs
  independently, then reconciles one forecast project per display ID while retaining native
  dates/outcomes and imported-task associations. Incomplete native catalogues still fail.
- **Help minimise:** logs showed successful password continuation then `window is nil` because
  Help had detached habitsVc. Morning/evening/focus-summary approval sheets now choose the
  actual visible main host. Existing password, AI-buddy and cancellation behavior is retained.
- **Other display covered:** leaving custom fullscreen or closing the main window clears the
  cover collection. Late routine callbacks cannot create covers beside a normal/hidden window.
  First-show and already-key fullscreen transitions restore missing covers directly, without
  entering the legacy modal-session cleanup code.
- **Music:** both Focus Music buttons now include the existing music.note icon and retain
  their translated labels/actions.

Local native validation:217 executed,216 passed and one optional ongoing visual-export case
skipped; this includes24 report tests,44 forecast tests and132 focus-session cases. The final
window follow-up separately passed all12 window regressions plus4 isolated-host tests. The normal
signed build passed; main and embedded helper signature verification passed; the designated
requirement matched the previous installed copy. Exact helper job bootout preceded shutdown,
then the app was launched with `open -a` from ~/Applications. All four processes use that bundle.
Calendar logged status3/readable=true after restart. No newer crash report was present at20:35.
Artifacts: EveningFeedbackResults.xcresult, EveningWindowFinalResults.xcresult and
`evening-feedback-applications-restart.json` in the existing validation directory.

Four reports are now Ready for Human QA:20:04:17 (confirmation),20:17:20 (music),20:16:24
(Help/minimise/display covers), and17:37:15 (forecast). The two empty20:05 reports are retained
under Needs Clarification; the user subsequently confirmed both fixed, along with the sidebar,
account-only status/replies and confirmation-action reports at20:36–20:37.
Never write a user confirmation on their behalf.

**Task editing remains blocked by backend2385.** The restarted app captured an exact reason at
20:35:09: the by-ID task exists and subtasks decode, but five fields are omitted
(eisenhower_quadrant, outcome, perspiration_level, synced_project_id, updated_at). Today's server
Day Plan contains eight rows and does not contain this task. Reconnecting cannot repair that
projection. Report20:17:28 is now `Needs Clarification/backend-task-snapshot-2026-09-10_20-17-28`.
The existing backend PR remains open; native diagnostics log only schema names/counts.

**Keychain prompt was caused by local CI startup.** PR2402 run34464278405 launched the normal
ad-hoc-signed DerivedData app at20:06:53 without the isolated test-host prerequisite. Its two
orphaned servers were stopped by exact path/PID. After2402 merged externally, main run34465291268
also lacked that prerequisite. Neither run changed the stable installed app's signature.
PR2465 now includes a preflight that fails before xcodebuild if Debug, TestAction isolation,
early app/credential guards or the host suite are missing. Six Python preflight regressions pass.
This prerequisite still needs to reach main/older PR branches; no main merges or deployments
were performed by this task.

Evening review heads completed native CI on the serial local self-hosted runner:

| PR | Published head | Run | Result |
| --- | --- | --- | --- |
|2465|46926c60c|34466963964|245 native +6 Python preflight passed|
|2405|5a6f346f9|34467030340|257 native passed|
|2463|d0b34c3cc|34467069505|289 native passed|
|2468|acb287d48|34467235732|269 native passed|
|2433|190881e65|34467415698|391 native passed|

The20:39 onward reports are being investigated in a second working-code wave. That code is not
installed yet. Keep each CODEX-NOTES status current using an exact `## Status` section followed
by `Investigating` or `Queued`; explanation belongs in a separate paragraph/section. A receipt
alone is Queued; active diagnosis/implementation/validation is Investigating. Never write the
user's confirmed-fixed status on their behalf.


## Second evening follow-up (21:16 local installation)

Installed source9735b77ef includes the second report wave:

- Forecast calendar reads share Day Plan's series/per-day/legacy hides, including overnight
  portions and hides made during an initial load. Concurrent meetings consume their union time;
  a real five-standup fixture verifies15 minutes, and the day view explains that total.
- The original grouped project cards are restored using local forecast results. Unknown effort
  gets no unsupported risk badge; completed unestimated work is not promoted as work to start.
- Forecast loading now reports actual project/task counts and stage percentages, then calendar,
  day preparation and calculation. There is no invented overall ETA. Screen reentry cannot
  restart an already-running load.
- Reports hide confirmed fixes by default, offer Show fixed reports, display explicit Queued and
  Investigating states, refresh visible tables every15 seconds, and open notes in an in-app sheet.
  Empty submissions and the form's global default Return shortcut are removed. Note-file checks
  use fresh filesystem attributes: native validation caught Foundation URL metadata caching a
  file's previous type after it was replaced by a symlink; the reader and regression now reject it.
- Approved routine postponement defers restoration to a normal window while preserving the page.
  A newer routine/window invalidates the pending transition. Day Plan's root width now follows
  the actual viewport: reproduced1024pt outer window with1266pt content; native regression covers
  986/1024/1600pt windows, expanded230pt sidebar,306pt task panel and visible Exit Fullscreen.
- The existing break player has a top-left opposite-mode button. Current timer/video/notes and
  completion attribution are retained; only unplayed upcoming activities are selected anew.
  Tooltips explain the current activity continuing and the no-remaining-activities case. Meeting
  breaks retain seated activities. No replacement of the complex existing player was performed.

Validation across the final targeted runs:54 forecast,8 grouped portfolio,25 break,38 report,
16 window and4 isolated-host cases passed (145 distinct cases). LateFeedbackFinalResults had a
single notes-file validation failure; after the fresh-attributes fix, LateRecoveryResults passed
all58 selected report/window/host tests. No failure is being hidden or described as a green full
combined run. The normal signed app build passed; main/helper deep/strict verification and the
unchanged designated requirement passed. Exact helper bootout preceded shutdown; LaunchServices
started the installed app, helper and two embedded servers from ~/Applications. Calendar logged
status3/readable=true at21:16:19. Latest crash report remained the17:57 report before this install.

Artifacts in the existing validation directory: LateFeedbackFinalResults.xcresult,
LateRecoveryResults.xcresult, late-feedback-app-build.log/.exit and
late-feedback-applications-restart.json. Primary source was frozen while tests/build ran;
subsequent project-list changes in the shared clone are not in this installed build.

Twelve second-wave reports moved to Ready for Human QA with installation/evidence notes at21:18.
The20:07:43 keychain report moved to Needs Clarification/keychain-test-host-prerequisite-...:
implementation/tests are complete but the prerequisite still awaits merge into main. Never mark
that waiting report Investigating without active work. The21:04:19 project-name/source mismatch
and21:04:45 alphabetical-order/actual-completion reports are now being investigated separately.

Assets462 at0dfa4c574 has42 report keys,5 player keys and earlier notes/menu keys (72 EN/ES entries
in the PR); both checks passed. Assets460 atdb77302b8 has66 forecast keys; both checks passed.
The next native CI wave starts with2405 atcb5b07c88, run34470565489. Other prepared PR updates
remain held while local project follow-up testing needs the serial Mac build slot.


## Project follow-up (21:37 installation, retained in21:55)

Source2433db727 added alphabetical All Projects ordering over the current-account active
catalogue, reconciled project display names, and actual completed/total task percentages when
task coverage is complete. Reconciliation preserves newer forecast metadata and known matching
sync associations. Project mutation refresh callbacks are bound to the account that opened them.
The optional synced_platform field labels known providers without guessing unknown or legacy data.
Backend [2386](https://github.com/Focus-Bear/backend/pull/2386) atb9c9cec6c supplies this read-only
field;121 focused service tests and full backend CI passed. It remains unmerged/undeployed, so the
source-label report remains under Needs Clarification until the server can provide it.

LateProjectsResults passed175 selected cases. After the final metadata/provider fixes,
LateProjectsFinalResults passed150 (54forecast,15portfolio,77ToDo,4host). The normal signed build
and stable-signature install passed. The21:04:45 alphabetical/completion and21:30:53 installed-status
reports moved to Ready for Human QA. The project-name portion of21:04:19 is installed; provider
attribution still requires backend2386. No deployed API fields or percentages were fabricated.

## Sleep and capacity follow-up (21:55 installation)

Installed sourceee623812c adds configurable sleep with22:00–06:00 default and extra self-care with
zero default. Account-scoped local settings use a stable account-bound editing draft and reject
stale-account saves. Sleep, calendar and habit intervals consume their union once. Today's elapsed
time is excluded; actual local23/25-hour DST days are preserved. Forecast, Day Plan header,
smart-date capacity and date badges use the same settings and task absorption. Hidden-calendar
changes and setting changes during the initial load invalidate stale results.

The settings and separate sleep/self-care rows have bundled EN/ES copy, including fallback when
the remote config is healthy but older. The break player's existing office-friendly alert now
uses its translated bundled menu keys as well.

The first SleepCapacityResults build failed because the app's existing State enum shadowed
SwiftUI.State. Commit ee623812c qualified the four wrappers and two initializers. The corrected
SleepCapacityFinalResults passed all107 selected tests (61forecast,15portfolio,27break,4host).
The normal signed build then succeeded. The exact helper job was unloaded before replacement;
LaunchServices restarted one app, one helper and two embedded servers from ~/Applications.
Both bundle signatures passed deep/strict checks and the designated requirement was unchanged.
Calendar logged pid66920/status3/readable=true at21:55:33. The latest crash report remained17:57:31.

Report21:34:19 moved to Ready for Human QA after installation, with its21:52 rebuild follow-up
explicitly answered. Artifacts: SleepCapacityFinalResults.xcresult, sleep-capacity-app-build.log,
and sleep-capacity-applications-restart.json in the existing validation directory.

Report21:53:48 asks to exclude completed history from forecast loading (4708 rows versus about200
unfinished). That follow-up is not in the installed app. An additive backend filter is being
prepared because raw status filtering alone can omit valid custom/external unfinished columns.
Do not install a caller that disables the existing forecast on the currently deployed server.

## Local runner protection (installed21:59, verified22:00)

The old main branch still lacks the isolated-host prerequisite. Run34472516757 fromf3afad1e
started the ordinary app at21:42 and completed250 tests with one CustomBlockingSchedule failure.
The recurring startup issue is independent of the stable certificate used by the user's app.

Reviewed scripts at53e063cc6 install as a runner-only PATH wrapper. Twelve wrapper regressions
and six unchanged structural preflight regressions pass. The trusted preflight SHA-256 remains
7bf6781f3f981950eda237e74ae8f80d4c93809d14327bfdf4c2b0cef2722464 (the reviewed2465 version).
The wrapper validates the actual invocation checkout and explicit isolated Debug scheme before
passing to /usr/bin/xcodebuild. It rejects prebuilt/overridden hosts whose isolation is unverified.
Other repositories, non-test commands and ordinary local commands pass through unchanged.

At21:59:21, after verifying the runner and native build slot idle, the reviewed version was
installed to ~/.local/share/focusbear-runner/53e063cc6a16f2b9a13ca4f4b7185bab7228842d/.
The exact Actions LaunchAgent was stopped, the original runner .path backed up in that version,
and the version's bin directory prepended without changing other entries or shell profiles.
The service restarted from Listener2145 to67764. Installed-wrapper smoke checks rejected an old
checkout with78 and accepted the current source preflight; no keychain/credential/signing ACLs
were changed. Installation evidence and rollback backup are in the version directory.

The real main CI rerun34472516757, attempt2, then exited78 at22:00:24 with the wrapper's explicit
missing-isolated-host message. There was no SwiftCompile or Test Suite output: the native tool
and test app did not start. The test step took less than one second. This expected refusal is
not a passing main test suite; old branches still need PR2465 before tests can run. Current
workflows invoke bare xcodebuild. The PATH wrapper is an operational protection for those trusted
workflows and can be bypassed by a deliberately absolute invocation; it is not a sandbox.

Both21:35:35 and the older20:07:43 keychain reports now show installed/verified local protection
and are Ready for Human QA. Evidence: runner-guard-main-attempt2.log. The2465 review PR is being
updated with the wrapper and tests. No main merge or deployment was performed.

The allowed-job check also passed: PR2465 head5534586b6, run34474598634, executed254 native
tests plus12 wrapper and6 structural checks through the installed guard. The real job log shows
the trusted preflight succeeding immediately before xcodebuild. Assets460 atb75972d includes
77 forecast and4 project keys in EN/ES; three of these support the pending unfinished-task follow-up.


## Final project-screen refinements (22:36 installation)

Source8137102e8 first installed the shared top-right project settings cog at22:25 (PID72441).
It opens the same account-bound capacity form from What matters, All projects and Time forecast.
The final source594e02e6f was then installed at22:36 (PID74248), adding the subsequent feedback:

- Automatic forecast refreshes are limited to once per15 minutes from the last attempt, including
  failures. Task/project/calendar changes and repeated screen/editor appearances reuse the cache;
  automatic callbacks never restart an in-flight calculation. The shared refresh-arrow button
  forces a fresh calculation. Explicit capacity/horizon changes remain immediate. Account changes
  cannot reuse the previous account's cached snapshot. Applying a work plan still re-reads sources.
- The22:24 clarification is implemented: forecast inputs are the active projects' remote backlog,
  independently of existing Day Plan task placements, cached local edits and local-only tasks.
  Legacy planned_date/habit assignments do not delay forecast allocation. Existing priority is
  retained: project outcome first, then nearest project due date; task priorities apply within
  each project. No task dates or Day Plan records are written by calculating this projection.
  The Day Plan's own capacity/task-to-habit absorption engine remains available in Day Plan.
- New translated labels distinguish Forecast task work from Unallocated work time and explain
  that allocation belongs to this forecast. Both work with stale remote configuration via bundled
  EN/ES fallback. The original remote work/available keys were not overwritten.
- Day details show initially collapsed Habits and Meetings sections. Sleep-only meetings are
  omitted; crossing events show only their awake portions. The reported00:00–06:30 Sleep event
  becomes06:00–06:30 under22:00–06:00 settings. Row clipping uses the matching forecast snapshot,
  not fresh settings/time, and group totals remain the interval-union capacity totals. Seven
  regressions cover clipping, identity, short habits and actual23/25-hour DST days.

The first ForecastRefinementResults build caught incorrect argument order in three new Project
fixtures. Test-only commit594e02e6f corrected it. ForecastRefinementFinalResults then passed all173
selected tests:70forecast,22portfolio,77ToDo and4isolated-host. The normal signed app build passed;
app/helper deep/strict signatures and unchanged designated requirement passed. The exact helper
job was unloaded before replacement, and LaunchServices started one app, one helper and two
embedded servers from ~/Applications. Calendar logged status3/readable=true at22:36:24. Latest
DiagnosticReports remained the17:57:31 crash; no new crash appeared after this restart.

Four older CI server processes (58328,58334,63297,63300) from unisolated runs were found and stopped
by exact PID/path at22:19. The active XCTest host and installed app were preserved. The runner
protection prevents future old-branch app launches; cleanup evidence is stale-ci-servers-cleanup.json.

The22:17:44 cog report and22:18:44/22:19:07/22:19:55 follow-ups are Ready for Human QA, with installed
source/time notes and all user-added instructions preserved. Artifacts: projects-cog-applications-
restart.json, ForecastRefinementFinalResults.xcresult, forecast-refinement-app-build.log, and
forecast-refinement-applications-restart.json in the existing validation directory.

### Unfinished-task download: prepared, not installed

Backend [2387](https://github.com/Focus-Bear/backend/pull/2387), corrected headcb22c9096,
passed full CI34475616672:11,071 tests across338 suites, checks, coverage and smoke. The original
run failed typechecking a test fixture that omitted the DTO's skip getter; it was corrected and
all gates rerun. The production predicate also passed a13-row/four-page PostgreSQL PGlite probe,
including custom-open/raw-COMPLETED rows and external active statuses. No Docker/server or new
backend dependency was required. The PR remains a draft; no merge or deployment was performed.

Mac [2463](https://github.com/Focus-Bear/Mac-App/pull/2463) finale2d8c783d passed full app build
and358 native tests on Jeremy's-RMIT-jeznag (run34477797978):79forecast,23portfolio,47ToDo,
9calendar-picker and4isolated-host cases included. It tested the merge preview69d569d against
maina3298e160. Hardcoded-string checking passed. The config gate correctly awaits85 upstream keys:
84 from assets460 (a106a9f) plus habitInvalidCutoff from462. Both companion asset PRs pass their
JSON checks; do not bypass the dependency gate.

That review branch includes the additive unfinished-only API caller and requires backend2387
released first. It demands meta.excludesCompleted=true on each page instead of silently downloading
4708 historical rows or dropping valid custom/external unfinished work. Project progress uses
validated server counters where source coverage is unambiguous. The installed primary retains
the compatible legacy API caller; its15-minute cache limits repeats, but its first fetch still
includes history. Report21:53:48 is under Needs Clarification/unfinished-task-loading-awaiting-
backend-release-2026-09-10_21-53-48. Release/verify the backend acknowledgement before installing
the filtered caller. The current primary and shared review clone intentionally diverge here;
port independent fixes with scoped cherry-picks, not an automatic whole-branch merge.
