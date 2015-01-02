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
        
        static let attributedSpace = NSAttributedString(string: " ")
        
        var suffix: String {
            switch self {
            case .Hours:
                return NSLocalizedString("h", comment: "units suffix denoting hours")
            case .Minutes:
                return NSLocalizedString("m", comment: "units suffix denoting minutes")
            case .Seconds:
                return NSLocalizedString("s", comment: "units suffix denoting seconds")
            }
        }
        
        func coloredStringForValue(value: Int) -> NSAttributedString {
            return NSAttributedString(string: "\(value)\(suffix)", attributes: [NSForegroundColorAttributeName: color])
        }
    }

    private func _updateDurationLabel() {
        let duration = timer!.duration
        let (hours, minutes, seconds) = duration.hoursMinutesSeconds
        let hoursString = SliderColor.Hours.coloredStringForValue(hours)
        let minutesString = SliderColor.Minutes.coloredStringForValue(minutes)
        let secondsString = SliderColor.Seconds.coloredStringForValue(seconds)
        
        var labelAttributedString = NSMutableAttributedString(attributedString: hoursString)
        labelAttributedString.appendAttributedString(SliderColor.attributedSpace)
        labelAttributedString.appendAttributedString(minutesString)
        labelAttributedString.appendAttributedString(SliderColor.attributedSpace)
        labelAttributedString.appendAttributedString(secondsString)
        
        durationLabel!.setAttributedText(labelAttributedString)
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
