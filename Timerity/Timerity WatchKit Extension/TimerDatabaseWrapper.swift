//
//  TimerDatabaseWrapper.swift
//  Timerity
//
//  Created by Curt Clifton on 12/23/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import Foundation
import TimerityData

// CCC, 12/23/2014. fix this constant
let timerDatabaseURL = NSURL(fileURLWithPath: "/example.txt", isDirectory: false)

func spinUpTimerDB() -> TimerData {
    if let url = timerDatabaseURL {
        return TimerData.fromURL(url)
    } else {
        // CCC, 12/23/2014. handle error case
        return TimerData()
    }
}

let timerDB = spinUpTimerDB()
