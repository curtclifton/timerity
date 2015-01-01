//
//  TimerSet.swift
//  Timerity
//
//  Created by Curt Clifton on 12/31/14.
//  Copyright (c) 2014 curtclifton.net. All rights reserved.
//

import Foundation

public struct Set<T: Hashable> {
    private var _backingDictionary: [T: Bool]
    
    public init() {
        _backingDictionary = [:]
    }

    public func contains(element: T) -> Bool {
        return _backingDictionary[element] != nil
    }
    
    public mutating func add(element: T) {
        _backingDictionary[element] = true
    }
    
    public var count: Int {
        return _backingDictionary.count
    }
}
