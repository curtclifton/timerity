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
    private var timerUpdateCallbackID: TimerChangeCallbackID?
    
    // outlets
    @IBOutlet var nameLabel: WKInterfaceLabel?
    @IBOutlet var totalTimeLabel: WKInterfaceLabel?
    @IBOutlet var countdownTimer: WKInterfaceTimer?
    
    var timerID: String? {
        get {
            return timer?.id
        }
        set {
            if let currentCallbackID = timerUpdateCallbackID {
                timerDB.unregisterCallback(identifier: currentCallbackID)
                timerUpdateCallbackID = nil
            }
            if let value = newValue {
                let registrationResult = timerDB.registerCallbackForTimer(identifier: value) {
                    newTimer in self.timer = newTimer
                    self.updateUserInterface()
                }
                switch registrationResult {
                case .left(let callbackIDBox):
                    timerUpdateCallbackID = callbackIDBox.unwrapped
                    break;
                case .right(let errorBox):
                    println("Error getting information for timer: \(errorBox.unwrapped)")
                    timer = nil
                    break;
                }
            }
        }
    }
    
    private func updateUserInterface() {
        if let timer = self.timer {
            println("yay! \(timer)");
            nameLabel!.setText(timer.name)
            if (timer.isActive) {
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
            totalTimeLabel!.setHidden(true)
            countdownTimer!.setHidden(true)
            nameLabel!.setText(NSLocalizedString("Missing timer", comment: "missing timer row label"))
        }
    }
    
    deinit {
        // CCC, 12/23/2014. clear current callback
    }
}
