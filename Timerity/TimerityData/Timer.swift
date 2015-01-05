//
//  TimerInformation.swift
//  Timerity
//
//  Created by Curt Clifton on 12/7/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import Foundation
import UIKit

public struct Duration {
    private static let secondsPerHour: Int = 3600
    private static let secondsPerMinute: Int = 60
    
    public let seconds: Double
    
    public var hoursMinutesSeconds: (hours: Int, minutes: Int, seconds: Int) {
        get {
            let totalSeconds = Int(floor(seconds))
            let fractionalHours = Double(seconds) / Double(Duration.secondsPerHour)
            let wholeHours = Int(floor(fractionalHours))
            let secondsRemaining = totalSeconds - wholeHours * Duration.secondsPerHour
            let fractionalMinutes = Double(secondsRemaining) / Double(Duration.secondsPerMinute)
            let wholeMinutes = Int(floor(fractionalMinutes))
            let wholeSeconds = secondsRemaining - wholeMinutes * Duration.secondsPerMinute
            return (wholeHours, wholeMinutes, wholeSeconds)
        }
    }
    
    public init(hours : Int = 0, minutes: Int = 0, seconds: Int = 0) {
        self.init(seconds: Double(hours * Duration.secondsPerHour + minutes * Duration.secondsPerMinute + seconds))
    }
    
    public init(seconds: Double) {
        assert(seconds >= 0, "cannot have a negative duration")
        self.seconds = seconds
    }
}

public enum TimerState {
    case Active(fireDate: NSDate)
    case Paused(timeRemaining: Duration)
    case Inactive
}

public struct TimerInformation {
    public var name: String
    public var duration: Duration
    public let id: String
    public var lastModified: NSDate

    var isActive: Bool = false
    var isPaused: Bool = false

    var timeRemaining: Duration = Duration()
    var fireDate: NSDate?
    
    // CCC, 1/4/2015. May want a "Going Off" state to deal with an expired timer while running the watch app. Or will a notification pull the wearer out of the watch app and into the notification interface?
    public var state: TimerState {
        if isActive {
            return TimerState.Active(fireDate: fireDate!)
        } else if isPaused {
            return TimerState.Paused(timeRemaining: timeRemaining)
        } else {
            return TimerState.Inactive
        }
    }
    
    public init() {
        self.init(name: "", duration: Duration())
    }
    
    init(name: String, duration: Duration) {
        self.name = name
        self.duration = duration
        lastModified = NSDate()
        id = CFUUIDCreateString(kCFAllocatorDefault, CFUUIDCreate(kCFAllocatorDefault))
    }
    
    private init(name: String, durationInSeconds: Double, id: String, lastModified: NSDate, state: TimerState) {
        self.name = name
        self.duration = Duration(seconds: durationInSeconds)
        self.id = id
        self.lastModified = lastModified
        switch state {
        case .Active(fireDate: let fireDate):
            if fireDate.timeIntervalSinceNow < 0 {
                // already expired so make inactive
                isActive = false
                isPaused = false
            } else {
                isActive = true
                isPaused = false
                self.fireDate = fireDate
            }
            break
        case .Paused(timeRemaining: let timeRemaining):
            isActive = false
            isPaused = true
            self.timeRemaining = timeRemaining
            break
        case .Inactive:
            isActive = false
            isPaused = false
            break
        }
    }
    
    //MARK: - Public API
    public mutating func start() {
        assert(!isPaused && !isActive)
        isActive = true
        isPaused = false
        fireDate = NSDate(timeIntervalSinceNow: duration.seconds)
        timeRemaining = duration
        _justModified()
    }
    
    public mutating func resume() {
        assert(isPaused && !isActive)
        isActive = true
        isPaused = false
        fireDate = NSDate(timeIntervalSinceNow: timeRemaining.seconds)
        timeRemaining = Duration()
        _justModified()
    }
    
    public mutating func pause() {
        assert(!isPaused && isActive)
        let timeUntilFireDate = fireDate!.timeIntervalSinceNow
        isActive = false
        isPaused = true
        fireDate = nil
        timeRemaining = Duration(seconds: timeUntilFireDate)
        _justModified()
    }
    
    public mutating func reset() {
        isActive = false
        isPaused = false
        fireDate = nil
        timeRemaining = Duration()
        _justModified()
    }
    
    //MARK: - Private API
    private mutating func _justModified() {
        lastModified = NSDate()
    }
}

//MARK: - Formatting
extension Duration {
    private enum TimeUnits {
        case Hours
        case Minutes
        case Seconds
        
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
        
        func coloredStringForValue(value: Int, color: UIColor) -> NSAttributedString {
            return NSAttributedString(string: "\(value)\(suffix)", attributes: [NSForegroundColorAttributeName: color])
        }
    }
    
    private static let attributedSpace = NSAttributedString(string: " ")

    public var formattedString: String {
        let (hours, minutes, seconds) = hoursMinutesSeconds
        return "\(hours)\(TimeUnits.Hours.suffix) \(minutes)\(TimeUnits.Minutes.suffix) \(seconds)\(TimeUnits.Seconds.suffix)"
    }
    
    public func formattedAtributedStringWithHoursColor(hoursColor: UIColor, minutesColor: UIColor, secondsColor: UIColor) -> NSAttributedString {
        let (hours, minutes, seconds) = hoursMinutesSeconds
        let hoursString = TimeUnits.Hours.coloredStringForValue(hours, color: hoursColor)
        let minutesString = TimeUnits.Minutes.coloredStringForValue(minutes, color: minutesColor)
        let secondsString = TimeUnits.Seconds.coloredStringForValue(seconds, color: secondsColor)

        var labelAttributedString = NSMutableAttributedString(attributedString: hoursString)
        labelAttributedString.appendAttributedString(Duration.attributedSpace)
        labelAttributedString.appendAttributedString(minutesString)
        labelAttributedString.appendAttributedString(Duration.attributedSpace)
        labelAttributedString.appendAttributedString(secondsString)
        
        return labelAttributedString
    }
}

//MARK: JSON encoding and decoding

// CCC, 1/4/2015. Rename to Timer
extension TimerInformation: JSONEncodable {
    func encode() -> [String : AnyObject] {
        var informationDictionary = [
            "id": id,
            "name": name,
            "duration": NSNumber(double: duration.seconds),
            "lastModified": NSNumber(double: lastModified.timeIntervalSince1970),
            "isActive": NSNumber(bool: isActive),
            "isPaused": NSNumber(bool: isPaused),
        ]
        switch state {
        case .Active(fireDate: let fireDate):
            informationDictionary["fireDate"] = NSNumber(double: fireDate.timeIntervalSince1970)
            break;
        case .Paused(timeRemaining: let timeRemaining):
            informationDictionary["timeRemaining"] = NSNumber(double: timeRemaining.seconds)
            break;
        case .Inactive:
            break;
        }
        return [JSONKey.TimerInformation: informationDictionary]
    }
}

extension TimerInformation: JSONDecodable {
    typealias ResultType = TimerInformation
    static func decodeJSONData(jsonData: [String : AnyObject], sourceURL: NSURL? = nil) -> Either<TimerInformation, TimerError> {
        let maybeEncodedTimer: AnyObject? = jsonData[JSONKey.TimerInformation]
        if let encodedTimer = maybeEncodedTimer as? [String: AnyObject] {
            // TODO: This is pretty hideous with all the error handling Swift requires. See 	SwiftyJSON https://github.com/SwiftyJSON/SwiftyJSON or this Haskell-style: http://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics approach for alternatives.
            var lastCheckedProperty: String
            lastCheckedProperty = "id"
            if let id = encodedTimer[lastCheckedProperty] as? String {
                lastCheckedProperty = "name"
                if let name = encodedTimer[lastCheckedProperty] as? String {
                    lastCheckedProperty = "duration"
                    if let durationNumber = encodedTimer[lastCheckedProperty] as? NSNumber {
                        lastCheckedProperty = "lastModified"
                        if let lastModifiedNumber = encodedTimer[lastCheckedProperty] as? NSNumber {
                            lastCheckedProperty = "isActive"
                            if let isActiveNumber = encodedTimer[lastCheckedProperty] as? NSNumber {
                                lastCheckedProperty = "isPaused"
                                if let isPausedNumber = encodedTimer[lastCheckedProperty] as? NSNumber {
                                    let isActive = isActiveNumber.boolValue
                                    let isPaused = isPausedNumber.boolValue
                                    switch (isActive, isPaused) {
                                    case (true, true):
                                        return Either.Right(Box(wrap: TimerError.Decoding("unexpected timer state, cannot be both active and paused")))
                                    case (true, false):
                                        lastCheckedProperty = "fireDate"
                                        if let fireDateNumber = encodedTimer[lastCheckedProperty] as? NSNumber {
                                            return Either.Left(Box(wrap: TimerInformation(name: name, durationInSeconds: durationNumber.doubleValue, id: id, lastModified: NSDate(timeIntervalSince1970: lastModifiedNumber.doubleValue), state: TimerState.Active(fireDate: NSDate(timeIntervalSince1970: fireDateNumber.doubleValue)))))
                                        }
                                        break;
                                    case (false, true):
                                        lastCheckedProperty = "timeRemaining"
                                        if let timeRemainingNumber = encodedTimer[lastCheckedProperty] as? NSNumber {
                                            return Either.Left(Box(wrap: TimerInformation(name: name, durationInSeconds: durationNumber.doubleValue, id: id, lastModified: NSDate(timeIntervalSince1970: lastModifiedNumber.doubleValue), state: TimerState.Paused(timeRemaining: Duration(seconds: timeRemainingNumber.doubleValue)))))
                                        }
                                        break;
                                    default:
                                        return Either.Left(Box(wrap: TimerInformation(name: name, durationInSeconds: durationNumber.doubleValue, id: id, lastModified: NSDate(timeIntervalSince1970: lastModifiedNumber.doubleValue), state: TimerState.Inactive)))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            return Either.Right(Box(wrap: TimerError.Decoding("invalid timer data, missing \(lastCheckedProperty): \(encodedTimer)")))
        } else {
            return Either.Right(Box(wrap: TimerError.Decoding("missing timer data")))
        }
    }
}

//MARK: Printable, DebugPrintable extensions

extension TimerInformation: Printable, DebugPrintable {
    public var description: String {
        return "name:\(name), duration: \(duration.description)"
    }
    
    public var debugDescription: String {
        return description
    }
}

extension Duration: Printable, DebugPrintable {
    public var description: String {
        let hms = hoursMinutesSeconds
        return "\(hms.hours)h \(hms.minutes)m \(hms.seconds)s"
    }
    
    public var debugDescription: String {
        return "Duration: \(seconds) seconds"
    }
}

