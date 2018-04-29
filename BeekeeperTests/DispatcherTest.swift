//
//  DispatcherTest.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import XCTest
@testable import Beekeeper

class DispatcherTest: XCTestCase {
    
    func testDispatching() {
        let signer = RequestSigner(secret: "")
        let dispatcher = URLDispatcher(baseURL: URL(string: "https://httpbin.org")!, path: "/post", signer: signer)
        
        let install = Date()
        let event = Event(id: "1", product: "0", timestamp: install.addingTimeInterval(1), name: "name", group: "group", detail: "detail", value: 42, previousEvent: "previous", previousEventTimestamp: install.day, install: install.day, custom: [])
        
        let expectation = self.expectation(description: "Expectation")
        dispatcher.dispatch(event: event) { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }
}
