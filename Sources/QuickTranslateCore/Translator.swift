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
    case missingAPIKey
    case invalidResponse
    case server(status: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "DEEPL_API_KEY が設定されていません。"
        case .invalidResponse:
            return "翻訳APIのレスポンスが不正です。"
        case let .server(status, message):
            return "翻訳APIエラー status=\(status): \(message)"
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
