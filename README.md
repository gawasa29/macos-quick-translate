# Quick Translate for macOS ⚡ - Translate selected text with CMD+C+C
[English](README.md) | [日本語](README.ja.md)

Quick Translate is a menu bar app for people who switch between Japanese and English throughout the day. It translates your current selection when you press `CMD+C` twice quickly, then shows the result in a lightweight HUD near your cursor. The app uses Apple Translation APIs and targets `macOS 26+`.

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
3. Choose your destination language from `Target Language` in the menu.
4. If translation fails, install required language models in `System Settings > General > Language & Region > Translation Languages`.
5. Select text in any app and press `CMD+C` twice quickly.
6. Confirm the translated text appears in the HUD.

```bash
./scripts/install.sh --help
```

## Features

- Menu bar workflow with no Dock app window.
- `CMD+C+C` trigger with both global key monitoring and pasteboard fallback detection.
- Target language picker built from Apple Translation supported languages.
- Translation result shown in an on-screen HUD without overwriting clipboard content.
- Optional `Launch at Login` toggle backed by a user LaunchAgent.
- CLI (`quick-translate-cli`) to validate the translation core before UI changes.

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

- Build and test:
```bash
swift build
swift test
```

- Validate translation core with CLI:
```bash
swift run quick-translate-cli "Hello" JA
```

- Run the menu bar app:
```bash
swift run quick-translate-macos
```

## Build from source

```bash
./scripts/create-app-bundle.sh --output-dir out
./scripts/install.sh --open
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
