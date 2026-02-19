# Quick Translate (macOS)

選択テキストを `CMD+C+C` で即翻訳する、メニューバー常駐アプリです。

## インストール（推奨）
Homebrew Cask からのインストールが推奨です。`brew tap` の事前実行は不要です。

```bash
brew install --cask gawasa29/tap/quick-translate
```

配布用ビルドは `Developer ID` 署名 + notarization が必要です（未実施だと Gatekeeper でブロックされる場合があります）。

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
- `Quick Translate` が「壊れているため開けません」と表示される:
  - いったん削除して再インストールしたうえで、まだ発生する場合は以下を実行してください（`/Applications` と `~/Applications` の両方に対応）。

```bash
APP_PATH="/Applications/Quick Translate.app"
[[ -d "$HOME/Applications/Quick Translate.app" ]] && APP_PATH="$HOME/Applications/Quick Translate.app"
xattr -dr com.apple.quarantine "$APP_PATH"
open "$APP_PATH"
```

## 開発者向け（最小）
```bash
swift test
swift run quick-translate-macos
```

## ライセンス
MIT License（`LICENSE` を参照）
