//
//  CursorEngineTests.swift
//  SuperCursorTests
//

import Foundation
import Testing
@testable import SuperCursor

@MainActor
struct CursorEngineTests {

    @Test func startsEnabledOnFirstLaunch() {
        let defaults = TemporaryDefaults()
        #expect(CursorEngine(store: defaults.store).isEnabled)
    }

    @Test func enabledStateIsRememberedAcrossLaunches() {
        let defaults = TemporaryDefaults()

        CursorEngine(store: defaults.store).isEnabled = false
        let secondLaunch = CursorEngine(store: defaults.store)
        #expect(secondLaunch.isEnabled == false)

        secondLaunch.isEnabled = true
        #expect(CursorEngine(store: defaults.store).isEnabled)
    }

    @Test func usesSavedWiggleSettingsAtLaunch() {
        let defaults = TemporaryDefaults()
        defaults.store.set(3, forKey: SettingsKey.requiredReversals)

        let engine = CursorEngine(store: defaults.store)

        #expect(engine.wiggleSettings == WiggleSettings(requiredReversals: 3, minSegmentDistance: 40, timeFrame: 1))
    }

    @Test func settingsChangesReachTheDetector() async {
        let defaults = TemporaryDefaults()
        let engine = CursorEngine(store: defaults.store)

        defaults.store.set(7, forKey: SettingsKey.requiredReversals)
        defaults.store.set(90.0, forKey: SettingsKey.minSegmentDistance)
        await drainMainQueue()

        #expect(engine.wiggleSettings == WiggleSettings(requiredReversals: 7, minSegmentDistance: 90, timeFrame: 1))
    }
}

/// Waits until operations already queued on the main operation queue have run.
@MainActor
private func drainMainQueue() async {
    await withCheckedContinuation { continuation in
        OperationQueue.main.addOperation { continuation.resume() }
    }
}
