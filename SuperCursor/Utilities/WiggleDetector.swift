//
//  WiggleDetector.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-21.
//
import Foundation
import Playgrounds
struct Segment {
    var direction: Direction
    var distance: Double
}

struct WiggleDetector {

    // User settable
    var requiredReversals: Int = 4
    var minSegmentDistance: Double = 40
    var timeFrame: TimeInterval = 1

    // Private state
    private var currentSegment: Segment?
    private var lastSample: MouseSample?
    private var reversalTimes: [TimeInterval] = []

    mutating func process(_ sample: MouseSample) -> Bool {
       
        //GUard first call so that we always have a sample
        guard let prev = lastSample else {
            lastSample = sample
            return false
        }
        lastSample = sample

        //Vertical only movement
        guard let movement = evaluateDirection(from: prev, to: sample) else {
            return false
        }

        //If a segment exists but were still going the same way, append distance
        if let segment = currentSegment, segment.direction == movement.direction {
            currentSegment?.distance += movement.distance
            return false
        }

        //Handle no segment or flipped
        if let segment = currentSegment, segment.distance >= minSegmentDistance {
            reversalTimes.append(sample.timestamp)
        }
        currentSegment = Segment(direction: movement.direction, distance: movement.distance)

        //Remove reversals outside the timeframe
        let cutoff = sample.timestamp - timeFrame
        reversalTimes.removeAll { $0 < cutoff }

        //Fire the supercursor :)
        if reversalTimes.count >= requiredReversals {
            reset()
            return true
        }
        return false
    }

    private mutating func reset() {
        currentSegment = nil
        lastSample = nil
        reversalTimes.removeAll()
    }
}

#Playground {
    // Builds samples from x positions, spaced `interval` seconds apart
    func makeSamples(xs: [Double], interval: TimeInterval) -> [MouseSample] {
        xs.enumerated().map { index, x in
            MouseSample(
                position: CGPoint(x: x, y: 0),
                timestamp: Double(index) * interval
            )
        }
    }

    // Feeds samples to a fresh detector and reports where it fires
    func run(_ name: String, _ samples: [MouseSample]) {
        var detector = WiggleDetector()
        print("--- \(name) ---")
        for (index, sample) in samples.enumerated() {
            if detector.process(sample) {
                print("Wiggle detected at sample \(index)")
            }
        }
        print("done")
    }

    run("Fast wiggle", makeSamples(xs: [0, 60, 0, 60, 0, 60], interval: 0.1))
    run("Slow wiggle", makeSamples(xs: [0, 60, 0, 60, 0, 60], interval: 0.5))
    run("Small jitter", makeSamples(xs: [0, 10, 0, 10, 0, 10, 0, 10], interval: 0.1))
}
