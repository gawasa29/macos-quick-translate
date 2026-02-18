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
            let translator = CachedTranslator(base: AppleTranslationTranslator())
            let request = TranslationRequest(text: text, targetLanguage: targetLanguage)

            let translated = try await translator.translate(request)
            print(translated)
        } catch let error as TranslatorError {
            fputs("error: \(error.localizedDescription)\n", stderr)
            if case .translationModelNotInstalled = error {
                fputs("hint: open \"x-apple.systempreferences:com.apple.Localization-Settings.extension\"\n", stderr)
            }
            exit(1)
        } catch {
            fputs("error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
