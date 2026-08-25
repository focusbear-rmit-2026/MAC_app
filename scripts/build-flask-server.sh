#!/usr/bin/env bash
#
# Build (and sign) the embedded Flask server binaries.
#
# The app ships a tiny Flask server (docs/FlaskAppBuild/server.py) as a PyInstaller
# binary, in two arch-specific slots:
#
#   FocusBear/server       arm64   -> loaded by the Apple-Silicon app (#if arch(arm64))
#   FocusBear/serverIntel  x86_64  -> loaded by the Intel app        (#else)
#
# IMPORTANT: `server` MUST be arm64-native. It used to be x86_64 and relied on the
# arm64 app running it under Rosetta -- that crash-loops ("Bad CPU type in executable")
# on Apple-Silicon Macs without Rosetta installed (e.g. clean macOS 26 Tahoe). See #2310.
# So we build each slot for its own architecture; we do NOT ship one x86_64 binary in
# both slots.
#
# Usage:
#   ./scripts/build-flask-server.sh                # ad-hoc sign (fine for Debug/dev)
#   ./scripts/build-flask-server.sh "Developer ID Application: Focus Bear Pty Ltd (TCUD568B3U)"
#                                                  # Developer-ID sign for release/notarisation
#
# Requires:
#   * an arm64 Python  (Homebrew /opt/homebrew, or a universal2 python.org run under arch -arm64)
#   * an x86_64-capable Python (a universal2 python.org install in /Library/Frameworks;
#     Homebrew's arm64-only python can NOT produce the Intel binary)
#
set -euo pipefail

SIGN_IDENTITY="${1:--}"   # default "-" = ad-hoc

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$REPO_ROOT/docs/FlaskAppBuild"
ENTITLEMENTS="$BUILD_DIR/serverIntel.entitlements"

[[ -f "$ENTITLEMENTS" ]] || { echo "ERROR: entitlements not found: $ENTITLEMENTS" >&2; exit 1; }

# --- locate an arch-capable python for a given arch ------------------------------
# echoes the path of a python3 that can run under `arch -<want>`; empty if none.
find_python_for_arch() {
  local want="$1" cand
  # Prefer a universal2 python.org install (can run under either arch), then Homebrew.
  for cand in \
      /Library/Frameworks/Python.framework/Versions/*/bin/python3 \
      /opt/homebrew/bin/python3 \
      /usr/local/bin/python3 \
      "$(command -v python3 || true)"; do
    [[ -n "$cand" && -x "$cand" ]] || continue
    if arch -"$want" "$cand" -c 'import sys' >/dev/null 2>&1; then
      echo "$cand"; return 0
    fi
  done
  return 1
}

# --- build one slot: <arch> <venv-dir> <dest-path> -------------------------------
build_slot() {
  local arch="$1" venv="$2" dest="$3" py
  py="$(find_python_for_arch "$arch")" || {
    echo "ERROR: no $arch-capable python found." >&2
    if [[ "$arch" == "x86_64" ]]; then
      echo "Install a universal2 Python from python.org, then re-run." >&2
    else
      echo "Install an arm64 Python (Homebrew or python.org), then re-run." >&2
    fi
    exit 1
  }
  echo "==> Building $arch slot ($dest)"
  echo "    using $arch python: $py"

  cd "$BUILD_DIR"
  if [[ ! -x "$venv/bin/python" ]]; then
    echo "    creating $arch venv ($venv) ..."
    arch -"$arch" "$py" -m venv "$venv"
  fi
  echo "    installing build deps ..."
  arch -"$arch" "$venv/bin/python" -m pip install --quiet --upgrade pip flask pyinstaller

  echo "    running PyInstaller ..."
  # server.spec has target_arch=None -> PyInstaller builds for the host arch, which
  # `arch -<arch>` forces here. Output is always dist/server, so build+place one slot
  # fully before the next (each run --cleans the previous dist).
  arch -"$arch" "$venv/bin/python" -m PyInstaller --clean --noconfirm server.spec

  local built="$BUILD_DIR/dist/server"
  [[ -f "$built" ]] || { echo "ERROR: build produced no dist/server" >&2; exit 1; }

  # sanity: the binary is actually the arch we asked for
  local got
  got="$(lipo -archs "$built" 2>/dev/null || true)"
  [[ "$got" == "$arch" ]] || { echo "ERROR: expected $arch but built '$got'" >&2; exit 1; }

  # --- sign ---
  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    echo "    ad-hoc signing (Debug/dev) ..."
    codesign --force -s - "$built"
  else
    echo "    signing Developer-ID + hardened runtime: $SIGN_IDENTITY"
    codesign --force --options runtime --entitlements "$ENTITLEMENTS" -s "$SIGN_IDENTITY" "$built"
  fi

  install -m 755 "$built" "$dest"
  echo "    installed $dest ($arch)"
}

build_slot arm64  ".venv_arm64" "$REPO_ROOT/FocusBear/server"
build_slot x86_64 ".venv_x86"   "$REPO_ROOT/FocusBear/serverIntel"

echo
echo "Done. Verify with:"
echo "  lipo -archs FocusBear/server       # -> arm64"
echo "  lipo -archs FocusBear/serverIntel  # -> x86_64"
echo "  codesign -dvv FocusBear/server 2>&1 | grep -E 'Authority|flags'"
echo
echo "Reminder: for a release build, pass the Developer-ID identity so both binaries are"
echo "notarisation-valid, then 'git add' FocusBear/server and FocusBear/serverIntel."
