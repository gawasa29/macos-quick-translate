# AGENTS.md (macos-quick-translate)

## このディレクトリ配下の方針
- 実装言語は `Swift` を使用する。
- `Package.swift` ベースで管理し、`.xcodeproj` は作成しない。
- UI変更前に、`quick-translate-cli` でコア翻訳ロジックの確認を行う。

## 実行コマンド
- ビルド: `swift build`
- テスト: `swift test`
- CLI: `swift run quick-translate-cli "Hello" JA`
- App: `swift run quick-translate-macos`
