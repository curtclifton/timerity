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
    @IBOutlet var button: WKInterfaceButton?
    
    deinit {
        _clearCurrentTimer()
    }
    
    //MARK: WKInterfaceController subclass
    override func awakeWithContext(context: AnyObject!) {
        _clearCurrentTimer()
        if let timerID = context as? String {
            timerController = SingleTimerController(nameLabel: nameLabel!, totalTimeLabel: totalTimeLabel!, countdownTimer: countdownTimer!, button: button, menuItemPresenter: self)
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
        timerController?.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        NSLog("%@ did deactivate", self)
        timerController?.didDeactivate()
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
        timerController?.buttonPressed()
    }
}

extension SingleTimerInterfaceController: MenuItemPresenter {
    func configureMenuForState(timerState: TimerState) {
        clearAllMenuItems()
        switch timerState {
        case .Active:
            // no menu items here
            break;
        case .Paused:
            addMenuItemWithItemIcon(WKMenuItemIcon.Decline, title: NSLocalizedString("Reset Timer", comment: "reset timer menu item title"), action: "resetMenuItemPressed")
            break;
        case .Inactive:
            addMenuItemWithItemIcon(WKMenuItemIcon.Info, title: NSLocalizedString("Edit Timer", comment: "edit timer menu item title"), action: "editMenuItemPressed")
            addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: NSLocalizedString("Delete Timer", comment: "delete timer menu item title"), action: "deleteMenuItemPressed")
            break;
        }
    }
    
    func resetMenuItemPressed() {
        if var timer = timerController?.timer {
            timer.reset()
            timerDB.updateTimer(timer)
        }
    }
    
    func editMenuItemPressed() {
        // CCC, 12/30/2014. implement
        println("edit the thing")
    }
    
    func deleteMenuItemPressed() {
        // CCC, 12/30/2014. implement
        println("delete the thing")
    }
}