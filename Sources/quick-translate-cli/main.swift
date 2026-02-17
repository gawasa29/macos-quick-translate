import Foundation
import QuickTranslateCore

@main
struct QuickTranslateCLI {
    static func main() async {
        do {
            guard CommandLine.arguments.count >= 2 else {
                fputs("usage: quick-translate-cli <text> [target_lang=en]\n", stderr)
                exit(1)
            }

            let text = CommandLine.arguments[1]
            let targetLanguage = CommandLine.arguments.count >= 3 ? CommandLine.arguments[2] : "EN"
            let translator = try CachedTranslator(base: DeepLTranslator.fromEnvironment())
            let request = TranslationRequest(text: text, targetLanguage: targetLanguage)

            let translated = try await translator.translate(request)
            print(translated)
        } catch {
            fputs("error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
