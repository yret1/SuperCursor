//
//  CursorEngine.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-23.
//

import AppKit
import Observation

@MainActor
@Observable
final class CursorEngine {
    private let store: UserDefaults
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
        }
    }

    var wiggleSettings: WiggleSettings { detector.settings }

    init(store: UserDefaults = .standard) {
        self.store = store
        self.detector = WiggleDetector(settings: .load(from: store))
        self.isEnabled = store.object(forKey: SettingsKey.isEnabled) as? Bool ?? true

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
    }

    isolated deinit {
        disable()
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
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

    private func reloadSettings() {
        detector.settings = WiggleSettings.load(from: store)
    }

    private func handle(_ event: NSEvent) {
        let sample = MouseSample(
            position: NSEvent.mouseLocation,
            timestamp: event.timestamp
        )

        if detector.process(sample) {
            NSSound.beep()
        }
    }
}
