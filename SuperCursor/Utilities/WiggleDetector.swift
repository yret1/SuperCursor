//
//  WiggleDetector.swift
//  SuperCursor
//
//  Created by Simon Gustavsson on 2026-10-21.
//
import Foundation

/// How hard and how fast the pointer must be shaken. Backed by the values in Settings.
struct WiggleSettings: Equatable {
    var requiredReversals = 4
    var minSegmentDistance = 40.0
    var timeFrame: TimeInterval = 1.0

    static let defaults = WiggleSettings()

    /// Reads the saved settings, using the defaults for anything not saved yet.
    static func load(from store: UserDefaults) -> WiggleSettings {
        WiggleSettings(
            requiredReversals: store.object(forKey: SettingsKey.requiredReversals) as? Int
                ?? defaults.requiredReversals,
            minSegmentDistance: store.object(forKey: SettingsKey.minSegmentDistance) as? Double
                ?? defaults.minSegmentDistance,
            timeFrame: store.object(forKey: SettingsKey.timeFrame) as? Double
                ?? defaults.timeFrame
        )
    }
}

/// One continuous horizontal stroke.
struct Segment {
    var direction: Direction
    var distance: Double
    var counted = false
}

struct WiggleDetector {
    var settings: WiggleSettings

    /// Backwards movement shorter than this is treated as hand jitter and doesn't end the stroke.
    static let jitterTolerance = 4.0

    // Private state
    private var currentSegment: Segment?
    private var previousSegmentWasLongEnough = false
    private var pendingReverseDistance = 0.0
    private var lastSample: MouseSample?
    private var reversalTimes: [TimeInterval] = []

    init(settings: WiggleSettings = .defaults) {
        self.settings = settings
    }

    mutating func process(_ sample: MouseSample) -> Bool {

        // Guard first call so that we always have a previous sample
        guard let prev = lastSample else {
            lastSample = sample
            return false
        }
        lastSample = sample

        // Vertical only movement
        guard let movement = evaluateDirection(from: prev, to: sample) else {
            return false
        }

        guard var segment = currentSegment else {
            currentSegment = Segment(direction: movement.direction, distance: movement.distance)
            return false
        }

        if movement.direction == segment.direction {
            segment.distance += movement.distance
            pendingReverseDistance = 0
        } else {
            pendingReverseDistance += movement.distance
            if pendingReverseDistance < Self.jitterTolerance {
                return false
            }
            previousSegmentWasLongEnough = segment.distance >= settings.minSegmentDistance
            segment = Segment(direction: movement.direction, distance: pendingReverseDistance)
            pendingReverseDistance = 0
        }

        // A direction change counts once a stroke covers the minimum distance
        // right after another stroke that did too.
        if !segment.counted, previousSegmentWasLongEnough,
            segment.distance >= settings.minSegmentDistance
        {
            segment.counted = true
            reversalTimes.append(sample.timestamp)
        }
        currentSegment = segment

        // Remove reversals outside the timeframe
        let cutoff = sample.timestamp - settings.timeFrame
        reversalTimes.removeAll { $0 < cutoff }

        // Fire the supercursor :)
        if reversalTimes.count >= settings.requiredReversals {
            reset()
            return true
        }
        return false
    }

    private mutating func reset() {
        currentSegment = nil
        previousSegmentWasLongEnough = false
        pendingReverseDistance = 0
        lastSample = nil
        reversalTimes.removeAll()
    }
}
