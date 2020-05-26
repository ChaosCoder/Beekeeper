//
//  BeekeeperTests.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 14.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import XCTest
import ConvAPI
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
        
        let eventName = "TestName"
        let eventGroup = "TestGroup"
        beekeeper.track(name: eventName, group: eventGroup)
        
        XCTAssertEqual(beekeeper.queue.count, 1)
        
        let event = beekeeper.queue.first()
        XCTAssertEqual(event?.name, eventName)
        XCTAssertEqual(event?.group, eventGroup)
    }
    
    func testSuccessfulDispatchingClearsQueue() {
        
        let beekeeper = testableBeekeeper
        beekeeper.start()
        
        let eventName = "TestName"
        let eventGroup = "TestGroup"
        beekeeper.track(name: eventName, group: eventGroup)
        
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
        beekeeper.track(name: "Name", group: "Group")
        XCTAssertTrue(beekeeper.isRunning())
    }
    
    func testBeekeeperAutomaticallyDispatchesEvents() {
        
        let expect = expectation(description: "Completion")
        let eventName = "TestName"
        let eventGroup = "TestGroup"
        
        let mockStorage = MockStorage()
        let mockDispatcher = MockDispatcher(callback: { (events) -> Error? in
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events[0].name, eventName)
            expect.fulfill()
            return nil
        }, maxBatchSize: 1, timeout: 1)
        let beekeeper = Beekeeper(product: "0", dispatcher: mockDispatcher, storage: mockStorage, queue: Queue<Event>())
        
        beekeeper.start()
        beekeeper.track(name: eventName, group: eventGroup)
        
        wait(for: [expect], timeout: 2)
    }
    
    func testPrevEvent() {
        let expect = expectation(description: "Completion")
        
        let date = "2018-04-20"
        let timestamp = Date(timeIntervalSince1970: 1524234032) // 2018-04-20T14:20:32Z
        let event = Event(id: "id", product: "0", timestamp: timestamp, name: "Name", group: "Group", detail: nil, value: nil, previousEvent: nil, previousEventTimestamp: nil, install: date, custom: [])
        
        let mockStorage = MockStorage()
        let mockDispatcher = MockDispatcher(callback: { (events) -> Error? in
            XCTAssertEqual(events.count, 5)
            
            let otherGroupEvent = events[1]
            XCTAssertEqual(otherGroupEvent.name, "Other")
            XCTAssertNil(otherGroupEvent.previousEvent)
            XCTAssertNil(otherGroupEvent.previousEventTimestamp)
            
            let sameGroupEvent = events[2]
            XCTAssertEqual(sameGroupEvent.name, "Same")
            XCTAssertEqual(sameGroupEvent.previousEvent, "Name")
            XCTAssertNil(sameGroupEvent.previousEventTimestamp)
            
            let newTestName = events[3]
            XCTAssertEqual(newTestName.name, "Name")
            XCTAssertEqual(newTestName.previousEvent, "Same")
            XCTAssertEqual(newTestName.previousEventTimestamp, date)
            
            let newTestNameInOtherGroup = events[4]
            XCTAssertEqual(newTestNameInOtherGroup.name, "Name")
            XCTAssertEqual(newTestNameInOtherGroup.previousEvent, "Other")
            XCTAssertNotEqual(newTestNameInOtherGroup.previousEventTimestamp, date)
            
            expect.fulfill()
            return nil
        }, maxBatchSize: 10, timeout: 1)
        let beekeeper = Beekeeper(product: "0", dispatcher: mockDispatcher, storage: mockStorage, queue: Queue<Event>())
        beekeeper.start()
        beekeeper.track(event: event)
        beekeeper.track(name: "Other", group: "Other Group")
        beekeeper.track(name: "Same", group: "Group")
        beekeeper.track(name: "Name", group: "Group")
        beekeeper.track(name: "Name", group: "Other Group")
        beekeeper.dispatch()
        
        wait(for: [expect], timeout: 2)
    }
    
    func testResetting() {
        let expect = expectation(description: "Completion")
        expect.expectedFulfillmentCount = 2
        
        let eventName = "TestName"
        let eventGroup = "TestGroup"
        
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
        
        beekeeper.track(name: eventName, group: eventGroup)
        beekeeper.dispatch()
        beekeeper.reset()
        beekeeper.track(name: eventName, group: eventGroup)
        beekeeper.dispatch()
        
        wait(for: [expect], timeout: 5)
    }
    
    func testOptingOut() {
        let beekeeper = testableBeekeeper
        beekeeper.optedOut = true
        
        beekeeper.start()
        beekeeper.track(name: "Name", group: "Group")
        XCTAssertEqual(beekeeper.queue.count, 0)
    }
    
    func testTimeZone() {
        let timestamp = Date(timeIntervalSince1970: 1524268799) // 2018-04-20T23:59:59Z
        let day = timestamp.day
        XCTAssertEqual(day, "2018-04-20")
    }
    
}
