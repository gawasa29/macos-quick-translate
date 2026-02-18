#if canImport(AppKit)
import AppKit
import Foundation
import QuickTranslateCore

final class QuickTranslateApp: NSObject, NSApplicationDelegate {
    private enum DefaultsKey {
        static let targetLanguage = "quickTranslate.targetLanguage"
        static let shortcutEnabled = "quickTranslate.shortcutEnabled"
    }

    private struct TargetLanguageOption {
        let code: String
        let title: String
    }

    private let languageOptions: [TargetLanguageOption] = [
        .init(code: "JA-JP", title: "Japanese (JA)"),
        .init(code: "EN-US", title: "English (US)"),
        .init(code: "EN-GB", title: "English (UK)")
    ]
    private let activeStatusTitle = "QT"
    private let pausedStatusTitle = "QT||"

    private var statusItem: NSStatusItem?
    private var monitor: Any?
    private var detector = CommandCCDetector()
    private let pasteboard = NSPasteboard.general
    private let translator: any Translator
    private var isShortcutEnabled: Bool
    private var targetLanguage: String
    private var shortcutToggleItem: NSMenuItem?
    private var languageMenuItems: [NSMenuItem] = []

    override init() {
        self.translator = CachedTranslator(base: AppleTranslationTranslator())
        self.targetLanguage = UserDefaults.standard.string(forKey: DefaultsKey.targetLanguage) ?? "JA-JP"
        self.isShortcutEnabled = UserDefaults.standard.object(forKey: DefaultsKey.shortcutEnabled) as? Bool ?? true
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
        updateStatusItemAppearance()

        let menu = NSMenu()

        let appTitle = NSMenuItem(title: "Quick Translate", action: nil, keyEquivalent: "")
        appTitle.isEnabled = false
        menu.addItem(appTitle)

        let toggleItem = NSMenuItem(title: "", action: #selector(toggleShortcut), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        shortcutToggleItem = toggleItem

        let languageRoot = NSMenuItem(title: "Target Language", action: nil, keyEquivalent: "")
        let languageSubmenu = NSMenu()
        languageMenuItems = languageOptions.map { option in
            let item = NSMenuItem(title: option.title, action: #selector(selectTargetLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = option.code
            languageSubmenu.addItem(item)
            return item
        }
        menu.setSubmenu(languageSubmenu, for: languageRoot)
        menu.addItem(languageRoot)

        menu.addItem(.separator())

        let openSettings = NSMenuItem(title: "Open Translation Settings", action: #selector(openTranslationSettingsFromMenu), keyEquivalent: "")
        openSettings.target = self
        menu.addItem(openSettings)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu

        updateShortcutMenuState()
        updateLanguageMenuState()
    }

    private func setupShortcutMonitor() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            guard self.isShortcutEnabled else { return }
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

        let request = TranslationRequest(text: sourceText, targetLanguage: targetLanguage)
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
            handleTranslationError(error)
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

    @objc private func toggleShortcut() {
        isShortcutEnabled.toggle()
        UserDefaults.standard.set(isShortcutEnabled, forKey: DefaultsKey.shortcutEnabled)
        updateShortcutMenuState()
    }

    @objc private func selectTargetLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        targetLanguage = code
        UserDefaults.standard.set(code, forKey: DefaultsKey.targetLanguage)
        updateLanguageMenuState()
    }

    @objc private func openTranslationSettingsFromMenu() {
        openTranslationSettings()
    }

    private func updateShortcutMenuState() {
        shortcutToggleItem?.title = isShortcutEnabled ? "Pause CMD+C+C" : "Resume CMD+C+C"
        updateStatusItemAppearance()
    }

    private func updateLanguageMenuState() {
        for item in languageMenuItems {
            guard let code = item.representedObject as? String else {
                item.state = .off
                continue
            }
            item.state = (code == targetLanguage) ? .on : .off
        }
    }

    private func updateStatusItemAppearance() {
        guard let button = statusItem?.button else { return }

        let symbolName = isShortcutEnabled ? "character.bubble" : "pause.circle"
        if let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Quick Translate") {
            symbol.isTemplate = true
            button.image = symbol
            button.title = ""
        } else {
            button.image = nil
            button.title = isShortcutEnabled ? activeStatusTitle : pausedStatusTitle
        }

        button.toolTip = "Quick Translate"
    }

    private func handleTranslationError(_ error: Error) {
        if let translatorError = error as? TranslatorError,
           case .translationModelNotInstalled = translatorError {
            showInstallGuide()
            return
        }

        showToast("翻訳に失敗: \(error.localizedDescription)")
    }

    private func showInstallGuide() {
        let alert = NSAlert()
        alert.messageText = "翻訳モデルが見つかりません"
        alert.informativeText = "「一般 > 言語と地域 > 翻訳言語」で言語をダウンロードしてください。設定画面を開きますか？"
        alert.addButton(withTitle: "設定を開く")
        alert.addButton(withTitle: "閉じる")

        if alert.runModal() == .alertFirstButtonReturn {
            openTranslationSettings()
        }
    }

    private func openTranslationSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.Localization-Settings.extension?translation",
            "x-apple.systempreferences:com.apple.Localization-Settings.extension"
        ]

        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            if NSWorkspace.shared.open(url) {
                return
            }
        }

        showToast("システム設定を開けませんでした。手動で「一般 > 言語と地域」を開いてください。")
    }

    private func showToast(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}

@main
enum QuickTranslateMain {
    private static var appDelegate: QuickTranslateApp?

    static func main() {
        let app = NSApplication.shared
        let delegate = QuickTranslateApp()
        appDelegate = delegate
        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        app.run()
    }
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
