import Foundation

public protocol LaunchAtLoginManaging {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

public enum LaunchAtLoginError: LocalizedError {
    case emptyExecutablePath
    case failedToEncodePlist
    case failedToWriteLaunchAgent(underlying: Error)
    case failedToRemoveLaunchAgent(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .emptyExecutablePath:
            return "実行ファイルのパスを解決できませんでした。"
        case .failedToEncodePlist:
            return "ログイン時起動設定の生成に失敗しました。"
        case .failedToWriteLaunchAgent(let underlying):
            return "ログイン時起動設定の保存に失敗しました: \(underlying.localizedDescription)"
        case .failedToRemoveLaunchAgent(let underlying):
            return "ログイン時起動設定の削除に失敗しました: \(underlying.localizedDescription)"
        }
    }
}

public struct LaunchAtLoginManager: LaunchAtLoginManaging {
    private let homeDirectory: URL
    private let executablePath: String
    private let agentLabel: String
    private let currentDirectoryPath: String
    private let fileManager: FileManager

    public init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        executablePath: String = CommandLine.arguments.first ?? "",
        agentLabel: String = "dev.gawasa.quick-translate-macos",
        currentDirectoryPath: String = FileManager.default.currentDirectoryPath,
        fileManager: FileManager = .default
    ) {
        self.homeDirectory = homeDirectory
        self.executablePath = executablePath
        self.agentLabel = agentLabel
        self.currentDirectoryPath = currentDirectoryPath
        self.fileManager = fileManager
    }

    public var isEnabled: Bool {
        fileManager.fileExists(atPath: launchAgentURL.path)
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try installLaunchAgent()
            return
        }

        try removeLaunchAgentIfExists()
    }

    private var launchAgentDirectoryURL: URL {
        homeDirectory.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    }

    private var launchAgentURL: URL {
        launchAgentDirectoryURL.appendingPathComponent("\(agentLabel).plist")
    }

    private func installLaunchAgent() throws {
        let executablePath = try resolvedExecutablePath()
        let plist: [String: Any] = [
            "Label": agentLabel,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false
        ]

        let data: Data
        do {
            data = try PropertyListSerialization.data(
                fromPropertyList: plist,
                format: .xml,
                options: 0
            )
        } catch {
            throw LaunchAtLoginError.failedToEncodePlist
        }

        do {
            try fileManager.createDirectory(
                at: launchAgentDirectoryURL,
                withIntermediateDirectories: true
            )
            try data.write(to: launchAgentURL, options: .atomic)
        } catch {
            throw LaunchAtLoginError.failedToWriteLaunchAgent(underlying: error)
        }
    }

    private func removeLaunchAgentIfExists() throws {
        guard fileManager.fileExists(atPath: launchAgentURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: launchAgentURL)
        } catch {
            throw LaunchAtLoginError.failedToRemoveLaunchAgent(underlying: error)
        }
    }

    private func resolvedExecutablePath() throws -> String {
        let trimmed = executablePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw LaunchAtLoginError.emptyExecutablePath
        }

        let executableURL: URL
        if trimmed.hasPrefix("/") {
            executableURL = URL(fileURLWithPath: trimmed)
        } else {
            executableURL = URL(fileURLWithPath: currentDirectoryPath, isDirectory: true)
                .appendingPathComponent(trimmed)
        }

        return executableURL.standardizedFileURL.path
    }
}
