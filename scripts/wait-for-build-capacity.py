#!/usr/bin/env python3
"""Wait for safe macOS build capacity without launching or stopping any application."""

import re
import subprocess
import sys
import time

MIN_FREE_PERCENT = 20
MAX_FREE_PERCENT = 100
MAX_LOAD = 20
WAIT_TIMEOUT_SECONDS = 600
POLL_INTERVAL_SECONDS = 30
COMMAND_TIMEOUT_SECONDS = 10
NO_MATCH_EXIT_CODE = 1


def check_capacity():
    try:
        memory = subprocess.run(["memory_pressure"], capture_output=True, text=True,
                                timeout=COMMAND_TIMEOUT_SECONDS, check=True)
        load = subprocess.run(["sysctl", "-n", "vm.loadavg"], capture_output=True, text=True,
                              timeout=COMMAND_TIMEOUT_SECONDS, check=True)
        builders = subprocess.run(["pgrep", "-x", "xcodebuild"], capture_output=True, text=True,
                                  timeout=COMMAND_TIMEOUT_SECONDS, check=False)
    except (OSError, subprocess.SubprocessError) as error:
        return False, f"capacity probe unavailable: {type(error).__name__}"
    memory_match = re.search(r"free percentage:\s*(\d+)%", memory.stdout)
    load_match = re.fullmatch(r"\s*\{\s*([0-9]+(?:\.[0-9]+)?)\s+[0-9.]+\s+[0-9.]+\s*\}\s*", load.stdout)
    if not memory_match or not load_match or builders.returncode not in (0, NO_MATCH_EXIT_CODE):
        return False, "capacity probe returned malformed or unavailable data"
    free_percent = int(memory_match.group(1))
    one_minute_load = float(load_match.group(1))
    if not 0 <= free_percent <= MAX_FREE_PERCENT:
        return False, "capacity probe returned invalid memory percentage"
    has_builder = builders.returncode == 0
    ready = free_percent >= MIN_FREE_PERCENT and one_minute_load < MAX_LOAD and not has_builder
    return ready, f"memory free={free_percent}%, 1-minute load={one_minute_load:g}, xcodebuild active={has_builder}"


def wait_for_capacity():
    deadline = time.monotonic() + WAIT_TIMEOUT_SECONDS
    while time.monotonic() < deadline:
        ready, reason = check_capacity()
        if ready and time.monotonic() < deadline:
            print(f"Build capacity ready: {reason}", flush=True)
            return 0
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        print(f"Waiting for build capacity ({remaining:.0f}s remaining): {reason}", flush=True)
        time.sleep(min(POLL_INTERVAL_SECONDS, remaining))
    print(f"Build deferred: capacity was not available within {WAIT_TIMEOUT_SECONDS} seconds; no build was started.",
          file=sys.stderr, flush=True)
    return 1


if __name__ == "__main__":
    sys.exit(wait_for_capacity())
