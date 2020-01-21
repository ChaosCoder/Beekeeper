//
//  Queue.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation

public struct Queue<Item> {
    
    var items: [Item]
    
    public init() {
        items = []
    }
    
    mutating func enqueue(item: Item) {
        items.append(item)
    }
    
    mutating func enqueue<S: Sequence>(items: S) where S.Element == Item {
        self.items.append(contentsOf: items)
    }
    
    func first() -> Item? {
        return items.first
    }
    
    func first(max: Int) -> [Item] {
        let count = min(max, items.count)
        let part = items[..<count]
        return Array(part)
    }
    
    @discardableResult
    mutating func remove(max: Int) -> [Item] {
        let count = min(max, items.count)
        let part = items[..<count]
        items.removeFirst(count)
        return Array(part)
    }
    
    mutating func removeAll() {
        items.removeAll()
    }
    
    @discardableResult
    mutating func remove() -> Item? {
        guard let item = items.first else {
            return nil
        }
        items = Array(items[1...])
        return item
    }
    
    var count: Int {
        return items.count
    }
}
