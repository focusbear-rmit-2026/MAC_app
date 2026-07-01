#!/usr/bin/env bash
#
# Render a Day Plan mockup to a PNG from a JSON scenario — scriptable & reproducible.
#
# The app boots, the offscreen DayPlanMockup renderer (in ScheduleViewController.swift) picks up
# the FB_MOCKUP_* env vars, lays the Day Plan out in an offscreen window, writes the PNG and quits.
# No real calendar/habit/task data is touched (the task store runs in non-persisting mock mode).
#
# Usage:
#   scripts/mockups/render-mockup.sh <scenario.json> [out.png] [WIDTHxHEIGHT]
#
# Examples:
#   scripts/mockups/render-mockup.sh scripts/mockups/high-school-student.json
#   scripts/mockups/render-mockup.sh scripts/mockups/high-school-student.json out/hs.png 1280x1000
#
# If you change Swift code, rebuild first:
#   xcodebuild -workspace FocusBear.xcworkspace -scheme "Focus Bear" -configuration Debug -derivedDataPath build
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

SCENARIO="${1:-}"
if [[ -z "$SCENARIO" || ! -f "$SCENARIO" ]]; then
  echo "usage: $0 <scenario.json> [out.png] [WIDTHxHEIGHT]" >&2
  echo "  (scenario file not found: '${SCENARIO}')" >&2
  exit 1
fi
SCENARIO="$(cd "$(dirname "$SCENARIO")" && pwd)/$(basename "$SCENARIO")"   # absolutize

# Default output: out/mockups/<scenario-basename>.png
DEFAULT_OUT="$REPO_ROOT/out/mockups/$(basename "${SCENARIO%.json}").png"
OUT="${2:-$DEFAULT_OUT}"
mkdir -p "$(dirname "$OUT")"
# Absolutize OUT (the app may run with a different cwd).
OUT="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"

SIZE="${3:-1280x1000}"

APP="$REPO_ROOT/build/Build/Products/Debug/Focus Bear.app"
BIN="$APP/Contents/MacOS/Focus Bear"
if [[ ! -x "$BIN" ]]; then
  echo "error: built app not found at: $APP" >&2
  echo "  build it first:" >&2
  echo "  xcodebuild -workspace FocusBear.xcworkspace -scheme \"Focus Bear\" -configuration Debug -derivedDataPath build" >&2
  exit 1
fi

echo "→ scenario: $SCENARIO"
echo "→ output:   $OUT  ($SIZE)"

rm -f "$OUT"

# Run the app binary directly (not `open`) so the env vars reach it and we can wait for exit.
# The app is chatty on stdout (auth tokens, logs); the renderer's status goes to stderr, so drop
# stdout and surface only the FB_MOCKUP lines.
FB_MOCKUP_FILE="$SCENARIO" \
FB_MOCKUP_OUT="$OUT" \
FB_MOCKUP_SIZE="$SIZE" \
  "$BIN" 2>&1 1>/dev/null | grep -E "FB_MOCKUP" || true

if [[ -f "$OUT" ]]; then
  echo "✓ wrote $OUT"
  # Surface the path for easy opening; uncomment to auto-open:
  # open "$OUT"
else
  echo "✗ render failed — no PNG written" >&2
  exit 1
fi
