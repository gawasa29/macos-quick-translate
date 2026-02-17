# macos-quick-translate

macOS向けの高速翻訳アプリ（Swift Package Manager構成）です。
`⌘ + C` を短時間に2回押す（`CMD+c+c`）と、選択中テキストを翻訳し、翻訳結果をクリップボードへ上書きします。

## 目的
- DeepLのような「選択して即翻訳」体験を、最小構成で実装する。
- まずCLIで翻訳コアを検証し、その後UI（メニューバー常駐）から利用する。

## セットアップ
1. macOS 13+ を用意
2. DeepL APIキーを環境変数に設定

```bash
export DEEPL_API_KEY="<your-key>"
```

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

## テスト
```bash
cd macos-quick-translate
swift test
```

## リリース
- まず `swift test` と `swift run quick-translate-cli` による疎通を確認する。
- その後 `swift run quick-translate-macos` で `CMD+c+c` の体験を手動検証する。
