#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/eyecandy.app"
EXECUTABLE="$ROOT_DIR/.build/release/eyecandy"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/ModuleCache"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/eyecandy"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"

if [ -d "$ROOT_DIR/Assets" ]; then
    cp -R "$ROOT_DIR/Assets/." "$APP_DIR/Contents/Resources/"
fi

codesign --force --deep --sign - "$APP_DIR" >/dev/null
echo "Packaged $APP_DIR"
