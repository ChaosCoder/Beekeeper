//
//  InternalMemory.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 20.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation

struct Memory: Codable {
    var lastDay: [String: Day]
    var installDay: Day
    var previousEvent: String?
    var optedOut: Bool
    
    var custom: [String]
    
    init() {
        lastDay = [:]
        installDay = Date().day
        custom = []
        optedOut = false
    }
    
    mutating func memorize(event: Event) {
        self.previousEvent = event.name
        self.lastDay[event.name] = event.timestamp.day
    }
    
    func lastTimestamp(eventName: String) -> String? {
        return lastDay[eventName]
    }
}
