import Foundation
import Testing
@testable import QuickTranslateCore

@Test("同一リクエストはキャッシュされる")
func cachesTranslation() async throws {
    let stub = CounterTranslator()
    let translator = CachedTranslator(base: stub)
    let request = TranslationRequest(text: "hello", targetLanguage: "JA")

    let first = try await translator.translate(request)
    let second = try await translator.translate(request)

    #expect(first == "HELLO")
    #expect(second == "HELLO")
    let callCount = await stub.callCount
    #expect(callCount == 1)
}

private actor CounterState {
    var callCount = 0

    func increment() {
        callCount += 1
    }
}

private struct CounterTranslator: Translator {
    let state = CounterState()

    var callCount: Int {
        get async { await state.callCount }
    }

    func translate(_ request: TranslationRequest) async throws -> String {
        await state.increment()
        return request.text.uppercased()
    }
}
