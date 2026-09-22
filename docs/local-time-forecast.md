# Local Day Plan forecast contract

This implements the local calculation and native UI for the 10 September 2026 report
`2026-09-10_11-47-16`. That report supersedes the earlier instruction to use backend
PR #2351. The forecast never calls that endpoint. Only explicitly selected and reviewed work-plan changes write task or project due dates.

**Installation prerequisite:** backend [#2387](https://github.com/Focus-Bear/backend/pull/2387)
must be deployed before this unfinished-only client is installed. It requests
`exclude_completed=true` and requires `meta.excludesCompleted=true` on every task page.
An older server stops after the first response with an explicit update explanation;
it does not silently download all completed history or omit custom/external open statuses.

## Source of capacity

Build each local day's schedule with the existing `ScheduleTab` / `ScheduleBuilder`
inputs, then pass the resulting blocks to `LocalTimeForecast.DayInput.fromDayPlan`.
Pass the same snapshot to the day-plan drill-down, rather than building another
calendar/routine estimator in the forecast screen.

The adapter uses `ScheduleTab.segmentsForDate(includeCompleted: true)` so the full day's scheduled habits, including completed habits today, remain in the budget. Do not sum every
configured habit regardless of weekday/window or treat overflow marker rows as placed
habits. Calendar snapshots honor whole-series and per-day hidden events consistently
with Day Plan. Declined/free/cancelled events are filtered by the shared CalendarManager
predicate. All-day busy or unavailable events consume their clipped awake intervals;
free birthdays and unspecified all-day events do not.

Each day's budget uses its actual local-calendar duration, clipped to time still ahead
for today. Configurable sleep defaults to 22:00–06:00. Calendar events consume only their
overlap outside that sleep window; placed habits consume only time not already reserved
by sleep, calendar events or other habits. Additional self-care is a separate configurable
daily allowance, defaulting to zero for time already represented in habits/calendar.
Settings are saved locally per account. Generated sleep, deep-work and sprint-break filler
rows are excluded. Additional self-care can expose a deficit; work allocation clamps at zero.

Local clock boundaries preserve actual 23/25-hour DST days and seven/nine-hour default
sleep windows. Day Plan's header, date badges and smart-date capacity use the same saved
settings and allocator: free time plus outstanding task work equals the available work
window, with linked habit time absorbed only once. The forecast remains a daily allocation,
not a promise of a particular uninterrupted clock slot.

## Inputs and allocation

- Supply all relevant active projects and unfinished tasks, including unprojected tasks. Paging
  and authorization remain the caller's responsibility. A partial project page must
  not be presented as a complete forecast.
- Use stable server task IDs to reconcile Day Plan tasks with backend tasks; an imported
  task's `DayPlanTask.sourceTaskId` identifies the same work. The engine deduplicates
  repeated IDs/dates/occurrences, but cannot infer that different IDs refer to one task.
- `ProjectInput.outcome` and `TaskInput.outcome` are on the server's /10 scale. Existing
  project `importance` is a distinct legacy 1–4 enum and must not be passed through as
  outcome. Backend companion [#2385](https://github.com/Focus-Bear/backend/pull/2385) adds nullable project outcome. Until selected, a project ranks after rated projects and cannot receive an inferred deadline extension.
- Tasks use known estimated minutes, optional due day, optional explicit future
  `notBefore`, optional dated habit assignment, outcome and perspiration. Missing,
  non-positive or non-finite duration stays unknown; do not manufacture a forecast
  estimate. The native forecast does not fetch completed effort history. Completed local
  habit assignments reserve their used habit share without contributing partial history
  to any project percentage. Server-confirmed unfinished tasks remain unfinished even
  when their raw status is COMPLETED and the custom-open project metadata is unavailable;
  those tasks still consume capacity as unprojected work. Hydrated local `done` flags
  cannot override this server guarantee: the cache derives them from raw status and
  has no reliable pending-completion marker. A fresh local completion may remain in
  the forecast briefly until its existing sync reaches the server.
- Project outcome sorts first, then project due day, then stable project ID. Inside a
  project, task outcome sorts first, then task due day, lower perspiration and task ID.
  Unprojected tasks compete using their own outcome, due day and perspiration. No
  project or day gets a separate copy of the available hours.
- Work is divisible into daily slices. Explicit future placement/habit assignment
  prevents allocating that task before its chosen day. Otherwise the highest-priority
  work fills the earliest capacity, including weekends when the Day Plan leaves time.
- A dated habit assignment shares one occurrence's remaining capacity across tasks in
  priority order. A completed linked task reserves its already-used share first. A
  17-minute task in a 10-minute habit needs 7 extra work minutes. Matching uses the
  Day Plan's existing `habit:<title>` key; a future stable-ID migration must update both
  surfaces together. Equal-title occurrences on one day share their combined capacity.

`Result.days` contains the categories and task slices. `Result.weeks(calendar:)`
groups them by calendar week. For stacked charts use allocation `workMinutes`, since
`absorbedHabitMinutes` is already inside the habit category. Project drill-downs may
show both. Unknown estimated tasks should be explained by localized UI copy.

`ProjectResult.likelyCompletionPercent` is effort-weighted completion by the inclusive
project due day, or horizon end for a project without a due date. It includes completed
known effort. A project with missing estimates returns nil rather than displaying a
misleading percentage. Completion beyond the supplied horizon remains unresolved.

## Suggestions and work plans

`nextSlot` runs the same allocator with the draft task included, so project/task
outcome and perspiration affect its position. A large task may span days; the result
separates its start and completion date. An overfull horizon has `fits == false` and
no invented fallback completion date. `fitsOnDay` checks a manually chosen date
against existing reserved work and warns rather than silently displacing other tasks.

`proposeWorkPlan` returns only typed due-date changes and conflicts. The UI must show
old and proposed dates and require explicit review before calling existing write APIs.
Revalidate permissions and the source snapshot before committing; do not overwrite a
concurrent edit. It may pull task dates forward to reflect higher-priority project
work. An already-achievable project deadline is retained.

Hard deadlines (/5 value 5, wire 10) never move later automatically or appear as a
proposed extension. Insufficient capacity is a visible conflict. Extension heuristics
for other outcomes are 21 days at /5 value 4, 90 days at 3, 365 days at 2, and no finite
limit at 1. Work beyond these limits or beyond the forecast horizon is a conflict,
not a silently altered deadline. These are transparent planning assumptions, not
rules inferred from the old 1–4 project importance enum.

## Validation

`LocalTimeForecastTests` exercises the production allocator, overlap/DST/day bounds,
priority order, estimates, absorption sharing, completion percentages, suggestions,
manual date warnings, weekly totals and safe work-plan proposals. The suite is wired
into the app test target and explicitly included in the unit workflow. That workflow
uses the existing self-hosted Mac runner, following the user's preference to avoid
GitHub-hosted macOS costs. Validation jobs run serially using its configured toolchain.

The DEBUG XCTest host loads bundled configuration and skips normal authentication,
desktop UI and background-service startup. Local builds/tests and synthetic visual
fixtures are authorized; database servers and Docker are not needed. Swift syntax,
project plist, translation and whitespace checks supplement the executable tests.

## Native surfaces and review dependencies

The Projects tab has Time Forecast beside All Projects. What Matters retains its existing
Ask for extension / Start now / Backburner groups using local estimates for the remaining
work. All Projects sorts the complete active catalogue alphabetically and uses validated
server `task_count` / `uncompleted_task_count` counters for actual completion. Native and
imported counters describe different task sets; merged-source ID collisions, missing or
invalid counters leave completion unavailable. No percentage uses an unfinished-only
list as its total historical denominator. Display-name reconciliation preserves newer
planning metadata. Optional synced-provider names require backend #2386. Selecting a day opens a read-only lightbox of the exact schedule snapshot
used by the forecast. The forecast store pages the complete task/project catalogue,
rejecting failed or incomplete pages rather than displaying partial data as complete.
Calendar queries run on a dedicated queue and calculations run off the UI thread.
Missing calendar permission is shown as incomplete coverage and disables plan writes.

Task and project outcome pickers use 1–5 and multiply choices by two for the wire.
Legacy odd values and unset values stay unchanged until edited. Wire value 1 displays as 1/5 while staying unchanged until an explicit selection; the remaining half steps display exactly. Date durations use the app language and fonts follow the app font preference. The Day Plan task
picker, tooltip and typed `*1`–`*5` shortcut use the same scale. New task sheets show
a capacity-based suggested date (or start/completion range for multi-day work), and
warn when a manually chosen day is full. Dragging tasks into habits updates Day Plan
work totals with shared absorption, including a completed task's already-used share.

The work-plan sheet initially selects no changes. It reloads the full snapshot after
approval, rejects changed inputs, checks the current record before each write, and
sends a minimal due-date update. A failure stops the sequence and reports how many
changes were saved; it never claims the operation was transactional. The existing
backend APIs have no compare-and-swap token, so a concurrent edit in the narrow
GET-to-PUT interval cannot be prevented by the client. Backend #2385 adds the missing
`updated_at` and `eisenhower_quadrant` fields to the existing task lookup for these
checks. A future conditional-write API can close that remaining race.

Translations: [assets #460](https://github.com/Focus-Bear/assets/pull/460), 77 forecast
and four project keys with English and Spanish parity. Both local fallback config files are bundled. Backend outcome/task-read fields require
#2385, optional provider metadata requires #2386, and unfinished-only loading requires
#2387 to be deployed before the new client. The existing installed app remains unchanged
while that prerequisite is pending.
