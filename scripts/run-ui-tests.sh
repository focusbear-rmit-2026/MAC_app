#!/usr/bin/env bash
#
# Run the Focus Bear XCUITest suite against an ISOLATED build of the app (docs/ui-tests.md).
#
# The app is built as com.App.EarnYourScreentime.uitests, so it has its own preferences, its own
# Application Support folder and in-memory credentials, and enforces nothing on this Mac. Launching a
# build with the shipping bundle id would quit the Focus Bear you are using, which is why the suite
# must never be run without this suffix — use this script rather than Xcode's Test button.
#
# The first test (AccountSignUpUITests) signs up a new internaltest+macuitest…@focusbear.io account
# through onboarding, and every signed-in test after it reuses that account. The (sandboxed) test
# runner keeps its login in its own container, so later runs of a single class reuse it too. To use
# an existing account instead:
#
#     FOCUSBEAR_UITEST_EMAIL=… FOCUSBEAR_UITEST_PASSWORD=… ./scripts/run-ui-tests.sh
#
# The blocking tests really hide apps and redirect Safari, so they run only when the dedicated runner
# opts in with FOCUSBEAR_UITEST_ENABLE_BLOCKING=1 (the CI workflow does). Never set it on a Mac
# someone is using.
#
# Which tests: --plan smoke (the critical path, a few minutes) or --plan regression (every UI test,
# the default). Extra arguments go to xcodebuild, e.g.
#     ./scripts/run-ui-tests.sh --plan smoke
#     ./scripts/run-ui-tests.sh -only-testing:"Focus BearUITests/LaunchAndNavigationUITests"
set -euo pipefail

readonly SMOKE_PLAN="Smoke"
readonly REGRESSION_PLAN="Regression"
test_plan="$REGRESSION_PLAN"
if [ "${1:-}" = "--plan" ]; then
  case "${2:-}" in
    smoke) test_plan="$SMOKE_PLAN" ;;
    regression) test_plan="$REGRESSION_PLAN" ;;
    *) echo "usage: $0 [--plan smoke|regression] [xcodebuild arguments…]" >&2; exit 64 ;;
  esac
  shift 2
fi

cd "$(dirname "$0")/.."

readonly BUNDLE_ID_SUFFIX=".uitests"
readonly DERIVED_DATA="${UI_TESTS_DERIVED_DATA:-build-ui}"
readonly RESULT_BUNDLE="${UI_TESTS_RESULT_BUNDLE:-UITestResults.xcresult}"
# A test that hangs (a sheet nobody dismisses, a prompt) fails after this instead of stalling the run.
readonly TEST_TIME_ALLOWANCE_SECONDS=300
readonly APP_UNDER_TEST="$DERIVED_DATA/Build/Products/Debug/Focus Bear.app"
readonly LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

# xcodebuild hands TEST_RUNNER_<NAME> to the test runner as <NAME>.
export TEST_RUNNER_FOCUSBEAR_UITEST_EMAIL="${FOCUSBEAR_UITEST_EMAIL:-}"
export TEST_RUNNER_FOCUSBEAR_UITEST_PASSWORD="${FOCUSBEAR_UITEST_PASSWORD:-}"
export TEST_RUNNER_FOCUSBEAR_UITEST_ENABLE_BLOCKING="${FOCUSBEAR_UITEST_ENABLE_BLOCKING:-}"
# EventsV2UITests posts one real event to the events-v2 stack for the test account; it skips unless set.
export TEST_RUNNER_FOCUSBEAR_EVENTS_V2="${FOCUSBEAR_EVENTS_V2:-}"

# Leave nothing behind: the build registers the test app with LaunchServices, where it could answer
# for Focus Bear later, and XCTest kills the app between tests without letting it stop the block-page
# server it started (blocking tests only). Only processes running from this build are touched.
clean_up_test_app() {
  local app_path executable process_id
  app_path=$(cd "$APP_UNDER_TEST" 2>/dev/null && pwd) || return 0
  for executable in "$app_path/Contents/Resources/server" "$app_path/Contents/Resources/serverIntel"; do
    # Command-line matches can select an unrelated shell or app. Only these exact binaries qualify.
    while IFS= read -r process_id; do
      [ -n "$process_id" ] || continue
      if /usr/sbin/lsof -nP -a -p "$process_id" -d txt -Fn 2>/dev/null |
          grep -Fxq "n$executable"; then
        kill -KILL "$process_id" || true
      fi
    done < <(/usr/sbin/lsof -nP -d txt -Fpn 2>/dev/null |
      awk -v executable="$executable" '/^p/ { process_id = substr($0, 2) }
        /^n/ && substr($0, 2) == executable { print process_id }' || true)
  done
  if [ -d "$APP_UNDER_TEST" ]; then "$LSREGISTER" -u "$APP_UNDER_TEST" || true; fi
}

# The installed Focus Bear's routine/break/session screen sits over every window and would take each
# click the suite makes (scripts/installed-focus-bear-cover.swift says why). A Debug build steps a routine
# aside for this run's lease once the Mac has been idle 5 minutes and no habit is running
# (scripts/ui-test-runner-lease.sh), so wait a while for that before giving up.
# shellcheck source=scripts/ui-test-runner-lease.sh
source scripts/ui-test-runner-lease.sh
readonly COVER_CHECK_COVERED=3
readonly EXIT_TEMPFAIL=75   # try again later: once the screen is gone
cover_check_folder=$(mktemp -d)
readonly COVER_CHECK="$cover_check_folder/installed-focus-bear-cover"

finish_run() {
  withdraw_lease
  rm -rf "$cover_check_folder"
  clean_up_test_app
}
trap finish_run EXIT
exit_on_stop_signals

publish_lease
cover_status=0
if ! swiftc -o "$COVER_CHECK" scripts/installed-focus-bear-cover.swift 2>/dev/null; then
  echo "warning: couldn't build the check for Focus Bear's full-screen screens; running anyway" >&2
else
  cover=$("$COVER_CHECK") || cover_status=$?
  if [ "$cover_status" -eq "$COVER_CHECK_COVERED" ]; then
    echo "$cover Waiting up to $((UI_TEST_YIELD_WAIT_SECONDS / 60)) min for it to step aside" \
      "(a Debug build does once this Mac has been idle 5 minutes and no habit is running)…" >&2
    cover_status=0
    wait_for_cover_to_clear "$COVER_CHECK_COVERED" "$COVER_CHECK" || cover_status=$?
    if [ "$cover_status" -eq 0 ]; then echo "Focus Bear stepped aside; starting the UI tests." >&2; fi
  fi
fi
if [ "$cover_status" -eq "$COVER_CHECK_COVERED" ]; then
  echo "Not running the UI tests: $cover" >&2
  echo "It didn't step aside: someone used this Mac in the last 5 minutes, a habit, break or focus session is" \
    "running, or it is a Release build. Finish or postpone it in Focus Bear, then run again." >&2
  exit "$EXIT_TEMPFAIL"
elif [ "$cover_status" -ne 0 ]; then
  echo "warning: couldn't check for Focus Bear's full-screen screens (exit $cover_status); running anyway" >&2
fi

rm -rf "${RESULT_BUNDLE:?}"
xcodebuild test \
  -workspace FocusBear.xcworkspace \
  -scheme "Focus Bear UITests" \
  -testPlan "$test_plan" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance "$TEST_TIME_ALLOWANCE_SECONDS" \
  FB_BUNDLE_ID_SUFFIX="$BUNDLE_ID_SUFFIX" \
  "$@"
