#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/install.sh [options]

Options:
  --install-dir <path>      Install destination for Quick Translate.app (default: ~/Applications)
  --configuration <name>    Swift build configuration: debug or release (default: release)
  --open                    Open the app after install
  -h, --help                Show this help
USAGE
}

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$HOME/Applications"
CONFIGURATION="release"
OPEN_AFTER_INSTALL="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir)
      INSTALL_DIR="$2"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --open)
      OPEN_AFTER_INSTALL="true"
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

mkdir -p "$INSTALL_DIR"

"$PROJECT_DIR/scripts/create-app-bundle.sh" \
  --output-dir "$INSTALL_DIR" \
  --configuration "$CONFIGURATION"

APP_PATH="$INSTALL_DIR/Quick Translate.app"

# Safety: clear quarantine if attributes were inherited from a downloaded workspace.
xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

echo "Installed: $APP_PATH"
echo "Run this app once and grant Accessibility permission if prompted."

if [[ "$OPEN_AFTER_INSTALL" == "true" ]]; then
  open "$APP_PATH"
fi
