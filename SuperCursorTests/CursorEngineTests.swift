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
        #expect(CursorEngine(store: defaults.store, hotKey: FakeHotKey()).isEnabled)
    }

    @Test func enabledStateIsRememberedAcrossLaunches() {
        let defaults = TemporaryDefaults()

        CursorEngine(store: defaults.store, hotKey: FakeHotKey()).isEnabled = false
        let secondLaunch = CursorEngine(store: defaults.store, hotKey: FakeHotKey())
        #expect(secondLaunch.isEnabled == false)

        secondLaunch.isEnabled = true
        #expect(CursorEngine(store: defaults.store, hotKey: FakeHotKey()).isEnabled)
    }

    @Test func usesSavedWiggleSettingsAtLaunch() {
        let defaults = TemporaryDefaults()
        defaults.store.set(3, forKey: SettingsKey.requiredReversals)

        let engine = CursorEngine(store: defaults.store, hotKey: FakeHotKey())

        #expect(engine.wiggleSettings == WiggleSettings(requiredReversals: 3, minSegmentDistance: 40, timeFrame: 1))
    }

    @Test func settingsChangesReachTheDetector() async {
        let defaults = TemporaryDefaults()
        let engine = CursorEngine(store: defaults.store, hotKey: FakeHotKey())

        defaults.store.set(7, forKey: SettingsKey.requiredReversals)
        defaults.store.set(90.0, forKey: SettingsKey.minSegmentDistance)
        await drainMainQueue()

        #expect(engine.wiggleSettings == WiggleSettings(requiredReversals: 7, minSegmentDistance: 90, timeFrame: 1))
    }

    @Test func wiggleTriggersActivation() {
        let defaults = TemporaryDefaults()
        let engine = CursorEngine(store: defaults.store, hotKey: FakeHotKey())
        var triggers: [CursorEngine.Trigger] = []
        engine.onTrigger = { triggers.append($0) }

        for (index, x) in [0.0, 60, 0, 60, 0, 60].enumerated() {
            engine.process(MouseSample(position: CGPoint(x: x, y: 0), timestamp: Double(index) * 0.1))
        }

        #expect(triggers == [.wiggle])
    }

    @Test func hotKeyPressTriggersActivation() {
        let defaults = TemporaryDefaults()
        let hotKey = FakeHotKey()
        let engine = CursorEngine(store: defaults.store, hotKey: hotKey)
        var triggers: [CursorEngine.Trigger] = []
        engine.onTrigger = { triggers.append($0) }

        hotKey.press()

        #expect(triggers == [.hotKey])
    }

    @Test func hotKeyIsOnlyRegisteredWhileEnabled() {
        let defaults = TemporaryDefaults()
        let hotKey = FakeHotKey()
        let engine = CursorEngine(store: defaults.store, hotKey: hotKey)
        #expect(hotKey.isRegistered)

        engine.isEnabled = false
        #expect(!hotKey.isRegistered)

        engine.isEnabled = true
        #expect(hotKey.isRegistered)
    }

    @Test func hotKeyCanBeTurnedOffInSettings() async {
        let defaults = TemporaryDefaults()
        let hotKey = FakeHotKey()
        let engine = CursorEngine(store: defaults.store, hotKey: hotKey)

        defaults.store.set(false, forKey: SettingsKey.hotKeyEnabled)
        await drainMainQueue()
        #expect(!hotKey.isRegistered)

        defaults.store.set(true, forKey: SettingsKey.hotKeyEnabled)
        await drainMainQueue()
        #expect(hotKey.isRegistered)

        withExtendedLifetime(engine) {}
    }

    @Test func hotKeyStaysOffAtLaunchWhenTurnedOffInSettings() {
        let defaults = TemporaryDefaults()
        defaults.store.set(false, forKey: SettingsKey.hotKeyEnabled)
        let hotKey = FakeHotKey()

        let engine = CursorEngine(store: defaults.store, hotKey: hotKey)

        #expect(!hotKey.isRegistered)
        withExtendedLifetime(engine) {}
    }
}

/// Stands in for the system-wide shortcut so tests don't grab a real key combination.
@MainActor
final class FakeHotKey: HotKeyRegistering {
    var onPress: (() -> Void)?
    private(set) var isRegistered = false

    func register() { isRegistered = true }
    func unregister() { isRegistered = false }
    func press() { onPress?() }
}

/// Waits until operations already queued on the main operation queue have run.
@MainActor
private func drainMainQueue() async {
    await withCheckedContinuation { continuation in
        OperationQueue.main.addOperation { continuation.resume() }
    }
}
