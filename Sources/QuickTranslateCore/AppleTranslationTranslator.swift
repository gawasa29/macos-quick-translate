import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif
#if canImport(Translation)
import Translation
#endif

public struct AppleTranslationTranslator: Translator {
    public init() {}

    public func translate(_ request: TranslationRequest) async throws -> String {
        let sourceText = request.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sourceText.isEmpty else {
            throw TranslatorError.emptyText
        }

        #if canImport(Translation)
        guard #available(macOS 26.0, *) else {
            throw TranslatorError.translationAPIRequiresNewerOS(minimumVersion: "macOS 26.0")
        }

        let sourceLanguage = try resolveSourceLanguage(for: request, sourceText: sourceText)
        let targetLanguage = try localeLanguage(from: request.targetLanguage)
        let session = TranslationSession(installedSource: sourceLanguage, target: targetLanguage)

        do {
            let response = try await session.translate(sourceText)
            return response.targetText
        } catch {
            if TranslationError.notInstalled ~= error {
                throw TranslatorError.translationModelNotInstalled
            }
            throw TranslatorError.translationFailed(error.localizedDescription)
        }
        #else
        throw TranslatorError.translationFrameworkUnavailable
        #endif
    }

    static func normalizedLanguageIdentifier(from rawCode: String) throws -> String {
        let trimmed = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TranslatorError.invalidLanguageCode(rawCode)
        }

        let canonical = trimmed.replacingOccurrences(of: "_", with: "-")
        let components = canonical.split(separator: "-", omittingEmptySubsequences: false)
        guard !components.isEmpty else {
            throw TranslatorError.invalidLanguageCode(rawCode)
        }

        var normalized: [String] = []
        normalized.reserveCapacity(components.count)

        for (index, component) in components.enumerated() {
            let segment = String(component)
            guard !segment.isEmpty else {
                throw TranslatorError.invalidLanguageCode(rawCode)
            }

            if index == 0 {
                normalized.append(segment.lowercased())
                continue
            }

            if segment.count == 2 || segment.count == 3 {
                normalized.append(segment.uppercased())
            } else {
                normalized.append(segment.lowercased())
            }
        }

        return normalized.joined(separator: "-")
    }

    private func resolveSourceLanguage(for request: TranslationRequest, sourceText: String) throws -> Locale.Language {
        if let sourceLanguage = request.sourceLanguage,
           !sourceLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return try localeLanguage(from: sourceLanguage)
        }

        #if canImport(NaturalLanguage)
        guard let detectedLanguage = NLLanguageRecognizer.dominantLanguage(for: sourceText) else {
            throw TranslatorError.unableToDetectSourceLanguage
        }
        return Locale.Language(identifier: detectedLanguage.rawValue)
        #else
        throw TranslatorError.unableToDetectSourceLanguage
        #endif
    }

    private func localeLanguage(from rawCode: String) throws -> Locale.Language {
        Locale.Language(identifier: try Self.normalizedLanguageIdentifier(from: rawCode))
    }
}
