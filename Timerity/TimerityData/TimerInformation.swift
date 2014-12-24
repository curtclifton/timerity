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

// CCC, 12/23/2014. Gross hack box of buggy IR gen
public struct Box<T> {
    private var valueInABox: [T]
    init(wrap: T) {
        valueInABox = [wrap]
    }
    public var unwrapped: T {
        return valueInABox.first!
    }
}

public enum Either<T,U> {
    case left(value: Box<T>) // CCC, 12/23/2014. Box is a hack. oh, swift
    case right(value: Box<U>)
}

public typealias TimerChangeCallback = TimerInformation -> () // CCC, 12/23/2014. might want Either<TimerInformation, Bool> here to signal deletion
public typealias TimerError = String // CCC, 12/23/2014. want an enum here

public struct TimerChangeCallbackID {
    let value: Int
}

//! Mutable timer database.
public class TimerData {
    public var timers: [TimerInformation]
    private var nextCallbackID = 0
    private var callbacks: [Int: TimerChangeCallback] = [:] // CCC, 12/23/2014. We'll also need a mapping from timer identifiers to registered callbacks

    
    //MARK: - Initialization
    public class func fromURL(url: NSURL) -> TimerData {
        var timers: [TimerInformation] = []

        var activeTimer = TimerInformation(name: "Break Time", duration: Duration(hours: 1, minutes: 3))
        activeTimer.isActive = true
        activeTimer.timeRemaining = activeTimer.duration
        let fireDate = NSDate(timeIntervalSinceNow: Double(activeTimer.duration.seconds))
        activeTimer.fireDate = fireDate
        
        timers.append(activeTimer)
        timers.append(TimerInformation(name: "Tea", duration: Duration(minutes: 3)))
        timers.append(TimerInformation(name: "Power Nap", duration: Duration(minutes: 20)))
        // CCC, 12/14/2014. implement for reals. Need to do file coordination on the file and call the registered callbacks as needed
        return TimerData(timers: timers)
    }
    
    private init(timers: [TimerInformation]) {
        self.timers = timers
    }
    
    public init() {
        self.timers = []
    }
    
    //MARK: - Mutation
    public func writeToURL(url: NSURL) { // CCC, 12/14/2014. return a success code, error?
        // CCC, 12/14/2014. implement
    }

    // CCC, 12/23/2014. Need API for telling the database that a timer changed

    //MARK: - Callbacks
    //! If there exists a timer wtih the given identifier, then callback function is invoked immediately and whenever the given timer changes in the database. The return value is either a unique integer that can be used to de-register the callback or else an error.
    public func registerCallbackForTimer(#identifier: String, callback: TimerChangeCallback) -> Either<TimerChangeCallbackID, TimerError> {
        switch _timerWithIdentifier(identifier) {
        case .left(let timerBox):
            let callbackID = nextCallbackID
            ++nextCallbackID
            callbacks[callbackID] = callback
            let timerInfo = timerBox.value.unwrapped
            callback(timerInfo)
            return Either.left(value: Box(wrap: TimerChangeCallbackID(value: callbackID)))
        case .right(let errorBox):
            return Either.right(value: errorBox)
        }
    }

    public func unregisterCallback(#identifier: TimerChangeCallbackID) {
        callbacks[identifier.value] = nil
    }
    
    // CCC, 12/23/2014. Need code to call all the callbacks
    
    //MARK: - Private API
    private func _timerWithIdentifier(identifier: String) -> Either<TimerInformation, TimerError> {
        let matchingTimers = timers.filter {
            timer in timer.id == identifier
        }
        switch matchingTimers.count {
        case 0:
            return Either.right(value: Box(wrap: "no timer with id \(identifier)"))
        case 1:
            return Either.left(value: Box(wrap: matchingTimers.first!))
        default:
            return Either.right(value: Box(wrap: "mulitple timers with id \(identifier)"))
        }
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

