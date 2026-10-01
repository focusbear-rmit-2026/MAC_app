#!/bin/bash
set -euo pipefail

# A test host must never register itself as the handler for the user's focusbear:// links.
[ -n "${FB_BUNDLE_ID_SUFFIX:-}" ] || exit 0
TEST_HOST_PLIST="${TARGET_BUILD_DIR:?}/${INFOPLIST_PATH:?}"
if /usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes' "$TEST_HOST_PLIST" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c 'Delete :CFBundleURLTypes' "$TEST_HOST_PLIST"
fi
