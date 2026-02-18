#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${INSTALL_DIR:-$HOME/Applications}/Quick Translate.app"
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/dev.gawasa.quick-translate-macos.plist"

pkill -f quick-translate-macos >/dev/null 2>&1 || true
rm -rf "$APP_PATH"
rm -f "$LAUNCH_AGENT_PATH"

echo "Removed app: $APP_PATH"
echo "Removed launch agent: $LAUNCH_AGENT_PATH"
