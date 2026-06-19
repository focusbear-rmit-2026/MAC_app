#!/usr/bin/env bash
#
# Fetch the vendored Sparkle.framework.
#
# Sparkle is a large, prebuilt binary framework, so we do NOT commit it to git.
# Instead it is downloaded from the official Sparkle release (already code-signed
# by the Sparkle project) and placed at the repo root as `Sparkle.framework`,
# where the Xcode project links and embeds it.
#
# Run this once after cloning (and again if SPARKLE_VERSION below changes):
#
#     ./scripts/fetch-sparkle.sh
#
# The download is checksum-verified against a pinned SHA-256.
#
set -euo pipefail

SPARKLE_VERSION="2.7.0"
# SHA-256 of https://github.com/sparkle-project/Sparkle/releases/download/<ver>/Sparkle-<ver>.tar.xz
# Update this together with SPARKLE_VERSION.
SPARKLE_SHA256="09fed60cca507d2dc542c86c22e525598af5483954a5c66366ce039647ec88e9"

# Repo root = parent of this script's directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="$REPO_ROOT/Sparkle.framework"

ARCHIVE="Sparkle-${SPARKLE_VERSION}.tar.xz"
URL="https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/${ARCHIVE}"

# Skip the download if the framework is already present at the right version.
if [[ -e "$DEST/Resources/Info.plist" ]]; then
  current="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$DEST/Resources/Info.plist" 2>/dev/null || true)"
  if [[ "$current" == "$SPARKLE_VERSION" ]]; then
    echo "Sparkle.framework $SPARKLE_VERSION already present — nothing to do."
    echo "(Delete $DEST and re-run to force a fresh download.)"
    exit 0
  fi
  echo "Found Sparkle.framework version '${current:-unknown}', want $SPARKLE_VERSION — replacing."
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading $URL ..."
curl -fsSL -o "$TMP/$ARCHIVE" "$URL"

echo "Verifying checksum ..."
actual="$(shasum -a 256 "$TMP/$ARCHIVE" | awk '{print $1}')"
if [[ "$actual" != "$SPARKLE_SHA256" ]]; then
  echo "ERROR: checksum mismatch for $ARCHIVE" >&2
  echo "  expected: $SPARKLE_SHA256" >&2
  echo "  actual:   $actual" >&2
  exit 1
fi

echo "Extracting Sparkle.framework ..."
# Extract only the framework (preserves the Versions/Current symlink structure).
tar -xJf "$TMP/$ARCHIVE" -C "$TMP" "./Sparkle.framework" 2>/dev/null \
  || tar -xJf "$TMP/$ARCHIVE" -C "$TMP" "Sparkle.framework"

rm -rf "$DEST"
mv "$TMP/Sparkle.framework" "$DEST"

installed="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$DEST/Resources/Info.plist" 2>/dev/null || echo '?')"
echo "Installed Sparkle.framework $installed at $DEST"
