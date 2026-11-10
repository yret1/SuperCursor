//
//  CaptureGeometry.swift
//  SuperCursor
//

import CoreGraphics

/// Coordinate conversions for capturing the screen around the pointer.
///
/// AppKit (`NSEvent.mouseLocation`, `NSScreen`) puts the origin at the bottom-left of the
/// main display with y growing upwards. Quartz and ScreenCaptureKit put it at the top-left
/// with y growing downwards. Captured images are in pixels, so Retina displays double everything.
enum CaptureGeometry {

    /// Converts a global AppKit point to global Quartz coordinates.
    static func quartzPoint(fromAppKit point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryScreenHeight - point.y)
    }

    /// The region to capture, centered on the pointer and kept on its display.
    /// `cursor` and `displayFrame` are global Quartz coordinates. The result is in points,
    /// relative to the display's top-left corner, as ScreenCaptureKit's `sourceRect` expects.
    static func captureRect(around cursor: CGPoint, displayFrame: CGRect, size: CGSize) -> CGRect {
        let width = min(size.width, displayFrame.width)
        let height = min(size.height, displayFrame.height)
        let localX = cursor.x - displayFrame.minX
        let localY = cursor.y - displayFrame.minY

        let x = min(max(localX - width / 2, 0), displayFrame.width - width)
        let y = min(max(localY - height / 2, 0), displayFrame.height - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    /// Where the pointer is in the captured image, in pixels from its top-left corner.
    static func cursorInImage(
        cursor: CGPoint,
        displayFrame: CGRect,
        captureRect: CGRect,
        scale: CGFloat
    ) -> CGPoint {
        CGPoint(
            x: (cursor.x - displayFrame.minX - captureRect.minX) * scale,
            y: (cursor.y - displayFrame.minY - captureRect.minY) * scale
        )
    }
}
