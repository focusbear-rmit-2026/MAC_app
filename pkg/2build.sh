#!/bin/bash
set -euo pipefail

# Notarization credentials come from the environment — never hardcode them here.
#   NOTARY_APPLE_ID  - Apple ID used for notarization
#   NOTARY_PASSWORD  - app-specific password for that Apple ID
#   NOTARY_TEAM_ID   - team id (defaults to TCUD568B3U)
: "${NOTARY_APPLE_ID:?Set NOTARY_APPLE_ID (Apple ID used for notarization)}"
: "${NOTARY_PASSWORD:?Set NOTARY_PASSWORD (app-specific password)}"
NOTARY_TEAM_ID="${NOTARY_TEAM_ID:-TCUD568B3U}"

# Name of the package.
NAME="Late No More"

# Once installed the identifier is used as the filename for a receipt files in /var/db/receipts/.
IDENTIFIER="com.focusbear.latenomore"

# Package version number.
VERSION="1.0"

productbuild --distribution Distribution.xml --package-path "$NAME-$VERSION.pkg"  --resources resources "Late No More.pkg" --sign "Developer ID Installer: Jeremy Nagel (TCUD568B3U)"

# Sign the final pkg
codesign -f -s "Developer ID Application: Jeremy Nagel (TCUD568B3U)" -v "Late No More.pkg"

#Verify Sign
codesign -vvv --deep --strict "Late No More.pkg"

xcrun notarytool submit "Late No More.pkg" --wait --apple-id "$NOTARY_APPLE_ID" --password "$NOTARY_PASSWORD" --team-id "$NOTARY_TEAM_ID"

xcrun stapler staple "Late No More.pkg"

spctl --assess -vv --type install "Late No More.pkg"
