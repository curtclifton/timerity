//
//  TimerDatabaseWrapper.swift
//  Timerity
//
//  Created by Curt Clifton on 12/23/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import Foundation
import TimerityData

let groupURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.net.curtclifton.Timerity")
let timerDatabaseURL = groupURL!.URLByAppendingPathComponent("data.json", isDirectory: false)

func spinUpTimerDB() -> TimerData {
    let timerDataPresenter = TimerDataPresenter(fileURL: timerDatabaseURL)
    let timerData = timerDataPresenter.timerData
    timerDataPresenter.invalidate()
    return timerData
}

/// Lazily loaded global timer database
let timerDB = spinUpTimerDB()
