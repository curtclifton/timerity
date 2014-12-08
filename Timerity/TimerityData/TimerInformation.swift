//
//  TimerInformation.swift
//  Timerity
//
//  Created by Curt Clifton on 12/7/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import Foundation

public struct Duration {
    private static let secondsPerHour: Int = 3600
    private static let secondsPerMinute: Int = 60
    
    let seconds: Int
    
    var hoursMinutesSeconds: (hours: Int, minutes: Int, seconds: Int) {
        get {
            let fractionalHours = Double(seconds) / Double(Duration.secondsPerHour)
            let wholeHours = Int(floor(fractionalHours))
            let secondsRemaining = seconds - wholeHours * Duration.secondsPerHour
            let fractionalMinutes = Double(secondsRemaining) / Double(Duration.secondsPerMinute)
            let wholeMinutes = Int(floor(fractionalMinutes))
            let wholeSeconds = secondsRemaining - wholeMinutes * Duration.secondsPerMinute
            return (wholeHours, wholeMinutes, wholeSeconds)
        }
    }
    
    init(hours : Int = 0, minutes: Int = 0, seconds: Int = 0) {
        self.seconds = hours * Duration.secondsPerHour + minutes * Duration.secondsPerMinute + seconds
        assert(self.seconds >= 0, "cannot have a negative duration")
    }
}

public struct TimerInformation {
    var name: String
    var duration: Duration
    var isActive: Bool = false
    var timeRemaining: Duration = Duration()
    var isPaused: Bool = false
    var fireDate: NSDate?
    var id: String
    
    init(name: String, duration: Duration) {
        self.name = name
        self.duration = duration
        id = CFUUIDCreateString(kCFAllocatorDefault, CFUUIDCreate(kCFAllocatorDefault))
    }
}

// CCC, 12/7/2014. Need functions to get [TimerInformation] from a given URL and to write [TimerInformation] to a given URL

