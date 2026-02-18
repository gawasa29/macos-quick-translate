import Foundation

public struct TranslationRequest: Hashable, Sendable {
    public let text: String
    public let sourceLanguage: String?
    public let targetLanguage: String

    public init(text: String, sourceLanguage: String? = nil, targetLanguage: String) {
        self.text = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }
}

public protocol Translator {
    func translate(_ request: TranslationRequest) async throws -> String
}

public enum TranslatorError: LocalizedError {
    case emptyText
    case invalidLanguageCode(String)
    case unableToDetectSourceLanguage
    case translationAPIRequiresNewerOS(minimumVersion: String)
    case translationFrameworkUnavailable
    case translationModelNotInstalled
    case translationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptyText:
            return "翻訳元テキストが空です。"
        case let .invalidLanguageCode(code):
            return "言語コードが不正です: \(code)"
        case .unableToDetectSourceLanguage:
            return "翻訳元言語を判定できませんでした。"
        case let .translationAPIRequiresNewerOS(minimumVersion):
            return "Translation API の利用には \(minimumVersion) 以降が必要です。"
        case .translationFrameworkUnavailable:
            return "Translation.framework を利用できません。"
        case .translationModelNotInstalled:
            return """
            翻訳モデルが未インストールです。システム設定の「一般 > 言語と地域 > 翻訳言語」で必要な言語をダウンロードしてください。
            x-apple.systempreferences:com.apple.Localization-Settings.extension
            """
        case let .translationFailed(message):
            return "翻訳に失敗しました: \(message)"
        }
    }
}

public actor TranslationCache {
    private var store: [TranslationRequest: String] = [:]

    public init() {}

    public func value(for request: TranslationRequest) -> String? {
        store[request]
    }

    public func insert(_ value: String, for request: TranslationRequest) {
        store[request] = value
    }
}

public final class CachedTranslator: Translator {
    private let base: any Translator
    private let cache: TranslationCache

    public init(base: any Translator, cache: TranslationCache = TranslationCache()) {
        self.base = base
        self.cache = cache
    }

    public func translate(_ request: TranslationRequest) async throws -> String {
        if let cached = await cache.value(for: request) {
            return cached
        }

        let translated = try await base.translate(request)
        await cache.insert(translated, for: request)
        return translated
    }
}
