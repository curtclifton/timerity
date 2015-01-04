//
//  TimerError.swift
//  Timerity
//
//  Created by Curt Clifton on 1/1/15.
//  Copyright (c) 2015 curtclifton.net. All rights reserved.
//

import Foundation

public enum TimerError {
    case MissingIdentifier(String)
    case Decoding(String)
    case FileError(NSError)
}

extension TimerError: Printable, DebugPrintable {
    public var description: String {
        switch self {
        case .MissingIdentifier(let string):
            return "Missing identifier error: \(string)"
        case .Decoding(let string):
            return "Decoding error: \(string)"
        case .FileError(let error):
            return "File error: \(error)"
        }
    }
    
    public var debugDescription: String {
        return description
    }
}