# macos-quick-translate

macOS向けの高速翻訳アプリ（Swift Package Manager構成）です。
`⌘ + C` を短時間に2回押す（`CMD+C+C`）と、選択中テキストを翻訳し、翻訳結果を軽量HUDで表示します。

## 概要
- macOS標準の `Translation` API を使って、選択テキストを即時翻訳します。
- 外部翻訳API（DeepLなど）は使いません。
- コア機能はCLIで検証し、UIはメニューバー常駐アプリとして提供します。

## 対応環境
- macOS `26.0` 以降（Translation API実行要件）
- Swift `5.10+`
- 権限: アクセシビリティ（グローバルキー監視のため）

## セットアップ
1. このディレクトリへ移動します。
```bash
cd macos-quick-translate
```
2. ビルドします。
```bash
swift build
```
3. 必要に応じて翻訳モデルをインストールします。
システム設定の `一般 > 言語と地域 > 翻訳言語` から対象言語をダウンロードしてください。

## 使い方
### 1) CLI（コアロジック検証）
```bash
swift run quick-translate-cli "Hello world" JA
```

### 2) macOSアプリ（メニューバー常駐）
```bash
swift run quick-translate-macos
```

起動後、アクセシビリティ権限を許可してください。
メニューでは以下を操作できます。
- `CMD+C+C を一時停止` / `CMD+C+C を再開`
- `ログイン時に起動`
- `翻訳先言語`（`日本語 (JA)` / `英語 (US)` / `英語 (UK)`）
- `翻訳設定を開く`
- `終了`

翻訳結果はクリップボードを上書きせず、非モーダルHUDで表示されます。

## 設定項目
- `ログイン時に起動` をONにすると `~/Library/LaunchAgents/dev.gawasa.quick-translate-macos.plist` を作成します。
- OFFにすると同ファイルを削除します。

## トラブルシュート
- `Unable to Translate` / 翻訳失敗
  - 翻訳モデル未インストールの可能性があります。`一般 > 言語と地域 > 翻訳言語` を確認してください。
- `Translation API の利用には macOS 26.0 以降が必要`
  - OSバージョンを満たしていません。
- HUDが表示されない
  - アクセシビリティ権限が許可されているか確認してください。
- 設定画面を直接開く
```bash
open "x-apple.systempreferences:com.apple.Localization-Settings.extension?translation"
```

## テスト方法
```bash
swift test
```

## リリース手順
1. `swift test` を実行して全テストが通ることを確認
2. `swift run quick-translate-cli "Hello" JA` でCLI疎通確認
3. `swift run quick-translate-macos` で手動確認
4. `CMD+C+C` 翻訳、言語切替、`ログイン時に起動` の動作確認
5. `README.md` / `AGENTS.md` の差分確認後にコミット・タグ付け

## 既知の制限
- Translation API と翻訳モデルの状態に依存します。
- 言語自動判定は短文や記号中心テキストで失敗する場合があります。
- HUD表示時間は固定上限があり、非常に長い翻訳では読み切りにくい場合があります。

## プライバシー
- 本アプリは外部のサードパーティ翻訳APIへ直接送信しません。
- 翻訳処理は macOS の `Translation` フレームワークに委譲されます。
- 翻訳結果はHUD表示のみで、クリップボードは上書きしません。

## ライセンス
ライセンスは未設定です。公開配布前に明記してください。
