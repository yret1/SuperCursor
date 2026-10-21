//
//  MouseSample.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-21.
//


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

func evaluateDirection(from: MouseSample, to: MouseSample) -> Direction? {
    let dx = to.position.x - from.position.x;
    
    if dx == 0
        {
            return nil
        }
    
    if dx > 0
        {
            return .left
        }
    
    
    
    return .right
}







