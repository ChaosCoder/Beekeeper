//
//  QueueTests.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import XCTest
@testable import Beekeeper

class QueueTests: XCTestCase {
    
    func testQueuingAndRemoving() {
        var queue = Queue<Int>()
        queue.enqueue(item: 1)
        queue.enqueue(item: 2)
        queue.enqueue(item: 3)
        XCTAssertEqual(queue.count, 3)
        XCTAssertEqual(queue.remove(), 1)
        XCTAssertEqual(queue.remove(), 2)
        XCTAssertEqual(queue.remove(), 3)
    }
    
    func testFirstItemsAreFIFO() {
        var queue = Queue<Int>()
        queue.enqueue(item: 1)
        queue.enqueue(item: 2)
        queue.enqueue(item: 3)
        let items = queue.first(max: 5)
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.sorted(), items)
    }
    
    func testRemoveOnEmptyQueueReturnsNil() {
        var queue = Queue<Int>()
        XCTAssertNil(queue.first())
        XCTAssertNil(queue.remove())
        XCTAssertEqual(queue.remove(max: 1), Array<Int>())
    }
    
}
