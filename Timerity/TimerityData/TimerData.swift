//
//  TimerData.swift
//  Timerity
//
//  Created by Curt Clifton on 1/1/15.
//  Copyright (c) 2015 curtclifton.net. All rights reserved.
//

import Foundation

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

public enum Either<T,U> {
    case Left(Box<T>) // TODO: Lose this wrapping box that's here to hack around Swift's "Unimplemented IR generation feature non-fixed multi-payload enum layout" bug.
    case Right(Box<U>)
}

public typealias TimerChangeCallback = TimerInformation? -> ()

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
    // CCC, 1/1/2015. This probably leaks because callbacks retain their creators and the database instance is global. Could mitigate if we're faithful about unregister callbacks, but if we do that in deinit it will never happen.
    private var callbacksByCallbackID: [Int: TimerChangeCallback] = [:]
    private var callbackIDsByTimerID: [String: [Int]] = [:]
    private var databaseChangeCallbacksByCallbackID: [Int: (() -> ())] = [:]
    
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
        timerIndex = TimerData._rebuiltTimerIndex(timers)
    }
    
    public convenience init() {
        self.init(timers: [], url: nil)
    }
    
    //MARK: - Mutation
    public func writeToURL(url: NSURL) { // CCC, 12/14/2014. return a success code, error?
        // CCC, 12/30/2014. be sure that this atomically and synchronously updates the data file (else use CPS)
    }
    
    public func updateTimer(timer: TimerInformation) {
        if let index = timerIndex[timer.id] {
            // CCC, 12/30/2014. Decide what sort of operation this is, pass the appropriate command to the main app. Let the write back trigger the database and UI update.
            //            let command = TimerCommand.Start
            //            command.send(timer)
            timers[index] = timer
            if let url = originalURL {
                self.writeToURL(url)
            }
            _invokeCallbacks(timer: timer)
        } else {
            // CCC, 12/30/2014. Pass Add command to the main app. Let the write back trigger the database and UI update.
            //            let command = TimerCommend.Add
            //            command.send(timer)
            // Add the new timer to the head of the list
            let newIndex = timers.count
            timers.insert(timer, atIndex: 0)
            timerIndex = TimerData._rebuiltTimerIndex(timers)
            _invokeDatabaseReloadCallbacks()
        }
    }
    
    public func deleteTimer(timer: TimerInformation) {
        if let index = timerIndex[timer.id] {
            // CCC, 12/30/2014. Pass Delete command to the main app. Let the write back trigger the database and UI update.
            //            let command = TimerCommend.Delete
            //            command.send(timer)
            timers.removeAtIndex(index)
            timerIndex = TimerData._rebuiltTimerIndex(timers)
            if let url = originalURL {
                self.writeToURL(url)
            }
            _invokeCallbacks(timer: timer, isDeleted: true)
        }
    }
    
    //MARK: - Callbacks
    /// If there exists a timer wtih the given identifier, then callback function is invoked immediately and whenever the given timer changes in the database. The return value is either a unique integer that can be used to de-register the callback or else an error.
    public func registerCallbackForTimer(#identifier: String, callback: TimerChangeCallback) -> Either<TimerChangeCallbackID, TimerError> {
        switch _timer(identifier: identifier) {
        case .Left(let timerBox):
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
            return Either.Left(Box(wrap: TimerChangeCallbackID(value: callbackID)))
        case .Right(let errorBox):
            return Either.Right(errorBox)
        }
    }
    
    public func unregisterCallback(#identifier: TimerChangeCallbackID) {
        callbacksByCallbackID[identifier.value] = nil
        // we wait until invocation time to clean up callbackIDsByTimerID
        databaseChangeCallbacksByCallbackID[identifier.value] = nil
    }
    
    public func registerDatabaseReloadCallback(callback: () -> ()) -> TimerChangeCallbackID {
        let callbackID = nextCallbackID
        ++nextCallbackID
        databaseChangeCallbacksByCallbackID[callbackID] = callback
        return TimerChangeCallbackID(value: callbackID)
    }
    
    //MARK: - Private API
    private class func _rebuiltTimerIndex(timers: [TimerInformation]) -> [String: Int] {
        var newTimerIndex: [String: Int] = [:]
        for (index, timer) in enumerate(timers) {
            assert(newTimerIndex[timer.id] == nil, "timer IDs must be unique, \(timer.id) is not.")
            newTimerIndex[timer.id] = index
        }
        return newTimerIndex
    }
    
    private func _invokeCallbacks(#timer: TimerInformation, isDeleted deleted: Bool = false) {
        if let callbackIDs = callbackIDsByTimerID[timer.id] {
            var validCallbackIDs:[Int] = []
            for callbackID in callbackIDs {
                if let callback = callbacksByCallbackID[callbackID] {
                    validCallbackIDs.append(callbackID)
                    callback(deleted ? nil : timer)
                    if deleted {
                        callbacksByCallbackID[callbackID] = nil
                    }
                }
            }
            callbackIDsByTimerID[timer.id] = deleted ? nil : validCallbackIDs
        }
    }
    
    private func _invokeDatabaseReloadCallbacks() {
        for callback in databaseChangeCallbacksByCallbackID.values {
            callback()
        }
    }
    
    private func _timer(#identifier: String) -> Either<TimerInformation, TimerError> {
        if let index = timerIndex[identifier] {
            return Either.Left(Box(wrap: timers[index]))
        } else {
            return Either.Right(Box(wrap: TimerError.MissingIdentifier(identifier)))
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

