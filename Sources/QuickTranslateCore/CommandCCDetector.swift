import Foundation

public struct CommandCCDetector {
    private let threshold: TimeInterval
    private var lastTrigger: Date?

    public init(threshold: TimeInterval = 0.45) {
        self.threshold = threshold
    }

    public mutating func registerCommandC(at now: Date = Date()) -> Bool {
        defer { lastTrigger = now }

        guard let lastTrigger else {
            return false
        }

        return now.timeIntervalSince(lastTrigger) <= threshold
    }
}
