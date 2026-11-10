//
//  PanelPlacement.swift
//  SuperCursor
//

import CoreGraphics

/// Where the overlay panel goes relative to the pointer. All values are in
/// AppKit screen coordinates (origin bottom-left, y grows upwards).
enum PanelPlacement {
    /// Gap between the pointer and the panel's nearest corner.
    static let cursorGap: CGFloat = 16

    /// Puts the panel below and to the right of the pointer, flips it to the left or
    /// above when it would run off the screen, and always keeps it inside `visibleFrame`.
    static func frame(size: CGSize, cursor: CGPoint, visibleFrame: CGRect) -> CGRect {
        var x = cursor.x + cursorGap
        if x + size.width > visibleFrame.maxX {
            x = cursor.x - cursorGap - size.width
        }

        var y = cursor.y - cursorGap - size.height
        if y < visibleFrame.minY {
            y = cursor.y + cursorGap
        }

        // Clamp so the left and top edges win if the panel is bigger than the screen.
        x = max(min(x, visibleFrame.maxX - size.width), visibleFrame.minX)
        y = min(max(y, visibleFrame.minY), visibleFrame.maxY - size.height)

        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}
