# Quick Translate for macOS ⚡ - Instant HUD translation with CMD+C+C
[English](README.md) | [日本語](README.ja.md)

Quick Translate is a menu bar app for people who switch languages throughout the day. It is designed as a practical alternative when DeepL's `CMD+C+C` flow feels slow to launch. It supports multiple target languages available in Apple Translation. Press `CMD+C` twice quickly to translate your current selection, then get the result in a lightweight HUD near your cursor. The app uses Apple Translation APIs and targets `macOS 26+`.

![Quick Translate HUD preview](assets/readme-preview.png)

## Install

### Requirements
- macOS 26.0 or later.
- Apple translation models installed in `System Settings > General > Language & Region > Translation Languages`.
- Accessibility permission enabled to detect the global shortcut.

### Package manager
```bash
brew install gawasa29/tap/quick-translate
```

### Build from source
```bash
git clone https://github.com/gawasa29/macos-quick-translate.git
cd macos-quick-translate
./scripts/install.sh --open
```

## Quick Start

1. Install the app and launch `Quick Translate`.
2. Allow Accessibility permission when prompted.
3. Pick your destination language from `Target Language` in the menu.
4. Select text in any app and press `CMD+C` twice quickly.
5. Confirm the translated text appears in the HUD.
6. If translation fails, open `Open Translation Settings` from the menu and install required models.

```bash
./scripts/install.sh --help
```

## Features

- Menu bar workflow with no Dock app window.
- Positioned as a practical replacement when DeepL `CMD+C+C` startup feels slow.
- `CMD+C+C` trigger using both global key monitoring and pasteboard fallback detection.
- Target language picker built from Apple Translation supported languages.
- Supports multiple target languages available in Apple Translation.
- Translation result shown in an on-screen HUD without overwriting clipboard content.
- Optional `Launch at Login` toggle backed by a user LaunchAgent.
- CLI (`quick-translate-cli`) to validate translation core behavior before UI changes.

## Docs

- [Project policy and run commands](AGENTS.md)
- [Menu bar app entry point](Sources/quick-translate-macos/main.swift)
- [CLI entry point](Sources/quick-translate-cli/main.swift)
- [Core translation contracts](Sources/QuickTranslateCore/Translator.swift)
- [Packaging scripts](scripts/)

## Privacy / Permissions / Limitations

### Privacy
- This project does not use DeepL and does not require `DEEPL_API_KEY`.
- Translation history is not persisted by the app.
- Clipboard text is read only when you trigger `CMD+C+C`.

### Permissions
- Accessibility permission is required for global shortcut detection.
- Launch at Login creates `~/Library/LaunchAgents/dev.gawasa.quick-translate-macos.plist`.

### Limitations
- Translation requires `macOS 26+` and installed Apple translation models.
- The shortcut is fixed to `CMD+C+C`.
- Available target languages depend on Apple Translation framework support.

## Getting started (dev)

```bash
swift build
swift test
swift run quick-translate-cli "Hello" JA
swift run quick-translate-macos
```

## Build app bundle

```bash
./scripts/create-app-bundle.sh --output-dir out
./scripts/install.sh --open
```

## Uninstall

```bash
brew uninstall quick-translate
./scripts/uninstall.sh
```

## Release

```bash
./scripts/create-app-bundle.sh --configuration release --output-dir out --version <version> --build-number <build-number>
./scripts/render-homebrew-cask.sh --version <version> --sha256 <sha256> --url <asset-url>
```

For public distribution, sign with Developer ID and notarize the release artifact.

## Related

- [Homebrew Tap (`gawasa29/tap`)](https://github.com/gawasa29/homebrew-tap) - Distribution channel for the cask.

## License

MIT License. See [`LICENSE`](LICENSE).
