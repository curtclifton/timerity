//
//  TimerJSON.swift
//  Timerity
//
//  Created by Curt Clifton on 1/4/15.
//  Copyright (c) 2015 curtclifton.net. All rights reserved.
//

import Foundation

public protocol JSONEncodable {
    /// Result strings should be unique tags for each saved typed. Result values should be encodable per NSJSONSerialization
    func encode() -> [String: AnyObject]
}

public protocol JSONDecodable {
    typealias ResultType
    class func decodeJSONData(jsonData: [String:AnyObject], sourceURL: NSURL?) -> Either<ResultType, TimerError>
}

struct JSONKey {
    static let TimerData = "TimerData"
    static let Timer = "TimerInformation"
    static let TimerCommand = "TimerCommand"
    static let TimerCommandType = "TimerCommandType"
}

