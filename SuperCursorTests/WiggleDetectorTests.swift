//
//  WiggleDetectorTests.swift
//  SuperCursorTests
//

import Foundation
import Testing
@testable import SuperCursor

@MainActor
struct WiggleDetectorTests {

    @Test func fastWiggleFiresOnFourthDirectionChange() {
        #expect(firingIndexes([0, 60, 0, 60, 0, 60], interval: 0.1) == [5])
    }

    @Test func wiggleStartingLeftFires() {
        #expect(firingIndexes([60, 0, 60, 0, 60, 0], interval: 0.1) == [5])
    }

    @Test func slowWiggleDoesNotFire() {
        #expect(firingIndexes([0, 60, 0, 60, 0, 60], interval: 0.5).isEmpty)
    }

    @Test func smallMovementsDoNotFire() {
        #expect(firingIndexes([0, 10, 0, 10, 0, 10, 0, 10], interval: 0.1).isEmpty)
    }

    @Test func jitterDuringLongSwipeDoesNotFire() {
        // A fast swipe to the right with a 5 pt backwards twitch every 50 pt.
        let xs: [Double] = [0, 50, 45, 95, 90, 140, 135, 185, 180, 230]
        #expect(firingIndexes(xs, interval: 0.02).isEmpty)
    }

    @Test func wobbleAtTurnaroundsStillCounts() {
        // A real wiggle where every turnaround has a 1 pt wobble before the next stroke.
        let xs: [Double] = [0, 60, 59, 60, 0, 1, 0, 60, 59, 60, 0, 1, 0, 60]
        #expect(firingIndexes(xs, interval: 0.05) == [13])
    }

    @Test func detectorResetsAfterFiring() {
        let twoWiggles: [Double] = [0, 60, 0, 60, 0, 60, 0, 60, 0, 60, 0, 60]
        #expect(firingIndexes(twoWiggles, interval: 0.1) == [5, 11])
    }

    @Test func requiredReversalsSettingIsUsed() {
        let settings = WiggleSettings(requiredReversals: 2, minSegmentDistance: 40, timeFrame: 1)
        #expect(firingIndexes([0, 60, 0, 60, 0, 60], interval: 0.1, settings: settings) == [3])
    }

    @Test func minSegmentDistanceSettingIsUsed() {
        let settings = WiggleSettings(requiredReversals: 4, minSegmentDistance: 100, timeFrame: 1)
        #expect(firingIndexes([0, 60, 0, 60, 0, 60], interval: 0.1, settings: settings).isEmpty)
    }

    @Test func timeFrameSettingIsUsed() {
        let settings = WiggleSettings(requiredReversals: 4, minSegmentDistance: 40, timeFrame: 3)
        #expect(firingIndexes([0, 60, 0, 60, 0, 60], interval: 0.5, settings: settings) == [5])
    }
}

@MainActor
struct WiggleSettingsTests {

    @Test func loadReadsStoredValues() {
        let defaults = TemporaryDefaults()
        defaults.store.set(6, forKey: SettingsKey.requiredReversals)
        defaults.store.set(80.0, forKey: SettingsKey.minSegmentDistance)
        defaults.store.set(0.5, forKey: SettingsKey.timeFrame)

        #expect(
            WiggleSettings.load(from: defaults.store)
                == WiggleSettings(requiredReversals: 6, minSegmentDistance: 80, timeFrame: 0.5)
        )
    }

    @Test func loadFallsBackToDefaultsForMissingKeys() {
        let defaults = TemporaryDefaults()

        #expect(
            WiggleSettings.load(from: defaults.store)
                == WiggleSettings(requiredReversals: 4, minSegmentDistance: 40, timeFrame: 1)
        )
    }
}

/// Feeds x positions to a fresh detector, one sample every `interval` seconds,
/// and returns the indexes of the samples where it fired.
@MainActor
func firingIndexes(
    _ xs: [Double],
    interval: TimeInterval,
    settings: WiggleSettings? = nil
) -> [Int] {
    var detector = WiggleDetector(settings: settings ?? .defaults)
    return xs.indices.filter { index in
        detector.process(
            MouseSample(
                position: CGPoint(x: xs[index], y: 0),
                timestamp: Double(index) * interval
            )
        )
    }
}

/// A user defaults suite of its own for each test, emptied before and after use,
/// so tests never touch the app's real settings or each other's.
/// The name is fixed per test because macOS keeps an empty file for every suite ever used.
final class TemporaryDefaults {
    let name: String
    let store: UserDefaults

    init(test: String = #function) {
        name = "SuperCursorTests." + test.replacingOccurrences(of: "()", with: "")
        store = UserDefaults(suiteName: name)!
        store.removePersistentDomain(forName: name)
    }

    deinit {
        store.removePersistentDomain(forName: name)
    }
}
