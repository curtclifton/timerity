//
//  SingleTimerController.swift
//  Timerity
//
//  Created by Curt Clifton on 12/29/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import WatchKit
import TimerityData

protocol MenuItemPresenter: class {
    func configureMenuForState(timerState: TimerState)
}

class SingleTimerController {
    var timer: Timer?
    private var timerUpdateCallbackID: TimerChangeCallbackID?
    private var isActive = true // we assume that we're initially active so that loading into an already loaded UI causes an update
    private var needsUpdate = false
    
    private var nameLabel: WKInterfaceLabel
    private var totalTimeLabel: WKInterfaceLabel
    private var countdownTimer: WKInterfaceTimer
    private var button: WKInterfaceButton?
    private weak var menuItemPresenter: MenuItemPresenter?
    
    init(nameLabel: WKInterfaceLabel, totalTimeLabel: WKInterfaceLabel, countdownTimer: WKInterfaceTimer, button: WKInterfaceButton? = nil, menuItemPresenter: MenuItemPresenter? = nil) {
        self.nameLabel = nameLabel
        self.totalTimeLabel = totalTimeLabel
        self.countdownTimer = countdownTimer
        self.button = button
        self.menuItemPresenter = menuItemPresenter
    }
    
    deinit {
        _clearCurrentTimerCallback()
    }
    
    //MARK: - Package API
    func willActivate() {
        isActive = true
        _updateIfNeeded()
    }
    
    func didDeactivate() {
        isActive = false
    }
    
    func setTimerID(timerID: String) {
        _clearCurrentTimerCallback()
        let registrationResult = timerDB.registerCallbackForTimer(identifier: timerID) { [weak self] maybeNewTimer in
            if let strongSelf = self {
                if let newTimer = maybeNewTimer {
                    strongSelf.timer = newTimer
                    strongSelf.needsUpdate = true
                    strongSelf._updateIfNeeded()
                } else {
                    strongSelf.timer = nil
                    strongSelf.needsUpdate = true
                }
            }
        }
        switch registrationResult {
        case .Left(let callbackIDBox):
            timerUpdateCallbackID = callbackIDBox.unwrapped
            break;
        case .Right(let errorBox):
            println("Error getting information for timer: \(errorBox.unwrapped)")
            timer = nil
            break;
        }
    }
    
    func buttonPressed() {
        if var timer = self.timer {
            switch timer.state {
            case .Active(fireDate: let fireDate):
                countdownTimer.stop() // the countdown will be removed by the callback, but lets not let the count drop below the cached time remaining
                timer.pause()
                timerDB.updateTimer(timer, commandType: TimerCommandType.Pause) // triggers a callback that updates the UI
                break;
            case .Paused(timeRemaining: let timeRemaining):
                timer.resume()
                break;
            case .Inactive:
                timer.start()
                break;
            }
        }
    }
    
    func clearTimerID() {
        _clearCurrentTimerCallback()
        timer = nil
    }
    
    //MARK: - Private API
    private func _updateIfNeeded() {
        if !needsUpdate || !isActive {
            return;
        }
        if let timer = self.timer {
            println("yay! \(timer)");
            nameLabel.setText(timer.name)
            switch timer.state {
            case .Active(fireDate: let fireDate):
                countdownTimer.setDate(fireDate)
                countdownTimer.start()
                totalTimeLabel.setHidden(true)
                countdownTimer.setHidden(false)
                button?.setTitle(NSLocalizedString("Pause", comment: "pause button label"))
                button?.setHidden(false)
                break;
            case .Paused(timeRemaining: let timeRemaining):
                totalTimeLabel.setText(timeRemaining.formattedString)
                totalTimeLabel.setHidden(false)
                countdownTimer.setHidden(true)
                button?.setTitle(NSLocalizedString("Resume", comment: "resume button label"))
                button?.setHidden(false)
                break;
            case .Inactive:
                totalTimeLabel.setText(timer.duration.formattedString)
                totalTimeLabel.setHidden(false)
                countdownTimer.setHidden(true)
                button?.setTitle(NSLocalizedString("Start", comment: "start button label"))
                button?.setHidden(false)
                break;
            }
            menuItemPresenter?.configureMenuForState(timer.state)
        } else {
            println("Eep, no timer")
            nameLabel.setText(NSLocalizedString("Missing timer", comment: "missing timer row label"))
            totalTimeLabel.setHidden(true)
            countdownTimer.setHidden(true)
            button?.setHidden(true)
        }
        needsUpdate = false
    }

    private func _clearCurrentTimerCallback() {
        if let currentCallbackID = timerUpdateCallbackID {
            timerDB.unregisterCallback(identifier: currentCallbackID)
            timerUpdateCallbackID = nil
        }
    }
}
