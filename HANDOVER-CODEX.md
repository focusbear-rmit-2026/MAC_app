# Handover — Focus Bear Mac App

Written 2026-09-10, midday. The build/relaunch instructions were updated after evening local testing.
Other commit hashes and counts below describe the midday handover, not the latest running build.

The working checkout is `/Users/s3255727/dev/Mac-App` on branch
`test/mega-relevance-shadow-webview` (called "mega" throughout). Head is `18d9b260`.
The running app is built from that branch. 720 tests pass on it.

---

Latest evening state: [local feedback validation](docs/local-feedback-validation-2026-09-10.md).
It records the installed build, completed PR checks, crash correction and unresolved forecast report.

## 1. Building and relaunching

Build via the **workspace**, not the project, and note the scheme name has a space in it.

```bash
cd /Users/s3255727/dev/Mac-App
xcodebuild -workspace FocusBear.xcworkspace -scheme "Focus Bear" \
  -configuration Debug -derivedDataPath build \
  CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION=YES build 2>&1 \
  | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Swap `build` for `test` at the end to run the suite. That entitlements flag is required on
current main or the build fails with "Entitlements file modified during build".

**A build takes 8 to 20 minutes and exceeds the 10-minute shell timeout.** Background it and
poll, never run it in the foreground:

```bash
nohup xcodebuild … > /tmp/build.log 2>&1 & disown
for i in $(seq 1 26); do
  grep -qE "TEST SUCCEEDED|TEST FAILED|BUILD FAILED" /tmp/build.log && break
  sleep 30
done
```

**Local testing uses `~/Applications/Focus Bear.app`**, as requested on September 10.
Build output is staging only: never run the user's app from a DerivedData directory that the
next build or test will overwrite. Keep `Config/Local.xcconfig` and the stable Apple Development
signing identity. Verify both the app and `Contents/Resources/FBHelper.app` with
`codesign --verify --deep --strict`, and compare the app's designated requirement with the
currently installed copy before replacing it.

Stage a complete bundle beside the installed app, keep a backup, then replace the bundle while
it is stopped. Stop the **exact Focus Bear helper LaunchAgent before its process**:
`gui/<uid>/com.focusbear.focusbearhelper.plist`. A loaded job can keep its old build-directory
path even after its plist changes, relaunching the wrong copy. Stop only processes whose full
executable paths belong to the app being replaced (helper first, then main app and its embedded
servers). Use SIGTERM first and a bounded exact-process fallback when a routine blocks quitting.
Do not use broad `pkill server`, which could stop unrelated applications.

Launch the installed copy through LaunchServices:

```bash
open -a "$HOME/Applications/Focus Bear.app"
```

The app recreates its helper registration from its own installed bundle location. Verify the
main app, helper and embedded servers all run from `~/Applications` after startup and again
after the helper's ten-second restart interval. Do not directly execute `Contents/MacOS/Focus Bear`.
Check permission observations in the normal Debug_Logs and inspect new DiagnosticReports before
calling the restart healthy. A matching signature is necessary but is not proof that every
permission was granted.

### Counting test results

Do not count `Test Case … passed` lines; they interleave and give wrong totals. The
authoritative line is:

```bash
grep -oE "Executed [0-9]+ tests, with [0-9]+ failures" log | sort -u -t' ' -k2 -n | tail -1
```

I misreported test counts several times before working this out.

### Worktrees

Agent work goes in `~/dev/claude-worktrees/<name>`, branched off `origin/main-human-verified`.
Every new worktree needs two things or you will waste time:

```bash
ln -sfn /Users/s3255727/dev/Mac-App/Sparkle.framework "$W/Sparkle.framework"
cp Config/Local.xcconfig "$W/Config/Local.xcconfig"
```

Without `Local.xcconfig` the build is ad-hoc signed, which makes macOS re-prompt for the
keychain on **every** build and lose calendar permission grants.

### Trust xcodebuild, not the editor

SourceKit reports false "cannot find type X in scope" and "No such module 'Focus_Bear'" across
files in the same target, constantly. They are not real. Only `xcodebuild` decides.

---

## 2. Branch and PR rules

- PRs always target **`main-human-verified`**. Mega is a local integration branch and must
  never be a PR base.
- The repo **squash-merges**, so every merge makes other open PRs conflict.
- **A CONFLICTING PR silently gets no CI at all.** It shows no red, just no checks. This bit me
  three times. Sweep for it:

```bash
gh pr list -R Focus-Bear/Mac-App --limit 40 --json number,mergeable \
  -q '[.[]|select(.mergeable=="CONFLICTING")|"#\(.number)"]|join(" ")'
```

  The fix is to merge `origin/main-human-verified` into the branch, build, test, push.

### Conflict traps, learned the hard way

- **Keep-both on `project.pbxproj` is safe** (entries are independent lines), but validate after:
  `plutil -lint`, check no `path = FocusBear/<Group>;` line lost its `sourceTree`, and check no
  reference points at a deleted file.
- **Keep-both on Swift is NOT safe.** Three times a conflict boundary cut through the middle of a
  function, and keeping both sides produced unbalanced braces. Always check
  `s.count('{') == s.count('}')` after resolving and read the junction.
- **Nested parentheses in commit subjects break naive regex** on conflict markers
  (`>>>>>>> sha (subject (with parens))`). Resolve line-by-line instead.
- The CI workflow lists every test suite by name, so **every branch that adds a suite conflicts
  on the same line**. Almost always keep both.

### The CI suite list — important

`.github/workflows/unit-tests.yml` names each suite explicitly with `-only-testing:`. **A test
in a suite that is not on that list never runs in CI.** Adding a test file to the project is not
enough. Check your suite is listed.

---

## 3. Bug reports

The in-app "report problem" feature writes folders to **`~/FocusBear-Claude-Tasks/`**, each with
`TASK.md`, `logs/` and `screenshots/`.

- **Unprocessed** reports sit at the top level, named `2026-MM-DD_HH-MM-SS`. There are 32.
- **Finished** work moves to `Ready for Human QA/`, renamed
  `descriptive-hyphenated-<original-timestamp>`, with a `CLAUDE-NOTES.md`.
- **Blocked or ambiguous** ones move to `Needs Clarification/` with notes explaining what is
  needed.

Always open the screenshot. Several reports were only diagnosable from the image, and the words
alone would have sent you the wrong way. The logs are genuinely useful too: `dayplan reload:`
and `[user-action]` lines are committed on main and answer "did this code even run".

### Two reports arrived at 11:47 and 11:49 and are NOT started

**`2026-09-10_11-49-19` — AI buddy fails open on a backend error.** The buddy showed "Something
went wrong. You can try again, or just do your habit." The user's words: *"this can't happen. If
there's a backend error, it needs to let me choose how long to postpone for and hold a button for
10 seconds to confirm I want to postpone my habits"*. The point is that a backend failure
currently hands out a free pass; it must instead force a deliberate, held-button confirmation.
This is the same fail-open class as Mac-App#2426 (auth logout stops all blocking), which the user
marked urgent.

**`2026-09-10_11-47-16` — a large product spec, not a bug.** It asks for a Time Forecast tab, a
rewritten time-available calculation, a likely-percent-completion estimate on project risk, an
outcome scale reworded to 1–5 (multiply/divide by 2 on the wire to keep the server's /10 scale),
a "Generate a work plan" button, next-free-slot suggestion when creating a task, and task-onto-
habit absorption in the free-time maths. **Read the full `TASK.md`; the summary above loses
detail.** It says explicitly: *"Let's do the forecast calculations locally for now"*. This is
several days of work and should be broken into pieces, not handed to one agent.

---

## 4. What I deliberately did NOT do

These are refusals with reasons, not omissions. Please do not quietly reverse them.

**Project note bodies stay web-only.** Notes are Yjs collaborative documents.
`ProjectNoteRealtimeProvider` prefers `yjs_state`, autosave re-renders `content` from the merged
document, and `updateNote` never writes `yjs_state`. A Mac write to `content` would be invisible
and then clobbered, corrupting a document shared with the web app. Shipped instead: note **title**
rename (a plain column) and a line in the pane saying why the body is web-only. Blocked on
backend#2377 / coord t117. Report filed under
`Needs Clarification/project-notes-editable-blocked-on-backend-2026-09-08_22-14-28`.

**Project emoji picker not built.** `UpdateProjectDto` has no `icon` field, and the global
`ValidationPipe` sets neither `whitelist` nor `forbidNonWhitelisted`, so sending `{icon}` returns
**200 with the write silently dropped**. The picker would have appeared to work and then reverted
with no error to catch. Filed as backend#2384 and coord t121.

**The time forecast Mac UI is parked.** Report `2026-09-08_22-14-12` is still at the top level.
Backend#2351 is still based on `feat/portfolio-dynamic-capacity` rather than the Day Plan
simulation in #2364, and carries three blockers from review. The user decided the forecast must be
driven by the **Day Plan**; building against the current endpoint would create a second allocator
disagreeing with it. Note the new 11:47 report supersedes part of this and asks for local
calculation — reconcile the two before starting. Tracked as coord t118.

**The 87 other force-unwraps of `startTime` are untouched.** I fixed the one with a crash report
behind it (#2457). The rest sit in routine-active paths where the value has loaded. They are a
standing risk, but sweeping 87 sites blind would be an unreviewable change.

**Four long-lived branches left conflicting**: #2369, #2223, #2090, #2070 — the relevance/ONNX and
dashboard-webview work, six weeks to ten days old. Merging main into those is a real resolution
job, not a monitoring-tick fix.

**About 25 of the 70 newly-wired tests are hollow** and were left in place. In
`RoutineSchedulingTests`, 13 of 15 call private helpers defined *in the test file* that
re-implement the scheduling logic, so they cannot catch a regression. Two `TimeParsingTests`
reduce to asserting `22 > 2`. They were flagged for a rewrite rather than deleted.

**`gh pr merge` is blocked for me** by the permission layer, so nothing has been merged. Every
merge below needs a human.

---

## 5. Open PRs and the merge order that unblocks them

Sixteen of my PRs are open and mergeable. Eight are fully green:

`#2441 #2445 #2446 #2450 #2453 #2455 #2457 #2460`

The other eight are red on **one check only**, `Local config strings exist in assets repo`:

`#2433 #2444 #2448 #2449 #2451 #2458 #2459 #2461`

That check compares the **whole** local config against the assets repo, so a PR goes red over
strings it never touched. Nine assets PRs are open and all mergeable:

| Merge | Unblocks |
|---|---|
| assets #454 | #2433, #2438, #2439 — three project-lifecycle strings on Mac main that were never filed in assets |
| assets #449 | #2444 |
| assets #450 | #2448 |
| assets #451 | #2449 |
| assets #452 | #2451 |
| assets #455 | #2458 |
| assets #456 | #2459 |
| assets #457 | #2461 |
| assets #453 | #2452 (the user's own managed-safety-policies PR) |

There is one gap that **no assets PR fixes**: `scheduleViewInfo.habitInvalidCutoff` is on Mac main
but was deliberately removed from assets. It reddens every Mac PR. The fix is to merge Mac **#2439**,
whose branch drops the key locally. Do **not** add it back to assets, and do not delete it from Mac
config alone — the code still reads it and would fall back to hardcoded English, losing the Spanish.
So: merge assets #454, which makes #2439 green, then merge #2439.

Assets merges need `--admin`; the repo requires a code-owner approval the author cannot self-grant.

---

## 6. Ported to mega, in case you need to rebuild it

Everything above is already cherry-picked onto mega and the running app includes it. If you
re-create mega, note that **mega and main have diverged on some names** — for example the Day Plan
tasks panel property is `scheduleFreeMinutes` on mega and `freeTimeMinutes` on main. Check by
content, not by commit subject: subjects get rewritten on forward-port and `git cherry` patch-ids
break on conflict resolution, so both overstate the gap badly.

---

## 7. Conventions worth keeping

- **Every user-facing string is config-driven**, not `Localizable.strings`. A new string goes in
  `FocusBear/config.json` AND `FocusBear/config-es.json` AND a new PR on `Focus-Bear/assets`
  (`config/config.json` + `config/config-es.json`, branched off assets `main`). CI enforces it.
  Day Plan strings live under `scheduleViewInfo`, read through the `ScheduleText` enum. Add new
  keys; never repurpose existing ones, because other platforms read them.
- **New Mac UI is SwiftUI** via `NSHostingController`. Qualify `SwiftUI.State` and `SwiftUI.Button`
  — the app has global AppKit types with those names that shadow them.
- An `NSHostingView` pinned edge-to-edge **grows the window**: its compression resistance (750)
  outranks AppKit's window-size priority (500). Set `sizingOptions = []` on macOS 13+ and drop
  compression-resistance and hugging priorities on both axes. `FocusBear/Focus mode/brainDumpVc.swift`
  has the canonical version.
- Prefer extracting a **pure function plus tests** over testing through AppKit singletons. The
  codebase already does this: `ScheduleBuilder`, `RoutineReorder`, `BreakStartKit`,
  `DayPlanFreeTime`, `DayPlanDueMerge`, `BlockingStatus`.
- Cross-agent coordination uses `python3 ~/.claude/skills/coord/coord.py` with
  `export COORD_AGENT=mac-agent`. Open handbacks: t114, t115, t117, t118, t119, t120, t121, t122.

---

## 8. One correction to carry forward

I twice dismissed a fatal nil-unwrap logged during test runs as a "test-host artifact" because it
was identical on main and the suite still passed. It was a real crash that took the app down on
launch, and it is the crash the user reported. **A fatal error in a log is not an artifact just
because the run reports success.** Check the crash reports in
`~/Library/Logs/DiagnosticReports/` before concluding otherwise.
