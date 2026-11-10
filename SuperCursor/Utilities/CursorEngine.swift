//
//  CursorEngine.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-23.
//

import AppKit
import Observation

/// Watches for the two ways to summon SuperCursor: wiggling the pointer and the keyboard shortcut.
@MainActor
@Observable
final class CursorEngine {
    enum Trigger { case wiggle, hotKey }

    /// Called when SuperCursor is summoned.
    @ObservationIgnored var onTrigger: ((Trigger) -> Void)?

    private let store: UserDefaults
    private let hotKey: HotKeyRegistering
    @ObservationIgnored private var detector: WiggleDetector

    // Monitor tokens
    @ObservationIgnored private var globalToken: Any?
    @ObservationIgnored private var inAppToken: Any?
    @ObservationIgnored private var settingsObserver: NSObjectProtocol?

    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            store.set(isEnabled, forKey: SettingsKey.isEnabled)
            isEnabled ? enable() : disable()
            updateHotKey()
        }
    }

    var wiggleSettings: WiggleSettings { detector.settings }

    init(store: UserDefaults = .standard, hotKey: HotKeyRegistering? = nil) {
        let hotKey = hotKey ?? HotKey()
        self.store = store
        self.hotKey = hotKey
        self.detector = WiggleDetector(settings: .load(from: store))
        self.isEnabled = store.object(forKey: SettingsKey.isEnabled) as? Bool ?? true

        hotKey.onPress = { [weak self] in
            self?.onTrigger?(.hotKey)
        }

        // Pick up changes made in the Settings window while running
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reloadSettings()
            }
        }

        if isEnabled {
            enable()
        }
        updateHotKey()
    }

    isolated deinit {
        disable()
        hotKey.unregister()
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
        }
    }

    /// Feeds one pointer position to the wiggle detector.
    func process(_ sample: MouseSample) {
        if detector.process(sample) {
            onTrigger?(.wiggle)
        }
    }

    private func enable() {
        guard globalToken == nil else { return }

        globalToken = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) {
            [weak self] mouseEvent in
            self?.handle(mouseEvent)
        }

        inAppToken = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) {
            [weak self] mouseEvent in
            self?.handle(mouseEvent)
            return mouseEvent
        }
    }

    private func disable() {
        if let globalToken {
            NSEvent.removeMonitor(globalToken)
            self.globalToken = nil
        }

        if let inAppToken {
            NSEvent.removeMonitor(inAppToken)
            self.inAppToken = nil
        }

        detector = WiggleDetector(settings: detector.settings)
    }

    private func updateHotKey() {
        let wanted = isEnabled && (store.object(forKey: SettingsKey.hotKeyEnabled) as? Bool ?? true)
        wanted ? hotKey.register() : hotKey.unregister()
    }

    private func reloadSettings() {
        detector.settings = WiggleSettings.load(from: store)
        updateHotKey()
    }

    private func handle(_ event: NSEvent) {
        process(
            MouseSample(
                position: NSEvent.mouseLocation,
                timestamp: event.timestamp
            )
        )
    }
}
