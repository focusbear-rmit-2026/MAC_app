#!/usr/bin/env bash
#
# Fetch the vendored, universal `esptool` binary used by the in-app Focus Button
# firmware flasher.
#
# esptool ships as a large, self-contained per-arch binary, so we do NOT commit
# it to git. Instead the official Espressif release binaries for both macOS
# architectures are downloaded, checksum-verified, and combined into a single
# universal binary at the repo root as `esptool`, where a build phase copies it
# into the app bundle (Contents/Resources/esptool) and code-signs it.
#
# Run this once after cloning (and again if ESPTOOL_VERSION below changes):
#
#     ./scripts/fetch-esptool.sh
#
set -euo pipefail

ESPTOOL_VERSION="5.3.0"
# SHA-256 of the official macOS release tarballs (update with ESPTOOL_VERSION).
ARM64_SHA256="78369f963f1454ecc1b5516119e43aa5aa5cc1afeaca467458cbbeef02675dd4"
AMD64_SHA256="ea33d15db3cc1f7aec1e6af0ed327ec13c82f139f442a100eca76d5b29094be9"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="$REPO_ROOT/esptool"

base="https://github.com/espressif/esptool/releases/download/v${ESPTOOL_VERSION}"

# Skip if a universal binary of the right version is already present.
if [[ -x "$DEST" ]] && lipo -archs "$DEST" 2>/dev/null | grep -q "arm64" \
   && "$DEST" version 2>/dev/null | grep -q "$ESPTOOL_VERSION"; then
  echo "esptool $ESPTOOL_VERSION (universal) already present at $DEST — nothing to do."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fetch_arch() {  # <arch> <sha256> — logs to stderr, prints only the binary path to stdout
  local arch="$1" sha="$2"
  local tgz="esptool-v${ESPTOOL_VERSION}-macos-${arch}.tar.gz"
  echo "Downloading $tgz ..." >&2
  curl -fsSL -o "$TMP/$tgz" "$base/$tgz"
  local actual; actual="$(shasum -a 256 "$TMP/$tgz" | awk '{print $1}')"
  if [[ "$actual" != "$sha" ]]; then
    echo "ERROR: checksum mismatch for $tgz" >&2
    echo "  expected: $sha" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi
  tar -xzf "$TMP/$tgz" -C "$TMP" "esptool-macos-${arch}/esptool" >&2
  echo "$TMP/esptool-macos-${arch}/esptool"
}

arm_bin="$(fetch_arch arm64 "$ARM64_SHA256")"
amd_bin="$(fetch_arch amd64 "$AMD64_SHA256")"

echo "Creating universal binary ..."
lipo -create "$arm_bin" "$amd_bin" -output "$DEST"
chmod +x "$DEST"

echo "Installed universal esptool at $DEST"
lipo -archs "$DEST"
"$DEST" version 2>/dev/null | head -1 || true
