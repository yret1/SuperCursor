//
//  OverlayView.swift
//  SuperCursor
//

import SwiftUI

/// What the overlay shows. Updated each time it opens.
@MainActor
@Observable
final class OverlayModel {
    /// The app that was in front when SuperCursor opened.
    var appName: String?
    var appIcon: NSImage?
    var prompt = ""
    /// Bumped on every open so the prompt field takes focus again.
    var focusRequest = 0
}

struct OverlayView: View {
    @Bindable var model: OverlayModel
    @FocusState private var promptFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let icon = model.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 18, height: 18)
                }
                Text(model.appName ?? "SuperCursor")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("esc")
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
            }

            TextField("Ask about what's under the pointer…", text: $model.prompt)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($promptFocused)
        }
        .padding(16)
        .frame(width: 380)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .onAppear { promptFocused = true }
        .onChange(of: model.focusRequest) { promptFocused = true }
    }
}

/// A ring that expands and fades out at the pointer.
struct PulseView: View {
    @State private var expanded = false

    var body: some View {
        Circle()
            .stroke(Color.accentColor, lineWidth: 3)
            .scaleEffect(expanded ? 1 : 0.2)
            .opacity(expanded ? 0 : 0.9)
            .padding(3)
            .onAppear {
                withAnimation(.easeOut(duration: PulseWindow.duration)) {
                    expanded = true
                }
            }
    }
}

#Preview {
    let model = OverlayModel()
    model.appName = "Safari"
    return OverlayView(model: model).padding()
}
