//
//  NSTimerExtensions.swift
//  Timerity
//
//  Created by Curt Clifton on 1/4/15.
//  Copyright (c) 2015 curtclifton.net. All rights reserved.
//

import Foundation

extension NSTimer {
    class func scheduledTimerWithTimeInterval(interval: NSTimeInterval, repeats: Bool, handler: NSTimer! -> Void) -> NSTimer {
        // NSTimer with closures in Swift, due to https://gist.github.com/natecook1000/b0285b518576b22c4dc8
        let fireDate = interval + CFAbsoluteTimeGetCurrent()
        let repeatInterval = repeats ? interval : 0
        let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, repeatInterval, 0, 0, handler)
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopCommonModes)
        return timer
    }
    
    class func scheduledTimerWithFireDate(fireDate: NSDate, handler: NSTimer! -> Void) -> NSTimer {
        let fireDateAsCFAbsoluteTime = fireDate.timeIntervalSinceReferenceDate
        let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDateAsCFAbsoluteTime, 0.0, 0, 0, handler)
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopCommonModes)
        return timer
    }
}

