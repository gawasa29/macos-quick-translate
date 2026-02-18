#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/render-homebrew-cask.sh [options]

Required:
  --version <value>         Cask version (e.g. 0.1.0)
  --sha256 <value>          SHA256 of release zip
  --url <value>             Download URL of release zip

Optional:
  --output <path>           Output file path (default: stdout)
  --token <value>           Cask token (default: quick-translate)
  --name <value>            App name (default: Quick Translate)
  --homepage <value>        Homepage URL (default: project repository)
  -h, --help                Show this help
USAGE
}

VERSION=""
SHA256=""
URL=""
OUTPUT=""
TOKEN="quick-translate"
APP_NAME="Quick Translate"
HOMEPAGE="https://github.com/gawasa29/Projects/tree/main/macos-quick-translate"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --sha256)
      SHA256="$2"
      shift 2
      ;;
    --url)
      URL="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --token)
      TOKEN="$2"
      shift 2
      ;;
    --name)
      APP_NAME="$2"
      shift 2
      ;;
    --homepage)
      HOMEPAGE="$2"
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

if [[ -z "$VERSION" || -z "$SHA256" || -z "$URL" ]]; then
  echo "--version, --sha256, and --url are required" >&2
  usage
  exit 1
fi

render() {
  cat <<RUBY
cask "$TOKEN" do
  version "$VERSION"
  sha256 "$SHA256"

  url "$URL"
  name "$APP_NAME"
  desc "Quick translator in the macOS menu bar"
  homepage "$HOMEPAGE"

  auto_updates false

  app "Quick Translate.app"

  caveats <<~EOS
    If macOS says this app is damaged, remove quarantine and reopen:
      xattr -dr com.apple.quarantine "/Applications/Quick Translate.app"
      open "/Applications/Quick Translate.app"
  EOS

  uninstall quit: "dev.gawasa.quick-translate-macos",
            delete: "~/Library/LaunchAgents/dev.gawasa.quick-translate-macos.plist"

  zap trash: [
    "~/Library/Preferences/dev.gawasa.quick-translate-macos.plist"
  ]
end
RUBY
}

if [[ -n "$OUTPUT" ]]; then
  mkdir -p "$(dirname "$OUTPUT")"
  render > "$OUTPUT"
  echo "Generated cask: $OUTPUT"
else
  render
fi
