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
    var capture: CaptureState = .capturing
    var prompt = ""
    /// Bumped on every open so the prompt field takes focus again.
    var focusRequest = 0
}

enum CaptureState {
    case capturing
    case captured(ScreenCapture)
    case needsPermission
    case failed(String)
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

            CapturePreview(state: model.capture)

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

/// Shows what was captured around the pointer, which is what the AI will see.
/// Fixed height so the panel doesn't change size when the capture arrives.
private struct CapturePreview: View {
    let state: CaptureState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)

            switch state {
            case .capturing:
                ProgressView()
                    .controlSize(.small)

            case .captured(let capture):
                Image(decorative: capture.image, scale: capture.scale)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 12))

            case .needsPermission:
                VStack(spacing: 10) {
                    Text("SuperCursor needs Screen Recording permission to see what's under the pointer.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                    Button("Open System Settings") {
                        ScreenCapturer.openPermissionSettings()
                    }
                }
                .padding()

            case .failed(let message):
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .frame(height: 170)
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
