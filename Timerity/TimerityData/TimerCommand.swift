//
//  TimerCommand.swift
//  Timerity
//
//  Created by Curt Clifton on 12/30/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
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
    
    public func send() {
        WKInterfaceController.openParentApplication(self.encodeToJSONData()) { result, error in
            if result != nil {
                NSLog("got callback with result: “%@”", result)
            }
            if error != nil {
                NSLog("got callback with error: “%@”", error)
            }
            // CCC, 12/30/2014. implement
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
                return Either.Left(Box(wrap: TimerCommand(commandType: timerCommandBox.unwrapped, timer: timerBox.unwrapped)))
            default:
                return Either.Right(Box(wrap: TimerError.Decoding("unexpected JSON data: \(payload)")))
            }
        } else {
            return Either.Right(Box(wrap: TimerError.Decoding("missing key “\(JSONKey.TimerCommand)” in JSON data: \(jsonData)")))
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
                return Either.Left(Box(wrap: timerCommandType))
            } else {
                return Either.Right(Box(wrap: TimerError.Decoding("invalid timer command type raw value: \(timerCommandTypeRawValue)")))
            }
        } else {
            return Either.Right(Box(wrap: TimerError.Decoding("missing timer command type key: \(jsonData)")))
        }
    }
}

