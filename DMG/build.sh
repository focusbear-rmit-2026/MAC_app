#!/bin/bash
set -euo pipefail

# Notarization credentials come from the environment — never hardcode them here.
#   NOTARY_APPLE_ID  - Apple ID used for notarization
#   NOTARY_PASSWORD  - app-specific password for that Apple ID
#   NOTARY_TEAM_ID   - team id (defaults to TCUD568B3U)
: "${NOTARY_APPLE_ID:?Set NOTARY_APPLE_ID (Apple ID used for notarization)}"
: "${NOTARY_PASSWORD:?Set NOTARY_PASSWORD (app-specific password)}"
NOTARY_TEAM_ID="${NOTARY_TEAM_ID:-TCUD568B3U}"

# Sign the final dmg
codesign -f -s "Developer ID Application: Jeremy Nagel (TCUD568B3U)" -v "Focus Bear.dmg"

#Verify Sign
codesign -vvv --deep --strict "Focus Bear.dmg"

xcrun notarytool submit "Focus Bear.dmg" --wait --apple-id "$NOTARY_APPLE_ID" --password "$NOTARY_PASSWORD" --team-id "$NOTARY_TEAM_ID"

xcrun stapler staple "Focus Bear.dmg"

spctl --assess -vv --type install "Focus Bear.dmg"
