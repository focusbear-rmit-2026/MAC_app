#!/usr/bin/env bash
#
# Fetch the vendored ONNX Runtime (arm64 macOS) for the relevance shadow-mode model.
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
ORT_SHA256="370c49770e2e1f243e17c7b227bb7f4b3da793b847d02f38016dc0e46c30fbe1"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$REPO_ROOT/FocusBear/RelevanceModel/onnxruntime"
TARBALL="onnxruntime-osx-arm64-${ORT_VERSION}.tgz"
URL="https://github.com/microsoft/onnxruntime/releases/download/v${ORT_VERSION}/${TARBALL}"

if [ -f "$DEST/lib/libonnxruntime.${ORT_VERSION}.dylib" ]; then
  echo "ONNX Runtime ${ORT_VERSION} already present at $DEST — nothing to do."
  exit 0
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
echo "Downloading ONNX Runtime ${ORT_VERSION} (arm64 macOS)…"
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
SRC="$TMP/onnxruntime-osx-arm64-${ORT_VERSION}"
mkdir -p "$DEST/lib" "$DEST/include"
cp "$SRC/lib/libonnxruntime.${ORT_VERSION}.dylib" "$DEST/lib/"
cp "$SRC/include/"*.h "$DEST/include/"
echo "ONNX Runtime ${ORT_VERSION} installed to $DEST"
