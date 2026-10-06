#!/usr/bin/env python3
"""Mocked probes only; never reads real machine load or starts a build."""
from collections import namedtuple
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
DISK_USAGE = namedtuple("DiskUsage", "total used free")
VALID_DISK = DISK_USAGE(20 * CAPACITY.BYTES_PER_GIB, 15 * CAPACITY.BYTES_PER_GIB, CAPACITY.MIN_FREE_DISK_BYTES)


class BuildCapacityTests(unittest.TestCase):
    def probe(self, memory="20", load="19.99", process_status=1, disk=VALID_DISK):
        replies = [subprocess.CompletedProcess([], 0, f"System-wide memory free percentage: {memory}%"),
                   subprocess.CompletedProcess([], 0, f"{{ {load} 10.0 10.0 }}"),
                   subprocess.CompletedProcess([], process_status, "")]
        with patch.object(CAPACITY.shutil, "disk_usage", return_value=disk), \
             patch.object(CAPACITY.subprocess, "run", side_effect=replies):
            return CAPACITY.check_capacity()[0]

    def test_accepts_exact_disk_and_memory_thresholds_and_load_below_limit(self):
        self.assertTrue(self.probe())

    def test_refuses_disk_below_threshold(self):
        self.assertFalse(self.probe(disk=VALID_DISK._replace(free=CAPACITY.MIN_FREE_DISK_BYTES - 1)))
        self.assertFalse(self.probe(disk=VALID_DISK._replace(free=0)))

    def test_refuses_invalid_disk_inventory(self):
        for disk in [VALID_DISK._replace(free=-1), VALID_DISK._replace(free=VALID_DISK.total + 1),
                     VALID_DISK._replace(free=float("nan")), VALID_DISK._replace(total=0),
                     VALID_DISK._replace(used=-1), VALID_DISK._replace(free=True)]:
            with self.subTest(disk=disk):
                self.assertFalse(self.probe(disk=disk))

    def test_refuses_unavailable_disk_inventory(self):
        with patch.object(CAPACITY.shutil, "disk_usage", side_effect=OSError("unavailable")), \
             patch.object(CAPACITY.subprocess, "run") as command:
            self.assertFalse(CAPACITY.check_capacity()[0])
            command.assert_not_called()

    def test_probes_runner_build_volume_or_working_directory(self):
        for environment, expected in [({"RUNNER_TEMP": "/fixture/runner"}, "/fixture/runner"),
                                      ({}, "/fixture/worktree")]:
            with self.subTest(environment=environment), \
                 patch.dict(CAPACITY.os.environ, environment, clear=True), \
                 patch.object(CAPACITY.os, "getcwd", return_value="/fixture/worktree"), \
                 patch.object(CAPACITY.shutil, "disk_usage", side_effect=OSError()) as disk:
                self.assertFalse(CAPACITY.check_capacity()[0])
                disk.assert_called_once_with(expected)

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
            with self.subTest(error=error), \
                 patch.object(CAPACITY.shutil, "disk_usage", return_value=VALID_DISK), \
                 patch.object(CAPACITY.subprocess, "run", side_effect=error):
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
