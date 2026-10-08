# shellcheck shell=bash
#
# Sourced by scripts/run-ui-tests.sh: the lease that lets a Debug build of the installed Focus Bear
# step its routine screen aside while this Mac runs the UI tests (FocusBear/Routine/UITestRunnerYield.swift
# says exactly when — the Mac idle for 5 minutes and no habit running — and why that isn't a way round a
# routine). Release builds have no such code and ignore the lease.
#
# The file location, notification name and JSON fields are shared with UITestRunnerYield.swift — change
# both together. The lease names this script's PID, so the app takes the screen back the moment the run
# ends, however it ends: withdrawn on exit, or ignored once that process is gone or the lease expires.

readonly UI_TEST_LEASE_FILE="$HOME/Library/Caches/com.focusbear.uitest-lease.json"
readonly UI_TEST_LEASE_NOTIFICATION="com.focusbear.uitest-lease-changed"
# The app refuses a lease claiming longer (UITestRunnerYield.maximumLeaseLifetime), so a long run renews.
readonly UI_TEST_LEASE_LIFETIME_SECONDS=1800
readonly UI_TEST_LEASE_RENEW_SECONDS=300
# The app's 5-minute idle threshold plus a minute: long enough for someone who has just stepped away.
readonly UI_TEST_YIELD_WAIT_SECONDS="${UI_TESTS_YIELD_WAIT_SECONDS:-360}"
readonly UI_TEST_YIELD_POLL_SECONDS="${UI_TESTS_YIELD_POLL_SECONDS:-5}"

lease_runner_pid=""
lease_started_at=""
lease_renewer_pid=""

# Tells the app to look at the lease now rather than on its next check. JXA, because posting a
# distributed notification needs Foundation; failing to post only delays the app's reaction.
notify_lease_changed() {
  osascript -l JavaScript -e "ObjC.import('Foundation');
    \$.NSDistributedNotificationCenter.defaultCenter.postNotificationNameObjectUserInfoDeliverImmediately(
      '$UI_TEST_LEASE_NOTIFICATION', \$(), \$(), true)" >/dev/null 2>&1 || true
}

# Written whole and moved into place, so the app never reads half a lease.
write_lease() {
  local expires_at=$(( $(date +%s) + UI_TEST_LEASE_LIFETIME_SECONDS ))
  local partial="$UI_TEST_LEASE_FILE.$lease_runner_pid.partial"
  mkdir -p "$(dirname "$UI_TEST_LEASE_FILE")"
  printf '{"runner_pid": %d, "started_at": %d, "expires_at": %d}\n' \
    "$lease_runner_pid" "$lease_started_at" "$expires_at" > "$partial"
  mv -f "$partial" "$UI_TEST_LEASE_FILE"
}

# Renews until the runner is gone. Checked before each write, so a runner that was killed outright
# (no exit trap) leaves a lease that simply expires. The nap is waited on, not slept in, so withdrawing
# the lease stops it at once instead of leaving a sleep behind.
renew_lease_while_runner_lives() {
  local nap=""
  trap '[ -z "$nap" ] || kill "$nap" 2>/dev/null; exit 0' TERM
  while kill -0 "$lease_runner_pid" 2>/dev/null; do
    sleep "$UI_TEST_LEASE_RENEW_SECONDS" &
    nap=$!
    wait "$nap"
    kill -0 "$lease_runner_pid" 2>/dev/null || return 0
    write_lease
  done
}

publish_lease() {
  lease_runner_pid=$$
  lease_started_at=$(date +%s)
  write_lease
  notify_lease_changed
  # Its own output goes nowhere: a pipe it held open would keep `run-ui-tests.sh | tee` waiting.
  renew_lease_while_runner_lives >/dev/null 2>&1 &
  lease_renewer_pid=$!
}

# bash skips the EXIT trap when a signal ends it, so turn the usual ones into exits (128 + signal number)
# and the lease is withdrawn however the run is stopped.
exit_on_stop_signals() {
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
}

# Only this run's lease: another run's (or none) is left alone.
withdraw_lease() {
  if [ -n "$lease_renewer_pid" ]; then
    kill "$lease_renewer_pid" 2>/dev/null || true
    lease_renewer_pid=""
  fi
  [ -n "$lease_runner_pid" ] && [ -f "$UI_TEST_LEASE_FILE" ] || return 0
  grep -Fq "\"runner_pid\": $lease_runner_pid," "$UI_TEST_LEASE_FILE" || return 0
  rm -f "$UI_TEST_LEASE_FILE"
  notify_lease_changed
}

# Runs the cover check ("$@") until it no longer reports a cover, or UI_TEST_YIELD_WAIT_SECONDS pass.
# Returns the check's last status and leaves its last output in $cover.
wait_for_cover_to_clear() {
  local covered_status=$1
  shift
  local deadline=$(( $(date +%s) + UI_TEST_YIELD_WAIT_SECONDS ))
  local status
  while :; do
    status=0
    cover=$("$@") || status=$?
    if [ "$status" -ne "$covered_status" ] || [ "$(date +%s)" -ge "$deadline" ]; then
      return "$status"
    fi
    sleep "$UI_TEST_YIELD_POLL_SECONDS"
  done
}
