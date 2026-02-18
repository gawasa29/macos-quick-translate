# Quick Translate (macOS)

選択テキストを `CMD+C+C` で即翻訳する、メニューバー常駐アプリです。

## インストール（推奨）
Homebrew Cask からのインストールが推奨です。

```bash
brew tap gawasa29/tap https://github.com/gawasa29/homebrew-tap
brew install --cask gawasa29/tap/quick-translate
```

## 初回セットアップ
1. アプリを起動
2. アクセシビリティ権限を許可
3. 翻訳モデルが未導入なら、システム設定 `一般 > 言語と地域 > 翻訳言語` でダウンロード

## 使い方
1. 翻訳したいテキストを選択
2. `CMD + C` を短時間に2回押す（`CMD+C+C`）
3. 翻訳結果がHUDで表示される

## メニューでできること
- `CMD+C+C を一時停止 / 再開`
- `ログイン時に起動`
- `翻訳先言語` の切替
- `翻訳設定を開く`

## アップデート / アンインストール
```bash
brew upgrade --cask gawasa29/tap/quick-translate
brew uninstall --cask gawasa29/tap/quick-translate
```

## よくある問題
- `Unable to Translate` が出る:
  - 翻訳モデル未導入の可能性があります。`翻訳言語` の設定を確認してください。
- HUDが表示されない:
  - アクセシビリティ権限を確認してください。

## 開発者向け（最小）
```bash
swift test
swift run quick-translate-macos
```
