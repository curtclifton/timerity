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
    static let commandKey = "command"
    static let timerIDKey = "timerID"

    let commandType: TimerCommandType
    let timer: Timer
    
    public func send() {
        var payload: [String: AnyObject] = commandType.encode()
        payload.merge(timer.encode())
        WKInterfaceController.openParentApplication(payload) { result, error in
            println("got callback with result: “\(result)”")
            println("and error: “\(error)”")
            // CCC, 12/30/2014. implement
        }
    }
}

public enum TimerCommandType: String {
    case Start = "start"
    case Pause = "pause"
    case Delete = "delete"
    case Reset = "reset"
    case Add = "add"
    case Replace = "replace"
}

extension TimerCommandType: JSONEncodable {
    func encode() -> [String : AnyObject] {
            return [TimerCommand.commandKey: rawValue]
    }
}

extension TimerCommandType: JSONDecodable {
    typealias ResultType = TimerCommandType
    static func decodeJSONData(jsonData: [String : AnyObject], sourceURL: NSURL?) -> Either<TimerCommandType, TimerError> {
        // CCC, 1/4/2015. implement
        return Either.Right(Box(wrap: TimerError.Decoding("not yet implement")))
    }
}

