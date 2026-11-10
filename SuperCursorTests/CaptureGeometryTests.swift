//
//  CaptureGeometryTests.swift
//  SuperCursorTests
//

import CoreGraphics
import Testing
@testable import SuperCursor

@MainActor
struct CaptureGeometryTests {
    let region = CGSize(width: 800, height: 500)
    let mainDisplay = CGRect(x: 0, y: 0, width: 1440, height: 900)

    // MARK: AppKit → Quartz

    @Test func flipsAppKitPointToQuartz() {
        let point = CaptureGeometry.quartzPoint(fromAppKit: CGPoint(x: 100, y: 800), primaryScreenHeight: 900)
        #expect(point == CGPoint(x: 100, y: 100))
    }

    @Test func pointOnDisplayAboveMainGetsNegativeQuartzY() {
        let point = CaptureGeometry.quartzPoint(fromAppKit: CGPoint(x: 200, y: 1200), primaryScreenHeight: 900)
        #expect(point == CGPoint(x: 200, y: -300))
    }

    // MARK: Capture region

    @Test func regionIsCenteredOnPointer() {
        let rect = CaptureGeometry.captureRect(around: CGPoint(x: 720, y: 450), displayFrame: mainDisplay, size: region)
        #expect(rect == CGRect(x: 320, y: 200, width: 800, height: 500))
    }

    @Test func regionStaysOnDisplayNearTopLeft() {
        let rect = CaptureGeometry.captureRect(around: CGPoint(x: 100, y: 50), displayFrame: mainDisplay, size: region)
        #expect(rect == CGRect(x: 0, y: 0, width: 800, height: 500))
    }

    @Test func regionStaysOnDisplayNearBottomRight() {
        let rect = CaptureGeometry.captureRect(around: CGPoint(x: 1400, y: 880), displayFrame: mainDisplay, size: region)
        #expect(rect == CGRect(x: 640, y: 400, width: 800, height: 500))
    }

    @Test func regionIsRelativeToSecondaryDisplay() {
        let secondary = CGRect(x: 1440, y: -200, width: 1920, height: 1080)
        let rect = CaptureGeometry.captureRect(around: CGPoint(x: 2400, y: 340), displayFrame: secondary, size: region)
        #expect(rect == CGRect(x: 560, y: 290, width: 800, height: 500))
    }

    @Test func regionShrinksToFitSmallDisplay() {
        let small = CGRect(x: 0, y: 0, width: 600, height: 400)
        let rect = CaptureGeometry.captureRect(around: CGPoint(x: 300, y: 200), displayFrame: small, size: region)
        #expect(rect == CGRect(x: 0, y: 0, width: 600, height: 400))
    }

    // MARK: Pointer in the captured image

    @Test func pointerIsInImageCenterOnRetina() {
        let point = CaptureGeometry.cursorInImage(
            cursor: CGPoint(x: 720, y: 450),
            displayFrame: mainDisplay,
            captureRect: CGRect(x: 320, y: 200, width: 800, height: 500),
            scale: 2
        )
        #expect(point == CGPoint(x: 800, y: 500))
    }

    @Test func pointerIsOffCenterWhenRegionWasClamped() {
        let secondary = CGRect(x: 1440, y: -200, width: 1920, height: 1080)
        let point = CaptureGeometry.cursorInImage(
            cursor: CGPoint(x: 1500, y: -150),
            displayFrame: secondary,
            captureRect: CGRect(x: 0, y: 0, width: 800, height: 500),
            scale: 1
        )
        #expect(point == CGPoint(x: 60, y: 50))
    }
}
