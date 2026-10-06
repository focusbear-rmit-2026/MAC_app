#!/bin/bash
# Scan what Focus Bear leaves on disk for plaintext secrets and personal data.
#
# Default: the UI-test build (com.App.EarnYourScreentime.uitests) and its own shared suite, looking
# for JWTs, the test account's email and the "UI test at-rest" canary titles the at-rest UI tests
# create. The installed app's domain can only be scanned with --secrets-only (JWTs, and an email you
# pass), so this never reports on anyone's task names. Read-only: it never writes, never runs
# `defaults`, never touches the keychain, and prints file/key names and finding kinds, never values.
#
# Usage:
#   scripts/check-at-rest.sh                                # the UI-test build, full scan
#   scripts/check-at-rest.sh --email ci@example.com         # also flag the test account's email
#   scripts/check-at-rest.sh --domain com.App.EarnYourScreentime --secrets-only
#
# Exit status: 0 clean (or only allow-listed findings), 1 findings, 2 usage error.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/check_at_rest.py" --allowlist "$SCRIPT_DIR/at-rest-allowlist.txt" "$@"
