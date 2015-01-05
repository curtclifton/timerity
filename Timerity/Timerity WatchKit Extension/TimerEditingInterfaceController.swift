//
//  TimerEditingInterfaceController.swift
//  Timerity
//
//  Created by Curt Clifton on 12/31/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import TimerityData
import WatchKit

// TODO: really should localize these and read them from a configuration file
let defaultTimerNames = ["Tea", "Power Nap", "Brownies", "Egg", "Tempo Run"]

class TimerEditingInterfaceController: WKInterfaceController {
    private lazy var timer = Timer()
    private var isChanged = false
    private var needsUpdate = true
    private var isActive = true
    private var callbackIdentifier: TimerChangeCallbackID?
    private var isNewTimer = true

    // outlets
    @IBOutlet var doneButton: WKInterfaceButton!
    @IBOutlet var nameButton: WKInterfaceButton!
    @IBOutlet var durationLabel: WKInterfaceLabel!
    @IBOutlet var hoursSlider: WKInterfaceSlider!
    @IBOutlet var minutesSlider: WKInterfaceSlider!
    @IBOutlet var secondsSlider: WKInterfaceSlider!
    
    deinit {
        if let callbackIdentifier = self.callbackIdentifier {
            timerDB.unregisterCallback(identifier: callbackIdentifier)
            self.callbackIdentifier = nil
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        if let timerID = context as? String {
            let registrationResult = timerDB.registerCallbackForTimer(identifier: timerID) { [weak self] maybeTimer in
                if let strongSelf = self {
                    if let timer = maybeTimer {
                        strongSelf.isNewTimer = false
                        strongSelf.timer = timer
                    } else {
                        strongSelf.timer = Timer()
                    }
                    strongSelf._update()
                }
            }
            
            switch registrationResult {
            case .Left(let callbackIdentifierBox):
                callbackIdentifier = callbackIdentifierBox.unwrapped
                break
            case .Right(let errorBox):
                println("error registering timer: \(errorBox.unwrapped)")
                break
            }
        } else if context == nil {
            _update()
        } else {
            assert(false, "Unexpected context \(context)")
        }
        
        hoursSlider!.setColor(SliderColor.Hours.color)
        minutesSlider!.setColor(SliderColor.Minutes.color)
        secondsSlider!.setColor(SliderColor.Seconds.color)
    }
    
    override func willActivate() {
        super.willActivate()
        isActive = true
        _updateIfNeeded()
    }
    
    override func didDeactivate() {
        isActive = false
        super.didDeactivate()
    }
    
    //MARK: - Actions

    @IBAction func nameButtonPressed() {
        let timerNameSuggestions = (timer.name.isEmpty ? [] : [timer.name]) + defaultTimerNames
        var nameSuggestionSet: Set<String> = Set()
        let filteredNameSuggestions = timerNameSuggestions.filter() { name in
            if nameSuggestionSet.contains(name) {
                return false
            }
            nameSuggestionSet.add(name)
            return true
        }
        
        presentTextInputControllerWithSuggestions(filteredNameSuggestions, allowedInputMode: WKTextInputMode.Plain) { maybeInputText in
            if let textInput = maybeInputText?.first as? String {
                if !textInput.isEmpty {
                    self.timer.name = textInput
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
        dismissController()
        timer.lastModified = NSDate()
        timerDB.updateTimer(timer, commandType: (isNewTimer ? .Add : .Replace))
    }
    
    //MARK: - Private API

    private enum Slider: Int {
        case Hours = 0
        case Minutes = 1
        case Seconds = 2
    }
    
    private func _changedSlider(slider: Slider, value newValue: Float) {
        let (hours, minutes, seconds) = timer.duration.hoursMinutesSeconds
        var times = [hours, minutes, seconds]
        let newValue = Int(round(newValue))

        if newValue == times[slider.rawValue] {
            return
        }
        times[slider.rawValue] = newValue
        let newDuration = Duration(hours: times[0], minutes: times[1], seconds: times[2])
        timer.duration = newDuration
        isChanged = true
        // We're assuming that the sliders can only change value when the interface is active and rely on the sliders updating themselves. If we call our regular _update method, we race the frameworks in updating the sliders and get flickering (at least in the simulator).
        _updateDurationLabel()
        _updateDoneButton()
    }
    
    private enum SliderColor {
        case Hours
        case Minutes
        case Seconds
        
        var color: UIColor {
            switch self {
            case .Hours:
                return UIColor(hue: 108.0/360.0, saturation: 0.69, brightness: 1.0, alpha: 1.0)
            case .Minutes:
                return UIColor(hue: 220.0/360.0, saturation: 0.69, brightness: 1.0, alpha: 1.0)
            case .Seconds:
                return UIColor(white: 0.7, alpha: 1.0)
            }
        }
    }

    private func _updateDurationLabel() {
        let labelAttributedString = timer.duration.formattedAtributedStringWithHoursColor(SliderColor.Hours.color, minutesColor: SliderColor.Minutes.color, secondsColor: SliderColor.Seconds.color)
        durationLabel!.setAttributedText(labelAttributedString)
    }
    
    private func _updateDoneButton() {
        doneButton!.setHidden(!isChanged)
    }
    
    // TODO: Does it make sense to make a WKInterfaceController subclass or a helper object to handle the delayed update tap dance?
    private func _setNeedsUpdate() {
        needsUpdate = true
    }
    
    private func _updateIfNeeded() {
        if !needsUpdate {
            return
        }

        if timer.name.isEmpty {
            nameButton.setTitle(NSLocalizedString("Unnamed", comment: "unnmaed timer placeholder"))
        } else {
            nameButton!.setTitle(timer.name)
        }
        _updateDurationLabel()

        let (hours, minutes, seconds) = timer.duration.hoursMinutesSeconds
        hoursSlider!.setValue(Float(hours))
        minutesSlider!.setValue(Float(minutes))
        secondsSlider!.setValue(Float(seconds))
        
        _updateDoneButton()
        needsUpdate = false
    }
    
    /// If the interface is active, then updates the interface to match the state of the timer. Otherwise schedules an interface update for the next time the interface becomes active.
    private func _update() {
        _setNeedsUpdate()
        if isActive {
            _updateIfNeeded()
        }
    }
}
