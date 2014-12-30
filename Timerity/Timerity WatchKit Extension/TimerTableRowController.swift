//
//  TimerTableRowController.swift
//  Timerity
//
//  Created by Curt Clifton on 12/12/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import WatchKit
import TimerityData

class TimerTableRowController: NSObject {
    private var timerController: SingleTimerController?
    
    // outlets
    @IBOutlet var nameLabel: WKInterfaceLabel?
    @IBOutlet var totalTimeLabel: WKInterfaceLabel?
    @IBOutlet var countdownTimer: WKInterfaceTimer?
    
    deinit {
        if var currentTimerController = timerController {
            currentTimerController.clearTimerID()
        }
    }

    //MARK: Package API
    func setTimerID(timerID: String) {
        if var currentTimerController = timerController {
            currentTimerController.clearTimerID()
        }
        timerController = SingleTimerController(nameLabel: nameLabel!, totalTimeLabel: totalTimeLabel!, countdownTimer: countdownTimer!)
        timerController!.setTimerID(timerID)
    }
    
}
