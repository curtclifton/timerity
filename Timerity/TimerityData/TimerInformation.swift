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
    
    public let seconds: Int
    
    public var hoursMinutesSeconds: (hours: Int, minutes: Int, seconds: Int) {
        get {
            let fractionalHours = Double(seconds) / Double(Duration.secondsPerHour)
            let wholeHours = Int(floor(fractionalHours))
            let secondsRemaining = seconds - wholeHours * Duration.secondsPerHour
            let fractionalMinutes = Double(secondsRemaining) / Double(Duration.secondsPerMinute)
            let wholeMinutes = Int(floor(fractionalMinutes))
            let wholeSeconds = secondsRemaining - wholeMinutes * Duration.secondsPerMinute
            return (wholeHours, wholeMinutes, wholeSeconds)
        }
    }
    
    public init(hours : Int = 0, minutes: Int = 0, seconds: Int = 0) {
        self.seconds = hours * Duration.secondsPerHour + minutes * Duration.secondsPerMinute + seconds
        assert(self.seconds >= 0, "cannot have a negative duration")
    }
}

public struct TimerInformation {
    public var name: String
    public var duration: Duration
    public var isActive: Bool = false
    public var timeRemaining: Duration = Duration()
    public var isPaused: Bool = false
    public var fireDate: NSDate?
    public let id: String
    
    init(name: String, duration: Duration) {
        self.name = name
        self.duration = duration
        id = CFUUIDCreateString(kCFAllocatorDefault, CFUUIDCreate(kCFAllocatorDefault))
    }
}

//! The global timer database.
// CCC, 12/14/2014. Does this really need to be a global?
public class TimerData {
    public var timers: [TimerInformation]
    
    public class func fromURL(url: NSURL) -> TimerData {
        // CCC, 12/14/2014. stub in to return test data
        var timers: [TimerInformation] = []
        timers.append(TimerInformation(name: "Tea", duration: Duration(minutes: 3)))
        timers.append(TimerInformation(name: "Power Nap", duration: Duration(minutes: 20)))
        // CCC, 12/14/2014. implement for reals
        return TimerData(timers: timers)
    }
    
    private init(timers: [TimerInformation]) {
        self.timers = timers
    }
    
    public func writeToURL(url: NSURL) { // CCC, 12/14/2014. return a success code, error?
        // CCC, 12/14/2014. implement
    }
}

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

// MARK: Printable, DebugPrintable extensions

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

extension TimerData: Printable, DebugPrintable {
    public var description: String {
        get {
            var result: String = "TimerData:\n"
            for (i, timer) in enumerate(timers) {
                result += timer.description
                if i < timers.count - 1 {
                    result += "\n"
                }
            }
            return result
        }
    }
    
    public var debugDescription: String {
        get {
            return description
        }
    }
}
