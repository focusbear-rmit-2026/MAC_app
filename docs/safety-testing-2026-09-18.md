# Local safety validation — 18 September 2026, 23:00 AEST

Before 23:00: source changes and report triage only. Leave the installed app, evening routine,
blocking settings and browser tabs untouched. Do not push changes that trigger this Mac's CI.

## Scheduled automatic checks

A one-shot launchd job (`io.focusbear.safety-validation-20260918`) starts at 23:00 local time.
Its script and output are in `/tmp/focusbear-safety-validation-20260918/`. It checks the committed
integration revision before running, waits for any existing xcodebuild, and never installs an app.

1. Exercise the pinned real URL classifier on the harmless Roblox homepage URL (games category)
   and example.com as an unknown control. This classifies URL strings locally; it opens no pages.
2. Run the Mac logic suites: ManagedPolicyTests, ManagedSafetyPrecedenceTests,
   RelevanceFreshnessTests, LogicTestHostTests, CustomBlockingScheduleTests and StatsLogicTests.
3. Save the classifier result, xcodebuild log and result bundle. A successful run can publish only
   the exact tested integration commit, using an ordinary non-force push. Failed checks stop it.

Schedule precedence coverage: an active school policy overrides a home allowlist; home resumes
at the school window's exclusive end; a known safety denial holds the navigation gate until that
end; safety allow continues into personal restrictions rather than allowing everything.

## Foreground browser validation (separate, still pending)

The automatic checks do **not** establish that a visible Chrome tab was blocked. The draft stacked
PR is #2576 (`test/mac-safety-classifier-precedence`, based on `integration/mac-swiftui-rebuild`).
Its explicit Debug smoke mode exercises the real classifier and enforcement path.

After 23:00, first inspect the desktop/session and current routine. If the Mac is locked, defer the
foreground smoke test. Do not replace/restart the user's app merely to discover it is locked.
Preserve routine progress and the known working app before any approved test launch. Use only
`https://www.roblox.com/`; no criminal or pornographic pages. Require evidence of the target PID,
window and tab, category decision, redirect/block presentation, and denied legacy reopen despite
personal allowance. Confirm normal routine state and blocking after restoring the regular app.

The earlier smoke attempt ran while the desktop was locked and produced only start/end records;
it did not prove visible blocking. Keep this limitation explicit until foreground evidence exists.
