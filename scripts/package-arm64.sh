#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/package-arm64.sh [--date YYYYMMDD] [--skip-build]

Builds and packages the macOS arm64 release into:
  dist/eyecandy-arm64-YYYYMMDD/
  dist/eyecandy-arm64-YYYYMMDD.zip

The package directory is recreated on each run so Finder-style numbered copies
such as "package 2" are never used.
USAGE
}

DATE_STAMP="$(date +%Y%m%d)"
SKIP_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --date)
      if [[ $# -lt 2 ]]; then
        echo "error: --date requires YYYYMMDD" >&2
        exit 2
      fi
      DATE_STAMP="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! "$DATE_STAMP" =~ ^[0-9]{8}$ ]]; then
  echo "error: date must be YYYYMMDD, got: $DATE_STAMP" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_CONFIG="release"
ARCH="arm64"
PRODUCT="eyecandy"
APP_NAME="sonic-screwdriver-eyecandy.app"
PACKAGE_NAME="eyecandy-arm64-$DATE_STAMP"
PACKAGE_DIR="$DIST_DIR/$PACKAGE_NAME"
ZIP_PATH="$DIST_DIR/$PACKAGE_NAME.zip"
BINARY_PATH="$ROOT_DIR/.build/$ARCH-apple-macosx/$BUILD_CONFIG/$PRODUCT"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/clang-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  swift build \
    --package-path "$ROOT_DIR" \
    --disable-sandbox \
    -c "$BUILD_CONFIG" \
    --arch "$ARCH" \
    --product "$PRODUCT"
fi

if [[ ! -x "$BINARY_PATH" ]]; then
  echo "error: release binary not found at $BINARY_PATH" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"

# Remove stale duplicate package folders created by Finder copy operations or
# previous manual packaging. Dated historical packages are left intact.
find "$DIST_DIR" -maxdepth 1 -type d \( \
  -name 'eyecandy-arm64-package [0-9]*' -o \
  -name 'eyecandy-arm64-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] [0-9]*' \
\) -exec rm -rf {} +

rm -rf "$PACKAGE_DIR"
rm -f "$ZIP_PATH"

mkdir -p \
  "$PACKAGE_DIR/$APP_NAME/Contents/MacOS" \
  "$PACKAGE_DIR/docs"

cp "$ROOT_DIR/Packaging/Info.plist" "$PACKAGE_DIR/$APP_NAME/Contents/Info.plist"
cp "$BINARY_PATH" "$PACKAGE_DIR/$APP_NAME/Contents/MacOS/$PRODUCT"
cp "$ROOT_DIR/README.md" "$PACKAGE_DIR/docs/README.md"
cp "$ROOT_DIR/USER_MANUAL.md" "$PACKAGE_DIR/docs/USER_MANUAL.md"

chmod 755 "$PACKAGE_DIR/$APP_NAME/Contents/MacOS/$PRODUCT"

cmp -s "$ROOT_DIR/README.md" "$PACKAGE_DIR/docs/README.md"
cmp -s "$ROOT_DIR/USER_MANUAL.md" "$PACKAGE_DIR/docs/USER_MANUAL.md"

codesign --force --deep --sign - "$PACKAGE_DIR/$APP_NAME"

(
  cd "$DIST_DIR"
  zip -qry -X "$ZIP_PATH" "$PACKAGE_NAME"
)

echo "Packaged $PACKAGE_DIR"
echo "Created $ZIP_PATH"
