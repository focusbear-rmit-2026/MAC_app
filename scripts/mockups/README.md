# Day Plan mockups

Render the **Day Plan** (schedule + tasks) to a PNG from a JSON scenario — scriptable and
reproducible, so you can knock out a set of example screenshots without touching real
calendar/habit/task data.

## How it works

- A scenario JSON describes a day: the scheduling window, routines (habits), calendar events,
  and the to-do list.
- At launch the app checks for the `FB_MOCKUP_*` env vars (see `DayPlanMockup` at the bottom of
  `FocusBear/Schedule/ScheduleViewController.swift`). When set, it builds a `scheduleViewController`
  in an **offscreen** window, injects the mock data, grows the window to fit the whole day, snapshots
  it to PNG, and quits.
- The task store runs in a non-persisting "mock mode" for the render, so nothing is written to
  `UserDefaults` and your real tasks are never touched.

## Usage

```bash
# 1. Build once (and after any Swift change):
xcodebuild -workspace FocusBear.xcworkspace -scheme "Focus Bear" -configuration Debug -derivedDataPath build

# 2. Render a scenario (PNG lands in out/mockups/<scenario>.png):
scripts/mockups/render-mockup.sh scripts/mockups/high-school-student.json

# Optional: custom output path, width x min-height, and render scale
scripts/mockups/render-mockup.sh scripts/mockups/high-school-student.json out/hs.png 1280x1000 2
```

The size is `WIDTH x MIN_HEIGHT` — width is fixed, height grows automatically to fit the full day,
so the min-height is just a floor.

The scale is pixels-per-point (default 2, i.e. standard Retina). The offscreen window is never
placed on a real screen, so without it the PNG renders at 1x and looks blurry next to normal
Retina screenshots — bump it (e.g. 3) for an even sharper render.

## Authoring a scenario

Copy `high-school-student.json` and edit. Times are `"HH:mm"`; `baseDate` is `"yyyy-MM-dd"`
(defaults to a Monday for reproducibility). Fields:

| key | meaning |
|-----|---------|
| `dayStart` / `dayEnd` | scheduling window (habits pack from `dayStart`) |
| `morningStart` / `eveningStart` | when the morning / evening routines begin |
| `deepWorkCutoff` | free time after this is **not** turned into deep-work sprints |
| `sprintWorkMinutes` / `sprintBreakMinutes` | Pomodoro sizing for deep-work blocks (default 25 / 5) |
| `routines[]` | `{ name, start, end, habits: [{ title, minutes }] }` |
| `events[]` | calendar events: `{ title, start, end }` |
| `tasks[]` | to-do list: `{ title, minutes, project, outcome (1–10), done, subtasks[], at }` |

A task's optional `at` (`"HH:mm"`) **timeboxes** it: the renderer nests it under whichever block
covers that time — a calendar event, or an afternoon deep-work/homework sprint. Tasks without `at`
stay in the "Not yet time boxed" section of the panel. (Timeboxed tasks show in both places: nested
under their block in the timeline, and under "Time boxed" in the task panel — matching the app.)

Emoji in titles render fine — prefix habit/event/task titles with one for a nicer mockup.
