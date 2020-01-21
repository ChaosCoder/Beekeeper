//
//  BeekeeperTests.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 14.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import XCTest
import JSONAPI
import PromiseKit
@testable import Beekeeper

struct MockStorage: Storage {
    var values: [String: Any] = [:]
    
    mutating func set(string: String, for key: String) {
        values[key] = string
    }
    
    func string(forKey key: String) throws -> String? {
        return values[key] as? String
    }
    
    mutating func set<T>(value: T, for key: String) throws where T : Encodable {
        values[key] = value
    }
    
    func value<T>(for key: String) -> T? where T : Decodable {
        return values[key] as? T
    }
    
    mutating func removeValue(for key: String) {
        values[key] = nil
    }
}

struct MockDispatcher: Dispatcher {
    var callback: (([Event]) -> Error?)?
    var maxBatchSize: Int
    var timeout: TimeInterval
    
    func dispatch(event: Event) -> Promise<Void> {
        if let error = callback?([event]) {
            return Promise(error: error)
        } else {
            return Promise()
        }
    }
    func dispatch(events: [Event]) -> Promise<Void> {
        if let error = callback?(events) {
            return Promise(error: error)
        } else {
            return Promise()
        }
    }
}

class BeekeeperTests: XCTestCase {
    
    var testableBeekeeper: Beekeeper {
        let mockStorage = MockStorage()
        let mockDispatcher = MockDispatcher(callback: nil, maxBatchSize: 1, timeout: 1)
        return Beekeeper(product: "0", dispatcher: mockDispatcher, storage: mockStorage, queue: Queue<Event>())
    }
    
    func testTrackingQueuesUp() {
        
        let beekeeper = testableBeekeeper
        
        let eventName = "TestEvent"
        beekeeper.track(name: eventName)
        
        XCTAssertEqual(beekeeper.queue.count, 1)
        XCTAssertEqual(beekeeper.queue.first()?.name, eventName)
    }
    
    func testSuccessfulDispatchingClearsQueue() {
        
        let beekeeper = testableBeekeeper
        beekeeper.start()
        
        let eventName = "TestEvent"
        beekeeper.track(name: eventName)
        
        XCTAssertEqual(beekeeper.queue.count, 1)
        beekeeper.dispatch()
        XCTAssertEqual(beekeeper.queue.count, 0)
        
    }
    
    func testDispatchingWithEmptyQueueStopsDispatcher() {
        let beekeeper = testableBeekeeper
        beekeeper.start()
        XCTAssertTrue(beekeeper.isRunning())
        beekeeper.dispatch()
        XCTAssertFalse(beekeeper.isRunning())
    }
    
    func testTrackingStartDispatching() {
        let beekeeper = testableBeekeeper
        beekeeper.start()
        XCTAssertTrue(beekeeper.isRunning())
        beekeeper.track(name: "Test")
        XCTAssertTrue(beekeeper.isRunning())
    }
    
    func testBeekeeperAutomaticallyDispatchesEvents() {
        
        let expect = expectation(description: "Completion")
        let eventName = "TestEvent"
        
        let mockStorage = MockStorage()
        let mockDispatcher = MockDispatcher(callback: { (events) -> Error? in
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events[0].name, eventName)
            expect.fulfill()
            return nil
        }, maxBatchSize: 1, timeout: 1)
        let beekeeper = Beekeeper(product: "0", dispatcher: mockDispatcher, storage: mockStorage, queue: Queue<Event>())
        
        beekeeper.start()
        beekeeper.track(name: eventName)
        
        wait(for: [expect], timeout: 2)
    }
    
    func testPrevEvent() {
        let expect = expectation(description: "Completion")
        
        let date = "2018-04-20"
        let timestamp = Date(timeIntervalSince1970: 1524234032) // 2018-04-20T14:20:32Z
        let event = Event(id: "id", product: "0", timestamp: timestamp, name: "Test", group: nil, detail: nil, value: nil, previousEvent: nil, previousEventTimestamp: nil, install: date, custom: [])
        
        let mockStorage = MockStorage()
        let mockDispatcher = MockDispatcher(callback: { (events) -> Error? in
            let newEvent = events[2]
            XCTAssertEqual(newEvent.previousEvent, "Other")
            XCTAssertEqual(newEvent.previousEventTimestamp, date)
            expect.fulfill()
            return nil
        }, maxBatchSize: 3, timeout: 1)
        let beekeeper = Beekeeper(product: "0", dispatcher: mockDispatcher, storage: mockStorage, queue: Queue<Event>())
        beekeeper.start()
        beekeeper.track(event: event)
        beekeeper.track(name: "Other")
        beekeeper.track(name: "Test")
        beekeeper.dispatch()
        
        wait(for: [expect], timeout: 2)
    }
    
    func testResetting() {
        let expect = expectation(description: "Completion")
        expect.expectedFulfillmentCount = 2
        
        let eventName = "TestEvent"
        
        let mockStorage = MockStorage()
        let mockDispatcher = MockDispatcher(callback: { (events) -> Error? in
            let event = events[0]
            XCTAssertEqual(event.name, eventName)
            XCTAssertEqual(event.previousEvent, nil)
            XCTAssertEqual(event.previousEventTimestamp, nil)
            expect.fulfill()
            return nil
        }, maxBatchSize: 1, timeout: 1)
        let beekeeper = Beekeeper(product: "0", dispatcher: mockDispatcher, storage: mockStorage, queue: Queue<Event>())
        beekeeper.start()
        
        beekeeper.track(name: eventName)
        beekeeper.dispatch()
        beekeeper.reset()
        beekeeper.track(name: eventName)
        beekeeper.dispatch()
        
        wait(for: [expect], timeout: 5)
    }
    
    func testOptingOut() {
        let beekeeper = testableBeekeeper
        beekeeper.optedOut = true
        
        beekeeper.start()
        beekeeper.track(name: "Test")
        XCTAssertEqual(beekeeper.queue.count, 0)
    }
    
    func testTimeZone() {
        let timestamp = Date(timeIntervalSince1970: 1524268799) // 2018-04-20T23:59:59Z
        let day = timestamp.day
        XCTAssertEqual(day, "2018-04-20")
    }
    
}
