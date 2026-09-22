#!/usr/bin/env bash
#
# Fetch the vendored ONNX Runtime (universal2: arm64 + x86_64 macOS) for the relevance shadow-mode model.
#
# Universal, NOT arm64-only: the app ships a universal binary (Apple Silicon + Intel users), and an
# arm64-only dylib made the Archive's x86_64 slice fail to link (_OrtGetApiBase undefined) even though
# arm64 Debug built fine.
#
# ONNX Runtime is a large, prebuilt library, so we do NOT commit it to git. It is the
# newest official ORT that still targets macOS 11 (1.20+ require macOS 13/14, as do the
# CocoaPods) — see FocusBear/RelevanceModel/README.md. It is downloaded here and placed
# under FocusBear/RelevanceModel/onnxruntime/{lib,include}, where the Xcode project links,
# embeds (code-sign-on-copy) and header-searches it.
#
# Run once after cloning (and again if ORT_VERSION changes):
#
#     ./scripts/fetch-onnxruntime.sh
#
# The download is checksum-verified against a pinned SHA-256.
set -euo pipefail

ORT_VERSION="1.19.2"
ORT_SHA256="b0289ddbc32f76e5d385abc7b74cc7c2c51cdf2285b7d118bf9d71206e5aee3a"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$REPO_ROOT/FocusBear/RelevanceModel/onnxruntime"
TARBALL="onnxruntime-osx-universal2-${ORT_VERSION}.tgz"
URL="https://github.com/microsoft/onnxruntime/releases/download/v${ORT_VERSION}/${TARBALL}"

DYLIB="$DEST/lib/libonnxruntime.${ORT_VERSION}.dylib"
if [ -f "$DYLIB" ]; then
  # Only skip if the present copy is the universal (arm64 + x86_64) build. A machine that fetched the
  # old arm64-only tarball must re-fetch, or the Archive's x86_64 slice fails to link (_OrtGetApiBase).
  if lipo -archs "$DYLIB" 2>/dev/null | grep -q x86_64; then
    echo "ONNX Runtime ${ORT_VERSION} (universal) already present at $DEST — nothing to do."
    exit 0
  fi
  echo "Existing ONNX Runtime at $DEST is not universal (arm64-only) — re-fetching the universal build…"
  rm -rf "$DEST/lib" "$DEST/include"
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
echo "Downloading ONNX Runtime ${ORT_VERSION} (universal2: arm64 + x86_64 macOS)…"
curl -fsSL "$URL" -o "$TMP/$TARBALL"

echo "Verifying checksum…"
ACTUAL="$(shasum -a 256 "$TMP/$TARBALL" | awk '{print $1}')"
if [ "$ACTUAL" != "$ORT_SHA256" ]; then
  echo "ERROR: checksum mismatch for $TARBALL" >&2
  echo "  expected $ORT_SHA256" >&2
  echo "  actual   $ACTUAL" >&2
  exit 1
fi

tar xzf "$TMP/$TARBALL" -C "$TMP"
SRC="$TMP/onnxruntime-osx-universal2-${ORT_VERSION}"
mkdir -p "$DEST/lib" "$DEST/include"
cp "$SRC/lib/libonnxruntime.${ORT_VERSION}.dylib" "$DEST/lib/"
cp "$SRC/include/"*.h "$DEST/include/"
echo "ONNX Runtime ${ORT_VERSION} installed to $DEST"
