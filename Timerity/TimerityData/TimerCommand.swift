//
//  TimerCommand.swift
//  Timerity
//
//  Created by Curt Clifton on 12/30/14.
//  Copyright (c) 2014–2015 curtclifton.net. All rights reserved.
//

import Foundation
import WatchKit

extension Dictionary {
    mutating func merge(other: Dictionary<Key, Value>) {
        for key in other.keys {
            self[key] = other[key]
        }
    }
}

public struct TimerCommand {
    public let commandType: TimerCommandType
    public let timer: Timer
    
    public func sendWithContinuation(continuation: (Either<[String: AnyObject], TimerError> -> Void)) {
        WKInterfaceController.openParentApplication(self.encodeToJSONData()) { maybeResult, maybeError in
            if let jsonResult = maybeResult as? [String: AnyObject] {
                NSLog("got callback with JSON result: “%@”", jsonResult)
                continuation(Either.Left(Box(jsonResult)))
            } else if maybeResult != nil {
                NSLog("got callback with non-JSON result: “%@”", maybeResult!)
                continuation(Either.Right(Box(TimerError.InterprocessCommunicationFormatError("expected JSON, got \(maybeResult)"))))
            } else if let error = maybeError {
                NSLog("got callback with error: “%@”", error)
                continuation(Either.Right(Box(TimerError.InterprocessCommunicationError(error))))
            } else {
                assert(false, "how could this happen?")
            }
        }
    }
}

public enum TimerCommandType: String {
    case Start = "start"
    case Pause = "pause"
    case Resume = "resume"
    case Delete = "delete"
    case Reset = "reset"
    case Add = "add"
    case Replace = "replace"
    case Local = "local"
}

extension TimerCommand: JSONEncodable {
    public func encodeToJSONData() -> [String : AnyObject] {
        var payload: [String: AnyObject] = commandType.encodeToJSONData()
        payload.merge(timer.encodeToJSONData())
        return [JSONKey.TimerCommand: payload]
    }
}

extension TimerCommand: JSONDecodable {
    typealias ResultType = TimerCommand
    public static func decodeJSONData(jsonData: [String : AnyObject]) -> Either<TimerCommand, TimerError> {
        if let payload = jsonData[JSONKey.TimerCommand] as? [String: AnyObject] {
            let maybeCommandType = TimerCommandType.decodeJSONData(payload)
            let maybeTimer = Timer.decodeJSONData(payload)
            switch (maybeCommandType, maybeTimer) {
            case (.Left(let timerCommandBox), .Left(let timerBox)):
                return Either.Left(Box(TimerCommand(commandType: timerCommandBox.contents, timer: timerBox.contents)))
            default:
                return Either.Right(Box(TimerError.Decoding("unexpected JSON data: \(payload)")))
            }
        } else {
            return Either.Right(Box(TimerError.Decoding("missing key “\(JSONKey.TimerCommand)” in JSON data: \(jsonData)")))
        }
    }
}

extension TimerCommandType: JSONEncodable {
    public func encodeToJSONData() -> [String : AnyObject] {
            return [JSONKey.TimerCommandType: rawValue]
    }
}

extension TimerCommandType: JSONDecodable {
    typealias ResultType = TimerCommandType
    public static func decodeJSONData(jsonData: [String : AnyObject]) -> Either<TimerCommandType, TimerError> {
        if let timerCommandTypeRawValue = jsonData[JSONKey.TimerCommandType] as? String {
            if let timerCommandType = TimerCommandType(rawValue: timerCommandTypeRawValue) {
                return Either.Left(Box(timerCommandType))
            } else {
                return Either.Right(Box(TimerError.Decoding("invalid timer command type raw value: \(timerCommandTypeRawValue)")))
            }
        } else {
            return Either.Right(Box(TimerError.Decoding("missing timer command type key: \(jsonData)")))
        }
    }
}

