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
    case DeserializationError(NSError)
    case InterprocessCommunicationFormatError(String)
    case InterprocessCommunicationError(NSError)
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
        case .DeserializationError(let error):
            return "Deserialization error: \(error)"
        case .InterprocessCommunicationFormatError(let string):
            return "Interprocess communication format error: \(string)"
        case .InterprocessCommunicationError(let error):
            return "Interprocess communication error: \(error)"
        }
    }
    
    public var debugDescription: String {
        return description
    }
}