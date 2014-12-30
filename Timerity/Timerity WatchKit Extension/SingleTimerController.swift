//
//  SingleTimerController.swift
//  Timerity
//
//  Created by Curt Clifton on 12/29/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import WatchKit
import TimerityData

struct SingleTimerController {
    var timer: TimerInformation?
    private var timerUpdateCallbackID: TimerChangeCallbackID?
    
    // outlets
    var nameLabel: WKInterfaceLabel
    var totalTimeLabel: WKInterfaceLabel
    var countdownTimer: WKInterfaceTimer
    var startButton: WKInterfaceButton?
    
    init(nameLabel: WKInterfaceLabel, totalTimeLabel: WKInterfaceLabel, countdownTimer: WKInterfaceTimer, startButton: WKInterfaceButton? = nil) {
        self.nameLabel = nameLabel
        self.totalTimeLabel = totalTimeLabel
        self.countdownTimer = countdownTimer
        self.startButton = startButton
    }
    
    // CCC, 12/29/2014. Maybe this should be setTimer. Is there any advantage in exposing the timerID? Why not just pass around timers?
    mutating func setTimerID(timerID: String) {
        _clearCurrentTimerCallback()
        let registrationResult = timerDB.registerCallbackForTimer(identifier: timerID) { newTimer in
            self.timer = newTimer
            self.timerDidUpdate()
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
    
    mutating func startTimer() {
        if var timer = self.timer {
            timer.start()
            timerDB.updateTimer(timer) // triggers a callback that updates the UI
            let startCommand = TimerCommand.Start
            startCommand.send(timer)
        }
    }
    
    mutating func clearTimerID() {
        _clearCurrentTimerCallback()
        timer = nil
    }
    
    private func timerDidUpdate() {
        if let timer = self.timer {
            println("yay! \(timer)");
            nameLabel.setText(timer.name)
            if (timer.isActive) {
                if let fireDate = timer.fireDate {
                    countdownTimer.setDate(fireDate)
                    countdownTimer.start()
                }
                totalTimeLabel.setHidden(true)
                countdownTimer.setHidden(false)
                startButton?.setHidden(true)
            } else {
                totalTimeLabel.setText(timer.duration.description) // CCC, 12/23/2014. add function for formatting a duration nicely
                totalTimeLabel.setHidden(false)
                countdownTimer.setHidden(true)
                startButton?.setHidden(false)
            }
        } else {
            println("Eep, no timer")
            nameLabel.setText(NSLocalizedString("Missing timer", comment: "missing timer row label"))
            totalTimeLabel.setHidden(true)
            countdownTimer.setHidden(true)
            startButton?.setHidden(true)
        }
    }

    private mutating func _clearCurrentTimerCallback() {
        if let currentCallbackID = timerUpdateCallbackID {
            timerDB.unregisterCallback(identifier: currentCallbackID)
            timerUpdateCallbackID = nil
        }
    }
}
