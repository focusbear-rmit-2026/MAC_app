# Local report follow-up — 18 September 2026

Read `CLAUDE.md`, the four new reports, and the three existing reports with fresh follow-ups.

## Changes

- Early morning routine start no longer uses abort-shutoff/postpone-evening password rules. Unlock computer and Work emergency retain their gates.
- Removed the automatic routine-duration sheet. Existing completion callbacks now continue without presenting it.
- Routine timing opens through the settings password gate. The general settings rule remains effective after cutoff, alongside the cutoff-specific rule and existing unlock grace period.
- Meeting, routine and deep-work cards share the duration scale without the former 120-point cap. Content is vertically centred; readable content sets the minimum height. Expanded deep-work sprints size individually, while collapsed runs size by their total span. Overflow markers stay content-sized.
- Project dropdown selections now notify their SwiftUI binding immediately; programmatic menu reloads do not masquerade as user selections.
- Reprioritisation proposes a Day Plan move even when the task already has the proposed due date but remains placed on another day. Hard deadlines and locked days remain protected. The conflict-row date link uses the existing translated “Edit due date” label without grammar examples. Day Plan snoozing already updates both planned and due dates in one write.
- The installer verifies the staged main/helper bundles and stable signing requirement before stopping the installed app. It stops exact installed executable paths, tries SIGTERM before a bounded fallback, and retains the prior bundle.
- Corrected the offscreen renderer to restore its requested size after attaching the controller.

## Validation

- DayPlanEventHeightTests and DayPlanRoutineDraftTests: 20 tests, zero failures.
- ForecastReschedulingTests, LocalTimeForecastTests and ProjectNotesFeedTests: 316 tests, zero failures.
- New regressions cover selecting a dropdown row before blur and moving a misplaced task whose due date already matches its forecast date.
- Shell syntax and git whitespace checks pass.
- Final workspace Debug build succeeded. Offscreen rendering confirms the 12½-hour card is 412.5 points tall with centred content and the half-hour card remains readable.
- Installed at `~/Applications/Focus Bear.app`; main app, helper and embedded servers confirmed running there after the helper restart interval. Main/helper signatures verified and the installed designated requirement matches the prior build.
- Previous bundle retained at `~/Applications/.focus-bear-old.20260918-053150.39259`.
- No new Focus Bear crash record appeared after relaunch. Live password flows still require human QA.

## Crash evidence and limits

The newest Focus Bear crash record available is `Focus Bear-2026-09-17-212107.ips`, captured at 21:20:54 on 17 September. It aborts in `NSStoryboard.nibForStoryboardNibNamed` while instantiating `firstViewControllerObj` from a Day Plan refresh. The screenshot reported the following morning does not establish a new crash time. No 18 September Focus Bear crash record was present during investigation.

The installer changes mitigate incomplete/replaced bundle resources, but do not prove that the reported crash has been reproduced or eliminated. Human QA is still needed for that report and for the live password flows.

## Update — 2026-09-18 06:03 — monitoring and focus-session follow-ups

- Started an active-session watcher of `TASK.md` and `USER-STATUS.json` throughout `~/FocusBear-Claude-Tasks`, polling every 20 seconds. It detected report `2026-09-18_05-53-21` during this batch. This is an active-session watcher, not a scheduled agent that can act after the session ends.
- Active focus-task titles use the same selectable-text view as task details (macOS 12+).
- Focus-session create/edit forms accept explicit minutes instead of the generic perspiration slider. Duration saves in seconds, updates the session queue, and participates in stale-edit detection. New tasks are due today.
- Added global Option-Command-V for menu voice input and a shortcut tooltip on the microphone. It uses the menu's subscription gate and permission/recording action; repeated presses do not restart recording or processing while the voice screen is active.
- Validation: FocusSessionTests executed 157 tests with one existing skip and zero failures. Installed the signed build; previous copy retained at `~/Applications/.focus-bear-old.20260918-060216.62557`.
- Backend urgency work is in draft PR https://github.com/Focus-Bear/backend/pull/2434. 192 existing service tests passed; six live-model evaluation fixtures render successfully. Live-model evaluation was not run (no local API credential; installed promptfoo also requires a newer Node runtime). Awaiting validation, human review and deployment.
- Reviewed existing backend PRs https://github.com/Focus-Bear/backend/pull/2429 (shared task edits) and https://github.com/Focus-Bear/backend/pull/2430 (streak/completion denominators). Both already contain code fixes and have passing CI. Their reports remain blocked on backend merge/deployment; no duplicate PRs or merges were made.

## Update — 2026-09-18 06:18 — confirmations and CI follow-up

- Report status updates confirm the voice shortcut and selectable active-task title are fixed. A fresh scan found no feedback newer than its review notes or user confirmation.
- Backend PR #2434 passed checks, all four test shards, coverage and smoke. The live-model evaluation limitation above still applies.
- Mac integration CI exposed an existing date-dependent test: its fixed 16 September date stopped formatting as “Yesterday” after midnight. The test now constructs yesterday in its pinned Melbourne calendar, retaining an exact ten-hour interval across daylight-saving transitions. LocalReportStatusTests passed locally.
- Integration CI also reports three existing hardcoded strings (upgrade close tooltip and accountability-buddy settings copy) and nine existing config strings missing from the assets repository (quit feedback and outcome deadline choices). These are outside this report batch; the integration branch is not fully green.

## Update — 2026-09-18 06:24 — reprioritising rework detected by monitor

- Addressed the 06:16 follow-up on `reprioritise-banner-and-menu-rename-2026-09-16_22-22-50`.
- Placement-only proposals now show “Day Plan” and the actual old placement → proposed day, rather than an unchanged due date → itself. Major/minor grouping uses that move distance. Matching-date proposals for locked placements are suppressed.
- Project forecasting now costs placed tasks using their Day Plan durations. The review duration badge uses the same estimate; editing it updates the Day Plan copy after the server write succeeds. Apply compares the complete task input snapshot, including placement and estimate, before proceeding.
- Regression reproduces the reported Monday load (5 + 15 + 15 minutes, only 10 minutes available) and verifies offered moves leave no more than 10 minutes on Monday. This tests the identified mismatch, not the entire live account portfolio.
- Both forecast suites passed: 246 tests, zero failures. Final signed build succeeded; installed and verified main/helper signatures and installed process paths. Backup: `~/Applications/.focus-bear-old.20260918-062346.77219`.
- Mac logic CI passed on `eadf00505`; pre-existing translation checks remain red. Latest reprioritising changes still need human QA on the live account.

## Update — 2026-09-18 09:06 — stale gardening tab over Cloudflare

- Screenshot and clarification report the gardening-page warning while Cloudflare is active. Logs confirm repeated decisions for `127.0.0.1:3118`; direct CLI verification of Chrome's live tab was denied by macOS Automation permissions.
- Chrome URL reading previously selected the first nonblank window in enumeration while title reading selected `front window`. The reader now explicitly captures the front window ID and reads its active tab URL, title and bounds together. Other windows are examined only for the existing `about:blank` call-window fallback. An unreadable front window cannot silently select a background page.
- URL checks, warning dismissal polling, title reads and warning bounds share this selection. The change addresses the inconsistent window-selection path; the exact live tab-switch reproduction still needs confirmation.
- 60 targeted tests passed across relevance freshness, cache and buddy task-picker suites. Regression covers a background gardening window preceding the front Cloudflare window, stale gardening verdict rejection, tab changes, failed front-window reads and blank call-window fallback. Final AppleScript compiled against Chrome's installed dictionary; signed app build succeeded.
- Installed main app and helper signatures and process paths verified. Previous bundle: `~/Applications/.focus-bear-old.20260918-090611.89000`.

## Update — 2026-09-18 09:51 — resumed report queue and due-date rework

- `d7bad9235`: isolated logic-test credentials in memory; restored the existing multi-turn buddy chat for extensions with approved-duration limits; re-check meeting state after finishing focus before resuming habits; removed the unwanted “Done adding tasks” control. 109 targeted tests passed and the signed app was installed.
- `80d18fff8`: block subtitles consume `isTaskMisalignedWithIntention` from the existing safety response and no longer request a separate alignment decision. 39 targeted tests passed; installed. Backend draft PR #2436 has 200 local service tests and all CI checks passing; it remains unmerged, so the report is blocked on deployment.
- Replaced independent Day Plan placement dates with due-date reconciliation across the complete paginated unfinished catalogue. Overdue work belongs today; future views show unfinished tasks due on or before that day without storing duplicate copies. Missing dates and later due dates remove stale unfinished placements. Incomplete/failed reads and reads overtaken by local edits do not replace the cache.
- Explicit day moves write due dates; successful To-do due-date edits update existing Day Plan copies immediately. Forecasts use the same due dates and local durations. Removed placement-only reprioritisation proposals. Completed history, local-only tasks, row order, and same-day block assignments are preserved.
- 327 targeted tests passed across ScheduleKit, LocalTimeForecast and ForecastRescheduling. The signed app was installed and launched; previous bundle retained at `~/Applications/.focus-bear-old.20260918-095017.19455`. Live portfolio behavior awaits human QA.
- Crash report `2026-09-18_04-32-16` was already confirmed fixed by the user at 2026-09-17T20:36:18Z. Filed it with that confirmation; no new crash diagnosis is claimed.

## Update — 2026-09-18 10:20 — monitored outcome styling report and CI follow-up

- Picked up new report 2026-09-18_09-52-41 while monitoring. Lowest outcome band now has no grey background and uses normal text contrast. Installed signed build; backup `~/Applications/.focus-bear-old.20260918-102018.38397`.
- Full integration CI ran 1,797 tests; three assertions failed in DayPlanProjectRepair and FocusStart because shared-store fixtures imported unrelated saved tasks through the new future-day projection. Added an in-memory fixture initializer and isolated the affected fixtures; production projection remains enabled. The affected suites plus ScheduleKit passed all 160 tests locally.

## Update — 2026-09-18 10:29 — future-day semantics clarified while monitoring

- Picked up report 2026-09-18_10-24-41: overdue is relative to actual today, not the viewed day. Removed future-day carry-forward projection; each task appears on max(today, due date) only.
- Regression reproduces Friday overdue/due-today tasks, Saturday's own task, and empty Sunday. All 160 targeted tests passed. Signed app installed; backup `~/Applications/.focus-bear-old.20260918-102905.44890`.
- Full unit-test CI passed for previous commit 660a5c3ca after test-fixture isolation.

## Update — 2026-09-18 10:37 — three new reports handled while monitoring

- 10:28 menu report: running-habit card uses a one-task Day Plan preview rather than four.
- 10:29 description report: enabled horizontal scrolling and document resizing for long URLs in the expanded task editor.
- 10:30 autocomplete report: project-only completion retains a local draft, keeps the editor/caret active, and does not let an empty name discard it. Existing task names are retained until a real name is committed.
- 138 targeted tests passed; signed app installed, backup `~/Applications/.focus-bear-old.20260918-103657.50423`. Live laptop layout/keyboard behavior awaits human QA.
- Full unit-test CI passed for 32370f14f (future days contain only their own due tasks).

## Update — 2026-09-18 11:26 — buddy queue and three monitored follow-ups

- Added optional structured Day Plan candidates/selected IDs to the existing buddy request/response. Mac validates against the offered and current unfinished tasks and seeds the queue before session startup. Backend draft PR #2437 (7959d93) is required for live matching; no merge/deployment performed.
- Backend: 377 tests passed, lint passed with numeric-literal warnings, four prompt-evaluation fixtures rendered (no live model run). Mac: 199 tests passed with one existing skip; final combined build passed 49 targeted tests.
- Task regrouping scrolls to the edited row after rebuild; description scrollers use the always-visible legacy style; “fri 18th” respects the explicit day number rather than jumping to next Friday.
- Signed combined build installed; backup `~/Applications/.focus-bear-old.20260918-112202.80367`. Latest live UI fixes await human QA. User confirmed the lowest-outcome background and future-day overdue fixes.

## Update — 2026-09-18 12:09 — Completed buddy extension and noon rework

- Report 12:01:30 logs show the completed buddy restarted at 12:01:11 without entering the extension chat. Completion-screen extensions now obtain fresh chat approval before routine re-postponement/password continuation or scoped-session restart, and use the approved duration throughout. Just-completed buddies still require approval after their live AI blocking stops. Cancelling grants no additional time.
- Explicit weekday/day inputs such as `fri 18th` now resolve within the viewed month, including Friday September 18 when moving a task from Saturday September 19. Bare weekday and bare day-number shortcuts keep their existing behavior.
- Project Tab autocomplete immediately regroups the row, restores its name editor and caret, scrolls it into view and briefly highlights the row. Internal editor replacement does not commit a partial task; reduced-motion preference is respected.
- 80 targeted tests passed across FocusSessionExtension, AccountabilityPostponeRecovery, SmartSnooze and TaskNameCommit. The AppKit regression exercises real project suggestions, Tab, row replacement, blank draft preservation and field-editor focus restoration. Signed build installed; previous bundle retained at `~/Applications/.focus-bear-old.20260918-120909.13448`. Live flows await human QA.

## Update — 2026-09-18 12:30 — Quantity Tab selection and focus rework

- New report 12:25:05: the quantity form explicitly used end-of-text focus when moving between numeric questions. Tab now selects the destination value for overwrite; Shift-Tab moves backward and also selects it. Both slider-backed values and count inputs use the existing select-all helper.
- Autocomplete follow-up 12:26:09: preserve the actual field-editor owner during reload, including the interval before AppKit sends textDidBeginEditing. Click and Return project acceptance now retain editing focus, matching Tab.
- 36 tests passed across TaskNameCommit and SmartSnooze, including AppKit tests for Tab and Return restoration followed by an immediate refresh before typing. Signed build installed; backup `~/Applications/.focus-bear-old.20260918-122959.24411`. Human QA still needed for the latest focus fix. The explicit weekday-date report is now user-confirmed fixed.
- Full unit-test CI for the previous commit 9e83920fd passed (run 35298280529); its translation checks still report the existing three hardcoded and nine missing asset strings.

## Update — 2026-09-18 12:54 — Snooze refresh, fresh queues and file previews

- Report 12:43:13: snooze already writes due_date and planned_date together. Its explicit move now ends the name/duration editor before changing rows, allowing the focus-preserving refresh guard to redraw the old day. The AppKit regression verifies local placement on the destination and removal of the old visible row. The screenshot obscures the task name, so the exact account task/server result has not been independently verified.
- Report 12:44:51: logs show a new buddy session for DMG/LinkedIn at 12:44:14, while the screen recycled a completed ATSuper task. Legacy responses without selectedTaskIds now produce an explicit empty queue. Menu/new scoped starts no longer fall back to lastTaskUsed. An extension explicitly retains unfinished tasks from the same session. Backend PR2437 remains needed for AI-selected task population.
- Report 12:45:51: the active-task card now loads files by its current task ID and renders the shared attachment list in preview-only mode. It uses the existing in-app image/PDF/text preview and recreates its store when the active task changes. Existing editing surfaces retain file upload/removal and paste behavior.
- Menu rework 12:43:31: the SwiftUI host ignores an extra safe-area inset inside AppKit content bounds, removing the detached-menu grey strip. Live visual confirmation is still needed.
- Snooze-focused run: 118 tests passed. Combined focused run: 314 tests, one existing optional skip, zero failures. Signed build installed; backup `~/Applications/.focus-bear-old.20260918-125333.39318`. Previous commit 4e562672f passed full unit-test CI (35299625488); the user confirmed completed-buddy approval and project autocomplete focus fixed.

## Update — 2026-09-18 15:36 — Tab limit counts and Chrome process identity

- Report 15:13:36: the account has the limiter enabled with a saved limit of four (report says five; preference left unchanged). Initial installed diagnostics counted one Chrome tab. NSWorkspace shows two real Chrome processes plus a separate cloned app using Chrome’s bundle ID, so name-based AppleScript can target the wrong instance.
- Chrome tab snapshots now address each real Chrome process by PID and retain process/window identity for closing an excess tab. Duplicate process discovery and repeated browser cache contributions are deduplicated. A failed process read invalidates the snapshot instead of returning an understated partial count; existing Automation permissions remain required.
- All supported tab-limit branches compare the observed current count with the configured limit, including multiple tabs opened together. An already-over-limit starting snapshot warns without deleting existing work. Window-specific close operations no longer assume the extra tab belongs to the front window.
- 22 targeted tests passed, including AppleScript-compatible absolute-ordinal encoding, two Chrome processes independently using window ID 7, duplicate process discovery, a partial read failure, cross-browser totals, several new tabs in one poll, and an existing excess. The standalone native read probe reached the normal macOS Automation denial (-1743); it did not verify the live count. An intermediate native reader returned an unavailable snapshot; comparison with an AppleScript reference exposed an absolute-ordinal descriptor mismatch, now corrected and regression-tested. The corrected signed build is installed (backup `~/Applications/.focus-bear-old.20260918-154152.43038`); At 15:42:55 the installed reader successfully counted eight Chrome tabs across three windows/two processes (old reader: one tab), emitted the existing-excess warning, and tracked subsequent counts seven, six and five. Automatic rejection of a newly opened excess tab still needs human QA.

## Update — 2026-09-18 16:03 — Exclude headless Chrome from the user tab limit

- Follow-up 15:58:05: the extra tab was a headless Chrome process launched for a local automation job, not a stale cache. Its bundle/path match normal Chrome, but NSWorkspace reports activationPolicy=prohibited; normal Chrome is regular.
- Chrome discovery now excludes processes unable to present a user interface. Aggregate cache counting also ignores prohibited applications, so a remaining headless process cannot keep a closed user browser's cached tabs alive. Hidden/minimized ordinary Chrome windows remain included.
- 23 targeted tests passed, including normal Chrome, headless Chrome and a cloned app. Signed build installed; backup `~/Applications/.focus-bear-old.20260918-160221.56336`. Awaiting the next live read/user confirmation of the adjusted total.
- Full unit-test CI passed for f6165de50 (run 35312391975). User confirmed quantity Tab selection, adding multiple tasks, focus-session add-task popup, and reprioritisation banner/menu fixes.

## Update — 2026-09-18 16:13 — Restore the full planned-task duration

- Report 16:01:51: the header used net committed minutes after habit absorption. A five-minute task fully covered by a habit therefore disappeared from the planned-total label, leaving only the ten-minute buffer.
- The header now shows the full duration of unfinished tasks. Buffer and over-capacity calculations still use the forecast's net committed load, preventing double-counting of work already covered by habits. Existing translated strings are reused.
- 161 tests passed across LocalTimeForecast and TaskNameCommit. The AppKit regression verifies a visible five-minute planned total with full, partial and no absorption, while the buffer respectively reads ten, seven and five minutes.
- Signed build installed after the shared CI process finished; backup `~/Applications/.focus-bear-old.20260918-161212.63604`. Human visual QA remains pending.
- Headless-browser follow-up 8aba8d5a0 passed full unit-test CI (35313299923); its installed diagnostic matched the user's three tabs across one normal Chrome process.

## Update — 2026-09-18 16:26 — Address active Chrome pages by process

- Report 16:14:08: screenshot shows Cliq while repeated relevance requests name the Geelong quote tab. The active URL/title/bounds reader still used name-based AppleScript, which can address the headless Chrome instance despite the corrected tab counter.
- Active-page reads now target an eligible normal Chrome process by PID, prefer the foreground instance, and retain that instance while Focus Bear's popup owns focus. URL/title are obtained together from tab properties, with the corresponding window bounds. Window/tab IDs are rechecked before accepting the observation. The existing blank Meet-window fallback remains within that same normal process. Total read time is bounded; Automation denials retain their normal handling.
- 28 targeted tests passed: process selection, popup focus, URL/title/bounds, tab/window switches, blank call-window fallback, plus tab-limit regressions. No new user-facing strings. Signed build installed; backup `~/Applications/.focus-bear-old.20260918-162247.70601`. Live browser observation and popup QA are still pending.
- Planned-duration b2ea2be87 passed full unit-test CI (35313937970).

## Update — 2026-09-18 17:17 — Cutoff applies to focus-session extensions

- Rework 16:59:48 on report 2026-09-17_17-05-10: logs show a five-minute extension at 16:59:00 with 42 seconds still running and cutoff 17:00. A postpone-duration clamp measured from now cannot safely limit minutes added to an existing focus-session end. Its running-postpone floor could also inflate an extension approval.
- Added a separate extension limit measured from max(now, current session end), with completed-session restarts measured from now. It applies to routine-linked focus/buddy sessions; an existing longer routine/meeting postpone does not authorize additional focus time. Strict after-cutoff refusals and the existing non-strict after-cutoff behavior remain distinct.
- Rechecks run before the buddy chat, after approval, after postpone/password sheets, and at the running-session timer mutation. The timer uses the resulting absolute end date, avoiding elapsed-second rounding pushing it beyond cutoff. The chat's extension path no longer applies the routine postpone floor.
- 65 targeted tests passed across cutoff limits, focus extensions and postpone recovery, including the exact 42-second incident, two minutes of remaining extension room, fractional-minute boundaries, completed restarts, and approval crossing cutoff. Changed Swift code passes the hardcoded-string check.
- Signed build installed; backup `~/Applications/.focus-bear-old.20260918-171450.1287`. Live near-cutoff UX needs human QA; no user cutoff/settings were changed. New EN/ES explanation is in draft assets PR #505 (22100ac); both JSON files parse, placeholders match, and English matches the local config. No assets merge/deployment performed.
- Chrome URL reader efb2263b7 passed full unit-test CI (35314863474); live normal-Chrome reads selected Zoho Writer. User confirmed the planned-duration total fixed at 16:44:56.
