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

private func spinUpPresenterQueue() -> NSOperationQueue {
    var result = NSOperationQueue()
    result.maxConcurrentOperationCount = 1
    return result
}

/// lazily initialized global queue
private let filePresenterQueue = spinUpPresenterQueue()

//! Mutable timer database.
public class TimerData: NSObject {
    public var timers: [Timer]
    /// maps timer IDs to indices in the timers array
    private var timerIndex: [String: Int]
    /// A sparse "array" of NSTimer instances counting down with the active timers, used to update timer state when timers expire.
    private var timerTimers: [Int: NSTimer] = [:]
    
    private var originalURL: NSURL?
    private var fileCoordinator: NSFileCoordinator?
    
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
        super.init()
        for (index, timer) in enumerate(timers) {
            switch timer.state {
            case .Active(fireDate: let fireDate):
                if fireDate.timeIntervalSinceNow < 0 {
                    // Oops. Already expired. Since no call-backs can be registered yet, just reset the timer.
                    self.timers[index].reset()
                } else {
                    timerTimers[index] = NSTimer.scheduledTimerWithFireDate(fireDate, handler: _timerExpirationHandlerForIndex(index))
                }
                break
            default:
                break
            }
        }
        if url != nil {
            // CCC, 1/4/2015. This seems late for setting this up. We've already read the file.
            fileCoordinator = NSFileCoordinator(filePresenter: self)
        }
    }
    
    public convenience init(url: NSURL? = nil) {
        self.init(timers: [], url: url)
    }
    
    //MARK: - Mutation
    
    private func write() -> NSError? {
        if originalURL == nil {
            return nil
        }
        NSLog("preparing to write to file")
        let url = originalURL!
        let fileCoordination = self.fileCoordinator!
        var coordinationError: NSError?
        var coordinatedWriteSucceeded = false // assume the worst
        NSLog("beginning coordinated write to file")
        fileCoordinator?.coordinateWritingItemAtURL(url, options: nil, error: &coordinationError) { newURL in
            assert(newURL == url, "don't expect the file to move")
            NSLog("entered writing block")
            let dataDictionary = self.encodeToJSONData()
            var error: NSError?
            let maybeJSONData = NSJSONSerialization.dataWithJSONObject(dataDictionary, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
            if let jsonData = maybeJSONData {
                NSLog("actually writing json data: %@", jsonData)
                if jsonData.writeToURL(url, options: NSDataWritingOptions.DataWritingAtomic, error: &error) {
                    NSLog("successfully wrote json data")
                    coordinatedWriteSucceeded = true
                    NSLog("successfully recorded success");
                } else {
                    NSLog("error writing JSON to file: %@", error!)
                    coordinationError = error
                }
            } else {
                NSLog("error encoding JSON data: %@", error!)
                coordinationError = error
            }
        }
        if coordinatedWriteSucceeded {
            NSLog("successfully finished coordinate write to file")
            return nil
        } else if let error = coordinationError {
            NSLog("coordinated write failed with error: %@", error)
            return error
        } else {
            NSLog("who knows what happened?!");
            return nil
        }
    }
    
    public func updateTimer(var timer: Timer, commandType: TimerCommandType) {
        if let index = timerIndex[timer.id] {
            if commandType == .Local {
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
                    break
                default:
                    break
                }
                timers[index] = timer
                write()
                // CCC, 1/4/2015. these might have to happen in a continuation:
                _invokeCallbacks(timer: timer)
            } else {
                let command = TimerCommand(commandType: commandType, timer: timer)
                command.send()
                // CCC, 1/4/2015. Need to update Watch timerTimers when we get a file coordination reload back
            }
        } else {
            // Unknown ID, so this is an Add operation
            if commandType == .Local {
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
                    break
                default:
                    break
                }
                let newIndex = timers.count
                timers.insert(timer, atIndex: 0)
                timerIndex = TimerData._rebuiltIndexForTimers(timers)
                write()
                // CCC, 1/4/2015. these might have to happen in a continuation
                _invokeDatabaseReloadCallbacks()
            } else {
                assert(commandType == .Add)
                let command = TimerCommand(commandType: TimerCommandType.Add, timer: timer)
                command.send()
                // CCC, 1/4/2015. Need to update Watch timerTimers when we get a file coordination reload back
            }
        }
    }
    
    public func deleteTimer(timer: Timer, commandType: TimerCommandType) {
        if commandType == .Local {
            if let index = timerIndex[timer.id] {
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
                write()
                // CCC, 1/4/2015. these might have to happen in a continuation
                _invokeCallbacks(timer: timer, isDeleted: true)
            }
        } else {
            assert(commandType == .Delete)
            let command = TimerCommand(commandType: TimerCommandType.Delete, timer: timer)
            command.send()
            // CCC, 1/4/2015. Need to update Watch timerTimers when we get a file coordination reload back
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
                strongSelf.updateTimer(currentTimer, commandType: TimerCommandType.Reset)
            }
        }
    }
}

extension TimerData: NSFilePresenter {
    public var presentedItemURL: NSURL? {
        NSLog("somebody is asking for presentedItemURL")
        if let url = originalURL {
            NSLog("It's “%@”", url)
        }
        return originalURL
    }

    public var presentedItemOperationQueue: NSOperationQueue {
        NSLog("somebody is asking for presentedItemOperationQueue")
        return filePresenterQueue
    }
    
    public func relinquishPresentedItemToReader(reader: ((() -> Void)!) -> Void) {
        // CCC, 1/4/2015. implement
        NSLog("relinquishing to reader")
        reader() {
            // anything?
            NSLog("reader is done")
        }
    }
    
    public func relinquishPresentedItemToWriter(writer: ((() -> Void)!) -> Void) {
        // CCC, 1/4/2015. implement
        NSLog("relinquishing to writer")
        writer() {
            // CCC, 1/4/2015. need to reload the contents of the file and send appropriate callbacks. probably should kick over to the main queue to do that
            NSLog("writer is done")
        }
    }
    
    public func presentedItemDidChange() {
        // CCC, 1/4/2015. not sure we need this because we should always get relinquishPresentedItemToWriter (the file is in our sandbox and we're using file coordination in both processes
        NSLog("presentedItemDidChange")
    }
}

extension TimerData: JSONEncodable {
    public func encodeToJSONData() -> [String : AnyObject] {
        let encodedTimers = timers.map() { $0.encodeToJSONData() }
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
                break
            case .Right(let errorBox):
                return .Right(errorBox)
            }
        }
        return Either.Left(Box(wrap: resultArray))
    }
}

extension TimerData: JSONDecodable {
    typealias ResultType = TimerData
    public class func decodeJSONData(jsonData: [String:AnyObject], sourceURL: NSURL? = nil) -> Either<TimerData, TimerError> {
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
                        result = leftFireDate.compare(rightFireDate) == NSComparisonResult.OrderedAscending
                        break
                    case (.Active, _):
                        result = true
                        break
                    case (_, .Active):
                        result = false
                        break
                    default:
                        result = left.lastModified.compare(right.lastModified) == NSComparisonResult.OrderedDescending
                        break
                    }
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

// TODO: can't implement the Swift versions of these on an NSObject subclass?
//extension TimerData: Printable, DebugPrintable {
//    overriding var description: String {
//        get {
//            var result: String = "TimerData:\n"
//            for (i, timer) in enumerate(timers) {
//                result += timer.description
//                if i < timers.count - 1 {
//                    result += "\n"
//                }
//            }
//            return result
//        }
//    }
//    
//    public var debugDescription: String {
//        get {
//            return description
//        }
//    }
//}

