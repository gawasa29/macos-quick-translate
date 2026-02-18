# AGENTS.md (macos-quick-translate)

## このディレクトリ配下の方針
- 実装言語は `Swift` を使用する。
- `Package.swift` ベースで管理し、`.xcodeproj` は作成しない。
- UI変更前に、`quick-translate-cli` でコア翻訳ロジックの確認を行う。
- 翻訳は macOS の `Translation` API を利用する（`macOS 26+`）。
- DeepL API は使用しない（`DEEPL_API_KEY` 不要）。

## 実行コマンド
- ビルド: `swift build`
- テスト: `swift test`
- CLI: `swift run quick-translate-cli "Hello" JA`
- App: `swift run quick-translate-macos`

## 現在のUI仕様
- メニューバー常駐アプリとして動作し、アイコンからメニューを開く。
- ショートカットは `CMD+C+C`（短時間の2回コピー）で翻訳を実行する。
- メニューから `Pause/Resume CMD+C+C` でショートカットをON/OFFできる。
- メニューから `Launch at Login` でログイン時起動をON/OFFできる（`LaunchAgents` を使用）。
- メニューから翻訳先言語を切り替えできる（`JA-JP` / `EN-US` / `EN-GB`）。
- メニューから `Open Translation Settings` でシステムの言語設定を開ける。
- 翻訳結果はクリップボードに上書きせず、右上に軽量HUDとして短時間表示する。

## エラーハンドリング方針
- 翻訳モデル未インストール時は `translationModelNotInstalled` を返し、設定画面への導線を出す。
- 遷移先URLは `x-apple.systempreferences:com.apple.Localization-Settings.extension` を使用する。
- CLI でも未インストール時は上記URLの `open` ヒントを表示する。
