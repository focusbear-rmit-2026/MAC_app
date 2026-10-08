#!/bin/bash
# Install a freshly built Debug app over the copy LaunchServices runs (~/Applications/Focus Bear.app).
#
# Two non-obvious constraints this encodes:
#
#  1. Kill by ABSOLUTE INSTALLED PATH. App-hosted XCTest runs launch a host process literally named
#     "Focus Bear" out of DerivedData, so `killall "Focus Bear"` — or any -f pattern that is a
#     substring of the DerivedData path — SIGKILLs a running test. That surfaces as a random test
#     dying with every executed test passing; only `xcresulttool` reveals "Test crashed with signal
#     kill". The GitHub Actions runner is this same Mac, so it red-lights other people's PRs too.
#  2. Never write into the .app in place (blocked): ditto to a non-.app staging name, then mv.
#  3. Two installs must never interleave. STAGING used to be a FIXED path with no lock, so when two
#     agents installed at once, B's `rm -rf STAGING` landed mid-ditto from A and both then raced on
#     `rm -rf INSTALLED` / `mv`. The loser left a bundle with Frameworks and Resources but NO
#     MacOS/ — an app that cannot launch, replacing one that could (2026-09-17 21:04). Hence the
#     lock, the per-process staging path, and the move-aside swap below.
#
# A bounded force-kill fallback is required when a routine blocks graceful termination.
set -euo pipefail

BUILT="${1:-$(cd "$(dirname "$0")/.." && pwd)/build/Build/Products/Debug/Focus Bear.app}"
INSTALLED="$HOME/Applications/Focus Bear.app"
# Per-process, so a concurrent run cannot delete the tree this one is still copying into.
STAGING="$HOME/Applications/.focus-bear-install.$$"
LOCK="$HOME/Applications/.focus-bear-install.lock"
STALE_LOCK_SECONDS=1800

[ -d "$BUILT" ] || { echo "no built app at: $BUILT" >&2; exit 1; }

# -x, never -f: `pgrep -f xcodebuild` matches this script's own command line and never clears.
if pgrep -x xcodebuild > /dev/null; then
    echo "xcodebuild is running — refusing to install, it would kill the test host" >&2
    exit 2
fi

# mkdir is atomic on APFS: two installs cannot both create the lock. A lock left behind by a killed
# run is cleared once it is plainly stale, so a crash does not block installs forever.
if [ -d "$LOCK" ]; then
    lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) ))
    if [ "$lock_age" -gt "$STALE_LOCK_SECONDS" ]; then
        echo "clearing a stale install lock (${lock_age}s old)" >&2
        rm -rf "$LOCK"
    fi
fi
if ! mkdir "$LOCK" 2>/dev/null; then
    echo "another install is in progress — refusing so the two cannot clobber each other" >&2
    exit 3
fi
trap 'rm -rf "$LOCK" "$STAGING"' EXIT

# Finish staging and validate every signed resource before disturbing the running app.
# A missing storyboard can crash much later, when its first controller is instantiated.
ditto "$BUILT" "$STAGING"
[ -x "$STAGING/Contents/MacOS/Focus Bear" ] || { echo "staged executable missing" >&2; exit 1; }
codesign --verify --deep --strict "$STAGING"
codesign --verify --deep --strict "$STAGING/Contents/Resources/FBHelper.app"
if [ -d "$INSTALLED" ]; then
    installed_requirement="$(codesign -d -r- "$INSTALLED" 2>/dev/null)"
    staged_requirement="$(codesign -d -r- "$STAGING" 2>/dev/null)"
    [ -n "$staged_requirement" ] && [ "$installed_requirement" = "$staged_requirement" ] || {
        echo "signing requirement changed — refusing to replace the installed app" >&2
        exit 1
    }
fi

launchctl bootout "gui/$UID/com.focusbear.focusbearhelper.plist" 2>/dev/null || true
# Stop only executables in the installed bundle, helper first. Do not kill test hosts,
# unrelated Python servers, or a helper belonging to another installation.
python3 - "$INSTALLED" <<'PY_STOP'
import os, signal, subprocess, sys, time
root = sys.argv[1] + "/Contents/"
groups = [
    [root + "Resources/FBHelper.app/Contents/MacOS/FBHelper"],
    [root + "MacOS/Focus Bear"],
    [root + "Resources/server", root + "Resources/serverIntel"],
]
def matching(paths):
    rows = subprocess.check_output(["ps", "-axo", "pid=,comm="], text=True).splitlines()
    return {int(parts[0]) for row in rows if len(parts := row.strip().split(None, 1)) == 2 and parts[1] in paths}
for paths in groups:
    targets = matching(paths)
    for pid in targets:
        try: os.kill(pid, signal.SIGTERM)
        except ProcessLookupError: pass
    deadline = time.monotonic() + 3
    while targets & matching(paths) and time.monotonic() < deadline:
        time.sleep(0.1)
    for pid in targets & matching(paths):
        try: os.kill(pid, signal.SIGKILL)
        except ProcessLookupError: pass
PY_STOP

# The swap: move the old bundle ASIDE rather than deleting it first, so there is no window in which
# ~/Applications has no Focus Bear at all, and so a failed mv can be rolled back.
OLD="$HOME/Applications/.focus-bear-old.$(date +%Y%m%d-%H%M%S).$$"
if [ -d "$INSTALLED" ]; then
    mv "$INSTALLED" "$OLD"
fi
if ! mv "$STAGING" "$INSTALLED"; then
    echo "install failed — restoring the previous bundle" >&2
    [ -d "$OLD" ] && mv "$OLD" "$INSTALLED"
    exit 1
fi
echo "previous bundle retained at: $OLD"

# Verify BEFORE launching: a bundle missing its executable is exactly what the old race produced,
# and `open` on one fails in a way that reads as "the app just closed".
if [ ! -x "$INSTALLED/Contents/MacOS/Focus Bear" ]; then
    echo "installed bundle has no executable — refusing to launch" >&2
    exit 1
fi
codesign --verify --deep --strict "$INSTALLED"
open -a "$INSTALLED"
echo "installed: $INSTALLED"
