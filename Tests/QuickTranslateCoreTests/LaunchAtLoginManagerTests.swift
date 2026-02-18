import Foundation
import Testing
@testable import QuickTranslateCore

@Test("ログイン時起動を有効化するとLaunchAgentが作成される")
func writesLaunchAgentPlistOnEnable() throws {
    let fileManager = FileManager.default
    let tempHome = fileManager.temporaryDirectory
        .appendingPathComponent("quick-translate-login-\(UUID().uuidString)", isDirectory: true)
    try fileManager.createDirectory(at: tempHome, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: tempHome) }

    let label = "dev.test.quick-translate"
    let executablePath = "/Applications/Quick Translate.app/Contents/MacOS/quick-translate-macos"
    let manager = LaunchAtLoginManager(
        homeDirectory: tempHome,
        executablePath: executablePath,
        agentLabel: label,
        fileManager: fileManager
    )

    #expect(manager.isEnabled == false)

    try manager.setEnabled(true)

    #expect(manager.isEnabled == true)
    let plistURL = tempHome.appendingPathComponent("Library/LaunchAgents/\(label).plist")
    #expect(fileManager.fileExists(atPath: plistURL.path))

    let data = try Data(contentsOf: plistURL)
    let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
    guard let dictionary = plist as? [String: Any] else {
        throw NSError(domain: "LaunchAtLoginManagerTests", code: 1)
    }

    #expect(dictionary["Label"] as? String == label)
    #expect(dictionary["RunAtLoad"] as? Bool == true)
    #expect(dictionary["ProgramArguments"] as? [String] == [executablePath])
}

@Test("相対パスの実行パスは絶対パスとしてLaunchAgentに保存される")
func storesAbsolutePathWhenExecutablePathIsRelative() throws {
    let fileManager = FileManager.default
    let tempHome = fileManager.temporaryDirectory
        .appendingPathComponent("quick-translate-login-\(UUID().uuidString)", isDirectory: true)
    try fileManager.createDirectory(at: tempHome, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: tempHome) }

    let label = "dev.test.quick-translate"
    let manager = LaunchAtLoginManager(
        homeDirectory: tempHome,
        executablePath: ".build/debug/quick-translate-macos",
        agentLabel: label,
        currentDirectoryPath: "/Users/example/work/macos-quick-translate",
        fileManager: fileManager
    )

    try manager.setEnabled(true)

    let plistURL = tempHome.appendingPathComponent("Library/LaunchAgents/\(label).plist")
    let data = try Data(contentsOf: plistURL)
    let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
    guard let dictionary = plist as? [String: Any] else {
        throw NSError(domain: "LaunchAtLoginManagerTests", code: 2)
    }

    #expect(dictionary["ProgramArguments"] as? [String] == ["/Users/example/work/macos-quick-translate/.build/debug/quick-translate-macos"])
}

@Test("ログイン時起動を無効化するとLaunchAgentが削除される")
func removesLaunchAgentPlistOnDisable() throws {
    let fileManager = FileManager.default
    let tempHome = fileManager.temporaryDirectory
        .appendingPathComponent("quick-translate-login-\(UUID().uuidString)", isDirectory: true)
    try fileManager.createDirectory(at: tempHome, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: tempHome) }

    let label = "dev.test.quick-translate"
    let manager = LaunchAtLoginManager(
        homeDirectory: tempHome,
        executablePath: "/tmp/quick-translate-macos",
        agentLabel: label,
        fileManager: fileManager
    )

    try manager.setEnabled(true)
    #expect(manager.isEnabled == true)

    try manager.setEnabled(false)

    #expect(manager.isEnabled == false)
    let plistURL = tempHome.appendingPathComponent("Library/LaunchAgents/\(label).plist")
    #expect(fileManager.fileExists(atPath: plistURL.path) == false)
}

@Test("実行パスが空なら有効化に失敗する")
func rejectsEmptyExecutablePath() throws {
    let fileManager = FileManager.default
    let tempHome = fileManager.temporaryDirectory
        .appendingPathComponent("quick-translate-login-\(UUID().uuidString)", isDirectory: true)
    try fileManager.createDirectory(at: tempHome, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: tempHome) }

    let manager = LaunchAtLoginManager(
        homeDirectory: tempHome,
        executablePath: "   ",
        agentLabel: "dev.test.quick-translate",
        fileManager: fileManager
    )

    #expect(throws: LaunchAtLoginError.self) {
        try manager.setEnabled(true)
    }
}
