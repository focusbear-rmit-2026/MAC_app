#!/usr/bin/env bash
#
# Build (and sign) the embedded Flask server binary.
#
# The app ships a tiny Flask server (docs/FlaskAppBuild/server.py) as a PyInstaller
# binary at FocusBear/server and FocusBear/serverIntel. Both slots are x86_64 — the
# arm64 app runs `server` under Rosetta — so a single x86_64 build covers both.
#
# Usage:
#   ./scripts/build-flask-server.sh                # ad-hoc sign (fine for Debug/dev)
#   ./scripts/build-flask-server.sh "Developer ID Application: Focus Bear Pty Ltd (TCUD568B3U)"
#                                                  # Developer-ID sign for release/notarisation
#
# Requires an x86_64-capable Python. A universal2 python.org install
# (/Library/Frameworks/Python.framework) works under Rosetta; Homebrew's arm64-only
# python does not.
#
set -euo pipefail

SIGN_IDENTITY="${1:--}"   # default "-" = ad-hoc

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$REPO_ROOT/docs/FlaskAppBuild"
ENTITLEMENTS="$BUILD_DIR/serverIntel.entitlements"

# --- locate an x86_64-capable python ---------------------------------------------
PY=""
for cand in /Library/Frameworks/Python.framework/Versions/*/bin/python3; do
  [[ -x "$cand" ]] || continue
  if arch -x86_64 "$cand" -c 'import sys' >/dev/null 2>&1; then PY="$cand"; break; fi
done
if [[ -z "$PY" ]]; then
  echo "ERROR: no x86_64-capable python found." >&2
  echo "Install a universal2 Python from python.org, then re-run." >&2
  exit 1
fi
echo "Using x86_64 python: $PY"

cd "$BUILD_DIR"

# --- build ------------------------------------------------------------------------
VENV=".venv_x86"
if [[ ! -x "$VENV/bin/python" ]]; then
  echo "Creating x86_64 venv ..."
  arch -x86_64 "$PY" -m venv "$VENV"
fi
echo "Installing build deps ..."
arch -x86_64 "$VENV/bin/python" -m pip install --quiet --upgrade pip flask pyinstaller

echo "Building with PyInstaller ..."
arch -x86_64 "$VENV/bin/python" -m PyInstaller --clean --noconfirm server.spec

BUILT="$BUILD_DIR/dist/server"
[[ -f "$BUILT" ]] || { echo "ERROR: build produced no dist/server" >&2; exit 1; }

# --- sign -------------------------------------------------------------------------
if [[ "$SIGN_IDENTITY" == "-" ]]; then
  echo "Ad-hoc signing (Debug/dev) ..."
  codesign --force -s - "$BUILT"
else
  echo "Signing with Developer-ID + hardened runtime: $SIGN_IDENTITY"
  codesign --force --options runtime --entitlements "$ENTITLEMENTS" -s "$SIGN_IDENTITY" "$BUILT"
fi

# --- place ------------------------------------------------------------------------
install -m 755 "$BUILT" "$REPO_ROOT/FocusBear/server"
install -m 755 "$BUILT" "$REPO_ROOT/FocusBear/serverIntel"
echo "Installed FocusBear/server and FocusBear/serverIntel"
echo
echo "Reminder: for a release build, re-run with the Developer-ID identity so the"
echo "server is notarisation-valid. Then 'git add' the two binaries."
