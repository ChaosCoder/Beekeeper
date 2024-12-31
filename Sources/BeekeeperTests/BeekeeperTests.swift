//
//  BeekeeperTests.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 14.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Testing
import Foundation
import Clocks
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
    var callback: (@Sendable ([Event]) -> Error?)?
    var maxBatchSize: Int
    var timeout: TimeInterval
    
    func dispatch(event: Event) async throws {
        if let error = callback?([event]) {
            throw error
        }
    }
    func dispatch(events: [Event]) async throws {
        if let error = callback?(events) {
            throw error
        }
    }
}

struct BeekeeperTests {
    
    var testableBeekeeper: Beekeeper {
        let mockStorage = MockStorage()
        let mockDispatcher = MockDispatcher(callback: nil, maxBatchSize: 1, timeout: 1)
        return Beekeeper(product: "0", dispatcher: mockDispatcher, storage: mockStorage, queue: Queue<Event>())
    }
    
    @Test
    func testTrackingQueuesUp() async {
        
        let beekeeper = testableBeekeeper
        
        let eventName = "TestName"
        let eventGroup = "TestGroup"
        let eventDetail = "TestDetail"
        let eventValue = 1.0
        let eventCustom = ["Custom"]
        
        await beekeeper.track(name: eventName, group: eventGroup, detail: eventDetail, value: eventValue, custom: eventCustom)
        
        await #expect(beekeeper.queue.count == 1)
        
        let event = await beekeeper.queue.first()
        #expect(event?.name == eventName)
        #expect(event?.group == eventGroup)
        #expect(event?.detail == eventDetail)
        #expect(event?.value == eventValue)
        #expect(event?.custom == eventCustom)
    }
    
    @Test
    func testSuccessfulDispatchingClearsQueue() async {
        
        let beekeeper = testableBeekeeper
        await beekeeper.start()
        
        let eventName = "TestName"
        let eventGroup = "TestGroup"
        await beekeeper.track(name: eventName, group: eventGroup)
        
        await #expect(beekeeper.queue.count == 1)
        await beekeeper.dispatch()
        await #expect(beekeeper.queue.count == 0)
    }
    
    @Test
    func testAsyncDispatchingClearsQueue() async {
        let beekeeper = testableBeekeeper
        await beekeeper.start()
        
        let eventName = "TestName"
        let eventGroup = "TestGroup"
        await beekeeper.track(name: eventName, group: eventGroup)
        
        await #expect(beekeeper.queue.count == 1)
        await beekeeper.dispatch()
        await #expect(beekeeper.queue.count == 0)
    }
    
    @Test
    func testDispatchingWithEmptyQueueStopsDispatcher() async {
        let beekeeper = testableBeekeeper
        await beekeeper.start()
        #expect(await beekeeper.isRunning())
        await beekeeper.dispatch()
        #expect(await !beekeeper.isRunning())
    }
    
    @Test
    func testTrackingStartDispatching() async {
        let beekeeper = testableBeekeeper
        await beekeeper.start()
        #expect(await beekeeper.isRunning())
        await beekeeper.track(name: "Name", group: "Group")
        #expect(await beekeeper.isRunning())
    }
    
    @Test
    func testBeekeeperAutomaticallyDispatchesEvents() async {
        
        let eventName = "TestName"
        let eventGroup = "TestGroup"
        
        await confirmation { confirm in
            let mockStorage = MockStorage()
            let mockDispatcher = MockDispatcher(callback: { (events) -> Error? in
                #expect(events.count == 1)
                #expect(events[0].name == eventName)
                confirm()
                return nil
            }, maxBatchSize: 1, timeout: 1)
            
            let testClock = TestClock()
            let beekeeper = Beekeeper(product: "0", dispatcher: mockDispatcher, storage: mockStorage, queue: Queue<Event>(), clock: AnyClock(testClock))
            await beekeeper.start()
            await beekeeper.track(name: eventName, group: eventGroup)
            await testClock.advance(by: .seconds(1))
        }
    }
    
    @Test
    func testPrevEvent() async {
        let date = "2018-04-20"
        let timestamp = Date(timeIntervalSince1970: 1524234032) // 2018-04-20T14:20:32Z
        let event = Event(id: "id", product: "0", timestamp: timestamp, name: "Name", group: "Group", detail: nil, value: nil, previousEvent: nil, previousEventTimestamp: nil, install: date, custom: [])
        
        await confirmation { confirm in
            let mockStorage = MockStorage()
            let mockDispatcher = MockDispatcher(callback: { (events) -> Error? in
                confirm()
                
                #expect(events.count == 5)
                
                let otherGroupEvent = events[1]
                #expect(otherGroupEvent.name == "Other")
                #expect(otherGroupEvent.previousEvent == nil)
                #expect(otherGroupEvent.previousEventTimestamp == nil)
                
                let sameGroupEvent = events[2]
                #expect(sameGroupEvent.name == "Same")
                #expect(sameGroupEvent.previousEvent == "Name")
                #expect(sameGroupEvent.previousEventTimestamp == nil)
                
                let newTestName = events[3]
                #expect(newTestName.name == "Name")
                #expect(newTestName.previousEvent == "Same")
                #expect(newTestName.previousEventTimestamp == date)
                
                let newTestNameInOtherGroup = events[4]
                #expect(newTestNameInOtherGroup.name == "Name")
                #expect(newTestNameInOtherGroup.previousEvent == "Other")
                #expect(newTestNameInOtherGroup.previousEventTimestamp != date)
                
                return nil
            }, maxBatchSize: 10, timeout: 1)
            
            let beekeeper = Beekeeper(product: "0", dispatcher: mockDispatcher, storage: mockStorage, queue: Queue<Event>())
            await beekeeper.start()
            await beekeeper.track(event: event)
            await beekeeper.track(name: "Other", group: "Other Group")
            await beekeeper.track(name: "Same", group: "Group")
            await beekeeper.track(name: "Name", group: "Group")
            await beekeeper.track(name: "Name", group: "Other Group")
            await beekeeper.dispatch()
        }
    }
    
    @Test
    func testResetting() async {
        let eventName = "TestName"
        let eventGroup = "TestGroup"
        
        await confirmation(expectedCount: 2) { confirm in
            let mockStorage = MockStorage()
            let mockDispatcher = MockDispatcher(callback: { (events) -> Error? in
                let event = events[0]
                #expect(event.name == eventName)
                #expect(event.previousEvent == nil)
                #expect(event.previousEventTimestamp == nil)
                confirm()
                return nil
            }, maxBatchSize: 1, timeout: 1)
            let beekeeper = Beekeeper(product: "0", dispatcher: mockDispatcher, storage: mockStorage, queue: Queue<Event>())
            await beekeeper.start()
            
            await beekeeper.track(name: eventName, group: eventGroup)
            await beekeeper.dispatch()
            await beekeeper.reset()
            await beekeeper.track(name: eventName, group: eventGroup)
            await beekeeper.dispatch()
        }
    }
    
    @Test
    func testOptingOut() async {
        let beekeeper = testableBeekeeper
        await beekeeper.setOptedOut(true)
        
        await beekeeper.start()
        await beekeeper.track(name: "Name", group: "Group")
        #expect(await beekeeper.queue.count == 0)
    }
    
    @Test
    func testTimeZone() {
        let timestamp = Date(timeIntervalSince1970: 1524268799) // 2018-04-20T23:59:59Z
        let day = timestamp.day
        #expect(day == "2018-04-20")
    }
    
    @Test
    func testSettingProperty() async {
        let beekeeper = testableBeekeeper
        await beekeeper.setProperty(1, value: "1")
        await beekeeper.track(name: "First", group: "Group")
        
        await beekeeper.setProperty(0, value: "0")
        await beekeeper.track(name: "Second", group: "Group")
        
        #expect(await beekeeper.queue.count == 2)
        
        let firstEvent = await beekeeper.queue.items[0]
        #expect(firstEvent.custom == [nil, "1"])
        
        let secondEvent = await beekeeper.queue.items[1]
        #expect(secondEvent.custom == ["0", "1"])
        
        await beekeeper.setProperty(0, value: nil)
        await beekeeper.setProperty(1, value: nil)
        await beekeeper.track(name: "Third", group: "Group")
        
        let thirdEvent = await beekeeper.queue.items[2]
        #expect(thirdEvent.custom == [nil, nil])
    }
    
    @Test
    func testSettingPropertyCount() async {
        let beekeeper = testableBeekeeper
        await beekeeper.setPropertyCount(3)
        await beekeeper.track(name: "First", group: "Group")
        
        let firstEvent = await beekeeper.queue.items[0]
        #expect(firstEvent.custom == [nil, nil, nil])
        
        await beekeeper.setProperty(1, value: "1")
        await beekeeper.track(name: "Second", group: "Group")
        
        let secondEvent = await beekeeper.queue.items[1]
        #expect(secondEvent.custom == [nil, "1", nil])
        
        await beekeeper.setPropertyCount(2)
        await beekeeper.track(name: "Third", group: "Group")
        
        let thirdEvent = await beekeeper.queue.items[2]
        #expect(thirdEvent.custom == [nil, "1"])
    }
    
    @Test
    func testOverwritingProperty() async {
        let beekeeper = testableBeekeeper
        
        await beekeeper.setPropertyCount(2)
        await beekeeper.setProperty(0, value: "0")
        await beekeeper.setProperty(1, value: "1")
        
        await beekeeper.track(name: "First", group: "Group", custom: [nil, "A"])
        
        #expect(await beekeeper.queue.count == 1)
        
        let event = await beekeeper.queue.items[0]
        #expect(event.custom == ["0", "A"])
    }
}
