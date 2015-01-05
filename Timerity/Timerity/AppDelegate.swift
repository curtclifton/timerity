//
//  AppDelegate.swift
//  Timerity
//
//  Created by Curt Clifton on 12/6/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import UIKit
import TimerityData

// TODO: This is just a bare skeleton iPhone app for demo purposes.

let groupURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.net.curtclifton.Timerity")
let timerDatabaseURL = groupURL!.URLByAppendingPathComponent("data.json", isDirectory: false)

func spinUpTimerDB() -> TimerData {
    let maybeTimerData = TimerData.fromURL(timerDatabaseURL)
    switch maybeTimerData {
    case .Left(let timerDataBox):
        return timerDataBox.unwrapped
    case .Right(let error):
        println("error reading data file: \(error.unwrapped)")
        return TimerData()
    }
}

/// Lazily loaded global timer database
let timerDB = spinUpTimerDB()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let settings = UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil)
        application.registerUserNotificationSettings(settings)
        // Override point for customization after application launch.
        
        // CCC, 1/4/2015. testing
        println("Loaded timer database: \(timerDB.timers)")
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication!, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]!, reply: (([NSObject : AnyObject]!) -> Void)!) {
        if let rawJSONData = userInfo as? [String: AnyObject] {
            let maybeCommand = TimerCommand.decodeJSONData(rawJSONData)
            switch maybeCommand {
            case .Left(let commandBox):
                let command = commandBox.unwrapped
                switch command.commandType {
                case .Local:
                    assert(false, "shouldn't send local command to the iPhone app")
                    break
                case .Delete:
                    timerDB.deleteTimer(command.timer, commandType: .Local)
                    break
                default:
                    timerDB.updateTimer(command.timer, commandType: .Local)
                    break
                }
                // CCC, 1/4/2015. Debugging
                NSLog("updated iPhone database %@", timerDB.timers.description)
                break
            case .Right(let errorBox):
                // CCC, 1/4/2015. implement error handling
                break
            }
            // CCC, 12/10/2014. This schedules a notification, but we also have to handle the case where the app is foregrounded when the notification expires.
            //        let notification = UILocalNotification()
            //        let oneMinuteHence = NSDate().dateByAddingTimeInterval(60.0)
            //        notification.fireDate = oneMinuteHence
            //        notification.alertTitle = "Fire!"
            //        notification.alertBody = "Release all zigs"
            //        application.scheduleLocalNotification(notification)
            
        }
        // CCC, 1/4/2015.  just round-tripping the data to debug our encoding at the moment:
        // CCC, 1/4/2015. this should be an error case
        let result: [NSObject: AnyObject] = userInfo
        reply(result)
    }
}

