//
//  TimerEditingInterfaceController.swift
//  Timerity
//
//  Created by Curt Clifton on 12/31/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import TimerityData
import WatchKit

class TimerEditingInterfaceController: WKInterfaceController {
    private var timer: TimerInformation?
    private var isUnedited = true
    private var needsUpdate = true
    private var isActive = true

    // outlets
    @IBOutlet var doneButton: WKInterfaceButton?
    @IBOutlet var nameButton: WKInterfaceButton?
    
    override func awakeWithContext(context: AnyObject?) {
        if let timerID = context as? String {
            timerDB.registerCallbackForTimer(identifier: timerID) { maybeTimer in
                if let timer = maybeTimer {
                    self.timer = timer
                } else {
                    self.timer = TimerInformation()
                }
                self._update()
            }
        } else if context == nil {
            timer = TimerInformation()
            _update()
        } else {
            assert(false, "Unexpected context \(context)")
        }
    }
    
    override func willActivate() {
        super.willActivate()
        isActive = true
        _updateIfNeeded()
    }
    
    override func didDeactivate() {
        isActive = false
    }
    
    //MARK: - Actions

    @IBAction func nameButtonPressed() {
        // CCC, 1/1/2015. if the timer is named, then include the name as a choice here
        presentTextInputControllerWithSuggestions(["Tea", "Power Nap"], allowedInputMode: WKTextInputMode.Plain) { maybeInputText in
            if let textInput = maybeInputText?.first as? String {
                if !textInput.isEmpty {
                    self.timer!.name = textInput
                    self._update()
                }
            }
        }
    }
    
    @IBAction func doneButtonPressed() {
        // CCC, 12/31/2014. need some mechanism for adding the row to the top-level listing. Probably give a way to register a timer-added callback on the database
        dismissController()
        timerDB.updateTimer(timer!)
    }
    
    //MARK: - Private API

    // CCC, 1/1/2015. Does it make sense to make a WKInterfaceController subclass or a helper object to handle the delayed update tap dance?
    private func _setNeedsUpdate() {
        needsUpdate = true
    }
    
    private func _updateIfNeeded() {
        if (!needsUpdate) {
            return
        }
        // CCC, 12/31/2014. implement
        nameButton!.setTitle(timer!.name)
        doneButton!.setHidden(isUnedited)
        needsUpdate = false
    }
    
    /// If the interface is active, then updates the interface to match the state of the timer. Otherwise schedules an interface update for the next time the interface becomes active.
    private func _update() {
        _setNeedsUpdate()
        if (isActive) {
            _updateIfNeeded()
        }
    }
}
