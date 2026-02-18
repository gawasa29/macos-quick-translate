import Foundation
import Testing
@testable import QuickTranslateCore

@Test("英語原文でターゲットが英語なら日本語に切り替える")
func switchesEnglishToJapaneseWhenTargetIsEnglish() {
    let resolver = TargetLanguageResolver { _ in "en" }
    let resolved = resolver.resolveTargetLanguage(
        sourceText: "Hello world",
        preferredTargetLanguage: "EN-US"
    )

    #expect(resolved == "JA-JP")
}

@Test("日本語原文でターゲットが日本語なら英語に切り替える")
func switchesJapaneseToEnglishWhenTargetIsJapanese() {
    let resolver = TargetLanguageResolver { _ in "ja" }
    let resolved = resolver.resolveTargetLanguage(
        sourceText: "こんにちは",
        preferredTargetLanguage: "JA-JP"
    )

    #expect(resolved == "EN-US")
}

@Test("原文がターゲットと異なる言語なら設定値を維持する")
func keepsPreferredTargetLanguageWhenSourceDiffers() {
    let resolver = TargetLanguageResolver { _ in "ja" }
    let resolved = resolver.resolveTargetLanguage(
        sourceText: "こんにちは",
        preferredTargetLanguage: "EN-GB"
    )

    #expect(resolved == "EN-GB")
}

@Test("言語判定できないときは設定値を維持する")
func keepsPreferredTargetLanguageWhenLanguageUndetermined() {
    let resolver = TargetLanguageResolver { _ in nil }
    let resolved = resolver.resolveTargetLanguage(
        sourceText: "12345",
        preferredTargetLanguage: "EN-US"
    )

    #expect(resolved == "EN-US")
}
