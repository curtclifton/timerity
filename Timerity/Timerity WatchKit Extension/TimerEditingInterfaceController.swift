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
    
    // outlets
    @IBOutlet var doneButton: WKInterfaceButton?
    
    override func awakeWithContext(context: AnyObject?) {
        if let timerID = context as? String {
            timerDB.registerCallbackForTimer(identifier: timerID) { maybeTimer in
                if let timer = maybeTimer {
                    self.timer = timer
                } else {
                    self.timer = TimerInformation()
                }
                self._updateUserInterface()
            }
        } else if context == nil {
            timer = TimerInformation()
            _updateUserInterface()
        } else {
            assert(false, "Unexpected context \(context)")
        }
    }
    
    //MARK: - Actions
    
    @IBAction func doneButtonPressed() {
        // CCC, 12/31/2014. need some mechanism for adding the row to the top-level listing
        dismissController()
        timerDB.updateTimer(timer!)
    }
    
    //Mark: - Private API
    
    private func _updateUserInterface() {
        // CCC, 12/31/2014. implement
//        doneButton!.setHidden(isUnedited)
    }
}
