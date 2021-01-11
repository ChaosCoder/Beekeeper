//
//  InternalMemory.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 20.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation

public struct EventNameGroup: Codable, Hashable {
    
    public let name: String
    public let group: String
    
    public init(name: String, group: String) {
        self.name = name
        self.group = group
    }
}

public struct Memory: Codable {
    
    var lastDay: [EventNameGroup: Day]
    var installDay: Day
    var previousEvent: [String: String]
    var optedOut: Bool
    
    var custom: [String?]
    
    init() {
        lastDay = [:]
        installDay = Date().day
        previousEvent = [:]
        custom = []
        optedOut = false
    }
    
    public init(lastDay: [EventNameGroup: Day], installDay: Day, previousEvent: [String: String], optedOut: Bool, custom: [String?]) {
        self.lastDay = lastDay
        self.installDay = installDay
        self.previousEvent = previousEvent
        self.optedOut = optedOut
        self.custom = custom
    }
    
    mutating func memorize(event: Event) {
        self.previousEvent[event.group] = event.name
        self.lastDay[EventNameGroup(name: event.name, group: event.group)] = event.timestamp.day
    }
    
    func previousEvent(group: String) -> String? {
        return previousEvent[group]
    }
    
    func lastTimestamp(eventName: String, eventGroup: String) -> String? {
        return lastDay[EventNameGroup(name: eventName, group: eventGroup)]
    }
}
