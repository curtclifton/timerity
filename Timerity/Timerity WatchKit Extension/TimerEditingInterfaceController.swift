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
    private var isChanged = false
    private var needsUpdate = true
    private var isActive = true

    // outlets
    @IBOutlet var doneButton: WKInterfaceButton?
    @IBOutlet var nameButton: WKInterfaceButton?
    @IBOutlet var durationLabel: WKInterfaceLabel?
    @IBOutlet var hoursSlider: WKInterfaceSlider?
    @IBOutlet var minutesSlider: WKInterfaceSlider?
    @IBOutlet var secondsSlider: WKInterfaceSlider?
    
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
        
        // CCC, 1/1/2015. Consider setting a color on the sliders and using an attributed string to put corresponding colors on the label fields.
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
                    self.isChanged = true
                    self._update()
                }
            }
        }
    }

    @IBAction func hoursSliderChanged(value: Float) {
        _changedSlider(.Hours, value: value)
    }
    
    @IBAction func minutesSliderChanged(value: Float) {
        _changedSlider(.Minutes, value: value)
    }
    
    @IBAction func secondsSliderChanged(value: Float) {
        _changedSlider(.Seconds, value: value)
    }
    
    @IBAction func doneButtonPressed() {
        // CCC, 12/31/2014. need some mechanism for adding the row to the top-level listing. Probably give a way to register a timer-added callback on the database
        dismissController()
        timerDB.updateTimer(timer!)
    }
    
    //MARK: - Private API

    private enum Slider: Int {
        case Hours = 0
        case Minutes = 1
        case Seconds = 2
    }
    
    private func _changedSlider(slider: Slider, value newValue: Float) {
        let (hours, minutes, seconds) = timer!.duration.hoursMinutesSeconds
        var times = [hours, minutes, seconds]
        let newValue = Int(round(newValue))

        if newValue == times[slider.rawValue] {
            return
        }
        times[slider.rawValue] = newValue
        let newDuration = Duration(hours: times[0], minutes: times[1], seconds: times[2])
        timer!.duration = newDuration
        isChanged = true
        _updateDurationLabel()
        _updateDoneButton()
    }
    
    private func _updateDurationLabel() {
        let duration = timer!.duration
        durationLabel!.setText(duration.description) // CCC, 1/1/2015. add function for formatting a duration nicely
    }
    
    private func _updateDoneButton() {
        doneButton!.setHidden(!isChanged)
    }
    
    // CCC, 1/1/2015. Does it make sense to make a WKInterfaceController subclass or a helper object to handle the delayed update tap dance?
    private func _setNeedsUpdate() {
        needsUpdate = true
    }
    
    private func _updateIfNeeded() {
        if (!needsUpdate) {
            return
        }

        nameButton!.setTitle(timer!.name)
        _updateDurationLabel()

        let (hours, minutes, seconds) = timer!.duration.hoursMinutesSeconds
        hoursSlider!.setValue(Float(hours))
        minutesSlider!.setValue(Float(minutes))
        secondsSlider!.setValue(Float(seconds))
        
        _updateDoneButton()
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
