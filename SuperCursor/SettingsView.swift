//
//  SettingsView.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-21.
//

import SwiftUI

enum SettingsKey {
    static let requiredReversals = "requiredReversals"
    static let minSegmentDistance = "minSegmentDistance"
    static let timeFrame = "timeFrame"
}

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                GeneralSettingsView()
            }
            Tab("AI", systemImage: "sparkles") {
                AISettingsView()
            }
        }
        .frame(width: 480)
    }
}

struct GeneralSettingsView: View {
    @AppStorage(SettingsKey.requiredReversals) private var requiredReversals = 4
    @AppStorage(SettingsKey.minSegmentDistance) private var minSegmentDistance = 40.0
    @AppStorage(SettingsKey.timeFrame) private var timeFrame = 1.0

    var body: some View {
        Form {
            Section {
                Stepper(
                    "Direction changes: \(requiredReversals)",
                    value: $requiredReversals,
                    in: 2...8
                )

                LabeledContent("Minimum movement") {
                    Slider(value: $minSegmentDistance, in: 10...150, step: 5)
                    Text("\(Int(minSegmentDistance)) pt")
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }

                LabeledContent("Time window") {
                    Slider(value: $timeFrame, in: 0.3...1.5, step: 0.1)
                    Text("\(timeFrame, format: .number.precision(.fractionLength(1))) s")
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
            } header: {
                Text("Wiggle detection")
            } footer: {
                Text("Shake the pointer quickly left and right to activate SuperCursor. These settings control how hard and how fast you need to shake.")
            }
        }
        .formStyle(.grouped)
    }
}

struct AISettingsView: View {
    var body: some View {
        Form {
            Section("Provider") {
                Text("Provider settings coming soon")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView()
}
