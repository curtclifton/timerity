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
    static let commandKey = "commandType"
    static let timerIDKey = "timerID"

    public let commandType: TimerCommandType
    public let timer: Timer
    
    public func send() {
        WKInterfaceController.openParentApplication(self.encode()) { result, error in
            println("got callback with result: “\(result)”")
            println("and error: “\(error)”")
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
    public func encode() -> [String : AnyObject] {
        var payload: [String: AnyObject] = commandType.encode()
        payload.merge(timer.encode())
        return [JSONKey.TimerCommand: payload]
    }
}

extension TimerCommand: JSONDecodable {
    typealias ResultType = TimerCommand
    public static func decodeJSONData(jsonData: [String : AnyObject], sourceURL: NSURL? = nil) -> Either<TimerCommand, TimerError> {
        // CCC, 1/4/2015. implement
        return Either.Right(Box(wrap: TimerError.Decoding("not yet implement")))
    }
}

extension TimerCommandType: JSONEncodable {
    public func encode() -> [String : AnyObject] {
            return [TimerCommand.commandKey: rawValue]
    }
}

extension TimerCommandType: JSONDecodable {
    typealias ResultType = TimerCommandType
    public static func decodeJSONData(jsonData: [String : AnyObject], sourceURL: NSURL? = nil) -> Either<TimerCommandType, TimerError> {
        // CCC, 1/4/2015. implement
        return Either.Right(Box(wrap: TimerError.Decoding("not yet implement")))
    }
}

