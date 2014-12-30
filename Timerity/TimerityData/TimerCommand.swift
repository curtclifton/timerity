//
//  TimerCommand.swift
//  Timerity
//
//  Created by Curt Clifton on 12/30/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import Foundation
import WatchKit

public enum TimerCommand: String {
    case Start = "start"
    // CCC, 12/29/2014. Other commands here

    static let commandKey = "command"
    static let timerIDKey = "timerID"
    
    public func send(timer: TimerInformation) {
        let payload: [NSObject: AnyObject] = [TimerCommand.commandKey: self.rawValue, TimerCommand.timerIDKey: timer.id]
        WKInterfaceController.openParentApplication(payload) { result, error in
            println("got callback with result “\(result)” and error “\(error)”")
            // CCC, 12/30/2014. implement
        }
    }
}


