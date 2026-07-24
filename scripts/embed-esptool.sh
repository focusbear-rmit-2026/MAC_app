#!/usr/bin/env bash
#
# Xcode build-phase script: embed the vendored `esptool` binary into the app
# bundle (Contents/Resources/esptool) and code-sign it with the Hardened
# Runtime + the entitlements esptool needs as a PyInstaller binary.
#
# The in-app Focus Button firmware flasher resolves esptool from the bundle
# first (FocusButtonFirmwareUpdater.resolveEsptool), so a signed, notarized
# build can flash on a clean machine with no separately-installed esptool.
#
# Run `./scripts/fetch-esptool.sh` first to vendor `$SRCROOT/esptool` (it is
# gitignored, like Sparkle.framework). This phase does no network access.
set -euo pipefail

SRC="${SRCROOT}/esptool"
ENTITLEMENTS="${SRCROOT}/scripts/esptool.entitlements"
DEST_DIR="${CODESIGNING_FOLDER_PATH}/Contents/Resources"
DEST="${DEST_DIR}/esptool"

if [[ ! -x "$SRC" ]]; then
  # Don't fail local builds that don't need flashing; release builds run
  # fetch-esptool.sh first (the in-app flasher reports esptool is missing if so).
  echo "warning: vendored esptool not found at $SRC — skipping bundle. Run ./scripts/fetch-esptool.sh to include the in-app firmware flasher."
  exit 0
fi

mkdir -p "$DEST_DIR"
cp -f "$SRC" "$DEST"
chmod +x "$DEST"

# Sign with the same identity Xcode is using for the app. Skip when building
# unsigned (e.g. local Debug with no identity) — the copy is still usable for
# local testing via the developer's own esptool fallback.
if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${EXPANDED_CODE_SIGN_IDENTITY}" != "-" ]]; then
  echo "Code-signing bundled esptool with ${EXPANDED_CODE_SIGN_IDENTITY_NAME:-$EXPANDED_CODE_SIGN_IDENTITY}"
  codesign --force --timestamp --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$DEST"
  codesign --verify --strict "$DEST"
else
  echo "No code-sign identity (EXPANDED_CODE_SIGN_IDENTITY unset) — embedding esptool unsigned."
fi
