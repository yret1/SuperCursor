//
//  SuperCursorApp.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-21.
//

import SwiftUI

@main
struct SuperCursorApp: App {
    @State private var engine = CursorEngine();
    
    var body: some Scene {
        MenuBarExtra("SuperCursor", systemImage: "cursorarrow.rays") {
            SettingsLink {
                Text("Settings…")
            }
            .keyboardShortcut(",")

            Divider()

            Button("Quit SuperCursor") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            
            Toggle(isOn: $engine.isEnabled){
                Text("Hi mom")
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView()
        }
    }
}
