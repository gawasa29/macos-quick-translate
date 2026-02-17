#if canImport(AppKit)
import AppKit
import Foundation
import QuickTranslateCore

@main
final class QuickTranslateApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var monitor: Any?
    private var detector = CommandCCDetector()
    private let pasteboard = NSPasteboard.general
    private let translator: any Translator

    override init() {
        let base = (try? DeepLTranslator.fromEnvironment())
        self.translator = CachedTranslator(base: base ?? StubTranslator())
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupShortcutMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "🌐"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    private func setupShortcutMonitor() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            let isCommandC = event.keyCode == 8 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command)
            guard isCommandC else { return }

            if self.detector.registerCommandC() {
                Task { await self.translateCurrentSelection() }
            }
        }
    }

    @MainActor
    private func translateCurrentSelection() async {
        let previous = pasteboard.string(forType: .string)
        copyCurrentSelection()
        try? await Task.sleep(nanoseconds: 120_000_000)

        guard let sourceText = pasteboard.string(forType: .string), !sourceText.isEmpty else { return }

        let request = TranslationRequest(text: sourceText, targetLanguage: "JA")
        do {
            let translated = try await translator.translate(request)
            pasteboard.clearContents()
            pasteboard.setString(translated, forType: .string)
            showToast("翻訳結果をクリップボードにコピーしました")
        } catch {
            if let previous {
                pasteboard.clearContents()
                pasteboard.setString(previous, forType: .string)
            }
            showToast("翻訳に失敗: \(error.localizedDescription)")
        }
    }

    private func copyCurrentSelection() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cDown?.flags = .maskCommand
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cUp?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }

    @objc private func quitApp() { NSApp.terminate(nil) }

    private func showToast(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}

private struct StubTranslator: Translator {
    func translate(_ request: TranslationRequest) async throws -> String { "[stub] \(request.text)" }
}
#else
import Foundation

@main
struct UnsupportedPlatformMain {
    static func main() {
        print("quick-translate-macos is only available on macOS.")
    }
}
#endif
