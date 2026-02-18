#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/create-app-bundle.sh [options]

Options:
  --output-dir <path>       Output directory for Quick Translate.app (default: ./out)
  --configuration <name>    Swift build configuration: debug or release (default: release)
  --version <semver>        CFBundleShortVersionString (default: 0.1.0)
  --build-number <number>   CFBundleVersion (default: 1)
  -h, --help                Show this help
USAGE
}

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/out"
CONFIGURATION="release"
VERSION="0.1.0"
BUILD_NUMBER="1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --build-number)
      BUILD_NUMBER="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
  echo "--configuration must be debug or release" >&2
  exit 1
fi

APP_NAME="Quick Translate.app"
APP_DIR="$OUTPUT_DIR/$APP_NAME"
EXECUTABLE_NAME="quick-translate-macos"
BUNDLE_ID="dev.gawasa.quick-translate-macos"

cd "$PROJECT_DIR"
swift build -c "$CONFIGURATION" --product "$EXECUTABLE_NAME"

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
BINARY_PATH="$BIN_DIR/$EXECUTABLE_NAME"

if [[ ! -x "$BINARY_PATH" ]]; then
  echo "Executable not found: $BINARY_PATH" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>Quick Translate</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Quick Translate</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>26.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

cp "$BINARY_PATH" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
chmod 755 "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"

echo "Created app bundle: $APP_DIR"
