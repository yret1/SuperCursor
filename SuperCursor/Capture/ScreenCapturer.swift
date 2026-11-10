//
//  ScreenCapturer.swift
//  SuperCursor
//

import AppKit
import ScreenCaptureKit

/// A screenshot of the area around the pointer.
struct ScreenCapture {
    let image: CGImage
    /// Pixels per point of the display it came from (2 on Retina).
    let scale: CGFloat
    /// Where the pointer is in `image`, in pixels from the top-left corner.
    let cursorInImage: CGPoint
}

enum ScreenCaptureError: LocalizedError {
    case displayNotFound

    var errorDescription: String? {
        switch self {
        case .displayNotFound: "Couldn't find the display under the pointer."
        }
    }
}

/// Captures the screen around the pointer with ScreenCaptureKit.
/// Needs Screen Recording permission, which works inside the App Sandbox.
enum ScreenCapturer {
    /// Size of the captured area in points.
    static let regionSize = CGSize(width: 800, height: 500)

    static var hasPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Shows the system prompt the first time and adds SuperCursor to the
    /// Screen Recording list in System Settings. Does nothing after that.
    static func requestPermission() {
        CGRequestScreenCaptureAccess()
    }

    static func openPermissionSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }

    /// Captures `regionSize` around `appKitCursor` (a global AppKit point such as
    /// `NSEvent.mouseLocation`), leaving out SuperCursor's own windows.
    static func capture(around appKitCursor: CGPoint) async throws -> ScreenCapture {
        let primaryHeight = CGDisplayBounds(CGMainDisplayID()).height
        let cursor = CaptureGeometry.quartzPoint(fromAppKit: appKitCursor, primaryScreenHeight: primaryHeight)

        var displayID = CGMainDisplayID()
        var displayCount: UInt32 = 0
        CGGetDisplaysWithPoint(cursor, 1, &displayID, &displayCount)
        let displayFrame = CGDisplayBounds(displayID)

        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw ScreenCaptureError.displayNotFound
        }
        let ownApp = content.applications.filter {
            $0.processID == ProcessInfo.processInfo.processIdentifier
        }
        let filter = SCContentFilter(display: display, excludingApplications: ownApp, exceptingWindows: [])
        let scale = CGFloat(filter.pointPixelScale)

        let rect = CaptureGeometry.captureRect(around: cursor, displayFrame: displayFrame, size: regionSize)
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = rect
        configuration.width = Int(rect.width * scale)
        configuration.height = Int(rect.height * scale)
        configuration.showsCursor = true

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)

        return ScreenCapture(
            image: image,
            scale: scale,
            cursorInImage: CaptureGeometry.cursorInImage(
                cursor: cursor,
                displayFrame: displayFrame,
                captureRect: rect,
                scale: scale
            )
        )
    }
}
