#!/usr/bin/env python3
"""Pure validation: no app launch, authentication, process termination, or user data access."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
SWIFT_TEST_TIMEOUT_SECONDS = 60


class UIRunnerSafetyTests(unittest.TestCase):
    def test_account_allowlist(self):
        cases = {
            "internaltest+macuitest123-abcdef@focusbear.io": True,
            "INTERNALTEST+MACUITEST123@FOCUSBEAR.IO": True,
            "person@focusbear.io": False,
            "internaltest+macqa123@focusbear.io": False,
            "internaltest+macuitest@focusbear.io": False,
            "internaltest+macuitest123@example.com": False,
            "internaltest+macuitest123@focusbear.io.evil.example": False,
            "internaltest+macuitest123@@focusbear.io": False,
            "internaltest+macuitest123 @focusbear.io": False,
            "internaltest+macuitest123@focusbear.io\n": False,
            "": False,
        }
        source = (ROOT / "FocusBear/UITestContract.swift").read_text()
        for email, allowed in cases.items():
            source += f'\nprecondition(UITestContract.TestAccount.isAllowed(email: {json.dumps(email)}) == {str(allowed).lower()})'
        with tempfile.TemporaryDirectory() as folder:
            script = Path(folder) / "main.swift"
            script.write_text(source)
            subprocess.run(["swift", str(script)], check=True, timeout=SWIFT_TEST_TIMEOUT_SECONDS,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    def test_saved_account_retires_before_its_trial_ends(self):
        """A reused account whose seven-day trial ran out turned Basic and hid the goal card
        (2026-10-05). Ages are relative to a fixed now so the check never depends on the clock."""
        now = 1_790_000_000
        day = 24 * 60 * 60
        minute = 60
        cases = {
            f"internaltest+macuitest{now - 5 * day}-abcdef@focusbear.io": False,
            f"internaltest+macuitest{now - 6 * day + minute}-abcdef@focusbear.io": False,
            f"internaltest+macuitest{now - 6 * day - minute}-abcdef@focusbear.io": True,
            f"INTERNALTEST+MACUITEST{now - 7 * day}-ABCDEF@FOCUSBEAR.IO": True,
            "internaltest+macuitest-abcdef@focusbear.io": False,
            "someone@focusbear.io": False,
        }
        support = (ROOT / "FocusBearUITests/UITestSupport.swift").read_text()

        def declaration(opening):
            return opening + support.split(opening, 1)[1].split("\n}\n", 1)[0] + "\n}\n"

        source = "\n".join([(ROOT / "FocusBear/UITestContract.swift").read_text(),
                            declaration("struct TestAccount: Codable {"), declaration("enum TestAccountStore {")])
        for email, retired in cases.items():
            source += (f'\nprecondition(TestAccountStore.hasOutlivedTrial(TestAccount(email: {json.dumps(email)}, password: "x"), '
                       f'now: Date(timeIntervalSince1970: {now})) == {str(retired).lower()}, {json.dumps(email)})')
        with tempfile.TemporaryDirectory() as folder:
            script = Path(folder) / "main.swift"
            script.write_text(source)
            subprocess.run(["swift", str(script)], check=True, timeout=SWIFT_TEST_TIMEOUT_SECONDS,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    def test_cleanup_requires_exact_executable_and_rechecks_pid(self):
        source = (ROOT / "scripts/run-ui-tests.sh").read_text()
        cleanup = source.split("clean_up_test_app() {", 1)[1].split("\n}\n", 1)[0]
        cleanup = "clean_up_test_app() {" + cleanup + "\n}\n"
        cleanup = cleanup.replace("/usr/sbin/lsof", "mock_lsof")
        with tempfile.TemporaryDirectory() as folder:
            script = Path(folder) / "cleanup.sh"
            script.write_text('''set -euo pipefail
APP_UNDER_TEST="$1"
LSREGISTER=true
mock_lsof() {
  if [ "$2" = "-a" ]; then
    case "$4" in
      101) printf 'n%s/Contents/Resources/server\\n' "$APP_UNDER_TEST" ;;
      102) printf 'n/unrelated/reused-pid\\n' ;;
      103) printf 'n%s/Contents/Resources/serverIntel\\n' "$APP_UNDER_TEST" ;;
    esac
  else
    printf 'p101\\nn%s/Contents/Resources/server\\np102\\nn%s/Contents/Resources/server\\np103\\nn%s/Contents/Resources/serverIntel\\np104\\nn%s/Contents/Resources/server-other\\np105\\nn/bin/sh\\n' \\
      "$APP_UNDER_TEST" "$APP_UNDER_TEST" "$APP_UNDER_TEST" "$APP_UNDER_TEST"
  fi
}
kill() { printf 'kill:%s:%s\\n' "$1" "$2"; }
''' + cleanup + "\nclean_up_test_app\n")
            result = subprocess.run(["bash", str(script), folder], check=True,
                                    capture_output=True, text=True)
            self.assertEqual(result.stdout.splitlines(), ["kill:-KILL:101", "kill:-KILL:103"])


LEASE_SCRIPT = ROOT / "scripts/ui-test-runner-lease.sh"
LEASE_RELATIVE_PATH = Path("Library/Caches/com.focusbear.uitest-lease.json")
LEASE_LIFETIME_SECONDS = 1800   # FocusBear/Routine/UITestRunnerYield.swift refuses a longer lease
COVERED = 3


class UIRunnerLeaseTests(unittest.TestCase):
    """The lease run-ui-tests.sh publishes so a Debug Focus Bear steps its routine screen aside.
    Runs under a throwaway HOME and never posts the real notification."""

    def run_with_lease(self, body, home, env_overrides=None, check=True):
        script = f'''set -euo pipefail
source "{LEASE_SCRIPT}"
notify_lease_changed() {{ echo notified >> "$HOME/notifications"; }}
{body}
'''
        env = {"PATH": "/usr/bin:/bin", "HOME": home, **(env_overrides or {})}
        return subprocess.run(["bash", "-c", script], env=env, capture_output=True, text=True, check=check)

    def read_lease(self, home):
        return json.loads((Path(home) / LEASE_RELATIVE_PATH).read_text())

    def notifications(self, home):
        log = Path(home) / "notifications"
        return log.read_text().splitlines() if log.exists() else []

    def test_publish_names_the_runner_and_expires_within_the_apps_limit(self):
        with tempfile.TemporaryDirectory() as home:
            result = self.run_with_lease('publish_lease; echo "$$"; kill "$lease_renewer_pid"; cat "$UI_TEST_LEASE_FILE"', home)
            runner_pid = int(result.stdout.splitlines()[0])
            lease = json.loads(result.stdout.splitlines()[1])
            self.assertEqual(lease["runner_pid"], runner_pid)
            self.assertEqual(lease["expires_at"] - lease["started_at"], LEASE_LIFETIME_SECONDS)
            self.assertEqual(self.notifications(home), ["notified"])

    def test_renewal_moves_only_the_expiry(self):
        with tempfile.TemporaryDirectory() as home:
            self.run_with_lease('lease_runner_pid=4242; lease_started_at=1000; write_lease', home)
            lease = self.read_lease(home)
            self.assertEqual((lease["runner_pid"], lease["started_at"]), (4242, 1000))
            self.assertGreater(lease["expires_at"], 1000 + LEASE_LIFETIME_SECONDS)
            self.assertEqual(list((Path(home) / LEASE_RELATIVE_PATH).parent.glob("*.partial")), [])

    def test_exit_withdraws_the_lease_and_says_so(self):
        for ending in ("exit 75", "exit 0", "kill -TERM $$", "kill -INT $$", "kill -HUP $$"):
            with self.subTest(ending=ending), tempfile.TemporaryDirectory() as home:
                self.run_with_lease(f'trap withdraw_lease EXIT; exit_on_stop_signals; publish_lease; {ending}', home,
                                    check=False)
                self.assertFalse((Path(home) / LEASE_RELATIVE_PATH).exists())
                self.assertEqual(self.notifications(home), ["notified", "notified"])

    def test_withdraw_leaves_another_runners_lease_alone(self):
        with tempfile.TemporaryDirectory() as home:
            self.run_with_lease('lease_runner_pid=4242; lease_started_at=1000; write_lease; '
                                'lease_runner_pid=4243; withdraw_lease', home)
            self.assertEqual(self.read_lease(home)["runner_pid"], 4242)
            self.assertEqual(self.notifications(home), [])

    def test_renewer_stops_once_the_runner_is_gone(self):
        with tempfile.TemporaryDirectory() as home:
            # A runner PID that no longer exists: the renewer must exit without writing.
            result = self.run_with_lease('sleep 0 & gone=$!; wait "$gone"; lease_runner_pid=$gone; lease_started_at=1; '
                                         'renew_lease_while_runner_lives; echo stopped', home)
            self.assertEqual(result.stdout.strip(), "stopped")
            self.assertFalse((Path(home) / LEASE_RELATIVE_PATH).exists())

    def test_waits_for_the_cover_to_clear(self):
        with tempfile.TemporaryDirectory() as home:
            # The check runs in a command substitution (a subshell), so it counts in a file.
            body = f'''
checks() {{ wc -l < "$HOME/checks" | tr -d " "; }}
fake_cover() {{ echo x >> "$HOME/checks"; [ "$(checks)" -ge 3 ] && return 0; return {COVERED}; }}
status=0; wait_for_cover_to_clear {COVERED} fake_cover || status=$?
echo "$status $(checks)"'''
            result = self.run_with_lease(body, home, {"UI_TESTS_YIELD_POLL_SECONDS": "0"})
            self.assertEqual(result.stdout.strip(), "0 3")

    def test_gives_up_covered_after_the_wait(self):
        with tempfile.TemporaryDirectory() as home:
            body = f'''
always_covered() {{ echo "Focus Bear has a full-screen routine"; return {COVERED}; }}
status=0; wait_for_cover_to_clear {COVERED} always_covered || status=$?
echo "$status|$cover"'''
            result = self.run_with_lease(body, home, {"UI_TESTS_YIELD_WAIT_SECONDS": "0"})
            self.assertEqual(result.stdout.strip(), f"{COVERED}|Focus Bear has a full-screen routine")

    def test_a_failed_check_is_not_a_cover(self):
        with tempfile.TemporaryDirectory() as home:
            body = f'''
broken() {{ return 1; }}
status=0; wait_for_cover_to_clear {COVERED} broken || status=$?
echo "$status"'''
            result = self.run_with_lease(body, home, {"UI_TESTS_YIELD_WAIT_SECONDS": "600"})
            self.assertEqual(result.stdout.strip(), "1")

    def test_runner_publishes_before_checking_and_withdraws_on_exit(self):
        source = (ROOT / "scripts/run-ui-tests.sh").read_text()
        self.assertIn("source scripts/ui-test-runner-lease.sh", source)
        self.assertIn("trap finish_run EXIT\nexit_on_stop_signals\n", source)
        finish = source.split("finish_run() {", 1)[1].split("\n}\n", 1)[0]
        self.assertIn("withdraw_lease", finish)
        self.assertLess(source.index("trap finish_run EXIT"), source.index("\npublish_lease"))
        self.assertLess(source.index("\npublish_lease"), source.index("wait_for_cover_to_clear"))
        self.assertLess(source.index("wait_for_cover_to_clear"), source.index("xcodebuild test"))


if __name__ == "__main__":
    unittest.main()
