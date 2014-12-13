//
//  InterfaceController.swift
//  Timerity WatchKit Extension
//
//  Created by Curt Clifton on 12/6/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    struct RowTypes {
        static let Timer = "TimerRow"
        static let AddButton = "AddButton"
    }
    
    @IBOutlet var table: WKInterfaceTable!
    
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
        NSLog("%@ init", self)
    }

    override func awakeWithContext(context: AnyObject!) {
        var rowTypes: [String] = []
        // CCC, 12/10/2014. Should get actual timers and iterate (up to 19 of) them. If there are more than 19, then just include 18 and replace the 19th with "and X more"
        for i in 1...5 {
            rowTypes.append(RowTypes.Timer)
        }
        rowTypes.append(RowTypes.AddButton)
        table?.setRowTypes(rowTypes)
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

    // MARK: Actions
    
    // CCC, 12/12/2014. All mutation of existing timers should be sent as commands to the iPhone app so it can reschedule timers and atomically rewrite the shared data store. Watch app should update its in-memory data, but not update the file. It should only read from the file.
    
    // CCC, 12/10/2014. Testing:
    @IBAction func buttonTapped() {
        NSLog("tapping");
        // CCC, 12/12/2014. Should be using an enum and associated values to fling the data to and fro
        InterfaceController.openParentApplication([:]) { result, error in
            if let fireDate = result["fireDate"] as? NSDate {
                NSLog("got call back with payload: %@", fireDate);
            } else {
                NSLog("got call back sans payload");
            }
        }
        NSLog("waiting for call back");
    }
    
}
