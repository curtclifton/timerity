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
    
    public init(array: [T]) {
        self.init()
        add(array)
    }

    public func contains(element: T) -> Bool {
        return _backingDictionary[element] != nil
    }
    
    public mutating func add(element: T) {
        _backingDictionary[element] = true
    }
    
    public mutating func add(elements: [T]) {
        for element in elements {
            add(element)
        }
    }
    
    public mutating func remove(element: T) {
        _backingDictionary[element] = nil
    }
    
    public var count: Int {
        return _backingDictionary.count
    }
}
