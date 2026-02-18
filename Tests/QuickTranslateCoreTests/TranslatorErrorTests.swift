import Foundation
import Testing
@testable import QuickTranslateCore

@Test("翻訳モデル未インストール時の案内文")
func translationModelNotInstalledDescription() {
    let description = TranslatorError.translationModelNotInstalled.errorDescription ?? ""

    #expect(description.contains("翻訳モデル"))
    #expect(description.contains("システム設定"))
    #expect(description.contains("x-apple.systempreferences:com.apple.Localization-Settings.extension"))
}
