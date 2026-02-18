import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

public struct TargetLanguageResolver {
    private let detectLanguageIdentifier: (String) -> String?

    public init() {
        self.detectLanguageIdentifier = Self.defaultLanguageDetector
    }

    init(detectLanguageIdentifier: @escaping (String) -> String?) {
        self.detectLanguageIdentifier = detectLanguageIdentifier
    }

    public func resolveTargetLanguage(
        sourceText: String,
        preferredTargetLanguage: String
    ) -> String {
        let sourceIdentifier = detectLanguageIdentifier(sourceText)?.lowercased()
        let preferredPrimary = Self.primaryLanguageCode(from: preferredTargetLanguage)

        switch (sourceIdentifier, preferredPrimary) {
        case ("en", "en"):
            return "JA-JP"
        case ("ja", "ja"):
            return "EN-US"
        default:
            return preferredTargetLanguage
        }
    }

    private static func primaryLanguageCode(from identifier: String) -> String {
        identifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
            .first?
            .lowercased() ?? ""
    }

    private static func defaultLanguageDetector(_ text: String) -> String? {
        #if canImport(NaturalLanguage)
        NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue
        #else
        nil
        #endif
    }
}
