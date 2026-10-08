#!/usr/bin/env python3
"""Pure decision logic only; never calls the GitHub API."""
import importlib.util
from pathlib import Path
import sys
import unittest

sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location("rerun", Path(__file__).with_name("rerun-assets-sync-checks.py"))
RERUN = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RERUN)
SYNC = RERUN.CONFIG_ASSETS_SYNC
MissingKey = RERUN.MissingKey

TIMESTAMP = "2026-10-04T03:55:46.4348024Z "
FAILED_RUN = {"status": "completed", "conclusion": "failure", "run_attempt": 1}


class MissingKeyExtractionTests(unittest.TestCase):
    def test_reads_the_line_the_sync_check_prints(self):
        line = SYNC.missing_key_line("assets-repo/config/config.json", "leftMenuVcInfo.showReminders")
        self.assertEqual(RERUN.extract_missing_keys(TIMESTAMP + line),
                         {MissingKey("config.json", "leftMenuVcInfo.showReminders")})

    def test_reads_legacy_annotation_as_rendered_in_job_logs(self):
        log = (f"{TIMESTAMP}##[error]Missing in assets repo: a.b = 'Text = with equals'\n"
               f"{TIMESTAMP}::error::Missing in assets repo: c.d = 'x'")
        self.assertEqual(RERUN.extract_missing_keys(log),
                         {MissingKey("config.json", "a.b"), MissingKey("config.json", "c.d")})

    def test_new_and_legacy_lines_for_the_same_key_collapse(self):
        log = (f"{TIMESTAMP}##[error]Missing in assets repo: a.b = 'x'\n"
               f"{TIMESTAMP}{SYNC.missing_key_line('config.json', 'a.b')}\r\n")
        self.assertEqual(RERUN.extract_missing_keys(log), {MissingKey("config.json", "a.b")})

    def test_key_may_contain_a_colon(self):
        line = SYNC.missing_key_line("config-es.json", "info.time: label")
        self.assertEqual(RERUN.parse_missing_key_line(line), MissingKey("config-es.json", "info.time: label"))

    def test_ignores_unrelated_and_malformed_lines(self):
        log = "\n".join([f"{TIMESTAMP}✅ All 10 local config strings are present in the assets repo.",
                         f"{TIMESTAMP}{SYNC.MISSING_KEY_PREFIX}config.json",
                         f"{TIMESTAMP}{SYNC.MISSING_KEY_PREFIX}config.json:",
                         f"{TIMESTAMP}echo MISSING_KEY: quoted in a shell command", ""])
        self.assertEqual(RERUN.extract_missing_keys(log), set())


class DecisionTests(unittest.TestCase):
    def test_metadata_skips(self):
        cases = {"no run": None,
                 "queued": {**FAILED_RUN, "status": "queued"},
                 "in progress": {**FAILED_RUN, "status": "in_progress"},
                 "passed": {**FAILED_RUN, "conclusion": "success"},
                 "cancelled": {**FAILED_RUN, "conclusion": "cancelled"},
                 "attempt cap": {**FAILED_RUN, "run_attempt": RERUN.MAX_RUN_ATTEMPTS}}
        for name, run in cases.items():
            with self.subTest(name):
                self.assertEqual(RERUN.decide_before_logs(run).action, RERUN.ACTION_SKIP)

    def test_failed_run_below_attempt_cap_needs_its_log(self):
        self.assertIsNone(RERUN.decide_before_logs({**FAILED_RUN, "run_attempt": RERUN.MAX_RUN_ATTEMPTS - 1}))

    def test_reruns_only_when_every_key_is_present(self):
        missing = {MissingKey("config.json", "a"), MissingKey("config.json", "b")}
        self.assertEqual(RERUN.decide_after_logs(missing, {"config.json": {"a", "b", "c"}}).action,
                         RERUN.ACTION_RERUN)
        decision = RERUN.decide_after_logs(missing, {"config.json": {"a"}})
        self.assertEqual(decision.action, RERUN.ACTION_WAIT)
        self.assertIn("config.json:b", decision.reason)
        self.assertNotIn("config.json:a", decision.reason)

    def test_key_must_be_in_the_file_it_was_missing_from(self):
        missing = {MissingKey("config-es.json", "a")}
        self.assertEqual(RERUN.decide_after_logs(missing, {"config.json": {"a"}}).action, RERUN.ACTION_WAIT)

    def test_failure_without_missing_keys_is_left_alone(self):
        self.assertEqual(RERUN.decide_after_logs(set(), {}).action, RERUN.ACTION_SKIP)

    def test_still_missing_is_sorted(self):
        missing = {MissingKey("config.json", "z"), MissingKey("config.json", "a")}
        self.assertEqual(RERUN.keys_still_missing(missing, {}), sorted(missing))

    def test_scope_is_the_default_author_unless_all_authors(self):
        mine = {"user": {"login": RERUN.DEFAULT_PULL_REQUEST_AUTHOR}}
        theirs = {"user": {"login": "someone-else"}}
        self.assertTrue(RERUN.is_in_scope(mine, RERUN.DEFAULT_PULL_REQUEST_AUTHOR))
        self.assertFalse(RERUN.is_in_scope(theirs, RERUN.DEFAULT_PULL_REQUEST_AUTHOR))
        self.assertTrue(RERUN.is_in_scope(theirs, None))

    def test_latest_run_is_highest_run_number(self):
        runs = [{"run_number": 3}, {"run_number": 7}, {"run_number": 5}]
        self.assertEqual(RERUN.latest_run(runs), {"run_number": 7})
        self.assertIsNone(RERUN.latest_run([]))


if __name__ == "__main__":
    unittest.main()
