//
//  InterfaceController.swift
//  Timerity WatchKit Extension
//
//  Created by Curt Clifton on 12/6/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import Foundation
import TimerityData
import WatchKit

let MaxRows = 20

struct InterfaceControllerIdentifier {
    static let AllTimersController = "AllTimersController"
    static let SingleTimerController = "SingleTimerController"
    static let TimerEditingController = "TimerEditingController"
}

class InterfaceController: WKInterfaceController {
    struct RowTypes {
        static let Timer = "TimerRow"
        static let AndNMoreLabelRow = "LabelRow"
        static let AddButton = "AddButton"
    }
    
    struct SegueIdentifiers {
        static let PushTimer = "PushTimer"
    }
    
    @IBOutlet var table: WKInterfaceTable!

    // we need to collect the set of rows to delete, since removing from the table when the table isn't active is a no-op
    private var _controllersToDelete: Set<TimerTableRowController> = Set()

    override init() {
        // Configure interface objects here.
    }

    override func awakeWithContext(context: AnyObject!) {
        setTitle(NSLocalizedString("Timerity", comment: "App title"))
        
        let numberOfTimersShown = timerDB.timers.count <= (MaxRows - 1) ? timerDB.timers.count : (MaxRows - 2) // leave space for a row saying "and X more"
        let isShowingAllTImers = (numberOfTimersShown == timerDB.timers.count)

        // create rows for all the visible timers
        table?.setNumberOfRows(numberOfTimersShown, withRowType: RowTypes.Timer)

        var nextRow = numberOfTimersShown
        
        // create row for the "And n more" row if needed
        if !isShowingAllTImers {
            let nMoreRow = NSIndexSet(index: nextRow)
            table?.insertRowsAtIndexes(nMoreRow, withRowType: RowTypes.AndNMoreLabelRow)
            if let nMoreRowController = table?.rowControllerAtIndex(nextRow) as? LabelRowController {
                let countOfElided = timerDB.timers.count - numberOfTimersShown
                let countOfElidedAsString = countOfElided.description
                let labelText = NSString(format: NSLocalizedString("And %@ more", comment: "and N more"), countOfElidedAsString)
                nMoreRowController.label?.setText(labelText)
            }
            ++nextRow
        }
        
        // create row for the Add Timer button
        let lastRow = NSIndexSet(index: nextRow)
        table?.insertRowsAtIndexes(lastRow, withRowType: RowTypes.AddButton)
        
        for i in 0 ..< numberOfTimersShown {
            if let timerRowController = table?.rowControllerAtIndex(i) as? TimerTableRowController {
                let timer = timerDB.timers[i]
                timerRowController.setTimerID(timer.id)
                timerDB.registerCallbackForTimer(identifier: timer.id) { maybeTimer in
                    if maybeTimer == nil {
                        self._deleteRowWithController(timerRowController)
                    }
                }
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("%@ will activate", self)
        _processPendingRowDeletions()
        _forEachRowController() { rowController in
            if let timerRowController = rowController as? TimerTableRowController {
                timerRowController.willActivate()
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        NSLog("%@ did deactivate", self)
        _forEachRowController() { rowController in
            if let timerRowController = rowController as? TimerTableRowController {
                timerRowController.didDeactivate()
            }
        }
        super.didDeactivate()
    }

    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        if (segueIdentifier == SegueIdentifiers.PushTimer) {
            println("getting context for seque \(segueIdentifier) and row \(rowIndex)")
            let timers = timerDB.timers
            return timers[rowIndex].id
        } else {
            println("unexpected seque identifier \(segueIdentifier)")
            return nil
        }
    }
    
    // MARK: Actions
    
    // CCC, 12/12/2014. All mutation of existing timers should be sent as commands to the iPhone app so it can reschedule timers and atomically rewrite the shared data store. Watch app should update its in-memory data, but not update the file. It should only read from the file.
    
    //MARK: - Private API
    func _forEachRowController(block: (AnyObject) -> ()) {
        for index in 0..<table!.numberOfRows {
            if let rowController: AnyObject = table!.rowControllerAtIndex(index) {
                block(rowController)
            }
        }
    }
    
    func _processPendingRowDeletions() {
        if _controllersToDelete.count == 0 {
            return;
        }
        let rowsToDelete = filter(0..<table!.numberOfRows) { rowIndex in
            if let currentController = self.table!.rowControllerAtIndex(rowIndex) as? TimerTableRowController {
                return self._controllersToDelete.contains(currentController)
            } else {
                return false
            }
        }

        rowsToDelete.reverse().map() { rowToDelete in
            self.table!.removeRowsAtIndexes(NSIndexSet(index: rowToDelete))
        }

        _controllersToDelete = Set()
    }
    
    func _deleteRowWithController(controller: TimerTableRowController) {
        _controllersToDelete.add(controller)
    }
}
