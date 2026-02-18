import Foundation
import Testing
@testable import QuickTranslateCore

@Test("言語コードをBCP-47風に正規化できる")
func normalizesLanguageCode() throws {
    #expect(try AppleTranslationTranslator.normalizedLanguageIdentifier(from: "JA") == "ja")
    #expect(try AppleTranslationTranslator.normalizedLanguageIdentifier(from: "en_US") == "en-US")
    #expect(try AppleTranslationTranslator.normalizedLanguageIdentifier(from: "ZH-hant") == "zh-hant")
}

@Test("空の言語コードはエラーになる")
func rejectsEmptyLanguageCode() {
    #expect(throws: TranslatorError.self) {
        _ = try AppleTranslationTranslator.normalizedLanguageIdentifier(from: "   ")
    }
}
