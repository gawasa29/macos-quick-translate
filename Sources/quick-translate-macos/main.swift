#if canImport(AppKit)
import AppKit
import Foundation
import QuickTranslateCore

@MainActor
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
        .init(code: "JA-JP", title: "日本語 (JA)"),
        .init(code: "EN-US", title: "英語 (US)"),
        .init(code: "EN-GB", title: "英語 (UK)")
    ]
    private let activeStatusTitle = "QT"
    private let pausedStatusTitle = "QT||"

    private var statusItem: NSStatusItem?
    private var globalKeyMonitor: Any?
    private var pasteboardPollTimer: Timer?
    private var keyboardDetector = CommandCCDetector()
    private var pasteboardDetector = CommandCCDetector()
    private var lastPasteboardChangeCount = NSPasteboard.general.changeCount
    private var lastTranslationTriggerAt: Date?
    private let pasteboard = NSPasteboard.general
    private let translator: any Translator
    private let launchAtLoginManager: any LaunchAtLoginManaging
    private let targetLanguageResolver = TargetLanguageResolver()
    private let translationHUD = TranslationHUDPresenter()
    private var isShortcutEnabled: Bool
    private var isLaunchAtLoginEnabled: Bool
    private var targetLanguage: String
    private var shortcutToggleItem: NSMenuItem?
    private var launchAtLoginItem: NSMenuItem?
    private var languageMenuItems: [NSMenuItem] = []

    override init() {
        let launchAtLoginManager = LaunchAtLoginManager()
        self.translator = CachedTranslator(base: AppleTranslationTranslator())
        self.launchAtLoginManager = launchAtLoginManager
        self.targetLanguage = UserDefaults.standard.string(forKey: DefaultsKey.targetLanguage) ?? "JA-JP"
        self.isShortcutEnabled = UserDefaults.standard.object(forKey: DefaultsKey.shortcutEnabled) as? Bool ?? true
        self.isLaunchAtLoginEnabled = launchAtLoginManager.isEnabled
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupShortcutMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
        }
        pasteboardPollTimer?.invalidate()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemAppearance()

        let menu = NSMenu()

        let appTitle = NSMenuItem(title: "クイック翻訳", action: nil, keyEquivalent: "")
        appTitle.isEnabled = false
        menu.addItem(appTitle)

        let toggleItem = NSMenuItem(title: "", action: #selector(toggleShortcut), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        shortcutToggleItem = toggleItem

        let launchAtLogin = NSMenuItem(title: "ログイン時に起動", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLogin.target = self
        menu.addItem(launchAtLogin)
        launchAtLoginItem = launchAtLogin

        let languageRoot = NSMenuItem(title: "翻訳先言語", action: nil, keyEquivalent: "")
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

        let openSettings = NSMenuItem(title: "翻訳設定を開く", action: #selector(openTranslationSettingsFromMenu), keyEquivalent: "")
        openSettings.target = self
        menu.addItem(openSettings)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "終了", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu

        updateShortcutMenuState()
        updateLaunchAtLoginMenuState()
        updateLanguageMenuState()
    }

    private func setupShortcutMonitor() {
        setupGlobalKeyShortcutMonitor()
        setupPasteboardShortcutFallback()
    }

    private func setupGlobalKeyShortcutMonitor() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            guard self.isShortcutEnabled else { return }
            let isCommandC = event.keyCode == 8 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command)
            guard isCommandC else { return }

            let now = Date()
            if self.keyboardDetector.registerCommandC(at: now) {
                self.triggerTranslation(at: now)
            }
        }
    }

    private func setupPasteboardShortcutFallback() {
        lastPasteboardChangeCount = pasteboard.changeCount
        pasteboardPollTimer?.invalidate()
        pasteboardPollTimer = Timer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(handlePasteboardPoll),
            userInfo: nil,
            repeats: true
        )

        if let pasteboardPollTimer {
            RunLoop.main.add(pasteboardPollTimer, forMode: .common)
        }
    }

    @objc private func handlePasteboardPoll() {
        guard isShortcutEnabled else { return }

        let currentChangeCount = pasteboard.changeCount
        let previousChangeCount = lastPasteboardChangeCount
        guard currentChangeCount != previousChangeCount else { return }

        lastPasteboardChangeCount = currentChangeCount

        let changeDelta = max(1, currentChangeCount - previousChangeCount)
        let now = Date()

        for _ in 0..<changeDelta {
            if pasteboardDetector.registerCommandC(at: now) {
                triggerTranslation(at: now)
                break
            }
        }
    }

    private func triggerTranslation(at now: Date) {
        if let lastTranslationTriggerAt,
           now.timeIntervalSince(lastTranslationTriggerAt) <= 0.35 {
            return
        }

        lastTranslationTriggerAt = now
        Task { await self.translateCurrentSelection() }
    }

    @MainActor
    private func translateCurrentSelection() async {
        try? await Task.sleep(nanoseconds: 120_000_000)

        guard let sourceText = pasteboard.string(forType: .string), !sourceText.isEmpty else { return }

        let resolvedTargetLanguage = targetLanguageResolver.resolveTargetLanguage(
            sourceText: sourceText,
            preferredTargetLanguage: targetLanguage
        )
        let request = TranslationRequest(text: sourceText, targetLanguage: resolvedTargetLanguage)
        do {
            let translated = try await translator.translate(request)
            translationHUD.show(text: translated)
        } catch {
            handleTranslationError(error)
        }
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

    @objc private func toggleLaunchAtLogin() {
        let shouldEnable = !isLaunchAtLoginEnabled

        do {
            try launchAtLoginManager.setEnabled(shouldEnable)
            isLaunchAtLoginEnabled = launchAtLoginManager.isEnabled
            updateLaunchAtLoginMenuState()
        } catch {
            showToast("ログイン時起動の設定に失敗: \(error.localizedDescription)")
        }
    }

    @objc private func openTranslationSettingsFromMenu() {
        openTranslationSettings()
    }

    private func updateShortcutMenuState() {
        shortcutToggleItem?.title = isShortcutEnabled ? "CMD+C+C を一時停止" : "CMD+C+C を再開"
        updateStatusItemAppearance()
    }

    private func updateLaunchAtLoginMenuState() {
        launchAtLoginItem?.state = isLaunchAtLoginEnabled ? .on : .off
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
        if let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: "クイック翻訳") {
            symbol.isTemplate = true
            button.image = symbol
            button.title = ""
        } else {
            button.image = nil
            button.title = isShortcutEnabled ? activeStatusTitle : pausedStatusTitle
        }

        button.toolTip = "クイック翻訳"
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

@MainActor
private final class TranslationHUDPresenter {
    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 12
    private let minWidth: CGFloat = 220
    private let maxTextWidth: CGFloat = 440
    private let minTextHeight: CGFloat = 20
    private let minWindowHeight: CGFloat = 56
    private let textWidthFudge: CGFloat = 12
    private let textHeightFudge: CGFloat = 14
    private let baseDismissInterval: TimeInterval = 3.2
    private let maxDismissInterval: TimeInterval = 6.0
    private let screenMargin: CGFloat = 12
    private let cursorOffsetX: CGFloat = 16
    private let cursorOffsetY: CGFloat = 18
    private let hudFont = NSFont.systemFont(ofSize: 15, weight: .medium)

    private var panel: NSPanel?
    private var textField: NSTextField?
    private var dismissWorkItem: DispatchWorkItem?

    func show(text: String) {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        let panel = ensurePanel()
        guard let textField else { return }
        let mouse = NSEvent.mouseLocation
        let screenFrame = screenContaining(point: mouse)?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let maxLabelHeight = max(
            minTextHeight,
            screenFrame.height - (screenMargin * 2) - (verticalPadding * 2)
        )

        let layout = layoutForMessage(message, maxLabelHeight: maxLabelHeight)
        textField.stringValue = message
        textField.frame = layout.labelFrame

        panel.setFrame(
            frameForHUD(size: layout.windowSize, mouse: mouse, screenFrame: screenFrame),
            display: false
        )
        panel.alphaValue = 1.0
        panel.orderFrontRegardless()

        dismissWorkItem?.cancel()
        let dismissInterval = min(
            maxDismissInterval,
            baseDismissInterval + Double(message.count) * 0.015
        )
        let work = DispatchWorkItem { [weak panel] in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                panel?.animator().alphaValue = 0
            } completionHandler: {
                panel?.orderOut(nil)
            }
        }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissInterval, execute: work)
    }

    private func ensurePanel() -> NSPanel {
        if let panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .normal
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]

        let effectView = NSVisualEffectView(frame: panel.contentView?.bounds ?? .zero)
        effectView.autoresizingMask = [.width, .height]
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 14
        effectView.layer?.masksToBounds = true

        let textField = NSTextField(wrappingLabelWithString: "")
        textField.font = hudFont
        textField.textColor = .labelColor
        textField.lineBreakMode = .byCharWrapping
        textField.maximumNumberOfLines = 0
        if let cell = textField.cell as? NSTextFieldCell {
            cell.wraps = true
            cell.usesSingleLineMode = false
            cell.truncatesLastVisibleLine = false
            cell.isScrollable = false
            cell.lineBreakMode = .byCharWrapping
        }

        effectView.addSubview(textField)
        panel.contentView?.addSubview(effectView)

        self.panel = panel
        self.textField = textField
        return panel
    }

    private func layoutForMessage(
        _ message: String,
        maxLabelHeight: CGFloat
    ) -> (windowSize: CGSize, labelFrame: NSRect) {
        let minimumLabelWidth = max(120, minWidth - horizontalPadding * 2)
        let firstPass = measureText(message, constrainedToWidth: maxTextWidth)
        let labelWidth = max(
            minimumLabelWidth,
            min(maxTextWidth, ceil(firstPass.width + textWidthFudge))
        )

        let secondPass = measureText(message, constrainedToWidth: labelWidth)
        let labelHeight = max(
            minTextHeight,
            min(maxLabelHeight, ceil(secondPass.height + textHeightFudge))
        )

        let windowWidth = max(minWidth, labelWidth + horizontalPadding * 2)
        let windowHeight = max(minWindowHeight, labelHeight + verticalPadding * 2)

        let labelFrame = NSRect(
            x: horizontalPadding,
            y: verticalPadding,
            width: windowWidth - horizontalPadding * 2,
            height: windowHeight - verticalPadding * 2
        )

        return (CGSize(width: windowWidth, height: windowHeight), labelFrame)
    }

    private func frameForHUD(size: CGSize, mouse: NSPoint, screenFrame: NSRect) -> NSRect {
        var x = mouse.x + cursorOffsetX
        var y = mouse.y - size.height - cursorOffsetY

        if x + size.width > screenFrame.maxX - screenMargin {
            x = mouse.x - size.width - cursorOffsetX
        }
        if y < screenFrame.minY + screenMargin {
            y = mouse.y + cursorOffsetY
        }

        let minX = screenFrame.minX + screenMargin
        let maxX = screenFrame.maxX - size.width - screenMargin
        let minY = screenFrame.minY + screenMargin
        let maxY = screenFrame.maxY - size.height - screenMargin

        x = min(max(x, minX), maxX)
        y = min(max(y, minY), maxY)

        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    private func measureText(_ message: String, constrainedToWidth width: CGFloat) -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        let attributedString = NSAttributedString(
            string: message,
            attributes: [
                .font: hudFont,
                .paragraphStyle: paragraphStyle
            ]
        )

        let textStorage = NSTextStorage(attributedString: attributedString)
        let layoutManager = NSLayoutManager()
        layoutManager.usesFontLeading = true
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        textContainer.lineBreakMode = .byCharWrapping
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = 0
        layoutManager.addTextContainer(textContainer)
        layoutManager.ensureLayout(for: textContainer)

        let usedRect = layoutManager.usedRect(for: textContainer).integral
        return CGSize(width: usedRect.width, height: usedRect.height)
    }

    private func screenContaining(point: NSPoint) -> NSScreen? {
        NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) })
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
