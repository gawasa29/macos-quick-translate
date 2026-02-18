# macos-quick-translate

macOS向けの高速翻訳アプリ（Swift Package Manager構成）です。
`⌘ + C` を短時間に2回押す（`CMD+c+c`）と、選択中テキストを翻訳し、翻訳結果を軽量HUDで表示します。

## 目的
- macOS標準の `Translation` API で「選択して即翻訳」体験を、最小構成で実装する。
- まずCLIで翻訳コアを検証し、その後UI（メニューバー常駐）から利用する。

## セットアップ
1. macOS 26+ を用意
2. 必要な言語モデルが未インストールの場合は、システムの翻訳機能で事前にダウンロードする

## 実行方法
### 1) CLI（コアロジック検証）
```bash
cd macos-quick-translate
swift run quick-translate-cli "Hello world" JA
```

### 2) macOSアプリ（メニューバー常駐）
```bash
cd macos-quick-translate
swift run quick-translate-macos
```

起動後にアクセシビリティ権限（キーボード監視/イベント送出）を許可してください。
メニューバーから以下を操作できます。
- `Pause/Resume CMD+C+C`（ショートカット有効化/停止）
- `Launch at Login`（ログイン時に自動起動）
- `Target Language`（翻訳先言語切り替え）
- `Open Translation Settings`（言語モデル設定画面へ遷移）
- 翻訳結果はメニューバー右上に非モーダルHUDとして短時間表示されます（クリップボードは上書きしません）
翻訳モデル未インストール時は、アプリ内ダイアログから「言語と地域」設定へ遷移できます。

`Launch at Login` は `~/Library/LaunchAgents/dev.gawasa.quick-translate-macos.plist` を作成/削除して設定します。

## テスト
```bash
cd macos-quick-translate
swift test
```

## リリース
- まず `swift test` と `swift run quick-translate-cli` による疎通を確認する。
- その後 `swift run quick-translate-macos` で `CMD+c+c` の体験を手動検証する。
