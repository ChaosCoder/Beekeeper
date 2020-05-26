//
//  InternalMemory.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 20.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation

public struct Memory: Codable {
    var lastDay: [String: Day]
    var installDay: Day
    var previousEvent: [String: String]
    var optedOut: Bool
    
    var custom: [String]
    
    init() {
        lastDay = [:]
        installDay = Date().day
        previousEvent = [:]
        custom = []
        optedOut = false
    }
    
    public init(lastDay: [String: Day], installDay: Day, previousEvent: [String: String], optedOut: Bool, custom: [String]) {
        self.lastDay = lastDay
        self.installDay = installDay
        self.previousEvent = previousEvent
        self.optedOut = optedOut
        self.custom = custom
    }
    
    mutating func memorize(event: Event) {
        self.previousEvent[event.group] = event.name
        self.lastDay[event.name] = event.timestamp.day
    }
    
    func previousEvent(group: String) -> String? {
        return previousEvent[group]
    }
    
    func lastTimestamp(eventName: String) -> String? {
        return lastDay[eventName]
    }
}
