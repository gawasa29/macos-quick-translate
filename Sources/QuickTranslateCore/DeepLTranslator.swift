import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct DeepLTranslator: Translator {
    private let apiKey: String
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public static func fromEnvironment(session: URLSession = .shared) throws -> DeepLTranslator {
        guard let key = ProcessInfo.processInfo.environment["DEEPL_API_KEY"], !key.isEmpty else {
            throw TranslatorError.missingAPIKey
        }

        return DeepLTranslator(apiKey: key, session: session)
    }

    public func translate(_ request: TranslationRequest) async throws -> String {
        var urlRequest = URLRequest(url: URL(string: "https://api-free.deepl.com/v2/translate")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = DeepLRequest(
            text: [request.text],
            sourceLang: request.sourceLanguage,
            targetLang: request.targetLanguage
        )
        urlRequest.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslatorError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "unknown"
            throw TranslatorError.server(status: httpResponse.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(DeepLResponse.self, from: data)
        guard let first = decoded.translations.first else {
            throw TranslatorError.invalidResponse
        }

        return first.text
    }
}

private struct DeepLRequest: Codable {
    let text: [String]
    let sourceLang: String?
    let targetLang: String

    enum CodingKeys: String, CodingKey {
        case text
        case sourceLang = "source_lang"
        case targetLang = "target_lang"
    }
}

private struct DeepLResponse: Codable {
    let translations: [DeepLTranslation]
}

private struct DeepLTranslation: Codable {
    let text: String
}
