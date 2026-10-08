#!/usr/bin/env python3
"""Only synthetic temporary directories and mocked process inventories are used."""
import contextlib
import io
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location("cleanup", Path(__file__).with_name("cleanup-logic-test-build.py"))
CLEANUP = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CLEANUP)


class BuildCleanupTests(unittest.TestCase):
    def setUp(self):
        self.fixture = tempfile.TemporaryDirectory()
        self.addCleanup(self.fixture.cleanup)
        self.root = Path(self.fixture.name).resolve()
        self.environment = {"RUNNER_TEMP": str(self.root), "GITHUB_RUN_ID": "123", "GITHUB_RUN_ATTEMPT": "2"}
        self.build = self.root / "logic-tests-123-2.noindex"
        self.build.mkdir()
        (self.build / "generated-product").write_text("fixture")

    def cleanup(self, builder_status=1, processes="/usr/bin/safe-fixture\n", process_error=""):
        replies = [subprocess.CompletedProcess([], builder_status, "", ""),
                   subprocess.CompletedProcess([], 0, processes, process_error)]
        with patch.object(CLEANUP.subprocess, "run", side_effect=replies):
            return CLEANUP.cleanup_build(self.environment)[0]

    def test_removes_only_current_run_products_and_preserves_diagnostics(self):
        other = self.root / "logic-tests-456-1.noindex"
        other.mkdir()
        log = self.root / "xcodebuild.log"
        log.write_text("keep")
        self.assertTrue(self.cleanup())
        self.assertFalse(self.build.exists())
        self.assertTrue(other.is_dir())
        self.assertEqual(log.read_text(), "keep")

    def test_preserves_unsuffixed_products_for_same_run(self):
        unsuffixed_build = self.root / "logic-tests-123-2"
        unsuffixed_build.mkdir()
        (unsuffixed_build / "retained-product").write_text("keep")
        self.assertTrue(self.cleanup())
        self.assertFalse(self.build.exists())
        self.assertEqual((unsuffixed_build / "retained-product").read_text(), "keep")

    def test_print_path_is_read_only_and_matches_cleanup_target(self):
        output = io.StringIO()
        with patch.object(CLEANUP.subprocess, "run") as inventory, \
                patch.object(CLEANUP.shutil, "rmtree") as remove, contextlib.redirect_stdout(output):
            self.assertEqual(CLEANUP.main(["--print-path"], self.environment), 0)
        self.assertEqual(output.getvalue(), f"{self.build}\n")
        inventory.assert_not_called()
        remove.assert_not_called()
        self.assertTrue(self.build.is_dir())

    def test_print_path_rejects_invalid_identity_without_mutation(self):
        with patch.dict(self.environment, {"GITHUB_RUN_ID": "../escape"}), \
                patch.object(CLEANUP.shutil, "rmtree") as remove, \
                contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(CLEANUP.main(["--print-path"], self.environment), 1)
        remove.assert_not_called()
        self.assertTrue(self.build.is_dir())

    def test_print_path_refuses_child_symlink_without_process_or_delete(self):
        target = self.root / "retained-products"
        self.build.rename(target)
        self.build.symlink_to(target, target_is_directory=True)
        with patch.object(CLEANUP.subprocess, "run") as inventory, \
                patch.object(CLEANUP.shutil, "rmtree") as remove, \
                contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(CLEANUP.main(["--print-path"], self.environment), 1)
        inventory.assert_not_called()
        remove.assert_not_called()
        self.assertTrue((target / "generated-product").is_file())

    def test_refuses_active_builder_or_failed_builder_inventory(self):
        for status in [0, 2]:
            self.assertFalse(self.cleanup(builder_status=status))
            self.assertTrue(self.build.exists())

    def test_refuses_process_referencing_build_or_missing_inventory(self):
        for processes, error in [(str(self.build / "Focus Bear.app/Contents/MacOS/Focus Bear"), ""),
                                 ("", ""), ("/usr/bin/process", "inventory denied")]:
            self.assertFalse(self.cleanup(processes=processes, process_error=error))
            self.assertTrue(self.build.exists())

    def test_refuses_inventory_exceptions(self):
        for error in [OSError(), subprocess.CalledProcessError(1, "ps"),
                      subprocess.TimeoutExpired("ps", CLEANUP.COMMAND_TIMEOUT_SECONDS)]:
            with patch.object(CLEANUP.subprocess, "run", side_effect=error):
                self.assertFalse(CLEANUP.cleanup_build(self.environment)[0])
                self.assertTrue(self.build.exists())

    def test_refuses_invalid_identity_and_missing_temp(self):
        for key, value in [("RUNNER_TEMP", ""), ("RUNNER_TEMP", "/"), ("RUNNER_TEMP", "relative"),
                           ("GITHUB_RUN_ID", "../escape"), ("GITHUB_RUN_ATTEMPT", "")]:
            with patch.dict(self.environment, {key: value}), patch.object(CLEANUP.shutil, "rmtree") as remove:
                self.assertFalse(CLEANUP.cleanup_build(self.environment)[0])
                remove.assert_not_called()

    def test_refuses_symlink_build_and_preserves_target(self):
        target = self.root / "other-products"
        self.build.rename(target)
        self.build.symlink_to(target, target_is_directory=True)
        self.assertFalse(self.cleanup())
        self.assertTrue((target / "generated-product").exists())

    def test_child_symlink_does_not_delete_its_target(self):
        target = self.root / "retained.txt"
        target.write_text("keep")
        (self.build / "linked-child").symlink_to(target)
        self.assertTrue(self.cleanup())
        self.assertEqual(target.read_text(), "keep")

    def test_waits_for_builder_and_rechecks_all_guards_before_removing(self):
        replies = [subprocess.CompletedProcess([], 0, "builder", ""),
                   subprocess.CompletedProcess([], 1, "", ""),
                   subprocess.CompletedProcess([], 0, "/usr/bin/safe-fixture\n", "")]
        def wait(_seconds):
            self.assertTrue(self.build.exists(), "Active-build products must remain untouched")
        with patch.object(CLEANUP.subprocess, "run", side_effect=replies), \
                patch.object(CLEANUP.time, "sleep", side_effect=wait) as sleep, \
                contextlib.redirect_stdout(io.StringIO()):
            self.assertTrue(CLEANUP.cleanup_build_when_idle(self.environment)[0])
        sleep.assert_called_once()
        self.assertFalse(self.build.exists())

    def test_busy_builder_timeout_preserves_products(self):
        active = subprocess.CompletedProcess([], 0, "builder", "")
        with patch.object(CLEANUP.subprocess, "run", return_value=active), \
                patch.object(CLEANUP.time, "monotonic", side_effect=[0, CLEANUP.CLEANUP_WAIT_SECONDS]), \
                patch.object(CLEANUP.time, "sleep") as sleep:
            cleaned, reason = CLEANUP.cleanup_build_when_idle(self.environment)
        self.assertFalse(cleaned)
        self.assertIn("timed out", reason)
        sleep.assert_not_called()
        self.assertTrue(self.build.exists())

    def test_inventory_failure_is_not_retried_or_deleted(self):
        failed = subprocess.CompletedProcess([], 2, "", "inventory denied")
        with patch.object(CLEANUP.subprocess, "run", return_value=failed), \
                patch.object(CLEANUP.time, "sleep") as sleep:
            self.assertFalse(CLEANUP.cleanup_build_when_idle(self.environment)[0])
        sleep.assert_not_called()
        self.assertTrue(self.build.exists())

    def test_later_process_reference_still_blocks_cleanup(self):
        replies = [subprocess.CompletedProcess([], 0, "builder", ""),
                   subprocess.CompletedProcess([], 1, "", ""),
                   subprocess.CompletedProcess([], 0, str(self.build / "host"), "")]
        with patch.object(CLEANUP.subprocess, "run", side_effect=replies), \
                patch.object(CLEANUP.time, "sleep"), contextlib.redirect_stdout(io.StringIO()):
            self.assertFalse(CLEANUP.cleanup_build_when_idle(self.environment)[0])
        self.assertTrue(self.build.exists())

    def test_missing_build_is_noop(self):
        self.build.rename(self.root / "retained-products")
        with patch.object(CLEANUP.subprocess, "run") as inventory:
            self.assertTrue(CLEANUP.cleanup_build(self.environment)[0])
            inventory.assert_not_called()


if __name__ == "__main__":
    unittest.main()
