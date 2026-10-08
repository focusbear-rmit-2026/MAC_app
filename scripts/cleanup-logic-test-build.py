#!/usr/bin/env python3
"""Remove only this CI run's unused derived data, retaining workspace diagnostics."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

COMMAND_TIMEOUT_SECONDS = 10
NO_MATCH_EXIT_CODE = 1
ACTIVE_BUILD_REASON = "an Xcode build is active"
CLEANUP_WAIT_SECONDS = 300
CLEANUP_POLL_SECONDS = 10
BUILD_DIRECTORY_PREFIX = "logic-tests-"
BUILD_DIRECTORY_SUFFIX = ".noindex"


def build_directory_for(environment):
    runner_temp = environment.get("RUNNER_TEMP", "")
    run_id = environment.get("GITHUB_RUN_ID", "")
    attempt = environment.get("GITHUB_RUN_ATTEMPT", "")
    if (not runner_temp or not Path(runner_temp).is_absolute()
            or not re.fullmatch(r"[0-9]+", run_id) or not re.fullmatch(r"[0-9]+", attempt)):
        raise ValueError("invalid run identity or temporary directory")
    temporary_directory = Path(runner_temp).resolve(strict=True)
    if temporary_directory == Path(temporary_directory.anchor) or not temporary_directory.is_dir():
        raise ValueError("invalid temporary directory")
    build_directory = temporary_directory / f"{BUILD_DIRECTORY_PREFIX}{run_id}-{attempt}{BUILD_DIRECTORY_SUFFIX}"
    if build_directory.is_symlink():
        raise ValueError("build directory is a symbolic link")
    return build_directory


def cleanup_build(environment=os.environ):
    try:
        build_directory = build_directory_for(environment)
        temporary_directory = build_directory.parent
        if not build_directory.exists():
            return True, "no generated build directory remains"
        if not build_directory.is_dir() or build_directory.resolve(strict=True).parent != temporary_directory:
            return False, "build directory is outside this run's temporary directory"
        builders = subprocess.run(["pgrep", "-x", "xcodebuild"], capture_output=True, text=True,
                                  timeout=COMMAND_TIMEOUT_SECONDS, check=False)
        if builders.returncode == 0 and not builders.stderr.strip():
            return False, ACTIVE_BUILD_REASON
        if builders.returncode != NO_MATCH_EXIT_CODE or builders.stderr.strip():
            return False, "Xcode build inventory is unavailable"
        processes = subprocess.run(["ps", "-axo", "command="], capture_output=True, text=True,
                                   timeout=COMMAND_TIMEOUT_SECONDS, check=True)
        if not processes.stdout.strip() or processes.stderr.strip():
            return False, "process inventory is unavailable"
        if str(build_directory) in processes.stdout or str(Path(environment["RUNNER_TEMP"]) / build_directory.name) in processes.stdout:
            return False, "a process still references this build directory"
        shutil.rmtree(build_directory)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        return False, f"cleanup unavailable: {type(error).__name__}"
    return True, "removed this run's unused generated build directory"


def cleanup_build_when_idle(environment=os.environ):
    deadline = time.monotonic() + CLEANUP_WAIT_SECONDS
    while True:
        cleaned, reason = cleanup_build(environment)
        if cleaned or reason != ACTIVE_BUILD_REASON:
            return cleaned, reason
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return False, f"{reason}; cleanup wait timed out"
        print(f"Logic-test build cleanup: waiting for active build ({int(remaining)}s remaining)", flush=True)
        time.sleep(min(CLEANUP_POLL_SECONDS, remaining))


def main(arguments=None, environment=os.environ):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--print-path", action="store_true", help="Print the validated path without cleanup or process inspection")
    options = parser.parse_args(arguments)
    if options.print_path:
        try:
            print(build_directory_for(environment))
        except (OSError, ValueError) as error:
            print(f"Logic-test path unavailable: {type(error).__name__}", file=sys.stderr)
            return 1
        return 0
    cleaned, reason = cleanup_build_when_idle(environment)
    print(f"Logic-test build cleanup: {reason}", flush=True)
    return 0 if cleaned else 1


if __name__ == "__main__":
    sys.exit(main())
