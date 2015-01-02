//
//  TimerInformation.swift
//  Timerity
//
//  Created by Curt Clifton on 12/7/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import Foundation

public struct Duration {
    private static let secondsPerHour: Int = 3600
    private static let secondsPerMinute: Int = 60
    
    public let seconds: Double
    
    public var hoursMinutesSeconds: (hours: Int, minutes: Int, seconds: Int) {
        get {
            let totalSeconds = Int(floor(seconds))
            let fractionalHours = Double(seconds) / Double(Duration.secondsPerHour)
            let wholeHours = Int(floor(fractionalHours))
            let secondsRemaining = totalSeconds - wholeHours * Duration.secondsPerHour
            let fractionalMinutes = Double(secondsRemaining) / Double(Duration.secondsPerMinute)
            let wholeMinutes = Int(floor(fractionalMinutes))
            let wholeSeconds = secondsRemaining - wholeMinutes * Duration.secondsPerMinute
            return (wholeHours, wholeMinutes, wholeSeconds)
        }
    }
    
    public init(hours : Int = 0, minutes: Int = 0, seconds: Int = 0) {
        self.init(seconds: Double(hours * Duration.secondsPerHour + minutes * Duration.secondsPerMinute + seconds))
    }
    
    public init(seconds: Double) {
        assert(seconds >= 0, "cannot have a negative duration")
        self.seconds = seconds
    }
}

public enum TimerState {
    case Active(fireDate: NSDate)
    case Paused(timeRemaining: Duration)
    case Inactive
}

public struct TimerInformation {
    public var name: String
    public var duration: Duration
    public let id: String

    var isActive: Bool = false
    var isPaused: Bool = false

    var timeRemaining: Duration = Duration()
    var fireDate: NSDate?
    
    public var state: TimerState {
        if isActive {
            return TimerState.Active(fireDate: fireDate!)
        } else if isPaused {
            return TimerState.Paused(timeRemaining: timeRemaining)
        } else {
            return TimerState.Inactive
        }
    }
    
    init(name: String, duration: Duration) {
        self.name = name
        self.duration = duration
        id = CFUUIDCreateString(kCFAllocatorDefault, CFUUIDCreate(kCFAllocatorDefault))
    }
    
    public init() {
        self.init(name: NSLocalizedString("Unnamed", comment: "name for unnamed timer"), duration: Duration())
    }
    
    public mutating func start() {
        assert(!isPaused && !isActive)
        isActive = true
        isPaused = false
        fireDate = NSDate(timeIntervalSinceNow: duration.seconds)
        timeRemaining = duration
    }
    
    public mutating func resume() {
        assert(isPaused && !isActive)
        isActive = true
        isPaused = false
        fireDate = NSDate(timeIntervalSinceNow: timeRemaining.seconds)
        timeRemaining = Duration()
    }
    
    public mutating func pause() {
        assert(!isPaused && isActive)
        let timeUntilFireDate = fireDate!.timeIntervalSinceNow
        isActive = false
        isPaused = true
        fireDate = nil
        timeRemaining = Duration(seconds: timeUntilFireDate)
    }
    
    public mutating func reset() {
        isActive = false
        isPaused = false
        fireDate = nil
        timeRemaining = Duration()
    }
}

// MARK: Printable, DebugPrintable extensions

extension TimerInformation: Printable, DebugPrintable {
    public var description: String {
        get {
            return "name:\(name), duration: \(duration.description)"
        }
    }
    
    public var debugDescription: String {
        get {
            return description
        }
    }
}

extension Duration: Printable, DebugPrintable {
    public var description: String {
        get {
            let hms = hoursMinutesSeconds
            return "\(hms.hours)h \(hms.minutes)m \(hms.seconds)s"
        }
    }
    
    public var debugDescription: String {
        get {
            return "Duration: \(seconds) seconds"
        }
    }
}

