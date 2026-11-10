//
//  OverlayController.swift
//  SuperCursor
//

import AppKit
import SwiftUI

/// Shows and hides the SuperCursor panel next to the pointer.
@MainActor
final class OverlayController {
    private let model = OverlayModel()
    private let pulse = PulseWindow()
    private var panel: OverlayPanel?
    private var clickOutsideMonitor: Any?
    private var captureTask: Task<Void, Never>?

    private(set) var isVisible = false

    /// Opens the panel at the pointer, or moves it there if it's already open.
    func show(at cursor: CGPoint) {
        pulse.play(at: cursor)

        // We never activate, so the frontmost app is still the one the user was in.
        let frontApp = NSWorkspace.shared.frontmostApplication
        model.appName = frontApp?.localizedName
        model.appIcon = frontApp?.icon
        if !isVisible {
            model.prompt = ""
        }
        model.focusRequest += 1

        let panel = self.panel ?? makePanel()
        let size = panel.contentView?.fittingSize ?? .zero
        let screen = NSScreen.screens.first { NSMouseInRect(cursor, $0.frame, false) } ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? CGRect(origin: .zero, size: size)
        panel.setFrame(
            PanelPlacement.frame(size: size, cursor: cursor, visibleFrame: visibleFrame),
            display: true
        )

        isVisible = true
        panel.makeKeyAndOrderFront(nil)
        watchForClicksOutside()
        startCapture(around: cursor)
    }

    func toggle(at cursor: CGPoint) {
        isVisible ? hide() : show(at: cursor)
    }

    func hide() {
        // Hiding makes the panel resign key, which calls back into here.
        guard isVisible else { return }
        isVisible = false

        captureTask?.cancel()
        captureTask = nil

        if let clickOutsideMonitor {
            NSEvent.removeMonitor(clickOutsideMonitor)
            self.clickOutsideMonitor = nil
        }
        panel?.orderOut(nil)
    }

    /// Captures the screen around the pointer into the panel. SuperCursor's own windows
    /// are left out of the capture, so the panel can already be showing.
    private func startCapture(around cursor: CGPoint) {
        captureTask?.cancel()

        guard ScreenCapturer.hasPermission else {
            ScreenCapturer.requestPermission()
            model.capture = .needsPermission
            return
        }

        model.capture = .capturing
        captureTask = Task { [model] in
            do {
                let capture = try await ScreenCapturer.capture(around: cursor)
                try Task.checkCancellation()
                model.capture = .captured(capture)
            } catch is CancellationError {
                // A newer capture or closing the panel replaced this one.
            } catch {
                model.capture = .failed(error.localizedDescription)
            }
        }
    }

    private func makePanel() -> OverlayPanel {
        let panel = OverlayPanel(content: OverlayView(model: model))
        panel.onDismiss = { [weak self] in
            self?.hide()
        }
        self.panel = panel
        return panel
    }

    /// Global monitors only see events for other apps, so any click here is outside the panel.
    private func watchForClicksOutside() {
        guard clickOutsideMonitor == nil else { return }
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            self?.hide()
        }
    }
}

/// A floating panel that can take typing without pulling focus away from the app you're in.
final class OverlayPanel: NSPanel {
    /// Called on Esc and when the panel loses focus (clicking elsewhere, switching apps).
    var onDismiss: (() -> Void)?

    init(content: some View) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        // SuperCursor is never the active app, so the default would hide the panel immediately.
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        animationBehavior = .utilityWindow
        contentView = NSHostingView(rootView: content)
    }

    // Borderless windows can't take keyboard focus by default, which would block typing.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onDismiss?()
    }

    override func resignKey() {
        super.resignKey()
        onDismiss?()
    }
}

/// A short expanding ring at the pointer, so you can see SuperCursor noticed the wiggle.
@MainActor
final class PulseWindow {
    static let duration = 0.45
    private static let size: CGFloat = 96

    private var window: NSPanel?

    func play(at point: CGPoint) {
        window?.orderOut(nil)

        let window = NSPanel(
            contentRect: CGRect(
                x: point.x - Self.size / 2,
                y: point.y - Self.size / 2,
                width: Self.size,
                height: Self.size
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.hidesOnDeactivate = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        window.contentView = NSHostingView(rootView: PulseView())
        window.orderFrontRegardless()
        self.window = window

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.duration))
            window.orderOut(nil)
            if self?.window === window {
                self?.window = nil
            }
        }
    }
}
