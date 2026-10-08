#!/usr/bin/env bash
#
# Build a signed release DMG of the checked-out commit and print its path as the last line of output.
# scripts/ui-test-and-publish.sh calls this after the UI tests pass:
#
#     scripts/build-release-dmg.sh <work folder>
#
# This scripts the manual process in README.md ("Steps to Build and Create a Notarized DMG"): archive a
# Release build, export it for Developer ID (Organizer's Direct Distribution), put it in a DMG next to an
# Applications link, sign the DMG and notarize it. Whoever cuts releases should keep it matching the
# process they actually follow (background image, window layout, notarization), since the DMG it prints
# is what gets published.
#
# Needs the Developer ID Application certificate for team TCUD568B3U and the FocusBearMainAppProfile /
# FocusBearHelperPersonalAcProfilePrashant provisioning profiles. Set NOTARY_PROFILE to a
# `xcrun notarytool store-credentials` keychain profile to notarize; without it the DMG is signed but
# not notarized.
set -euo pipefail

cd "$(dirname "$0")/.."

readonly TEAM_ID="TCUD568B3U"
readonly DEVELOPER_ID_AUTHORITY="Developer ID Application"
# The identity Config/Signing-Release.xcconfig signs the app with.
readonly DMG_SIGNING_IDENTITY="${DMG_SIGNING_IDENTITY:-$DEVELOPER_ID_AUTHORITY: Focus Bear Pty Ltd ($TEAM_ID)}"
readonly MAIN_APP_BUNDLE_ID="com.App.EarnYourScreentime"
readonly MAIN_APP_PROFILE="FocusBearMainAppProfile"
readonly HELPER_BUNDLE_ID="com.focusbear.focusbearhelper"
readonly HELPER_PROFILE="FocusBearHelperPersonalAcProfilePrashant"
readonly APP_NAME="Focus Bear"

[ $# -eq 1 ] || { echo "usage: $0 <work folder>" >&2; exit 64; }
readonly WORK="$1"
mkdir -p "$WORK"

fail() { echo "error: $*" >&2; exit 1; }

write_export_options() {
  cat > "$1" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>signingStyle</key><string>manual</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>$MAIN_APP_BUNDLE_ID</key><string>$MAIN_APP_PROFILE</string>
    <key>$HELPER_BUNDLE_ID</key><string>$HELPER_PROFILE</string>
  </dict>
</dict>
</plist>
EOF
}

# Prints the path of the exported, Developer ID-signed app.
export_release_app() {
  local archive="$WORK/FocusBear.xcarchive" log="$WORK/build.log"
  echo "Building the Release archive (log: $log)…" >&2
  xcodebuild archive -workspace FocusBear.xcworkspace -scheme "$APP_NAME" -configuration Release \
    -archivePath "$archive" > "$log" 2>&1 || { tail -30 "$log" >&2; fail "the Release archive failed"; }
  write_export_options "$WORK/ExportOptions.plist"
  xcodebuild -exportArchive -archivePath "$archive" -exportOptionsPlist "$WORK/ExportOptions.plist" \
    -exportPath "$WORK/export" >> "$log" 2>&1 || { tail -30 "$log" >&2; fail "the Developer ID export failed"; }
  local app="$WORK/export/$APP_NAME.app"
  codesign --verify --deep --strict "$app" || fail "the exported app's signature doesn't verify"
  codesign -dvv "$app" 2>&1 | grep -q "^Authority=$DEVELOPER_ID_AUTHORITY: .*($TEAM_ID)" ||
    fail "the exported app isn't signed with the team's Developer ID certificate"
  echo "$app"
}

# Prints the path of the DMG.
make_dmg() {
  local app="$1" staging="$WORK/dmg"
  local version build dmg
  version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app/Contents/Info.plist")
  build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$app/Contents/Info.plist")
  dmg="$WORK/Focus-Bear-$version-$build-$(git rev-parse --short HEAD).dmg"
  mkdir -p "$staging"
  ditto "$app" "$staging/$APP_NAME.app"
  ln -s /Applications "$staging/Applications"
  hdiutil create -volname "$APP_NAME" -srcfolder "$staging" -format UDZO -ov "$dmg" >&2
  codesign -f -s "$DMG_SIGNING_IDENTITY" --timestamp "$dmg" >&2 || fail "signing the DMG failed"
  echo "$dmg"
}

notarize_dmg() {
  local dmg="$1"
  if [ -z "${NOTARY_PROFILE:-}" ]; then
    echo "NOTARY_PROFILE isn't set, so the DMG is signed but not notarized." >&2
    return
  fi
  echo "Notarizing…" >&2
  xcrun notarytool submit "$dmg" --keychain-profile "$NOTARY_PROFILE" --wait >&2 || fail "notarization failed"
  xcrun stapler staple "$dmg" >&2 || fail "stapling the notarization ticket failed"
  spctl --assess -vv --type install "$dmg" >&2 || fail "Gatekeeper rejects the notarized DMG"
}

app=$(export_release_app)
dmg=$(make_dmg "$app")
notarize_dmg "$dmg"
echo "$dmg"
