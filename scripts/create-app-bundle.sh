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
  --signing-identity <id>   codesign identity (default: -, ad-hoc)
  --no-sign                 Skip codesign
  -h, --help                Show this help
USAGE
}

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/out"
CONFIGURATION="release"
VERSION="0.1.0"
BUILD_NUMBER="1"
SIGNING_IDENTITY="-"
SIGN_APP="true"
APP_ICON_NAME="AppIcon"

generate_app_icon_icns() {
  local output_icns="$1"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  local source_png="$tmp_dir/${APP_ICON_NAME}-1024.png"
  local iconset_dir="$tmp_dir/${APP_ICON_NAME}.iconset"

  swift "$PROJECT_DIR/scripts/render-app-icon.swift" "$source_png"

  mkdir -p "$iconset_dir"
  sips -z 16 16 "$source_png" --out "$iconset_dir/icon_16x16.png" >/dev/null
  sips -z 32 32 "$source_png" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$source_png" --out "$iconset_dir/icon_32x32.png" >/dev/null
  sips -z 64 64 "$source_png" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$source_png" --out "$iconset_dir/icon_128x128.png" >/dev/null
  sips -z 256 256 "$source_png" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$source_png" --out "$iconset_dir/icon_256x256.png" >/dev/null
  sips -z 512 512 "$source_png" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$source_png" --out "$iconset_dir/icon_512x512.png" >/dev/null
  cp "$source_png" "$iconset_dir/icon_512x512@2x.png"

  iconutil -c icns "$iconset_dir" -o "$output_icns"
  rm -rf "$tmp_dir"
}

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
    --signing-identity)
      SIGNING_IDENTITY="$2"
      shift 2
      ;;
    --no-sign)
      SIGN_APP="false"
      shift
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

generate_app_icon_icns "$APP_DIR/Contents/Resources/$APP_ICON_NAME.icns"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>Quick Translate</string>
  <key>CFBundleIconFile</key>
  <string>$APP_ICON_NAME</string>
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

if [[ "$SIGN_APP" == "true" ]]; then
  CODESIGN_ARGS=(--force --deep --sign "$SIGNING_IDENTITY")
  if [[ "$SIGNING_IDENTITY" != "-" ]]; then
    CODESIGN_ARGS+=(--options runtime --timestamp)
  fi

  codesign "${CODESIGN_ARGS[@]}" "$APP_DIR"
  codesign --verify --deep --strict --verbose=2 "$APP_DIR"
fi

echo "Created app bundle: $APP_DIR"
