#!/usr/bin/env python3
"""Mocked probes only; never reads real machine load or starts a build."""
import importlib.util
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location("capacity", Path(__file__).with_name("wait-for-build-capacity.py"))
CAPACITY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CAPACITY)


class BuildCapacityTests(unittest.TestCase):
    def probe(self, memory="20", load="19.99", process_status=1):
        replies = [subprocess.CompletedProcess([], 0, f"System-wide memory free percentage: {memory}%"),
                   subprocess.CompletedProcess([], 0, f"{{ {load} 10.0 10.0 }}"),
                   subprocess.CompletedProcess([], process_status, "")]
        with patch.object(CAPACITY.subprocess, "run", side_effect=replies):
            return CAPACITY.check_capacity()[0]

    def test_accepts_exact_memory_threshold_and_load_below_limit(self):
        self.assertTrue(self.probe())

    def test_refuses_low_memory_and_load_at_or_above_limit(self):
        self.assertFalse(self.probe(memory="19"))
        self.assertFalse(self.probe(load="20"))
        self.assertFalse(self.probe(load="267"))

    def test_refuses_existing_builder_and_process_probe_failure(self):
        self.assertFalse(self.probe(process_status=0))
        self.assertFalse(self.probe(process_status=2))

    def test_refuses_malformed_metrics(self):
        self.assertFalse(self.probe(memory="unknown"))
        self.assertFalse(self.probe(memory="101"))
        self.assertFalse(self.probe(load="unknown"))

    def test_refuses_command_failure_or_timeout(self):
        for error in [OSError(), subprocess.CalledProcessError(1, "sysctl"),
                      subprocess.TimeoutExpired("memory_pressure", 10)]:
            with self.subTest(error=error), patch.object(CAPACITY.subprocess, "run", side_effect=error):
                self.assertFalse(CAPACITY.check_capacity()[0])

    def test_waits_then_proceeds_when_capacity_recovers(self):
        with patch.object(CAPACITY, "check_capacity", side_effect=[(False, "busy"), (True, "ready")]), \
             patch.object(CAPACITY.time, "monotonic", return_value=0), \
             patch.object(CAPACITY.time, "sleep") as sleep:
            self.assertEqual(CAPACITY.wait_for_capacity(), 0)
            sleep.assert_called_once_with(CAPACITY.POLL_INTERVAL_SECONDS)

    def test_timeout_fails_without_starting_a_build(self):
        with patch.object(CAPACITY, "check_capacity", return_value=(False, "busy")), \
             patch.object(CAPACITY.time, "monotonic", side_effect=[0, 0, CAPACITY.WAIT_TIMEOUT_SECONDS + 1]), \
             patch.object(CAPACITY.time, "sleep") as sleep:
            self.assertEqual(CAPACITY.wait_for_capacity(), 1)
            sleep.assert_not_called()


if __name__ == "__main__":
    unittest.main()
