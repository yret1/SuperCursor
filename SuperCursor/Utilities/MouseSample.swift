//
//  MouseSample.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-21.
//

import Foundation;

struct MouseSample {
    let position: CGPoint
    let timestamp: TimeInterval
}

enum Direction {
    case left
    case right
}

//Some kind of way to track amount of bounces withing the alloted timeout


//Users Settings (Imported from elsewhere maybe)?



//We eval the actuall usage
func evaluateDirection(from: MouseSample, to: MouseSample) -> (direction: Direction, distance: Double)? {
    let dx = to.position.x - from.position.x;
    
    if dx == 0
        {
            return nil
        }
    
    if dx > 0
        {
            return( .right, dx)
        }
    
    return (.left, dx)
}

// Activate the overlay things
func activateSuperCursor(){}


//Upload image to current context



//Send To AI





