import Foundation
import Testing
@testable import QuickTranslateCore

@Test("2回目のCommand+Cがしきい値内ならトリガーされる")
func detectsDoubleTapWithinThreshold() {
    var detector = CommandCCDetector(threshold: 0.4)
    #expect(detector.registerCommandC(at: Date(timeIntervalSince1970: 100)) == false)
    #expect(detector.registerCommandC(at: Date(timeIntervalSince1970: 100.3)) == true)
}

@Test("しきい値を超えるとトリガーされない")
func ignoresSlowDoubleTap() {
    var detector = CommandCCDetector(threshold: 0.4)
    #expect(detector.registerCommandC(at: Date(timeIntervalSince1970: 100)) == false)
    #expect(detector.registerCommandC(at: Date(timeIntervalSince1970: 101)) == false)
}
