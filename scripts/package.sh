#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=0.2.0-preview
OUT="$ROOT/dist"
APP="$OUT/Logic Pro 11 MCP.app"
mkdir -p "$OUT"

for ARCH in arm64 x86_64; do
  swift build --package-path "$ROOT" -c release \
    --triple "$ARCH-apple-macosx14.0" \
    --scratch-path "$ROOT/.build/package-$ARCH"
done
ARM_BIN=$(swift build --package-path "$ROOT" -c release --triple arm64-apple-macosx14.0 --scratch-path "$ROOT/.build/package-arm64" --show-bin-path)
INTEL_BIN=$(swift build --package-path "$ROOT" -c release --triple x86_64-apple-macosx14.0 --scratch-path "$ROOT/.build/package-x86_64" --show-bin-path)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create \
  "$ARM_BIN/logic-pro-11-mcp" \
  "$INTEL_BIN/logic-pro-11-mcp" \
  -output "$APP/Contents/MacOS/logic-pro-11-mcp"
cp "$ROOT/packaging/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/packaging/INSTALLATION.txt" "$APP/Contents/Resources/INSTALLATION.txt"

if [ -n "${LOGIC_MCP_SIGN_IDENTITY:-}" ]; then
  codesign --force --options runtime --timestamp --sign "$LOGIC_MCP_SIGN_IDENTITY" "$APP"
else
  codesign --force --sign - "$APP"
fi

ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/logic-pro-11-mcp-$VERSION-macos-universal.zip"
cp "$ROOT/packaging/INSTALLATION.txt" "$OUT/Lisez-moi.txt"
(cd "$OUT" && zip -q "logic-pro-11-mcp-$VERSION-macos-universal.zip" Lisez-moi.txt)
(cd "$OUT" && shasum -a 256 "logic-pro-11-mcp-$VERSION-macos-universal.zip" > SHA256SUMS.txt)
echo "Paquet créé : $OUT/logic-pro-11-mcp-$VERSION-macos-universal.zip"
