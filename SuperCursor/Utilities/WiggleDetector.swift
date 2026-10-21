//
//  WiggleDetector.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-21.
//
import Foundation

struct CurrentSample {
    var direction: Direction
    var distance: Double
}

struct WiggleDetector {
    
    //User Setable
    var requiredReversals: Int = 4
    var minSegmentDistance: Double = 40
    var timeFrame: TimeInterval = 1
    
    //Private data
    private var Segment: CurrentSample?
    private var lastSample: MouseSample?
    private var reversalTimes: [TimeInterval] = []
}
