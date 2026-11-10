//
//  SuperCursorApp.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-21.
//

import SwiftUI

@main
struct SuperCursorApp: App {
    @State private var engine = CursorEngine()

    var body: some Scene {
        MenuBarExtra("SuperCursor", systemImage: "cursorarrow.rays") {
            Toggle("Enabled", isOn: $engine.isEnabled)

            Divider()

            OpenSettingsButton()

            Divider()

            Button("Quit SuperCursor") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView()
        }
    }
}

/// Opens Settings in front of other apps. A menu bar app is never the active app,
/// so without activating first the window opens behind whatever you were using.
private struct OpenSettingsButton: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings…") {
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")
    }
}
