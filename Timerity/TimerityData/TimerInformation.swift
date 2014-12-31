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
    private var isActive: Bool = false
    public var timeRemaining: Duration = Duration()
    private var isPaused: Bool = false
    public var fireDate: NSDate?
    public let id: String
    
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

// TODO: Lose this gross hack once Swift's IR gen is fixed. (See Either<T,U> below)
public struct Box<T> {
    private var valueInABox: [T]
    init(wrap: T) {
        valueInABox = [wrap]
    }
    public var unwrapped: T {
        return valueInABox.first!
    }
}

// CCC, 12/29/2014. sides should be uppercase
public enum Either<T,U> {
    case left(Box<T>) // TODO: Lose this wrapping box that's here to hack around Swift's "Unimplemented IR generation feature non-fixed multi-payload enum layout" bug.
    case right(Box<U>)
}

public typealias TimerChangeCallback = TimerInformation -> () // CCC, 12/23/2014. might want Either<TimerInformation, Bool> here to signal deletion
public typealias TimerError = String // CCC, 12/23/2014. want an enum here

public struct TimerChangeCallbackID {
    let value: Int
}

//! Mutable timer database.
public class TimerData {
    public var timers: [TimerInformation]
    /// maps timer IDs to indices in the timers array
    private var timerIndex: [String: Int]
    
    private var originalURL: NSURL?
    
    private var nextCallbackID = 0
    private var callbacksByCallbackID: [Int: TimerChangeCallback] = [:]
    private var callbackIDsByTimerID: [String: [Int]] = [:]

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
        return TimerData(timers: timers, url: url)
    }
    
    private init(timers: [TimerInformation], url: NSURL? = nil) {
        originalURL = url
        self.timers = timers
        timerIndex = [:]
        for (index, timer) in enumerate(timers) {
            assert(timerIndex[timer.id] == nil, "timer IDs must be unique, \(timer.id) is not.")
            timerIndex[timer.id] = index
        }
    }
    
    public init() {
        timers = []
        timerIndex = [:]
    }
    
    //MARK: - Mutation
    public func writeToURL(url: NSURL) { // CCC, 12/14/2014. return a success code, error?
        // CCC, 12/30/2014. be sure that this atomically and synchronously updates the data file (else use CPS)
    }

    public func updateTimer(timer: TimerInformation) {
        if let index = timerIndex[timer.id] {
            // CCC, 12/30/2014. Decide what sort of operation this is, pass the appropriate command to the main app. Let the write back trigger the UI update.
//            let startCommand = TimerCommand.Start
//            startCommand.send(timer)
            timers[index] = timer
            if let url = originalURL {
                self.writeToURL(url)
            }
            _invokeCallbacks(timer: timer)
        } else {
            // CCC, 12/30/2014. This should probably just add the new timer.
            assert(false, "no existing timer with id \(timer.id)")
        }
    }

    //MARK: - Callbacks
    /// If there exists a timer wtih the given identifier, then callback function is invoked immediately and whenever the given timer changes in the database. The return value is either a unique integer that can be used to de-register the callback or else an error.
    public func registerCallbackForTimer(#identifier: String, callback: TimerChangeCallback) -> Either<TimerChangeCallbackID, TimerError> {
        switch _timer(identifier: identifier) {
        case .left(let timerBox):
            let callbackID = nextCallbackID
            ++nextCallbackID
            callbacksByCallbackID[callbackID] = callback
            if var callbacksForTimer = callbackIDsByTimerID[identifier] {
                callbacksForTimer.append(callbackID)
                callbackIDsByTimerID[identifier] = callbacksForTimer
            } else {
                callbackIDsByTimerID[identifier] = [callbackID]
            }
            let timerInfo = timerBox.unwrapped
            callback(timerInfo)
            return Either.left(Box(wrap: TimerChangeCallbackID(value: callbackID)))
        case .right(let errorBox):
            return Either.right(errorBox)
        }
    }

    public func unregisterCallback(#identifier: TimerChangeCallbackID) {
        callbacksByCallbackID[identifier.value] = nil
        // we wait until invocation time to clean up callbackIDsByTimerID
    }
    
    //MARK: - Private API
    private func _invokeCallbacks(#timer: TimerInformation) {
        if let callbackIDs = callbackIDsByTimerID[timer.id] {
            var validCallbackIDs:[Int] = []
            for callbackID in callbackIDs {
                if let callback = callbacksByCallbackID[callbackID] {
                    validCallbackIDs.append(callbackID)
                    callback(timer)
                }
            }
            callbackIDsByTimerID[timer.id] = validCallbackIDs
        }
    }
    
    private func _timer(#identifier: String) -> Either<TimerInformation, TimerError> {
        if let index = timerIndex[identifier] {
            return Either.left(Box(wrap: timers[index]))
        } else {
            return Either.right(Box(wrap: "no timer with id \(identifier)"))
        }
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

