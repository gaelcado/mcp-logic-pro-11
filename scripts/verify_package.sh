#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ZIP="$ROOT/dist/logic-pro-11-mcp-0.1.0-preview-macos-universal.zip"
TEMP=$(mktemp -d)
trap 'rm -rf "$TEMP"' EXIT HUP INT TERM

(cd "$ROOT/dist" && shasum -a 256 -c SHA256SUMS.txt)
ditto -x -k "$ZIP" "$TEMP"
test -s "$TEMP/Lisez-moi.txt"
APP="$TEMP/Logic Pro 11 MCP.app"
BIN="$APP/Contents/MacOS/logic-pro-11-mcp"
test -x "$BIN"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")" = "com.gaelcado.logic-pro-11-mcp"
ARCHS=$(lipo -archs "$BIN")
case " $ARCHS " in *" arm64 "*) : ;; *) echo 'Architecture arm64 absente' >&2; exit 1 ;; esac
case " $ARCHS " in *" x86_64 "*) : ;; *) echo 'Architecture x86_64 absente' >&2; exit 1 ;; esac
codesign --verify --deep --strict "$APP"
"$BIN" --version | grep 'MCP 2026-07-28'
echo 'Archive extraite, deux architectures, signature et lancement vérifiés ; Logic non testé.'
