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

public typealias TimerChangeCallback = Timer? -> ()

public struct TimerChangeCallbackID {
    let value: Int
}

//! Mutable timer database.
public class TimerData {
    public var timers: [Timer]
    /// maps timer IDs to indices in the timers array
    private var timerIndex: [String: Int]
    /// A sparse "array" of NSTimer instances counting down with the active timers, used to update timer state when timers expire.
    private var timerTimers: [Int: NSTimer] = [:]
    
    private var originalURL: NSURL?
    
    private var nextCallbackID = 0
    private var callbacksByCallbackID: [Int: TimerChangeCallback] = [:]
    private var callbackIDsByTimerID: [String: [Int]] = [:]
    private var databaseChangeCallbacksByCallbackID: [Int: (() -> ())] = [:]
    
    //MARK: - Initialization
    public class func fromURL(url: NSURL) -> Either<TimerData, TimerError> {
        // CCC, 12/14/2014. Need to do file coordination on the file and call the registered callbacks as needed
        // CCC, 1/2/2015. On reload via file coordination, maintain the original order, but insert any new timers at the start?
        var error: NSError?
        let maybeRawData = NSData(contentsOfURL: url, options: nil, error: &error)
        if let rawData = maybeRawData {
            let maybeJSONData: AnyObject? = NSJSONSerialization.JSONObjectWithData(rawData, options: nil, error: &error)
            if let jsonData: AnyObject = maybeJSONData {
                if let jsonDictionary = jsonData as? [String:AnyObject] {
                    return TimerData.decodeJSONData(jsonDictionary, sourceURL: url)
                } else {
                    return Either.Right(Box(wrap: TimerError.Decoding("invalid data file contents, expected top-level dictionary, got \(jsonData)")))
                }
            } else {
                return Either.Right(Box(wrap: TimerError.FileError(error!)))
            }
        } else {
            return Either.Right(Box(wrap: TimerError.FileError(error!)))
        }
    }
    
    private init(timers: [Timer], url: NSURL? = nil) {
        originalURL = url
        self.timers = timers
        timerIndex = TimerData._rebuiltIndexForTimers(timers)
        for (index, timer) in enumerate(timers) {
            switch timer.state {
            case .Active(fireDate: let fireDate):
                if fireDate.timeIntervalSinceNow < 0 {
                    // Oops. Already expired. Since no call-backs can be registered yet, just reset the timer.
                    self.timers[index].reset()
                } else {
                    timerTimers[index] = NSTimer.scheduledTimerWithFireDate(fireDate, handler: _timerExpirationHandlerForIndex(index))
                }
                break;
            default:
                break;
            }
        }
    }
    
    public convenience init() {
        self.init(timers: [], url: nil)
    }
    
    //MARK: - Mutation
    public func writeToURL(url: NSURL) -> NSError? {
        let dataDictionary = self.encode()
        var error: NSError?
        let maybeJSONData = NSJSONSerialization.dataWithJSONObject(dataDictionary, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
        if let jsonData = maybeJSONData {
            // CCC, 1/2/2015. do a coordinated write to the file
            if jsonData.writeToURL(url, options: NSDataWritingOptions.DataWritingAtomic, error: &error) {
                return nil
            } else {
                println("error writing JSON to file: \(error)")
                return error
            }
        } else {
            println("error encoding JSON data: \(error)")
            return error
        }
    }
    
    public func updateTimer(var timer: Timer) {
        if let index = timerIndex[timer.id] {
            // CCC, 12/30/2014. Decide what sort of operation this is, pass the appropriate command to the main app. Let the write back trigger the database update and callbacks.
            //            let command = TimerCommand.Start
            //            command.send(timer)
            if let timerTimer = timerTimers[index] {
                timerTimer.invalidate()
                timerTimers[index] = nil
            }
            switch timer.state {
            case .Active(fireDate: let fireDate):
                if fireDate.timeIntervalSinceNow < 0 {
                    timer.reset()
                } else {
                    timerTimers[index] = NSTimer.scheduledTimerWithFireDate(fireDate, handler: _timerExpirationHandlerForIndex(index))
                }
                break;
            default:
                break;
            }
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
            switch timer.state {
            case .Active(fireDate: let fireDate):
                if fireDate.timeIntervalSinceNow < 0 {
                    timer.reset()
                } else {
                    let timerTimer = NSTimer.scheduledTimerWithFireDate(fireDate, handler: _timerExpirationHandlerForIndex(0))
                    var timerTimers: [Int: NSTimer] = [:]
                    for oldIndex in self.timerTimers.keys {
                        timerTimers[oldIndex + 1] = self.timerTimers[oldIndex]
                    }
                    timerTimers[0] = timerTimer
                    self.timerTimers = timerTimers
                }
                break;
            default:
                break;
            }
            let newIndex = timers.count
            timers.insert(timer, atIndex: 0)
            timerIndex = TimerData._rebuiltIndexForTimers(timers)
            if let url = originalURL {
                self.writeToURL(url)
            }
            _invokeDatabaseReloadCallbacks()
        }
    }
    
    public func deleteTimer(timer: Timer) {
        if let index = timerIndex[timer.id] {
            // CCC, 12/30/2014. Pass Delete command to the main app. Let the write back trigger the database and UI update.
            //            let command = TimerCommend.Delete
            //            command.send(timer)
            timers.removeAtIndex(index)

            if let timerTimer = self.timerTimers[index] {
                timerTimer.invalidate()
                self.timerTimers[index] = nil
            }
            var timerTimers: [Int: NSTimer] = [:]
            for oldIndex in self.timerTimers.keys {
                if oldIndex >= index {
                    timerTimers[oldIndex - 1] = self.timerTimers[oldIndex]
                }
            }
            self.timerTimers = timerTimers

            timerIndex = TimerData._rebuiltIndexForTimers(timers)
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
    private class func _rebuiltIndexForTimers(timers: [Timer]) -> [String: Int] {
        var newTimerIndex: [String: Int] = [:]
        for (index, timer) in enumerate(timers) {
            assert(newTimerIndex[timer.id] == nil, "timer IDs must be unique, \(timer.id) is not.")
            newTimerIndex[timer.id] = index
        }
        return newTimerIndex
    }
    
    private func _invokeCallbacks(#timer: Timer, isDeleted deleted: Bool = false) {
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
    
    private func _timer(#identifier: String) -> Either<Timer, TimerError> {
        if let index = timerIndex[identifier] {
            return Either.Left(Box(wrap: timers[index]))
        } else {
            return Either.Right(Box(wrap: TimerError.MissingIdentifier(identifier)))
        }
    }
    
    private func _timerExpirationHandlerForIndex(index: Int) -> (NSTimer! -> Void) {
        return { [weak self] scheduledTimer in
            if let strongSelf = self {
                var currentTimer = strongSelf.timers[index]
                currentTimer.reset()
                strongSelf.updateTimer(currentTimer)
            }
        }
    }
}

extension TimerData: JSONEncodable {
    func encode() -> [String : AnyObject] {
        let encodedTimers = timers.map() { $0.encode() }
        return [JSONKey.TimerData: encodedTimers]
    }
}

private extension Array {
    func emap<U>(f: T -> Either<U, TimerError>) -> Either<[U], TimerError> {
        var resultArray: [U] = []
        for element in self {
            let maybeResult = f(element)
            switch maybeResult {
            case .Left(let resultBox):
                resultArray.append(resultBox.unwrapped)
                break;
            case .Right(let errorBox):
                return .Right(errorBox)
            }
        }
        return Either.Left(Box(wrap: resultArray))
    }
}

extension TimerData: JSONDecodable {
    typealias ResultType = TimerData
    class func decodeJSONData(jsonData: [String:AnyObject], sourceURL: NSURL? = nil) -> Either<TimerData, TimerError> {
        let maybeEncodedTimers: AnyObject? = jsonData[JSONKey.TimerData]
        if let encodedTimers = maybeEncodedTimers as? [[String: AnyObject]] {
            let maybeTimers = encodedTimers.emap() { Timer.decodeJSONData($0) }
            switch maybeTimers {
            case .Left(let timersBox):
                let timers = timersBox.unwrapped
                let sortedTimers = timers.sorted() { left, right in
                    var result: Bool
                    switch (left.state, right.state) {
                    case (.Active(fireDate: let leftFireDate), .Active(fireDate: let rightFireDate)):
                        println("comparing: \(left.name) firing at \(leftFireDate)")
                        println("           with: \(right.name) firing at \(rightFireDate)")
                        result = leftFireDate.compare(rightFireDate) == NSComparisonResult.OrderedAscending
                        break
                    case (.Active, _):
                        println("comparing: \(left.name) which is active (\(left.isActive))")
                        println("           with: \(right.name) which is not (\(right.isActive))")
                        result = true
                        break
                    case (_, .Active):
                        println("comparing: \(left.name) which is not active (\(left.isActive))")
                        println("           with: \(right.name) which is (\(right.isActive))")
                        result = false
                        break
                    default:
                        println("comparing: \(left.name) last modified on \(left.lastModified)")
                        println("           with: \(right.name) last modified on \(right.lastModified)")
                        result = left.lastModified.compare(right.lastModified) == NSComparisonResult.OrderedAscending
                        break;
                    }
                    let modifier = result ? "" : "not "
                    println("left is \(modifier)ordered before right")
                    return result
                }
                return .Left(Box(wrap:TimerData(timers: sortedTimers, url: sourceURL)))
            case .Right(let timerErrorBox):
                return .Right(timerErrorBox)
            }
        } else {
            return Either.Right(Box(wrap: TimerError.Decoding("missing all timer data")))
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

