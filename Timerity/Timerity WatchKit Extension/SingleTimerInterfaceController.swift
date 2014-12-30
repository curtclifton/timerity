//
//  SingleTimerInterfaceController.swift
//  Timerity
//
//  Created by Curt Clifton on 12/29/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import WatchKit
import TimerityData

class SingleTimerInterfaceController: WKInterfaceController {
    private var timerController: SingleTimerController?
    
    // outlets
    @IBOutlet var nameLabel: WKInterfaceLabel?
    @IBOutlet var totalTimeLabel: WKInterfaceLabel?
    @IBOutlet var countdownTimer: WKInterfaceTimer?
    @IBOutlet var startButton: WKInterfaceButton?
    
    deinit {
        _clearCurrentTimer()
    }
    
    //MARK: WKInterfaceController subclass
    override func awakeWithContext(context: AnyObject!) {
        _clearCurrentTimer()
        if let timerID = context as? String {
            timerController = SingleTimerController(nameLabel: nameLabel!, totalTimeLabel: totalTimeLabel!, countdownTimer: countdownTimer!, startButton: startButton)
            timerController!.setTimerID(timerID)
            setTitle(timerController?.timer?.name)
        } else {
            assert(false, "unexpected context \(context)")
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("%@ will activate", self)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        NSLog("%@ did deactivate", self)
        super.didDeactivate()
    }

    //MARK: Private API
    private func _clearCurrentTimer() {
        if var currentTimerController = timerController {
            currentTimerController.clearTimerID()
        }
        timerController = nil
    }
    
    @IBAction private func _buttonPressed() {
        println("ow!")
    }
}
