#!/usr/bin/env bash
#
# Upload macOS debug symbols (dSYMs) to Sentry so crash and App-Hang
# main-thread stacks symbolicate instead of showing as <anonymous>.
#
# Fixes Focus-Bear/Mac-App#1954 (crashes) and #1955 (App Hangs): the Sentry
# Cocoa SDK captures the main-thread stack, but without the matching dSYMs
# Sentry can't turn addresses into function names.
#
# Two ways to run it:
#
#   1. Automatically, as the "[Sentry] Upload Debug Symbols" Xcode Run Script
#      build phase on the "Focus Bear" target. It only uploads for Release
#      builds (Archive), reading $DWARF_DSYM_FOLDER_PATH / $CONFIGURATION from
#      Xcode. Debug builds are a no-op, so day-to-day development is unaffected.
#
#   2. Manually, to back-fill an already-shipped build (e.g. to symbolicate the
#      existing App Hangs). Point it at an .xcarchive, a dSYMs folder, a .app,
#      or a .dSYM:
#
#        SENTRY_AUTH_TOKEN=... ./scripts/upload-dsyms.sh \
#          "~/Library/Developer/Xcode/Archives/2026-06-18/Focus Bear.xcarchive"
#
# Configuration comes from the environment — never hardcode a token here:
#   SENTRY_AUTH_TOKEN  (required) auth token with project:releases / project:write
#   SENTRY_ORG         (optional) defaults to focus-bear
#   SENTRY_PROJECT     (optional) defaults to focus-bear-macos
#
# Requires sentry-cli:  brew install getsentry/tools/sentry-cli
#                  or:  npm install -g @sentry/cli
#
set -euo pipefail

SENTRY_ORG="${SENTRY_ORG:-focus-bear}"
SENTRY_PROJECT="${SENTRY_PROJECT:-focus-bear-macos}"

# When invoked as an Xcode Run Script build phase, $CONFIGURATION is set.
readonly RELEASE_CONFIGURATION="Release"
is_xcode_build_phase() { [[ -n "${CONFIGURATION:-}" ]]; }

log() { echo "[upload-dsyms] $*"; }

# In an Xcode build phase, only act on Release archives; skip Debug/dev builds
# so a missing token or missing sentry-cli never breaks a local build.
if is_xcode_build_phase && [[ "${CONFIGURATION}" != "${RELEASE_CONFIGURATION}" ]]; then
  log "CONFIGURATION=${CONFIGURATION} (not ${RELEASE_CONFIGURATION}) — skipping dSYM upload."
  exit 0
fi

if ! command -v sentry-cli >/dev/null 2>&1; then
  MSG="sentry-cli not found. Install it: brew install getsentry/tools/sentry-cli (or npm i -g @sentry/cli)."
  if is_xcode_build_phase; then
    # Fail the Release build — dSYM upload is mandatory for releases.
    echo "error: ${MSG}" >&2
    exit 1
  fi
  log "ERROR: ${MSG}"
  exit 1
fi

# Xcode launched from the Dock/Finder often does NOT inherit vars set via `launchctl setenv`
# (e.g. by ~/Library/LaunchAgents/io.focusbear.sentry-token.plist) — it captures its environment
# at launch. Fall back to reading the token straight from the launchd user domain so archiving
# works without having to relaunch Xcode from a shell. CI still supplies it via env/secrets.
if [[ -z "${SENTRY_AUTH_TOKEN:-}" ]] && command -v launchctl >/dev/null 2>&1; then
  SENTRY_AUTH_TOKEN="$(launchctl getenv SENTRY_AUTH_TOKEN 2>/dev/null || true)"
fi

if [[ -z "${SENTRY_AUTH_TOKEN:-}" ]]; then
  MSG="SENTRY_AUTH_TOKEN is not set — required to upload dSYMs to Sentry."
  if is_xcode_build_phase; then
    echo "error: ${MSG} Set it in your environment / CI secrets before archiving a release." >&2
    exit 1
  fi
  log "ERROR: ${MSG}"
  exit 1
fi
export SENTRY_AUTH_TOKEN

# Resolve the path to scan for debug files.
#   - explicit argument wins (back-fill / manual runs)
#   - otherwise use Xcode's dSYM folder for the current build
UPLOAD_PATH="${1:-${DWARF_DSYM_FOLDER_PATH:-}}"
if [[ -z "${UPLOAD_PATH}" ]]; then
  log "ERROR: no path to upload. Pass an .xcarchive / dSYMs folder / .app, or run inside an Xcode build phase."
  exit 1
fi
if [[ ! -e "${UPLOAD_PATH}" ]]; then
  log "ERROR: path does not exist: ${UPLOAD_PATH}"
  exit 1
fi

log "Uploading debug files from '${UPLOAD_PATH}' to ${SENTRY_ORG}/${SENTRY_PROJECT} ..."
sentry-cli debug-files upload \
  --org "${SENTRY_ORG}" \
  --project "${SENTRY_PROJECT}" \
  "${UPLOAD_PATH}"

log "Done. Verify at https://${SENTRY_ORG}.sentry.io/settings/projects/${SENTRY_PROJECT}/debug-symbols/"
