//
//  PanelPlacementTests.swift
//  SuperCursorTests
//

import CoreGraphics
import Testing
@testable import SuperCursor

@MainActor
struct PanelPlacementTests {
    let size = CGSize(width: 300, height: 200)
    let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)

    @Test func opensBelowRightOfPointer() {
        let frame = PanelPlacement.frame(size: size, cursor: CGPoint(x: 100, y: 500), visibleFrame: screen)
        #expect(frame == CGRect(x: 116, y: 284, width: 300, height: 200))
    }

    @Test func flipsLeftNearRightEdge() {
        let frame = PanelPlacement.frame(size: size, cursor: CGPoint(x: 900, y: 500), visibleFrame: screen)
        #expect(frame == CGRect(x: 584, y: 284, width: 300, height: 200))
    }

    @Test func flipsAboveNearBottomEdge() {
        let frame = PanelPlacement.frame(size: size, cursor: CGPoint(x: 100, y: 100), visibleFrame: screen)
        #expect(frame == CGRect(x: 116, y: 116, width: 300, height: 200))
    }

    @Test func flipsBothWaysInBottomRightCornerOfSecondScreen() {
        let secondScreen = CGRect(x: 1000, y: 0, width: 1000, height: 800)
        let frame = PanelPlacement.frame(size: size, cursor: CGPoint(x: 1950, y: 50), visibleFrame: secondScreen)
        #expect(frame == CGRect(x: 1634, y: 66, width: 300, height: 200))
    }

    @Test func worksOnScreenLeftOfMainDisplay() {
        let leftScreen = CGRect(x: -1440, y: 0, width: 1440, height: 900)
        let frame = PanelPlacement.frame(size: size, cursor: CGPoint(x: -1430, y: 890), visibleFrame: leftScreen)
        #expect(frame == CGRect(x: -1414, y: 674, width: 300, height: 200))
    }

    @Test func staysOnScreenWhenThereIsNoRoomAboveOrBelow() {
        let shortScreen = CGRect(x: 0, y: 0, width: 1000, height: 300)
        let frame = PanelPlacement.frame(size: size, cursor: CGPoint(x: 100, y: 150), visibleFrame: shortScreen)
        #expect(frame == CGRect(x: 116, y: 100, width: 300, height: 200))
    }

    @Test func panelTallerThanScreenKeepsItsTopVisible() {
        let shortScreen = CGRect(x: 0, y: 0, width: 1000, height: 300)
        let tall = CGSize(width: 300, height: 400)
        let frame = PanelPlacement.frame(size: tall, cursor: CGPoint(x: 100, y: 150), visibleFrame: shortScreen)
        #expect(frame == CGRect(x: 116, y: -100, width: 300, height: 400))
    }
}
