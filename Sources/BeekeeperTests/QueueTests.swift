//
//  QueueTests.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Testing
@testable import Beekeeper

struct QueueTests {
    
    @Test
    func testQueuingAndRemoving() {
        var queue = Queue<Int>()
        queue.enqueue(item: 1)
        queue.enqueue(item: 2)
        queue.enqueue(item: 3)
        #expect(queue.count == 3)
        #expect(queue.remove() == 1)
        #expect(queue.remove() == 2)
        #expect(queue.remove() == 3)
    }
    
    @Test
    func testFirstItemsAreFIFO() {
        var queue = Queue<Int>()
        queue.enqueue(item: 1)
        queue.enqueue(item: 2)
        queue.enqueue(item: 3)
        let items = queue.first(max: 5)
        #expect(items.count == 3)
        #expect(items.sorted() == items)
    }
    
    @Test
    func testRemoveOnEmptyQueueReturnsNil() {
        var queue = Queue<Int>()
        #expect(queue.first() == nil)
        #expect(queue.remove() == nil)
        #expect(queue.remove(max: 1) == [])
    }
    
}
