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
    private var timer: TimerInformation?
    
    // outlets
    @IBOutlet var nameLabel: WKInterfaceLabel?
    @IBOutlet var totalTimeLabel: WKInterfaceLabel?
    @IBOutlet var countdownTimer: WKInterfaceTimer?
    
    var timerID: String? {
        get {
            return timer?.id
        }
        set {
            // CCC, 12/23/2014. clear current callback
            if let value = newValue {
                // CCC, 12/23/2014. get timer and register a call back
                timerDB.registerCallbackForTimer(identifier: value) {
                    newTimer in self.timer = newTimer
                    self.updateUserInterface()
                }
            } else {
                // CCC, 12/23/2014. anything?
            }
        }
    }
    
    private func updateUserInterface() {
        if let timer = self.timer {
            println("yay! \(timer)");
            nameLabel!.setText(timer.name)
            if (timer.isActive) {
                // CCC, 12/23/2014. set fire time of countdownTimer
                if let fireDate = timer.fireDate {
                    countdownTimer!.setDate(fireDate)
                    countdownTimer!.start()
                }
                totalTimeLabel!.setHidden(true)
                countdownTimer!.setHidden(false)
            } else {
                totalTimeLabel!.setText(timer.duration.description) // CCC, 12/23/2014. add function for formatting a duration nicely
                totalTimeLabel!.setHidden(false)
                countdownTimer!.setHidden(true)
            }
        } else {
            println("Eep, no timer")
        }
    }
    
    deinit {
        // CCC, 12/23/2014. clear current callback
    }
}
