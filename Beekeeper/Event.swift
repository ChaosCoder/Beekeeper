//
//  Event.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation

public struct Event: Codable {
    let id: String
    let product: String
    let timestamp: Date
    let name: String
    let group: String
    let detail: String?
    let value: Double?
    let previousEvent: String?
    let previousEventTimestamp: Day?
    let install: Day
    let custom: [String?]
    
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case product = "p"
        case timestamp = "t"
        case name = "name"
        case group = "group"
        case detail = "detail"
        case value = "value"
        case previousEvent = "prev"
        case previousEventTimestamp = "last"
        case install = "install"
        case custom = "custom"
    }
}
